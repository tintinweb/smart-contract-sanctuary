/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/PurchaseListener.sol

pragma solidity ^0.6.6;

interface PurchaseListener {
    // TODO: find out about how to best detect who implements an interface
    //   see at least https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
    // function isPurchaseListener() external returns (bool);

    /**
     * Similarly to ETH transfer, returning false will decline the transaction
     *   (declining should probably cause revert, but that's up to the caller)
     * IMPORTANT: include onlyMarketplace modifier to your implementations!
     */
    function onPurchase(bytes32 productId, address subscriber, uint endTimestamp, uint priceDatacoin, uint feeDatacoin)
        external returns (bool accepted);
}

// File: contracts/Ownable.sol

pragma solidity ^0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "onlyPendingOwner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/Marketplace.sol

// solhint-disable not-rely-on-time
pragma solidity ^0.6.6;






interface IMarketplace {
    enum ProductState {
        NotDeployed,                // non-existent or deleted
        Deployed                    // created or redeployed
    }

    enum Currency {
        DATA,                       // "token wei" (10^-18 DATA)
        USD                         // attodollars (10^-18 USD)
    }

    enum WhitelistState{
        None,
        Pending,
        Approved,
        Rejected
    }
    function getSubscription(bytes32 productId, address subscriber) external view returns (bool isValid, uint endTimestamp);
    function getPriceInData(uint subscriptionSeconds, uint price, Currency unit) external view returns (uint datacoinAmount);
}
interface IMarketplace1 is IMarketplace{
    function getProduct(bytes32 id) external view returns (string memory name, address owner, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds, ProductState state);
}
interface IMarketplace2 is IMarketplace{
    function getProduct(bytes32 id) external view returns (string memory name, address owner, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds, ProductState state, bool requiresWhitelist);
    function buyFor(bytes32 productId, uint subscriptionSeconds, address recipient) external;
}
/**
 * @title Streamr Marketplace
 * @dev note about numbers:
 *   All prices and exchange rates are in "decimal fixed-point", that is, scaled by 10^18, like ETH vs wei.
 *  Seconds are integers as usual.
 *
 * Next version TODO:
 *  - EIP-165 inferface definition; PurchaseListener
 */
