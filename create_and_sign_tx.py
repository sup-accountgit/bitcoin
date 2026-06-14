import os
import json
import requests

def main():
    # 1. Fetch all secret variables from GitHub Secrets Environment
    utxo_input_str = os.getenv("INPUT_UTXO_JSON") # UTXOS_1
    priv_key = os.getenv("BTC_PRIVATE_KEY")       # BTC_1 (Key used to unlock/sign)
    target_address = os.getenv("TARGET_ADDRESS")  # BTC_2 (Recipient address for 1.0 BTC)
    change_address = os.getenv("CHANGE_ADDRESS")  # BTC_3 (Change address)
    
    amount_to_send = 1.0
    print("=== [Step 1] Verifying Wallet and UTXO Data ===")

    # 2. Validate UTXO structure and perform Math calculations for total balance
    try:
        utxos = json.loads(utxo_input_str)
    except Exception as e:
        print("[ERROR] UTXOS_1 data format is invalid. It must be a JSON Array.")
        return

    # Math Validation: Sum up all available input funds
    total_input_amount = sum(float(u["amount"]) for u in utxos)
    num_inputs = len(utxos)
    
    print(f"-> Verified total balance in UTXOS_1: {total_input_amount:.8f} BTC ({num_inputs} Inputs)")

    # Check if total balance is sufficient to send 1.0 BTC
    if total_input_amount < amount_to_send:
        print(f"[ERROR] Total balance ({total_input_amount:.8f} BTC) is insufficient to send {amount_to_send} BTC")
        return
    print("[SUCCESS] Balance verification passed minimum requirement.")

    # 3. Fetch network fee rate for the next block (High Priority / 1 Block)
    print("\n=== [Step 2] Calculating Maximum Fee (1 Block Confirmation) ===")
    try:
        # Fetching live high-priority fee rate from mempool.space API
        fee_response = requests.get("https://mempool.space/api/v1/fees/recommended", timeout=10)
        sat_per_vbyte = fee_response.json()["fastestFee"]
        print(f"-> Latest high-priority fee rate from network: {sat_per_vbyte} sat/vB")
    except Exception as e:
        sat_per_vbyte = 140 # High-priority fallback fee if API fails
        print(f"[WARNING] API request failed. Using fallback high-priority fee: {sat_per_vbyte} sat/vB")

    # Calculate estimated transaction size and fee in BTC
    estimated_vbytes = (num_inputs * 68) + (2 * 31) + 11
    total_fee_btc = (estimated_vbytes * sat_per_vbyte) / 100_000_000
    
    # Math: Calculate remaining change amount
    change_amount = total_input_amount - amount_to_send - total_fee_btc
    print(f"-> Estimated Tx Size: {estimated_vbytes} vBytes | Total Tx Fee: {total_fee_btc:.8f} BTC")
    print(f"-> Change amount to be returned to BTC_3: {change_amount:.8f} BTC")

    if change_amount < 0:
        print("[ERROR] Insufficient funds to cover the high-priority fee required for 1-Block confirmation.")
        return

    # 4. Map data and format single-step automation commands
    cli_inputs = [{"txid": u["txid"], "vout": u["vout"]} for u in utxos]
    cli_outputs = {
        target_address: amount_to_send,
        change_address: round(change_amount, 8)
    }

    print("\n=== [Step 3] Node Automation Commands (Create & Sign in One Step) ===")
    
    # Command 1: Create Raw Transaction
    inputs_json = json.dumps(cli_inputs).replace('"', '\\"')
    outputs_json = json.dumps(cli_outputs).replace('"', '\\"')
    
    print("# Execute these commands sequentially on your node to build and unlock your funds:")
    create_cmd = f"RAW_HEX=$(bitcoin-cli createrawtransaction \"{inputs_json}\" \"{outputs_json}\")"
    print(create_cmd)
    
    # Command 2: Unlock and Sign using key BTC_1
    sign_cmd = f"SIGNED_HEX=$(bitcoin-cli signrawtransactionwithkey \"$RAW_HEX\" '[\"{priv_key}\"]')\necho \"Transaction signed successfully: $SIGNED_HEX\""
    print(sign_cmd)

if __name__ == "__main__":
    main()
  
