//SourceUnit: BasicToken.sol

pragma solidity 0.5.8;

import  "./Pauseable.sol";
import "./SafeMath.sol";

/**
 * @title TRC20Basic
 * @dev Simpler version of TRC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */

contract TRC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic Token
 * @dev Basic version of Standard Token, with no allowances. 
 */

contract BasicToken is TRC20Basic, Pauseable {
    
    using SafeMath for uint256;
    
    mapping(address => uint256) internal Frozen;
    
    mapping(address => uint256) internal _balances;
    
    /**
     * @dev transfer token to a specified address
     * @param to The address to which tokens are transfered.
     * @param value The amount which is transferred.
     */
    
    function transfer(address to, uint256 value) public stoppable validRecipient(to) returns(bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0));
        require(value > 0);
        require(_balances[from].sub(Frozen[from]) >= value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Gets the balance of a specified address.
     * @param _owner is the address to query the balance of. 
     * @return uint256 representing the amount owned by the address.
     */

   function balanceOf(address _owner) public view returns(uint256) {
      return _balances[_owner];
    }

    /**
     * @dev Gets the available balance of a specified address which is not frozen.
     * @param _owner is the address to query the available balance of. 
     * @return uint256 representing the amount owned by the address which is not frozen.
     */

    function availableBalance(address _owner) public view returns(uint256) {
        return _balances[_owner].sub(Frozen[_owner]);
    }

    /**
     * @dev Gets the frozen balance of a specified address.
     * @param _owner is the address to query the frozen balance of. 
     * @return uint256 representing the amount owned by the address which is frozen.
     */

    function frozenOf(address _owner) public view returns(uint256) {
        return Frozen[_owner];
    }

    /**
     * @dev a modifier to avoid a functionality to be applied on zero address and token contract.
     */

    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
    _;
    }
}


//SourceUnit: KinToken.sol

pragma solidity 0.5.8;

import "./SmartToken.sol";

contract KinToken is SmartToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor() public {
        _name = "King Tech";
        _symbol = "KIN";
        _decimals = 6;
        mint(msg.sender, 500000000e6);
    }

    /**
     * @dev Returns name of the token.
    */

    function name() public view returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns symbol of the token.
    */

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns decimals of the token.
     */

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    event Freeze(address indexed from, address indexed to, uint256 value);
    event Melt(address indexed from ,address indexed to, uint256 value);
    
    /**
     * @dev transfer frozen tokens to a specified address
     * @param to is the address to which frozen tokens are transfered.
     * @param value is the frozen amount which is transferred.
     */

    function freeze(address to, uint256 value) public onlyOwner stoppable returns(bool) {
        _freeze(msg.sender, to, value);
        return true;
    }

    function _freeze(address _from, address to, uint256 value) private {
        Frozen[to] = Frozen[to].add(value);
        _transfer(_from, to, value);
        emit Freeze(_from ,to, value);
    }

    /**
     * @dev melt frozen tokens of specified address
     * @param to is the address from which frozen tokens are molten.
     * @param value is the frozen amount which is molten.
     */
    
    function melt(address to, uint256 value) public  onlyOwner stoppable returns(bool) {
        _melt(msg.sender, to, value);
        return true;
    }
    
    function _melt(address _onBehalfOf, address to, uint256 value) private {
        require(Frozen[to] >= value);
        Frozen[to] = Frozen[to].sub(value);
        emit Melt(_onBehalfOf, to, value);
    }
    
    function transferAnyTRC20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        ITRC20(_tokenAddress).transfer(_to, _amount);
    }

    function transferTRC10Token(address toAddress, uint256 tokenValue, trcToken id) public onlyOwner {
        address(uint160(toAddress)).transferToken(tokenValue, id);
    }

    function withdrawTRX() public onlyOwner returns(bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }
}

//SourceUnit: Ownable.sol

pragma solidity 0.5.8;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
    
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    
    function owner() public view returns (address) {
        return _owner;
    }
}


//SourceUnit: Pauseable.sol

pragma solidity 0.5.8;

import "./Ownable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifier `stoppable`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifier is put in place.
 */