contract Marketplace is Ownable, IMarketplace2 {
    using SafeMath for uint256;

    // product events
    event ProductCreated(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductUpdated(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductDeleted(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductImported(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductRedeployed(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductOwnershipOffered(address indexed owner, bytes32 indexed id, address indexed to);
    event ProductOwnershipChanged(address indexed newOwner, bytes32 indexed id, address indexed oldOwner);

    // subscription events
    event Subscribed(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event NewSubscription(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionExtended(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionImported(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionTransferred(bytes32 indexed productId, address indexed from, address indexed to, uint secondsTransferred);

    // currency events
    event ExchangeRatesUpdated(uint timestamp, uint dataInUsd);

    // whitelist events
    event WhitelistRequested(bytes32 indexed productId, address indexed subscriber);
    event WhitelistApproved(bytes32 indexed productId, address indexed subscriber);
    event WhitelistRejected(bytes32 indexed productId, address indexed subscriber);
    event WhitelistEnabled(bytes32 indexed productId);
    event WhitelistDisabled(bytes32 indexed productId);

    //txFee events
    event TxFeeChanged(uint256 indexed newTxFee);


    struct Product {
        bytes32 id;
        string name;
        address owner;
        address beneficiary;        // account where revenue is directed to
        uint pricePerSecond;
        Currency priceCurrency;
        uint minimumSubscriptionSeconds;
        ProductState state;
        address newOwnerCandidate;  // Two phase hand-over to minimize the chance that the product ownership is lost to a non-existent address.
        bool requiresWhitelist;
        mapping(address => TimeBasedSubscription) subscriptions;
        mapping(address => WhitelistState) whitelist;
    }

    struct TimeBasedSubscription {
        uint endTimestamp;
    }

    /////////////// Marketplace lifecycle /////////////////

    ERC20 public datacoin;

    address public currencyUpdateAgent;
    IMarketplace1 prev_marketplace;
    uint256 public txFee;

    constructor(address datacoinAddress, address currencyUpdateAgentAddress, address prev_marketplace_address) Ownable() public {
        _initialize(datacoinAddress, currencyUpdateAgentAddress, prev_marketplace_address);
    }

    function _initialize(address datacoinAddress, address currencyUpdateAgentAddress, address prev_marketplace_address) internal {
        currencyUpdateAgent = currencyUpdateAgentAddress;
        datacoin = ERC20(datacoinAddress);
        prev_marketplace = IMarketplace1(prev_marketplace_address);
    }

    ////////////////// Product management /////////////////

    mapping (bytes32 => Product) public products;
    /*
        checks this marketplace first, then the previous
    */
    function getProduct(bytes32 id) public override view returns (string memory name, address owner, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds, ProductState state, bool requiresWhitelist) {
        (name, owner, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds, state, requiresWhitelist) = _getProductLocal(id);
        if (owner != address(0))
            return (name, owner, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds, state, requiresWhitelist);
        (name, owner, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds, state) = prev_marketplace.getProduct(id);
        return (name, owner, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds, state, false);
    }

    /**
    checks only this marketplace, not the previous marketplace
     */

    function _getProductLocal(bytes32 id) internal view returns (string memory name, address owner, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds, ProductState state, bool requiresWhitelist) {
        Product memory p = products[id];
        return (
            p.name,
            p.owner,
            p.beneficiary,
            p.pricePerSecond,
            p.priceCurrency,
            p.minimumSubscriptionSeconds,
            p.state,
            p.requiresWhitelist
        );
    }

    // also checks that p exists: p.owner == 0 for non-existent products
    modifier onlyProductOwner(bytes32 productId) {
        (,address _owner,,,,,,) = getProduct(productId);
        require(_owner != address(0), "error_notFound");
        require(_owner == msg.sender || owner == msg.sender, "error_productOwnersOnly");
        _;
    }

    /**
     * Imports product details (but NOT subscription details) from previous marketplace
     */
    function _importProductIfNeeded(bytes32 productId) internal returns (bool imported){
        Product storage p = products[productId];
        if (p.id != 0x0) { return false; }
        (string memory _name, address _owner, address _beneficiary, uint _pricePerSecond, IMarketplace1.Currency _priceCurrency, uint _minimumSubscriptionSeconds, IMarketplace1.ProductState _state) = prev_marketplace.getProduct(productId);
        if (_owner == address(0)) { return false; }
        p.id = productId;
        p.name = _name;
        p.owner = _owner;
        p.beneficiary = _beneficiary;
        p.pricePerSecond = _pricePerSecond;
        p.priceCurrency = _priceCurrency;
        p.minimumSubscriptionSeconds = _minimumSubscriptionSeconds;
        p.state = _state;
        emit ProductImported(p.owner, p.id, p.name, p.beneficiary, p.pricePerSecond, p.priceCurrency, p.minimumSubscriptionSeconds);
        return true;
    }

    function _importSubscriptionIfNeeded(bytes32 productId, address subscriber) internal returns (bool imported) {
        bool _productImported = _importProductIfNeeded(productId);

        // check that subscription didn't already exist in current marketplace
        (Product storage product, TimeBasedSubscription storage sub) = _getSubscriptionLocal(productId, subscriber);
        if (sub.endTimestamp != 0x0) { return false; }

        // check that subscription exists in the previous marketplace(s)
        // only call prev_marketplace.getSubscription() if product exists there
        // consider e.g. product created in current marketplace but subscription still doesn't exist
        // if _productImported, it must have existed in previous marketplace so no need to perform check
        if (!_productImported) {
            (,address _owner_prev,,,,,) = prev_marketplace.getProduct(productId);
            if (_owner_prev == address(0)) { return false; }
        }
        (, uint _endTimestamp) = prev_marketplace.getSubscription(productId, subscriber);
        if (_endTimestamp == 0x0) { return false; }
        product.subscriptions[subscriber] = TimeBasedSubscription(_endTimestamp);
        emit SubscriptionImported(productId, subscriber, _endTimestamp);
        return true;
    }
    function createProduct(bytes32 id, string memory name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds) public whenNotHalted {
        _createProduct(id, name, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds, false);
    }

    function createProductWithWhitelist(bytes32 id, string memory name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds) public whenNotHalted {
        _createProduct(id, name, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds, true);
        emit WhitelistEnabled(id);
    }


    function _createProduct(bytes32 id, string memory name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds, bool requiresWhitelist) internal {
        require(id != 0x0, "error_nullProductId");
        require(pricePerSecond > 0, "error_freeProductsNotSupported");
        (,address _owner,,,,,,) = getProduct(id);
        require(_owner == address(0), "error_alreadyExists");
        products[id] = Product({id: id, name: name, owner: msg.sender, beneficiary: beneficiary, pricePerSecond: pricePerSecond,
            priceCurrency: currency, minimumSubscriptionSeconds: minimumSubscriptionSeconds, state: ProductState.Deployed, newOwnerCandidate: address(0), requiresWhitelist: requiresWhitelist});
        emit ProductCreated(msg.sender, id, name, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds);
    }

    /**
    * Stop offering the product
    */
    function deleteProduct(bytes32 productId) public onlyProductOwner(productId) {
        _importProductIfNeeded(productId);
        Product storage p = products[productId];
        require(p.state == ProductState.Deployed, "error_notDeployed");
        p.state = ProductState.NotDeployed;
        emit ProductDeleted(p.owner, productId, p.name, p.beneficiary, p.pricePerSecond, p.priceCurrency, p.minimumSubscriptionSeconds);
    }

    /**
    * Return product to market
    */
    function redeployProduct(bytes32 productId) public onlyProductOwner(productId) {
        _importProductIfNeeded(productId);
        Product storage p = products[productId];
        require(p.state == ProductState.NotDeployed, "error_mustBeNotDeployed");
        p.state = ProductState.Deployed;
        emit ProductRedeployed(p.owner, productId, p.name, p.beneficiary, p.pricePerSecond, p.priceCurrency, p.minimumSubscriptionSeconds);
    }

    function updateProduct(bytes32 productId, string memory name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds, bool redeploy) public onlyProductOwner(productId) {
        require(pricePerSecond > 0, "error_freeProductsNotSupported");
        _importProductIfNeeded(productId);
        Product storage p = products[productId];
        p.name = name;
        p.beneficiary = beneficiary;
        p.pricePerSecond = pricePerSecond;
        p.priceCurrency = currency;
        p.minimumSubscriptionSeconds = minimumSubscriptionSeconds;
        emit ProductUpdated(p.owner, p.id, name, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds);
        if (redeploy) {
            redeployProduct(productId);
        }
    }

    /**
    * Changes ownership of the product. Two phase hand-over minimizes the chance that the product ownership is lost to a non-existent address.
    */
    function offerProductOwnership(bytes32 productId, address newOwnerCandidate) public onlyProductOwner(productId) {
        _importProductIfNeeded(productId);
        // that productId exists is already checked in onlyProductOwner
        products[productId].newOwnerCandidate = newOwnerCandidate;
        emit ProductOwnershipOffered(products[productId].owner, productId, newOwnerCandidate);
    }

    /**
    * Changes ownership of the product. Two phase hand-over minimizes the chance that the product ownership is lost to a non-existent address.
    */
    function claimProductOwnership(bytes32 productId) public whenNotHalted {
        _importProductIfNeeded(productId);
        // also checks that productId exists (newOwnerCandidate is zero for non-existent)
        Product storage p = products[productId];
        require(msg.sender == p.newOwnerCandidate, "error_notPermitted");
        emit ProductOwnershipChanged(msg.sender, productId, p.owner);
        p.owner = msg.sender;
        p.newOwnerCandidate = address(0);
    }

    /////////////// Whitelist management ///////////////

    function setRequiresWhitelist(bytes32 productId, bool _requiresWhitelist) public onlyProductOwner(productId) {
        _importProductIfNeeded(productId);
        Product storage p = products[productId];
        require(p.id != 0x0, "error_notFound");
        p.requiresWhitelist = _requiresWhitelist;
        if (_requiresWhitelist) {
            emit WhitelistEnabled(productId);
        } else {
            emit WhitelistDisabled(productId);
        }
    }

    function whitelistApprove(bytes32 productId, address subscriber) public onlyProductOwner(productId) {
        _importProductIfNeeded(productId);
        Product storage p = products[productId];
        require(p.id != 0x0, "error_notFound");
        require(p.requiresWhitelist, "error_whitelistNotEnabled");
        p.whitelist[subscriber] = WhitelistState.Approved;
        emit WhitelistApproved(productId, subscriber);
    }

    function whitelistReject(bytes32 productId, address subscriber) public onlyProductOwner(productId) {
        _importProductIfNeeded(productId);
        Product storage p = products[productId];
        require(p.id != 0x0, "error_notFound");
        require(p.requiresWhitelist, "error_whitelistNotEnabled");
        p.whitelist[subscriber] = WhitelistState.Rejected;
        emit WhitelistRejected(productId, subscriber);
    }

    function whitelistRequest(bytes32 productId) public {
        _importProductIfNeeded(productId);
        Product storage p = products[productId];
        require(p.id != 0x0, "error_notFound");
        require(p.requiresWhitelist, "error_whitelistNotEnabled");
        require(p.whitelist[msg.sender] == WhitelistState.None, "error_whitelistRequestAlreadySubmitted");
        p.whitelist[msg.sender] = WhitelistState.Pending;
        emit WhitelistRequested(productId, msg.sender);
    }

    function getWhitelistState(bytes32 productId, address subscriber) public view returns (WhitelistState wlstate) {
        (, address _owner,,,,,,) = getProduct(productId);
        require(_owner != address(0), "error_notFound");
        // if product is not local (maybe in old marketplace) this will return 0 (WhitelistState.None)
        Product storage p = products[productId];
        return p.whitelist[subscriber];
    }

    /////////////// Subscription management ///////////////

    function getSubscription(bytes32 productId, address subscriber) public override view returns (bool isValid, uint endTimestamp) {
        (,address _owner,,,,,,) = _getProductLocal(productId);
        if (_owner == address(0)) {
            return prev_marketplace.getSubscription(productId,subscriber);
        }

        (, TimeBasedSubscription storage sub) = _getSubscriptionLocal(productId, subscriber);
        if (sub.endTimestamp == 0x0) {
            // only call prev_marketplace.getSubscription() if product exists in previous marketplace too
            (,address _owner_prev,,,,,) = prev_marketplace.getProduct(productId);
            if (_owner_prev != address(0)) {
                return prev_marketplace.getSubscription(productId,subscriber);
            }
        }
        return (_isValid(sub), sub.endTimestamp);
    }

    function getSubscriptionTo(bytes32 productId) public view returns (bool isValid, uint endTimestamp) {
        return getSubscription(productId, msg.sender);
    }

    /**
     * Checks if the given address currently has a valid subscription
     * @param productId to check
     * @param subscriber to check
     */
    function hasValidSubscription(bytes32 productId, address subscriber) public view returns (bool isValid) {
        (isValid,) = getSubscription(productId, subscriber);
    }

    /**
     * Enforces payment rules, triggers PurchaseListener event
     */
    function _subscribe(bytes32 productId, uint addSeconds, address subscriber, bool requirePayment) internal {
        _importSubscriptionIfNeeded(productId, subscriber);
        (Product storage p, TimeBasedSubscription storage oldSub) = _getSubscriptionLocal(productId, subscriber);
        require(p.state == ProductState.Deployed, "error_notDeployed");
        require(!p.requiresWhitelist || p.whitelist[subscriber] == WhitelistState.Approved, "error_whitelistNotAllowed");
        uint endTimestamp;

        if (oldSub.endTimestamp > block.timestamp) {
            require(addSeconds > 0, "error_topUpTooSmall");
            endTimestamp = oldSub.endTimestamp.add(addSeconds);
            oldSub.endTimestamp = endTimestamp;
            emit SubscriptionExtended(p.id, subscriber, endTimestamp);
        } else {
            require(addSeconds >= p.minimumSubscriptionSeconds, "error_newSubscriptionTooSmall");
            endTimestamp = block.timestamp.add(addSeconds);
            TimeBasedSubscription memory newSub = TimeBasedSubscription(endTimestamp);
            p.subscriptions[subscriber] = newSub;
            emit NewSubscription(p.id, subscriber, endTimestamp);
        }
        emit Subscribed(p.id, subscriber, endTimestamp);

        uint256 price = 0;
        uint256 fee = 0;
        address recipient = p.beneficiary;
        if (requirePayment) {
            price = getPriceInData(addSeconds, p.pricePerSecond, p.priceCurrency);
            fee = txFee.mul(price).div(1 ether);
            require(datacoin.transferFrom(msg.sender, recipient, price.sub(fee)), "error_paymentFailed");
            if (fee > 0) {
                require(datacoin.transferFrom(msg.sender, owner, fee), "error_paymentFailed");
            }
        }

        uint256 codeSize;
        assembly { codeSize := extcodesize(recipient) }  // solhint-disable-line no-inline-assembly
        if (codeSize > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = recipient.call(
                abi.encodeWithSignature("onPurchase(bytes32,address,uint256,uint256,uint256)",
                productId, subscriber, oldSub.endTimestamp, price, fee)
            );

            if (success) {
                (bool accepted) = abi.decode(returnData, (bool));
                require(accepted, "error_rejectedBySeller");
            }
        }
    }

    function grantSubscription(bytes32 productId, uint subscriptionSeconds, address recipient) public whenNotHalted onlyProductOwner(productId){
        return _subscribe(productId, subscriptionSeconds, recipient, false);
    }


    function buyFor(bytes32 productId, uint subscriptionSeconds, address recipient) public override whenNotHalted {
        return _subscribe(productId, subscriptionSeconds, recipient, true);
    }


    /**
     * Purchases access to this stream for msg.sender.
     * If the address already has a valid subscription, extends the subscription by the given period.
     * @dev since v4.0: Notify the seller if the seller implements PurchaseListener interface
     */
    function buy(bytes32 productId, uint subscriptionSeconds) public whenNotHalted {
        buyFor(productId,subscriptionSeconds, msg.sender);
    }


    /** Gets subscriptions info from the subscriptions stored in this contract */
    function _getSubscriptionLocal(bytes32 productId, address subscriber) internal view returns (Product storage p, TimeBasedSubscription storage s) {
        p = products[productId];
        require(p.id != 0x0, "error_notFound");
        s = p.subscriptions[subscriber];
    }

    function _isValid(TimeBasedSubscription storage s) internal view returns (bool) {
        return s.endTimestamp >= block.timestamp;  // solhint-disable-line not-rely-on-time
    }

    // TODO: transfer allowance to another Marketplace contract
    // Mechanism basically is that this Marketplace draws from the allowance and credits
    //   the account on another Marketplace; OR that there is a central credit pool (say, an ERC20 token)
    // Creating another ERC20 token for this could be a simple fix: it would need the ability to transfer allowances

    /////////////// Currency management ///////////////

    // Exchange rates are formatted as "decimal fixed-point", that is, scaled by 10^18, like ether.
    //        Exponent: 10^18 15 12  9  6  3  0
    //                      |  |  |  |  |  |  |
    uint public dataPerUsd = 100000000000000000;   // ~= 0.1 DATA/USD

    /**
    * Update currency exchange rates; all purchases are still billed in DATAcoin
    * @param timestamp in seconds when the exchange rates were last updated
    * @param dataUsd how many data atoms (10^-18 DATA) equal one USD dollar
    */
    function updateExchangeRates(uint timestamp, uint dataUsd) public {
        require(msg.sender == currencyUpdateAgent, "error_notPermitted");
        require(dataUsd > 0, "error_invalidRate");
        dataPerUsd = dataUsd;
        emit ExchangeRatesUpdated(timestamp, dataUsd);
    }

    /**
    * Helper function to calculate (hypothetical) subscription cost for given seconds and price, using current exchange rates.
    * @param subscriptionSeconds length of hypothetical subscription, as a non-scaled integer
    * @param price nominal price scaled by 10^18 ("token wei" or "attodollars")
    * @param unit unit of the number price
    */
    function getPriceInData(uint subscriptionSeconds, uint price, Currency unit) public override view returns (uint datacoinAmount) {
        if (unit == Currency.DATA) {
            return price.mul(subscriptionSeconds);
        }
        return price.mul(dataPerUsd).mul(subscriptionSeconds).div(10**18);
    }

    /////////////// Admin functionality ///////////////

    event Halted();
    event Resumed();
    bool public halted = false;

    modifier whenNotHalted() {
        require(!halted || owner == msg.sender, "error_halted");
        _;
    }
    function halt() public onlyOwner {
        halted = true;
        emit Halted();
    }
    function resume() public onlyOwner {
        halted = false;
        emit Resumed();
    }

    function reInitialize(address datacoinAddress, address currencyUpdateAgentAddress, address prev_marketplace_address) public onlyOwner {
        _initialize(datacoinAddress, currencyUpdateAgentAddress, prev_marketplace_address);
    }

    function setTxFee(uint256 newTxFee) public onlyOwner {
        require(newTxFee <= 1 ether, "error_invalidTxFee");
        txFee = newTxFee;
        emit TxFeeChanged(txFee);
    }
}