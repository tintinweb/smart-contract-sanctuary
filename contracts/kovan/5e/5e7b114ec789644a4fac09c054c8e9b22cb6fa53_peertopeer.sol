/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity ^0.5.0;

contract peertopeer{ 
    mapping (address => uint256)  balance;
    mapping (address => uint256)  balance2;
    mapping (address => uint256)  datecheck;
    mapping (address => uint256)  rateallow;
    uint256 interestpooling;
    mapping (address => uint256)  rateallow2;
    mapping (address => uint256)  amountallow;
    mapping (address => uint256)  amountallow2;
    mapping (address => address)  addressallow;
    mapping (address => address)  addressallow2;
    mapping (address => address)  transationhappen;
    mapping (address => uint256)  timestamp1;
    address[] account;
    address public owner = msg.sender;
    // interest rate;
    uint256 public rate = 5;
    constructor() public{
      owner =  msg.sender;
    }
    function depositforlending() public payable returns(uint256){
    if(0 == balance[msg.sender]){
        account.push(msg.sender);
          }
        balance[msg.sender] += msg.value;
        return balance[msg.sender];
    }
     function paymoney(uint value, address payable adds) payable public {
        balance[msg.sender] -= value;
        balance[adds] += value;
        adds.transfer(value);
    }
        function checkbalance(address adds)  public view returns(uint256){
        return balance[adds];
    }
    //////spare money
        function sparemoney(address addrx, uint amountx) public returns(bool){
        require(balance[msg.sender] >= amountx ," money enough");   
        require(amountx >= 100000," minimun is 100000");  
        addressallow[msg.sender] = addrx;
        addressallow[addrx] = msg.sender;
        amountallow[msg.sender] = amountx;
        amountallow[addrx] = amountx;
        rateallow[msg.sender] = 5;
        rateallow[addrx] = 5;
        datecheck[msg.sender] = now;
        return true;
     }
         function checkamountcanborrow(address addsr) public view returns(uint amountx,uint rata){
          amountx = 0;
          rata = 0;
          amountx = amountallow[addsr];
          rata = rateallow[addsr];
     }
     
     function borrowmoney(uint256 withdrawamount,address addsr1, address payable addsr2) public returns(uint256){
        //require(addressallow[addsr1] == addsr2, "not correct");
        require(withdrawamount == amountallow[addsr1], "amount is not enough");
        transationhappen[addsr2] = addsr1;
        timestamp1[addsr2] = now;
        balance2[addsr1] = withdrawamount;
        balance2[addsr2] = withdrawamount;
        balance[addsr1] -= withdrawamount;
        balance[addsr2] += withdrawamount;
        addsr2.transfer(withdrawamount);
    }
    
          function checkamountpayandgetbackmoney(address adx)public view returns(uint256 a){
          a = balance2[adx]*(1000000+50000);
          //*c = (now-timestamp1[msg.sender])
          // a = balance2[adx]*(1000000+50000*c/365);
          a = a/1000000;
    }
    
    
       function paymoneyback(uint256 value, address adb, address payable adds) payable public{
       uint256 b = 0;
       b = balance2[adb]*(10000)/1000000;
           //*c = (now-timestamp1[msg.sender])
          // b = balance2[adb]*(10000)/1000000*c/365);
       
       
       balance[adb] -= value;
       balance[adds] = balance[adds] + value - b;
       interestpooling += b;
       
       adds.transfer(value);
    }
    function checkpoolincome()  public view returns(uint256 b){
       b = 0;
       b = interestpooling;
     }
     // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    //0x85e9cb6A6e9D01faEcA6C8642959ADbF140eb0Ca 0xaC7C9881aeFf16D9557A85d5C640C54D0851B687  0x0C923dA8AC3a1eC8C43feE12fF9DdE847EfF11D6 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
}