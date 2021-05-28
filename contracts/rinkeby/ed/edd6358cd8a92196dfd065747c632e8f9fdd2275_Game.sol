/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.4.24;

contract Game{
    
    event win(address);
    
    function get_random() public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(random) % 1000;
    }
    
    function play() public payable{
        require(msg.value == 1 ether);
        if(get_random()>=500){
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
    }
    address owner;
    
    function () public payable{
        require(msg.value == 10 ether);
        owner = msg.sender;
    }
    
    constructor () public payable{
        require(msg.value == 10 ether);
    }
    
    function killcontract() public{
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}