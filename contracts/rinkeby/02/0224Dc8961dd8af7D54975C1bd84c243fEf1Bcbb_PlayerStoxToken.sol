/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.0;


// 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

// 
interface IPlayerStoxFactory {
    function userWithdraw(address token_, address user_, uint256 amount_) external;
    function userDeposit(address token_, address user_, uint256 amount_) external;
}

// 
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// 
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// 
/**
 * @dev Implementation of the {IERC20} interface.
 */
contract PlayerStoxToken is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    enum OrderType { BUY, SELL }

    struct OrderInfo {
        address user;
        address token;
        uint256 amount;
        uint256 quantity;
        uint256 timestamp;
        OrderType orderType;
        bool inETH;
    }

    bool public transferEnabled;
    address public factoryAddress;
    mapping(string => OrderInfo) public orders;
    mapping(address => OrderInfo[]) public userOrders;

    /**
     * @dev Initializes the Player Stox Token Contract.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param decimals_ The number of decimals for the token.
     */
    function initialize(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_)
        external initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        factoryAddress = msg.sender;
        transferEnabled = false;
        // mint tokens for dividends
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of a particular `account_`.
     * @param account_ The account to check balance.
     */
    function balanceOf(address account_) public view virtual override returns (uint256) {
        return _balances[account_];
    }

    /**
     * @dev Move `amount_` of token to `recipient_`.
     * @param recipient_ The address to transfer to transfer token.
     * @param amount_ The amount of token to be transferred.
     *
     */
    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient_, amount_);
        return true;
    }

    /**
     * @dev Returns allowance for a particular `spender_` to transfer tokens that belong to `owner_`.
     * @param owner_ The owner of the token.
     * @param spender_ The address of the spender to check allowance for.
     */
    function allowance(address owner_, address spender_) public view virtual override returns (uint256) {
        return _allowances[owner_][spender_];
    }

    /**
     * @dev Approve `spender_` address to transfer `amount_` tokens.
     * @param spender_ The address to approve for transferring tokens.
     * @param amount_ The amount of token to be approved.
     */
    function approve(address spender_, uint256 amount_) public virtual override returns (bool) {
        _approve(_msgSender(), spender_, amount_);
        return true;
    }

    /**
     * @dev Move `amount_` tokens from `sender_` address to `recipient_` address.
     * @param sender_ The address from which token has to be transferred.
     * @param recipient_ The address to which token has to be transferred.
     * @param amount_ The amount of token to be transferred.
     */
    function transferFrom(address sender_, address recipient_, uint256 amount_) public virtual override returns (bool) {
        _transfer(sender_, recipient_, amount_);
        _approve(sender_, _msgSender(), _allowances[sender_][_msgSender()].sub(amount_));
        return true;
    }

    function quoteQuantity(uint256 amount_, address token_) public view returns (uint256) {
        // convert the amount to USDT
        // calculate quantity
        return 5;
    }

    function quoteAmount(uint256 quantity_, address token_) public view returns (uint256) {
        // calculate amount in USDT
        // convert amount to token_
        return 100;
    }

    // input is variable, output is fixed
    function buyExactStoxForTokens(address token_, uint amountMax_, uint256 quantity_, string memory orderId_) external {
        uint256 currentAmount = quoteAmount(quantity_, token_);
        require(currentAmount <= amountMax_, "Price has fluctuated beyond slippage");
        // check for orderId
        IPlayerStoxFactory(factoryAddress).userDeposit(token_, msg.sender, currentAmount);
        _mint(msg.sender, quantity_);
        OrderInfo memory order;
        order.user = msg.sender;
        order.amount = currentAmount;
        order.token = address(token_);
        order.orderType = OrderType.BUY;
        order.quantity = quantity_;
        order.timestamp = block.timestamp;
        order.inETH = false;
        orders[orderId_] = order;
        userOrders[msg.sender].push(order);
    }

    // input is fixed, output is variable
    function buyStoxForExactTokens(address token_, uint256 amount_, uint256 quantityMin_, string memory orderId_) external {
        uint256 currentQuantity = quoteQuantity(amount_, token_);
        require(currentQuantity >= quantityMin_, "Price has fluctuated beyond slippage");
        // check for orderId
        IPlayerStoxFactory(factoryAddress).userDeposit(token_, msg.sender, amount_);
        _mint(msg.sender, currentQuantity);
        OrderInfo memory order;
        order.user = msg.sender;
        order.amount = amount_;
        order.token = address(token_);
        order.orderType = OrderType.BUY;
        order.quantity = currentQuantity;
        order.timestamp = block.timestamp;
        order.inETH = false;
        orders[orderId_] = order;
        userOrders[msg.sender].push(order);
    }

    // input is fixed, output is variable
    function sellExactStoxForTokens(address token_, uint256 amountMin_, uint256 quantity_, string memory orderId_) external {
        uint256 currentAmount = quoteAmount(quantity_, token_);
        require(currentAmount >= amountMin_, "Price has fluctuated beyond slippage");
        // check for orderId
        IPlayerStoxFactory(factoryAddress).userWithdraw(token_, msg.sender, currentAmount);
        _burn(msg.sender, quantity_);
        OrderInfo memory order;
        order.user = msg.sender;
        order.amount = currentAmount;
        order.token = address(token_);
        order.orderType = OrderType.SELL;
        order.quantity = quantity_;
        order.timestamp = block.timestamp;
        order.inETH = false;
        orders[orderId_] = order;
        userOrders[msg.sender].push(order);
    }

    // input is variable, output is fixed
    function sellStoxForExactTokens(address token_, uint256 amount_, uint256 quantityMax_, string memory orderId_) external {
        uint256 currentQuantity = quoteQuantity(quantityMax_, token_);
        require(currentQuantity <= quantityMax_, "Price has fluctuated beyond slippage");
        // check for orderId
        IPlayerStoxFactory(factoryAddress).userWithdraw(token_, msg.sender, amount_);
        _burn(msg.sender, currentQuantity);
        OrderInfo memory order;
        order.user = msg.sender;
        order.amount = amount_;
        order.token = address(token_);
        order.orderType = OrderType.SELL;
        order.quantity = currentQuantity;
        order.timestamp = block.timestamp;
        order.inETH = false;
        orders[orderId_] = order;
        userOrders[msg.sender].push(order);
    }

    /**
     * @dev Moves `amount_` tokens from `sender_` to `recipient_`.
     * @param sender_ The address from which token has to be transferred.
     * @param recipient_ The address to which token has to be transferred.
     * @param amount_ The amount of token to be transferred.
     */
    function _transfer(address sender_, address recipient_, uint256 amount_) internal virtual {
        require(transferEnabled, "Transfer is not enabled for this stox.");
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");

        _balances[sender_] = _balances[sender_].sub(amount_);
        _balances[recipient_] = _balances[recipient_].add(amount_);
        emit Transfer(sender_, recipient_, amount_);
    }

    /** @dev Creates `amount_` tokens and assigns them to `account_`, increasing
     * the total supply.
     * @param account_ The account to assign tokens to.
     * @param amount_ The amount of token to be minted and assigned.
     */
    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address(0), account_, amount_);
    }

    /**
     * @dev Destroys `amount_` tokens from `account_`, reducing the
     * total supply.
     * @param account_ The account to destroy token from.
     * @param amount_ The amount of token to be destroyed.
     */
    function _burn(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: burn from the zero address");

        _balances[account_] = _balances[account_].sub(amount_);
        _totalSupply = _totalSupply.sub(amount_);
        emit Transfer(account_, address(0), amount_);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * @param owner_ The owner of the token.
     * @param spender_ The address to approve for transferring tokens.
     * @param amount_ The amount of token to be approved.
     */
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
}

// No option to enableTransfer
// how we will support matic