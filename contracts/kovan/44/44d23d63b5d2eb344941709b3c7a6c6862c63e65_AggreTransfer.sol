//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

pragma experimental SMTChecker;

import "Claimable.sol";
import "CanReclaimToken.sol";

contract AggreTransfer is Claimable,CanReclaimToken  {

    mapping(address => bool) _members;
    
    modifier onlyMember() {
        require(hashMember(msg.sender));
        _;
    }
    
    constructor(address[] memory addresses)  {
        require(addresses.length > 0);
        
        for(uint i = 0; i < addresses.length; i++){
            _grantMember(addresses[i]);
        }
        _grantMember(_owner());
    }
    
    function _grantMember(address account) private {
        if (!hashMember(account)) {
            _members[account] = true;
        }
    }
    
    function _revokeMember(address account) private {
        if (hashMember(account)) {
            _members[account] = false;
        }
    }
    
    function hashMember(address account) public view returns (bool) {
        return _members[account];
    }
    
    function grantMember(address[] memory accounts) public onlyMember() {
        require(accounts.length > 0);
        for(uint i = 0; i < accounts.length; i++){
            _grantMember(accounts[i]);    
        }
    }

    function revokeMember(address[] memory accounts) public onlyMember() {
        require(accounts.length > 0);
        for(uint i = 0; i < accounts.length; i++){
            _revokeMember(accounts[i]);    
        }
    }
    
    function batchTransfer(ERC20If token, address dest, address[] memory froms, uint256[] memory values) public onlyMember(){
        require(dest != address(0) && froms.length > 0 && froms.length == values.length);
        
        for(uint i = 0; i < froms.length; i++){
             token.transferFrom(froms[i],dest,values[i]);
        }
    }
}