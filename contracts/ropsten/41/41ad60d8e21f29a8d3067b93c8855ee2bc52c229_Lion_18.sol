/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

//Jinseon Moon
pragma solidity 0.8.0;


contract Lion_18 {
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    address public owner;
    uint balance;
    uint count = 0;
    
    function setOwner() public {
        owner = msg.sender;
    }
    
    function withdraw_100() public onlyOwner payable {
        require(msg.value == 100);
        balance += 100;
    }
    
    function withdraw_200() public onlyOwner payable {
        require(msg.value == 200);
        balance += msg.value;
    }
    
    function withdraw_500() public onlyOwner payable {
        require(msg.value == 500);
        balance += msg.value;
    }
    
    function withdraw_1000() public onlyOwner payable {
        require(msg.value == 1000 && count <= 5);
        balance += msg.value;
        count++;
    }
    
    function withdraw() public onlyOwner payable {
        require(msg.value > 7500);
        balance += msg.value;
    }
    
    
}