pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "./lib/SafeMathInt.sol";
import "./ERC20UpgradeSafe.sol";
import "./ERC677Token.sol";

interface ISync {
    function sync() external;
}

interface IGulp {
    function gulp(address token) external;
}

/**
 * @title BASE ERC20 token
 * @dev This is part of an implementation of the BASE Index Fund protocol.
 *      BASE is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      BASE balances are internally represented with a hidden denomination, 'shares'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'shares' and the public 'BASE'.
 */
contract BaseToken is ERC20UpgradeSafe, ERC677Token, OwnableUpgradeSafe {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of shares that equals 1 BASE.
    //    The inverse rate must not be used--totalShares is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert shares to BASE instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Share balances converted into BaseToken are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x BaseToken to address 'B'. A's resulting external balance will
    //   be decreased by precisely x BaseToken, and B's external balance will be precisely
    //   increased by x BaseToken.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);

    // Used for authentication
    address public monetaryPolicy;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 1000000000 * 10**DECIMALS;
    uint256 private constant INITIAL_SHARES = (MAX_UINT256 / (10 ** 36)) - ((MAX_UINT256 / (10 ** 36)) % INITIAL_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalShares;
    uint256 private _totalSupply;
    uint256 private _sharesPerBASE;
    mapping(address => uint256) private _shareBalances;

    mapping(address => bool) public bannedUsers; // Deprecated

    // This is denominated in BaseToken, because the shares-BASE conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedBASE;

    bool private transfersPaused;
    bool public rebasesPaused;

    mapping(address => bool) private transferPauseExemptList;

    function setRebasesPaused(bool _rebasesPaused)
        public
        onlyOwner
    {
        rebasesPaused = _rebasesPaused;
    }

    /**
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */
    function setMonetaryPolicy(address monetaryPolicy_)
        external
        onlyOwner
    {
        monetaryPolicy = monetaryPolicy_;
        emit LogMonetaryPolicyUpdated(monetaryPolicy_);
    }

    /**
     * @dev Notifies BaseToken contract about a new rebase cycle.
     * @param supplyDelta The number of new BASE tokens to add into circulation via expansion.
     * @return The total number of BASE after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        returns (uint256)
    {
        require(msg.sender == monetaryPolicy, "only monetary policy");
        require(!rebasesPaused, "rebases paused");

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _sharesPerBASE = _totalShares.div(_totalSupply);

        // From this point forward, _sharesPerBASE is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _sharesPerBASE
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(totalShares - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.

        emit LogRebase(epoch, _totalSupply);

        /** These DEXes don't exist for PRLX token */
        // ISync(0xdE5b7Ff5b10CC5F8c95A2e2B643e3aBf5179C987).sync();              // Uniswap BASE/ETH
        // ISync(0xD8B8B575c943f3d63638c9563B464D204ED8B710).sync();              // Sushiswap BASE/ETH
        // IGulp(0x19B770c8F9d5439C419864d8458255791f7e736C).gulp(address(this)); // Value BASE/USDC

        return _totalSupply;
    }

    function totalShares()
        public
        view
        returns (uint256)
    {
        return _totalShares;
    }

    function sharesOf(address user)
        public
        view
        returns (uint256)
    {
        return _shareBalances[user];
    }

    function initialize()
        public
        initializer
    {
        __ERC20_init("Tesla Rebase Token", "pTSLA");
        _setupDecimals(uint8(DECIMALS));
        __Ownable_init();

        _totalShares = INITIAL_SHARES;
        _totalSupply = INITIAL_SUPPLY;
        _shareBalances[owner()] = _totalShares;
        _sharesPerBASE = _totalShares.div(_totalSupply);

        emit Transfer(address(0x0), owner(), _totalSupply);
    }

    /**
     * @return The total number of BASE.
     */
    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        override
        view
        returns (uint256)
    {
        return _shareBalances[who].div(_sharesPerBASE);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        override(ERC20UpgradeSafe, ERC677)
        validRecipient(to)
        returns (bool)
    {
        uint256 shareValue = value.mul(_sharesPerBASE);
        _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(shareValue);
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowedBASE[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        override
        validRecipient(to)
        returns (bool)
    {
        _allowedBASE[from][msg.sender] = _allowedBASE[from][msg.sender].sub(value);

        uint256 shareValue = value.mul(_sharesPerBASE);
        _shareBalances[from] = _shareBalances[from].sub(shareValue);
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedBASE[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _allowedBASE[msg.sender][spender] = _allowedBASE[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedBASE[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowedBASE[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedBASE[msg.sender][spender] = 0;
        } else {
            _allowedBASE[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedBASE[msg.sender][spender]);
        return true;
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.
Copyright (c) 2020 Base Protocol, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity 0.6.12;


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

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

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
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
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity 0.6.12;

import "./interfaces/ERC677.sol";
import "./interfaces/ERC677Receiver.sol";


abstract contract ERC677Token is ERC677 {
    /**
    * @dev transfer token to a contract address with additional data if the recipient is a contact.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The extra data to be passed to the receiving contract.
    */
    function transferAndCall(address _to, uint _value, bytes memory _data)
        public
        override
        returns (bool success)
    {
        transfer(_to, _value);
        // emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(address _to, uint _value, bytes memory _data)
        private
    {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr)
        private
        view
        returns (bool hasCode)
    {
        uint length;
        // solhint-disable-next-line no-inline-assembly
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}

pragma solidity 0.6.12;


abstract contract ERC677 {
    function transfer(address to, uint256 value) public virtual returns (bool);
    function transferAndCall(address to, uint value, bytes memory data) public virtual returns (bool success);

    // event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

pragma solidity 0.6.12;


abstract contract ERC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes memory _data) virtual public;
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";
import "./BaseToken.sol";


interface IOracle {
    function getData() external view returns (uint256, bool);
}


/**
 * @title BaseToken Monetary Supply Policy
 * @dev This is an implementation of the BaseToken Index Fund protocol.
 *      BaseToken operates symmetrically on expansion and contraction. It will both split and
 *      combine coins to maintain a stable unit price.
 *
 *      This component regulates the token supply of the BaseToken ERC20 token in response to
 *      market oracles.
 */
contract BaseTokenMonetaryPolicy is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        uint256 mcap,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    BaseToken public BASE;

    // Provides the current market cap, as an 18 decimal fixed point number.
    IOracle public mcapOracle;

    // Market oracle provides the token/USD exchange rate as an 18 decimal fixed point number.
    // (eg) An oracle value of 1.5e18 it would mean 1 BASE is trading for $1.50.
    IOracle public tokenPriceOracle;

    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    // DECIMALS Fixed point number.
    uint256 public deviationThreshold;

    // The rebase lag parameter, used to dampen the applied supply adjustment by 1 / rebaseLag
    // Check setRebaseLag comments for more details.
    // Natural number, no decimal places.
    uint256 public rebaseLag;

    // More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    uint256 public rebaseWindowOffsetSec;

    // The length of the time window where a rebase operation is allowed to execute, in seconds.
    uint256 public rebaseWindowLengthSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**6 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    // This module orchestrates the rebase execution and downstream notification.
    address public orchestrator;

    address[] private charityRecipients;
    mapping(address => bool)    private charityExists;
    mapping(address => uint256) private charityIndex;
    mapping(address => uint256) private charityPercentOnExpansion;
    mapping(address => uint256) private charityPercentOnContraction;
    uint256 private totalCharityPercentOnExpansion;
    uint256 private totalCharityPercentOnContraction;

    function setBASEToken(address _BASE)
        public
        onlyOwner
    {
        BASE = BaseToken(_BASE);
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (TokenPriceOracleRate - targetPrice) / targetPrice
     *      and targetPrice is McapOracleRate / baseMcap
     */
    function rebase() external {
        require(msg.sender == orchestrator, "you are not the orchestrator");
        require(inRebaseWindow(), "the rebase window is closed");

        // This comparison also ensures there is no reentrancy.
        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now, "cannot rebase yet");

        // Snap the rebase time to the start of this window.
        lastRebaseTimestampSec = now.sub(now.mod(minRebaseTimeIntervalSec)).add(rebaseWindowOffsetSec);

        epoch = epoch.add(1);

        int256 supplyDelta;
        uint256 mcap;
        uint256 tokenPrice;
        (supplyDelta, mcap, tokenPrice) = getNextSupplyDelta();
        if (supplyDelta == 0) {
            emit LogRebase(epoch, tokenPrice, mcap, supplyDelta, now);
            return;
        }

        if (supplyDelta > 0 && BASE.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(BASE.totalSupply())).toInt256Safe();
        }

        uint256 nextSupply = BASE.rebase(epoch, supplyDelta);
        assert(nextSupply <= MAX_SUPPLY);
        emit LogRebase(epoch, tokenPrice, mcap, supplyDelta, now);
    }

    function getNextSupplyDelta()
        public
        view
        returns (int256 supplyDelta, uint256 mcap, uint256 tokenPrice)
    {
        uint256 mcap;
        bool mcapValid;
        (mcap, mcapValid) = mcapOracle.getData();
        require(mcapValid, "invalid mcap");

        uint256 tokenPrice;
        bool tokenPriceValid;
        (tokenPrice, tokenPriceValid) = tokenPriceOracle.getData();
        require(tokenPriceValid, "invalid token price");

        if (tokenPrice > MAX_RATE) {
            tokenPrice = MAX_RATE;
        }

        supplyDelta = computeSupplyDelta(tokenPrice, mcap);

        // Apply the Dampening factor.
        supplyDelta = supplyDelta.div(rebaseLag.toInt256Safe());
        return (supplyDelta, mcap, tokenPrice);
    }

    /**
     * @notice Sets the reference to the market cap oracle.
     * @param mcapOracle_ The address of the mcap oracle contract.
     */
    function setMcapOracle(IOracle mcapOracle_)
        external
        onlyOwner
    {
        mcapOracle = mcapOracle_;
    }

    /**
     * @notice Sets the reference to the token price oracle.
     * @param tokenPriceOracle_ The address of the token price oracle contract.
     */
    function setTokenPriceOracle(IOracle tokenPriceOracle_)
        external
        onlyOwner
    {
        tokenPriceOracle = tokenPriceOracle_;
    }

    /**
     * @notice Sets the reference to the orchestrator.
     * @param orchestrator_ The address of the orchestrator contract.
     */
    function setOrchestrator(address orchestrator_)
        external
        onlyOwner
    {
        orchestrator = orchestrator_;
    }

    /**
     * @notice Sets the deviation threshold fraction. If the exchange rate given by the market
     *         oracle is within this fractional distance from the targetRate, then no supply
     *         modifications are made. DECIMALS fixed point number.
     * @param deviationThreshold_ The new exchange rate threshold fraction.
     */
    function setDeviationThreshold(uint256 deviationThreshold_)
        external
        onlyOwner
    {
        deviationThreshold = deviationThreshold_;
    }

    /**
     * @notice Sets the rebase lag parameter.
               It is used to dampen the applied supply adjustment by 1 / rebaseLag
               If the rebase lag R, equals 1, the smallest value for R, then the full supply
               correction is applied on each rebase cycle.
               If it is greater than 1, then a correction of 1/R of is applied on each rebase.
     * @param rebaseLag_ The new rebase lag parameter.
     */
    function setRebaseLag(uint256 rebaseLag_)
        external
        onlyOwner
    {
        require(rebaseLag_ > 0);
        rebaseLag = rebaseLag_;
    }

    /**
     * @notice Sets the parameters which control the timing and frequency of
     *         rebase operations.
     *         a) the minimum time period that must elapse between rebase cycles.
     *         b) the rebase window offset parameter.
     *         c) the rebase window length parameter.
     * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
     *        operations, in seconds.
     * @param rebaseWindowOffsetSec_ The number of seconds from the beginning of
              the rebase interval, where the rebase window begins.
     * @param rebaseWindowLengthSec_ The length of the rebase window in seconds.
     */
    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 rebaseWindowOffsetSec_,
        uint256 rebaseWindowLengthSec_)
        external
        onlyOwner
    {
        require(minRebaseTimeIntervalSec_ > 0, "minRebaseTimeIntervalSec cannot be 0");
        require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_, "rebaseWindowOffsetSec_ >= minRebaseTimeIntervalSec_");

        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
        rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
        rebaseWindowLengthSec = rebaseWindowLengthSec_;
    }

    /**
     * @dev ZOS upgradable contract initialization method.
     *      It is called at the time of contract creation to invoke parent class initializers and
     *      initialize the contract's state variables.
     */
    function initialize(BaseToken BASE_)
        public
        initializer
    {
        __Ownable_init();

        deviationThreshold = 0;
        rebaseLag = 1;
        minRebaseTimeIntervalSec = 1 days;
        rebaseWindowOffsetSec = 79200;  // 10PM UTC
        rebaseWindowLengthSec = 60 minutes;
        lastRebaseTimestampSec = 0;
        epoch = 0;

        BASE = BASE_;
    }

    /**
     * @return If the latest block timestamp is within the rebase time window it, returns true.
     *         Otherwise, returns false.
     */
    function inRebaseWindow() public view returns (bool) {
        return (
            now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec &&
            now.mod(minRebaseTimeIntervalSec) < (rebaseWindowOffsetSec.add(rebaseWindowLengthSec))
        );
    }

    /**
     * @return Computes the total supply adjustment in response to the exchange rate
     *         and the targetRate.
     */
    function computeSupplyDelta(uint256 price, uint256 mcap)
        public
        view
        returns (int256)
    {
        if (withinDeviationThreshold(price, mcap.div(1))) {
            return 0;
        }

        // supplyDelta = totalSupply * (price - targetPrice) / targetPrice
        int256 pricex1T       = price.mul(1).toInt256Safe();
        int256 targetPricex1T = mcap.toInt256Safe();
        return BASE.totalSupply().toInt256Safe()
            .mul(pricex1T.sub(targetPricex1T))
            .div(targetPricex1T);
    }

    /**
     * @param rate The current exchange rate, an 18 decimal fixed point number.
     * @param targetRate The target exchange rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate, uint256 targetRate)
        private
        view
        returns (bool)
    {
        if (deviationThreshold == 0) {
            return false;
        }

        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold).div(10 ** DECIMALS);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }
}

pragma solidity 0.6.12;


/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "./BaseTokenMonetaryPolicy.sol";


/**
 * @title BaseTokenOrchestrator
 * @notice The orchestrator is the main entry point for rebase operations. It coordinates the policy
 * actions with external consumers.
 */
contract BaseTokenOrchestrator is OwnableUpgradeSafe {

    event TransactionFailed(address indexed destination, uint index, bytes data);

    // Stable ordering is not guaranteed.
    bool[] transactionEnabled;
    address[] transactionDestination;
    bytes[] transactionData;

    BaseTokenMonetaryPolicy public policy;

    function setMonetaryPolicy(address _policy)
        public
        onlyOwner
    {
        policy = BaseTokenMonetaryPolicy(_policy);
    }

    /**
     * @param policy_ Address of the BaseToken policy.
     */
    function initialize(address policy_)
        public
        initializer
    {
        __Ownable_init();
        policy = BaseTokenMonetaryPolicy(policy_);
    }

    /**
     * @notice Main entry point to initiate a rebase operation.
     *         The BaseTokenOrchestrator calls rebase on the policy and notifies downstream applications.
     *         Contracts are guarded from calling, to avoid flash loan attacks on liquidity
     *         providers.
     *         If a transaction in the transaction list reverts, it is swallowed and the remaining
     *         transactions are executed.
     */
    function rebase()
        external
    {
        require(msg.sender == tx.origin);  // solhint-disable-line avoid-tx-origin

        policy.rebase();

        for (uint i = 0; i < transactionEnabled.length; i++) {
            // Transaction storage t = transactions[i];
            if (transactionEnabled[i]) {
                bool result = externalCall(transactionDestination[i], transactionData[i]);
                if (!result) {
                    emit TransactionFailed(transactionDestination[i], i, transactionData[i]);
                    revert("Transaction Failed");
                }
            }
        }
    }

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes memory data)
        external
        onlyOwner
    {
        transactionEnabled.push(true);
        transactionDestination.push(destination);
        transactionData.push(data);
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint index)
        external
        onlyOwner
    {
        require(index < transactionEnabled.length, "index out of bounds");

        if (index < transactionEnabled.length - 1) {
            transactionEnabled[index] = transactionEnabled[transactionEnabled.length - 1];
            transactionDestination[index] = transactionDestination[transactionEnabled.length - 1];
            transactionData[index] = transactionData[transactionEnabled.length - 1];
        }

        transactionEnabled.pop();
        transactionDestination.pop();
        transactionData.pop();
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint index, bool enabled)
        external
        onlyOwner
    {
        require(index < transactionEnabled.length, "index must be in range of stored tx list");
        transactionEnabled[index] = enabled;
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize()
        external
        view
        returns (uint256)
    {
        return transactionEnabled.length;
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes memory data)
        internal
        returns (bool)
    {
        bool result;
        assembly {  // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas(), 34710),


                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data),  // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "./lib/SafeMathInt.sol";
import "./BaseToken.sol";

interface ICascadeV2 {
    function migrate(address user) external;
}

contract Cascade is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    function migrate()
        public
    {
        require(deposits_multiplierLevel[msg.sender] > 0, "no deposit");

        updateDepositSeconds();

        uint256 numLPTokens = deposits_lpTokensDeposited[msg.sender];
        uint256 numRewardTokens = BASE.balanceOf(address(this)).mul(sumOfUserDepositSeconds(msg.sender)).div(totalDepositSeconds());

        cascadeV2.migrate(msg.sender);

        (uint256 level1, uint256 level2, uint256 level3) = userDepositSeconds(msg.sender);
        totalDepositSecondsLevel1 = totalDepositSecondsLevel1.sub(level1);
        totalDepositSecondsLevel2 = totalDepositSecondsLevel2.sub(level2);
        totalDepositSecondsLevel3 = totalDepositSecondsLevel3.sub(level3);

        if (deposits_multiplierLevel[msg.sender] == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.sub(deposits_lpTokensDeposited[msg.sender]);
        }

        bool ok = lpToken.transfer(address(cascadeV2), deposits_lpTokensDeposited[msg.sender]);
        require(ok, "transfer deposit");
        ok = BASE.transfer(address(cascadeV2), numRewardTokens);
        require(ok, "transfer rewards");

        delete deposits_lpTokensDeposited[msg.sender];
        delete deposits_depositTimestamp[msg.sender];
        delete deposits_multiplierLevel[msg.sender];
        delete deposits_mostRecentBASEWithdrawal[msg.sender];

        emit Migrate(msg.sender, numLPTokens, numRewardTokens);
    }

    mapping(address => uint256) public deposits_lpTokensDeposited;
    mapping(address => uint256) public deposits_depositTimestamp;
    mapping(address => uint8)   public deposits_multiplierLevel;
    mapping(address => uint256) public deposits_mostRecentBASEWithdrawal;

    uint256 public totalDepositedLevel1;
    uint256 public totalDepositedLevel2;
    uint256 public totalDepositedLevel3;
    uint256 public totalDepositSecondsLevel1;
    uint256 public totalDepositSecondsLevel2;
    uint256 public totalDepositSecondsLevel3;
    uint256 public lastAccountingUpdateTimestamp;

    IERC20 public lpToken;
    BaseToken public BASE;
    uint256 public minTimeBetweenWithdrawals;

    uint256 public rewardsStartTimestamp;
    uint256 public rewardsDuration;

    mapping(address => uint256) public deposits_lastMultiplierUpgradeTimestamp;
    uint256 multiplierUpgradeTimeout;

    ICascadeV2 public cascadeV2;

    event Deposit(address indexed user, uint256 previousLPTokens, uint256 additionalTokens, uint256 timestamp);
    event Withdraw(address indexed user, uint256 lpTokens, uint256 baseTokens, uint256 timestamp);
    event UpgradeMultiplierLevel(address indexed user, uint8 oldLevel, uint256 newLevel, uint256 timestamp);
    event Migrate(address indexed user, uint256 lpTokens, uint256 rewardTokens);

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    /**
     * Admin
     */

    function setLPToken(address _lpToken)
        public
        onlyOwner
    {
        lpToken = IERC20(_lpToken);
    }

    function setBASEToken(address _baseToken)
        public
        onlyOwner
    {
        BASE = BaseToken(_baseToken);
    }

    function setCascadeV2(address _cascadeV2)
        public
        onlyOwner
    {
        cascadeV2 = ICascadeV2(_cascadeV2);
    }

    function setMinTimeBetweenWithdrawals(uint256 _minTimeBetweenWithdrawals)
        public
        onlyOwner
    {
        minTimeBetweenWithdrawals = _minTimeBetweenWithdrawals;
    }

    function setRewardsParams(uint256 _rewardsStartTimestamp, uint256 _rewardsDuration)
        public
        onlyOwner
    {
        rewardsStartTimestamp = _rewardsStartTimestamp;
        rewardsDuration = _rewardsDuration;
    }

    function setMultiplierUpgradeTimeout(uint256 _multiplierUpgradeTimeout)
        public
        onlyOwner
    {
        multiplierUpgradeTimeout = _multiplierUpgradeTimeout;
    }

    function adminWithdrawBASE(address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "bad amount");

        bool ok = BASE.transfer(recipient, amount);
        require(ok, "transfer");
    }

    function rescueMistakenlySentTokens(address token, address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "bad amount");

        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");
    }

    /**
     * Public methods
     */

    function deposit(uint256 amount)
        public
    {
        require(deposits_lastMultiplierUpgradeTimestamp[msg.sender] == 0, "multiplied too recently");

        updateDepositSeconds();

        uint256 allowance = lpToken.allowance(msg.sender, address(this));
        require(amount <= allowance, "allowance");

        totalDepositedLevel1 = totalDepositedLevel1.add(amount);

        deposits_lpTokensDeposited[msg.sender] = deposits_lpTokensDeposited[msg.sender].add(amount);
        deposits_multiplierLevel[msg.sender] = 1;
        if (deposits_depositTimestamp[msg.sender] == 0) {
            deposits_depositTimestamp[msg.sender] = now;
        }

        bool ok = lpToken.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom");

        emit Deposit(msg.sender, deposits_lpTokensDeposited[msg.sender].sub(amount), amount, now);
    }

    function upgradeMultiplierLevel()
        public
    {
        require(deposits_multiplierLevel[msg.sender] > 0, "no deposit");
        require(deposits_multiplierLevel[msg.sender] < 3, "fully upgraded");

        deposits_lastMultiplierUpgradeTimestamp[msg.sender] = block.timestamp;

        updateDepositSeconds();

        uint8 oldLevel = deposits_multiplierLevel[msg.sender];
        uint256 age = now.sub(deposits_depositTimestamp[msg.sender]);
        uint256 lpTokensDeposited = deposits_lpTokensDeposited[msg.sender];

        if (deposits_multiplierLevel[msg.sender] == 1 && age >= 60 days) {
            uint256 secondsSinceLevel2 = age.sub(30 days);
            uint256 secondsSinceLevel3 = age.sub(60 days);
            totalDepositedLevel1 = totalDepositedLevel1.sub(lpTokensDeposited);
            totalDepositedLevel3 = totalDepositedLevel3.add(lpTokensDeposited);
            totalDepositSecondsLevel2 = totalDepositSecondsLevel2.add( lpTokensDeposited.mul(secondsSinceLevel2) );
            totalDepositSecondsLevel3 = totalDepositSecondsLevel3.add( lpTokensDeposited.mul(secondsSinceLevel2.add(secondsSinceLevel3)) );
            deposits_multiplierLevel[msg.sender] = 3;

        } else if (deposits_multiplierLevel[msg.sender] == 1 && age >= 30 days) {
            uint256 secondsSinceLevel2 = age.sub(30 days);
            totalDepositedLevel1 = totalDepositedLevel1.sub(lpTokensDeposited);
            totalDepositedLevel2 = totalDepositedLevel2.add(lpTokensDeposited);
            totalDepositSecondsLevel1 = totalDepositSecondsLevel1.sub( lpTokensDeposited.mul(secondsSinceLevel2) );
            totalDepositSecondsLevel2 = totalDepositSecondsLevel2.add( lpTokensDeposited.mul(secondsSinceLevel2) );
            deposits_multiplierLevel[msg.sender] = 2;

        } else if (deposits_multiplierLevel[msg.sender] == 2 && age >= 60 days) {
            uint256 secondsSinceLevel3 = age.sub(60 days);
            totalDepositedLevel2 = totalDepositedLevel2.sub(lpTokensDeposited);
            totalDepositedLevel3 = totalDepositedLevel3.add(lpTokensDeposited);
            totalDepositSecondsLevel3 = totalDepositSecondsLevel3.add( lpTokensDeposited.mul(secondsSinceLevel3) );
            deposits_multiplierLevel[msg.sender] = 3;

        } else {
            revert("ineligible");
        }

        emit UpgradeMultiplierLevel(msg.sender, oldLevel, deposits_multiplierLevel[msg.sender], now);
    }

    function withdrawLPTokens()
        public
    {
        require(deposits_lastMultiplierUpgradeTimestamp[msg.sender] == 0, "multiplied too recently");

        updateDepositSeconds();

        uint256 owed = owedTo(msg.sender);
        require(BASE.balanceOf(address(this)) >= owed, "available tokens");
        require(deposits_multiplierLevel[msg.sender] > 0, "doesn't exist");
        require(deposits_lpTokensDeposited[msg.sender] > 0, "no stake");
        require(allowedToWithdraw(msg.sender), "too soon");

        deposits_mostRecentBASEWithdrawal[msg.sender] = now;

        (uint256 level1, uint256 level2, uint256 level3) = userDepositSeconds(msg.sender);
        totalDepositSecondsLevel1 = totalDepositSecondsLevel1.sub(level1);
        totalDepositSecondsLevel2 = totalDepositSecondsLevel2.sub(level2);
        totalDepositSecondsLevel3 = totalDepositSecondsLevel3.sub(level3);

        if (deposits_multiplierLevel[msg.sender] == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.sub(deposits_lpTokensDeposited[msg.sender]);
        }

        uint256 deposited = deposits_lpTokensDeposited[msg.sender];

        delete deposits_lpTokensDeposited[msg.sender];
        delete deposits_depositTimestamp[msg.sender];
        delete deposits_multiplierLevel[msg.sender];
        delete deposits_mostRecentBASEWithdrawal[msg.sender];

        bool ok = lpToken.transfer(msg.sender, deposited);
        require(ok, "transfer");
        ok = BASE.transfer(msg.sender, owed);
        require(ok, "transfer");

        emit Withdraw(msg.sender, deposited, owed, now);
    }

    /**
     * Accounting utilities
     */

    function updateDepositSeconds()
        public
    {
        (totalDepositSecondsLevel1, totalDepositSecondsLevel2, totalDepositSecondsLevel3) = getUpdatedDepositSeconds();
        lastAccountingUpdateTimestamp = now;
    }

    function getUpdatedDepositSeconds()
        public
        view
        returns (uint256 level1, uint256 level2, uint256 level3)
    {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        return (
            totalDepositSecondsLevel1.add(totalDepositedLevel1.mul(delta)),
            totalDepositSecondsLevel2.add(totalDepositedLevel2.mul(delta)),
            totalDepositSecondsLevel3.add(totalDepositedLevel3.mul(delta))
        );
    }

    /**
     * Getters
     */

    function depositInfo(address user)
        public
        view
        returns (
            uint256 _lpTokensDeposited,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _mostRecentBASEWithdrawal,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds
        )
    {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        _totalDepositSeconds = totalDepositSecondsLevel1.add(totalDepositedLevel1.mul(delta))
                                  .add(totalDepositSecondsLevel2.add(totalDepositedLevel2.mul(delta)).mul(2))
                                  .add(totalDepositSecondsLevel3.add(totalDepositedLevel3.mul(delta)).mul(3));

        return (
            deposits_lpTokensDeposited[user],
            deposits_depositTimestamp[user],
            deposits_multiplierLevel[user],
            deposits_mostRecentBASEWithdrawal[user],
            sumOfUserDepositSeconds(user),
            _totalDepositSeconds
        );
    }

    function allowedToWithdraw(address user)
        public
        view
        returns (bool)
    {
        return deposits_mostRecentBASEWithdrawal[user] == 0
                ? now > deposits_depositTimestamp[user].add(minTimeBetweenWithdrawals)
                : now > deposits_mostRecentBASEWithdrawal[user].add(minTimeBetweenWithdrawals);
    }

    function userDepositSeconds(address user)
        public
        view
        returns (uint256 level1, uint256 level2, uint256 level3)
    {
        uint256 timeSinceDeposit = now.sub(deposits_depositTimestamp[user]);
        uint256 multiplier = deposits_multiplierLevel[user];
        uint256 lpTokens = deposits_lpTokensDeposited[user];
        uint256 secondsLevel1;
        uint256 secondsLevel2;
        uint256 secondsLevel3;
        if (multiplier == 1) {
            secondsLevel1 = timeSinceDeposit;
        } else if (multiplier == 2) {
            secondsLevel1 = 30 days;
            secondsLevel2 = timeSinceDeposit.sub(30 days);
        } else if (multiplier == 3) {
            secondsLevel1 = 30 days;
            secondsLevel2 = 30 days;
            secondsLevel3 = timeSinceDeposit.sub(60 days);
        }

        return (
            lpTokens.mul(secondsLevel1),
            lpTokens.mul(secondsLevel2),
            lpTokens.mul(secondsLevel3)
        );
    }

    function sumOfUserDepositSeconds(address user)
        public
        view
        returns (uint256)
    {
        (uint256 level1, uint256 level2, uint256 level3) = userDepositSeconds(user);
        return level1.add(level2.mul(2)).add(level3.mul(3));
    }

    function totalDepositSeconds()
        public
        view
        returns (uint256)
    {
        (uint256 level1, uint256 level2, uint256 level3) = getUpdatedDepositSeconds();
        return level1.add(level2.mul(2)).add(level3.mul(3));
    }

    function rewardsPool()
        public
        view
        returns (uint256)
    {
        uint256 baseBalance = BASE.balanceOf(address(this));
        uint256 unlocked;
        if (rewardsStartTimestamp > 0) {
            uint256 secondsIntoVesting = now.sub(rewardsStartTimestamp);
            if (secondsIntoVesting > rewardsDuration) {
                unlocked = baseBalance;
            } else {
                unlocked = baseBalance.mul( now.sub(rewardsStartTimestamp) ).div(rewardsDuration);
            }
        } else {
            unlocked = baseBalance;
        }
        return unlocked;
    }

    function owedTo(address user)
        public
        view
        returns (uint256 amount)
    {
        if (totalDepositSeconds() == 0) {
            return 0;
        }
        return rewardsPool().mul(sumOfUserDepositSeconds(user)).div(totalDepositSeconds());
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "./BaseToken.sol";

interface ICascadeV1 {
    function depositInfo(address user) external view
        returns (
            uint256 _lpTokensDeposited,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _mostRecentBASEWithdrawal,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds
        );
}

/**
 * @title CascadeV2 is a liquidity mining contract.
 */
contract CascadeV2 is OwnableUpgradeSafe {
    using SafeMath for uint256;

    mapping(address => uint256)   public userDepositsNumDeposits;
    mapping(address => uint256[]) public userDepositsNumLPTokens;
    mapping(address => uint256[]) public userDepositsDepositTimestamp;
    mapping(address => uint8[])   public userDepositsMultiplierLevel;
    mapping(address => uint256)   public userTotalLPTokensLevel1;
    mapping(address => uint256)   public userTotalLPTokensLevel2;
    mapping(address => uint256)   public userTotalLPTokensLevel3;
    mapping(address => uint256)   public userDepositSeconds;
    mapping(address => uint256)   public userLastAccountingUpdateTimestamp;

    uint256 public totalDepositedLevel1;
    uint256 public totalDepositedLevel2;
    uint256 public totalDepositedLevel3;
    uint256 public totalDepositSeconds;
    uint256 public lastAccountingUpdateTimestamp;

    uint256[] public rewardsNumShares;
    uint256[] public rewardsVestingStart;
    uint256[] public rewardsVestingDuration;
    uint256[] public rewardsSharesWithdrawn;

    IERC20 public lpToken;
    BaseToken public BASE;
    ICascadeV1 public cascadeV1;

    event Deposit(address indexed user, uint256 tokens, uint256 timestamp);
    event Withdraw(address indexed user, uint256 withdrawnLPTokens, uint256 withdrawnBASETokens, uint256 timestamp);
    event UpgradeMultiplierLevel(address indexed user, uint256 depositIndex, uint256 oldLevel, uint256 newLevel, uint256 timestamp);
    event Migrate(address indexed user, uint256 lpTokens, uint256 rewardTokens);
    event AddRewards(uint256 tokens, uint256 shares, uint256 vestingStart, uint256 vestingDuration, uint256 totalTranches);
    event SetBASEToken(address token);
    event SetLPToken(address token);
    event SetCascadeV1(address cascadeV1);
    event UpdateDepositSeconds(address user, uint256 totalDepositSeconds, uint256 userDepositSeconds);
    event AdminRescueTokens(address token, address recipient, uint256 amount);

    /**
     * @dev Called by the OpenZeppelin "upgrades" library to initialize the contract in lieu of a constructor.
     */
    function initialize() external initializer {
        __Ownable_init();

        // Copy over the rewards tranche from Cascade v1
        rewardsNumShares.push(0);
        rewardsVestingStart.push(1606763901);
        rewardsVestingDuration.push(7776000);
        rewardsSharesWithdrawn.push(0);
    }

    /**
     * Admin
     */

    /**
     * @notice Changes the address of the LP token for which staking is allowed.
     * @param _lpToken The address of the LP token.
     */
    function setLPToken(address _lpToken) external onlyOwner {
        require(_lpToken != address(0x0), "zero address");
        lpToken = IERC20(_lpToken);
        emit SetLPToken(_lpToken);
    }

    /**
     * @notice Changes the address of the BASE token.
     * @param _baseToken The address of the BASE token.
     */
    function setBASEToken(address _baseToken) external onlyOwner {
        require(_baseToken != address(0x0), "zero address");
        BASE = BaseToken(_baseToken);
        emit SetBASEToken(_baseToken);
    }

    /**
     * @notice Changes the address of Cascade v1 (for purposes of migration).
     * @param _cascadeV1 The address of Cascade v1.
     */
    function setCascadeV1(address _cascadeV1) external onlyOwner {
        require(address(_cascadeV1) != address(0x0), "zero address");
        cascadeV1 = ICascadeV1(_cascadeV1);
        emit SetCascadeV1(_cascadeV1);
    }

    /**
     * @notice Allows the admin to withdraw tokens mistakenly sent into the contract.
     * @param token The address of the token to rescue.
     * @param recipient The recipient that the tokens will be sent to.
     * @param amount How many tokens to rescue.
     */
    function adminRescueTokens(address token, address recipient, uint256 amount) external onlyOwner {
        require(token != address(0x0), "zero address");
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "zero amount");

        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");

        emit AdminRescueTokens(token, recipient, amount);
    }

    /**
     * @notice Allows the owner to add another tranche of rewards.
     * @param numTokens How many tokens to add to the tranche.
     * @param vestingStart The timestamp upon which vesting of this tranche begins.
     * @param vestingDuration The duration over which the tokens fully unlock.
     */
    function addRewards(uint256 numTokens, uint256 vestingStart, uint256 vestingDuration) external onlyOwner {
        require(numTokens > 0, "zero amount");
        require(vestingStart > 0, "zero vesting start");

        uint256 numShares = tokensToShares(numTokens);
        rewardsNumShares.push(numShares);
        rewardsVestingStart.push(vestingStart);
        rewardsVestingDuration.push(vestingDuration);
        rewardsSharesWithdrawn.push(0);

        bool ok = BASE.transferFrom(msg.sender, address(this), numTokens);
        require(ok, "transfer");

        emit AddRewards(numTokens, numShares, vestingStart, vestingDuration, rewardsNumShares.length);
    }

    /**
     * Public methods
     */

    /**
     * @notice Allows a user to deposit LP tokens into the Cascade.
     * @param amount How many tokens to stake.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "zero amount");

        uint256 allowance = lpToken.allowance(msg.sender, address(this));
        require(amount <= allowance, "allowance");

        updateDepositSeconds(msg.sender);

        totalDepositedLevel1 = totalDepositedLevel1.add(amount);
        userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].add(1);
        userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].add(amount);
        userDepositsNumLPTokens[msg.sender].push(amount);
        userDepositsDepositTimestamp[msg.sender].push(now);
        userDepositsMultiplierLevel[msg.sender].push(1);

        bool ok = lpToken.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom");

        emit Deposit(msg.sender, amount, now);
    }

    /**
     * @notice Allows a user to withdraw LP tokens from the Cascade.
     * @param numLPTokens How many tokens to unstake.
     */
    function withdrawLPTokens(uint256 numLPTokens) external {
        require(numLPTokens > 0, "zero tokens");

        updateDepositSeconds(msg.sender);

        (
            uint256 totalAmountToWithdraw,
            uint256 totalDepositSecondsToBurn,
            uint256 amountToWithdrawLevel1,
            uint256 amountToWithdrawLevel2,
            uint256 amountToWithdrawLevel3
        ) = removeDepositSeconds(numLPTokens);

        uint256 totalRewardShares = unlockedRewardsPoolShares().mul(totalDepositSecondsToBurn).div(totalDepositSeconds);
        removeRewardShares(totalRewardShares);

        totalDepositedLevel1 = totalDepositedLevel1.sub(amountToWithdrawLevel1);
        totalDepositedLevel2 = totalDepositedLevel2.sub(amountToWithdrawLevel2);
        totalDepositedLevel3 = totalDepositedLevel3.sub(amountToWithdrawLevel3);

        userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].sub(totalDepositSecondsToBurn);
        totalDepositSeconds = totalDepositSeconds.sub(totalDepositSecondsToBurn);

        uint256 rewardTokens = sharesToTokens(totalRewardShares);

        bool ok = lpToken.transfer(msg.sender, totalAmountToWithdraw);
        require(ok, "transfer deposit");
        ok = BASE.transfer(msg.sender, rewardTokens);
        require(ok, "transfer rewards");

        emit Withdraw(msg.sender, totalAmountToWithdraw, rewardTokens, block.timestamp);
    }

    function removeDepositSeconds(uint256 numLPTokens) private
        returns (
            uint256 totalAmountToWithdraw,
            uint256 totalDepositSecondsToBurn,
            uint256 amountToWithdrawLevel1,
            uint256 amountToWithdrawLevel2,
            uint256 amountToWithdrawLevel3
        )
    {
        for (uint256 i = userDepositsNumLPTokens[msg.sender].length; i > 0; i--) {
            uint256 lpTokensToRemove;
            uint256 age = now.sub(userDepositsDepositTimestamp[msg.sender][i-1]);
            uint8   multiplier = userDepositsMultiplierLevel[msg.sender][i-1];

            if (totalAmountToWithdraw.add(userDepositsNumLPTokens[msg.sender][i-1]) <= numLPTokens) {
                lpTokensToRemove = userDepositsNumLPTokens[msg.sender][i-1];
                userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].sub(1);
                userDepositsNumLPTokens[msg.sender].pop();
                userDepositsDepositTimestamp[msg.sender].pop();
                userDepositsMultiplierLevel[msg.sender].pop();
            } else {
                lpTokensToRemove = numLPTokens.sub(totalAmountToWithdraw);
                userDepositsNumLPTokens[msg.sender][i-1] = userDepositsNumLPTokens[msg.sender][i-1].sub(lpTokensToRemove);
            }

            if (multiplier == 1) {
                userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel1 = amountToWithdrawLevel1.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(age.mul(lpTokensToRemove));
            } else if (multiplier == 2) {
                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel2 = amountToWithdrawLevel2.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(lpTokensToRemove.mul(30 days + (age - 30 days).mul(2)));
            } else if (multiplier == 3) {
                userTotalLPTokensLevel3[msg.sender] = userTotalLPTokensLevel3[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel3 = amountToWithdrawLevel3.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(lpTokensToRemove.mul(30 days + uint256(30 days).mul(2) + (age - 60 days).mul(3)));
            }
            totalAmountToWithdraw = totalAmountToWithdraw.add(lpTokensToRemove);

            if (totalAmountToWithdraw >= numLPTokens) {
                break;
            }
        }
        return (
            totalAmountToWithdraw,
            totalDepositSecondsToBurn,
            amountToWithdrawLevel1,
            amountToWithdrawLevel2,
            amountToWithdrawLevel3
        );
    }

    function removeRewardShares(uint256 totalSharesToRemove) private {
        uint256 totalSharesRemovedSoFar;

        for (uint256 i = rewardsNumShares.length; i > 0; i--) {
            uint256 sharesAvailable = unlockedRewardSharesInTranche(i-1);
            if (sharesAvailable == 0) {
                continue;
            }

            uint256 sharesStillNeeded = totalSharesToRemove.sub(totalSharesRemovedSoFar);
            if (sharesAvailable > sharesStillNeeded) {
                rewardsSharesWithdrawn[i-1] = rewardsSharesWithdrawn[i-1].add(sharesStillNeeded);
                return;
            }

            rewardsSharesWithdrawn[i-1] = rewardsSharesWithdrawn[i-1].add(sharesAvailable);
            totalSharesRemovedSoFar = totalSharesRemovedSoFar.add(sharesAvailable);
            if (rewardsNumShares[i-1].sub(rewardsSharesWithdrawn[i-1]) == 0) {
                rewardsNumShares.pop();
                rewardsVestingStart.pop();
                rewardsVestingDuration.pop();
                rewardsSharesWithdrawn.pop();
            }
        }
    }

    /**
     * @notice Allows a user to upgrade their deposit-seconds multipler for the given deposits.
     * @param deposits A list of the indices of deposits to be upgraded.
     */
    function upgradeMultiplierLevel(uint256[] memory deposits) external {
        require(deposits.length > 0, "no deposits");

        updateDepositSeconds(msg.sender);

        for (uint256 i = 0; i < deposits.length; i++) {
            uint256 idx = deposits[i];
            uint256 age = now.sub(userDepositsDepositTimestamp[msg.sender][idx]);

            if (age <= 30 days || userDepositsMultiplierLevel[msg.sender][idx] == 3) {
                continue;
            }

            uint8 oldLevel = userDepositsMultiplierLevel[msg.sender][idx];
            uint256 tokensDeposited = userDepositsNumLPTokens[msg.sender][idx];

            if (age > 30 days && userDepositsMultiplierLevel[msg.sender][idx] == 1) {
                uint256 secondsSinceLevel2 = age - 30 days;
                uint256 extraDepositSeconds = tokensDeposited.mul(secondsSinceLevel2);
                totalDepositedLevel1 = totalDepositedLevel1.sub(tokensDeposited);
                totalDepositedLevel2 = totalDepositedLevel2.add(tokensDeposited);
                totalDepositSeconds  = totalDepositSeconds.add(extraDepositSeconds);

                userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].sub(tokensDeposited);
                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].add(tokensDeposited);
                userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].add(extraDepositSeconds);
                userDepositsMultiplierLevel[msg.sender][idx] = 2;
            }

            if (age > 60 days && userDepositsMultiplierLevel[msg.sender][idx] == 2) {
                uint256 secondsSinceLevel3 = age - 60 days;
                uint256 extraDepositSeconds = tokensDeposited.mul(secondsSinceLevel3);
                totalDepositedLevel2 = totalDepositedLevel2.sub(tokensDeposited);
                totalDepositedLevel3 = totalDepositedLevel3.add(tokensDeposited);
                totalDepositSeconds  = totalDepositSeconds.add(extraDepositSeconds);

                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].sub(tokensDeposited);
                userTotalLPTokensLevel3[msg.sender] = userTotalLPTokensLevel3[msg.sender].add(tokensDeposited);
                userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].add(extraDepositSeconds);
                userDepositsMultiplierLevel[msg.sender][idx] = 3;
            }
            emit UpgradeMultiplierLevel(msg.sender, idx, oldLevel, userDepositsMultiplierLevel[msg.sender][idx], block.timestamp);
        }
    }

    /**
     * @notice Called by Cascade v1 to migrate funds into Cascade v2.
     * @param user The user for whom to migrate funds.
     */
    function migrate(address user) external {
        require(msg.sender == address(cascadeV1), "only cascade v1");
        require(user != address(0x0), "zero address");

        (
            uint256 numLPTokens,
            uint256 depositTimestamp,
            uint8   multiplier,
            ,
            uint256 userDS,
            uint256 totalDS
        ) = cascadeV1.depositInfo(user);
        uint256 numRewardShares = BASE.sharesOf(address(cascadeV1)).mul(userDS).div(totalDS);

        require(numLPTokens > 0, "no stake");
        require(multiplier > 0, "zero multiplier");
        require(depositTimestamp > 0, "zero timestamp");
        require(userDS > 0, "zero seconds");

        updateDepositSeconds(user);

        userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].add(1);
        userDepositsNumLPTokens[user].push(numLPTokens);
        userDepositsMultiplierLevel[user].push(multiplier);
        userDepositsDepositTimestamp[user].push(depositTimestamp);
        userDepositSeconds[user] = userDS;
        userLastAccountingUpdateTimestamp[user] = now;
        totalDepositSeconds = totalDepositSeconds.add(userDS);

        rewardsNumShares[0] = rewardsNumShares[0].add(numRewardShares);

        if (multiplier == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.add(numLPTokens);
            userTotalLPTokensLevel1[user] = userTotalLPTokensLevel1[user].add(numLPTokens);
        } else if (multiplier == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.add(numLPTokens);
            userTotalLPTokensLevel2[user] = userTotalLPTokensLevel2[user].add(numLPTokens);
        } else if (multiplier == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.add(numLPTokens);
            userTotalLPTokensLevel3[user] = userTotalLPTokensLevel3[user].add(numLPTokens);
        }

        emit Migrate(user, numLPTokens, sharesToTokens(numRewardShares));
    }

    /**
     * @notice Updates the global deposit-seconds accounting as well as that of the given user.
     * @param user The user for whom to update the accounting.
     */
    function updateDepositSeconds(address user) public {
        (totalDepositSeconds, userDepositSeconds[user]) = getUpdatedDepositSeconds(user);
        lastAccountingUpdateTimestamp = now;
        userLastAccountingUpdateTimestamp[user] = now;
        emit UpdateDepositSeconds(user, totalDepositSeconds, userDepositSeconds[user]);
    }

    /**
     * Getters
     */

    /**
     * @notice Returns the global deposit-seconds as well as that of the given user.
     * @param user The user for whom to fetch the current deposit-seconds.
     */
    function getUpdatedDepositSeconds(address user) public view returns (uint256 _totalDepositSeconds, uint256 _userDepositSeconds) {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        _totalDepositSeconds = totalDepositSeconds.add(delta.mul(totalDepositedLevel1
                                                                       .add( totalDepositedLevel2.mul(2) )
                                                                       .add( totalDepositedLevel3.mul(3) ) ));

        delta = now.sub(userLastAccountingUpdateTimestamp[user]);
        _userDepositSeconds  = userDepositSeconds[user].add(delta.mul(userTotalLPTokensLevel1[user]
                                                                       .add( userTotalLPTokensLevel2[user].mul(2) )
                                                                       .add( userTotalLPTokensLevel3[user].mul(3) ) ));
        return (_totalDepositSeconds, _userDepositSeconds);
    }

    /**
     * @notice Returns the BASE rewards owed to the given user.
     * @param user The user for whom to fetch the current rewards.
     */
    function owedTo(address user) public view returns (uint256) {
        require(user != address(0x0), "zero address");

        (uint256 totalDS, uint256 userDS) = getUpdatedDepositSeconds(user);
        if (totalDS == 0) {
            return 0;
        }
        return sharesToTokens(unlockedRewardsPoolShares().mul(userDS).div(totalDS));
    }

    /**
     * @notice Returns the total number of unlocked BASE in the rewards pool.
     */
    function unlockedRewardsPoolTokens() public view returns (uint256) {
        return sharesToTokens(unlockedRewardsPoolShares());
    }

    function unlockedRewardsPoolShares() private view returns (uint256) {
        uint256 totalShares;
        for (uint256 i = 0; i < rewardsNumShares.length; i++) {
            totalShares = totalShares.add(unlockedRewardSharesInTranche(i));
        }
        return totalShares;
    }

    function unlockedRewardSharesInTranche(uint256 rewardsIdx) private view returns (uint256) {
        if (rewardsVestingStart[rewardsIdx] >= now || rewardsNumShares[rewardsIdx].sub(rewardsSharesWithdrawn[rewardsIdx]) == 0) {
            return 0;
        }
        uint256 secondsIntoVesting = now.sub(rewardsVestingStart[rewardsIdx]);
        if (secondsIntoVesting > rewardsVestingDuration[rewardsIdx]) {
            return rewardsNumShares[rewardsIdx].sub(rewardsSharesWithdrawn[rewardsIdx]);
        } else {
            return rewardsNumShares[rewardsIdx].mul( secondsIntoVesting )
                                               .div( rewardsVestingDuration[rewardsIdx] == 0 ? 1 : rewardsVestingDuration[rewardsIdx] )
                                               .sub( rewardsSharesWithdrawn[rewardsIdx] );
        }
    }

    function sharesToTokens(uint256 shares) private view returns (uint256) {
        return shares.mul(BASE.totalSupply()).div(BASE.totalShares());
    }

     function tokensToShares(uint256 tokens) private view returns (uint256) {
        return tokens.mul(BASE.totalShares().div(BASE.totalSupply()));
    }

    /**
     * @notice Returns various statistics about the given user and deposit.
     * @param user The user to fetch.
     * @param depositIdx The index of the given user's deposit to fetch.
     */
    function depositInfo(address user, uint256 depositIdx) public view
        returns (
            uint256 _numLPTokens,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds,
            uint256 _owed
        )
    {
        require(user != address(0x0), "zero address");

        (_totalDepositSeconds, _userDepositSeconds) = getUpdatedDepositSeconds(user);
        return (
            userDepositsNumLPTokens[user][depositIdx],
            userDepositsDepositTimestamp[user][depositIdx],
            userDepositsMultiplierLevel[user][depositIdx],
            _userDepositSeconds,
            _totalDepositSeconds,
            owedTo(user)
        );
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "ERC20";
        name = "Example ERC20";
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}

pragma solidity 0.6.12;

import "../BaseTokenOrchestrator.sol";


contract ConstructorRebaseCallerContract {
    constructor(address orchestrator) public {
        // Take out a flash loan.
        // Do something funky...
        BaseTokenOrchestrator(orchestrator).rebase();  // should fail
        // pay back flash loan.
    }
}

pragma solidity 0.6.12;


contract Mock {
    event FunctionCalled(string instanceName, string functionName, address caller);
    event FunctionArguments(uint256[] uintVals, int256[] intVals);
    event ReturnValueInt256(int256 val);
    event ReturnValueUInt256(uint256 val);
}

pragma solidity 0.6.12;

import "./Mock.sol";


contract MockBaseToken is Mock {
    uint256 private _supply;

    // Methods to mock data on the chain
    function storeSupply(uint256 supply)
        public
    {
        _supply = supply;
    }

    // Mock methods
    function rebase(uint256 epoch, int256 supplyDelta)
        public
        returns (uint256)
    {
        emit FunctionCalled("BaseToken", "rebase", msg.sender);
        uint256[] memory uintVals = new uint256[](1);
        uintVals[0] = epoch;
        int256[] memory intVals = new int256[](1);
        intVals[0] = supplyDelta;
        emit FunctionArguments(uintVals, intVals);
        return uint256(int256(_supply) + int256(supplyDelta));
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _supply;
    }
}

pragma solidity 0.6.12;

import "./Mock.sol";


contract MockBaseTokenMonetaryPolicy is Mock {

    function rebase() external {
        emit FunctionCalled("BaseTokenMonetaryPolicy", "rebase", msg.sender);
    }
}

pragma solidity 0.6.12;

import "./Mock.sol";


contract MockDownstream is Mock {

    function updateNoArg() external returns (bool) {
        emit FunctionCalled("MockDownstream", "updateNoArg", msg.sender);
        uint256[] memory uintVals = new uint256[](0);
        int256[] memory intVals = new int256[](0);
        emit FunctionArguments(uintVals, intVals);
        return true;
    }

    function updateOneArg(uint256 u) external {
        emit FunctionCalled("MockDownstream", "updateOneArg", msg.sender);

        uint256[] memory uintVals = new uint256[](1);
        uintVals[0] = u;
        int256[] memory intVals = new int256[](0);
        emit FunctionArguments(uintVals, intVals);
    }

    function updateTwoArgs(uint256 u, int256 i) external {
        emit FunctionCalled("MockDownstream", "updateTwoArgs", msg.sender);

        uint256[] memory uintVals = new uint256[](1);
        uintVals[0] = u;
        int256[] memory intVals = new int256[](1);
        intVals[0] = i;
        emit FunctionArguments(uintVals, intVals);
    }

    function reverts() external {
        emit FunctionCalled("MockDownstream", "reverts", msg.sender);

        uint256[] memory uintVals = new uint256[](0);
        int256[] memory intVals = new int256[](0);
        emit FunctionArguments(uintVals, intVals);

        require(false, "reverted");
    }
}

pragma solidity 0.6.12;

import "./Mock.sol";


contract MockOracle is Mock {
    bool private _validity = true;
    uint256 private _data;
    string public name;

    constructor(string memory name_) public {
        name = name_;
    }

    // Mock methods
    function getData()
        external view
        returns (uint256, bool)
    {
        return (_data, _validity);
    }

    // Methods to mock data on the chain
    function storeData(uint256 data)
        public
    {
        _data = data;
    }

    function storeValidity(bool validity)
        public
    {
        _validity = validity;
    }
}

pragma solidity 0.6.12;

import "../BaseTokenOrchestrator.sol";


contract RebaseCallerContract {

    function callRebase(address orchestrator) public returns (bool) {
        // Take out a flash loan.
        // Do something funky...
        BaseTokenOrchestrator(orchestrator).rebase();  // should fail
        // pay back flash loan.
        return true;
    }
}

pragma solidity 0.6.12;

import "./Mock.sol";
import "../lib/SafeMathInt.sol";


contract SafeMathIntMock is Mock {
    function mul(int256 a, int256 b)
        external
        returns (int256)
    {
        int256 result = SafeMathInt.mul(a, b);
        emit ReturnValueInt256(result);
        return result;
    }

    function div(int256 a, int256 b)
        external
        returns (int256)
    {
        int256 result = SafeMathInt.div(a, b);
        emit ReturnValueInt256(result);
        return result;
    }

    function sub(int256 a, int256 b)
        external
        returns (int256)
    {
        int256 result = SafeMathInt.sub(a, b);
        emit ReturnValueInt256(result);
        return result;
    }

    function add(int256 a, int256 b)
        external
        returns (int256)
    {
        int256 result = SafeMathInt.add(a, b);
        emit ReturnValueInt256(result);
        return result;
    }

    function abs(int256 a)
        external
        returns (int256)
    {
        int256 result = SafeMathInt.abs(a);
        emit ReturnValueInt256(result);
        return result;
    }
}

pragma solidity 0.6.12;

import "./Mock.sol";
import "../lib/UInt256Lib.sol";


contract UInt256LibMock is Mock {
    function toInt256Safe(uint256 a)
        external
        returns (int256)
    {
        int256 result = UInt256Lib.toInt256Safe(a);
        emit ReturnValueInt256(result);
        return result;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

interface IOracle {
    function latestAnswer() external returns (uint256);
}

contract Oracle is OwnableUpgradeSafe {
    IOracle public externalOracle;
    uint8   public externalOracleDecimals;
    uint8   public desiredDecimals;

    function initialize()
        public
        initializer
    {
        __Ownable_init();
        externalOracleDecimals = 8;
        desiredDecimals = 18;
    }

    function setExternalOracle(address _externalOracle)
        public
        onlyOwner
    {
        externalOracle = IOracle(_externalOracle);
    }

    function getData()
        public
        returns (uint256, bool)
    {
        uint256 answer = externalOracle.latestAnswer();
        answer = answer * (10 ** (uint256(desiredDecimals - externalOracleDecimals)));
        return (answer, true);
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

// SPDX-License-Identifier: MIT
interface IERC20 {
    function decimals() external view returns (uint8);
}

contract Ownable {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() internal {
		_owner = msg.sender;
		emit OwnershipTransferred(address(0), _owner);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view returns (address) {
		return _owner;
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
	 * @dev Leaves the contract without owner. It will not be possible to call
	 * `onlyOwner` functions anymore. Can only be called by the current owner.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 */
	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 */
	function _transferOwnership(address newOwner) internal {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract TokenPriceOracle is Ownable {
    using SafeMath for uint;

    IPancakePair pair;
    address public token0;
    address public token1;

    function getPair() external view returns (address) {
        return address(pair);
    }

    function setPair(address factory, address baseToken, address targetToken) external onlyOwner {
        require(factory != address(0), "ERR: zero address");
        require(baseToken != address(0), "ERR: zero address");
        require(targetToken != address(0), "ERR: zero address");

        IPancakePair _pair = IPancakePair(PancakeLibrary.pairFor(factory, baseToken, targetToken));
        pair = _pair;
        token0 = baseToken;
        token1 = targetToken;

        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'TokenPriceOracle: NO_RESERVES'); // ensure that there's liquidity in the pair
    }

    function getData() external view returns (uint price, bool) {
        require(address(pair) != address(0), "ERR: zero address");

        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        uint token0Decimals = IERC20(token0).decimals();
        uint token1Decimals = IERC20(token1).decimals();

        if (token0 == pair.token0()) {
            price = uint(reserve1).div(10**token1Decimals).mul(10**18).div(
                uint(reserve0).div(10**token0Decimals)
            );
        } else {
            price = uint(reserve0).div(10**token0Decimals).mul(10**18).div(
                uint(reserve1).div(10**token1Decimals)
            );
        }

        return (price, true);
    }

}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "./BaseToken.sol";

contract Vault is OwnableUpgradeSafe {
    using SafeMath for uint256;

    BaseToken public BASE;
    IERC20    public stakeToken;

    uint256 public enrollmentPeriodStartTimestamp;
    uint256 public enrollmentPeriodDuration;
    uint256 public vestingStartTimestamp;
    uint256 public vestingDuration;
    uint256 public maxStaked;

    uint256 public totalStaked;
    uint256 public totalRewardShares;
    mapping(address => uint256) public staked;
    mapping(address => uint256) public sharesWithdrawnByUser;
    mapping(address => bool)    public unstaked;

    event Stake(address indexed user, uint256 newAmount, uint256 totalAmount);
    event Unstake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 tokensWithdrawnThisTime, uint256 totalSharesWithdrawnByUser);
    event RescueFunds(address token, address recipient, uint256 amount);
    event AddRewards(uint256 amountAdded, uint256 totalRewardTokens);
    event RemoveRewards(uint256 amountRemoved, uint256 totalRewardTokens);

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    /**
     * User methods
     */

    function stake(uint256 tokens)
        public
    {
        require(now > enrollmentPeriodStartTimestamp, "too soon");
        require(now < enrollmentPeriodStartTimestamp + enrollmentPeriodDuration, "too late");

        uint256 amount = stakeTokenIsBASE() ? tokensToShares(tokens) : tokens;
        require(maxStaked == 0 || totalStaked + amount < maxStaked, "full");

        staked[msg.sender] = staked[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);

        bool ok = stakeToken.transferFrom(msg.sender, address(this), tokens);
        require(ok, "transfer");

        emit Stake(msg.sender, amount, staked[msg.sender]);
    }

    function withdrawRewards()
        public
    {
        require(now > vestingStartTimestamp, "too soon");

        (uint256 tokens, uint256 shares) = withdrawable(msg.sender);
        require(tokens > 0, "no tokens");
        require(shares > 0, "no shares");

        sharesWithdrawnByUser[msg.sender] = sharesWithdrawnByUser[msg.sender].add(shares);

        bool ok = BASE.transfer(msg.sender, tokens);
        require(ok, "transfer reward");

        emit Withdraw(msg.sender, tokens, sharesWithdrawnByUser[msg.sender]);
    }

    function unstake()
        public
    {
        require(now > vestingStartTimestamp + vestingDuration, "too soon");

        require(unstaked[msg.sender] == false, "already unstaked");
        unstaked[msg.sender] = true;

        (uint256 tokens, uint256 shares) = withdrawable(msg.sender);
        require(shares > 0, "no stake");

        sharesWithdrawnByUser[msg.sender] = sharesWithdrawnByUser[msg.sender].add(shares);
        emit Withdraw(msg.sender, tokens, sharesWithdrawnByUser[msg.sender]);

        bool ok = BASE.transfer(msg.sender, tokens);
        require(ok, "transfer reward");

        uint256 amount = stakeTokenIsBASE() ? sharesToTokens(staked[msg.sender]) : staked[msg.sender];
        ok = stakeToken.transfer(msg.sender, amount);
        require(ok, "transfer deposit");

        emit Unstake(msg.sender, staked[msg.sender]);
    }

    /**
     * Getters
     */

    function vaultInfo(address user)
        public
        view
        returns (
            uint256 _enrollmentPeriodStartTimestamp,
            uint256 _enrollmentPeriodDuration,
            uint256 _vestingStartTimestamp,
            uint256 _vestingDuration,
            uint256 _maxStaked,
            uint256 _totalTokensStaked,
            uint256 _tokensStakedByUser,
            uint256 _totalRewardTokens,
            uint256 _tokensWithdrawableByUser,
            uint256 _tokensWithdrawnByUser
        )
    {
        _enrollmentPeriodStartTimestamp = enrollmentPeriodStartTimestamp;
        _enrollmentPeriodDuration = enrollmentPeriodDuration;
        _vestingStartTimestamp = vestingStartTimestamp;
        _vestingDuration = vestingDuration;
        _maxStaked = stakeTokenIsBASE() ? sharesToTokens(maxStaked) : maxStaked;
        _totalTokensStaked = stakeTokenIsBASE() ? sharesToTokens(totalStaked) : totalStaked;
        _tokensStakedByUser = stakeTokenIsBASE() ? sharesToTokens(staked[user]) : staked[user];
        _totalRewardTokens = sharesToTokens(totalRewardShares);
        (_tokensWithdrawableByUser, ) = withdrawable(user);
        _tokensWithdrawnByUser = sharesToTokens(sharesWithdrawnByUser[user]);
        return (
            _enrollmentPeriodStartTimestamp,
            _enrollmentPeriodDuration,
            _vestingStartTimestamp,
            _vestingDuration,
            _maxStaked,
            _totalTokensStaked,
            _tokensStakedByUser,
            _totalRewardTokens,
            _tokensWithdrawableByUser,
            _tokensWithdrawnByUser
        );
    }

    function withdrawable(address user)
        public
        view
        returns (uint256 tokens, uint256 shares)
    {
        uint256 secondsIntoVesting = vestingStartTimestamp >= now
                                        ? 0
                                        : now.sub(vestingStartTimestamp);
        if (secondsIntoVesting == 0) {
            return (0, 0);
        } else if (totalStaked == 0) {
            return (0, 0);
        }

        if (secondsIntoVesting > vestingDuration) {
            secondsIntoVesting = vestingDuration;
        }

        uint256 userRewardShares = totalRewardShares.mul(staked[user]).div(totalStaked);
        uint256 unlockedShares = userRewardShares.mul(secondsIntoVesting).div(vestingDuration).sub(sharesWithdrawnByUser[user]);
        uint256 unlockedTokens = sharesToTokens(unlockedShares);
        return (unlockedTokens, unlockedShares);
    }

    /**
     * Admin
     */

    function setupVault(
        BaseToken BASE_,
        IERC20 stakeToken_,
        uint256 maxStaked_,
        uint256 enrollmentPeriodStartTimestamp_,
        uint256 enrollmentPeriodDuration_,
        uint256 vestingStartTimestamp_,
        uint256 vestingDuration_
    )
        public
        onlyOwner
    {
        require(enrollmentPeriodDuration_ > 0, "enrollmentPeriodDuration is 0");
        require(vestingDuration_ > 0, "vestingDuration is 0");

        BASE = BASE_;
        stakeToken = stakeToken_;
        maxStaked = maxStaked_;
        enrollmentPeriodStartTimestamp = enrollmentPeriodStartTimestamp_;
        enrollmentPeriodDuration = enrollmentPeriodDuration_;
        vestingStartTimestamp = vestingStartTimestamp_;
        vestingDuration = vestingDuration_;
    }

    function addRewards(uint256 tokens)
        public
        onlyOwner
    {
        totalRewardShares = totalRewardShares.add(tokensToShares(tokens));
        bool ok = BASE.transferFrom(msg.sender, address(this), tokens);
        require(ok, "transfer");
        emit AddRewards(tokens, sharesToTokens(totalRewardShares));
    }

    function removeRewards(uint256 tokens)
        public
        onlyOwner
    {
        totalRewardShares = totalRewardShares.sub(tokensToShares(tokens));
        bool ok = BASE.transfer(msg.sender, tokens);
        require(ok, "transfer");
        emit RemoveRewards(tokens, sharesToTokens(totalRewardShares));
    }

    function adminRescueFunds(address token, address recipient, uint256 amount)
        public
        onlyOwner
    {
        emit RescueFunds(token, recipient, amount);

        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");
    }

    /**
     * Util
     */

    function stakeTokenIsBASE()
        private
        view
        returns (bool)
    {
        return address(stakeToken) == address(BASE);
    }

    function sharesToTokens(uint256 shares)
        public
        view
        returns (uint256)
    {
        return shares.mul(BASE.totalSupply()).div(BASE.totalShares());
    }

     function tokensToShares(uint256 tokens)
        public
        view
        returns (uint256)
    {
        return tokens.mul(BASE.totalShares().div(BASE.totalSupply()));
    }
}

