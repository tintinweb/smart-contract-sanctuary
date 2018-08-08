pragma solidity 0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract TANDER is ERC20
{ using SafeMath for uint256;
    // Name of the token
    string public constant name = "TANDER";

    // Symbol of token
    string public constant symbol = "TDR";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 10000000000000 *10 ** 18; // 10 TRILLION TDR
    address public owner;
    uint256 constant public _price_tokn = 1000 ; 
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    bool stopped = false;
    uint256 public pre_startdate;
    uint256 public ico_startdate;
    uint256 pre_enddate;
    uint256 ico_enddate;
    uint256 maxCap_PRE;
    uint256 maxCap_ICO;
    bool public icoRunningStatus = true;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address ethFundMain = 0x0070570A1D3F5CcaD6A74B3364D13C475BF9bD6a; // Owner&#39;s Account
    uint256 public Numtokens;
    uint256 public bonustokn;
    uint256 public ethreceived;
    uint bonusCalculationFactor;
    uint public bonus;
    uint x ;
 
    
     enum Stages {
        NOTSTARTED,
        PREICO,
        ICO,
        ENDED
    }
    Stages public stage;
    
    modifier atStage(Stages _stage) {
        if (stage != _stage)
            // Contract not in expected state
            revert();
        _;
    }
    
     modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
  
   
    function TANDER() public
    {
        owner = msg.sender;
        balances[owner] = 2000000000000 *10 ** 18;  // 2 TRILLION TDR FOR RESERVE
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
    }
  
    function () public payable 
    {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
    if( stage == Stages.PREICO && now <= pre_enddate )
        {  
            no_of_tokens =(msg.value).mul(_price_tokn);
            ethreceived = ethreceived.add(msg.value);
            bonus= bonuscalpre();
            bonus_token = ((no_of_tokens).mul(bonus)).div(100);  // bonus calculation
            total_token = no_of_tokens + bonus_token;
            Numtokens= Numtokens.add(no_of_tokens);
             bonustokn= bonustokn.add(bonus_token);
            transferTokens(msg.sender,total_token);
         }
         
         
    else
    if(stage == Stages.ICO && now <= ico_enddate )
        {
             
            no_of_tokens =((msg.value).mul(_price_tokn));
            ethreceived = ethreceived.add(msg.value);
            total_token = no_of_tokens + bonus_token;
           Numtokens= Numtokens.add(no_of_tokens);
             bonustokn= bonustokn.add(bonus_token);
            transferTokens(msg.sender,total_token);
        
        }
    else {
            revert();
        }
       
    }

    
    //bonus calculation for preico on per day basis
     function bonuscalpre() private returns (uint256 cp)
        {
          uint bon = 8;
             bonusCalculationFactor = (block.timestamp.sub(pre_startdate)).div(604800); //time period in seconds
            if(bonusCalculationFactor == 0)
            {
                bon = 8;
            }
         
            else{
                 bon -= bonusCalculationFactor* 8;
            }
            return bon;
          
        }
        
 
  
     function start_PREICO() public onlyOwner atStage(Stages.NOTSTARTED)
      {
          stage = Stages.PREICO;
          stopped = false;
          maxCap_PRE = 3000000000000 * 10 ** 18;  // 3 TRILLION
          balances[address(this)] = maxCap_PRE;
          pre_startdate = now;
          pre_enddate = now + 90 days; //time for preICO
          Transfer(0, address(this), balances[address(this)]);
          }
    
    
      function start_ICO() public onlyOwner atStage(Stages.PREICO)
      {
          stage = Stages.ICO;
          stopped = false;
          maxCap_ICO = 5000000000000 * 10 **18;   // 5 TRILLION
          balances[address(this)] = balances[address(this)].add(maxCap_ICO);
         ico_startdate = now;
         ico_enddate = now + 180 days; //time for ICO
          Transfer(0, address(this), balances[address(this)]);
          }
          
   
    // called by the owner, pause ICO
    function StopICO() external onlyOwner  {
        stopped = true;
      
    }

    // called by the owner , resumes ICO
    function releaseICO() external onlyOwner
    {
        stopped = false;
      
    }
    
     function end_ICO() external onlyOwner atStage(Stages.ICO)
     {
         require(now > ico_enddate);
         stage = Stages.ENDED;
         icoRunningStatus= false;
        _totalsupply = (_totalsupply).sub(balances[address(this)]);
         balances[address(this)] = 0;
         Transfer(address(this), 0 , balances[address(this)]);
         
     }
      // This function can be used by owner in emergency to update running status parameter
        function fixSpecications(bool RunningStatus ) external onlyOwner
        {
           icoRunningStatus = RunningStatus;
        }
     
    // what is the total supply of the ech tokens
     function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = _totalsupply;
     }
    
    // What is the balance of a particular account?
     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
    
    // Send _value amount of tokens from address _from to address _to
     // The transferFrom method is used for a withdraw workflow, allowing contracts to send
     // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     // fees in sub-currencies; the command should fail unless the _from account has
     // deliberately authorized the sender of the message via some mechanism; we propose
     // these standardized APIs for approval:
     function transferFrom( address _from, address _to, uint256 _amount )public returns (bool success) {
     require( _to != 0x0);
     require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
     balances[_from] = (balances[_from]).sub(_amount);
     allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
     balances[_to] = (balances[_to]).add(_amount);
     Transfer(_from, _to, _amount);
     return true;
         }
    
   // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     function approve(address _spender, uint256 _amount)public returns (bool success) {
         require(!icoRunningStatus);
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         require( _owner != 0x0 && _spender !=0x0);
         return allowed[_owner][_spender];
   }
    // Transfer the balance from owner&#39;s account to another account
     function transfer(address _to, uint256 _amount) public returns (bool success) {
         if(icoRunningStatus && msg.sender == owner)
         {
            require(balances[owner] >= _amount && _amount >= 0 && balances[_to] + _amount > balances[_to]);
            balances[owner] = (balances[owner]).sub(_amount);
            balances[_to] = (balances[_to]).add(_amount);
            Transfer(owner, _to, _amount);
            return true;
         }
       
         else if(!icoRunningStatus)
         {
            require(balances[msg.sender] >= _amount && _amount >= 0 && balances[_to] + _amount > balances[_to]);
            balances[msg.sender] = (balances[msg.sender]).sub(_amount);
            balances[_to] = (balances[_to]).add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
         } 
         
         else 
         revert();
     }
  

          // Transfer the balance from owner&#39;s account to another account
    function transferTokens(address _to, uint256 _amount) private returns(bool success) {
        require( _to != 0x0);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = (balances[address(this)]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(address(this), _to, _amount);
        return true;
        }

        function transferby(address _to,uint256 _amount) external onlyOwner returns(bool success) {
        require( _to != 0x0); 
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = (balances[address(this)]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(address(this), _to, _amount);
        return true;
    }
    
 
    	//In case the ownership needs to be transferred
	function transferOwnership(address newOwner)public onlyOwner
	{
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	}

    
    function drain() external onlyOwner {
        ethFundMain.transfer(this.balance);
    }
    
}