/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;

contract class44_game{

    event win(address);
    
    
    function play(uint num) public payable{
        require (msg.value == 0.01 ether);
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        
        if(num == uint (ramdon) % 3){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
        
    }

    function () public payable{
        require(msg.value == 1 ether);
    }
    
    constructor () public payable{
        require(msg.value == 1 ether);
        
    }
    
    function querybalance() public view returns(uint) {
        return address(this).balance;
    }
    
    
}