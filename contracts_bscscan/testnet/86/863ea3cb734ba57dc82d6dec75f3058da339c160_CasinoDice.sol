/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;



contract CasinoDice{
    constructor() {
                owner = msg.sender;
    }
    
mapping(address => uint256) internal balancee;
    address public owner;
function deposit() public payable {
    balancee[msg.sender] += msg.value;
    }
uint256 nonce = 0;
uint256 nonce1 = 20;
uint256 nonce2 = 895;
uint256 nonce3 = 34;
uint256 tnonce;
uint256 rolll;
uint256 lastroll = 0;
function withdraw(uint256 amount) public {
        require(balancee[msg.sender] >= amount);
        address payable sender = payable(msg.sender);
            sender.transfer(amount);
            balancee[msg.sender] -= amount;
    }
    
    function roll() view public returns(uint256) {
        return rolll;
    }

    function balance() view public returns(uint256) {
        return balancee[msg.sender];
    }
    
function play(uint256 amount) public returns(string memory){
        require(balancee[owner] >= amount * 2);
        require(amount > 0 &&  balancee[msg.sender] > 0);
        tnonce = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, nonce, balancee[owner], balancee[msg.sender], owner, lastroll))) % 101;
        rolll = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, nonce, balancee[owner], balancee[msg.sender], owner, lastroll, tnonce))) % 101;
        lastroll = rolll;
        nonce++;
        nonce1++;
        nonce2++;
        nonce3++;
        if(rolll > 55) {
            nonce++;
            nonce1++;
            balancee[owner] -= amount;
            balancee[msg.sender] += amount;
            roll();
            return "Won!";
            
        }else {
            nonce2++;
            nonce3++;
            balancee[owner] += amount;
            balancee[msg.sender] -= amount;
            roll();
            return "Lost!";
        }
        
    }
    
    
}