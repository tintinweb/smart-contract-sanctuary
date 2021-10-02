/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract bnbMassTrans {
    
    address public owner;
    
    mapping(address => bool) public admin;
    event tran(address indexed addr, uint256 _amount);
    
    constructor () {
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
    
    receive() external payable {}
    
    function transfer_To_Multi_Wallet(address[] memory _user) public payable {
        require(admin[msg.sender] == true, "Caller is not an admin");
        
        for (uint256 i = 0; i < _user.length; i++) {
            address wallet = _user[i];
            uint256 amount = msg.value;
            // payable(address(owner))(owner, wallet, amount);
            payable(wallet).transfer(amount);
            emit tran(wallet, amount);
        }
    }
    
    function withdrawETH() public {
        require(admin[msg.sender] == true, "Caller is not an admin");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    
}