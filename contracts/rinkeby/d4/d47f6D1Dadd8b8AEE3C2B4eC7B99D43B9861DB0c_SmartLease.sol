/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: SmartLease.sol

contract SmartLease {
    //------------------------------Declaring the CONTRACT VARIABLES-----------------------------------//

    //The address & address payable types store 160-bit Ethereum address.
    //The difference between the two is that the latter type(address payble) permits the following calls: .send(), .transfer(), .call()
    address payable lessor;
    address payable lessee;

    enum CONTRACT_STATUS {
        DEPLOYED,
        SIGNED,
        ACTIVE,
        TERMINATED
    }

    enum CAR_CONDITION {
        NEW,
        USED
    }

    struct Car {
        string VIN;
        string Car_model;
        int256 Car_product_year;
        CAR_CONDITION Car_condition;
    }

    Car public leased_car;

    //Declearing the leasing parameters:
    struct Leasing {
        uint256 lease_duration_in_months;
        uint256 lease_rate;
        uint256 full_retail_value;
        uint256 residual_value;
        uint256 total_cost_of_lease;
        uint256 security_deposit;
        uint256 miles_limit;
        uint256 additional_fees;
        uint256 down_payment;
        uint256 tax_rate;
        bool buy_option;
        uint256 depreciation_value;
    }

    Leasing public lease_conditions;

    uint256 WEI_VALUE = 1 wei;

    bytes public lesse_signature;

    bool security_deposit_transferred_successfully = false;
    bool down_payment_transferred_successfully = false;
    bool total_monthly_lease_transferred_successfully = false;
    uint256 actual_deposit_paid;
    uint256 actual_down_payment_paid;
    uint256 actual_total_monthly_lease_paid;

    CONTRACT_STATUS status = CONTRACT_STATUS.DEPLOYED;

    //Modifiers are used to modify the behaviour of a function, or to add a prerequisite to a function:
    modifier only_lessee() {
        require(
            msg.sender == lessee,
            "Only the LESSEE can perform the current transaction !"
        );
        _;
    }
    modifier only_lessor() {
        require(
            msg.sender == lessor,
            "Only the LESSOR can perfrom the current transaction !"
        );
        _;
    }

    //------------------------Setting  the identity of the LESSOR and the LESSEE----------------------------//

    //A contructor is a type of function that gets automatically executed when the contract is deployed. Since the lessor is also the owner of the contract, we can identify right away after deployment who is the lessor in our contract
    constructor() public {
        lessor = msg.sender;
    }

    function get_lessor() public view returns (address) {
        return lessor;
    }

    function set_lessee(address payable _lessee) public {
        require(msg.sender == lessor);
        lessee = _lessee;
    }

    function get_lessee() public view returns (address) {
        return lessee;
    }

    //------------------------Setting  the profile of the leased CAR--------------------------------------//
    function add_car(
        string memory _VIN,
        string memory _Car_model,
        int256 _Car_product_year,
        CAR_CONDITION _Car_condition
    ) public {
        require(msg.sender == lessor);
        leased_car = Car(_VIN, _Car_model, _Car_product_year, _Car_condition);
    }

    //------------------------Setting  the conditions of the LEASE CONTRACT--------------------------------------//

    function set_leasing_conditions(
        uint256 _lease_duration_in_months,
        uint256 _lease_rate,
        uint256 _full_retail_value,
        uint256 _residual_value,
        uint256 _total_cost_of_lease,
        uint256 _security_deposit,
        uint256 _miles_limit,
        uint256 _additional_fees,
        uint256 _down_payment,
        uint256 _tax_rate,
        bool _buy_option
    ) public {
        Leasing memory _temp_leasing;

        lease_conditions = _temp_leasing;

        lease_conditions.lease_duration_in_months = _lease_duration_in_months;
        lease_conditions.lease_rate = _lease_rate;
        lease_conditions.full_retail_value = _full_retail_value * WEI_VALUE;
        lease_conditions.residual_value = _residual_value * WEI_VALUE;
        lease_conditions.total_cost_of_lease = _total_cost_of_lease * WEI_VALUE;
        lease_conditions.security_deposit = _security_deposit * WEI_VALUE;
        lease_conditions.miles_limit = _miles_limit;
        lease_conditions.additional_fees = _additional_fees * WEI_VALUE;
        lease_conditions.down_payment = _down_payment * WEI_VALUE;
        lease_conditions.tax_rate = _tax_rate;
        lease_conditions.buy_option = _buy_option;
        lease_conditions.depreciation_value =
            (lease_conditions.full_retail_value -
                lease_conditions.residual_value) *
            WEI_VALUE;
    }

    // TODO: Revise the calculation of monthly payments
    // 1. What happens when the division of depreciation value by lease duration (or lease rate) does not result in an integer number?
    // 2. Instead of always having to call the monthly_payment function with the tax rate, choose one of the two approaches
    //      2.1 Either set the tax rate via a set_tax_rate(uint256 _tax_rate) function and do not require any parameter in the monthly_payment()
    //      2.2 Or implement a set_monthly_payment(uint256 _tax_rate) function which will calculate everything and save it in the contract (in a variable)

    //Important: The calculation logic below, will work only for countries where the taxes are demanded on monthly payment. Source: https://www.buerklehonda.com/financing/how-car-lease-payments-are-calculated///
    function monthly_payment() public view returns (uint256) {
        uint256 monthly_depreciation = lease_conditions.depreciation_value /
            lease_conditions.lease_duration_in_months;
        uint256 monthly_finance_charge = lease_conditions.depreciation_value /
            lease_conditions.lease_rate /
            100;
        uint256 base_monthly_payment = monthly_depreciation +
            monthly_finance_charge;
        uint256 monthly_lease_payment = base_monthly_payment *
            (1 + lease_conditions.tax_rate / 100);
        return monthly_lease_payment;
    }

    //------------------------Electronically Signing the contract--------------------------------------//

    /*Remark: The code from the line 203 to 270 has been addapted according to the instructions and actual code provided by the following two souces: 
    Source 1: https://solidity-by-example.org/signature/(article) & https://www.youtube.com/watch?v=NP4db_UPVwc (video)
    Source 2: https://cryptomarketpool.com/how-to-sign-verify-an-ethereum-message-off-chain/ */

    function get_agree_to_sign_message() public pure returns (string memory) {
        return (
            "I agree with all terms and conditions of the underlying leasing contract. Thereby, I sign this contract"
        );
    }

    function get_agree_to_sign_message_hash() public pure returns (bytes32) {
        return keccak256(abi.encodePacked(get_agree_to_sign_message()));
    }

    function get_eth_signed_message_hash() public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    get_agree_to_sign_message_hash()
                )
            );
    }

    function activate_contract() internal {
        status = CONTRACT_STATUS.SIGNED;
    }

    function sign_contract_lessee(bytes memory signature)
        public
        returns (bool)
    {
        if (msg.sender != lessee) {
            revert("Only the LESSEE has the right to sign the contract");
        } else if (!verify(signature)) {
            revert("Invalid signature.");
        } else {
            lesse_signature = signature;
            activate_contract();
            return true;
        }
    }

    function verify(bytes memory signature) public view returns (bool) {
        return find_signer(signature) == get_lessee();
    }

    function find_signer(bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = split_signature(_signature);
        bytes32 ethSignedMessageHash = get_eth_signed_message_hash();

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function split_signature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /*----------------------GETTER functions for the contract status, accout balance of the Lessee and the Lessor   ----------------------*/
    function get_contract_status() public view returns (string memory) {
        if (status == CONTRACT_STATUS.DEPLOYED) {
            return ("Deployed");
        } else if (status == CONTRACT_STATUS.SIGNED) {
            return (" Signed");
        } else if (status == CONTRACT_STATUS.ACTIVE) {
            return ("Active");
        } else if (status == CONTRACT_STATUS.TERMINATED) {
            return (" Terminated");
        }
    }

    function contract_status() internal view returns (CONTRACT_STATUS) {
        return status;
    }

    function get_contract_balance() public view returns (uint256) {
        //Remark: "address(this).balance" reffers to the balance of the smart contract.
        return address(this).balance;
    }

    function get_lessor_balance() public view only_lessor returns (uint256) {
        return lessor.balance;
    }

    function get_lessee_balance() public view only_lessee returns (uint256) {
        return lessee.balance;
    }

    /*----------------------Transfering the SECURITY DEPOSIT from the Lessee to the Lessor account----------------------*/
    function transfer_security_deposit()
        public
        payable
        only_lessee
        returns (bool)
    {
        if (lease_conditions.security_deposit == 0) {
            revert("The leasing contract does not require a security deposit");
        } else if (contract_status() != CONTRACT_STATUS.SIGNED) {
            revert(
                "The contract must be signed first, in order to proceed with the following transaction"
            );
        } else if (msg.sender.balance < msg.value) {
            revert("Not enough funds");
        } else if (msg.value != lease_conditions.security_deposit) {
            revert(
                "You need to pay the exact, full security deposit amount !!!"
            );
        } else {
            actual_deposit_paid = msg.value;
            transfer_money_to_lessor(actual_deposit_paid);
            security_deposit_transferred_successfully = true;
            return security_deposit_transferred_successfully;
        }
    }

    /*----------------------Transfering the DOWN_PAYMENT from the Lessee to the Lessor account----------------------*/
    function transfer_down_payment() public payable only_lessee returns (bool) {
        if (lease_conditions.down_payment == 0) {
            revert("The leasing contract does not require a downpayment !");
        } else if (contract_status() != CONTRACT_STATUS.SIGNED) {
            revert(
                "The contract must be signed first, in order to proceed with the following transaction !"
            );
        } else if (msg.sender.balance < msg.value) {
            revert("Not enough funds !");
        } else if (msg.value != lease_conditions.down_payment) {
            revert("You need to pay the exact, full down payment amount !!!");
        } else {
            actual_down_payment_paid = msg.value;
            transfer_money_to_lessor(actual_down_payment_paid);
            down_payment_transferred_successfully = true;
            return down_payment_transferred_successfully;
        }
    }

    /*---------------------------------------Monthly payment transaction-------------------------------------------*/

    //Source: https://ethereum.stackexchange.com/questions/42/how-can-a-contract-run-itself-at-a-later-time
    //Remark the Ethereum Protocol, does not have at the current moment a native way of auto-executing a transaction at a specific future point in time.
    //Thus, we used a simulation for the monthly payment
    function transfer_sum_monthly_payment()
        public
        payable
        only_lessee
        returns (bool)
    {
        uint256 total_monthly_lease_payment = monthly_payment() *
            lease_conditions.lease_duration_in_months;
        if (contract_status() != CONTRACT_STATUS.SIGNED) {
            revert(
                "Dear Lessee, the contract must be signed first, for you to proceed with the following transaction"
            );
        } else if (msg.sender.balance < total_monthly_lease_payment) {
            revert("Dear Lessee, you do not have enough funds on your account");
        } else if (msg.value != total_monthly_lease_payment) {
            revert(
                "Dear Lessee, for the purpose of this simulation, you must pay the cummulative monthly lease payment for the entire lease duration!"
            );
        } else {
            actual_total_monthly_lease_paid = msg.value;
            total_monthly_lease_transferred_successfully = true;
            return total_monthly_lease_transferred_successfully;
        }
    }

    /*---------------------------------------Transfer money to lessor account-------------------------------------------*/

    function transfer_money_to_lessor(uint256 _amount)
        public
        payable
        returns (bool)
    {
        //The lessor.transfer() function allows to send  money from the smart contract to the lessor account.
        lessor.transfer(_amount);
        return true;
    }
}