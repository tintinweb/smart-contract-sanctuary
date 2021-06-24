/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;

contract number{
    
    event win(address);
    function get_random() public view returns(uint){
        bytes32 ran = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ran) % 3;
    }
    
    function play(uint guess) public payable{
        
        require(msg.value == 0.1 ether);
        
        if(get_random() == guess){
            msg.sender.transfer(0.3 ether);
            emit win(msg.sender);
        }
    }
    
    function ()public payable{
        require(msg.value == 1 ether);
    }
    
    constructor () public payable{
        require(msg.value == 1 ether);
    }
}