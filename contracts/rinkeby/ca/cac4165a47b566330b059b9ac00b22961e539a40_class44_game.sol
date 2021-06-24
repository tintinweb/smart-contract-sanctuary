/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;

contract class44_game{
    event win(address);
    uint num;
    uint roletype;
    function get_random() public view returns(uint){
        bytes32 ramdom = keccak256(abi.encodePacked(now, blockhash(block.number-1)));
        return uint(ramdom)% 10;
    }
    
    function play(uint a) public payable{
        require(msg.value == 0.01 ether);
        if(get_random()==a){
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
}