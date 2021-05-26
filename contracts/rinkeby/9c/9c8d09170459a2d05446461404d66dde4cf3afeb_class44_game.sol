/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;

contract class44_game{
    event win(address);
    address owner;
    
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon)%1000;
    }
    
    function play() public payable{
        require(msg.value == 1 ether);
        if(get_random()>=500){
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
    }
    function()public payable{
        require(msg.value == 2 ether);
    }
    
    function killcontract()public{
        require(msg.sender==owner);
        selfdestruct(0xEe8C72DC3660405Ba9d209A03Bcb93C7602BE773);
    }
    
    constructor()public payable{
        owner=0xbF788b242FdcCeb19c47703dd4A346971807B315;
        require(msg.value == 2 ether);
    }
}