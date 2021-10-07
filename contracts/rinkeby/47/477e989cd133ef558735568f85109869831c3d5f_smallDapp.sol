/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*遊戲只有一個合約
1.遊戲主合約裡面已經有一些賭本，每次下注只能收取 0.1 ETH - require
2.遊戲需要記錄，下注的人是誰？下注什麼(剪刀、石頭、布？) - 可以用兩個Mapping代表。
3.產生1~3的亂數，1代表剪刀，2代表石頭...。
4.再次判斷玩家是否贏錢。
*/

contract smallDapp {
    
    address public GameOwner;
    mapping (address => uint) players;//記錄玩家名單 (地址1.地址2.地址3....)
    mapping (uint => uint) pick;     //紀錄 1代表剪刀,2代表石頭,3代表布
    uint8 public scissors = 1;
    uint8 public rock = 2;
    uint8 public papper = 3;
    
    event win(address);
    event nothing(address);
    event lose(address);
    
    constructor() payable {
        GameOwner = payable(msg.sender);
        require(msg.value >= 1 ether);
    }
    
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1)));
        return uint(ramdon) % 3 +1;
    }
    
    function pickRock () public payable{
        require(msg.value == 0.1 ether);
        players[msg.sender] +=1;
        pick[rock] +=1;
        
        if(get_random() == scissors){
            payable(msg.sender).transfer(0.2 ether);
            emit win(msg.sender);
        }
        else if(get_random() == rock){
            payable(msg.sender).transfer(0.09 ether);
            emit nothing(msg.sender);
        }else{
            emit lose(msg.sender);
        }
    }
    
    function pickPapper () public payable{
        require(msg.value == 0.1 ether);
        players[msg.sender] +=1;
        pick[papper] +=1;
        
        if(get_random() == rock){
            payable(msg.sender).transfer(0.2 ether);
            emit win(msg.sender);
        }
        else if(get_random() == papper){
            payable(msg.sender).transfer(0.09 ether);
            emit nothing(msg.sender);
        }else{
            emit lose(msg.sender);
        }
    }
    
    function pickScissors () public payable{
        require(msg.value == 0.1 ether);
        players[msg.sender] +=1;
        pick[scissors] +=1;
        
        if(get_random() == papper){
            payable(msg.sender).transfer(0.2 ether);
            emit win(msg.sender);
        }
        else if(get_random() == scissors){
            payable(msg.sender).transfer(0.09 ether);
            emit nothing(msg.sender);
        }else{
            emit lose(msg.sender);
        }
    }
}