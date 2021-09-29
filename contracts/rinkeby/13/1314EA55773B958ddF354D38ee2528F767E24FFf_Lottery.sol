/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity ^0.8.3;


contract Lottery {
    
    uint public paidAmount;
    uint endTime = 1632909720;
    uint public mintedAt;
    address public owner = 0xB600F86E73Fd50FaA5BE6b2A5bCC2B76382f99B1;
    
    constructor() {
        paidAmount = 0;
    }
    
    function pay() public payable {
        paidAmount = msg.value;
    }
    
    
    function mintNFT(uint numOfNFTs) public payable {
        require(endTime <= block.timestamp, 'Too early');
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