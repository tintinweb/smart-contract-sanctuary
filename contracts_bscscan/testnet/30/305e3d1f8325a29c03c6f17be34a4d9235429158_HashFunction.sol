/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract HashFunction {
    
    mapping(address => string) userSalt;
    mapping(address => bytes32) userHash;
    
    uint256 public sentvalue;
    bytes32 public hashvalue;
    
    function hash() payable public returns (bool) {
        sentvalue = msg.value;
        address _user = msg.sender;
        string storage _salt = userSalt[_user];
        
        hashvalue = keccak256(abi.encodePacked(sentvalue, _user, _salt));
        //userHash[_user] = x;
        return true;
    }
    
    function hash2(uint256 _amount) payable public returns (bool) {
        address _user = msg.sender;
        string storage _salt = userSalt[_user];
        
        hashvalue = keccak256(abi.encodePacked(_amount, _user, _salt));
        return true;
    }

    // Example of hash collision
    // Hash collision can occur when you pass more than one dynamic data type
    // to abi.encodePacked. In such case, you should use abi.encode instead.
    function getHash(address _user) public view returns (bytes32)
    {
        return userHash[_user];
    }
    
    function getSalt(address _user) public view returns (string memory)
    {
        return userSalt[_user];
    }
    
    function setSalt(string memory  _salt) public returns(bool)
    {
        userSalt[msg.sender]  = _salt;
        
        return true;
    }
    
    function hash(string memory _data) public  pure  returns (bytes32) {
        return keccak256(abi.encodePacked(_data));
    }
}