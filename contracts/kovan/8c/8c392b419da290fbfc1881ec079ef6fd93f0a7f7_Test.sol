/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Moopig Developer

contract Test {
    uint256 coin; 
    address admin;
    mapping(address => string) public member;
    mapping(address => uint256) public balance;
    
    event Puy(uint256 coind);
    
    constructor(uint256 initialCoin, address adminAddress) {
        coin = initialCoin;
        admin = adminAddress;
    }
    
    function newRegis(string memory nameInput) public {
            member[msg.sender] =  nameInput;
            balance[msg.sender] = 200;
            emit Puy(coin);
    }
    
    function tranferCoin(address send , uint256 amount) external payable {
        
    }
}