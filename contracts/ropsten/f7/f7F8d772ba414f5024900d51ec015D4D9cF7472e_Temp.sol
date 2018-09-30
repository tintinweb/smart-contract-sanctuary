pragma solidity ^0.4.0;
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
    uint256 c = a / b;
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


contract Temp is ERC20 { 
    
    using SafeMath for uint256;
    string public constant name = "Temp";               
    string public constant symbol = "TMP";                  
    uint8 public constant decimals = 18;
    uint public _totalsupply = 1000000 * 10 ** 18;         
    address public owner;                                  
    uint256 public _price_token_PRE = 100;                 
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    bool stopped = false;
    uint256 public pre_startdate;
    uint256 pre_enddate;
    uint256 public eth_received;                            
    uint256 maxCap_public = 1000000 * 10 ** 18;           
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    enum Stages {
        NOTSTARTED,
        PREICO,
        PAUSED,
        ENDED
    }
    
    Stages public stage;
    
    modifier atStage(Stages _stage) {
        if (stage != _stage)
            revert();
        _;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function Temp() public {
        owner = msg.sender;
        balances[owner] = 1000000 * 10 ** 18;          
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
    }
  
    function () public payable {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
            if( stage == Stages.PREICO && now <= pre_enddate ) { 
                eth_received = (eth_received).add(msg.value);
                no_of_tokens = ((msg.value).mul(_price_token_PRE));               
                total_token  = no_of_tokens;
                transferTokens(msg.sender,total_token);
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
        pre_enddate   = now + 30 days;                                          
        Transfer(0, address(this), balances[address(this)]);
    }
     
    function PauseICO() external onlyOwner
    {
        stopped = true;
    }

    function ResumeICO() external onlyOwner
    {
        stopped = false;
    }
   
    function end_ICO() external onlyOwner atStage(Stages.PREICO)
    {
        require(now > pre_startdate);
        stage = Stages.ENDED;
        _totalsupply = (_totalsupply).sub(balances[address(this)]);
        balances[address(this)] = 0;
        Transfer(address(this), 0 , balances[address(this)]);
    }

    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transferFrom( address _from, address _to, uint256 _amount ) public returns (bool success) {
        require( _to != 0x0);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
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

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
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