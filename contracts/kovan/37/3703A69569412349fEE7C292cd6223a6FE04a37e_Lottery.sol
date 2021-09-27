/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.3;


contract Lottery {
    
    uint public paidAmount;
    uint endTime = 1632690520;
    uint public mintedAt;
    
    constructor() {
        paidAmount = 0;
    }
    
    function pay() public payable {
        paidAmount = msg.value;
    }
    
    function mintNFT(uint numOfNFTs) public payable {
        mintedAt = block.timestamp;
    }
    
    function balance() public view returns(uint){
        return address(this).balance;
    }
    
    function checkAndPay() public payable {
        require(endTime <= block.timestamp, 'Too early');
    }
    
    function getTime() public view returns(uint){
        return block.timestamp;
    }
    
}