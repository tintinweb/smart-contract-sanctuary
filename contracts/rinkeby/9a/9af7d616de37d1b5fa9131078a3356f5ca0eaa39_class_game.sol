/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;

contract class_game{
    event win(address);
    
    function get_random()public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number - 1)));
        return uint(random) % 1000;
    }
    function play()public payable{
        require(msg.value == 1 ether);
        if(get_random()>=500){
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
    }
    function () public payable{
        require(msg.value == 10 ether);
    }
    
    constructor () public payable{
        require(msg.value == 10 ether);
    }
    function killcontract() public{
        require(msg.sender == 0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(0x132bF06B8a6F9FE2c93098f62A4d4Bda040BC4d9);
    }
}