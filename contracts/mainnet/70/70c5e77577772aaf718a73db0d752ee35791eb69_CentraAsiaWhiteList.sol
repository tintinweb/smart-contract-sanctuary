pragma solidity ^0.4.13;        
   
  contract CentraAsiaWhiteList { 
 
      using SafeMath for uint;  
 
      address public owner;
      uint public operation;
      mapping(uint => address) public operation_address;
      mapping(uint => uint) public operation_amount; 
      
   
      // Functions with this modifier can only be executed by the owner
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }
   
      // Constructor
      function CentraAsiaWhiteList() {
          owner = msg.sender; 
          operation = 0;         
      }
      
      //default function for crowdfunding
      function() payable {    
 
        if(msg.value < 0) throw;
        if(this.balance > 47000000000000000000000) throw; // 0.1 eth
        if(now > 1505865600)throw; // timestamp 2017.09.20 00:00:00
        
        operation_address[operation] = msg.sender;
        operation_amount[operation] = msg.value;        
        operation = operation.add(1);
      }
 
      //Withdraw money from contract balance to owner
      function withdraw() onlyOwner returns (bool result) {
          owner.send(this.balance);
          return true;
      }
      
 }
 
 /**
   * Math operations with safety checks
   */
  library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }
 
    function div(uint a, uint b) internal returns (uint) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
      return c;
    }
 
    function sub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }
 
    function add(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c >= a);
      return c;
    }
 
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a >= b ? a : b;
    }
 
    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a < b ? a : b;
    }
 
    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a >= b ? a : b;
    }
 
    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a < b ? a : b;
    }
 
    function assert(bool assertion) internal {
      if (!assertion) {
        throw;
      }
    }
  }