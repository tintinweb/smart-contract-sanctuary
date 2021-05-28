/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.4.24;

contract game{
    event win(address);
    function get_Random() public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now, blockhash(block.number-1)));
        return uint(random) % 1000;
    }
    
    function play() public payable{
        require(msg.value == 2 ether);
        if(get_Random() >= 500){
            msg.sender.transfer(4 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 20 ether);
    }
    
    constructor () public payable{
        require(msg.value == 20 ether);
    }
    
}