/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

/*
  Implement ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
*/

pragma solidity ^0.5.10;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address payable public _owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable _newOwner) internal {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract Token {
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 amount) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 amount) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Zero destination address");
        require(_value > 0, "Transferred value <= 0");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Zero source address");
        require(_to != address(0), "Zero destination address");
        require(_value > 0, "Transferred value <= 0");
        balances[_to] = SafeMath.add(balances[_to], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


contract CustomizedToken is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _decimalUnits
        ) public {
        balances[msg.sender] = _initialAmount; // Give the creator all initial tokens
        totalSupply = _initialAmount;          // Update total supply
        name = _tokenName;                     // Set the name for display purposes
        symbol = _tokenSymbol;                 // Set the symbol for display purposes
        decimals = _decimalUnits;              // Amount of decimals for display purposes
        emit Transfer(address(0), _owner, totalSupply);
    }

    /* This notifies clients about the amount burnt */
    event Burn(address indexed _from, uint256 _value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed _from, uint256 _value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed _from, uint256 _value);

    /* Token that can be irreversibly burned (destroyed) */
    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0, "Burned value <= 0");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        totalSupply = SafeMath.sub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }

    /* Token that can be minted (created) */
    function mint(uint _value) public onlyOwner returns (bool success) {
        require(_value > 0, "Minted value <= 0");
        totalSupply = SafeMath.add(totalSupply, _value);
        balances[_owner] = SafeMath.add(balances[_owner], _value);
        emit Transfer(address(0), _owner, _value);
        return true;
    }

    /* Return the frozen amount */
    mapping (address => uint256) public freezes;
    function freezeOf(address _owner) public view returns (uint256 amount) {
        return freezes[_owner];
    }

    /* Token that can be frozen (locked) */
    function freeze(uint256 _value) public returns (bool success) {
        require(_value > 0, "Frozen value <= 0");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        freezes[msg.sender] = SafeMath.add(freezes[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }

    /* Token that can be unfrozen (unlocked) */
    function unfreeze(uint256 _value) public returns (bool success) {
        require(_value > 0, "Unfrozen value <= 0");
        freezes[msg.sender] = SafeMath.sub(freezes[msg.sender], _value);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    /* Ether withdraw function */
    function withdrawEther(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount <= 0");
        _owner.transfer(_amount);
        emit Transfer(address(this), _owner, _amount);
    }

    /* Fallback function */
    function() external payable {}
}