contract Pauseable is Ownable {

    /**
     * @dev Emitted when the pause is triggered by `owner`.
     */

    event Stopped(address _owner);

    /**
     * @dev Emitted when the pause is lifted by `owner`.
     */

    event Started(address _owner);

    bool private stopped;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    
    constructor() internal {
        stopped = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */

    modifier stoppable {
        require(!stopped);
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */

    function paused() public view returns (bool) {
        return stopped;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */

    function halt() public onlyOwner {
        stopped = true;
        emit Stopped(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */

    function start() public onlyOwner {
        stopped = false;
        emit Started(msg.sender);
    }
}

//SourceUnit: SafeMath.sol

pragma solidity 0.5.8;

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
     * - Addition cannot overflow.
     */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
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
     * - Multiplication cannot overflow.
     */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
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
     * - The divisor cannot be zero.
     */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}

//SourceUnit: SmartToken.sol

pragma solidity 0.5.8;

import "./StandardToken.sol";

/**
 * @title ITRC677 Token interface
 * @dev see https://github.com/ethereum/EIPs/issues/677
 */

contract ITRC677 is ITRC20 {
    function transferAndCall(address receiver, uint value, bytes memory data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

/**
 * @title ITRC677 Receiving Contract interface
 * @dev see https://github.com/ethereum/EIPs/issues/677
 */

contract TRC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes memory _data) public;
}

/**
 * @title Smart Token
 * @dev Enhanced Standard Token, with "transfer and call" possibility.
 */

contract SmartToken is ITRC677, StandardToken {
    
    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contract.
     * @param _to address to transfer to.
     * @param _value amount to be transferred.
     * @param _data extra data to be passed to the receiving contract.
     */

    function transferAndCall(address _to, uint256 _value, bytes memory _data) public validRecipient(_to) returns(bool success) {
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(address _to, uint _value, bytes memory _data) private {
    TRC677Receiver receiver = TRC677Receiver(_to);
    receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
    }
    
}


//SourceUnit: StandardToken.sol

pragma solidity 0.5.8;

import "./BasicToken.sol";

/**
 * @title ITRC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

contract ITRC20 is TRC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard token
 * @dev Enhanced Basic Token, with "allowance" possibility.
 */

contract StandardToken is ITRC20, BasicToken {

    mapping(address => mapping(address => uint256)) private _allowed;

    /**
     * @dev Approving an address to acquire allowance of spending a certain amount of tokens on behalf of msg.sender.
     * @param spender the address which will spend the funds.
     * @param value the amount of tokens to be spent.
     */

    function approve(address spender, uint256 value) public stoppable validRecipient(spender) returns(bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function _approve(address _owner, address spender, uint256 value) private {
        _allowed[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
    
    /**
     * @dev Transfer tokens from one address to another.
     * @param from the address which you want to send tokens from.
     * @param to the address which you want to transfer to.
     * @param value the amount of tokens to be transferred.
     */

     function transferFrom(address from, address to, uint256 value) public  stoppable validRecipient(to) returns(bool) {
        require(_allowed[from][msg.sender] >= value);
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner the address which owns the funds.
   * @param _spender the address which is allowed to be able to spend the funds.
   * @return uint256 specifying the amount of tokens still available for the spender.
   */

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowed[_owner][_spender];
    }
    
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * Requirements: `spender` cannot be the zero address.
     */

    function increaseAllowance(address spender, uint256 addedValue) public stoppable validRecipient(spender) returns(bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }
    
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * Requirements: `spender` cannot be the zero address.
     */
    
    function decreaseAllowance(address spender, uint256 subtractValue) public stoppable validRecipient(spender) returns(bool) {
        uint256 oldValue = _allowed[msg.sender][spender];
        if(subtractValue > oldValue) {
            _approve(msg.sender, spender, 0);
        }
        else {
            _approve(msg.sender, spender, oldValue.sub(subtractValue));
        }
        return true;
    }

    /** @dev Creates "amount" tokens and assigns them to `account`, increasing
     *  the total supply.
     *  Emits a {Transfer} event with "from" set to the zero address.
     *  Requirements: "to" cannot be the zero address.
     */

    function mint(address account, uint256 amount) public onlyOwner stoppable validRecipient(account) returns(bool) {
        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    /**
     * @dev Destroys "amount" tokens from "account", reducing the
     * total supply.
     * Emits a {Transfer} event with "to" set to the zero address.
     * Requirements: "account" cannot be the zero address and must have at least "amount" tokens.
     */

    function burn(uint256 amount) public stoppable onlyOwner returns(bool) {
        require(amount > 0 && _balances[msg.sender] >= amount);
        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

}