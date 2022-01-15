/**
 * @title Dont Trigger Role
 * @dev DontTriggerRole contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/


import "./Ownable.sol";

pragma solidity ^0.6.12;

contract DontTrigger is Ownable {
    
    mapping(address => bool) dontTrigger;
    event AddedToDontTrigger(address indexed account);
    event RemovedFromDontTrigger(address indexed account);

    modifier onlyDontTrigger() {
        require(isDontTrigger(msg.sender));
        _;
    }

    /**
     * @dev add address to the DontTrigger.
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function addToDontTrigger(address _address) public onlyOwner {
        dontTrigger[_address] = true;
        emit AddedToDontTrigger(_address);
    }

    /**
     * @dev Remove address from DontTrigger.
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function removeFromDontTrigger(address _address) public onlyOwner {
        dontTrigger[_address] = false;
        emit RemovedFromDontTrigger(_address);
    }

    /**
     * @dev Returns address is DontTrigger true or false
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function isDontTrigger(address _address) public view returns(bool) {
        return dontTrigger[_address];
    }
}