pragma solidity ^0.5.16;

import "../../contracts/SafeMath.sol";

interface ERC20Base {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract ERC20 is ERC20Base {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ERC20NS is ERC20Base {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
}

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 *  See https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

/**
 * @title Non-Standard ERC20 token
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
contract NonStandardToken is ERC20NS {
    using SafeMath for uint256;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
    }

    function transferFrom(address src, address dst, uint256 amount) external {
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

contract ERC20Harness is StandardToken {
    // To support testing, we can specify addresses for which transferFrom should fail and return false
    mapping (address => bool) public failTransferFromAddresses;

    // To support testing, we allow the contract to always fail `transfer`.
    mapping (address => bool) public failTransferToAddresses;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public
        StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function harnessSetFailTransferFromAddress(address src, bool _fail) public {
        failTransferFromAddresses[src] = _fail;
    }

    function harnessSetFailTransferToAddress(address dst, bool _fail) public {
        failTransferToAddresses[dst] = _fail;
    }

    function harnessSetBalance(address _account, uint _amount) public {
        balanceOf[_account] = _amount;
    }

    function transfer(address dst, uint256 amount) external returns (bool success) {
        // Added for testing purposes
        if (failTransferToAddresses[dst]) {
            return false;
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool success) {
        // Added for testing purposes
        if (failTransferFromAddresses[src]) {
            return false;
        }
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }
}

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}