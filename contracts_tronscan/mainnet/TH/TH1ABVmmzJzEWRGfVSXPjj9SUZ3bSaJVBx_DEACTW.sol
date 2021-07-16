//SourceUnit: DEACTW.sol

pragma solidity 0.5.10;

import "./IERC20.sol";
import "./SafeMath.sol";

contract DEACTW is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;
    mapping (address => mapping(address => uint256)) public allowed;

    address public owner;

    uint256 public _totalSupply;
    string public constant name = 'Decentralized AU Currency';
    uint8 public constant decimals = 6;
    string public constant symbol = 'DEACTW';

    event Burn(address indexed burner, uint256 token);

    constructor () public {
        _totalSupply = 10000 * 10**uint(decimals);
        balances[msg.sender] = _totalSupply;

        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function totalSupply() external view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address addr) external view returns(uint256) {
        return balances[addr];
    }

    function allowance(address addr, address spender) external view returns(uint256) {
        return allowed[addr][spender];
    }

    function transfer(address to, uint256 amount) external returns(bool) {
        require(to != address(0));
        require(balances[msg.sender] >= amount);

        return _transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balances[from] >= value && allowed[from][to] >= value);

        allowed[from][to] = allowed[from][to].sub(value);

        return _transfer(from, to, value);
    }

    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(from, to, value);

        return true;
    }

    function mint(address to, uint256 tokens) external onlyOwner returns (bool) {
        _totalSupply = _totalSupply.add(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(0), to, tokens);

        return true;
    }

    function burn(address to, uint256 tokens) external onlyOwner returns (bool) {
      require(balances[msg.sender] >= tokens);

      balances[msg.sender] = balances[msg.sender].sub(tokens);
      _totalSupply = _totalSupply.sub(tokens);

      emit Transfer(msg.sender, address(0), tokens);
      emit Burn(msg.sender, tokens);

      return true;
    }
}


//SourceUnit: IERC20.sol

pragma solidity ^0.5.10;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: Migrations.sol

pragma solidity 0.5.10;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}