/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract rigelMassTrans {
    
    IERC20 public rigel;
    address public owner;
    uint256 public amount;
    
    mapping(address => bool) public admin;
    
    constructor (uint256 _amt, address rigelTokenAddr) {
        amount = _amt;
        rigel = IERC20(rigelTokenAddr);
        owner = msg.sender;
        admin[msg.sender] = true;
    }
    
    function addAdmin(address[] memory _admAddr) public {
        require(msg.sender == owner, "Only Owner can call this function");
        for (uint256 i = 0; i < _admAddr.length; i ++) {
            address _admin = _admAddr[i];
            admin[_admin] = true;
        }
    }
    
    function transfer_To_Multi_Wallet(address[] memory _user) public {
        require(admin[msg.sender] == true, "Caller is not an admin");
        for (uint256 i = 0; i < _user.length; i++) {
            address wallet = _user[i];
            rigel.transferFrom(owner, wallet, amount);
        }
    }
    
    function setAmount(uint256 _newAmount) public {
        require(admin[msg.sender] == true, "Caller is not an admin");
        amount = _newAmount;
    }
}