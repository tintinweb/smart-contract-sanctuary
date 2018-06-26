pragma solidity ^0.4.10;

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
 
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
 
  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract ERC20 {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  uint public decimals;
  string public name;
}

contract dcntrpls is SafeMath {
    address[] investors;
    address owner;
    address admin1 = 0x60eF63B7fB48F79fe38Ae1814DC72e7473c22048;
    address admin2 = 0x60eF63B7fB48F79fe38Ae1814DC72e7473c22048;
    address[] disdone;
    uint public closingtime;
    uint goal;
    uint poolfee=0;
    uint min = 0;
    uint max = 10000000000000000000000;
    bool auto = false;
    
    struct investorSpec {
        uint iAmount;
        string idata;
    }
    mapping(address => investorSpec) investor;
    
    
    function dcntrpls(uint timeline,uint _goal,uint _poolfee,uint _min,uint _max,bool _auto){
        //note that goal need to be inputed in 6 decimal format.
        //will have to add a throw function here so that pool creator cannot be an investor
        owner = msg.sender;
        closingtime = now + (timeline * 60);
        goal = safeMul(_goal,1000000000000);
        poolfee = _poolfee;
        min = safeMul(_min,1000000000000);
        max = safeMul(_max,1000000000000);
        auto = _auto;
    }
    
    function () payable{
        if(now > closingtime || this.balance > goal) throw;
        investors.push(msg.sender);
        investor[msg.sender].iAmount = safeAdd(investor[msg.sender].iAmount, msg.value);
    }
    
    
    function distribute(ERC20 token) public {
      if(msg.sender != owner) {
          if(msg.sender != admin1){
              if(msg.sender != admin2){
                  throw;
              }
          }
      }
      uint tAmount = token.balanceOf(this);
      if(tAmount <= 0) throw;
      for (uint256 i = 0; i < investors.length; i++) {
        uint investedEth = investor[investors[i]].iAmount;
        uint tokentosend = safeMul(investedEth,tAmount)/this.balance;
        token.transfer(investors[i], tokentosend);
      }
      disdone.push(token);
    }
    
    function transfer(address to){
      if(this.balance <= 0 || now <= closingtime) throw;
      if(msg.sender != owner) {
          if(msg.sender != admin1){
              if(msg.sender != admin2){
                  throw;
              }
          }
      }
      to.transfer(this.balance);
    }
    
    function cancel(){
        if(investor[msg.sender].iAmount <= 0 || now > closingtime || this.balance >= goal) throw;
        msg.sender.transfer(investor[msg.sender].iAmount);
    }
    
    function getAllInvestors() public constant returns(address[]){
        return investors;
    }
    
    function gettotalEth() public constant returns(uint){
        return this.balance;
    }
    
    function gettotaltoken(ERC20 token) public constant returns(uint){
        return token.balanceOf(this);
    }
    
    function getInvestmentByAddress(address user) public constant returns(uint){
        return investor[user].iAmount;
    }
    
    function getPoolOwner() public constant returns(address){
        return owner;
    }
    
    function getPoolAddress() public constant returns(address){
        return this;
    }
    
    function getdisdone() public constant returns(address[]){
        return disdone;
    }
    function gettimelineandgoal() public constant returns(uint,uint){
        return (closingtime,goal);
    }
    

}