/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity 0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20
{
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);  //减去用户余额事件
}

contract Owned
{
    address public owner;

    constructor() internal
    {
        owner = msg.sender;
    }

    modifier onlyowner()
    {
        require(msg.sender==owner);
        _;
    }
}

contract pausable is Owned
{
    event Pause();
    event Unpause();
    bool public pause = false;

    modifier whenNotPaused()
    {
        require(!pause);
        _;
    }
    modifier whenPaused()
    {
        require(pause);
        _;
    }

    function pause() onlyowner whenNotPaused public
    {
        pause = true;
        emit Pause();
    }
    function unpause() onlyowner whenPaused public
    {
        pause = false;
        emit Unpause();
    }
}

contract TokenControl is ERC20,pausable
{
    using SafeMath for uint256;
    mapping (address =>uint256) internal balances;
    mapping (address => mapping(address =>uint256)) internal allowed;
    uint256 totaltoken;

    function totalSupply() public view returns (uint256)
    {
        return totaltoken;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool)
    {
        require(_to!=address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused  returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue)
        {
            allowed[msg.sender][_spender] = 0;
        }
        else
        {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function burn(uint256 tokens) public returns (bool) 
    {
        // 檢查夠不夠燒
        require(tokens <= balances[msg.sender]);
        // 減少 total supply
        totaltoken = totaltoken.sub(tokens);
        // 減少 msg.sender balance
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        emit Burn(msg.sender, tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
}

contract claimable is Owned
{
    address public pendingOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyPendingOwner()
    {
        require(msg.sender == pendingOwner);
        _;
    }

     function transferOwnership(address newOwner) onlyowner public
    {
        pendingOwner = newOwner;
    }

    function claimOwnership() onlyPendingOwner public
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract CTOKEN is TokenControl,claimable
{
    using SafeMath for uint256;
    string public constant name    = "CTOKEN";
    string public constant symbol  = "CT";
    uint256 public decimals = 18;
    uint256 totalsupply =  160000*(10**decimals);

    //contract initial
    constructor () public
    {
        balances[0xF966b84a37F9b64Ea588547C40dE23cb62eFa943] = totalsupply;
        totaltoken = totalsupply;
    }
}

contract Crowdsale {
   bool public icoCompleted;
   uint256 public icoStartTime;
   uint256 public icoEndTime;
   uint256 public tokenRate;
   CTOKEN public token;
   address public tokenAddress;
   uint256 public fundingGoal;
   address public owner;
   modifier whenIcoCompleted {
      require(icoCompleted);
      _;
   }
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
   function () public payable {
      buy();
   }
constructor(uint256 _icoStart, uint256 _icoEnd, uint256 _tokenRate, address _tokenAddress, uint256 _fundingGoal) public {
      require(_icoStart != 0 &&
      _icoEnd != 0 &&
      _icoStart < _icoEnd &&
      _tokenRate != 0 &&
      _tokenAddress != address(0) &&
      _fundingGoal != 0);
      icoStartTime = _icoStart;
      icoEndTime = _icoEnd;
      tokenRate = _tokenRate;
      token = CTOKEN(0x199d6407F88462FD6FAFc90f0900F02C97312fdD);
      tokenAddress = _tokenAddress;
      fundingGoal = _fundingGoal;
      owner = msg.sender;
   }
   function buy() public payable {
      uint256 tokensToBuy;
      tokensToBuy = msg.value * 1e5 / 1 ether * tokenRate;
      
      token.transfer(msg.sender, tokensToBuy);
   }
   function extractEther() public whenIcoCompleted onlyOwner {
      owner.transfer(address(this).balance);
   }
}