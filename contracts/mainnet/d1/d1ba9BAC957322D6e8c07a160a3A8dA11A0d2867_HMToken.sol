/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface HMTokenInterface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function transferBulk(address[] calldata _tos, uint256[] calldata _values, uint256 _txId) external returns (uint256 _bulkCount);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract HMToken is HMTokenInterface {
    using SafeMath for uint256;

    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant BULK_MAX_VALUE = 1000000000 * (10 ** 18);
    uint32  private constant BULK_MAX_COUNT = 100;

    event BulkTransfer(uint256 indexed _txId, uint256 _bulkCount);
    event BulkApproval(uint256 indexed _txId, uint256 _bulkCount);

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    string public name;
    uint8 public decimals;
    string public symbol;

    constructor(uint256 _totalSupply, string memory _name, uint8 _decimals, string memory _symbol) public {
        totalSupply = _totalSupply * (10 ** uint256(_decimals));
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        success = transferQuiet(_to, _value);
        require(success, "Transfer didn't succeed");
        return success;
    }

    function transferFrom(address _spender, address _to, uint256 _value) public override returns (bool success) {
        uint256 _allowance = allowed[_spender][msg.sender];
        require(_allowance >= _value, "Spender allowance too low");
        require(_to != address(0), "Can't send tokens to uninitialized address");

        balances[_spender] = balances[_spender].sub(_value, "Spender balance too low");
        balances[_to] = balances[_to].add(_value);

        if (_allowance != MAX_UINT256) { // Special case to approve unlimited transfers
            allowed[_spender][msg.sender] = allowed[_spender][msg.sender].sub(_value);
        }

        emit Transfer(_spender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        require(_spender != address(0), "Token spender is an uninitialized address");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function increaseApproval(address _spender, uint _delta) public returns (bool success) {
        require(_spender != address(0), "Token spender is an uninitialized address");

        uint _oldValue = allowed[msg.sender][_spender];
        if (_oldValue.add(_delta) < _oldValue || _oldValue.add(_delta) >= MAX_UINT256) { // Truncate upon overflow.
            allowed[msg.sender][_spender] = MAX_UINT256.sub(1);
        } else {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_delta);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _delta) public returns (bool success) {
        require(_spender != address(0), "Token spender is an uninitialized address");

        uint _oldValue = allowed[msg.sender][_spender];
        if (_delta > _oldValue) { // Truncate upon overflow.
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_delta);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferBulk(address[] memory _tos, uint256[] memory _values, uint256 _txId) public override returns (uint256 _bulkCount) {
        require(_tos.length == _values.length, "Amount of recipients and values don't match");
        require(_tos.length < BULK_MAX_COUNT, "Too many recipients");

        uint256 _bulkValue = 0;
        for (uint j = 0; j < _tos.length; ++j) {
            _bulkValue = _bulkValue.add(_values[j]);
        }
        require(_bulkValue < BULK_MAX_VALUE, "Bulk value too high");

        bool _success;
        for (uint i = 0; i < _tos.length; ++i) {
            _success = transferQuiet(_tos[i], _values[i]);
            if (_success) {
                _bulkCount = _bulkCount.add(1);
            }
        }
        emit BulkTransfer(_txId, _bulkCount);
        return _bulkCount;
    }

    function approveBulk(address[] memory _spenders, uint256[] memory _values, uint256 _txId) public returns (uint256 _bulkCount) {
        require(_spenders.length == _values.length, "Amount of spenders and values don't match");
        require(_spenders.length < BULK_MAX_COUNT, "Too many spenders");

        uint256 _bulkValue = 0;
        for (uint j = 0; j < _spenders.length; ++j) {
            _bulkValue = _bulkValue.add(_values[j]);
        }
        require(_bulkValue < BULK_MAX_VALUE, "Bulk value too high");

        bool _success;
        for (uint i = 0; i < _spenders.length; ++i) {
            _success = increaseApproval(_spenders[i], _values[i]);
            if (_success) {
                _bulkCount = _bulkCount.add(1);
            }
        }
        emit BulkApproval(_txId, _bulkCount);
        return _bulkCount;
    }

    // Like transfer, but fails quietly.
    function transferQuiet(address _to, uint256 _value) internal returns (bool success) {
        if (_to == address(0)) return false; // Preclude burning tokens to uninitialized address.
        if (_to == address(this)) return false; // Preclude sending tokens to the contract.
        if (balances[msg.sender] < _value) return false;

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}