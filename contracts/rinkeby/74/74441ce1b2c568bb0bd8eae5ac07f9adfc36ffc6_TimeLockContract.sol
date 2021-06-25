/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Timelock Contracts (TLCs) on Ethereum ETH.
 *
 * This contract provides a way to create and keep TLCs for ETH.
 *
 * Protocol:
 *
 * (1) newFundsContract(receiver, locktime) - a sender calls this to createa new TLC(1 year lock-in period) 
 *      and gets back a 32 byte contract id
 * 
 * (2) withdraw(contractId) - once the lock-in period is over , 
 *      the receiver can claim the ETH with this function
 * 
 *  (3) refund() - before the end of the timelock ,the sender / creator of the TLC can get their ETH
 *      back with this function.
 * 
 *  locktime(Unix Timestamp): 
 *      1 hour	3600 seconds
 *      1 day	86400 seconds
 *      1 year (365.24 days) 	 31556926 seconds
 */
contract TimeLockContract {

    event LockContractNew(
        bytes32 indexed contractId,
        address indexed sender,
        address indexed receiver,
        uint amount,
        uint timelock
        );

    event LockContractWithdraw(
        bytes32 indexed contractId
        );
    
    event LockContractRefund(
        bytes32 indexed contractId
        );

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
    
    modifier contractExists(bytes32 _contractId) {
        require(haveContract(_contractId), "Contract ID does not exist");
        _;
    }

    modifier withdrawable(bytes32 _contractId) {
        require(contracts[_contractId].receiver == msg.sender, "Withdrawable: Not receiver Contract ID");
        require(contracts[_contractId].withdrawn == false, "Withdrawable: Funds were already withdrew");
        require(contracts[_contractId].timelock <= block.timestamp, "Withdrawable: Timelock time must be in the future");
        _;
    }
    
    modifier refundable(bytes32 _contractId) {
        require(contracts[_contractId].sender == msg.sender, "Refundable: not sender");
        require(contracts[_contractId].refunded == false, "Refundable: Funds were already refunded");
        require(contracts[_contractId].withdrawn == false, "Refundable: Funds were already withdrew");
        require(contracts[_contractId].timelock > block.timestamp, "Invalidation Timelock");
        _;
    }

    mapping (bytes32 => LockContract) contracts;

    function newFundsContract(address payable _receiver, uint locktime)
        external
        payable
        fundsSent
        returns (bytes32 contractId)
    {
        contractId = sha256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                msg.value,
                block.timestamp + locktime 
            )
        );

        if (haveContract(contractId))
            revert("Contract ID already exists");

        contracts[contractId] = LockContract(
            payable(msg.sender),
            _receiver,
            msg.value,
            block.timestamp + locktime,
            false,
            false
        );
        
        emit LockContractNew(
            contractId,
            msg.sender,
            _receiver,
            msg.value,
            block.timestamp + locktime
            );
        
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
        emit LockContractWithdraw(_contractId);
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
        emit LockContractRefund(_contractId);
        return true;
    }

    function getContractInfo(bytes32 _contractId)
        public
        view
        returns (
            address sender,
            address receiver,
            uint amount,
            uint timelock,
            bool withdrawn,
            bool refunded
        )
    {
        if (haveContract(_contractId) == false)
            return (address(0), address(0), 0, 0, false, false);
        LockContract storage c = contracts[_contractId];
        return (
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