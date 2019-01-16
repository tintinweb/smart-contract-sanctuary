pragma solidity ^0.4.24;

/**
 * @title Safe math
 * @dev Math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        /* Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
         * benefit is lost if &#39;b&#39; is also tested.
         * See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
         */
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0.

        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

/**
 * @title ERC-20 token interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Standard ERC-20 token.
 * @dev Implementation of the basic standard token.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @return Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the given address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Transfers tokens for the specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev Transfers tokens from one address to another.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev Checks the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return An uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Increases the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Decreases the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Transfers tokens for a specified address.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    /**
     * @dev Mints an amount of the token and assigns it to an account.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != 0);

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);

        emit Transfer(address(0), account, value);
    }
}

/**
 * @title ERC-20 detailed token template
 * @dev The decimals are only for visualization purposes. All the operations are done using
 * the smallest and indivisible token unit, just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;

    string private _symbol;

    uint8 private _decimals;

    constructor(string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return The name of the token.
     */
    function name() public view returns (string) {
        return _name;
    }

    /**
     * @return The symbol of the token.
     */
    function symbol() public view returns (string) {
        return _symbol;
    }

    /**
     * @return The number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @title ERC-20 extension for multiple recipients
 * @dev Extends the functionality of the ERC-20 standard token with the ability to transfer tokens
 * to multiple recipients in a single transaction.
 */
contract ERC20MultiRecipient is ERC20 {
    function transferMulti(address[] recipients, uint256[] values) public returns (bool) {
        require(recipients.length > 0);
        require(recipients.length == values.length);

        uint256 i;
        uint256 total;

        for (i = 0; i < values.length; i++) {
            total = total.add(values[i]);
        }

        require(total <= _balances[msg.sender]);

        _balances[msg.sender] = _balances[msg.sender].sub(total);

        for (i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0));

            _balances[recipients[i]] = _balances[recipients[i]].add(values[i]);

            emit Transfer(msg.sender, recipients[i], values[i]);
        }

        return true;
    }
}

/**
 * @title DX Token
 */
contract DXToken is ERC20MultiRecipient, ERC20Detailed {
    string private constant NAME = "DX Network Token";

    string private constant SYMBOL = "DXN";

    uint8 private constant DECIMALS = 18;

    uint256 public constant TOTAL_SUPPLY = 100000000 * (10 ** uint256(DECIMALS));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public ERC20Detailed(NAME, SYMBOL, uint8(DECIMALS)) {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}