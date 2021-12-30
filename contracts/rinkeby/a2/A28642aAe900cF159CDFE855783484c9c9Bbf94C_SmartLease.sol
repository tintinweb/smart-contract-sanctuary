/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: SmartLease.sol

contract SmartLease {
    //------------------------------Declaring the CONTRACT VARIABLES-----------------------------------//

    //The address & address payable types store 160-bit Ethereum address.
    //The difference between the two is that the latter type(address payble) permits the following calls: .send(), .transfer(), .call()
    address lessor;
    address payable lessee;

    enum CONTRACT_STATUS {
        DEPLOYED,
        CREATED,
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

    Car leased_car;

    struct Leasing {
        uint256 lease_duration_in_months;
        uint256 lease_rate;
        uint256 full_retail_value;
        uint256 residual_value;
        uint256 total_cost_of_lease;
        uint256 depreciation_value;
        uint256 security_deposit;
        uint256 miles_limit;
        uint256 additional_fees;
        uint256 down_payment;
        bool buy_option;
        bool early_lease_termination_option;
        address early_termination_responsible;
    }

    Leasing public Lease_conditions;

    bytes public lesse_signature;

    CONTRACT_STATUS status = CONTRACT_STATUS.DEPLOYED;

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

    function get_car()
        public
        view
        returns (
            string memory,
            string memory,
            int256,
            CAR_CONDITION
        )
    {
        return (
            leased_car.VIN,
            leased_car.Car_model,
            leased_car.Car_product_year,
            leased_car.Car_condition
        );
    }

    //------------------------Setting  the conditions of the LEASE CONTRACT--------------------------------------//

    function set_leasing_conditions(
        uint256 _lease_duration_in_months,
        uint256 _lease_rate,
        uint256 _full_retail_value,
        uint256 _residual_value,
        uint256 _total_cost_of_lease,
        uint256 _miles_limit,
        uint256 _additional_fees,
        uint256 _down_payment,
        uint256 _security_deposit,
        bool _buy_option,
        bool _early_lease_termination_option
    ) public {
        Leasing memory _temp_leasing;

        Lease_conditions = _temp_leasing;

        Lease_conditions.lease_duration_in_months = _lease_duration_in_months;
        Lease_conditions.lease_rate = _lease_rate;
        Lease_conditions.full_retail_value = _full_retail_value;
        Lease_conditions.residual_value = _residual_value;
        Lease_conditions.total_cost_of_lease = _total_cost_of_lease;
        Lease_conditions.miles_limit = _miles_limit;
        Lease_conditions.additional_fees = _additional_fees;
        Lease_conditions.down_payment = _down_payment;
        Lease_conditions.security_deposit = _security_deposit;
        Lease_conditions.buy_option = _buy_option;
        Lease_conditions
            .early_lease_termination_option = _early_lease_termination_option;
        Lease_conditions.depreciation_value =
            Lease_conditions.full_retail_value -
            Lease_conditions.residual_value;
        Lease_conditions.early_termination_responsible = address(0);
    }

    function get_lease_duration_in_months() internal view returns (uint256) {
        return Lease_conditions.lease_duration_in_months;
    }

    function get_lease_rate() internal view returns (uint256) {
        return Lease_conditions.lease_rate;
    }

    function get_full_retail_value() internal view returns (uint256) {
        return Lease_conditions.full_retail_value;
    }

    function get_residual_value() internal view returns (uint256) {
        return Lease_conditions.residual_value;
    }

    function get_total_cost_of_lease() internal view returns (uint256) {
        return Lease_conditions.total_cost_of_lease;
    }

    function get_depreciation_value() internal view returns (uint256) {
        return Lease_conditions.depreciation_value;
    }

    function get_miles_limit() internal view returns (uint256) {
        return Lease_conditions.miles_limit;
    }

    function get_additional_fees() internal view returns (uint256) {
        return Lease_conditions.additional_fees;
    }

    function get_down_payment() internal view returns (uint256) {
        return Lease_conditions.down_payment;
    }

    function get_early_termination_responsible()
        internal
        view
        returns (address)
    {
        return Lease_conditions.early_termination_responsible;
    }

    //Important: The calculation logic below, will work only for countries where the taxes are demanded on monthly payment. Source: https://www.buerklehonda.com/financing/how-car-lease-payments-are-calculated///
    function monthly_payment(uint256 _tax_rate) public view returns (uint256) {
        uint256 monthly_depreciation = Lease_conditions.depreciation_value /
            Lease_conditions.lease_duration_in_months;
        uint256 monthly_finance_charge = Lease_conditions.depreciation_value /
            Lease_conditions.lease_rate;
        uint256 base_monthly_payment = monthly_depreciation +
            monthly_finance_charge;
        uint256 monthly_lease_payment = base_monthly_payment * (1 + _tax_rate);
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
        status = CONTRACT_STATUS.ACTIVE;
    }

    function sign_contract_lessee(bytes memory signature) public {
        if (!verify(signature)) {
            revert("Invalid signature.");
        } else {
            lesse_signature = signature;
            activate_contract();
        }
    }

    function verify(bytes memory signature) public view returns (bool) {
        return recover_signer(signature) == get_lessee();
    }

    function recover_signer(bytes memory _signature)
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

    function get_contract_status() public view returns (CONTRACT_STATUS) {
        return status;
    }

    /*----------------------Transforming EUR to ETH----------------------*/
}