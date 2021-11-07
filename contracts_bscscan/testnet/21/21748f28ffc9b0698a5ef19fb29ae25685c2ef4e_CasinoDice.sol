/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.7;




contract CasinoDice{
    
    constructor() public {
                owner = msg.sender;
    }
    
mapping(address => uint256) public balance;
    address public owner;
function deposit() public payable {
    balance[msg.sender] += msg.value;
    }
uint256 nonce = 0;
uint256 nonce1 = 20;
uint256 nonce2 = 895;
uint256 nonce3 = 34;
uint256 tnonce;
uint256 public roll;
uint256 lastroll = 0;
function withdraw(uint256 amount) payable public {
        require(balance[msg.sender] >= amount);
            msg.sender.transfer(amount);
            balance[msg.sender] -= amount;
    }
    
    

function play(uint256 amount) payable public {
        require(balance[owner] >= amount * 2);
        require(amount > 0 &&  balance[msg.sender] > 0);
        tnonce = uint(keccak256(abi.encodePacked(now, block.difficulty, msg.sender, nonce, balance[owner], balance[msg.sender], owner, lastroll))) % 101;
        roll = uint(keccak256(abi.encodePacked(now, block.difficulty, msg.sender, nonce, balance[owner], balance[msg.sender], owner, lastroll, tnonce))) % 101;
        lastroll = roll;
        nonce++;
        nonce1++;
        nonce2++;
        nonce3++;
        if(roll > 55) {
            balance[owner] -= amount;
            balance[msg.sender] += amount;
        }else {
            balance[owner] += amount;
            balance[msg.sender] -= amount;
        }
        
    }
    
    
}