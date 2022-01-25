// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Profile {
   
    // if key value is true, then it's enabled
    mapping(string => bool) public keys;

    // only address can update mapping
    mapping(string => address) public authorized;

    mapping(address => mapping(string => string)) public profiles;

    address private admin;


    constructor() {
        admin = msg.sender;
    }

    function enableKey(string memory key, address _authorized) public returns(bool) {
        require(msg.sender == admin, "Only admin");
        keys[key] = true;
        authorized[key] = _authorized;
        return true;
    }

    function disableKey(string memory key) public returns(bool) {
        require(msg.sender == admin, "Only admin");
        keys[key] = false;
        return true;
    }

    function setKey(address _address, string memory key, string memory value) public returns(bool) {
        require(msg.sender == authorized[key], "Only authorized");
        profiles[_address][key] = value;
        return true;
    }

}