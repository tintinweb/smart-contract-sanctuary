pragma solidity 0.4.24;

// File: contracts/commons/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/base/BaseExchangeableTokenInterface.sol

interface BaseExchangeableTokenInterface {

    // Sender interface must have:
    // mapping(address => uint) private exchangedWith;
    // mapping(address => uint) private exchangedBy;

    // Receiver interface must have:
    // mapping(address => uint) private exchangesReceived;

    /// @dev Fired if token exchange complete
    event Exchange(address _from, address _targetContract, uint _amount);

    /// @dev Fired if token exchange and spent complete
    event ExchangeSpent(address _from, address _targetContract, address _to, uint _amount);

    // Sender interface
    function exchangeToken(address _targetContract, uint _amount) external returns (bool success, uint creditedAmount);

    function exchangeAndSpend(address _targetContract, uint _amount, address _to) external returns (bool success);

    function __exchangerCallback(address _targetContract, address _exchanger, uint _amount) external returns (bool success);

    // Receiver interface
    function __targetExchangeCallback(uint _amount) external returns (bool success);

    function __targetExchangeAndSpendCallback(address _to, uint _amount) external returns (bool success);
}

// File: contracts/flavours/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/flavours/Lockable.sol

/**
 * @title Lockable
 * @dev Base contract which allows children to
 *      implement main operations locking mechanism.
 */
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

    /**
     * @dev Modifier to make a function callable
    *       only when the contract is not locked.
     */
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

    /**
     * @dev Modifier to make a function callable
     *      only when the contract is locked.
     */
    modifier whenLocked() {
        require(locked);
        _;
    }

    /**
     * @dev called by the owner to lock, triggers locked state
     */
    function lock() public onlyOwner whenNotLocked {
        locked = true;
        emit Lock();
    }

    /**
     * @dev called by the owner
     *      to unlock, returns to unlocked state
     */
    function unlock() public onlyOwner whenLocked {
        locked = false;
        emit Unlock();
    }
}

// File: contracts/base/BaseFixedERC20Token.sol

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

    /// @dev ERC20 Total supply
    uint public totalSupply;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) private allowed;

    /// @dev Fired if token is transferred according to ERC20 spec
    event Transfer(address indexed from, address indexed to, uint value);

    /// @dev Fired if token withdrawal is approved according to ERC20 spec
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Gets the balance of the specified address
     * @param owner_ The address to query the the balance of
     * @return An uint representing the amount owned by the passed address
     */
    function balanceOf(address owner_) public view returns (uint balance) {
        return balances[owner_];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to_ The address to transfer to.
     * @param value_ The amount to be transferred.
     */
    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[msg.sender]);
        // SafeMath.sub will throw an exception if there is not enough balance
        balances[msg.sender] = balances[msg.sender].sub(value_);
        balances[to_] = balances[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from_ address The address which you want to send tokens from
     * @param to_ address The address which you want to transfer to
     * @param value_ uint the amount of tokens to be transferred
     */
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        emit Transfer(from_, to_, value_);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering
     *
     * To change the approve amount you first have to reduce the addresses
     * allowance to zero by calling `approve(spender_, 0)` if it is not
     * already 0 to mitigate the race condition described in:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param spender_ The address which will spend the funds.
     * @param value_ The amount of tokens to be spent.
     */
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     * @param owner_ address The address which owns the funds
     * @param spender_ address The address which will spend the funds
     * @return A uint specifying the amount of tokens still available for the spender
     */
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
    }
}

// File: contracts/base/BaseTokenExchangeInterface.sol

interface BaseTokenExchangeInterface {
    // Token exchange service contract must have:
    // address[] private registeredTokens;

    /// @dev Fired if token exchange complete
    event Exchange(address _from, address _by, uint _value, address _target);

    /// @dev Fired if token exchange and spent complete
    event ExchangeAndSpent(address _from, address _by, uint _value, address _target, address _to);

    function registerToken(address _token) external returns (bool success);

    function exchangeToken(address _targetContract, uint _amount) external returns (bool success, uint creditedAmount);

    function exchangeAndSpend(address _targetContract, uint _amount, address _to) external returns (bool success);
}

// File: contracts/base/BaseExchangeableToken.sol

/**
 * @dev ERC20 and EIP-823 (exchangeable) compliant token.
 */
