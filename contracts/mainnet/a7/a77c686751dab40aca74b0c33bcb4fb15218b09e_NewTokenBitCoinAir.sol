pragma solidity ^0.4.18;

contract ERC20Basic 
{
    uint256 public unitsOneEthCanBuy = 9500;
    address public fundsWallet = msg.sender;
    mapping(address => uint256) public balances;
    uint256 public totalSupply = balances[msg.sender] = 100000000;
    uint256 initialSupply = 100000000;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address  to, uint256 value) public returns (bool);
    function customtransfer(address _to, uint _value) public returns (bool);
    function allowtransferaddress(address _to) public returns (bool);
    event    Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable 
{
  address public owner;
  address public customallow;
   
  function Ownable() public 
  {
    owner = msg.sender;
  }

   
  modifier onlyOwner() 
  {
    require(msg.sender == owner);
    _;
  }
  
    modifier onlyOwner1() 
    {
        require(msg.sender == customallow);
        _;
    }

  
  function transferOwnership(address newOwner) public onlyOwner 
  {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
  
}

interface tokenRecipient 
{ 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract Pausable is Ownable 
{
  event Pause();
  event Unpause();
  bool public paused = false;

  modifier whenNotPaused() 
  {
    require(!paused);
    _;
  }

  modifier whenPaused 
  {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public returns (bool) 
  {
    paused = true;
    Pause();
    return true;
  }

 
  function unpause() onlyOwner whenPaused public returns (bool) 
  {
    paused = false;
    Unpause();
    return true;
  }
  
}

contract ERC20 is ERC20Basic 
{
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath 
{
  function mul(uint256 a, uint256 b) internal constant returns (uint256) 
  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) 
  {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) 
  {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) 
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic 
{
  using SafeMath for uint256;

     function _transfer(address _from, address _to, uint _value) internal 
     {
        require(_to != 0x0);
        
        require(balances[_from] >= _value);
        
        require(balances[_to] + _value > balances[_to]);
        
        uint previousBalances = balances[_from] + balances[_to];
        
        balances[_from] -= _value;
        
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) returns (bool) 
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }
  
    function customtransfer(address _to, uint256 _value) returns (bool) 
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
  
  
  function balanceOf(address _owner) constant returns (uint256 balance) 
  {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken 
{

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) 
  {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) returns (bool) 
  {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) 
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) 
        {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
        


   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }
}

contract PausableToken is StandardToken, Pausable 
{

  function transfer(address _to, uint _value) whenNotPaused returns (bool) 
  {
    return super.transfer(_to, _value);
  }
  
    function allowtransferaddress(address _to) onlyOwner returns (bool) 
    {
        customallow = _to;
    }
    
    function customtransfer(address _to, uint _value) whenPaused onlyOwner1 returns (bool) 
    {
        if(msg.sender == customallow)
        { return super.customtransfer(_to, _value); }
        else 
        { return false; }
    }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) 
  {
    return super.transferFrom(_from, _to, _value);
  }
}

contract BurnableToken is StandardToken 
{

    event Burn(address indexed burner, uint256 value);


    function burn(uint256 _value) public 
    {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }
}

contract MintableToken is StandardToken, Ownable 
{
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;

  modifier canMint() 
  {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) 
  {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  
  function finishMinting() onlyOwner returns (bool) 
  {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract NewTokenBitCoinAir is BurnableToken, PausableToken, MintableToken 
{


    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping (address => bool) public frozenAccount;
    string  public constant symbol = "BABT";
    string public constant name = "Bitcoin Air Bounty Token";
    uint8 public constant decimals = 0;
    event FrozenFunds(address target, bool frozen);

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public 
    {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public 
    {
        frozenAccount[target] = freeze;
    }
    
    function _transfer(address _from, address _to, uint _value) internal 
    {
        require (_to != 0x0);
        require (balances[_from] >= _value);
        require (balances[_to] + _value > balances[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
    }
    
    function buy() payable public 
    {
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }
    
    function sell(uint256 amount) public 
    {
        require(this.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }
    
    function burn(uint256 _value) whenNotPaused public 
    {
        super.burn(_value);
    }
}