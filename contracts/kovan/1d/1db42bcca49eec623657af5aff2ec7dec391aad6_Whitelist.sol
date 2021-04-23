/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;
    
contract Whitelist {
    
    address public owner;
    uint public totalWhitelisted;
    uint public totalMinimum;
    
    struct User {
        bool isWhitelisted;
        uint minimum;
    }
    
    mapping(address => User) private _users;
    
    event NewWhitelist(address user, uint minimumEntry);
    
    constructor(address _owner) {
        owner = _owner;
    }
    
    modifier onlyOwner() {
        
        require(msg.sender == owner, "only owner can do this");
        _;
    }
    
    function _whitelist(address _user, uint _minEntry) internal {
        
        User storage user = _users[_user];
        user.isWhitelisted = true;
        user.minimum = _minEntry;
        
        totalWhitelisted++;
        totalMinimum + _minEntry;
        
        emit NewWhitelist(_user, _minEntry);
    }
    
    function batchWhitelist(address[] memory _user, uint[] memory _minEntry) external onlyOwner returns(bool) {
        
        require(_user.length == _minEntry.length, "user and min entry must have the same length");
        
        for (uint i = 0; i < _user.length; i++) {
            require(!_users[_user[i]].isWhitelisted, "user already whitelisted"); 
            _whitelist(_user[i], _minEntry[i]);
        }
        return true;
    }
    
    function whitelist(address _user, uint _minEntry) external onlyOwner returns(bool){
        
        require(!_users[_user].isWhitelisted, "user already whitelisted");
        
        _whitelist(_user, _minEntry);
        return true;
    }
    
    function isWhitelisted(address _user) external view returns(bool) {
        
        return _users[_user].isWhitelisted == true;
    }
    
    function getMinimum(address _user) external view returns(uint) {
        
        return _users[_user].minimum;
    }

}