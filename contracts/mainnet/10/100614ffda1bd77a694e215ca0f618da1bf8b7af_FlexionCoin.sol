pragma solidity 0.4.24;

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


contract FlexionCoin is ERC20 { 
    
    using SafeMath for uint256;
    string public constant name = "FLEXION";            // Name of the token
    string public constant symbol = "FXN";              // Symbol of token
    uint8 public constant decimals = 18;
    uint public _totalsupply = 360000000 * 10 ** 18;    // 360 million total supply // muliplies dues to decimal precision
    address public owner;                               // Owner of this contract
    uint256 public _price_token_PRE = 16000;            // 1 Ether = 16000 tokens in Pre-ICO
    uint256 public _price_token_ICO1 = 8000;            // 1 Ether = 8000 tokens in ICO Phase 1
    uint256 public _price_token_ICO2 = 4000;            // 1 Ether = 4000 tokens in ICO Phase 2
    uint256 public _price_token_ICO3 = 2666;            // 1 Ether = 2666 tokens in ICO Phase 3
    uint256 public _price_token_ICO4 = 2000;            // 1 Ether = 2000 tokens in ICO Phase 4
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    bool stopped = false;
    uint256 public pre_startdate;
    uint256 public ico1_startdate;
    uint256 ico_first;
    uint256 ico_second;
    uint256 ico_third;
    uint256 ico_fourth;
    uint256 pre_enddate;
    uint256 public eth_received;                        // Total ether received in the contract
    uint256 maxCap_public = 240000000 * 10 ** 18;       // 240 million in Public Sale
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    enum Stages {
        NOTSTARTED,
        PREICO,
        ICO,
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

    function FlexionCoin() public {
        owner = msg.sender;
        balances[owner] = 120000000 * 10 ** 18;         // 100 million to owner & 20 million to referral bonus
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
    }
  
    function () public payable {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
            if( stage == Stages.PREICO && now <= pre_enddate ) { 
                require (eth_received <= 1500 ether);                       // Hardcap
                eth_received = (eth_received).add(msg.value);
                no_of_tokens = ((msg.value).mul(_price_token_PRE)); 
                require (no_of_tokens >= (500 * 10 ** 18));                 // 500 min purchase
                bonus_token  = ((no_of_tokens).mul(50)).div(100);           // 50% bonus in Pre-ICO
                total_token  = no_of_tokens + bonus_token;
                transferTokens(msg.sender,total_token);
            }
            else if (stage == Stages.ICO && now <= ico_fourth ) {
                    
                if( now < ico_first )
                {
                    no_of_tokens = (msg.value).mul(_price_token_ICO1);
                    require (no_of_tokens >= (100 * 10 ** 18));             // 100 min purchase
                    bonus_token  = ((no_of_tokens).mul(40)).div(100);       // 40% bonus in ICO Phase 1
                    total_token  = no_of_tokens + bonus_token;
                    transferTokens(msg.sender,total_token);
                }   
                else if( now >= ico_first && now < ico_second )
                {
                    no_of_tokens = (msg.value).mul(_price_token_ICO2);
                    require (no_of_tokens >= (100 * 10 ** 18));             // 100 min purchase
                    bonus_token  = ((no_of_tokens).mul(30)).div(100);       // 30% bonus in ICO Phase 2
                    total_token  = no_of_tokens + bonus_token;
                    transferTokens(msg.sender,total_token);
                }
                else if( now >= ico_second && now < ico_third )
                {
                    no_of_tokens = (msg.value).mul(_price_token_ICO3);
                    require (no_of_tokens >= (100 * 10 ** 18));             // 100 min purchase
                    bonus_token  = ((no_of_tokens).mul(20)).div(100);       // 20% bonus in ICO Phase 3
                    total_token  = no_of_tokens + bonus_token;
                    transferTokens(msg.sender,total_token);
                }
                else if( now >= ico_third && now < ico_fourth )
                {
                    no_of_tokens = (msg.value).mul(_price_token_ICO4);
                    require (no_of_tokens >= (100 * 10 ** 18));             // 100 min purchase    
                    bonus_token  = ((no_of_tokens).mul(10)).div(100);       // 10% bonus in ICO Phase 4
                    total_token  = no_of_tokens + bonus_token;
                    transferTokens(msg.sender,total_token);
                }
            }
            else
            {
                revert();
            }
    }
    
    function start_PREICO() public onlyOwner atStage(Stages.NOTSTARTED)
    {
        stage   = Stages.PREICO;
        stopped = false;
        balances[address(this)] =  maxCap_public;
        pre_startdate = now;
        pre_enddate   = now + 30 days;                                      // 30 days PREICO
        Transfer(0, address(this), balances[address(this)]);
    }
     
    function start_ICO() public onlyOwner atStage(Stages.PREICO)
    {
        require(now > pre_enddate);
        stage   = Stages.ICO;
        stopped = false;
        ico1_startdate = now;
        ico_first  = now + 15 days;
        ico_second = ico_first + 15 days;
        ico_third  = ico_second + 15 days;
        ico_fourth = ico_third + 15 days;
        Transfer(0, address(this), balances[address(this)]);
    }
    
    // called by the owner, pause ICO
    function PauseICO() external onlyOwner
    {
        stopped = true;
    }

    // called by the owner, resumes ICO
    function ResumeICO() external onlyOwner
    {
        stopped = false;
    }
   
    function end_ICO() external onlyOwner atStage(Stages.ICO)
    {
        require(now > ico_fourth);
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
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom( address _from, address _to, uint256 _amount ) public returns (bool success) {
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
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require( _spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require( _owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    // Transfer the balance from owner&#39;s account to another account
    function transferTokens(address _to, uint256 _amount) private returns (bool success) {
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