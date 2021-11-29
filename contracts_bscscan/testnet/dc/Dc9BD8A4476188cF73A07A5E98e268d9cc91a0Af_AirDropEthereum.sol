/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

contract AirDropEthereum{

    using SafeMath for uint256;
    address public owner;
    address payable[10] public recipients;
    uint256 public percentage;

    modifier onlyOwner() {
        require (msg.sender == owner,"You're not contract owner!");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    
    function DepositEtherInSmartContract() public payable{}
    function setRecipients(address payable[10] calldata _recipients) public onlyOwner{
        recipients=_recipients;
    }

    function setPercantage(uint256 _percentage) public onlyOwner{
        percentage=_percentage;
    }

    function transferEther() public onlyOwner returns(bool){
        require(contractBalance()> 0,"Contract hasn't enough ethers to transfer!");
        uint256 calculatedEthereum=(contractBalance().mul(percentage)).div(100);
        for(uint256 i=0;i<recipients.length;i++){
            recipients[i].transfer(calculatedEthereum);
        }
        return true;
    }
    
    function contractBalance() public view returns(uint256){
        return address(this).balance;
    }
}