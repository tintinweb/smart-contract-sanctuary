/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;

contract class44_game{
    event win(address);
    address owner;
    
    
    
    function get_random() public view returns(uint){
        bytes32 ramdom = keccak256(abi.encodePacked(now, blockhash(block.number-1)));
        return uint(ramdom) % 1000;
    }
    
    function play() public payable{
        require(msg.value == 0.01 ether);
        if(get_random()>=500){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 1 ether);
    }
    
    constructor () public payable{
        require(msg.value == 1 ether);
        owner = 0xbF788b242FdcCeb19c47703dd4A346971807B315;
        
    }
    
    function qyerybalance() public view returns(uint){
        return address(this).balance;
    } 
    
    function killcontract() public{
        require(msg.sender == owner);
        selfdestruct(0xDa212D2eE9BDcEA4032f65c531c42Fa85B0D55fA);
        
    }
    
}