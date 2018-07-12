pragma solidity ^0.4.21;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value)public returns (bool);
  function approve(address spender, uint256 value)public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {
    
   function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure  returns (uint256 c) {
     c = a / b;
    return c;
  }
 
  function sub(uint256 a, uint256 b)internal pure  returns (uint256 c) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
  
}

contract BasicToken is ERC20Basic {
    
using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    //totalSupply_= totalSupply_.sub(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

 
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract INBETToken is BurnableToken {
    
    string public constant name = &quot;InBet Token&quot;;
    
    string public constant symbol = &quot;IBO&quot;;
    
    uint32 public constant decimals = 18;
    
    uint256 public INITIAL_SUPPLY = 100*10**6 *1 ether;
    
    function INBETToken()public {
      totalSupply_ = INITIAL_SUPPLY;
      balances[msg.sender] = INITIAL_SUPPLY;
    }
   
}

contract Ownable {
    
  address public owner;
 
  function Ownable() public {
    owner = msg.sender;
  }
 
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  function transferOwnership(address newOwner) onlyOwner public{
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}

contract Crowdsale is Ownable {
    
  using SafeMath for uint;
    
  INBETToken public token=new INBETToken();
  
  bool activeSCO=false;
  
  address multisig=0x68A9692Af455c82F7cD79D98246d9ac9f7B9Cfb5;
  address developer=0x79Df31E07A18F64a02Da8840B968F8d1C1Fb7FC8;
  address fond=0xFb9eDf7aD729c9BA6BCB1031bBD18dC00cE7DB77;
  address ambassador=0x77EdD8CA35a955e8da8b6df3553c0F8703aB7385;
  address bounty=0xBbf0a71A28Fb991a9362B6eB4369cCeF323D7CF1;
 
  uint ratePreICO=10000 ;
  uint rateICO1=7000 ;
  uint rateICO2=3500 ;
  uint rateSCO=550 ;
  
  uint buyPreICO=0;
  uint buyICO1=0;
  uint buyICO2=0;
  
// uint startPreICO=1532394000; // 25 july 01:00:00 GMT-0 
// uint endPreICO=1533942000; // 10 august 23:00:00 GMT-0 
// uint startICO1=1536973200; // 15 september 01:00:00 GMT-0 
// uint endICO1=1539565200; // 15 october 01:00:00 GMT-0 
// uint startICO2=1540861200; // 30 october 01:00:00 GMT-0 
// uint endICO2=1543539600; // 30 november 01:00:00 GMT-0
 
 uint startPreICO=now+5 minutes; 
 uint endPreICO=startPreICO+5 minutes; 
 uint startICO1=endPreICO+5 minutes; 
 uint endICO1=startICO1+5 minutes; 
 uint startICO2=endICO1+5 minutes; 
 uint endICO2=startICO2+5 minutes; 
  
  uint limitPreICO=5*10**6*1 ether;
  uint limitICO=25*10**6*1 ether;
  
  function Crowdsale() public {
    token.transfer(developer, 15*10**6 * 1 ether);
    token.transfer(fond, 1025*10**4 * 1 ether);
    token.transfer(ambassador, 6*10**6 * 1 ether);
    token.transfer(bounty, 2*10**6 * 1 ether);
  }
  
  modifier isActive() {
    require((now > startPreICO && now<endPreICO ) ||(now > startICO1 && now < endICO1 ) || (now > startICO2 && now < endICO2 )||activeSCO);
    _;
  }
  
  function Rate() internal view returns (uint) {
         if(now > startPreICO && now<endPreICO ) return ratePreICO;
         else if(now > startICO1 && now < endICO1 ) return rateICO1;
         else if (now > startICO2 && now < endICO2 ) return rateICO2;
         else return rateSCO;
  }
  
  function Bonus(uint buyToken) internal view returns (uint) {
           if(now > startPreICO && now<endPreICO ) return buyToken.div(10);
           else if(now > startICO1 && now < endICO1 ) return buyToken.div(20);
           else return 0;
  }
  
  function Remainder(uint buyToken)internal view returns (uint) {
      uint remainder=0;
       if(now > startPreICO && now<endPreICO){
          remainder=limitPreICO.sub(buyPreICO);
          buyPreICO=buyPreICO.add((buyToken>remainder)?remainder:buyToken); 
        } else if(now > startICO1 && now < endICO1 ) {
          remainder=limitICO.sub(buyICO1);
          buyICO1=buyICO1.add((buyToken>remainder)?remainder:buyToken);
        } else if (now > startICO2 && now < endICO2 ){
           remainder=limitICO.sub(buyICO2);
           buyICO2=buyICO2.add((buyToken>remainder)?remainder:buyToken); 
        } else if (activeSCO ) remainder=token.totalSupply();
          
        return (buyToken>remainder)?remainder:buyToken;
  }

  function buyTokens(address _to)isActive public  payable {
      require(msg.value>0);
      uint rate=Rate();
     uint tokens =Remainder(msg.value.mul(rate));
     uint wai=tokens.div(rate);
     multisig.transfer(wai);
     msg.sender.transfer(msg.value.sub(wai)); 
     tokens= tokens.add(Bonus(tokens));
     token.transfer(_to, tokens);
  }
  
  function burn()onlyOwner public {
       uint bonusBurn=0;
       uint burnToken=0;
       
      if (now >  endICO2 ) {     
          burnToken=limitICO.sub(buyICO2);
          buyICO2=buyICO2.add(burnToken);
      }
      else if(now >  endICO1 )     {  
          burnToken=limitICO.sub(buyICO1);
          buyICO1=buyICO1.add(burnToken);
          bonusBurn= burnToken.div(20);
      }
      else if(now > endPreICO )      { 
          burnToken=limitPreICO.sub(buyPreICO);
          buyPreICO=buyPreICO.add(burnToken); 
          bonusBurn= burnToken.div(10);
      }
        
      token.burn(burnToken.add(bonusBurn));
  }
  
  function ActiveSCO(bool active, uint rate)onlyOwner public{
      activeSCO=active;
      rateSCO=rate;
  }
  
  function () external payable { buyTokens(msg.sender); }
    
}