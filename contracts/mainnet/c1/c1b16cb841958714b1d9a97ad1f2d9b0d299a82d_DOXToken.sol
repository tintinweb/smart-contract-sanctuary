pragma solidity ^0.4.15;

library Math {
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
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
  
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;


  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;



  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];


    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) returns (bool) {


    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract DOXToken is StandardToken, owned {

string public constant name = "DOX";
string public constant symbol = "DOX";
uint32 public constant decimals = 3;
uint256 public  exchangeRate=200;
uint256 public INITIAL_SUPPLY = 100000000 * 1000;

address addressSellAgent;
address addressSellAgentSiteReg;
address addressSellAgentCreators;
address addressSellAgentBounty;
address addressRateAgent;
 
uint256 public START_PRESALE_TIMESTAMP   = 1523721600; 
uint256 public START_PREICO_TIMESTAMP   = 1526313600;  
uint256 public START_ICO_TIMESTAMP   = 1528992000;     
 
uint256 public END_PRESALE_TIMESTAMP   = 0;
uint256 public END_PREICO_TIMESTAMP   = 0;
uint256 public END_ICO_TIMESTAMP   = 0;
 
uint256 public LOCKUP_3M_ICO_TIMESTAMP   = 0;
uint256 public LOCKUP_6M_ICO_TIMESTAMP   = 0;
 
uint32 public  PRESALE_HARDCAP=  250000;
uint32 public   PREICO_HARDCAP=  950000;
uint32 public      ICO_HARDCAP=11450000;
  
uint256 public   PRESALE_PERIOD=28;
uint256 public   PREICO_PERIOD=28;
uint256 public     ICO_PERIOD=28;
 
address addressPayForService=0xF7F6c903467c0C8b9CF7C9D9eA8e24bA54d3bAdd;


    
uint256 public tokensForBounty=0;
uint256 public tokensForSiteReg=0;
uint256 public tokensForCreators=0;
        

mapping(address => uint256) arrayCreators;
mapping(address => uint256) arrayBounty;

event PayForServiceETHEvent(address indexed from, uint256 value);
event PayForServiceCHLEvent(address indexed from, uint256 value);
event BurnFrom(address indexed from, uint256 value);

event TransferCreators(address indexed to, uint256 value);
event TransferBounty(address indexed to, uint256 value);
event TransferSiteReg(address indexed to, uint256 value);

function DOXToken() {
        totalSupply = INITIAL_SUPPLY;
 
        tokensForSiteReg= INITIAL_SUPPLY.div(100);
        tokensForBounty= INITIAL_SUPPLY.mul(4).div(100);
        tokensForCreators=INITIAL_SUPPLY.mul(2).div(10);
     
     
        balances[msg.sender] = INITIAL_SUPPLY-tokensForBounty-tokensForCreators-tokensForSiteReg;
 
        END_PRESALE_TIMESTAMP=START_PRESALE_TIMESTAMP+(PRESALE_PERIOD * 1 days);  
        END_PREICO_TIMESTAMP=START_PREICO_TIMESTAMP+(PREICO_PERIOD * 1 days);   
        END_ICO_TIMESTAMP=START_ICO_TIMESTAMP+(ICO_PERIOD * 1 days);   
 
        LOCKUP_3M_ICO_TIMESTAMP=END_ICO_TIMESTAMP+(90 * 1 days); 
        LOCKUP_6M_ICO_TIMESTAMP=END_ICO_TIMESTAMP+(180 * 1 days);  
 
        addressSellAgent=msg.sender;
        addressPayForService=msg.sender;
        addressSellAgentSiteReg=msg.sender;
        addressSellAgentCreators=msg.sender;
        addressSellAgentBounty=msg.sender;
        addressRateAgent=msg.sender;
 
}
    function SetRate( uint32 newRate)   external returns (bool) {
        require(msg.sender==addressRateAgent) ;
        require(newRate>0);
	    exchangeRate = newRate;
	   return true;
     }
     
       function Update_START_PRESALE_TIMESTAMP( uint256 newTS)  onlyOwner {
	  START_PRESALE_TIMESTAMP = newTS;
	   END_PRESALE_TIMESTAMP=START_PRESALE_TIMESTAMP+(PRESALE_PERIOD * 1 days);  
     }
       function Update_START_PREICO_TIMESTAMP( uint256 newTS)  onlyOwner {
	  START_PREICO_TIMESTAMP = newTS;
	  END_PREICO_TIMESTAMP=START_PREICO_TIMESTAMP+(PREICO_PERIOD * 1 days);  
     }
     
        function Update_START_ICO_TIMESTAMP( uint256 newTS)  onlyOwner {
	    START_ICO_TIMESTAMP = newTS;
	    END_ICO_TIMESTAMP=START_ICO_TIMESTAMP+(ICO_PERIOD * 1 days);  
	    LOCKUP_3M_ICO_TIMESTAMP=END_ICO_TIMESTAMP+(90 * 1 days);  
        LOCKUP_6M_ICO_TIMESTAMP=END_ICO_TIMESTAMP+(180 * 1 days);  
     }
     
  
  function UpdateSellAgent(address new_address) onlyOwner {
   addressSellAgent=new_address;
  }
  
function UpdateSellAgentSiteReg(address new_address) onlyOwner {
   addressSellAgentSiteReg=new_address;
  }
  function UpdateSellAgentBounty(address new_address) onlyOwner {
   addressSellAgentBounty=new_address;
  }
  function UpdateSellAgentCreators(address new_address) onlyOwner {
   addressSellAgentCreators=new_address;
  }
  function UpdateAddressPayForService(address new_address) onlyOwner {
   addressPayForService=new_address;
  }
  
   function UpdateRateAgent(address new_address) onlyOwner {
   addressRateAgent=new_address;
  }

 
   function TransferSellAgent(address _to, uint256 _value) external returns (bool) {
      require(msg.sender==addressSellAgent) ;

    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(owner, _to, _value);
    return true;
  }
  
  function TransferSellAgentMulti(address[] _toes, uint256 _value) external returns (bool) {
      require(msg.sender==addressSellAgent) ;
      
       require(  balances[owner]>=_value.mul(_toes.length));
      
      for (uint i = 0; i < _toes.length; i++) {
          
        balances[owner] = balances[owner].sub(_value);
        balances[_toes[i]] = balances[_toes[i]].add(_value);
         
     Transfer(owner, _toes[i], _value);

        }
  

    return true;
  }
  
  
  
     function TransferSellAgentSiteReg(address _to, uint256 _value) external returns (bool) {
    require(msg.sender==addressSellAgentSiteReg) ;
    require(tokensForSiteReg>=_value);
    

    tokensForSiteReg = tokensForSiteReg.sub(_value);

    balances[_to] = balances[_to].add(_value);

    TransferSiteReg( _to, _value);
    return true;
  }
  
    function TransferSellAgentSiteRegMulti(address[] _toes, uint256 _value) external returns (bool) {
    require(msg.sender==addressSellAgentSiteReg);
    require(tokensForSiteReg>=_value.mul(_toes.length));
    
     for (uint i = 0; i < _toes.length; i++) {
         
        tokensForSiteReg = tokensForSiteReg.sub(_value);
        balances[_toes[i]] = balances[_toes[i]].add(_value);
        TransferSiteReg(_toes[i], _value);
        }
        
    return true;
  }
  
  
  
  function TransferSellAgentBounty(address _to, uint256 _value) external returns (bool) {
    require(msg.sender==addressSellAgentBounty) ;
    require(tokensForBounty>=_value);
     require(now>END_ICO_TIMESTAMP );
    
    tokensForBounty = tokensForBounty.sub(_value);
    arrayBounty[_to]=arrayBounty[_to].add(_value);
    balances[_to] = balances[_to].add(_value);
    TransferBounty( _to, _value);
    return true;
  }
  
    function TransferSellAgentCreators(address _to, uint256 _value) external returns (bool) {
    require(msg.sender==addressSellAgentCreators) ;
    require(tokensForCreators>=_value);
    require(now>END_ICO_TIMESTAMP );
    
    tokensForCreators = tokensForCreators.sub(_value);
    arrayCreators[_to]=arrayCreators[_to].add(_value);
    balances[_to] = balances[_to].add(_value);
    TransferCreators( _to, _value);
    return true;
  }
  
  

  
   modifier isSelling() {
    require( ((now>START_PRESALE_TIMESTAMP&&now<END_PRESALE_TIMESTAMP ) ||(now>START_PREICO_TIMESTAMP&&now<END_PREICO_TIMESTAMP ) ||(now>START_ICO_TIMESTAMP&&now<END_ICO_TIMESTAMP ) ) );
     require(balances[owner]>0 );
    
    
    _;
  }
  
    function transfer(address _to, uint256 _value) returns (bool) {
        require(!( arrayCreators[msg.sender]>0)||now>LOCKUP_6M_ICO_TIMESTAMP);
        require(!( arrayBounty[msg.sender]>0) ||now>LOCKUP_3M_ICO_TIMESTAMP);
        
       
        
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
  
    function() external payable isSelling {

     uint tokens = exchangeRate.mul(5000).mul(msg.value).div(1 ether);
     uint newBalance=exchangeRate.mul(msg.value+owner.balance).div(1 ether);

if (now>START_PRESALE_TIMESTAMP&&now<END_PRESALE_TIMESTAMP)
{
    require(newBalance<PRESALE_HARDCAP);
    
       tokens=tokens.mul(3).div(2);
    
       
} else 

if (now>START_PREICO_TIMESTAMP&&now<END_PREICO_TIMESTAMP)
{
    require(newBalance<PREICO_HARDCAP);
    
      uint bonusTokens = 0;
        if(now < START_PREICO_TIMESTAMP + (PREICO_PERIOD * 1 days).div(4)) {
          bonusTokens = tokens.mul(3).div(10);
        } else if(now >= START_PREICO_TIMESTAMP + (PREICO_PERIOD * 1 days).div(4) && now < START_PREICO_TIMESTAMP + (PREICO_PERIOD * 1 days).div(4).mul(2)) {
          bonusTokens = tokens.div(4);
        } else if(now >= START_PREICO_TIMESTAMP + (PREICO_PERIOD * 1 days).div(4).mul(2) && now < START_PREICO_TIMESTAMP + (PREICO_PERIOD * 1 days).div(4).mul(3)) {
          bonusTokens = tokens.div(5);
        } else
        {
             bonusTokens = tokens.mul(3).div(20);
        }
        
        
        tokens += bonusTokens;
       
       
} else 
     
     if (now>START_ICO_TIMESTAMP&&now<END_ICO_TIMESTAMP)
{
    require(newBalance<ICO_HARDCAP);
    
      uint bonusTokensICO = 0;
        if(now < START_ICO_TIMESTAMP + (ICO_PERIOD * 1 days).div(4)) {
          bonusTokensICO = tokens.div(8);
        } else if(now >= START_ICO_TIMESTAMP + (ICO_PERIOD * 1 days).div(4) && now < START_ICO_TIMESTAMP + (ICO_PERIOD * 1 days).div(4).mul(2)) {
          bonusTokensICO = tokens.mul(2).div(15);
        } else if(now >= START_ICO_TIMESTAMP + (ICO_PERIOD * 1 days).div(4).mul(2) && now < START_ICO_TIMESTAMP + (ICO_PERIOD * 1 days).div(4).mul(3)) {
          bonusTokensICO = tokens.div(40);
        } else
        {
             bonusTokensICO =0;
        }
        
        
        tokens += bonusTokensICO;
       
       
} else {
   revert();
}
  
     
  
    owner.transfer(msg.value);
    balances[owner] = balances[owner].sub(tokens);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    Transfer(owner, msg.sender, tokens);
           
    }
     function PayForServiceETH() external payable  {
      
      addressPayForService.transfer(msg.value);
      PayForServiceETHEvent(msg.sender,msg.value);
      
  }
    function PayForServiceCHL(uint256 _value)  external    {
     
      require(balances[msg.sender]>=_value&&_value>0);
      
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[addressPayForService] = balances[addressPayForService].add(_value);
      PayForServiceCHLEvent(msg.sender,_value);
      
  }
  function BurnTokensFrom(address _from, uint256 _value) external onlyOwner  {
    require (balances[_from] >= _value&&_value>0);                
   
    balances[_from]  = balances[_from].sub(_value);
    totalSupply =totalSupply.sub(_value);
    BurnFrom(_from, _value);
   
}
  
}