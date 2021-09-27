/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

pragma solidity ^0.8.3;


contract Lottery {
    
    uint public paidAmount;
    uint endTime = 1632690520;
    
    constructor() {
        paidAmount = 0;
    }
    
    function pay() public payable {
        paidAmount = msg.value;
    }
    
    function mintNFT(uint numOfNFTs) public payable {
        require(numOfNFTs > 10, "Mint more than 10 gipsy!");
        require(msg.value > 500, "Poor little boy...");
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