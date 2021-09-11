/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

pragma solidity ^0.6.4;

contract corebank{ 
    mapping (address => uint256) public balance;
    mapping (address => uint256) public balance2;
    address[] account;
    address[] account2;
    
    
    address public owner;
    // interest rate;
    uint256 rate = 3;
    uint256 rate2 = 5;
    
    constructor() public{
       owner =  msg.sender;
    }
    
    
    
    function lenderamount() public payable returns(uint256){
        if(0 == balance[msg.sender]){
            account.push(msg.sender);
        }
        balance[msg.sender] += msg.value*(100+rate)/100;
        
        return balance[msg.sender];
    }
    
    
    
    function lenderwithdraw(uint256 amountc) public returns(uint256){
      require(balance[msg.sender]>= amountc," amount not enough");
      balance[msg.sender] -= amountc;
      msg.sender.transfer(amountc);    
      return balance[msg.sender];
    }
    
    
    
    function systembalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function systemwithdraw(uint256 withdrawamount) public returns(uint256){
        require(owner == msg.sender ," you are not owner");
        require(withdrawamount <= systembalance(), "amount is not enough");
        msg.sender.transfer(withdrawamount);
        
    }
    
      function systemwithdep() public payable returns(uint256){
        require(owner == msg.sender ," you are not owner");
        return systembalance();
         
    }
    
    
    /////
    
    
    
    function borrowamount(uint256 borrowwithdrawamount) public returns(uint256){
        balance2[msg.sender] = borrowwithdrawamount;
        borrowwithdrawamount = borrowwithdrawamount-borrowwithdrawamount*(100-rate2)/100;
        msg.sender.transfer(borrowwithdrawamount);
        
    }
    
    
    
        function borrowpayback() public payable returns(uint256){
        require(balance2[msg.sender]== msg.value, "amount is not correct");
        balance2[msg.sender] -= msg.value;
        return balance2[msg.sender];
    }
    
    /////////
    function calint(address user, uint256 _rate) public view returns(uint256){
        uint256 interest =  balance[user]*_rate/100;
        return interest;
        
    }
    
       function paydividend() public payable{
       require(owner == msg.sender ," you are not owner"); 
       uint256 totalint = 0;
       for (uint256 i = 0; i< account.length; i++){
           address accountx = account[i];
           uint256 interest = calint(accountx,rate);
           balance[accountx] += interest;
           totalint += interest;
       }
       
       
       
       require(msg.value == totalint," can not pay" ); 
       
    }
    
    
}