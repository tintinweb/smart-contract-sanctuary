/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: SmartLease.sol

contract SmartLease {
    //------------------------------Declaring the CONTRACT VARIABLES-----------------------------------//

    //The "address payable" data type store 160-bit Ethereum address.
    //The data type "address payble" permits the following usefull calls: .send(), .transfer(), .call()
    address payable lessor;
    address payable lessee;

    enum CONTRACT_STATUS {
        DEPLOYED,
        SIGNED,
        ACTIVE,
        TERMINATED
    }

    CONTRACT_STATUS status = CONTRACT_STATUS.DEPLOYED;

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

    struct Leasing {
        uint256 lease_duration_in_months;
        uint256 annual_percentage_rate;
        uint256 full_retail_value;
        uint256 residual_value;
        uint256 security_deposit;
        uint256 monthly_miles_limit;
        uint256 tax_percentage_rate;
        bool buy_option;
        uint256 depreciation_value;
    }

    Leasing public lease_conditions;

    uint256 WEI_VALUE = 1 wei;

    bytes public lesse_signature;

    bool security_deposit_transferred_successfully = false;
    bool total_monthly_lease_transferred_successfully = false;
    uint256 actual_deposit_paid;
    uint256 actual_total_monthly_lease_paid;
    uint256 total_miles_limit;
    uint256 penalty_per_mile;
    bool penalties_have_been_paid;
    int256[] monthly_miles_usage_tracker;

    uint256 call_option_price;
    uint256 spot_price;
    uint256 strike_price;
    bool option_price_paid = false;
    address car_owner = lessor;
    bool call_option_has_been_exercised = false;
    bool security_deposit_has_been_refunded = false;

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

    //According to Collins (2021), a contructor is a type of function that gets automatically executed when the contract is deployed.
    //Since the lessor is also the owner of the contract, we can identify right away after deployment who is the lessor in our contract
    constructor() public {
        lessor = msg.sender;
    }

    function get_lessor() public view returns (address) {
        return lessor;
    }

    function set_lessee(address payable _lessee) public {
        lessee = _lessee;
    }

    function get_lessee() public view returns (address) {
        return lessee;
    }

    //------------------------Setting  the profile of the leased CAR--------------------------------------//
    function select_car_lessee(
        string memory _Car_model,
        int256 _Car_product_year,
        CAR_CONDITION _Car_condition
    ) public only_lessee {
        leased_car.Car_model = _Car_model;
        leased_car.Car_product_year = _Car_product_year;
        leased_car.Car_condition = _Car_condition;
    }

    function input_VIN_lessor(string memory _VIN) public only_lessor {
        leased_car.VIN = _VIN;
    }

    //------------------------Setting  the conditions of the LEASE CONTRACT--------------------------------------//

    function set_leasing_conditions(
        uint256 _lease_duration_in_months,
        uint256 _annual_percentage_rate,
        uint256 _full_retail_value,
        uint256 _residual_value,
        uint256 _security_deposit,
        uint256 _monthly_miles_limit,
        uint256 _tax_percentage_rate,
        bool _buy_option
    ) public {
        Leasing memory _temp_leasing;

        lease_conditions = _temp_leasing;

        lease_conditions.lease_duration_in_months = _lease_duration_in_months;
        lease_conditions.annual_percentage_rate = _annual_percentage_rate;
        lease_conditions.full_retail_value = _full_retail_value * WEI_VALUE;
        lease_conditions.residual_value = _residual_value * WEI_VALUE;
        lease_conditions.security_deposit = _security_deposit * WEI_VALUE;
        lease_conditions.monthly_miles_limit = _monthly_miles_limit;
        lease_conditions.tax_percentage_rate = _tax_percentage_rate;
        lease_conditions.buy_option = _buy_option;
        lease_conditions.depreciation_value =
            (lease_conditions.full_retail_value -
                lease_conditions.residual_value) *
            WEI_VALUE;
    }

    //The calculation logic below was implemented according to the explanation provided by Buerkle Honda (n.d)
    //Also, in order to understand better the concept of "money factor", we consulted the Investopedia article by Touvila (2020)
    function monthly_payment() public view returns (uint256) {
        uint256 monthly_depreciation = lease_conditions.depreciation_value /
            lease_conditions.lease_duration_in_months;
        uint256 money_factor = lease_conditions.annual_percentage_rate / 2400;
        uint256 monthly_finance_charge = (lease_conditions.full_retail_value +
            lease_conditions.residual_value) * money_factor;
        uint256 base_monthly_payment = monthly_depreciation +
            monthly_finance_charge;
        uint256 monthly_lease_payment = base_monthly_payment *
            (1 + lease_conditions.tax_percentage_rate / 100);
        return monthly_lease_payment;
    }

    //------------------------Electronically Signing the contract--------------------------------------//

    /*Remark: The code from the line 160 to 233 has been addapted according to the instructions and actual code provided by Smart Contract Programmer (2020) and Crypto Market Pool (n.d)*/

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
        } else if (!verify_signature(signature)) {
            revert("Invalid signature.");
        } else {
            lesse_signature = signature;
            activate_contract();
            return true;
        }
    }

    function verify_signature(bytes memory signature)
        public
        view
        returns (bool)
    {
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

    /*----------------------GETTER functions for the contract status, account balance of the contract, Lessee and Lessor----------------------*/
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

    /*--------------------------------------------------------Monthly payment transaction-----------------------------------------------------------------*/
    /*Remark: 
    - The Ethereum Protocol, does not have at the current moment a native way of auto-executing a transaction at a specific future point in time.
    - Thus, we used a simulation for the monthly payment
    - The first step of the simulation involves the lessee transferring the full amount of the cummulative monthly payments for the entire lease period to the contract balance.
    - In the second step, the smart contract will automatically transfer on a monthly basis the monthly lease payment to the lessor account.*/
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

    function transfer_monthly_lease_payment() public payable {
        lessor.transfer(monthly_payment());
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

    /*---------------------------------------Apply penalty function for exceeding the total miles limit--------------------*/

    function set_penalty_per_mile(uint256 _penalty_per_mile) public {
        penalty_per_mile = _penalty_per_mile * 1 wei;
    }

    function get_penalty_per_mile() public view returns (uint256) {
        return penalty_per_mile;
    }

    function total_miles_allowed() public returns (uint256) {
        total_miles_limit =
            lease_conditions.monthly_miles_limit *
            lease_conditions.lease_duration_in_months;
        return total_miles_limit;
    }

    function add_actual_monthly_miles_used(uint256 _actual_monthly_miles)
        public
    {
        int256 miles_difference = int256(
            _actual_monthly_miles - lease_conditions.monthly_miles_limit
        );
        monthly_miles_usage_tracker.push(miles_difference);
    }

    function get_monthly_miles_usage_tracker()
        public
        view
        returns (int256[] memory)
    {
        return monthly_miles_usage_tracker;
    }

    function reset_monthly_miles_usage_tracker()
        public
        only_lessor
        returns (int256[] memory)
    {
        delete monthly_miles_usage_tracker;
        return monthly_miles_usage_tracker;
    }

    function get_penalty_to_be_paid() public view returns (uint256) {
        int256 cumulative_miles_usage = 0;
        for (uint256 i = 0; i < monthly_miles_usage_tracker.length; i++) {
            cumulative_miles_usage =
                cumulative_miles_usage +
                monthly_miles_usage_tracker[i];
        }
        uint256 penalty_to_be_paid;
        if (cumulative_miles_usage > 0) {
            penalty_to_be_paid =
                uint256(cumulative_miles_usage) *
                get_penalty_per_mile();
        }
        return penalty_to_be_paid;
    }

    function pay_penalty() public payable only_lessee returns (bool) {
        if (get_penalty_to_be_paid() <= 0) {
            revert("Dear Lessee, luckily, no penalty must be paid!");
        } else if (msg.value != get_penalty_to_be_paid()) {
            revert("Dear Lessee, you must pay the exact amount of the penalty");
        } else if (get_penalty_to_be_paid() > 0) {
            msg.value == get_penalty_to_be_paid();
            transfer_money_to_lessor(get_penalty_to_be_paid());
            penalties_have_been_paid = true;
            return penalties_have_been_paid;
        }
    }

    /*----------------------------Call Option execution at the termination of an closed-end lease------------------------------s---*/

    function get_car_owner() public view returns (address) {
        return car_owner;
    }

    function set_call_option_parameters(
        uint256 _call_option_price,
        uint256 _spot_price
    ) public only_lessor {
        if (lease_conditions.buy_option == true) {
            call_option_price = _call_option_price;
            spot_price = _spot_price;
            strike_price = lease_conditions.residual_value;
        } else {
            revert("No call_option was pre-defined in the leasing conditions!");
        }
    }

    function pay_option_price() public payable only_lessee returns (bool) {
        if (lease_conditions.buy_option == true) {
            require(
                msg.value == call_option_price,
                "Dear lesee, you must pay the exact call option price!"
            );
            transfer_money_to_lessor(call_option_price);
        }
        option_price_paid = true;
        return option_price_paid;
    }

    function check_option_worthiness() public view only_lessee returns (bool) {
        if (strike_price + call_option_price > spot_price) {
            return false;
        } else {
            return true;
        }
    }

    function exercise_call_option() public payable only_lessee returns (bool) {
        if (lease_conditions.buy_option == false) {
            revert(
                "Dear Lesee, the leasing predefined conditions do not allow for a call option exercise"
            );
        } else if (check_option_worthiness() == false) {
            revert("Dear Lesse, the option is not worth exercising");
        } else {
            require(
                msg.value == strike_price,
                "Dear Lesse, you must pay the full strike price"
            );
            transfer_money_to_lessor(strike_price);
            car_owner = lessee;
            call_option_has_been_exercised = true;
            return call_option_has_been_exercised;
        }
    }

    //*--------------------------------------Terminate the contract---------------------------------------------*

    function refund_security_deposit()
        public
        payable
        only_lessor
        returns (bool)
    {
        if (penalties_have_been_paid == true) {
            require(
                msg.value == lease_conditions.security_deposit,
                "Dear Lessor, if all the conditions have been fulfilled by the lesee, please return the full security deposit. Otherwise, provide the reasons for the partial refund"
            );
            lessee.transfer(lease_conditions.security_deposit);
            security_deposit_has_been_refunded = true;
            return security_deposit_has_been_refunded;
        } else if (
            get_penalty_to_be_paid() < lease_conditions.security_deposit
        ) {
            uint256 partial_security_deposit_refund = lease_conditions
                .security_deposit - get_penalty_to_be_paid();
            lessee.transfer(partial_security_deposit_refund);
            security_deposit_has_been_refunded = true;
            return security_deposit_has_been_refunded;
        } else if (
            get_penalty_to_be_paid() == lease_conditions.security_deposit
        ) {
            security_deposit_has_been_refunded = true;
            return security_deposit_has_been_refunded;
        } else {
            revert(
                "There are still pending penalties that must be paid. The security deposit is not enough to cover this penalties!"
            );
        }
    }

    function terminate_contract() public only_lessor returns (CONTRACT_STATUS) {
        if (security_deposit_has_been_refunded == true) {
            status = CONTRACT_STATUS.TERMINATED;
        }
        return status;
    }
}