/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;

contract game{
    event win(address);
    
    function get_random() public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(random) % 100;
    }
    
    function play(uint guess) public payable {
        require(msg.value == 0.01 ether);
        if(get_random()==guess){
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
    
    address owner=0xbF788b242FdcCeb19c47703dd4A346971807B315;
    
    function querybalance() public view returns(uint){
        return address(this).balance;
    }
    
    function killcontract() public{
        require(msg.sender == owner);
        selfdestruct(0x189b76D349054CCca252A58c538BE175C7A6f948);
    }
}