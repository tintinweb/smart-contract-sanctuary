/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address owner) public {
        _owner = owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            isOwner(),
            "Only contract owner is allowed to perform this operation"
        );
        _;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.7.6;

contract ExecutorManager is Ownable {
    address[] internal executors;
    mapping(address => bool) internal executorStatus;

    event ExecutorAdded(address executor, address owner);
    event ExecutorRemoved(address executor, address owner);

    // MODIFIERS
    modifier onlyExecutor() {
        require(
            executorStatus[msg.sender],
            "You are not allowed to perform this operation"
        );
        _;
    }

    constructor(address owner) public Ownable(owner) {
        require( owner != address(0), "owner cannot be zero");
    }

    function getExecutorStatus(address executor)
        public
        view
        returns (bool status)
    {
        status = executorStatus[executor];
    }

    function getAllExecutors() public view returns (address[] memory) {
        return executors;
    }

    //Register new Executors
    function addExecutors(address[] calldata executorArray) external onlyOwner {
        for (uint256 i = 0; i < executorArray.length; i++) {
            addExecutor(executorArray[i]);
        }
    }

    // Register single executor
    function addExecutor(address executorAddress) public onlyOwner {
        require(executorAddress != address(0), "executor address can not be 0");
        executors.push(executorAddress);
        executorStatus[executorAddress] = true;
        emit ExecutorAdded(executorAddress, msg.sender);
    }

    //Remove registered Executors
    function removeExecutors(address[] calldata executorArray) external onlyOwner {
        for (uint256 i = 0; i < executorArray.length; i++) {
            removeExecutor(executorArray[i]);
        }
    }

    // Remove Register single executor
    function removeExecutor(address executorAddress) public onlyOwner {
        require(executorAddress != address(0), "executor address can not be 0");
        executorStatus[executorAddress] = false;
        emit ExecutorRemoved(executorAddress, msg.sender);
    }
}