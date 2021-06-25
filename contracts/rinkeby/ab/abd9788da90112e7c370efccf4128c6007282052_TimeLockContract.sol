/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Protocol:
 *
 */
contract TimeLockContract {
    
    
    bytes32 contractId_;
    
    constructor() {
    }
    
    struct LockContract {
        address payable sender;
        address payable receiver;
        uint amount;
        uint timelock;
        bool withdrawn;
        bool refunded;
    }

    modifier fundsSent() {
        require(msg.value > 0, "Funds must be > 0");
        _;
    }
    
    modifier futureTimelock(uint _time) {
        require(_time > block.number, "Timelock time must be in the future");
        _;
    }
    
    modifier contractExists(bytes32 _contractId) {
        require(haveContract(_contractId), "Contract ID does not exist");
        _;
    }

    modifier withdrawable(bytes32 _contractId) {
        require(contracts[_contractId].receiver == msg.sender, "Withdrawable: Not receiver Contract ID");
        require(contracts[_contractId].withdrawn == false, "Withdrawable: Funds were already withdrew");
        require(contracts[_contractId].timelock > block.number, "Withdrawable: Timelock time must be in the future");
        _;
    }
    
    modifier refundable(bytes32 _contractId) {
        require(contracts[_contractId].sender == msg.sender, "Refundable: not sender");
        require(contracts[_contractId].refunded == false, "Refundable: Funds were already refunded");
        require(contracts[_contractId].withdrawn == false, "Refundable: Funds were already withdrew");
        require(contracts[_contractId].timelock <= block.number, "Timelock time must be in the future");
        _;
    }

    mapping (bytes32 => LockContract) contracts;
    mapping (address => bytes32) contractids;

    function newFundsContract(address payable _receiver, uint _timelock)
        external
        payable
        fundsSent
        futureTimelock(_timelock)
        returns (bytes32 contractId)
    {
        contractId = sha256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                msg.value,
                _timelock
            )
        );

        if (haveContract(contractId))
            revert("Contract ID already exists");

        contracts[contractId] = LockContract(
            payable(msg.sender),
            _receiver,
            msg.value,
            _timelock,
            false,
            false
        );
        
        contractids[msg.sender] = contractId;
        contractids[_receiver] = contractId;
        

    }

    function withdraw(bytes32 _contractId)
        external
        contractExists(_contractId)
        withdrawable(_contractId)
        returns (bool)
    {
        LockContract storage c = contracts[_contractId];
        c.withdrawn = true;
        c.receiver.transfer(c.amount);
        return true;
    }

    function refund(bytes32 _contractId)
        external
        contractExists(_contractId)
        refundable(_contractId)
        returns (bool)
    {
        LockContract storage c = contracts[_contractId];
        c.refunded = true;
        c.sender.transfer(c.amount);
        return true;
    }

    function getContractInfo(address _addressId)
        public
        view
        returns (
            bytes32 _contractId,
            address sender,
            address receiver,
            uint amount,
            uint timelock,
            bool withdrawn,
            bool refunded
        )
    {
        _contractId = contractids[_addressId];
        if (haveContract(_contractId) == false)
            return (0,address(0), address(0), 0, 0, false, false);
        LockContract storage c = contracts[_contractId];
        return (
            _contractId,
            c.sender,
            c.receiver,
            c.amount,
            c.timelock,
            c.withdrawn,
            c.refunded
        );
    }

    function haveContract(bytes32 _contractId)
        internal
        view
        returns (bool exists)
    {
        exists = (contracts[_contractId].sender != address(0));
    }

}