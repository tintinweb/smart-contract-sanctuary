/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract KNXMassTrans {
    
    IERC20 public knox;
    address public owner;
    uint256 public amount;
    
    mapping(address => bool) public admin;
    
    constructor (uint256 _amt, address knoxTokenAddr) {
        amount = _amt;
        knox = IERC20(knoxTokenAddr);
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
            knox.transferFrom(owner, wallet, amount);
        }
    }
    
    function setAmount(uint256 _newAmount) public {
        require(admin[msg.sender] == true, "Caller is not an admin");
        amount = _newAmount;
    }
}