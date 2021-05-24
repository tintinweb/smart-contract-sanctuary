/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_18 {
    uint balance = 0;
    uint count;
    modifier limit_5{
        require(count<5);
        _;
    }
    modifier total{
        require(balance<7500);
        _;
    }
    address public owner = msg.sender;
    
    modifier onlyOwner {
        require(msg.sender ==owner, "it is not owner");
        _;
    }  
    function pay_100() public total onlyOwner payable{
        if (msg.value==100) {
            balance += msg.value; 
        }
    }
        function pay_200() public total onlyOwner payable {
        if (msg.value==200) {
            balance += msg.value; 
        }
    }
        function pay_500() public total onlyOwner payable {
        if (msg.value==500) {
            balance += msg.value; 
        }
    }
        function pay_1000() public limit_5 total onlyOwner payable {
        if (msg.value==1000) {
            balance += msg.value; 
            count++;
        }

    }
        function pay_all() public total onlyOwner payable {
        balance += address(this).balance;
    }
        function getBalance() public view returns(uint){
        return balance;
    }
}