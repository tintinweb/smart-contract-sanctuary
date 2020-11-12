/**
 *Submitted for verification at Etherscan.io on 2018-09-17
*/

pragma solidity ^0.4.4;


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
// @Name IVYBase
// @Desc ERC20-based token
// ----------------------------------------------------------------------------
contract IVYBase is ERC20Interface {
    using SafeMath for uint;

    uint                                                _totalSupply;
    mapping(address => uint256)                         _balances;
    mapping(address => mapping(address => uint256))     _allowance;

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return _balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return _allowance[tokenOwner][spender];
    }

    function transfer(address to, uint value) public returns (bool success) {
        require( _balances[msg.sender] >= value);

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= _balances[from]);
        require(value <= _allowance[from][msg.sender]);
        
        _balances[from] = _balances[from].sub(value);
        _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((value != 0) && (_allowance[msg.sender][spender] != 0)) {
            return false;
        }
        
        _allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function increaseApproval (address spender, uint addedValue) public returns (bool success) {
        uint oldValue = _allowance[msg.sender][spender];
        _allowance[msg.sender][spender] = oldValue.add(addedValue);
        return true;
    }
    
    function decreaseApproval (address spender, uint subtractedValue) public returns (bool success) {
        uint oldValue = _allowance[msg.sender][spender];
        if (subtractedValue > oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        return true;
    }

}

// ----------------------------------------------------------------------------
// @Name IVY
// @Desc ERC20 token
// ----------------------------------------------------------------------------
contract IVY is IVYBase {
    string public name;
    uint8 public decimals;
    string public symbol;

    // Admin IVY Address
    address public owner;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    event EventBurnCoin(address a_burnAddress, uint a_amount);
    event EventAddCoin(uint a_amount, uint a_totalSupply);

    constructor(uint a_totalSupply, string a_tokenName, string a_tokenSymbol, uint8 a_decimals) public {
        owner = msg.sender;
        
        _totalSupply = a_totalSupply;
        _balances[msg.sender] = a_totalSupply;

        name = a_tokenName;
        symbol = a_tokenSymbol;
        decimals = a_decimals;
    }

    function burnCoin(uint value) external isOwner
    {
        require(_balances[msg.sender] >= value);

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);

        emit EventBurnCoin(msg.sender, value);
    }

    function addCoin(uint value) external isOwner
    {
        _balances[msg.sender] = _balances[msg.sender].add(value);
        _totalSupply = _totalSupply.add(value);

        emit EventAddCoin(value, _totalSupply);
    }
}