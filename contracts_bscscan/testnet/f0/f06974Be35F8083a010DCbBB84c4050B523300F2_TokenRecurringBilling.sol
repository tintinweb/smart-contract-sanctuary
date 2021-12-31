/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

// SPDX-License-Identifier: UNLISCENSED
/**
 * Token recurring billing smart contracts, which enable recurring billing feature for ERC20-compatible tokens.
 * Developed by DreamTeam.GG contributors. Visit dreamteam.gg and github.com/dreamteam-gg/smart-contracts for more info.
 * Copyright © 2019 DREAMTEAM.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

pragma solidity 0.8.2;

interface ERC20CompatibleToken {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);
}

/**
 * Math operations with safety checks that throw on overflows.
 */
library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

/**
 * Factory that creates recurring billing smart contracts for specified token.
 * You can enable recurring billing for your own ERC20-compatible tokens!
 * Find the documentation here: https://github.com/dreamteam-gg/smart-contracts#smart-contracts-documentation
 */
contract RecurringBillingContractFactory {

    event NewRecurringBillingContractCreated(address token, address recurringBillingContract);

    function newRecurringBillingContract (address tokenAddress) public returns (address recurringBillingContractAddress) {
        TokenRecurringBilling rb = new TokenRecurringBilling(tokenAddress);
        emit NewRecurringBillingContractCreated(tokenAddress, address(rb));
        return address(rb);
    }

}
 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
/**
 * Smart contract for recurring billing in ERC20-compatible tokens. This smart contract defines workflow between
 * a merchant and a customer. Workflow:
 * 1. Merchant registers theirselves in this smart contract using `registerNewMerchant`.
 *   1.1. Merchant specifies `beneficiary` address, which receives tokens.
 *   1.2. Merchant specifies `merchant` address, which is able to change `merchant` and `beneficiary` addresses.
 *   1.3. Merchant specified an address that is authorized to call `charge` related to this merchant.
 *     1.3.1. Later, merchant can (de)authorize another addresses to call `charge` using `changeMerchantChargingAccount`.
 *   1.4. As a result, merchant gets `merchantId`, which is used to initialize recurring billing by customers.
 *   1.5. Merchant account can change their `beneficiary`, `merchant` and authorized charging addresses by calling:
 *     1.4.1. Function `changeMerchantAccount`, which changes account that can control this merchant (`merchantId`).
 *     1.4.2. Function `changeMerchantBeneficiaryAddress`, which changes merchant's `beneficiary`.
 *     1.4.3. Function `changeMerchantChargingAccount`, which (de)authorizes addresses to call `charge` on behalf of this merchant.
 * 2. According to an off-chain agreement with merchant, customer calls `allowRecurringBilling` and:
 *   2.1. Specifies `billingId`, which is given off-chain by merchant (merchant will listen blockchain Event on this ID).
 *   2.2. Specifies `merchantId`, the merchant which will receive tokens.
 *   2.3. Specifies `period` in seconds, during which only one charge can occur.
 *   2.4. Specifies `value`, amount in tokens which can be charged each `period`.
 *     2.4.1. If the customer doesn't have at least `value` tokens, `allowRecurringBilling` errors.
 *     2.4.2. If the customer haven't approved at least `value` tokens for a smart contract, `allowRecurringBilling` errors.
 *   2.5. `billingId` is then used by merchant to charge customer each `period`.
 * 3. Merchant use authorized accounts (1.3) to call the `charge` function each `period` to charge agreed amount from a customer.
 *   3.1. It is impossible to call `charge` if the date of the last charge is less than `period`.
 *   3.2. Calling `charge` cancels billing when called after 2 `period`s from the last charge.
 *   3.3. Thus, to successfully charge an account, `charge` must be strictly called within 1 and 2 `period`s after the last charge.
 *   3.4. Calling `charge` errors if any of the following occur:
 *     3.4.1. Customer canceled recurring billing with `cancelRecurringBilling`.
 *     3.4.2. Customer's balance is lower than the chargeable amount.
 *     3.4.3. Customer's allowance to the smart contract is less than the chargable amount.
 *     3.4.4. Specified `billingId` does not exists.
 *     3.4.5. There's no `period` passed since the last charge.
 *   3.5. Next charge date increments strictly by `period` each charge, thus, there's no need to exec `charge` strictly on time.
 * 4. Customer can cancel further billing by calling `cancelRecurringBilling` and passing `billingId`.
 * 5. TokenRecurringBilling smart contract implements `receiveApproval` function for allowing/cancelling billing within one call from
 *    the token smart contract. Parameter `data` is encoded as tightly-packed (uint256 metadata, uint256 billingId).
 *   5.1. `metadata` is encoded using `encodeBillingMetadata`.
 *   5.2. As for `receiveApproval`, `lastChargeAt` in `metadata` is used as an action identifier.
 *      5.2.1. `lastChargeAt=0` specifies that customer wants to allow new recurring billing.
 *      5.2.2. `lastChargeAt=1` specifies that customer wants to cancel existing recurring billing.
 *   5.3. Make sure that passed `bytes` parameter is exactly 64 bytes in length.
 */
