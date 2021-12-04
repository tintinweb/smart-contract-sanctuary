/**
 *Submitted for verification at polygonscan.com on 2021-12-03
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @uniswap/v2-core/contracts/interfaces/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;



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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/AssetToken.sol


pragma solidity ^0.8.2;
contract AssetToken is ERC20, ERC20Burnable, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}


// File contracts/StakingToken.sol


pragma solidity ^0.8.2;
contract StakingToken is ERC20, ERC20Burnable, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}


// File contracts/adminBases/interface/IOwnable.sol



pragma solidity ^0.8.2;

interface IOwnable {
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}


// File contracts/interface/IERC20Extented.sol


pragma solidity ^0.8.0;
interface IERC20Extented is IERC20 {
    function decimals() external view returns(uint8);
}


// File contracts/interface/IStakingToken.sol


pragma solidity ^0.8.0;
interface IStakingToken is IERC20Extented {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function owner() external view returns (address);
}


// File contracts/interface/IShortStaking.sol



pragma solidity ^0.8.2;
interface IShortStaking {
    function pendingNSDX(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount, address _realUser) external;
    function withdraw(uint256 _pid, uint256 _amount, address _realUser) external;
    function poolLength() external view returns (uint256);
}


// File contracts/adminBases/interface/IShortStaking_.sol



pragma solidity ^0.8.2;
interface IShortStaking_ is IShortStaking, IOwnable {
    function add(uint256 _rootPid, IStakingToken _shortToken, bool _withUpdate) external;
    function setMintAddr(address _mintAddr) external;
    function setNsdx(address _nsdx) external;
    function setMasterChef(address _masterChef) external;
}


// File contracts/adminBases/ShortStakingAdmin.sol



pragma solidity ^0.8.2;
abstract contract ShortStakingAdmin {

    // staking
    address public shortStaking;

    constructor(address staking_) {
        // require(IOwnable(staking_).owner() == address(this), "ShortStakingAdmin: wrong owner");
        shortStaking = staking_;
    }

    function shortStaking_add(uint256 _rootPid, address _shortToken, bool _withUpdate) public onlyOwner {
        IShortStaking_(shortStaking).add(_rootPid, IStakingToken(_shortToken), _withUpdate);
    }

    function shortStaking_setMintAddr(address _mintAddr) external onlyOwner {
        IShortStaking_(shortStaking).setMintAddr(_mintAddr);
    }

    function shortStaking_setNsdx(address _nsdx) external onlyOwner {
        IShortStaking_(shortStaking).setNsdx(_nsdx);
    }

    function shortStaking_setMasterChef(address _masterChef) external onlyOwner {
        IShortStaking_(shortStaking).setMasterChef(_masterChef);
    }

    function setShortStaking(address staking_) external onlyOwner {
        // require(IOwnable(staking_).owner() == address(this), "ShortStakingAdmin: wrong owner");
        shortStaking = staking_;
    }

    modifier onlyOwner() virtual {
        _;
    }
}


// File contracts/interface/IUniswapPair.sol



pragma solidity ^0.8.2;
interface IUniswapPair is IERC20 {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}


// File contracts/adminBases/interface/ILongStaking_.sol



pragma solidity ^0.8.2;
interface ILongStaking_ is IOwnable {
    function add(uint256 _rootPid, IStakingToken _shortToken, IUniswapPair _lpToken, bool _withUpdate) external;
    function setMintAddr(address _mintAddr) external;
    function setNsdx(address _nsdx) external;
    function setMasterChef(address _masterChef) external;
    function setSwapV2Router(address _swapRouter) external;
}


// File contracts/adminBases/LongStakingAdmin.sol



pragma solidity ^0.8.2;
abstract contract LongStakingAdmin {

    // staking
    address public longStaking;

    constructor(address staking_) {
        // require(IOwnable(staking_).owner() == address(this), "LongStakingAdmin: wrong owner");
        longStaking = staking_;
    }

    function longStaking_add(uint256 _rootPid, address _longToken, address _lpToken, bool _withUpdate) public onlyOwner {
        ILongStaking_(longStaking).add(_rootPid, IStakingToken(_longToken), IUniswapPair(_lpToken), _withUpdate);
    }

    function longStaking_setMintAddr(address _mintAddr) external onlyOwner {
        ILongStaking_(longStaking).setMintAddr(_mintAddr);
    }

    function longStaking_setNsdx(address _nsdx) external onlyOwner {
        ILongStaking_(longStaking).setNsdx(_nsdx);
    }

    function longStaking_setMasterChef(address _masterChef) external onlyOwner {
        ILongStaking_(longStaking).setMasterChef(_masterChef);
    }

    function setLongStaking(address staking_) external onlyOwner {
        // require(IOwnable(staking_).owner() == address(this), "LongStakingAdmin: wrong owner");
        longStaking = staking_;
    }

    modifier onlyOwner() virtual {
        _;
    }
}


// File contracts/adminBases/interface/IShortLock_.sol



pragma solidity ^0.8.2;
interface IShortLock_ is IOwnable {
    function setMintAddr(address _mintAddr) external;
    function setLockPeriod(uint lockPeriod_) external;
}


// File contracts/adminBases/ShortLockAdmin.sol



pragma solidity ^0.8.2;
abstract contract ShortLockAdmin {

    // short lock
    address public shortLock;

    constructor(address shortLock_) {
        // require(IOwnable(shortLock_).owner() == address(this), "ShortLockAdmin: wrong owner");
        shortLock = shortLock_;
    }

    function shortLock_setMintAddr(address _mintAddr) external onlyOwner {
        IShortLock_(shortLock).setMintAddr(_mintAddr);
    }

    function shortLock_setLockPeriod(uint lockPeriod_) external onlyOwner {
        IShortLock_(shortLock).setLockPeriod(lockPeriod_);
    }

    function setShortLock(address shortLock_) external onlyOwner {
        // require(IOwnable(shortLock_).owner() == address(this), "ShortLockAdmin: wrong owner");
        shortLock = shortLock_;
    }

    modifier onlyOwner() virtual {
        _;
    }
}


// File contracts/interface/IAssetToken.sol


pragma solidity ^0.8.0;
interface IAssetToken is IERC20Extented {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function owner() external view;
}


// File contracts/interface/IAsset.sol



pragma solidity ^0.8.2;
struct IPOParams{
    uint mintEnd;
    uint preIPOPrice;
    // >= 1000
    uint16 minCRatioAfterIPO;
}

struct AssetConfig {
    IAssetToken token;
    AggregatorV3Interface oracle;
    uint16 auctionDiscount;
    uint16 minCRatio;
    uint16 targetRatio;
    uint endPrice;
    uint8 endPriceDecimals;
    // 鏄惁鍦≒reIPO闃舵
    bool isInPreIPO;
    IPOParams ipoParams;
    // 鏄惁宸查€€甯?
    bool delisted;
    // the Id of the pool in ShortStaking contract.
    uint poolId;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

// Collateral Asset Config
struct CAssetConfig {
    IERC20Extented token;
    AggregatorV3Interface oracle;
    uint16 multiplier;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

interface IAsset {
    function asset(address nToken) external view returns(AssetConfig memory);
    function cAsset(address token) external view returns(CAssetConfig memory);
    function isCollateralInPreIPO(address cAssetToken) external view returns(bool);
}


// File contracts/adminBases/interface/IAsset_.sol



pragma solidity ^0.8.2;
interface IAsset_ is IAsset, IOwnable {
    function registerAsset(
        address assetToken, 
        address assetOracle, 
        uint16 auctionDiscount, 
        uint16 minCRatio, 
        uint16 targetRatio, 
        bool isInPreIPO, 
        uint poolId, 
        IPOParams memory ipoParams
    ) external;

    function updateAsset(
        address assetToken, 
        address assetOracle, 
        uint16 auctionDiscount, 
        uint16 minCRatio, 
        uint16 targetRatio, 
        bool isInPreIPO, 
        uint poolId, 
        IPOParams memory ipoParams
    ) external;

    function registerCollateral(address cAssetToken, address oracle, uint16 multiplier) external;

    function updateCollateral(address cAssetToken, address oracle, uint16 multiplier) external;

    function revokeCollateral(address cAssetToken) external;

    function triggerIPO(address assetToken) external;

    function registerMigration(address assetToken, uint endPrice, uint8 endPriceDecimals) external;

    function setCollateralInPreIPO(address cAssetToken, bool value) external;
}


// File contracts/adminBases/AssetAdmin.sol



pragma solidity ^0.8.2;
abstract contract AssetAdmin {

    // asset
    address public asset;

    constructor(address asset_) {
        // require(IOwnable(asset_).owner() == address(this), "AssetAdmin: wrong owner");
        asset = asset_;
    }

    function asset_registerAsset(
        address assetToken, 
        address assetOracle, 
        uint16 auctionDiscount, 
        uint16 minCRatio, 
        uint16 targetRatio, 
        bool isInPreIPO, 
        uint poolId, 
        IPOParams memory ipoParams
    ) internal {
        IAsset_(asset).registerAsset(assetToken, assetOracle, auctionDiscount, minCRatio, targetRatio, isInPreIPO, poolId, ipoParams);
    }

    function asset_updateAsset(
        address assetToken, 
        address assetOracle, 
        uint16 auctionDiscount, 
        uint16 minCRatio, 
        uint16 targetRatio, 
        bool isInPreIPO, 
        uint poolId, 
        IPOParams memory ipoParams
    ) external {
        IAsset_(asset).updateAsset(assetToken, assetOracle, auctionDiscount, minCRatio, targetRatio, isInPreIPO, poolId, ipoParams);
    }

    function asset_registerCollateral(address cAssetToken, address oracle, uint16 multiplier) external onlyOwner {
        IAsset_(asset).registerCollateral(cAssetToken, oracle, multiplier);
    }

    function asset_updateCollateral(address cAssetToken, address oracle, uint16 multiplier) external onlyOwner {
        IAsset_(asset).updateCollateral(cAssetToken, oracle, multiplier);
    }

    function asset_revokeCollateral(address cAssetToken) external onlyOwner {
        IAsset_(asset).revokeCollateral(cAssetToken);
    }

    function asset_triggerIPO(address assetToken) external onlyOwner {
        IAsset_(asset).triggerIPO(assetToken);
    }

    function asset_registerMigration(address assetToken, uint endPrice, uint8 endPriceDecimals) external onlyOwner {
        IAsset_(asset).registerMigration(assetToken, endPrice, endPriceDecimals);
    }

    function asset_setCollateralInPreIPO(address cAssetToken, bool value) external onlyOwner {
        IAsset_(asset).setCollateralInPreIPO(cAssetToken, value);
    }

    function setAsset(address asset_) external onlyOwner {
        // require(IOwnable(asset_).owner() == address(this), "AssetAdmin: wrong owner");
        asset = asset_;
    }

    modifier onlyOwner() virtual {
        _;
    }
}


// File contracts/adminBases/interface/IMint_.sol



pragma solidity ^0.8.2;
interface IMint_ is IOwnable {

    function swapToToken() external view returns(address);

    function updateState(
        address asset_,
        address positions_,
        uint oracleMaxDelay_,
        address swapToToken_,
        uint16 feeRate_,
        address lock_,
        address staking_,
        address swapRouter_
    ) external;
}


// File contracts/adminBases/MintAdmin.sol



pragma solidity ^0.8.2;
abstract contract MintAdmin {

    // mint
    address public mint;

    constructor(address mint_) {
        // require(IOwnable(mint_).owner() == address(this), "MintAdmin: wrong owner");
        mint = mint_;
    }

    function mint_updateState(
        address asset_,
        address positions_,
        uint oracleMaxDelay_,
        address swapToToken_,
        uint16 feeRate_,
        address lock_,
        address staking_,
        address swapRouter_
    ) external onlyOwner {
        IMint_(mint).updateState(
            asset_, 
            positions_, 
            oracleMaxDelay_, 
            swapToToken_, 
            feeRate_, 
            lock_, 
            staking_, 
            swapRouter_
        );
    }

    function setMint(address mint_) external onlyOwner {
        // require(IOwnable(mint_).owner() == address(this), "MintAdmin: wrong owner");
        mint = mint_;
    }

    modifier onlyOwner() virtual {
        _;
    }
}


// File contracts/interface/IMasterChef.sol



pragma solidity ^0.8.0;
interface IMasterChef {

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingNSDX(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function poolLength() external view returns (uint256);
}


// File contracts/adminBases/interface/IMasterChef_.sol



pragma solidity ^0.8.2;
interface IMasterChef_ is IMasterChef, IOwnable {
    function updateMultiplier(uint256 multiplierNumber) external;
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external;
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
    function setMaxMint(uint256 _nsdxMaxMint) external;
    function setPerBlock(uint256 _nsdxPerBlock, bool _withUpdate) external;
    function transferNSDXOwnership(address _newOwner) external;
}


// File contracts/adminBases/MasterChefAdmin.sol



pragma solidity ^0.8.2;
abstract contract MasterChefAdmin {

    // master chef
    address public masterChef;

    constructor(address masterChef_) {
        // require(IOwnable(masterChef_).owner() == address(this), "MasterChefAdmin: wrong owner");
        masterChef = masterChef_;
    }

    function masterChef_updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        IMasterChef_(masterChef).updateMultiplier(multiplierNumber);
    }

    function masterChef_add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        IMasterChef_(masterChef).add(_allocPoint, _lpToken, _withUpdate);
    }

    function masterChef_set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        IMasterChef_(masterChef).set(_pid, _allocPoint, _withUpdate);
    }

    function masterChef_setMaxMint(uint256 _nsdxMaxMint) external onlyOwner {
        IMasterChef_(masterChef).setMaxMint(_nsdxMaxMint);
    }

    function masterChef_setPerBlock(uint256 _nsdxPerBlock, bool _withUpdate) external onlyOwner {
        IMasterChef_(masterChef).setPerBlock(_nsdxPerBlock, _withUpdate);
    }

    function masterChef_transferNSDXOwnership(address _newOwner) external onlyOwner {
        IMasterChef_(masterChef).transferNSDXOwnership(_newOwner);
    }

    function setMasterChef(address masterChef_) external onlyOwner {
        // require(IOwnable(masterChef).owner() == address(this), "MasterChefAdmin: wrong owner");
        masterChef = masterChef_;
    }

    modifier onlyOwner() virtual {
        _;
    }
}


// File contracts/Admin.sol



pragma solidity ^0.8.2;
contract Admin is ShortStakingAdmin, LongStakingAdmin, ShortLockAdmin, AssetAdmin, MintAdmin, MasterChefAdmin {

    address public owner;
    
    // factory
    address public factory;
    

    // IAssetToken
    // IStakingToken

    constructor(
        address shortStaking_,
        address longStaking_,
        address shortLock_,
        address asset_,
        address mint_,
        address masterChef_, 
        address factory_
    ) 
    ShortStakingAdmin(shortStaking_)
    LongStakingAdmin(longStaking_)
    ShortLockAdmin(shortLock_)
    AssetAdmin(asset_)
    MintAdmin(mint_)
    MasterChefAdmin(masterChef_) {
        
        factory = factory_;
        owner = msg.sender;
    }

    modifier onlyOwner() override(
        ShortStakingAdmin, 
        LongStakingAdmin, 
        ShortLockAdmin, 
        AssetAdmin, 
        MintAdmin, 
        MasterChefAdmin
    ) {
        require(owner == msg.sender, "Admin: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Admin: new owner is the zero address");
        owner = newOwner;
    }

    function transferAllOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Admin: new owner is the zero address");
        IShortStaking_(shortStaking).transferOwnership(newOwner);
        ILongStaking_(longStaking).transferOwnership(newOwner);
        IShortLock_(shortLock).transferOwnership(newOwner);
        IAsset_(asset).transferOwnership(newOwner);
        IMint_(mint).transferOwnership(newOwner);
        IMasterChef_(masterChef).transferOwnership(newOwner);
    }

    struct WhiteListTokenParams {
        string nTokenName;
        string nTokenSymbol;
        string sTokenName;
        string sTokenSymbol;
        string lTokenName;
        string lTokenSymbol;
    }

    struct WhiteListParams {
        AggregatorV3Interface oracle;
        uint16 auctionDiscount;
        uint16 minCRatio;
        uint16 targetRatio;
        bool isInPreIPO;
    }

    function whiteList(
        WhiteListTokenParams memory tokenParams, 
        uint sAllocPoint_,
        uint lAllocPoint_,
        WhiteListParams memory whiteListParams, 
        IPOParams memory ipoParams
    ) external onlyOwner {
        AssetToken nToken = new AssetToken(tokenParams.nTokenName, tokenParams.nTokenSymbol);
        nToken.transferOwnership(mint);

        StakingToken sToken = new StakingToken(tokenParams.sTokenName, tokenParams.sTokenSymbol);
        sToken.transferOwnership(shortStaking);

        StakingToken lToken = new StakingToken(tokenParams.lTokenName, tokenParams.lTokenSymbol);
        lToken.transferOwnership(longStaking);

        address swapToToken = IMint_(mint).swapToToken();

        address pair = IUniswapV2Factory(factory).createPair(address(nToken), swapToToken);

        // add a long farm pool in MasterChef
        masterChef_add(lAllocPoint_, IERC20(lToken), false);
        uint rootPoolId = IMasterChef(masterChef).poolLength() - 1;

        // add a pool in LongStaking
        longStaking_add(rootPoolId, address(lToken), pair, false);

        // add a short farm pool in MasterChef
        masterChef_add(sAllocPoint_, IERC20(sToken), false);
        rootPoolId = IMasterChef(masterChef).poolLength() - 1;

        // add a pool in ShortStaking
        shortStaking_add(rootPoolId, address(sToken), false);
        uint poolId = IShortStaking(shortStaking).poolLength() - 1;

        // Register nAsset in Asset
        asset_registerAsset(
            address(nToken), 
            address(whiteListParams.oracle), 
            whiteListParams.auctionDiscount, 
            whiteListParams.minCRatio, 
            whiteListParams.targetRatio, 
            whiteListParams.isInPreIPO, 
            poolId, 
            ipoParams
        );
    }

    function setFactory(address factory_) external onlyOwner {
        factory = factory_;
    }
}