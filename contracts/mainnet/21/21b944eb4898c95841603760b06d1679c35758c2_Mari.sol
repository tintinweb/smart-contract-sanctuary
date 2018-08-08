pragma solidity 0.4.18;

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure  internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
    
    function safeDiv(uint a, uint b) pure internal returns (uint) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
     assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
}
contract ERC20 {
  uint256 public totalsupply;
  function totalSupply() public constant returns(uint256 _totalSupply);
  function balanceOf(address who) public constant returns (uint256);
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool ok);
  function approve(address spender, uint256 value) public returns (bool ok);
  function transfer(address to, uint256 value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Mari is ERC20, SafeMath
{
    // Name of the token
    string public constant name = "Mari";

    // Symbol of token
    string public constant symbol = "MAR";

    uint8 public constant decimals = 18;
    uint public totalsupply = 2000000 * 10 ** 18; //
    address public owner;
    uint256 public _price_tokn = 483 ;
    uint256 no_of_tokens;
    bool stopped = true;
    uint256 startdate;
    uint256 enddate;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
     enum Stages {
        NOTSTARTED,
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
    function Mari() public
    {
        owner = msg.sender;
        balances[owner] = 1750000 * 10 **18;
        balances[address(this)] = 250000 *10**18;
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
        Transfer(0, owner, balances[address(this)]);
    }
  
    function () public payable atStage(Stages.ICO)
    {
        require(!stopped && msg.sender != owner && now <= enddate);
        no_of_tokens = safeMul(msg.value , _price_tokn);
        transferTokens(msg.sender,no_of_tokens);
    }
    
     function start_ICO() public onlyOwner 
      {
          stage = Stages.ICO;
          stopped = false;
          startdate = now;
          enddate = startdate + 30 days;
     }
    
    // called by the owner, pause ICO
    function StopICO() external onlyOwner {
        stopped = true;
        stage = Stages.PAUSED;
    }

    // called by the owner , resumes ICO
    function releaseICO() external onlyOwner {
        stopped = false;
        stage = Stages.ICO;
    }
    
     function end_ICO() external onlyOwner
     {
         stage = Stages.ENDED;
         totalsupply = safeSub(totalsupply , balances[address(this)]);
         balances[address(this)] = 0;
         Transfer(address(this), 0 , balances[address(this)]);
         
     }


    function totalSupply() public constant returns(uint256 _totalSupply)
    {
        return totalsupply;
    }
    
    function balanceOf(address sender) public constant returns (uint256)
    {
        return balances[sender];
    }
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns(bool success) {
        if (balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
      // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) public returns(bool success) {
        if (balances[msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
         
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);

          

            return true;
        } else {
            return false;
        }
    }
    
          // Transfer the balance from owner&#39;s account to another account
    function transferTokens(address _to, uint256 _amount) private returns(bool success) {
        if (balances[address(this)] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
         
            balances[address(this)] -= _amount;
            balances[_to] += _amount;
            Transfer(address(this), _to, _amount);

            return true;
        } else {
            return false;
        }
    }
    
     function drain() external onlyOwner {
        owner.transfer(this.balance);
    }
    
    
    
}