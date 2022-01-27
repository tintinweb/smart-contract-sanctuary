/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Bank {

    address private admin;
    mapping(address => uint256) private accounts;
    uint256 cummulativeBal;

    constructor(){
        admin = msg.sender;
    }

    function deposit() external payable {
        accounts[msg.sender] += msg.value;
        cummulativeBal += msg.value;
    }

    function depositToAccount(address addr, uint256 amount) external {
       require(accounts[msg.sender] >= amount, "Low balance");
       accounts[msg.sender] -= amount;
       accounts[addr] += amount;
    }

    function withdraw(uint256 amount) external {
        require(accounts[msg.sender] > 0, "No funds available in the account");
		require(amount <= accounts[msg.sender], "Low balance");
        payable(msg.sender).transfer(amount);
		accounts[msg.sender] -= amount;
        cummulativeBal -= amount;
    }

    function withdrawAll() external {
        require(accounts[msg.sender] > 0, "No funds available in the account");
        payable(msg.sender).transfer(accounts[msg.sender]);
        cummulativeBal -= accounts[msg.sender];
		accounts[msg.sender] = 0;
    }

    function balance() external view returns (uint256 bal) {
        bal =  accounts[msg.sender];
        return bal;
    }

    function balance(address addr) external view OwnerOrAdminOnly(addr) returns (uint256 bal) {
        bal =  accounts[addr];
        return bal;
    }

    modifier OwnerOrAdminOnly(address addr){
        require(msg.sender == addr || msg.sender == admin, "Only Owner or admin can check other accounts balance");
        _;
    }

    modifier AdminOnly(){
        require(msg.sender == admin, "Only admin can check total Assets");
        _;
    }

    function totalAssets() external view AdminOnly returns (uint256 bal){
        bal = cummulativeBal;
        return bal;
    }
}