contract TokenRecurringBilling {

    using SafeMath for uint256;

    event BillingAllowed(uint256 indexed billingId, address customer, uint256 merchantId, uint256 timestamp, uint256 period, uint256 value);
    event BillingCharged(uint256 indexed billingId, uint256 timestamp, uint256 nextChargeTimestamp);
    event BillingCanceled(uint256 indexed billingId);
    event MerchantRegistered(uint256 indexed merchantId, address merchantAccount, address beneficiaryAddress);
    event MerchantAccountChanged(uint256 indexed merchantId, address merchantAccount);
    event MerchantBeneficiaryAddressChanged(uint256 indexed merchantId, address beneficiaryAddress);
    event MerchantChargingAccountAllowed(uint256 indexed merchantId, address chargingAccount, bool allowed);

    struct BillingRecord {
        address customer; // Billing address (those who pay).
        uint256 metadata; // Metadata packs 5 values to save on storage. Metadata spec (from first to last byte):
                          //   + uint32 period;       // Billing period in seconds; configurable period of up to 136 years.
                          //   + uint32 merchantId;   // Merchant ID; up to ~4.2 Milliard IDs.
                          //   + uint48 lastChargeAt; // When the last charge occurred; up to year 999999+.
                          //   + uint144 value;       // Billing value charrged each period; up to ~22 septillion tokens with 18 decimals
    }

    struct Merchant {
        address merchant;    // Merchant admin address that can change all merchant struct properties.
        address beneficiary; // Address receiving tokens.
    }

    enum receiveApprovalAction { // In receiveApproval, `lastChargeAt` in passed `metadata` specifies an action to execute.
        allowRecurringBilling,   // == 0
        cancelRecurringBilling   // == 1
    }

    uint256 public lastMerchantId;     // This variable increments on each new merchant registered, generating unique ids for merchant.
    ERC20CompatibleToken public token; // Token address.

    mapping(uint256 => BillingRecord) public billingRegistry;                           // List of all billings registered by ID.
    mapping(uint256 => Merchant) public merchantRegistry;                               // List of all merchants registered by ID.
    mapping(uint256 => mapping(address => bool)) public merchantChargingAccountAllowed; // Accounts that are allowed to charge customers.

    // Checks whether {merchant} owns {merchantId}
    modifier isMerchant (uint256 merchantId) {
        require(merchantRegistry[merchantId].merchant == msg.sender, "Sender is not a merchant");
        _;
    }

    // Checks whether {customer} owns {billingId}
    modifier isCustomer (uint256 billingId) {
        require(billingRegistry[billingId].customer == msg.sender, "Sender is not a customer");
        _;
    }

    // Guarantees that the transaction is sent by token smart contract only.
    modifier tokenOnly () {
        require(msg.sender == address(token), "Sender is not a token");
        _;
    }

    /// ======================================================== Constructor ========================================================= \\\

    // Creates a recurring billing smart contract for particular token.
    constructor (address tokenAddress) public {
        token = ERC20CompatibleToken(tokenAddress);
    }

    /// ====================================================== Public Functions ====================================================== \\\

    // Enables merchant with {merchantId} to charge transaction signer's account according to specified {value} and {period}.
    function allowRecurringBilling (uint256 billingId, uint256 merchantId, uint256 value, uint256 period) public {
        allowRecurringBillingInternal(msg.sender, merchantId, billingId, value, period);
    }

    // Enables anyone to become a merchant, charging tokens for their services.
    function registerNewMerchant (address beneficiary, address chargingAccount) public returns (uint256 merchantId) {

        merchantId = ++lastMerchantId;
        Merchant storage record = merchantRegistry[merchantId];
        record.merchant = msg.sender;
        record.beneficiary = beneficiary;
        emit MerchantRegistered(merchantId, msg.sender, beneficiary);

        changeMerchantChargingAccount(merchantId, chargingAccount, true);

    }

    /// =========================================== Public Functions with Restricted Access =========================================== \\\

    // Calcels recurring billing with id {billingId} if it is owned by a transaction signer.
    function cancelRecurringBilling (uint256 billingId) public isCustomer(billingId) {
        cancelRecurringBillingInternal(billingId);
    }

    // Charges customer's account according to defined {billingId} billing rules. Only merchant's authorized accounts can charge the customer.
    function charge (uint256 billingId) public {

        BillingRecord storage billingRecord = billingRegistry[billingId];
        (uint256 value, uint256 lastChargeAt, uint256 merchantId, uint256 period) = decodeBillingMetadata(billingRecord.metadata);

        require(merchantChargingAccountAllowed[merchantId][msg.sender], "Sender is not allowed to charge");
        require(merchantId != 0, "Billing does not exist");
        require(lastChargeAt.add(period) <= block.timestamp, "Charged too early");

        // If 2 periods have already passed since the last charge (or beginning), no further charges are possible
        // and recurring billing is canceled in case of a charge.
        if (block.timestamp > lastChargeAt.add(period.mul(2))) {
            cancelRecurringBillingInternal(billingId);
            return;
        }

        require(
            token.transferFrom(billingRecord.customer, merchantRegistry[merchantId].beneficiary, value),
            "Unable to charge customer"
        );

        billingRecord.metadata = encodeBillingMetadata(value, lastChargeAt.add(period), merchantId, period);

        emit BillingCharged(billingId, block.timestamp, lastChargeAt.add(period.mul(2)));

    }

    /**
     * Invoked by a token smart contract on approveAndCall. Allows or cancels recurring billing.
     * @param sender - Address that approved some tokens for this smart contract.
     * @param data - Tightly-packed (uint256,uint256) values of (metadata, billingId). Metadata's `lastChargeAt`
     *               specifies an action to perform (see `receiveApprovalAction` enum).
     */
    function receiveApproval (address sender, uint, address, bytes calldata data) external tokenOnly {

        // The token contract MUST guarantee that "sender" is actually the token owner, and metadata is signed by a token owner.
        require(data.length == 64, "Invalid data length");

        // `action` is used instead of `lastCahrgeAt` to save some space.
        (uint256 value, uint256 action, uint256 merchantId, uint256 period) = decodeBillingMetadata(bytesToUint256(data, 0));
        uint256 billingId = bytesToUint256(data, 32);

        if (action == uint256(receiveApprovalAction.allowRecurringBilling)) {
            allowRecurringBillingInternal(sender, merchantId, billingId, value, period);
        } else if (action == uint256(receiveApprovalAction.cancelRecurringBilling)) {
            require(billingRegistry[billingId].customer == sender, "Unable to cancel recurring billing of another customer");
            cancelRecurringBillingInternal(billingId);
        } else {
            revert("Unknown action provided");
        }

    }

    // Changes merchant account with id {merchantId} to {newMerchantAccount}.
    function changeMerchantAccount (uint256 merchantId, address newMerchantAccount) public isMerchant(merchantId) {
        merchantRegistry[merchantId].merchant = newMerchantAccount;
        emit MerchantAccountChanged(merchantId, newMerchantAccount);
    }

    // Changes merchant's beneficiary address (address that receives charged tokens) to {newBeneficiaryAddress}.
    function changeMerchantBeneficiaryAddress (uint256 merchantId, address newBeneficiaryAddress) public isMerchant(merchantId) {
        merchantRegistry[merchantId].beneficiary = newBeneficiaryAddress;
        emit MerchantBeneficiaryAddressChanged(merchantId, newBeneficiaryAddress);
    }

    // Allows or disallows particular {account} to charge customers related to this merchant.
    function changeMerchantChargingAccount (uint256 merchantId, address account, bool allowed) public isMerchant(merchantId) {
        merchantChargingAccountAllowed[merchantId][account] = allowed;
        emit MerchantChargingAccountAllowed(merchantId, account, allowed);
    }

    /// ================================================== Public Utility Functions ================================================== \\\

    // Used to encode 5 values into one uint256 value. This is primarily made for cheaper storage.
    function encodeBillingMetadata (
        uint256 value,
        uint256 lastChargeAt,
        uint256 merchantId,
        uint256 period
    ) public pure returns (uint256 result) {

        require(
            value < 2 ** 144
            && lastChargeAt < 2 ** 48
            && merchantId < 2 ** 32
            && period < 2 ** 32,
            "Invalid input sizes to encode"
        );

        result = value;
        result |= lastChargeAt << (144);
        result |= merchantId << (144 + 48);
        result |= period << (144 + 48 + 32);

        return result;

    }

    // Used to decode 5 values from one uint256 value encoded by `encodeBillingMetadata` function.
    function decodeBillingMetadata (uint256 encodedData) public pure returns (
        uint256 value,
        uint256 lastChargeAt,
        uint256 merchantId,
        uint256 period
    ) {
        value = uint144(encodedData);
        lastChargeAt = uint48(encodedData >> (144));
        merchantId = uint32(encodedData >> (144 + 48));
        period = uint32(encodedData >> (144 + 48 + 32));
    }

    /// ================================================ Internal (Private) Functions ================================================ \\\

    // Allows recurring billing. Noone but this contract can call this function.
    function allowRecurringBillingInternal (
        address customer,
        uint256 merchantId,
        uint256 billingId,
        uint256 value,
        uint256 period
    ) internal {

        require(merchantId <= lastMerchantId && merchantId != 0, "Invalid merchant specified");
        require(period < block.timestamp, "Invalid period specified");
        require(token.balanceOf(customer) >= value, "Not enough tokens for the first charge");
        require(token.allowance(customer, address(this)) >= value, "Tokens are not approved for this smart contract");
        require(billingRegistry[billingId].customer == address(0x0), "Recurring billing with this ID is already registered");

        BillingRecord storage newRecurringBilling = billingRegistry[billingId];
        newRecurringBilling.metadata = encodeBillingMetadata(value, block.timestamp.sub(period), merchantId, period);
        newRecurringBilling.customer = customer;

        emit BillingAllowed(billingId, customer, merchantId, block.timestamp, period, value);

    }

    // Cancels recurring billing. Noone but this contract can call this function.
    function cancelRecurringBillingInternal (uint256 billingId) internal {
        delete billingRegistry[billingId];
        emit BillingCanceled(billingId);
    }

    // Utility function to convert bytes type to uint256. Noone but this contract can call this function.
    function bytesToUint256(bytes memory input, uint offset) internal pure returns (uint256 output) {
        assembly { output := mload(add(add(input, 32), offset)) }
    }

}