contract BaseExchangeableToken is BaseExchangeableTokenInterface, BaseFixedERC20Token {
    using SafeMath for uint;

    BaseTokenExchangeInterface public exchange;

    /// @dev Fired if token is change exchange. (extends EIP-823)
    event ExchangeChanged(address _exchange);

    /**
     * @dev Modifier to make a function callable
     *      only when the exchange contract is set.
     */
    modifier whenConfigured() {
        require(exchange != address(0));
        _;
    }

    /**
     * @dev Modifier to make a function callable
     *      only by exchange contract
     */
    modifier onlyExchange() {
        require(msg.sender == address(exchange));
        _;
    }

    // Sender interface
    /// @dev number of tokens exchanged to another tokens for each token address
    mapping(address => uint) private exchangedWith;

    /// @dev number of tokens exchanged to another tokens for each user address
    mapping(address => uint) private exchangedBy;

    // Receiver interface
    /// @dev number of tokens exchanged from another tokens for each token address
    mapping(address => uint) private exchangesReceived;

    /// @dev change exchange for this token. (extends EIP-823)
    function changeExchange(address _exchange) public onlyOwner {
        require(_exchange != address(0));
        exchange = BaseTokenExchangeInterface(_exchange);
        emit ExchangeChanged(_exchange);
    }

    // Sender interface
    /**
     * @dev exchange amount of this token to target token
     * @param _targetContract target token contract
     * @param _amount amount of tokens to exchange
     * @return (true, creditedAmount) on success.
     *          (false, 0) on:
     *              nothing =)
     *          revert on:
     *              exchangeToken in exchange contract return (false, 0)
     *              exchange address is not configured
     *              balance of tokens less then amount to exchange
     */
    function exchangeToken(address _targetContract, uint _amount) public whenConfigured returns (bool success, uint creditedAmount) {
        require(_targetContract != address(0) && _amount <= balances[msg.sender]);
        (success, creditedAmount) = exchange.exchangeToken(_targetContract, _amount);
        if (!success) {
            revert();
        }
        emit Exchange(msg.sender, _targetContract, _amount);
        return (success, creditedAmount);
    }

    /**
     * @dev exchange amount of this token to target token and transfer to specified address
     * @param _targetContract target token contract
     * @param _amount amount of tokens to exchange
     * @param _to address for transferring exchanged tokens
     * @return true on success.
     *          false on:
     *              nothing =)
     *          revert on:
     *              exchangeTokenAndSpend in exchange contract return false
     *              exchange address is not configured
     *              balance of tokens less then amount to exchange
     */
    function exchangeAndSpend(address _targetContract, uint _amount, address _to) public whenConfigured returns (bool success) {
        require(_targetContract != address(0) && _to != address(0) && _amount <= balances[msg.sender]);
        success = exchange.exchangeAndSpend(_targetContract, _amount, _to);
        if (!success) {
            revert();
        }
        emit ExchangeSpent(msg.sender, _targetContract, _to, _amount);
        return success;
    }

    /**
     * @dev send amount of this token to exchange. Must be called only from exchange contract
     * @param _targetContract target token contract
     * @param _exchanger address of user, who exchange tokens
     * @param _amount amount of tokens to exchange
     * @return true on success.
     *          false on:
     *              balance of tokens less then amount to exchange
     *          revert on:
     *              exchange address is not configured
     *              called not by configured exchange address
     */
    function __exchangerCallback(address _targetContract, address _exchanger, uint _amount) public whenConfigured onlyExchange returns (bool success) {
        require(_targetContract != address(0));
        if (_amount > balances[_exchanger]) {
            return false;
        }
        balances[_exchanger] = balances[_exchanger].sub(_amount);
        exchangedWith[_targetContract] = exchangedWith[_targetContract].add(_amount);
        exchangedBy[_exchanger] = exchangedBy[_exchanger].add(_amount);
        return true;
    }

    // Receiver interface
    /**
     * @dev receive amount of tokens from exchange. Must be called only from exchange contract
     * @param _amount amount of tokens to receive
     * @return true on success.
     *          false on:
     *              nothing =)
     *          revert on:
     *              exchange address is not configured
     *              called not by configured exchange address
     */
    function __targetExchangeCallback(uint _amount) public whenConfigured onlyExchange returns (bool success) {
        balances[tx.origin] = balances[tx.origin].add(_amount);
        exchangesReceived[tx.origin] = exchangesReceived[tx.origin].add(_amount);
        emit Exchange(tx.origin, this, _amount);
        return true;
    }

    /**
     * @dev receive amount of tokens from exchange and transfer to specified address. Must be called only from exchange contract
     * @param _amount amount of tokens to receive
     * @param _to address for transferring exchanged tokens
     * @return true on success.
     *          false on:
     *              nothing =)
     *          revert on:
     *              exchange address is not configured
     *              called not by configured exchange address
     */
    function __targetExchangeAndSpendCallback(address _to, uint _amount) public whenConfigured onlyExchange returns (bool success) {
        balances[_to] = balances[_to].add(_amount);
        exchangesReceived[_to] = exchangesReceived[_to].add(_amount);
        emit ExchangeSpent(tx.origin, this, _to, _amount);
        return true;
    }
}

// File: contracts/BitoxToken.sol

/**
 * @title Bitox token contract.
 */
contract BitoxToken is BaseExchangeableToken {
    using SafeMath for uint;

    string public constant name = "BitoxTokens";

    string public constant symbol = "BITOX";

    uint8 public constant decimals = 18;

    uint internal constant ONE_TOKEN = 1e18;

    constructor(uint totalSupplyTokens_) public {
        locked = false;
        totalSupply = totalSupplyTokens_ * ONE_TOKEN;
        address creator = msg.sender;
        balances[creator] = totalSupply;

        emit Transfer(0, this, totalSupply);
        emit Transfer(this, creator, balances[creator]);
    }

    // Disable direct payments
    function() external payable {
        revert();
    }

}