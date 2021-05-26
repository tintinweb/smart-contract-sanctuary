/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;
contract Game{
    
    event win(address);
    
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon) % 1000;
    }
    
    function play() public payable {
        require(msg.value == 0.01 ether);
        if(get_random()>=500){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable {
        require(msg.value == 1 ether);
    }
    address owner;
    constructor () public payable {
        require(msg.value == 1 ether);
        owner = msg.sender;
    }
    
    function querybalance() public view returns(uint){
        return address(this).balance;
    }
    //合約自毀
    function killcontract() public{
        require(msg.sender==owner);
        selfdestruct(0xbF788b242FdcCeb19c47703dd4A346971807B315);
        
    }
}