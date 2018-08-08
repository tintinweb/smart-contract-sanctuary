pragma solidity ^0.4.11;



contract Token 
{

    
    function totalSupply() constant returns (uint256 ) {
      return;
    }

    
    
    function balanceOf(address ) constant returns (uint256 ) {
      return;
    }

    
    
    
    
    function transfer(address , uint256 ) returns (bool ) {
      return;
    }

    
    
    
    
    
    function transferFrom(address , address , uint256 ) returns (bool ) {
      return;
    }

    
    
    
    
    function approve(address , uint256 ) returns (bool ) {
      return;
    }

    
    
    
    function allowance(address , address ) constant returns (uint256 ) {
      return;
    }


    event Transfer(address indexed , address indexed , uint256 );
    event Approval(address indexed , address indexed , uint256 );
}

contract StdToken is Token 
{

     mapping(address => uint256) balances;
     mapping (address => mapping (address => uint256)) allowed;

     uint256 public allSupply = 0;


     function transfer(address _to, uint256 _value) returns (bool success) 
     {
          if((balances[msg.sender] >= _value) && (balances[_to] + _value > balances[_to])) 
          {
               balances[msg.sender] -= _value;
               balances[_to] += _value;

               Transfer(msg.sender, _to, _value);
               return true;
          } 
          else 
          { 
               return false; 
          }
     }

     function transferFrom(address _from, address _to, uint256 _value) returns (bool success) 
     {
          if((balances[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (balances[_to] + _value > balances[_to])) 
          {
               balances[_to] += _value;
               balances[_from] -= _value;
               allowed[_from][msg.sender] -= _value;

               Transfer(_from, _to, _value);
               return true;
          } 
          else 
          { 
               return false; 
          }
     }

     function balanceOf(address _owner) constant returns (uint256 balance) 
     {
          return balances[_owner];
     }

     function approve(address _spender, uint256 _value) returns (bool success) 
     {
          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);

          return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint256 remaining) 
     {
          return allowed[_owner][_spender];
     }

     function totalSupply() constant returns (uint256 supplyOut) 
     {
          supplyOut = allSupply;
          return;
     }
}

contract ReputationToken is StdToken {
     string public name = "EthlendReputationToken";
     uint public decimals = 18;
     string public symbol = "CRE";

     address public creator = 0x0;

     function ReputationToken(){
          creator = msg.sender;
     }

     function changeCreator(address newCreator){
          if(msg.sender!=creator)throw;

          creator = newCreator;
     }

     function issueTokens(address forAddress, uint tokenCount) returns (bool success){
          if(msg.sender!=creator)throw;
          
          if(tokenCount==0) {
               success = false;
               return ;
          }

          balances[forAddress]+=tokenCount;
          allSupply+=tokenCount;

          success = true;
          return;
     }
}