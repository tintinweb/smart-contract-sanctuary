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
        
    event LockContractDestroyAll(
        bytes32 indexed contractId
        );
        
    event Termination(
        bytes32 indexed contractId
        );

    struct LockContract {
        address payable sender;
        address payable receiver;
        uint amount;
        uint timelock;
        bool withdrawn;
        bool refunded;
        bool destroyAll;
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

    /**
     * @dev Sender sets up a new time lock contract depositing the ETH and
     * providing the reciever lock terms.
     *
     * @param _receiver Receiver of the ETH.
     * @param locktime UNIX epoch seconds time, the lock-in period time .
     *                  withdrew can be made until the end of the lock-in period time.
     *                  Refunds can be made before the end of the lock-in period time.
     */
    function newFundsContract(address payable _receiver, uint locktime, bool destroyAll)
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

        if (haveContract(contractId)){
            revert("Contract ID already exists");
        }
            
        contracts[contractId] = LockContract(
            payable(msg.sender),
            _receiver,
            msg.value,
            block.timestamp + locktime,
            false,
            false,
            destroyAll
        );
        
        emit LockContractNew(
            contractId,
            msg.sender,
            _receiver,
            msg.value,
            block.timestamp + locktime
            );
        
        if(destroyAll == true){
            emit LockContractDestroyAll(
                contractId
                );
        }
        
    }

    /**
     * @dev Called by the receiver once the the lock-in period time was over.
     * This will transfer the locked funds to their address.
     *
     * @param _contractId Id of the TLC.
     * @return bool true on success
     */
    function withdraw(bytes32 _contractId)
        external
        contractExists(_contractId)
        withdrawable(_contractId)
        returns (bool)
    {
        LockContract storage c = contracts[_contractId];
        c.withdrawn = true;
        if(c.destroyAll == true){
            emit Termination(_contractId);
            collectAllandDestroy(c.receiver);
        }
        else{
            c.receiver.transfer(c.amount);
            emit LockContractWithdraw(_contractId);
        }
        return true;
    }

    /**
     * @dev Called by the sender before the end of the lock-in period time.
     * This will refund the contract amount.
     *
     * @param _contractId Id of TLC to refund from.
     * @return bool true on success
     */
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

    /**
     * @dev Get contract details.
     * @param _contractId TLC contract id
     */
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
        if (haveContract(_contractId) == false){
            return (address(0), address(0), 0, 0, false, false);
        }
            
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

    /**
     * @dev Called by the receiver if the LockContract.destroyAll is true
     * This will selfdestruct the contract and sned the rest of the funds to the receiver.
     *
     * @param _address Address of the receiver.
     */
    function collectAllandDestroy(address _address) 
        internal
    {
        selfdestruct(payable(_address));
    }
    
    /**
     * @dev Is there a contract with id _contractId.
     * @param _contractId Id into contracts mapping.
     */
    function haveContract(bytes32 _contractId)
        internal
        view
        returns (bool exists)
    {
        exists = (contracts[_contractId].sender != address(0));
    }

}