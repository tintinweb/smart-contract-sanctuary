pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// @Project YouRyuCoin (YRC)
// @Creator RyuChain
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// @Name SafeMath
// @Desc Math operations with safety checks that throw on error
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// ----------------------------------------------------------------------------
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// ----------------------------------------------------------------------------
// @Name YouRyuCoinBase
// @Desc ERC20-based token
// ----------------------------------------------------------------------------
contract YouRyuCoinBase is ERC20Interface {
    using SafeMath for uint;

    uint                                                _totalSupply;
    mapping(address => uint256)                         _balances;
    mapping(address => mapping(address => uint256))     _allowed;

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return _balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require( _balances[msg.sender] >= tokens);

        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        _balances[to] = _balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        _allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= _balances[from]);
        require(tokens <= _allowed[from][msg.sender]);
        
        _balances[from] = _balances[from].sub(tokens);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);
        _balances[to] = _balances[to].add(tokens);

        emit Transfer(from, to, tokens);
        return true;
    }
}
// ----------------------------------------------------------------------------
// @Name YouRyuCoin (YRC)
// @Desc Cutie Ryu
// ----------------------------------------------------------------------------
contract YouRyuCoin is YouRyuCoinBase {
    string public name;
    uint8 public decimals;
    string public symbol;

    // Admin Ryu Address
    address public owner;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    event EventBurnCoin(address a_burnAddress, uint a_amount);
    event EventAddCoin(uint a_amount, uint a_totalSupply);

     function YouRyuCoin(uint a_totalSupply, string a_tokenName, string a_tokenSymbol, uint8 a_decimals) public {
        owner = msg.sender;
        
        _totalSupply = a_totalSupply;
        _balances[msg.sender] = a_totalSupply;

        name = a_tokenName;
        symbol = a_tokenSymbol;
        decimals = a_decimals;
    }

    function burnCoin(uint a_coinAmount) external isOwner
    {
        require(_balances[msg.sender] >= a_coinAmount);

        _balances[msg.sender] = _balances[msg.sender].sub(a_coinAmount);
        _totalSupply = _totalSupply.sub(a_coinAmount);

        emit EventBurnCoin(msg.sender, a_coinAmount);
    }

    function addCoin(uint a_coinAmount) external isOwner
    {
        _balances[msg.sender] = _balances[msg.sender].add(a_coinAmount);
        _totalSupply = _totalSupply.add(a_coinAmount);

        emit EventAddCoin(a_coinAmount, _totalSupply);
    }
}