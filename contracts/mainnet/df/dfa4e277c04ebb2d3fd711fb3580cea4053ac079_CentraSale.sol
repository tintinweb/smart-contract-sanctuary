pragma solidity ^0.4.16;        
   
  contract CentraSale { 

    using SafeMath for uint; 

    address public contract_address = 0x96a65609a7b84e8842732deb08f56c3e21ac6f8a; 

    address public owner;    
    uint public constant min_value = 10**18*1/10;     

    uint256 public constant token_price = 1481481481481481;  
    uint256 public tokens_total;  
   
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }      
 
    // Constructor
    function CentraSale() {
        owner = msg.sender;                         
    }
      
    //default function for crowdfunding
    function() payable {    

      if(!(msg.value >= min_value)) throw;                                 

      tokens_total = msg.value*10**18/token_price;
      if(!(tokens_total > 0)) throw;           

      if(!contract_transfer(tokens_total)) throw;
      owner.send(this.balance);
    }

    //Contract execute
    function contract_transfer(uint _amount) private returns (bool) {      

      if(!contract_address.call(bytes4(sha3("transfer(address,uint256)")),msg.sender,_amount)) {    
        return false;
      }
      return true;
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