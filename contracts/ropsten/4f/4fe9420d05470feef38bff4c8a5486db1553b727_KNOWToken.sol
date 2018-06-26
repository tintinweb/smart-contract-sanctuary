pragma solidity 0.4.24;

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

contract KNOWToken is ERC20
{
    using SafeMath for uint256;
    // Name of the token
    string public constant name = &quot;KNOW Token&quot;;

    // Symbol of token
    string public constant symbol = &quot;KNOW&quot;;
    uint8 public constant decimals = 18;
    uint public _totalsupply = 18300000000 * 10 ** 18; // 18 billion total supply // muliplies dues to decimal precision
    uint256 public totalsupplyafterdeduction = 2745000000 * 10 ** 18;
    address public owner;                    // Owner of this contract
    uint256 public _price_tokn_ICO = 8090;   // 1 Ether = 8090 coins
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    bool stopped = false;
    uint256 public privatesale_startdate;
    uint256 public privatesale_enddate;
    uint256 public eth_received; // total ether received in the contract
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    enum Stages {
        NOTSTARTED,
        PRIVATESALE,
        PAUSED,
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

    function KNOWToken() public
    {
        
        owner = msg.sender;
        balances[owner] = 10980000000 * 10 ** 18; // 60% to Contributor
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
        
        
        uint256 _transfertoearlyinvestors = 4575000000 * 10 ** 18; // 25% to Early Investors
        balances[0x2cffc943c01b8499ee3848f32c6732363e38b402] = _transfertoearlyinvestors;
        Transfer(address(0), 0x2cffc943c01b8499ee3848f32c6732363e38b402, _transfertoearlyinvestors);
    }
    
    function () public payable 
    {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
            if( stage == Stages.PRIVATESALE && now <= privatesale_enddate )
            { 
                eth_received = (eth_received).add(msg.value);
                total_token = ((msg.value).mul(_price_tokn_ICO));
                transferTokens(msg.sender,total_token);
            }
            else
            {
                revert();
            }   
    }
    
    function start_PRIVATESALE() public onlyOwner atStage(Stages.NOTSTARTED)
     {
          stage = Stages.PRIVATESALE;
          stopped = false;
          balances[address(this)] =  totalsupplyafterdeduction;
          privatesale_startdate = now;
          privatesale_enddate = now + 365 days;
          Transfer(0, address(this), balances[address(this)]);
    }
        // called by the owner, pause ICO
    function pause_PRIVATESALE() external onlyOwner
    {
        stopped = true;
    }

    // called by the owner , resumes ICO
    function resume_PRIVATESALE() external onlyOwner
    {
        stopped = false;
    }
    function end_PRIVATESALE() external onlyOwner atStage(Stages.PRIVATESALE)
    {
         require(now > privatesale_enddate);
         stage = Stages.ENDED;
         _totalsupply = (_totalsupply).sub(balances[address(this)]);
         balances[address(this)] = 0;
         Transfer(address(this), 0 , balances[address(this)]);
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
     // tokens on your behalf, for example to &quot;deposit&quot; to a contract address and/or to charge
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
     function transfer(address _to, uint256 _amount)public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
             return true;
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
 
    
    function drain() external onlyOwner {
        owner.transfer(this.balance);
    }
    
}