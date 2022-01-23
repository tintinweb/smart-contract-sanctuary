/**
 * @title Zero Fee
 * @dev ZeroFee contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 *
 **/

import "./Ownable.sol";

pragma solidity ^0.6.12;

contract ZeroFee is Ownable {
    
    mapping(address => bool) zeroFeeSender;
    event AddedToZeroFeeSender(address indexed account);
    event RemovedFromZeroFeeSender(address indexed account);

    modifier onlyZeroFeeSender() {
        require(isZeroFeeSender(msg.sender));
        _;
    }

    /**
     * @dev add address to the ZeroFee (set address to true).
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function addToZeroFeeSender(address _address) public onlyOwner {
        zeroFeeSender[_address] = true;
        emit AddedToZeroFeeSender(_address);
    }

    /**
     * @dev Remove address from ZeroFee (set address to false).
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function removeFromZeroFeeSender(address _address) public onlyOwner {
        zeroFeeSender[_address] = false;
        emit RemovedFromZeroFeeSender(_address);
    }

    /**
     * @dev Returns address is ZeroFee true or false
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function isZeroFeeSender(address _address) public view returns(bool) {
        return zeroFeeSender[_address];
    }

    mapping(address => bool) zeroFeeRecipient;
    event AddedToZeroFeeRecipient(address indexed account);
    event RemovedFromZeroFeeRecipient(address indexed account);

    modifier onlyZeroFeeRecipient() {
        require(isZeroFeeRecipient(msg.sender));
        _;
    }

    /**
     * @dev add address to the ZeroFee (set address to true).
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function addToZeroFeeRecipient(address _address) public onlyOwner {
        zeroFeeRecipient[_address] = true;
        emit AddedToZeroFeeRecipient(_address);
    }

    /**
     * @dev Remove address from ZeroFee (set address to false).
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function removeFromZeroFeeRecipient(address _address) public onlyOwner {
        zeroFeeRecipient[_address] = false;
        emit RemovedFromZeroFeeRecipient(_address);
    }

    /**
     * @dev Returns address is ZeroFee true or false
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function isZeroFeeRecipient(address _address) public view returns(bool) {
        return zeroFeeRecipient[_address];
    }
}