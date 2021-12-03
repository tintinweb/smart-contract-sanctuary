// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./BlacklistRole.sol";

pragma solidity ^0.6.12;

contract Blacklist is Ownable, BlacklistRole {
        
    address otherContract;    
    mapping(address => bool) blacklist;
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    modifier onlyBlacklisted() {
        require(isBlacklisted(msg.sender));
        _;
    }

    modifier onlyOtherContract() {
        require(msg.sender == otherContract);
        _;
    }

    /**
     * @dev add address to the Blacklist.
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function addToBlacklist(address _address) public onlyBlacklister {
        blacklist[_address] = true;
        emit AddedToBlacklist(_address);
    }

    /**
     * @dev Remove address from Blacklist.
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function removeFromBlacklist(address _address) public onlyBlacklister {
        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    /**
     * @dev Returns address is Blacklist true or false
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function isBlacklisted(address _address) public onlyOtherContract view returns(bool) {
        return blacklist[_address];
    }

    /**
     * @dev add address to the onlyOtherContract role.
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function setOtherContract(address _otherContract) public onlyOwner {
        otherContract = _otherContract;
    }
}