/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;

contract Game {
    
    event win(address);
    
    function get_random() public view returns(uint) {
        bytes32 random = keccak256(abi.encodePacked(now, blockhash(block.number-1)));
        return uint(random) % 1000;
    }
    
    function play() public payable {
        require(msg.value == 1 ether);
        if(get_random() >= 500) {
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable {
        require(msg.value == 3 ether);
    }
    
    constructor () public payable {
        require(msg.value == 3 ether);
    }
    
    function Killcontract() public {
        require(msg.sender == 0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(0x786B753cE867E0f6aE81d7Bff6D0cD392A9AeA93);
    }
}