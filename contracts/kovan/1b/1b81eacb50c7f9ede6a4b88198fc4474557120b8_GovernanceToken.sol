pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./mocks/MockERC20.sol";
import "./GovernanceToken.sol";
import "./dutchSwap/IDutchAuction.sol";
import "./dutchSwap/IDutchSwapFactory.sol";
import "./IPriceOracle.sol";

contract AuctionManager is OwnableUpgradeSafe, ERC20UpgradeSafe {
  using SafeMath for uint256;

  // used as factor when dealing with %
  uint256 constant ACCURACY = 1e4;
  // when 95% at market price, start selling
  uint256 public sellThreshold;
  // cap auctions at certain amount of $TRDL minted
  uint256 public dilutionBound;
  // stop selling when volume small
  // uint256 public dustThreshold; set at dilutionBound / 52
  // % start_price above estimate, and % min_price below estimate
  uint256 public priceSpan;
  // auction duration
  uint256 public auctionDuration;

  MockERC20 private strudel;
  IERC20 private vBtc;
  GovernanceToken private gStrudel;
  IPriceOracle private btcPriceOracle;
  IPriceOracle private vBtcPriceOracle;
  IPriceOracle private strudelPriceOracle;
  IDutchSwapFactory private auctionFactory;
  uint256 private govIntervalLength;

  IDutchAuction public currentAuction;
  mapping(address => uint256) public lockTimeForAuction;

  constructor(
    address _strudelAddr,
    address _gStrudel,
    address _vBtcAddr,
    address _btcPriceOracle,
    address _vBtcPriceOracle,
    address _strudelPriceOracle,
    address _auctionFactory
  ) public {
    __Ownable_init();
    __ERC20_init("Strudel Auction Token", "a$TRDL");
    strudel = MockERC20(_strudelAddr);
    gStrudel = GovernanceToken(_gStrudel);
    govIntervalLength = gStrudel.intervalLength();
    vBtc = IERC20(_vBtcAddr);
    btcPriceOracle = IPriceOracle(_btcPriceOracle);
    vBtcPriceOracle = IPriceOracle(_vBtcPriceOracle);
    strudelPriceOracle = IPriceOracle(_strudelPriceOracle);
    auctionFactory = IDutchSwapFactory(_auctionFactory);
    sellThreshold = 9500; // vBTC @ 95% of BTC price or above
    dilutionBound = 70; // 0.7% of $TRDL total supply
    priceSpan = 2500; // 25%
    auctionDuration = 84600; // ~23,5h
  }

  function _getDiff(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) {
      return a - b;
    }
    return b - a;
  }

  function rotateAuctions() external {
    if (address(currentAuction) != address(0)) {
      require(currentAuction.auctionEnded(), "previous auction hasn't ended");
      try currentAuction.finaliseAuction() {
        // do nothing
      } catch Error(string memory) {
        // do nothing
      } catch (bytes memory) {
        // do nothing
      }
      uint256 studelReserves = strudel.balanceOf(address(this));
      if (studelReserves > 0) {
        strudel.burn(studelReserves);
      }
    }

    // get prices
    uint256 btcPriceInEth = btcPriceOracle.consult(1e18);
    uint256 vBtcPriceInEth = vBtcPriceOracle.consult(1e18);
    uint256 strudelPriceInEth = strudelPriceOracle.consult(1e18);

    // measure outstanding supply
    uint256 vBtcOutstandingSupply = vBtc.totalSupply();
    uint256 strudelSupply = strudel.totalSupply();
    uint256 vBtcAmount = vBtc.balanceOf(address(this));
    vBtcOutstandingSupply -= vBtcAmount;

    // calculate vBTC supply imbalance in ETH
    uint256 imbalance = _getDiff(btcPriceInEth, vBtcPriceInEth).mul(vBtcOutstandingSupply);

    uint256 cap = strudelSupply.mul(dilutionBound).mul(strudelPriceInEth).div(ACCURACY);
    // cap by dillution bound
    imbalance = Math.min(cap, imbalance);

    // pause if imbalance below dust threshold
    if (imbalance.div(strudelPriceInEth) < strudelSupply.mul(dilutionBound).div(52).div(ACCURACY)) {
      // pause auctions
      currentAuction = IDutchAuction(address(0));
      return;
    }

    // determine what kind of auction we want
    uint256 priceRelation = btcPriceInEth.mul(ACCURACY).div(vBtcPriceInEth);
    if (priceRelation < ACCURACY.mul(ACCURACY).div(sellThreshold)) {
      // cap vBtcAmount by imbalance in vBTC
      vBtcAmount = Math.min(vBtcAmount, imbalance.div(vBtcPriceInEth));
      // calculate vBTC price
      imbalance = vBtcPriceInEth.mul(1e18).div(strudelPriceInEth);
      // auction off some vBTC
      vBtc.approve(address(auctionFactory), vBtcAmount);
      currentAuction = IDutchAuction(
        auctionFactory.deployDutchAuction(
          address(vBtc),
          vBtcAmount,
          now,
          now + auctionDuration,
          address(strudel),
          imbalance.mul(ACCURACY.add(priceSpan)).div(ACCURACY), // startPrice
          imbalance.mul(ACCURACY.sub(priceSpan)).div(ACCURACY), // minPrice
          address(this)
        )
      );
    } else {
      // calculate price in vBTC
      vBtcAmount = strudelPriceInEth.mul(1e18).div(vBtcPriceInEth);
      // auction off some $TRDL
      currentAuction = IDutchAuction(
        auctionFactory.deployDutchAuction(
          address(this),
          imbalance.div(strudelPriceInEth), // calculate imbalance in $TRDL
          now,
          now + auctionDuration,
          address(vBtc),
          vBtcAmount.mul(ACCURACY.add(priceSpan)).div(ACCURACY), // startPrice
          vBtcAmount.mul(ACCURACY.sub(priceSpan)).div(ACCURACY), // minPrice
          address(this)
        )
      );

      // if imbalance >= dillution bound, use max lock (52 weeks)
      // if imbalance < dillution bound, lock shorter
      lockTimeForAuction[address(currentAuction)] = govIntervalLength.mul(52).mul(imbalance).div(
        cap
      );
    }
  }

  function setSellThreshold(uint256 _threshold) external onlyOwner {
    require(_threshold >= 6000, "threshold below 60% minimum");
    require(_threshold <= 12000, "threshold above 120% maximum");
    sellThreshold = _threshold;
  }

  function setDulutionBound(uint256 _dilutionBound) external onlyOwner {
    require(_dilutionBound <= 1000, "dilution bound above 10% max value");
    dilutionBound = _dilutionBound;
  }

  function setPriceSpan(uint256 _priceSpan) external onlyOwner {
    require(_priceSpan > 1000, "price span should have at least 10%");
    require(_priceSpan < ACCURACY, "price span larger accuracy");
    priceSpan = _priceSpan;
  }

  function setAuctionDuration(uint256 _auctionDuration) external onlyOwner {
    require(_auctionDuration >= 3600, "auctions should run at laest for 1 hour");
    require(_auctionDuration <= 604800, "auction duration should be less than week");
    auctionDuration = _auctionDuration;
  }

  function renounceMinter() external onlyOwner {
    strudel.renounceMinter();
  }

  function swipe(address tokenAddr) external onlyOwner {
    IERC20 token = IERC20(tokenAddr);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  // In deployDutchAuction, approve and transferFrom are called
  // In initDutchAuction, transferFrom is called again
  // In DutchAuction, transfer is called to either payout, or return money to AuctionManager

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override returns (bool success) {
    return true;
  }

  function approve(address _spender, uint256 _value) public override returns (bool success) {
    return true;
  }

  function transfer(address to, uint256 amount) public override returns (bool success) {
    // require sender is our Auction
    address auction = _msgSender();
    require(lockTimeForAuction[auction] > 0, "Caller is not our auction");

    // if recipient is AuctionManager, it means we are doing a refund -> do nothing
    if (to == address(this)) return true;

    uint256 blocks = lockTimeForAuction[auction];
    strudel.mint(address(this), amount);
    strudel.approve(address(gStrudel), amount);
    gStrudel.lock(to, amount, blocks, false);
    return true;
  }
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

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

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

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20UpgradeSafe {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 supply
  ) public {
    _mint(msg.sender, supply);
    __ERC20_init(name, symbol);
    _setupDecimals(decimals);
  }

  /**
   * @dev See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the {MinterRole}.
   */
  function mint(address account, uint256 amount) external returns (bool) {
    _mint(account, amount);
    return true;
  }

  /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
  /// total supply.
  /// @param _amount   The amount of tokens that will be burnt.
  function burn(uint256 _amount) external {
    _burn(msg.sender, _amount);
  }

  function renounceMinter() public {
    // do nothing
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./erc20/ITokenRecipient.sol";
import "./StrudelToken.sol";
import "./IGovBridge.sol";

/// @title  Strudel Governance Token.
/// @notice This is an ERC20 contract that mints by locking another token.
contract GovernanceToken is ERC20UpgradeSafe, OwnableUpgradeSafe, ITokenRecipient {
  using SafeMath for uint256;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint256) public nonces;

  StrudelToken private strudel;
  uint256 public intervalLength;
  IGovBridge public bridge;
  mapping(address => uint256) private lockData;

  function initialize(
    address _strudelAddr,
    address _bridgeAddr,
    uint256 _intervalLength
  ) external initializer {
    __ERC20_init("Strudel Governance Token", "g$TRDL");
    __Ownable_init();
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("g$TRDL")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
    require(_strudelAddr != address(0), "zero strudel");
    strudel = StrudelToken(_strudelAddr);
    require(_bridgeAddr != address(0), "zero bridge");
    bridge = IGovBridge(_bridgeAddr);
    _approve(address(this), _bridgeAddr, uint256(-1));
    require(_intervalLength > 0, "zero interval");
    intervalLength = _intervalLength;
  }

  function _parse(uint256 lockData)
    internal
    pure
    returns (
      uint256 endBlock,
      uint256 locked,
      uint256 minted
    )
  {
    endBlock = lockData >> 224;
    locked = uint256(uint112(lockData >> 112));
    minted = uint256(uint112(lockData));
  }

  function _compact(
    uint256 endBlock,
    uint256 locked,
    uint256 minted
  ) internal pure returns (uint256 lockData) {
    lockData = (endBlock << 224) | (locked << 112) | minted;
  }

  function getLock(address owner)
    external
    view
    returns (
      uint256 endBlock,
      uint256 lockTotal,
      uint256 mintTotal
    )
  {
    (endBlock, lockTotal, mintTotal) = _parse(lockData[owner]);
  }

  function _lock(
    address sender,
    address lockOwner,
    address tokenRecipient,
    uint256 amount,
    uint256 lockDuration
  ) internal returns (uint256 mintAmount) {
    require(lockOwner != address(0), "owner 0");
    require(tokenRecipient != address(0), "recipient 0");
    require(amount >= 1e15, "small deposit");
    require(lockDuration >= intervalLength, "lock too short");
    uint256 maxInterval = intervalLength * 52;
    require(lockDuration <= maxInterval, "lock too long");
    strudel.transferFrom(sender, address(this), amount);

    // (45850 * 52 * 2 - lockDuration) * lockDuration * amount
    // -------------------------------------------------------
    //                  45850 * 52 * 45850 * 52
    mintAmount = maxInterval.mul(2).sub(lockDuration).mul(lockDuration).mul(amount).div(
      maxInterval.mul(maxInterval)
    );

    uint256 endBlock;
    uint256 lockTotal;
    uint256 mintTotal;
    (endBlock, lockTotal, mintTotal) = _parse(lockData[lockOwner]);

    // TODO: this is sketch cus msg.sender not necesserally owner
    // if there is an existing lock for owner, that has matured,
    // _lock will fail if called from an address not owner
    // return previous lock, if matured
    if (lockTotal > 0 && block.number >= endBlock) {
      unlock();
      endBlock = block.number;
      lockTotal = 0;
      mintTotal = 0;
    }

    uint256 remainingLock = endBlock - block.number;
    // TODO: arithmetic mean here is not apropriate. should follow mintAmount formula
    uint256 averageDuration =
      remainingLock.mul(lockTotal).add(amount.mul(lockDuration)).div(amount.add(lockTotal));

    lockData[lockOwner] = _compact(
      block.number + averageDuration,
      lockTotal + amount,
      mintAmount + mintTotal
    );

    _mint(tokenRecipient, mintAmount);
  }

  function lock(
    address recipient,
    uint256 amount,
    uint256 blocks,
    bool deposit
  ) public returns (bool) {
    require(!deposit, "deposit not supported");
    if (msg.sender != recipient) {
      require(lockData[recipient] == 0, "recipient has a lock already");
    }
    _lock(_msgSender(), recipient, recipient, amount, blocks);
    return true;
  }

  function lockWithPermit(
    uint256 value,
    uint256 blocks,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bool deposit
  ) external returns (bool) {
    strudel.permit(_msgSender(), address(this), value, deadline, v, r, s);
    return lock(_msgSender(), value, blocks, deposit);
  }

  function getBlocks(bytes memory _extraData) internal pure returns (uint256) {
    uint256 blocks;
    assembly {
      blocks := mload(add(_extraData, 32))
    }
    return blocks;
  }

  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes calldata _extraData
  ) external override {
    require(msg.sender == address(strudel), "only $TRDL lockable");
    require(_token == address(strudel), "only accepting $TRDL");
    _lock(_from, _from, _from, _value, getBlocks(_extraData));
  }

  function _transferLock(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    uint256 lock = lockData[sender];
    uint256 mintTotal;
    (, , mintTotal) = _parse(lock);
    if (mintTotal > 0) {
      require(amount >= mintTotal, "not enough g$TRDL to transfer lock");
      require(lockData[recipient] == 0, "recipient has a lock already");
      // transfer g$TRDL and lock together
      lockData[recipient] = lock;
      lockData[sender] = 0;
    }
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    address msgSender = _msgSender();
    _transferLock(msgSender, recipient, amount);
    _transfer(msgSender, recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transferLock(sender, recipient, amount);
    _transfer(sender, recipient, amount);
    address msgSender = _msgSender();
    _approve(
      sender,
      msgSender,
      allowance(sender, msgSender).sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  function _sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  function unlock() public returns (bool) {
    uint256 endBlock;
    uint256 locked;
    uint256 minted;
    (endBlock, locked, minted) = _parse(lockData[_msgSender()]);
    require(locked > 0, "nothing to unlock");
    require(endBlock <= block.number, "lock has not passed yet");
    lockData[_msgSender()] = 0;
    _burn(_msgSender(), minted);
    strudel.transfer(_msgSender(), locked);

    uint256 normalizer = 1000000000;
    // (               lockAmount - mintAmount  )
    // (normalizer - ---------------------------) * 52
    // (                    lockAmount          )

    uint256 approx = normalizer.sub(locked.sub(minted).mul(normalizer).div(locked)).mul(52);
    uint256 trdlReward = _sqrt(locked).mul(approx).div(52);
    strudel.mint(_msgSender(), trdlReward);
  }

  /// @notice           Set allowance for other address and notify.
  ///                   Allows `_spender` to spend no more than `_value`
  ///                   tokens on your behalf and then ping the contract about
  ///                   it.
  /// @dev              The `_spender` should implement the `ITokenRecipient`
  ///                   interface to receive approval notifications.
  /// @param _spender   Address of contract authorized to spend.
  /// @param _value     The max amount they can spend.
  /// @param _extraData Extra information to send to the approved contract.
  /// @return true if the `_spender` was successfully approved and acted on
  ///         the approval, false (or revert) otherwise.
  function approveAndCall(
    ITokenRecipient _spender,
    uint256 _value,
    bytes calldata _extraData
  ) external returns (bool) {
    // not external to allow bytes memory parameters
    if (approve(address(_spender), _value)) {
      _spender.receiveApproval(_msgSender(), _value, address(this), _extraData);
      return true;
    }
    return false;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "Strudel Gov: EXPIRED");
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
      );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(
      recoveredAddress != address(0) && recoveredAddress == owner,
      "Strudel Gov: INVALID_SIGNATURE"
    );
    _approve(owner, spender, value);
  }
}

pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

interface IDutchAuction {
  function initDutchAuction(
    address _funder,
    address _token,
    uint256 _tokenSupply,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address payable _wallet
  ) external;

  function auctionEnded() external view returns (bool);

  function tokensClaimed(address user) external view returns (uint256);

  function tokenSupply() external view returns (uint256);

  function wallet() external view returns (address);

  function minimumPrice() external view returns (uint256);

  function clearingPrice() external view returns (uint256);

  function auctionToken() external view returns (address);

  function endDate() external view returns (uint256);

  function finaliseAuction() external;

  function paymentCurrency() external view returns (address);
}

pragma solidity 0.6.6;

interface IDutchSwapFactory {
  function deployDutchAuction(
    address _token,
    uint256 _tokenSupply,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address _wallet
  ) external returns (address dutchAuction);
}

pragma solidity 0.6.6;

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
interface IPriceOracle {
  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountIn) external view returns (uint256 amountOut);
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

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

/// @title Interface of recipient contract for `approveAndCall` pattern.
///        Implementors will be able to be used in an `approveAndCall`
///        interaction with a supporting contract, such that a token approval
///        can call the contract acting on that approval in a single
///        transaction.
///
///        See the `FundingScript` and `RedemptionScript` contracts as examples.
interface ITokenRecipient {
  /// Typically called from a token contract's `approveAndCall` method, this
  /// method will receive the original owner of the token (`_from`), the
  /// transferred `_value` (in the case of an ERC721, the token id), the token
  /// address (`_token`), and a blob of `_extraData` that is informally
  /// specified by the implementor of this method as a way to communicate
  /// additional parameters.
  ///
  /// Token calls to `receiveApproval` should revert if `receiveApproval`
  /// reverts, and reverts should remove the approval.
  ///
  /// @param _from The original owner of the token approved for transfer.
  /// @param _value For an ERC20, the amount approved for transfer; for an
  ///        ERC721, the id of the token approved for transfer.
  /// @param _token The address of the contract for the token whose transfer
  ///        was approved.
  /// @param _extraData An additional data blob forwarded unmodified through
  ///        `approveAndCall`, used to allow the token owner to pass
  ///         additional parameters and data to this method. The structure of
  ///         the extra data is informally specified by the implementor of
  ///         this interface.
  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes calldata _extraData
  ) external;
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./erc20/MinterRole.sol";
import "./erc20/ITokenRecipient.sol";

/// @title  Strudel Token.
/// @notice This is the Strudel ERC20 contract.
contract StrudelToken is ERC20UpgradeSafe, MinterRole {
  using SafeMath for uint256;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint256) public nonces;

  constructor() public {
    __ERC20_init("Strudel Finance", "$TRDL");
    __Ownable_init();
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("Strudel Finance")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  /**
   * @dev See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the {MinterRole}.
   */
  function mint(address account, uint256 amount) external onlyMinter returns (bool) {
    _mint(account, amount);
    return true;
  }

  /// @dev             Burns an amount of the token from the given account's balance.
  ///                  deducting from the sender's allowance for said account.
  ///                  Uses the internal _burn function.
  /// @param _account  The account whose tokens will be burnt.
  /// @param _amount   The amount of tokens that will be burnt.
  function burnFrom(address _account, uint256 _amount) external {
    uint256 decreasedAllowance =
      allowance(_account, _msgSender()).sub(_amount, "ERC20: burn amount exceeds allowance");

    _approve(_account, _msgSender(), decreasedAllowance);
    _burn(_account, _amount);
  }

  /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
  /// total supply.
  /// @param _amount   The amount of tokens that will be burnt.
  function burn(uint256 _amount) external {
    _burn(msg.sender, _amount);
  }

  /// @notice           Set allowance for other address and notify.
  ///                   Allows `_spender` to spend no more than `_value`
  ///                   tokens on your behalf and then ping the contract about
  ///                   it.
  /// @dev              The `_spender` should implement the `ITokenRecipient`
  ///                   interface to receive approval notifications.
  /// @param _spender   Address of contract authorized to spend.
  /// @param _value     The max amount they can spend.
  /// @param _extraData Extra information to send to the approved contract.
  /// @return true if the `_spender` was successfully approved and acted on
  ///         the approval, false (or revert) otherwise.
  function approveAndCall(
    ITokenRecipient _spender,
    uint256 _value,
    bytes memory _extraData
  ) public returns (bool) {
    // not external to allow bytes memory parameters
    if (approve(address(_spender), _value)) {
      _spender.receiveApproval(msg.sender, _value, address(this), _extraData);
      return true;
    }
    return false;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "Strudel: EXPIRED");
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
      );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(
      recoveredAddress != address(0) && recoveredAddress == owner,
      "Strudel: INVALID_SIGNATURE"
    );
    _approve(owner, spender, value);
  }
}

pragma solidity 0.6.6;

interface IGovBridge {
  function deposit(
    address token,
    uint256 amountOrId,
    address receiver
  ) external;
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./Roles.sol";

contract MinterRole is ContextUpgradeSafe, OwnableUpgradeSafe {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  modifier onlyMinter() {
    require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters.has(account);
  }

  function addMinter(address account) public onlyOwner {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(_msgSender());
  }

  function _addMinter(address account) internal {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    _minters.remove(account);
    emit MinterRemoved(account);
  }
}

pragma solidity 0.6.6;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account), "Roles: account already has role");
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    require(has(role, account), "Roles: account does not have role");
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "Roles: account is the zero address");
    return role.bearer[account];
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "./IPriceOracle.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract SpotPriceOracle is IPriceOracle {
  using FixedPoint for *;

  uint256 public constant PERIOD = 1 minutes;

  address public immutable weth;
  address public immutable factory;
  address public immutable vBtc;

  // working memory
  uint256 public priceCumulativeLast;
  uint32 public blockTimestampLast;
  FixedPoint.uq112x112 public priceAverage;

  constructor(
    address _factory,
    address _wEth,
    address _vBtc
  ) public {
    factory = _factory;
    weth = _wEth;

    // check inputs
    require(_vBtc != address(0), "zero token");
    vBtc = _vBtc;

    // check pair
    IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(_factory, _wEth, _vBtc));
    require(address(pair) != address(0), "no pair");
    uint112 reserve0;
    uint112 reserve1;
    (reserve0, reserve1, ) = pair.getReserves();
    require(reserve0 != 0 && reserve1 != 0, "SpotOracle: NO_RESERVES"); // ensure that there's liquidity in the pair

    // fetch the current accumulated price value (0 / 1)
    priceCumulativeLast = (pair.token0() == _wEth)
      ? pair.price1CumulativeLast()
      : pair.price0CumulativeLast();
  }

  function update() external {
    uint32 blockTimestamp;
    uint224 priceSum = 0;

    IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, weth, vBtc));
    uint256 price0Cumulative;
    uint256 price1Cumulative;
    (price0Cumulative, price1Cumulative, blockTimestamp) = UniswapV2OracleLibrary
      .currentCumulativePrices(address(pair));
    uint256 priceCumulative = (pair.token0() == weth) ? price1Cumulative : price0Cumulative;
    uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

    // ensure that at least one full period has passed since the last update
    require(timeElapsed >= PERIOD, "ExampleOracleSimple: PERIOD_NOT_ELAPSED");

    // overflow is desired, casting never truncates
    // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
    priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
    );
    priceCumulativeLast = priceCumulative;
    blockTimestampLast = blockTimestamp;
  }

  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountIn) external view override returns (uint256 amountOut) {
    return priceAverage.mul(amountIn).decode144();
  }
}

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Babylonian.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "../IPriceOracle.sol";

contract MockPriceOracle is IPriceOracle {
  using FixedPoint for *;

  FixedPoint.uq112x112 public priceAverage;

  function update(uint256 average) external {
    priceAverage = FixedPoint.fraction(uint112(average), uint112(1e6));
  }

  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountOfX) external view override returns (uint256 priceInEth) {
    return priceAverage.mul(amountOfX).decode144();
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import {TypedMemView} from "./summa-tx/TypedMemView.sol";
import {ViewBTC} from "./summa-tx/ViewBTC.sol";
import {ViewSPV} from "./summa-tx/ViewSPV.sol";
import "./erc20/ITokenRecipient.sol";
import "./summa-tx/IRelay.sol";
import "./StrudelToken.sol";
import "./FlashERC20.sol";

/// @title  VBTC Token.
/// @notice This is the VBTC ERC20 contract.
contract VbtcToken is FlashERC20, ERC20CappedUpgradeSafe {
  using SafeMath for uint256;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ViewBTC for bytes29;
  using ViewSPV for bytes29;

  event Crossing(
    bytes32 indexed btcTxHash,
    address indexed receiver,
    uint256 amount,
    uint32 outputIndex
  );

  uint8 constant ADDR_LEN = 20;
  uint256 constant BTC_CAP_SQRT = 4582575700000; // sqrt(BTC_CAP)
  bytes3 constant PROTOCOL_ID = 0x07ffff; // a mersenne prime
  bytes32 public DOMAIN_SEPARATOR;

  // immutable
  StrudelToken private strudel;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  // gov params
  IRelay public relay;
  uint256 public numConfs;
  uint256 public relayReward;

  // working memory
  // marking all sucessfully processed outputs
  mapping(bytes32 => bool) public knownOutpoints;
  mapping(address => uint256) public nonces;

  function initialize(
    address _relay,
    address _strudel,
    uint256 _minConfs,
    uint256 _relayReward
  ) public initializer {
    relay = IRelay(_relay);
    strudel = StrudelToken(_strudel);
    numConfs = _minConfs;
    relayReward = _relayReward;
    // chain constructors?
    __Flash_init("Strudel BTC", "VBTC");
    __ERC20Capped_init(BTC_CAP);
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("Strudel BTC")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20CappedUpgradeSafe, ERC20UpgradeSafe) {
    super._beforeTokenTransfer(from, to, amount);
  }

  function makeCompressedOutpoint(bytes32 _txid, uint32 _index) internal pure returns (bytes32) {
    // sacrifice 4 bytes instead of hashing
    return ((_txid >> 32) << 32) | bytes32(uint256(_index));
  }

  /// @notice             Verifies inclusion of a tx in a header, and that header in the Relay chain
  /// @dev                Specifically we check that both the best tip and the heaviest common header confirm it
  /// @param  _header     The header containing the merkleroot committing to the tx
  /// @param  _proof      The merkle proof intermediate nodes
  /// @param  _index      The index of the tx in the merkle tree's leaves
  /// @param  _txid       The txid that is the proof leaf
  function _checkInclusion(
    bytes29 _header, // Header
    bytes29 _proof, // MerkleArray
    uint256 _index,
    bytes32 _txid
  ) internal view returns (bool) {
    // check the txn is included in the header
    require(ViewSPV.prove(_txid, _header.merkleRoot(), _proof, _index), "Bad inclusion proof");

    // check the header is included in the chain
    bytes32 headerHash = _header.hash256();
    bytes32 GCD = relay.getLastReorgCommonAncestor();
    require(relay.isAncestor(headerHash, GCD, 2500), "GCD does not confirm header");

    // check offset to tip
    bytes32 bestKnownDigest = relay.getBestKnownDigest();
    uint256 height = relay.findHeight(headerHash);
    require(height > 0, "height not found in relay");
    uint256 offset = relay.findHeight(bestKnownDigest).sub(height);
    require(offset >= numConfs, "Insufficient confirmations");

    return true;
  }

  /// @dev             Mints an amount of the token and assigns it to an account.
  ///                  Uses the internal _mint function.
  /// @param _header   header
  /// @param _proof    proof
  /// @param _version  version
  /// @param _locktime locktime
  /// @param _index    tx index in block
  /// @param _crossingOutputIndex    output index that
  /// @param _vin      vin
  /// @param _vout     vout
  function proofOpReturnAndMint(
    bytes calldata _header,
    bytes calldata _proof,
    bytes4 _version,
    bytes4 _locktime,
    uint256 _index,
    uint32 _crossingOutputIndex,
    bytes calldata _vin,
    bytes calldata _vout
  ) external returns (bool) {
    return
      _provideProof(
        _header,
        _proof,
        _version,
        _locktime,
        _index,
        _crossingOutputIndex,
        _vin,
        _vout
      );
  }

  function _provideProof(
    bytes memory _header,
    bytes memory _proof,
    bytes4 _version,
    bytes4 _locktime,
    uint256 _index,
    uint32 _crossingOutputIndex,
    bytes memory _vin,
    bytes memory _vout
  ) internal returns (bool) {
    bytes32 txId = abi.encodePacked(_version, _vin, _vout, _locktime).ref(0).hash256();
    bytes32 outpoint = makeCompressedOutpoint(txId, _crossingOutputIndex);
    require(!knownOutpoints[outpoint], "already processed outputs");

    _checkInclusion(
      _header.ref(0).tryAsHeader().assertValid(),
      _proof.ref(0).tryAsMerkleArray().assertValid(),
      _index,
      txId
    );

    // mark processed
    knownOutpoints[outpoint] = true;

    // do payouts
    address account;
    uint256 amount;
    (account, amount) = doPayouts(_vout.ref(0).tryAsVout(), _crossingOutputIndex);
    emit Crossing(txId, account, amount, _crossingOutputIndex);
    return true;
  }

  function doPayouts(bytes29 _vout, uint32 _crossingOutputIndex)
    internal
    returns (address account, uint256 amount)
  {
    bytes29 output = _vout.indexVout(_crossingOutputIndex);

    // extract receiver and address
    amount = output.value() * 10**10; // wei / satosh = 10^18 / 10^8 = 10^10
    require(amount > 0, "output has 0 value");

    bytes29 opReturnPayload = output.scriptPubkey().opReturnPayload();
    require(opReturnPayload.len() == ADDR_LEN + 3, "invalid op-return payload length");
    require(bytes3(opReturnPayload.index(0, 3)) == PROTOCOL_ID, "invalid protocol id");
    account = address(bytes20(opReturnPayload.index(3, ADDR_LEN)));

    uint256 sqrtVbtcBefore = Babylonian.sqrt(totalSupply());
    _mint(account, amount);
    uint256 sqrtVbtcAfter = Babylonian.sqrt(totalSupply());

    // calculate the reward as area h(x) = f(x) - g(x), where f(x) = x^2 and g(x) = |minted|
    // pay out only the delta to the previous claim: H(after) - H(before)
    // this caps all minting rewards to 2/3 of BTC_CAP
    uint256 rewardAmount =
      BTC_CAP
        .mul(3)
        .mul(sqrtVbtcAfter)
        .add(sqrtVbtcBefore**3)
        .sub(BTC_CAP.mul(3).mul(sqrtVbtcBefore))
        .sub(sqrtVbtcAfter**3)
        .div(3)
        .div(BTC_CAP_SQRT);
    strudel.mint(account, rewardAmount);
    strudel.mint(owner(), rewardAmount.div(devFundDivRate));
  }

  // TODO: implement
  // bytes calldata _header,
  // bytes calldata _proof,
  // uint256 _index,
  // bytes32 _txid,
  function proofP2FSHAndMint(
    bytes calldata _header,
    bytes calldata _proof,
    uint256 _index,
    bytes32 _txid
  ) external virtual returns (bool) {
    require(false, "not implemented");
  }

  /// @dev             Burns an amount of the token from the given account's balance.
  ///                  deducting from the sender's allowance for said account.
  ///                  Uses the internal _burn function.
  /// @param _account  The account whose tokens will be burnt.
  /// @param _amount   The amount of tokens that will be burnt.
  function burnFrom(address _account, uint256 _amount) external {
    uint256 decreasedAllowance =
      allowance(_account, _msgSender()).sub(_amount, "ERC20: burn amount exceeds allowance");

    _approve(_account, _msgSender(), decreasedAllowance);
    _burn(_account, _amount);
  }

  /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
  /// total supply.
  /// @param _amount   The amount of tokens that will be burnt.
  function burn(uint256 _amount) external {
    _burn(msg.sender, _amount);
  }

  /// @notice           Set allowance for other address and notify.
  ///                   Allows `_spender` to spend no more than `_value`
  ///                   tokens on your behalf and then ping the contract about
  ///                   it.
  /// @dev              The `_spender` should implement the `ITokenRecipient`
  ///                   interface to receive approval notifications.
  /// @param _spender   Address of contract authorized to spend.
  /// @param _value     The max amount they can spend.
  /// @param _extraData Extra information to send to the approved contract.
  /// @return true if the `_spender` was successfully approved and acted on
  ///         the approval, false (or revert) otherwise.
  function approveAndCall(
    ITokenRecipient _spender,
    uint256 _value,
    bytes calldata _extraData
  ) external returns (bool) {
    // not external to allow bytes memory parameters
    if (approve(address(_spender), _value)) {
      _spender.receiveApproval(msg.sender, _value, address(this), _extraData);
      return true;
    }
    return false;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "vBTC: EXPIRED");
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
      );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "VBTC: INVALID_SIGNATURE");
    _approve(owner, spender, value);
  }

  function setRelayReward(uint256 _newRelayReward) external onlyOwner {
    require(_newRelayReward > 0, "!newRelayReward-0");
    relayReward = _newRelayReward;
  }

  function setRelayAddress(address _newRelayAddr) external onlyOwner {
    require(_newRelayAddr != address(0), "!newRelayAddr-0");
    relay = IRelay(_newRelayAddr);
  }

  function setNumConfs(uint256 _numConfs) external onlyOwner {
    require(_numConfs > 0, "!newNumConfs-0");
    require(_numConfs < 100, "!newNumConfs-useless");
    numConfs = _numConfs;
  }
}

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "../../Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20CappedUpgradeSafe is Initializable, ERC20UpgradeSafe {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */

    function __ERC20Capped_init(uint256 cap) internal initializer {
        __Context_init_unchained();
        __ERC20Capped_init_unchained(cap);
    }

    function __ERC20Capped_init_unchained(uint256 cap) internal initializer {


        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;

    }


    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }

    uint256[49] private __gap;
}

pragma solidity 0.6.6;

import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

library TypedMemView {
  using SafeMath for uint256;

  // Why does this exist?
  // the solidity `bytes memory` type has a few weaknesses.
  // 1. You can't index ranges effectively
  // 2. You can't slice without copying
  // 3. The underlying data may represent any type
  // 4. Solidity never deallocates memory, and memory costs grow
  //    superlinearly

  // By using a memory view instead of a `bytes memory` we get the following
  // advantages:
  // 1. Slices are done on the stack, by manipulating the pointer
  // 2. We can index arbitrary ranges and quickly convert them to stack types
  // 3. We can insert type info into the pointer, and typecheck at runtime

  // This makes `TypedMemView` a useful tool for efficient zero-copy
  // algorithms.

  // Why bytes29?
  // We want to avoid confusion between views, digests, and other common
  // types so we chose a large and uncommonly used odd number of bytes
  //
  // Note that while bytes are left-aligned in a word, integers and addresses
  // are right-aligned. This means when working in assembly we have to
  // account for the 3 unused bytes on the righthand side
  //
  // First 5 bytes are a type flag.
  // - ff_ffff_fffe is reserved for unknown type.
  // - ff_ffff_ffff is reserved for invalid types/errors.
  // next 12 are memory address
  // next 12 are len
  // bottom 3 bytes are empty

  // Assumptions:
  // - non-modification of memory.
  // - No Solidity updates
  // - - wrt free mem point
  // - - wrt bytes representation in memory
  // - - wrt memory addressing in general

  // Usage:
  // - create type constants
  // - use `assertType` for runtime type assertions
  // - - unfortunately we can't do this at compile time yet :(
  // - recommended: implement modifiers that perform type checking
  // - - e.g.
  // - - `uint40 constant MY_TYPE = 3;`
  // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
  // - instantiate a typed view from a bytearray using `ref`
  // - use `index` to inspect the contents of the view
  // - use `slice` to create smaller views into the same memory
  // - - `slice` can increase the offset
  // - - `slice can decrease the length`
  // - - must specify the output type of `slice`
  // - - `slice` will return a null view if you try to overrun
  // - - make sure to explicitly check for this with `notNull` or `assertType`
  // - use `equal` for typed comparisons.

  // The null view
  bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
  uint8 constant TWELVE_BYTES = 96;

  // Returns the encoded hex charcter that represents the lower 4 bits of the argument.
  function nibbleHex(uint8 _b) internal pure returns (uint8) {
    // This can probably be done more efficiently, but it's only in error
    // paths, so we don't really care :)
    uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
    if (_nibble == 0xf0) {
      return 0x30;
    } // 0
    if (_nibble == 0xf1) {
      return 0x31;
    } // 1
    if (_nibble == 0xf2) {
      return 0x32;
    } // 2
    if (_nibble == 0xf3) {
      return 0x33;
    } // 3
    if (_nibble == 0xf4) {
      return 0x34;
    } // 4
    if (_nibble == 0xf5) {
      return 0x35;
    } // 5
    if (_nibble == 0xf6) {
      return 0x36;
    } // 6
    if (_nibble == 0xf7) {
      return 0x37;
    } // 7
    if (_nibble == 0xf8) {
      return 0x38;
    } // 8
    if (_nibble == 0xf9) {
      return 0x39;
    } // 9
    if (_nibble == 0xfa) {
      return 0x61;
    } // a
    if (_nibble == 0xfb) {
      return 0x62;
    } // b
    if (_nibble == 0xfc) {
      return 0x63;
    } // c
    if (_nibble == 0xfd) {
      return 0x64;
    } // d
    if (_nibble == 0xfe) {
      return 0x65;
    } // e
    if (_nibble == 0xff) {
      return 0x66;
    } // f
  }

  // Returns a uint16 containing the hex-encoded byte
  function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
    encoded |= nibbleHex(_b >> 4); // top 4 bits
    encoded <<= 8;
    encoded |= nibbleHex(_b); // lower 4 bits
  }

  // Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
  // `second` contains the encoded lower 16 bytes.
  function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
    for (uint8 i = 31; i > 15; i -= 1) {
      uint8 _byte = uint8(_b >> (i * 8));
      first |= byteHex(_byte);
      if (i != 16) {
        first <<= 16;
      }
    }

    // abusing underflow here =_=
    for (uint8 i = 15; i < 255; i -= 1) {
      uint8 _byte = uint8(_b >> (i * 8));
      second |= byteHex(_byte);
      if (i != 0) {
        second <<= 16;
      }
    }
  }

  /// @notice          Changes the endianness of a uint256
  /// @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
  /// @param _b        The unsigned integer to reverse
  /// @return v        The reversed value
  function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
    v = _b;

    // swap bytes
    v =
      ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
      ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    v =
      ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
      ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    v =
      ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
      ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    v =
      ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
      ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  /// Create a mask with the highest `_len` bits set
  function leftMask(uint8 _len) private pure returns (uint256 mask) {
    // ugly. redo without assembly?
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      mask := sar(sub(_len, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
    }
  }

  /// Return the null view
  function nullView() internal pure returns (bytes29) {
    return NULL;
  }

  /// Check if the view is null
  function isNull(bytes29 memView) internal pure returns (bool) {
    return memView == NULL;
  }

  /// Check if the view is not null
  function notNull(bytes29 memView) internal pure returns (bool) {
    return !isNull(memView);
  }

  /// Check if the view is of a valid type and points to a valid location in
  /// memory. We perform this check by examining solidity's unallocated
  /// memory pointer and ensuring that the view's upper bound is less than
  /// that.
  function isValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return false;
    }
    uint256 _end = end(memView);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      ret := not(gt(_end, mload(0x40)))
    }
  }

  /// Require that a typed memory view be valid.
  /// Returns the view for easy chaining
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    require(isValid(memView), "Validity assertion failed");
    return memView;
  }

  /// Return true if the memview is of the expected type. Otherwise false.
  function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
    return typeOf(memView) == _expected;
  }

  /// Require that a typed memory view has a specific type.
  /// Returns the view for easy chaining
  function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
    if (!isType(memView, _expected)) {
      (, uint256 g) = encodeHex(uint256(typeOf(memView)));
      (, uint256 e) = encodeHex(uint256(_expected));
      string memory err =
        string(
          abi.encodePacked("Type assertion failed. Got 0x", uint80(g), ". Expected 0x", uint80(e))
        );
      revert(err);
    }
    return memView;
  }

  /// Return an identical view with a different type
  function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
    // then | in the new type
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      // shift off the top 5 bytes
      newView := or(newView, shr(40, shl(40, memView)))
      newView := or(newView, shl(216, _newType))
    }
  }

  /// Unsafe raw pointer construction. This should generally not be called
  /// directly. Prefer `ref` wherever possible.
  function buildUnchecked(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) private pure returns (bytes29 newView) {
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      newView := shl(96, or(newView, _type)) // insert type
      newView := shl(96, or(newView, _loc)) // insert loc
      newView := shl(24, or(newView, _len)) // empty bottom 3 bytes
    }
  }

  /// Instantiate a new memory view. This should generally not be called
  /// directly. Prefer `ref` wherever possible.
  function build(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) internal pure returns (bytes29 newView) {
    uint256 _end = _loc.add(_len);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      if gt(_end, mload(0x40)) {
        _end := 0
      }
    }
    if (_end == 0) {
      return NULL;
    }
    newView = buildUnchecked(_type, _loc, _len);
  }

  /// Instantiate a memory view from a byte array.
  ///
  /// Note that due to Solidity memory representation, it is not possible to
  /// implement a deref, as the `bytes` type stores its len in memory.
  function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
    uint256 _len = arr.length;

    uint256 _loc;
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      _loc := add(arr, 0x20) // our view is of the data, not the struct
    }

    return build(newType, _loc, _len);
  }

  /// Return the associated type information
  function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      // 216 == 256 - 40
      _type := shr(216, memView) // shift out lower 24 bytes
    }
  }

  /// Optimized type comparison. Checks that the 5-byte type flag is equal.
  function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
  }

  /// Return the memory address of the underlying bytes
  function loc(bytes29 memView) internal pure returns (uint96 _loc) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
      _loc := and(shr(120, memView), _mask)
    }
  }

  /// The number of memory words this memory view occupies, rounded up
  function words(bytes29 memView) internal pure returns (uint256) {
    return uint256(len(memView)).add(32) / 32;
  }

  /// The in-memory footprint of a fresh copy of the view
  function footprint(bytes29 memView) internal pure returns (uint256) {
    return words(memView) * 32;
  }

  /// The number of bytes of the view
  function len(bytes29 memView) internal pure returns (uint96 _len) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      _len := and(shr(24, memView), _mask)
    }
  }

  /// Returns the endpoint of the `memView`
  function end(bytes29 memView) internal pure returns (uint256) {
    return loc(memView) + len(memView);
  }

  /// Safe slicing without memory modification.
  function slice(
    bytes29 memView,
    uint256 _index,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    uint256 _loc = loc(memView);

    // Ensure it doesn't overrun the view
    if (_loc.add(_index).add(_len) > end(memView)) {
      return NULL;
    }

    _loc = _loc.add(_index);
    return build(newType, _loc, _len);
  }

  /// Shortcut to `slice`. Gets a view representing the first `_len` bytes
  function prefix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, 0, _len, newType);
  }

  /// Shortcut to `slice`. Gets a view representing the last `_len` byte
  function postfix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, uint256(len(memView)).sub(_len), _len, newType);
  }

  /// Construct an error message for an indexing overrun.
  function indexErrOverrun(
    uint256 _loc,
    uint256 _len,
    uint256 _index,
    uint256 _slice
  ) internal pure returns (string memory err) {
    (, uint256 a) = encodeHex(_loc);
    (, uint256 b) = encodeHex(_len);
    (, uint256 c) = encodeHex(_index);
    (, uint256 d) = encodeHex(_slice);
    err = string(
      abi.encodePacked(
        "TypedMemView/index - Overran the view. Slice is at 0x",
        uint48(a),
        " with length 0x",
        uint48(b),
        ". Attempted to index at offset 0x",
        uint48(c),
        " with length 0x",
        uint48(d),
        "."
      )
    );
  }

  /// Load up to 32 bytes from the view onto the stack.
  ///
  /// Returns a bytes32 with only the `_bytes` highest bytes set.
  /// This can be immediately cast to a smaller fixed-length byte array.
  /// To automatically cast to an integer, use `indexUint` or `indexInt`.
  function index(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (bytes32 result) {
    if (_bytes == 0) {
      return bytes32(0);
    }
    if (_index.add(_bytes) > len(memView)) {
      revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
    }
    require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

    uint8 bitLength = _bytes * 8;
    uint256 _loc = loc(memView);
    uint256 _mask = leftMask(bitLength);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      result := and(mload(add(_loc, _index)), _mask)
    }
  }

  /// Parse an unsigned integer from the view at `_index`. Requires that the
  /// view have >= `_bytes` bytes following that index.
  function indexUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /// Parse an unsigned integer from LE bytes.
  function indexLEUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return reverseUint256(uint256(index(memView, _index, _bytes)));
  }

  /// Parse a signed integer from the view at `_index`. Requires that the
  /// view have >= `_bytes` bytes following that index.
  function indexInt(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (int256 result) {
    return int256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /// Parse an address from the view at `_index`. Requires that the view have >= 20 bytes following that index.
  function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
    return address(uint160(indexInt(memView, _index, 20)));
  }

  /// Return the keccak256 hash of the underlying memory
  function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      digest := keccak256(_loc, _len)
    }
  }

  /// Return the sha2 digest of the underlying memory. We explicitly deallocate memory afterwards
  function sha2(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      digest := mload(ptr)
    }
  }

  /// @notice          Implements bitcoin's hash160 (rmd160(sha2()))
  /// @param memView   The pre-image
  /// @return digest   The digest
  function hash160(bytes29 memView) internal view returns (bytes20 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
      pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
      digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
    }
  }

  /// @notice          Implements bitcoin's hash256 (double sha2)
  /// @param memView   A view of the preimage
  /// @return digest   The digest
  function hash256(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
      digest := mload(ptr)
    }
  }

  /// Return true if the underlying memory is equal. Else false.
  function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
  }

  /// Return false if the underlying memory is equal. Else true.
  function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !untypedEqual(left, right);
  }

  /// Typed equality. Shortcuts if the pointers are identical, otherwise
  /// compares type and digest
  function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
    return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
  }

  /// Typed inequality. Shortcuts if the pointers are identical, otherwise
  /// compares type and digest
  function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !equal(left, right);
  }

  /// Copy the view to a location, return an unsafe memory reference
  ///
  /// Super Dangerous direct memory access.
  /// This reference can be overwritten if anything else modifies memory (!!!).
  /// As such it MUST be consumed IMMEDIATELY.
  /// This function is private to prevent unsafe usage by callers
  function copyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
    require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
    require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
    }

    written = buildUnchecked(typeOf(memView), _newLoc, _len);
  }

  /// Copies the referenced memory to a new loc in memory, returning a
  /// `bytes` pointing to the new memory
  function clone(bytes29 memView) internal view returns (bytes memory ret) {
    uint256 ptr;
    uint256 _len = len(memView);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
      ret := ptr
    }
    copyTo(memView, ptr + 0x20);
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
      mstore(ptr, _len) // write len of new array (in bytes)
    }
  }

  /// Join the views in memory, return an unsafe reference to the memory.
  ///
  /// Super Dangerous direct memory access.
  /// This reference can be overwritten if anything else modifies memory (!!!).
  /// As such it MUST be consumed IMMEDIATELY.
  /// This function is private to prevent unsafe usage by callers
  function unsafeJoin(bytes29[] memory memViews, uint256 _location)
    private
    view
    returns (bytes29 unsafeView)
  {
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      let ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _location) {
        revert(0x60, 0x20) // empty revert message
      }
    }

    uint256 _offset = 0;
    for (uint256 i = 0; i < memViews.length; i++) {
      bytes29 memView = memViews[i];
      copyTo(memView, _location + _offset);
      _offset += len(memView);
    }
    unsafeView = buildUnchecked(0, _location, _offset);
  }

  /// Produce the keccak256 digest of the concatenated contents of multiple views
  function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return keccak(unsafeJoin(memViews, ptr));
  }

  /// Produce the sha256 digest of the concatenated contents of multiple views
  function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return sha2(unsafeJoin(memViews, ptr));
  }

  /// copies all views, joins them into a new bytearray
  function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
    uint256 ptr;
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }

    bytes29 _newView = unsafeJoin(memViews, ptr + 0x20);
    uint256 _written = len(_newView);
    uint256 _footprint = footprint(_newView);

    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      // store the legnth
      mstore(ptr, _written)
      // new pointer is old + 0x20 + the footprint of the body
      mstore(0x40, add(add(ptr, _footprint), 0x20))
      ret := ptr
    }
  }
}

pragma solidity 0.6.6;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */

import {TypedMemView} from "./TypedMemView.sol";
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

library ViewBTC {
  using TypedMemView for bytes29;
  using SafeMath for uint256;

  // The target at minimum Difficulty. Also the target of the genesis block
  uint256 public constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

  uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60; // 2 weeks in seconds
  uint256 public constant RETARGET_PERIOD_BLOCKS = 2016; // 2 weeks in blocks

  enum BTCTypes {
    Unknown, // 0x0
    CompactInt, // 0x1
    ScriptSig, // 0x2 - with length prefix
    Outpoint, // 0x3
    TxIn, // 0x4
    IntermediateTxIns, // 0x5 - used in vin parsing
    Vin, // 0x6
    ScriptPubkey, // 0x7 - with length prefix
    PKH, // 0x8 - the 20-byte payload digest
    WPKH, // 0x9 - the 20-byte payload digest
    WSH, // 0xa - the 32-byte payload digest
    SH, // 0xb - the 20-byte payload digest
    OpReturnPayload, // 0xc
    TxOut, // 0xd
    IntermediateTxOuts, // 0xe - used in vout parsing
    Vout, // 0xf
    Header, // 0x10
    HeaderArray, // 0x11
    MerkleNode, // 0x12
    MerkleStep, // 0x13
    MerkleArray // 0x14
  }

  // TODO: any way to bubble up more info?
  /// @notice             requires `memView` to be of a specified type
  /// @param memView      a 29-byte view with a 5-byte type
  /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
  /// @return             passes if it is the correct type, errors if not
  modifier typeAssert(bytes29 memView, BTCTypes t) {
    memView.assertType(uint40(t));
    _;
  }

  /// Revert with an error message re: non-minimal VarInts
  function revertNonMinimal(bytes29 ref) private pure returns (string memory) {
    (, uint256 g) = TypedMemView.encodeHex(ref.indexUint(0, uint8(ref.len())));
    string memory err = string(abi.encodePacked("Non-minimal var int. Got 0x", uint144(g)));
    revert(err);
  }

  /// @notice             reads a compact int from the view at the specified index
  /// @param memView      a 29-byte view with a 5-byte type
  /// @param _index       the index
  /// @return number      the compact int at the specified index
  function indexCompactInt(bytes29 memView, uint256 _index) internal pure returns (uint64 number) {
    uint256 flag = memView.indexUint(_index, 1);
    if (flag <= 0xfc) {
      return uint64(flag);
    } else if (flag == 0xfd) {
      number = uint64(memView.indexLEUint(_index + 1, 2));
      if (compactIntLength(number) != 3) {
        revertNonMinimal(memView.slice(_index, 3, 0));
      }
    } else if (flag == 0xfe) {
      number = uint64(memView.indexLEUint(_index + 1, 4));
      if (compactIntLength(number) != 5) {
        revertNonMinimal(memView.slice(_index, 5, 0));
      }
    } else if (flag == 0xff) {
      number = uint64(memView.indexLEUint(_index + 1, 8));
      if (compactIntLength(number) != 9) {
        revertNonMinimal(memView.slice(_index, 9, 0));
      }
    }
  }

  /// @notice         gives the total length (in bytes) of a CompactInt-encoded number
  /// @param number   the number as uint64
  /// @return         the compact integer as uint8
  function compactIntLength(uint64 number) internal pure returns (uint8) {
    if (number <= 0xfc) {
      return 1;
    } else if (number <= 0xffff) {
      return 3;
    } else if (number <= 0xffffffff) {
      return 5;
    } else {
      return 9;
    }
  }

  /// @notice             extracts the LE txid from an outpoint
  /// @param _outpoint    the outpoint
  /// @return             the LE txid
  function txidLE(bytes29 _outpoint)
    internal
    pure
    typeAssert(_outpoint, BTCTypes.Outpoint)
    returns (bytes32)
  {
    return _outpoint.index(0, 32);
  }

  /// @notice             extracts the index as an integer from the outpoint
  /// @param _outpoint    the outpoint
  /// @return             the index
  function outpointIdx(bytes29 _outpoint)
    internal
    pure
    typeAssert(_outpoint, BTCTypes.Outpoint)
    returns (uint32)
  {
    return uint32(_outpoint.indexLEUint(32, 4));
  }

  /// @notice          extracts the outpoint from an input
  /// @param _input    the input
  /// @return          the outpoint as a typed memory
  function outpoint(bytes29 _input)
    internal
    pure
    typeAssert(_input, BTCTypes.TxIn)
    returns (bytes29)
  {
    return _input.slice(0, 36, uint40(BTCTypes.Outpoint));
  }

  /// @notice           extracts the script sig from an input
  /// @param _input     the input
  /// @return           the script sig as a typed memory
  function scriptSig(bytes29 _input)
    internal
    pure
    typeAssert(_input, BTCTypes.TxIn)
    returns (bytes29)
  {
    uint64 scriptLength = indexCompactInt(_input, 36);
    return
      _input.slice(36, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptSig));
  }

  /// @notice         extracts the sequence from an input
  /// @param _input   the input
  /// @return         the sequence
  function sequence(bytes29 _input)
    internal
    pure
    typeAssert(_input, BTCTypes.TxIn)
    returns (uint32)
  {
    uint64 scriptLength = indexCompactInt(_input, 36);
    uint256 scriptEnd = 36 + compactIntLength(scriptLength) + scriptLength;
    return uint32(_input.indexLEUint(scriptEnd, 4));
  }

  /// @notice         determines the length of the first input in an array of inputs
  /// @param _inputs  the vin without its length prefix
  /// @return         the input length
  function inputLength(bytes29 _inputs)
    internal
    pure
    typeAssert(_inputs, BTCTypes.IntermediateTxIns)
    returns (uint256)
  {
    uint64 scriptLength = indexCompactInt(_inputs, 36);
    return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 36 + 4;
  }

  /// @notice         extracts the input at a specified index
  /// @param _vin     the vin
  /// @param _index   the index of the desired input
  /// @return         the desired input
  function indexVin(bytes29 _vin, uint256 _index)
    internal
    pure
    typeAssert(_vin, BTCTypes.Vin)
    returns (bytes29)
  {
    uint256 _nIns = uint256(indexCompactInt(_vin, 0));
    uint256 _viewLen = _vin.len();
    require(_index < _nIns, "Vin read overrun");

    uint256 _offset = uint256(compactIntLength(uint64(_nIns)));
    bytes29 _remaining;
    for (uint256 _i = 0; _i < _index; _i += 1) {
      _remaining = _vin.postfix(_viewLen.sub(_offset), uint40(BTCTypes.IntermediateTxIns));
      _offset += inputLength(_remaining);
    }

    _remaining = _vin.postfix(_viewLen.sub(_offset), uint40(BTCTypes.IntermediateTxIns));
    uint256 _len = inputLength(_remaining);
    return _vin.slice(_offset, _len, uint40(BTCTypes.TxIn));
  }

  /// @notice         extracts the raw LE bytes of the output value
  /// @param _output  the output
  /// @return         the raw LE bytes of the output value
  function valueBytes(bytes29 _output)
    internal
    pure
    typeAssert(_output, BTCTypes.TxOut)
    returns (bytes8)
  {
    return bytes8(_output.index(0, 8));
  }

  /// @notice         extracts the value from an output
  /// @param _output  the output
  /// @return         the value
  function value(bytes29 _output)
    internal
    pure
    typeAssert(_output, BTCTypes.TxOut)
    returns (uint64)
  {
    return uint64(_output.indexLEUint(0, 8));
  }

  /// @notice             extracts the scriptPubkey from an output
  /// @param _output      the output
  /// @return             the scriptPubkey
  function scriptPubkey(bytes29 _output)
    internal
    pure
    typeAssert(_output, BTCTypes.TxOut)
    returns (bytes29)
  {
    uint64 scriptLength = indexCompactInt(_output, 8);
    return
      _output.slice(
        8,
        compactIntLength(scriptLength) + scriptLength,
        uint40(BTCTypes.ScriptPubkey)
      );
  }

  /// @notice             determines the length of the first output in an array of outputs
  /// @param _outputs     the vout without its length prefix
  /// @return             the output length
  function outputLength(bytes29 _outputs)
    internal
    pure
    typeAssert(_outputs, BTCTypes.IntermediateTxOuts)
    returns (uint256)
  {
    uint64 scriptLength = indexCompactInt(_outputs, 8);
    return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 8;
  }

  /// @notice         extracts the output at a specified index
  /// @param _vout    the vout
  /// @param _index   the index of the desired output
  /// @return         the desired output
  function indexVout(bytes29 _vout, uint256 _index)
    internal
    pure
    typeAssert(_vout, BTCTypes.Vout)
    returns (bytes29)
  {
    uint256 _nOuts = uint256(indexCompactInt(_vout, 0));
    uint256 _viewLen = _vout.len();
    require(_index < _nOuts, "Vout read overrun");

    uint256 _offset = uint256(compactIntLength(uint64(_nOuts)));
    bytes29 _remaining;
    for (uint256 _i = 0; _i < _index; _i += 1) {
      _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
      _offset += outputLength(_remaining);
    }

    _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
    uint256 _len = outputLength(_remaining);
    return _vout.slice(_offset, _len, uint40(BTCTypes.TxOut));
  }

  /// @notice         extracts the Op Return Payload
  /// @param _spk     the scriptPubkey
  /// @return         the Op Return Payload (or null if not a valid Op Return output)
  function opReturnPayload(bytes29 _spk)
    internal
    pure
    typeAssert(_spk, BTCTypes.ScriptPubkey)
    returns (bytes29)
  {
    uint64 _bodyLength = indexCompactInt(_spk, 0);
    uint64 _payloadLen = uint64(_spk.indexUint(2, 1));
    if (
      _bodyLength > 77 ||
      _bodyLength < 4 ||
      _spk.indexUint(1, 1) != 0x6a ||
      _spk.indexUint(2, 1) != _bodyLength - 2
    ) {
      return TypedMemView.nullView();
    }
    return _spk.slice(3, _payloadLen, uint40(BTCTypes.OpReturnPayload));
  }

  /// @notice         extracts the payload from a scriptPubkey
  /// @param _spk     the scriptPubkey
  /// @return         the payload (or null if not a valid PKH, SH, WPKH, or WSH output)
  function payload(bytes29 _spk)
    internal
    pure
    typeAssert(_spk, BTCTypes.ScriptPubkey)
    returns (bytes29)
  {
    uint256 _spkLength = _spk.len();
    uint256 _bodyLength = indexCompactInt(_spk, 0);
    if (_bodyLength > 0x22 || _bodyLength < 0x16 || _bodyLength + 1 != _spkLength) {
      return TypedMemView.nullView();
    }

    // Legacy
    if (
      _bodyLength == 0x19 &&
      _spk.indexUint(0, 4) == 0x1976a914 &&
      _spk.indexUint(_spkLength - 2, 2) == 0x88ac
    ) {
      return _spk.slice(4, 20, uint40(BTCTypes.PKH));
    } else if (
      _bodyLength == 0x17 &&
      _spk.indexUint(0, 3) == 0x17a914 &&
      _spk.indexUint(_spkLength - 1, 1) == 0x87
    ) {
      return _spk.slice(3, 20, uint40(BTCTypes.SH));
    }

    // Witness v0
    if (_spk.indexUint(1, 1) == 0) {
      uint256 _payloadLen = _spk.indexUint(2, 1);
      if ((_bodyLength != 0x22 && _bodyLength != 0x16) || _payloadLen != _bodyLength - 2) {
        return TypedMemView.nullView();
      }
      uint40 newType = uint40(_payloadLen == 0x20 ? BTCTypes.WSH : BTCTypes.WPKH);
      return _spk.slice(3, _payloadLen, newType);
    }

    return TypedMemView.nullView();
  }

  /// @notice     (loosely) verifies an spk and converts to a typed memory
  /// @dev        will return null in error cases. Will not check for disabled opcodes.
  /// @param _spk the spk
  /// @return     the typed spk (or null if error)
  function tryAsSPK(bytes29 _spk)
    internal
    pure
    typeAssert(_spk, BTCTypes.Unknown)
    returns (bytes29)
  {
    if (_spk.len() == 0) {
      return TypedMemView.nullView();
    }
    uint64 _len = indexCompactInt(_spk, 0);
    if (_spk.len() == compactIntLength(_len) + _len) {
      return _spk.castTo(uint40(BTCTypes.ScriptPubkey));
    } else {
      return TypedMemView.nullView();
    }
  }

  /// @notice     verifies the vin and converts to a typed memory
  /// @dev        will return null in error cases
  /// @param _vin the vin
  /// @return     the typed vin (or null if error)
  function tryAsVin(bytes29 _vin)
    internal
    pure
    typeAssert(_vin, BTCTypes.Unknown)
    returns (bytes29)
  {
    if (_vin.len() == 0) {
      return TypedMemView.nullView();
    }
    uint64 _nIns = indexCompactInt(_vin, 0);
    uint256 _viewLen = _vin.len();
    if (_nIns == 0) {
      return TypedMemView.nullView();
    }

    uint256 _offset = uint256(compactIntLength(_nIns));
    for (uint256 i = 0; i < _nIns; i++) {
      if (_offset >= _viewLen) {
        // We've reached the end, but are still trying to read more
        return TypedMemView.nullView();
      }
      bytes29 _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
      _offset += inputLength(_remaining);
    }
    if (_offset != _viewLen) {
      return TypedMemView.nullView();
    }
    return _vin.castTo(uint40(BTCTypes.Vin));
  }

  /// @notice         verifies the vout and converts to a typed memory
  /// @dev            will return null in error cases
  /// @param _vout    the vout
  /// @return         the typed vout (or null if error)
  function tryAsVout(bytes29 _vout)
    internal
    pure
    typeAssert(_vout, BTCTypes.Unknown)
    returns (bytes29)
  {
    if (_vout.len() == 0) {
      return TypedMemView.nullView();
    }
    uint64 _nOuts = indexCompactInt(_vout, 0);
    uint256 _viewLen = _vout.len();
    if (_nOuts == 0) {
      return TypedMemView.nullView();
    }

    uint256 _offset = uint256(compactIntLength(_nOuts));
    for (uint256 i = 0; i < _nOuts; i++) {
      if (_offset >= _viewLen) {
        // We've reached the end, but are still trying to read more
        return TypedMemView.nullView();
      }
      bytes29 _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
      _offset += outputLength(_remaining);
    }
    if (_offset != _viewLen) {
      return TypedMemView.nullView();
    }
    return _vout.castTo(uint40(BTCTypes.Vout));
  }

  /// @notice         verifies the header and converts to a typed memory
  /// @dev            will return null in error cases
  /// @param _header  the header
  /// @return         the typed header (or null if error)
  function tryAsHeader(bytes29 _header)
    internal
    pure
    typeAssert(_header, BTCTypes.Unknown)
    returns (bytes29)
  {
    if (_header.len() != 80) {
      return TypedMemView.nullView();
    }
    return _header.castTo(uint40(BTCTypes.Header));
  }

  /// @notice         Index a header array.
  /// @dev            Errors on overruns
  /// @param _arr     The header array
  /// @param index    The 0-indexed location of the header to get
  /// @return         the typed header at `index`
  function indexHeaderArray(bytes29 _arr, uint256 index)
    internal
    pure
    typeAssert(_arr, BTCTypes.HeaderArray)
    returns (bytes29)
  {
    uint256 _start = index.mul(80);
    return _arr.slice(_start, 80, uint40(BTCTypes.Header));
  }

  /// @notice     verifies the header array and converts to a typed memory
  /// @dev        will return null in error cases
  /// @param _arr the header array
  /// @return     the typed header array (or null if error)
  function tryAsHeaderArray(bytes29 _arr)
    internal
    pure
    typeAssert(_arr, BTCTypes.Unknown)
    returns (bytes29)
  {
    if (_arr.len() % 80 != 0) {
      return TypedMemView.nullView();
    }
    return _arr.castTo(uint40(BTCTypes.HeaderArray));
  }

  /// @notice     verifies the merkle array and converts to a typed memory
  /// @dev        will return null in error cases
  /// @param _arr the merkle array
  /// @return     the typed merkle array (or null if error)
  function tryAsMerkleArray(bytes29 _arr)
    internal
    pure
    typeAssert(_arr, BTCTypes.Unknown)
    returns (bytes29)
  {
    if (_arr.len() % 32 != 0) {
      return TypedMemView.nullView();
    }
    return _arr.castTo(uint40(BTCTypes.MerkleArray));
  }

  /// @notice         extracts the merkle root from the header
  /// @param _header  the header
  /// @return         the merkle root
  function merkleRoot(bytes29 _header)
    internal
    pure
    typeAssert(_header, BTCTypes.Header)
    returns (bytes32)
  {
    return _header.index(36, 32);
  }

  /// @notice         extracts the target from the header
  /// @param _header  the header
  /// @return         the target
  function target(bytes29 _header)
    internal
    pure
    typeAssert(_header, BTCTypes.Header)
    returns (uint256)
  {
    uint256 _mantissa = _header.indexLEUint(72, 3);
    uint256 _exponent = _header.indexUint(75, 1).sub(3);
    return _mantissa.mul(256**_exponent);
  }

  /// @notice         calculates the difficulty from a target
  /// @param _target  the target
  /// @return         the difficulty
  function toDiff(uint256 _target) internal pure returns (uint256) {
    return DIFF1_TARGET.div(_target);
  }

  /// @notice         extracts the difficulty from the header
  /// @param _header  the header
  /// @return         the difficulty
  function diff(bytes29 _header)
    internal
    pure
    typeAssert(_header, BTCTypes.Header)
    returns (uint256)
  {
    return toDiff(target(_header));
  }

  /// @notice         extracts the timestamp from the header
  /// @param _header  the header
  /// @return         the timestamp
  function time(bytes29 _header)
    internal
    pure
    typeAssert(_header, BTCTypes.Header)
    returns (uint32)
  {
    return uint32(_header.indexLEUint(68, 4));
  }

  /// @notice         extracts the parent hash from the header
  /// @param _header  the header
  /// @return         the parent hash
  function parent(bytes29 _header)
    internal
    pure
    typeAssert(_header, BTCTypes.Header)
    returns (bytes32)
  {
    return _header.index(4, 32);
  }

  /// @notice         calculates the Proof of Work hash of the header
  /// @param _header  the header
  /// @return         the Proof of Work hash
  function workHash(bytes29 _header)
    internal
    view
    typeAssert(_header, BTCTypes.Header)
    returns (bytes32)
  {
    return _header.hash256();
  }

  /// @notice         calculates the Proof of Work hash of the header, and converts to an integer
  /// @param _header  the header
  /// @return         the Proof of Work hash as an integer
  function work(bytes29 _header)
    internal
    view
    typeAssert(_header, BTCTypes.Header)
    returns (uint256)
  {
    return TypedMemView.reverseUint256(uint256(workHash(_header)));
  }

  /// @notice          Concatenates and hashes two inputs for merkle proving
  /// @dev             Not recommended to call directly.
  /// @param _a        The first hash
  /// @param _b        The second hash
  /// @return digest   The double-sha256 of the concatenated hashes
  function _merkleStep(bytes32 _a, bytes32 _b) internal view returns (bytes32 digest) {
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      let ptr := mload(0x40)
      mstore(ptr, _a)
      mstore(add(ptr, 0x20), _b)
      pop(staticcall(gas(), 2, ptr, 0x40, ptr, 0x20)) // sha2 #1
      pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
      digest := mload(ptr)
    }
  }

  /// @notice         verifies a merkle proof
  /// @param _leaf    the leaf
  /// @param _proof   the merkle proof
  /// @param _root    the merkle root
  /// @param _index   the index
  /// @return         true if valid, false if otherwise
  function checkMerkle(
    bytes32 _leaf,
    bytes29 _proof,
    bytes32 _root,
    uint256 _index
  ) internal view typeAssert(_proof, BTCTypes.MerkleArray) returns (bool) {
    uint256 nodes = _proof.len() / 32;
    if (nodes == 0) {
      return _leaf == _root;
    }

    uint256 _idx = _index;
    bytes32 _current = _leaf;

    for (uint256 i = 0; i < nodes; i++) {
      bytes32 _next = _proof.index(i * 32, 32);
      if (_idx % 2 == 1) {
        _current = _merkleStep(_next, _current);
      } else {
        _current = _merkleStep(_current, _next);
      }
      _idx >>= 1;
    }

    return _current == _root;
  }

  /// @notice                 performs the bitcoin difficulty retarget
  /// @dev                    implements the Bitcoin algorithm precisely
  /// @param _previousTarget  the target of the previous period
  /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
  /// @param _secondTimestamp the timestamp of the last block in the difficulty period
  /// @return                 the new period's target threshold
  function retargetAlgorithm(
    uint256 _previousTarget,
    uint256 _firstTimestamp,
    uint256 _secondTimestamp
  ) internal pure returns (uint256) {
    uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

    // Normalize ratio to factor of 4 if very long or very short
    if (_elapsedTime < RETARGET_PERIOD.div(4)) {
      _elapsedTime = RETARGET_PERIOD.div(4);
    }
    if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
      _elapsedTime = RETARGET_PERIOD.mul(4);
    }

    /*
            NB: high targets e.g. ffff0020 can cause overflows here
                so we divide it by 256**2, then multiply by 256**2 later
                we know the target is evenly divisible by 256**2, so this isn't an issue
        */
    uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
    return _adjusted.div(RETARGET_PERIOD).mul(65536);
  }
}

pragma solidity 0.6.6;

/** @title ViewSPV */
/** @author Summa (https://summa.one) */

import {TypedMemView} from "./TypedMemView.sol";
import {ViewBTC} from "./ViewBTC.sol";
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

library ViewSPV {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ViewBTC for bytes29;
  using SafeMath for uint256;

  uint256 constant ERR_BAD_LENGTH =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint256 constant ERR_INVALID_CHAIN =
    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
  uint256 constant ERR_LOW_WORK =
    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

  function getErrBadLength() internal pure returns (uint256) {
    return ERR_BAD_LENGTH;
  }

  function getErrInvalidChain() internal pure returns (uint256) {
    return ERR_INVALID_CHAIN;
  }

  function getErrLowWork() internal pure returns (uint256) {
    return ERR_LOW_WORK;
  }

  /// @notice             requires `memView` to be of a specified type
  /// @param memView      a 29-byte view with a 5-byte type
  /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
  /// @return             passes if it is the correct type, errors if not
  modifier typeAssert(bytes29 memView, ViewBTC.BTCTypes t) {
    memView.assertType(uint40(t));
    _;
  }

  /// @notice                     Validates a tx inclusion in the block
  /// @dev                        `index` is not a reliable indicator of location within a block
  /// @param _txid                The txid (LE)
  /// @param _merkleRoot          The merkle root (as in the block header)
  /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
  /// @param _index               The leaf's index in the tree (0-indexed)
  /// @return                     true if fully valid, false otherwise
  function prove(
    bytes32 _txid,
    bytes32 _merkleRoot,
    bytes29 _intermediateNodes,
    uint256 _index
  ) internal view typeAssert(_intermediateNodes, ViewBTC.BTCTypes.MerkleArray) returns (bool) {
    // Shortcut the empty-block case
    if (_txid == _merkleRoot && _index == 0 && _intermediateNodes.len() == 0) {
      return true;
    }

    return ViewBTC.checkMerkle(_txid, _intermediateNodes, _merkleRoot, _index);
  }

  /// @notice             Hashes transaction to get txid
  /// @dev                Supports Legacy and Witness
  /// @param _version     4-bytes version
  /// @param _vin         Raw bytes length-prefixed input vector
  /// @param _vout        Raw bytes length-prefixed output vector
  /// @param _locktime    4-byte tx locktime
  /// @return             32-byte transaction id, little endian
  function calculateTxId(
    bytes4 _version,
    bytes29 _vin,
    bytes29 _vout,
    bytes4 _locktime
  )
    internal
    view
    typeAssert(_vin, ViewBTC.BTCTypes.Vin)
    typeAssert(_vout, ViewBTC.BTCTypes.Vout)
    returns (bytes32)
  {
    // TODO: write in assembly
    return abi.encodePacked(_version, _vin.clone(), _vout.clone(), _locktime).ref(0).hash256();
  }

  // TODO: add test for checkWork
  /// @notice             Checks validity of header work
  /// @param _header      Header view
  /// @param _target      The target threshold
  /// @return             true if header work is valid, false otherwise
  function checkWork(bytes29 _header, uint256 _target)
    internal
    view
    typeAssert(_header, ViewBTC.BTCTypes.Header)
    returns (bool)
  {
    return _header.work() < _target;
  }

  /// @notice                     Checks validity of header chain
  /// @dev                        Compares current header parent to previous header's digest
  /// @param _header              The raw bytes header
  /// @param _prevHeaderDigest    The previous header's digest
  /// @return                     true if the connect is valid, false otherwise
  function checkParent(bytes29 _header, bytes32 _prevHeaderDigest)
    internal
    pure
    typeAssert(_header, ViewBTC.BTCTypes.Header)
    returns (bool)
  {
    return _header.parent() == _prevHeaderDigest;
  }

  /// @notice                     Checks validity of header chain
  /// @notice                     Compares the hash of each header to the prevHash in the next header
  /// @param _headers             Raw byte array of header chain
  /// @return _totalDifficulty    The total accumulated difficulty of the header chain, or an error code
  function checkChain(bytes29 _headers)
    internal
    view
    typeAssert(_headers, ViewBTC.BTCTypes.HeaderArray)
    returns (uint256 _totalDifficulty)
  {
    bytes32 _digest;
    uint256 _headerCount = _headers.len() / 80;
    for (uint256 i = 0; i < _headerCount; i += 1) {
      bytes29 _header = _headers.indexHeaderArray(i);
      if (i != 0) {
        if (!checkParent(_header, _digest)) {
          return ERR_INVALID_CHAIN;
        }
      }
      _digest = _header.workHash();
      uint256 _work = TypedMemView.reverseUint256(uint256(_digest));
      uint256 _target = _header.target();

      if (_work > _target) {
        return ERR_LOW_WORK;
      }

      _totalDifficulty += ViewBTC.toDiff(_target);
    }
  }
}

// SPDX-License-Identifier: MPL

pragma solidity 0.6.6;

/** @title IRelay */

interface IRelay {
  event Extension(bytes32 indexed _first, bytes32 indexed _last);
  event NewTip(bytes32 indexed _from, bytes32 indexed _to, bytes32 indexed _gcd);

  /// @notice     Getter for bestKnownDigest
  /// @dev        This updated only by calling markNewHeaviest
  /// @return     The hash of the best marked chain tip
  function getBestKnownDigest() external view returns (bytes32);

  /// @notice     Getter for relayGenesis
  /// @dev        This is updated only by calling markNewHeaviest
  /// @return     The hash of the shared ancestor of the most recent fork
  function getLastReorgCommonAncestor() external view returns (bytes32);

  /// @notice         Finds the height of a header by its digest
  /// @dev            Will fail if the header is unknown
  /// @param _digest  The header digest to search for
  /// @return         The height of the header, or error if unknown
  function findHeight(bytes32 _digest) external view returns (uint256);

  /// @notice             Checks if a digest is an ancestor of the current one
  /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
  /// @param _ancestor    The prospective ancestor
  /// @param _descendant  The descendant to check
  /// @param _limit       The maximum number of blocks to check
  /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
  function isAncestor(
    bytes32 _ancestor,
    bytes32 _descendant,
    uint256 _limit
  ) external view returns (bool);

  function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

  function addHeadersWithRetarget(
    bytes calldata _oldPeriodStartHeader,
    bytes calldata _oldPeriodEndHeader,
    bytes calldata _headers
  ) external returns (bool);

  function markNewHeaviest(
    bytes32 _ancestor,
    bytes calldata _currentBest,
    bytes calldata _newBest,
    uint256 _limit
  ) external returns (bool);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./IBorrower.sol";
import "./ILender.sol";

// inspired by https://github.com/Austin-Williams/flash-mintable-tokens/blob/master/FlashERC20/FlashERC20.sol
contract FlashERC20 is
  Initializable,
  ContextUpgradeSafe,
  ERC20UpgradeSafe,
  ILender,
  OwnableUpgradeSafe
{
  uint256 constant BTC_CAP = 21 * 10**24;
  uint256 constant FEE_FACTOR = 100;

  // used for reentrance guard
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  event FlashMint(address indexed src, uint256 wad, bytes32 data, uint256 fee);

  // working memory
  uint256 private _status;
  // Dev fund
  uint256 public devFundDivRate;

  function __Flash_init(string memory name, string memory symbol) internal initializer {
    devFundDivRate = 17;
    _status = _NOT_ENTERED;
    __ERC20_init(name, symbol);
    __Ownable_init();
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `_lock_` function from another `_lock_`
   * function is not supported. It is possible to prevent this from happening
   * by making the `_lock_` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier lock() {
    // On the first call to _lock_, _notEntered will be true
    require(_status != _ENTERED, "ERR_REENTRY");

    // Any calls to _lock_ after this point will fail
    _status = _ENTERED;
    _;
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  // Allows anyone to mint tokens as long as it gets burned by the end of the transaction.
  function flashMint(uint256 amount, bytes32 data) external override lock {
    // do not exceed cap
    require(totalSupply().add(amount) <= BTC_CAP, "can not borrow more than BTC cap");

    // mint tokens
    _mint(msg.sender, amount);

    // hand control to borrower
    IBorrower(msg.sender).executeOnFlashMint(amount, data);

    uint256 fee = amount.div(devFundDivRate.mul(FEE_FACTOR));

    // burn tokens
    _burn(msg.sender, amount.add(fee)); // reverts if `msg.sender` does not have enough
    _mint(owner(), fee);

    emit FlashMint(msg.sender, amount, data, fee);
  }

  // governance function
  function setDevFundDivRate(uint256 _devFundDivRate) external onlyOwner {
    require(_devFundDivRate > 0, "!devFundDivRate-0");
    devFundDivRate = _devFundDivRate;
  }
}

pragma solidity 0.6.6;

interface IBorrower {
  function executeOnFlashMint(uint256 amount, bytes32 data) external;
}

pragma solidity 0.6.6;

contract ILender {
  function flashMint(uint256 amount, bytes32 data) external virtual {}
}

pragma solidity 0.6.6;

import {FlashERC20} from "../FlashERC20.sol";

contract MockFlashERC20 is FlashERC20 {
  bytes32 public DOMAIN_SEPARATOR;

  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  mapping(address => uint256) public nonces;

  constructor(
    string memory name,
    string memory symbol,
    uint256 supply
  ) public {
    _mint(msg.sender, supply);
    __Flash_init(name, symbol);
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("Strudel BTC")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  function deposit() public payable {
    _mint(msg.sender, msg.value);
  }

  event Data(bytes);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "vBTC: EXPIRED");
    bytes memory msg =
      abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline);
    emit Data(msg);
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(msg)));
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "VBTC: INVALID_SIGNATURE");
    _approve(owner, spender, value);
  }
}

pragma solidity 0.6.6;

import "../IBorrower.sol";
import "../ILender.sol";

contract MockBorrower is IBorrower {
  address lender;
  bool reentrance;

  constructor(address _lender) public {
    lender = _lender;
  }

  event Data(uint256 amount, bytes32 data);

  function executeOnFlashMint(uint256 amount, bytes32 data) external override {
    emit Data(amount, data);
    if (reentrance) {
      ILender(lender).flashMint(amount, data);
    }
  }

  function flashMint(
    uint256 amount,
    bytes32 data,
    bool _reentrance
  ) external {
    reentrance = _reentrance;
    ILender(lender).flashMint(amount, data);
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./StrudelToken.sol";

// The torchship has brought them to Ganymede, where they have to pulverize boulders and lava flows, and seed the resulting dust with carefully formulated organic material.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once STRDLS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract TorchShip is Initializable, ContextUpgradeSafe, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Events
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of STRDLs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accStrudelPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accStrudelPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. STRDLs to distribute per block.
    uint256 lastRewardBlock; // Last block number that STRDLs distribution occurs.
    uint256 accStrudelPerShare; // Accumulated STRDLs per share, times 1e12. See below.
  }

  // immutable
  StrudelToken private strudel;

  // governance params
  // Dev fund
  uint256 public devFundDivRate;
  // last time when total supply of reference token observed
  // formerly bonusEndBlock: Block number when bonus STRDL period ends.
  uint256 public lastBlockHeight;
  // STRDL tokens created per block.
  uint256 public strudelPerBlock;
  // the window size for variance calculation
  // formerly bonusMultiplier: Bonus muliplier for early strudel makers.
  uint256 public windowSize;
  // The block number when STRDL mining starts.
  uint256 public startBlock;

  // working memory
  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  // new since farming 2.0
  address private referenceToken;
  // the number of observations stored during the window
  // immutable
  uint8 public granularity;
  // list of observations as ringbuffer
  uint256[] public observations;
  // position
  uint8 public latestPos;

  function initialize(
    address _strudel,
    uint256 _strudelPerBlock,
    uint256 _startBlock,
    uint256 _lastBlockHeight,
    uint256 _windowSize
  ) public initializer {
    __Ownable_init();
    strudel = StrudelToken(_strudel);
    require(_strudelPerBlock >= 10**15, "forgot the decimals for $TRDL?");
    strudelPerBlock = _strudelPerBlock;
    lastBlockHeight = _lastBlockHeight;
    startBlock = _startBlock;
    windowSize = _windowSize;
    totalAllocPoint = 0;
    devFundDivRate = 17;
  }

  // Safe strudel transfer function, just in case if rounding error causes pool to not have enough STRDLs.
  function safeStrudelTransfer(address _to, uint256 _amount) internal {
    uint256 strudelBal = strudel.balanceOf(address(this));
    if (_amount > strudelBal) {
      strudel.transfer(_to, strudelBal);
    } else {
      strudel.transfer(_to, _amount);
    }
  }

  // update the totalSupply for the observation at the current timestamp. each observation is updated at most
  // once per epoch period.
  function updateVariance() public {
    if (referenceToken == address(0)) {
      return;
    }

    uint256 currentTotal = IERC20(referenceToken).totalSupply();

    // populate the array with empty observations (first call only)
    for (uint256 i = observations.length; i < granularity; i++) {
      observations.push(currentTotal);
    }

    if (block.number.sub(lastBlockHeight) >= windowSize.div(granularity)) {
      uint8 nextPos = (latestPos >= granularity - 1) ? 0 : latestPos + 1;
      observations[nextPos] = currentTotal;
      lastBlockHeight = block.number;
      latestPos = nextPos;
    }
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    // fallback before not initialized
    if (referenceToken == address(0)) {
      if (_to <= lastBlockHeight) {
        return _to.sub(_from).mul(windowSize).mul(1e18);
      } else if (_from >= lastBlockHeight) {
        return _to.sub(_from).mul(1e18);
      } else {
        return lastBlockHeight.sub(_from).mul(windowSize).add(_to.sub(lastBlockHeight)).mul(1e18);
      }
    }

    uint256 average = 0;
    for (uint256 i = 0; i < granularity; i++) {
      average += observations[i];
    }
    average = average.div(granularity);
    uint256 latestSupply = observations[latestPos];

    // get the variance, normalize over supply
    uint256 variance = latestSupply.sub(average).mul(1e19).div(latestSupply).add(1e18);
    return _to.sub(_from).mul(variance);
  }

  // View function to see pending STRDLs on frontend.
  function pendingStrudel(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accStrudelPerShare = pool.accStrudelPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 strudelReward =
        multiplier.mul(strudelPerBlock).mul(pool.allocPoint).div(totalAllocPoint).div(1e18);
      accStrudelPerShare = accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    }
    return user.amount.mul(accStrudelPerShare).div(1e12).sub(user.rewardDebt);
  }

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 strudelReward =
      multiplier.mul(strudelPerBlock).mul(pool.allocPoint).div(totalAllocPoint).div(1e18);
    strudel.mint(owner(), strudelReward.div(devFundDivRate));
    strudel.mint(address(this), strudelReward);
    pool.accStrudelPerShare = pool.accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to TorchShip for STRDL allocation.
  function deposit(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updateVariance();
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
      safeStrudelTransfer(msg.sender, pending);
    }
    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw LP tokens from TorchShip.
  function withdraw(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updateVariance();
    updatePool(_pid);
    uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
    safeStrudelTransfer(msg.sender, pending);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // governance functions:

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accStrudelPerShare: 0
      })
    );
  }

  // Update the given pool's STRDL allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  function setDevFundDivRate(uint256 _devFundDivRate) external onlyOwner {
    require(_devFundDivRate > 0, "!devFundDivRate-0");
    devFundDivRate = _devFundDivRate;
  }

  function setStrudelPerBlock(uint256 _strudelPerBlock) external onlyOwner {
    require(_strudelPerBlock > 0, "!strudelPerBlock-0");
    strudelPerBlock = _strudelPerBlock;
  }

  function initVariance(
    address token_,
    uint256 windowSize_,
    uint8 granularity_
  ) external {
    require(referenceToken == address(0), "already initialized");
    require(granularity_ > 1, "TorchShip: GRANULARITY");
    require(windowSize_ % granularity_ == 0, "TorchShip: WINDOW_NOT_EVENLY_DIVISIBLE");
    massUpdatePools();
    referenceToken = token_;
    windowSize = windowSize_;
    granularity = granularity_;
    lastBlockHeight = block.number - (windowSize_ / granularity_);
    updateVariance();
  }
}

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "../StrudelToken.sol";

// The torchship has brought them to Ganymede, where they have to pulverize boulders and lava flows, and seed the resulting dust with carefully formulated organic material.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once STRDLS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract V1TorchShip is Initializable, ContextUpgradeSafe, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Events
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of STRDLs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accStrudelPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accStrudelPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. STRDLs to distribute per block.
    uint256 lastRewardBlock; // Last block number that STRDLs distribution occurs.
    uint256 accStrudelPerShare; // Accumulated STRDLs per share, times 1e12. See below.
  }

  // immutable
  StrudelToken private strudel;

  // governance params
  // Dev fund
  uint256 public devFundDivRate;
  // Block number when bonus STRDL period ends.
  uint256 public bonusEndBlock;
  // STRDL tokens created per block.
  uint256 public strudelPerBlock;
  // Bonus muliplier for early strudel makers.
  uint256 public bonusMultiplier;
  // The block number when STRDL mining starts.
  uint256 public startBlock;

  // working memory
  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  function initialize(
    address _strudel,
    uint256 _strudelPerBlock,
    uint256 _startBlock,
    uint256 _bonusEndBlock,
    uint256 _bonusMultiplier
  ) public initializer {
    __Ownable_init();
    strudel = StrudelToken(_strudel);
    require(_strudelPerBlock >= 10**15, "forgot the decimals for $TRDL?");
    strudelPerBlock = _strudelPerBlock;
    bonusEndBlock = _bonusEndBlock;
    startBlock = _startBlock;
    bonusMultiplier = _bonusMultiplier;
    totalAllocPoint = 0;
    devFundDivRate = 17;
  }

  // Safe strudel transfer function, just in case if rounding error causes pool to not have enough STRDLs.
  function safeStrudelTransfer(address _to, uint256 _amount) internal {
    uint256 strudelBal = strudel.balanceOf(address(this));
    if (_amount > strudelBal) {
      strudel.transfer(_to, strudelBal);
    } else {
      strudel.transfer(_to, _amount);
    }
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    if (_to <= bonusEndBlock) {
      return _to.sub(_from).mul(bonusMultiplier);
    } else if (_from >= bonusEndBlock) {
      return _to.sub(_from);
    } else {
      return bonusEndBlock.sub(_from).mul(bonusMultiplier).add(_to.sub(bonusEndBlock));
    }
  }

  // View function to see pending STRDLs on frontend.
  function pendingStrudel(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accStrudelPerShare = pool.accStrudelPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 strudelReward =
        multiplier.mul(strudelPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      accStrudelPerShare = accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    }
    return user.amount.mul(accStrudelPerShare).div(1e12).sub(user.rewardDebt);
  }

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 strudelReward =
      multiplier.mul(strudelPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    strudel.mint(owner(), strudelReward.div(devFundDivRate));
    strudel.mint(address(this), strudelReward);
    pool.accStrudelPerShare = pool.accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to TorchShip for STRDL allocation.
  function deposit(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
      safeStrudelTransfer(msg.sender, pending);
    }
    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw LP tokens from TorchShip.
  function withdraw(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updatePool(_pid);
    uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
    safeStrudelTransfer(msg.sender, pending);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // governance functions:

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accStrudelPerShare: 0
      })
    );
  }

  // Update the given pool's STRDL allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  function setDevFundDivRate(uint256 _devFundDivRate) public onlyOwner {
    require(_devFundDivRate > 0, "!devFundDivRate-0");
    devFundDivRate = _devFundDivRate;
  }

  function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
    bonusEndBlock = _bonusEndBlock;
  }

  function setStrudelPerBlock(uint256 _strudelPerBlock) public onlyOwner {
    require(_strudelPerBlock > 0, "!strudelPerBlock-0");
    strudelPerBlock = _strudelPerBlock;
  }

  function setBonusMultiplier(uint256 _bonusMultiplier) public onlyOwner {
    require(_bonusMultiplier > 0, "!bonusMultiplier-0");
    bonusMultiplier = _bonusMultiplier;
  }
}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Ctrl+f for XXX to see all the modifications.

// XXX: pragma solidity ^0.5.16;
pragma solidity 0.6.6;

// XXX: import "./SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract Timelock {
  using SafeMath for uint256;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  uint256 public constant GRACE_PERIOD = 14 days;
  uint256 public constant MINIMUM_DELAY = 1 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;
  bool public admin_initialized;

  mapping(bytes32 => bool) public queuedTransactions;

  constructor(address admin_, uint256 delay_) public {
    require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

    admin = admin_;
    delay = delay_;
    admin_initialized = false;
  }

  // XXX: function() external payable { }
  receive() external payable {}

  function setDelay(uint256 delay_) public {
    require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
    require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    // allows one time setting of admin for deployment purposes
    if (admin_initialized) {
      require(
        msg.sender == address(this),
        "Timelock::setPendingAdmin: Call must come from Timelock."
      );
    } else {
      require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
      admin_initialized = true;
    }
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public returns (bytes32) {
    require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
    require(
      eta >= getBlockTimestamp().add(delay),
      "Timelock::queueTransaction: Estimated execution block must satisfy delay."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public {
    require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public payable returns (bytes memory) {
    require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash],
      "Timelock::executeTransaction: Transaction hasn't been queued."
    );
    require(
      getBlockTimestamp() >= eta,
      "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
    );
    require(
      getBlockTimestamp() <= eta.add(GRACE_PERIOD),
      "Timelock::executeTransaction: Transaction is stale."
    );

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{value: value}(callData);
    require(success, "Timelock::executeTransaction: Transaction execution reverted.");

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "./erc20/ITokenRecipient.sol";
import "./erc20/MinterRole.sol";

interface IStrudel {
  function mint(address account, uint256 amount) external returns (bool);

  function burnFrom(address _account, uint256 _amount) external;

  function renounceMinter() external;
}

/// @title  Strudel Token.
/// @notice This is the Strudel ERC20 contract.
contract StrudelWrapper is ITokenRecipient, MinterRole {
  event LogSwapin(bytes32 indexed txhash, address indexed account, uint256 amount);
  event LogSwapout(address indexed account, address indexed bindaddr, uint256 amount);

  address public strdlAddr;

  constructor(address _strdlAddr) public {
    __Ownable_init();
    strdlAddr = _strdlAddr;
  }

  function mint(address to, uint256 amount) external onlyMinter returns (bool) {
    IStrudel(strdlAddr).mint(to, amount);
    return true;
  }

  function burn(address from, uint256 amount) external onlyMinter returns (bool) {
    require(from != address(0), "StrudelWrapper: address(0x0)");
    IStrudel(strdlAddr).burnFrom(from, amount);
    return true;
  }

  function Swapin(
    bytes32 txhash,
    address account,
    uint256 amount
  ) public onlyMinter returns (bool) {
    IStrudel(strdlAddr).mint(account, amount);
    emit LogSwapin(txhash, account, amount);
    return true;
  }

  function Swapout(uint256 amount, address bindaddr) public returns (bool) {
    require(bindaddr != address(0), "StrudelWrapper: address(0x0)");
    IStrudel(strdlAddr).burnFrom(msg.sender, amount);
    emit LogSwapout(msg.sender, bindaddr, amount);
    return true;
  }

  function getAddr(bytes memory _extraData) internal returns (address) {
    address addr;
    assembly {
      addr := mload(add(_extraData, 20))
    }
    return addr;
  }

  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes calldata _extraData
  ) external override {
    require(msg.sender == strdlAddr, "StrudelWrapper: onlyAuth");
    require(_token == strdlAddr, "StrudelWrapper: onlyAuth");
    address bindaddr = getAddr(_extraData);
    require(bindaddr != address(0), "StrudelWrapper: address(0x0)");
    IStrudel(strdlAddr).burnFrom(_from, _value);
    emit LogSwapout(_from, bindaddr, _value);
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./erc20/ITokenRecipient.sol";

/// @title  BCH Token.
/// @notice This is the Strudel ERC20 contract.
contract BchMainnetToken is ERC20, Ownable {
  using SafeMath for uint256;

  uint256 constant BCH_CAP = 21 * 10**24;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  mapping(address => uint256) public nonces;

  uint256 private _reportedSupply;

  constructor() public ERC20("Bitcoin Cash by Strudel", "vBCH") {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("Bitcoin Cash by Strudel")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
    _mint(msg.sender, BCH_CAP);
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _reportedSupply;
  }

  function reportSupply(uint256 newReportedSupply) external onlyOwner {
    require(newReportedSupply <= BCH_CAP, "amount should be less than cap");
    _reportedSupply = newReportedSupply;
  }

  /// @dev             Burns an amount of the token from the given account's balance.
  ///                  deducting from the sender's allowance for said account.
  ///                  Uses the internal _burn function.
  /// @param _account  The account whose tokens will be burnt.
  /// @param _amount   The amount of tokens that will be burnt.
  function burnFrom(address _account, uint256 _amount) external {
    uint256 decreasedAllowance =
      allowance(_account, _msgSender()).sub(_amount, "ERC20: burn amount exceeds allowance");

    _approve(_account, _msgSender(), decreasedAllowance);
    _burn(_account, _amount);
    _reportedSupply = _reportedSupply.sub(_amount);
  }

  /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
  /// total supply.
  /// @param _amount   The amount of tokens that will be burnt.
  function burn(uint256 _amount) external {
    _burn(msg.sender, _amount);
    _reportedSupply = _reportedSupply.sub(_amount);
  }

  /// @notice           Set allowance for other address and notify.
  ///                   Allows `_spender` to spend no more than `_value`
  ///                   tokens on your behalf and then ping the contract about
  ///                   it.
  /// @dev              The `_spender` should implement the `ITokenRecipient`
  ///                   interface to receive approval notifications.
  /// @param _spender   Address of contract authorized to spend.
  /// @param _value     The max amount they can spend.
  /// @param _extraData Extra information to send to the approved contract.
  /// @return true if the `_spender` was successfully approved and acted on
  ///         the approval, false (or revert) otherwise.
  function approveAndCall(
    ITokenRecipient _spender,
    uint256 _value,
    bytes memory _extraData
  ) public returns (bool) {
    // not external to allow bytes memory parameters
    if (approve(address(_spender), _value)) {
      _spender.receiveApproval(msg.sender, _value, address(this), _extraData);
      return true;
    }
    return false;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "Strudel BCH: EXPIRED");
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
      );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(
      recoveredAddress != address(0) && recoveredAddress == owner,
      "Strudel BCH: INVALID_SIGNATURE"
    );
    _approve(owner, spender, value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    function decimals() public view virtual returns (uint8) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
}

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import {IGovBridge} from "../IGovBridge.sol";

contract MockGovBridge {
  event Deposit(address indexed receiver);

  function deposit(
    address token,
    uint256 amount,
    address receiver
  ) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    emit Deposit(receiver);
  }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../balancer/BMath.sol";
import "../balancer/IBPool.sol";

contract BPool is ERC20UpgradeSafe, BMath, IBPool {
  struct Record {
    bool bound; // is token bound to pool
    uint256 index; // private
    uint256 denorm; // denormalized weight
    uint256 balance;
  }

  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);

  event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);

  event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data);

  modifier _logs_() {
    emit LOG_CALL(msg.sig, msg.sender, msg.data);
    _;
  }

  modifier _lock_() {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    require(!_mutex, "ERR_REENTRY");
    _;
  }

  bool private _mutex;

  address private _factory; // BFactory address to push token exitFee to
  address private _controller; // has CONTROL role
  bool private _publicSwap; // true if PUBLIC can call SWAP functions

  // `setSwapFee` and `finalize` require CONTROL
  // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
  uint256 private _swapFee;
  bool private _finalized;

  address[] private _tokens;
  mapping(address => Record) private _records;
  uint256 private _totalWeight;

  constructor(address controller) public {
    _controller = controller;
    _factory = msg.sender;
    _swapFee = MIN_FEE;
    _publicSwap = false;
    _finalized = false;
    __ERC20_init("poolName", "POS");
  }

  /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) internal pure returns (uint256 spotPrice) {
    uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
    uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
    uint256 ratio = bdiv(numer, denom);
    uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
    return (spotPrice = bmul(ratio, scale));
  }

  /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
    uint256 adjustedIn = bsub(BONE, swapFee);
    adjustedIn = bmul(tokenAmountIn, adjustedIn);
    uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
    uint256 foo = bpow(y, weightRatio);
    uint256 bar = bsub(BONE, foo);
    tokenAmountOut = bmul(tokenBalanceOut, bar);
    return tokenAmountOut;
  }

  function isPublicSwap() external view override returns (bool) {
    return _publicSwap;
  }

  function isFinalized() external view returns (bool) {
    return _finalized;
  }

  function isBound(address t) external view override returns (bool) {
    return _records[t].bound;
  }

  function getNumTokens() external view returns (uint256) {
    return _tokens.length;
  }

  function getCurrentTokens() external view override _viewlock_ returns (address[] memory tokens) {
    return _tokens;
  }

  function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
    require(_finalized, "ERR_NOT_FINALIZED");
    return _tokens;
  }

  function getDenormalizedWeight(address token)
    external
    view
    override
    _viewlock_
    returns (uint256)
  {
    require(_records[token].bound, "ERR_NOT_BOUND");
    return _records[token].denorm;
  }

  function getTotalDenormalizedWeight() external view override _viewlock_ returns (uint256) {
    return _totalWeight;
  }

  function getNormalizedWeight(address token) external view _viewlock_ returns (uint256) {
    require(_records[token].bound, "ERR_NOT_BOUND");
    uint256 denorm = _records[token].denorm;
    return bdiv(denorm, _totalWeight);
  }

  function getBalance(address token) external view override _viewlock_ returns (uint256) {
    require(_records[token].bound, "ERR_NOT_BOUND");
    return _records[token].balance;
  }

  function getSwapFee() external view override _viewlock_ returns (uint256) {
    return _swapFee;
  }

  function getController() external view _viewlock_ returns (address) {
    return _controller;
  }

  function setSwapFee(uint256 swapFee) external override _logs_ _lock_ {
    require(!_finalized, "ERR_IS_FINALIZED");
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
    require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
    _swapFee = swapFee;
  }

  function setController(address manager) external _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    _controller = manager;
  }

  function setPublicSwap(bool public_) external override _logs_ _lock_ {
    require(!_finalized, "ERR_IS_FINALIZED");
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    _publicSwap = public_;
  }

  function finalize() external _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(!_finalized, "ERR_IS_FINALIZED");
    require(_tokens.length >= MIN_ASSET_LIMIT, "ERR_MIN_TOKENS");

    _finalized = true;
    _publicSwap = true;

    _mintPoolShare(MIN_POOL_SUPPLY);
    _pushPoolShare(msg.sender, MIN_POOL_SUPPLY);
  }

  function bind(
    address token,
    uint256 balance,
    uint256 denorm
  )
    external
    override
    _logs_ // _lock_  Bind does not lock because it jumps to `rebind`, which does
  {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(!_records[token].bound, "ERR_IS_BOUND");
    require(!_finalized, "ERR_IS_FINALIZED");

    require(_tokens.length < MAX_ASSET_LIMIT, "ERR_MAX_TOKENS");

    _records[token] = Record({
      bound: true,
      index: _tokens.length,
      denorm: 0, // balance and denorm will be validated
      balance: 0 // and set by `rebind`
    });
    _tokens.push(token);
    rebind(token, balance, denorm);
  }

  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) public override _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(_records[token].bound, "ERR_NOT_BOUND");
    require(!_finalized, "ERR_IS_FINALIZED");

    require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
    require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
    require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

    // Adjust the denorm and totalWeight
    uint256 oldWeight = _records[token].denorm;
    if (denorm > oldWeight) {
      _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
      require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
    } else if (denorm < oldWeight) {
      _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
    }
    _records[token].denorm = denorm;

    // Adjust the balance record and actual token balance
    uint256 oldBalance = _records[token].balance;
    _records[token].balance = balance;
    if (balance > oldBalance) {
      _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
    } else if (balance < oldBalance) {
      // In this case liquidity is being withdrawn, so charge EXIT_FEE
      uint256 tokenBalanceWithdrawn = bsub(oldBalance, balance);
      uint256 tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
      _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
      _pushUnderlying(token, _factory, tokenExitFee);
    }
  }

  function unbind(address token) external override _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(_records[token].bound, "ERR_NOT_BOUND");
    require(!_finalized, "ERR_IS_FINALIZED");

    uint256 tokenBalance = _records[token].balance;
    uint256 tokenExitFee = bmul(tokenBalance, EXIT_FEE);

    _totalWeight = bsub(_totalWeight, _records[token].denorm);

    // Swap the token-to-unbind with the last token,
    // then delete the last token
    uint256 index = _records[token].index;
    uint256 last = _tokens.length - 1;
    _tokens[index] = _tokens[last];
    _records[_tokens[index]].index = index;
    _tokens.pop();
    _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});

    _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
    _pushUnderlying(token, _factory, tokenExitFee);
  }

  // Absorb any tokens that have been sent to this contract into the pool
  function gulp(address token) external override _logs_ _lock_ {
    require(_records[token].bound, "ERR_NOT_BOUND");
    _records[token].balance = IERC20(token).balanceOf(address(this));
  }

  function getSpotPrice(address tokenIn, address tokenOut)
    external
    view
    _viewlock_
    returns (uint256 spotPrice)
  {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    Record storage inRecord = _records[tokenIn];
    Record storage outRecord = _records[tokenOut];
    return
      calcSpotPrice(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        _swapFee
      );
  }

  function getSpotPriceSansFee(address tokenIn, address tokenOut)
    external
    view
    _viewlock_
    returns (uint256 spotPrice)
  {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    Record storage inRecord = _records[tokenIn];
    Record storage outRecord = _records[tokenOut];
    return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
  }

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external _logs_ _lock_ {
    require(_finalized, "ERR_NOT_FINALIZED");

    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    require(ratio != 0, "ERR_MATH_APPROX");

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = _records[t].balance;
      uint256 tokenAmountIn = bmul(ratio, bal);
      require(tokenAmountIn != 0, "ERR_MATH_APPROX");
      require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
      _records[t].balance = badd(_records[t].balance, tokenAmountIn);
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }
    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
  }

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external _logs_ _lock_ {
    require(_finalized, "ERR_NOT_FINALIZED");

    uint256 poolTotal = totalSupply();
    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
    uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
    uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
    require(ratio != 0, "ERR_MATH_APPROX");

    _pullPoolShare(msg.sender, poolAmountIn);
    _pushPoolShare(_factory, exitFee);
    _burnPoolShare(pAiAfterExitFee);

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = _records[t].balance;
      uint256 tokenAmountOut = bmul(ratio, bal);
      require(tokenAmountOut != 0, "ERR_MATH_APPROX");
      require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
      _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
      emit LOG_EXIT(msg.sender, t, tokenAmountOut);
      _pushUnderlying(t, msg.sender, tokenAmountOut);
    }
  }

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external override _logs_ _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

    uint256 spotPriceBefore =
      calcSpotPrice(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        _swapFee
      );
    require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

    tokenAmountOut = calcOutGivenIn(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      tokenAmountIn,
      _swapFee
    );
    require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

    inRecord.balance = badd(inRecord.balance, tokenAmountIn);
    outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
    require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
    require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountOut, spotPriceAfter);
  }

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external _logs_ _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

    uint256 spotPriceBefore =
      calcSpotPrice(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        _swapFee
      );
    require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

    tokenAmountIn = calcInGivenOut(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      tokenAmountOut,
      _swapFee
    );
    require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

    inRecord.balance = badd(inRecord.balance, tokenAmountIn);
    outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
    require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
    require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountIn, spotPriceAfter);
  }

  // ==
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(
    address erc20,
    address from,
    uint256 amount
  ) internal {
    bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
    require(xfer, "ERR_ERC20_FALSE");
  }

  function _pushUnderlying(
    address erc20,
    address to,
    uint256 amount
  ) internal {
    bool xfer = IERC20(erc20).transfer(to, amount);
    require(xfer, "ERR_ERC20_FALSE");
  }

  function _pullPoolShare(address from, uint256 amount) internal {
    _transfer(from, address(this), amount);
  }

  function _pushPoolShare(address to, uint256 amount) internal {
    _transfer(address(this), to, amount);
  }

  function _mintPoolShare(uint256 amount) internal {
    _mint(address(this), amount);
  }

  function _burnPoolShare(uint256 amount) internal {
    _burn(address(this), amount);
  }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General internal License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General internal License for more details.

// You should have received a copy of the GNU General internal License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.6;

import "./BNum.sol";

contract BMath is BNum {
  /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
    uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
    uint256 y = bdiv(tokenBalanceOut, diff);
    uint256 foo = bpow(y, weightRatio);
    foo = bsub(foo, BONE);
    tokenAmountIn = bsub(BONE, swapFee);
    tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
    return tokenAmountIn;
  }

  /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountOut) {
    // Charge the trading fee for the proportion of tokenAi
    ///  which is implicitly traded to the other pool tokens.
    // That proportion is (1- weightTokenIn)
    // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

    uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
    uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

    // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
    uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    poolAmountOut = bsub(newPoolSupply, poolSupply);
    return poolAmountOut;
  }

  /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    //uint newBalTi = poolRatio^(1/weightTi) * balTi;
    uint256 boo = bdiv(BONE, normalizedWeight);
    uint256 tokenInRatio = bpow(poolRatio, boo);
    uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
    uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
    // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
    //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
    //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
    uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
    return tokenAmountIn;
  }

  /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    // charge exit fee on the pool token side
    // pAiAfterExitFee = pAi*(1-exitFee)
    uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
    uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    // newBalTo = poolRatio^(1/weightTo) * balTo;
    uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
    uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

    uint256 tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

    // charge swap fee on the output token side
    //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
    return tokenAmountOut;
  }

  /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountIn) {
    // charge swap fee on the output token side
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
    uint256 zoo = bsub(BONE, normalizedWeight);
    uint256 zar = bmul(zoo, swapFee);
    uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

    uint256 newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
    uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

    //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
    uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

    // charge exit fee on the pool token side
    // pAi = pAiAfterExitFee/(1-exitFee)
    poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
    return poolAmountIn;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

interface IBPool {
  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function setSwapFee(uint256 swapFee) external;

  function setPublicSwap(bool publicSwap) external;

  function bind(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function unbind(address token) external;

  function gulp(address token) external;

  function isBound(address token) external view returns (bool);

  function getBalance(address token) external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function isPublicSwap() external view returns (bool);

  function getDenormalizedWeight(address token) external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.6;

import "./libraries/BConst.sol";

contract BNum is BConst {
  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }

  // DSMath.wpow
  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;

    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);

      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
    require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);

    uint256 wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    // term 0:
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;

      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }

    return sum;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

/**
 * @author Balancer Labs
 * @title Put all the constants in one place
 */

contract BConst {
  // State variables (must be constant in a library)

  // B "ONE" - all math is in the "realm" of 10 ** 18;
  // where numeric 1 = 10 ** 18
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_WEIGHT = BONE;
  uint256 internal constant MAX_WEIGHT = BONE * 50;
  uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 50;
  uint256 internal constant MIN_BALANCE = BONE / 10**6;
  uint256 internal constant MAX_BALANCE = BONE * 10**12;
  uint256 internal constant MIN_POOL_SUPPLY = BONE * 100;
  uint256 internal constant MAX_POOL_SUPPLY = BONE * 10**9;
  uint256 internal constant MIN_FEE = BONE / 10**6;
  uint256 internal constant MAX_FEE = BONE / 10;
  // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
  uint256 internal constant EXIT_FEE = 0;
  uint256 internal constant MAX_IN_RATIO = BONE / 2;
  uint256 internal constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
  // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
  uint256 internal constant MIN_ASSET_LIMIT = 2;
  uint256 internal constant MAX_ASSET_LIMIT = 8;
  uint256 internal constant MAX_UINT = uint256(-1);

  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

import {IBPool} from "../balancer/IBPool.sol";
import {BPool} from "./BPool.sol";

contract MockBFactory {
  function newBPool() external returns (IBPool) {
    return new BPool(msg.sender);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

import "./IBPool.sol";

interface IBFactory {
  function newBPool() external returns (IBPool);

  function setBLabs(address b) external;

  function collect(IBPool pool) external;

  function isBPool(address b) external view returns (bool);

  function getBLabs() external view returns (address);
}

pragma solidity 0.6.6;

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::: @#::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::: ########: ##:: jU* DUTCh>: ihD%Ky: #@Whdqy:::::::::::::::::::::
//::: ###... ###: ##:: #@j: @B... @@7...t: [email protected] [email protected]:::::::::::::::::::
//::: ##::::: ##: ##::[email protected]: @Q::: @Q.::::: [email protected]:: [email protected]:::::::::::::::::::
//:::: ##DuTCH##: %@[email protected]@S`: hQQQh <[email protected]@Q* [email protected]:: [email protected]:::::::::::::::::::
//::::::.......: [email protected]:::....:::......::...:::...:::::::::::::::::::
//:::::::::::::: [email protected]? [email protected]! 'DW;::::::.KK. [email protected]: NNKNQBdt:::::::::
//:::::::::::::: 'zqRqj*. [email protected] [email protected]: QQ: [email protected] [email protected] [email protected]@: @@U... @Q::::::::
//:::::::::::::::::...... [email protected]^ ^@@[email protected]@[email protected] <@Q^::: @@: @@}::: @@::::::::
//:::::::::::::::::: [email protected]@QKt... [email protected]@[email protected] [email protected]: @@QQ#QQq:::::::::
//:::::::::::::::::::.....::::::...:::...::::.......: @@!.....:::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::01101100:01101111:01101111:01101011::::::::::::::::::::
//:::::01100100:01100101:01100101:01110000:01111001:01110010:::::::::::
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// DutchSwap Factory
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// Appropriated from BokkyPooBah's Fixed Supply Token 👊 Factory
// https://www.ethervendingmachine.io
// Thanks Bokky!
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./CloneFactory.sol";
import "./IDutchAuction.sol";

contract DutchSwapFactory is OwnableUpgradeSafe, CloneFactory {
  using SafeMath for uint256;

  address public dutchAuctionTemplate;

  struct Auction {
    bool exists;
    uint256 index;
  }

  address public newAddress;
  uint256 public minimumFee = 0 ether;
  mapping(address => Auction) public isChildAuction;
  address[] public auctions;

  event DutchAuctionDeployed(
    address indexed owner,
    address indexed addr,
    address dutchAuction,
    uint256 fee
  );
  event CustomAuctionDeployed(address indexed owner, address indexed addr);

  event AuctionRemoved(address dutchAuction, uint256 index);
  event FactoryDeprecated(address newAddress);
  event MinimumFeeUpdated(uint256 oldFee, uint256 newFee);
  event AuctionTemplateUpdated(address oldDutchAuction, address newDutchAuction);

  function initDutchSwapFactory(address _dutchAuctionTemplate, uint256 _minimumFee) public {
    __Ownable_init();
    dutchAuctionTemplate = _dutchAuctionTemplate;
    minimumFee = _minimumFee;
  }

  function numberOfAuctions() public view returns (uint256) {
    return auctions.length;
  }

  function addCustomAuction(address _auction) public onlyOwner {
    require(!isChildAuction[_auction].exists);
    bool finalised = IDutchAuction(_auction).auctionEnded();
    require(!finalised);
    isChildAuction[address(_auction)] = Auction(true, auctions.length - 1);
    auctions.push(address(_auction));
    emit CustomAuctionDeployed(msg.sender, address(_auction));
  }

  function removeFinalisedAuction(address _auction) public {
    require(isChildAuction[_auction].exists);
    bool finalised = IDutchAuction(_auction).auctionEnded();
    require(finalised);
    uint256 removeIndex = isChildAuction[_auction].index;
    emit AuctionRemoved(_auction, auctions.length - 1);
    uint256 lastIndex = auctions.length - 1;
    address lastIndexAddress = auctions[lastIndex];
    auctions[removeIndex] = lastIndexAddress;
    isChildAuction[lastIndexAddress].index = removeIndex;
    if (auctions.length > 0) {
      auctions.pop();
    }
  }

  function deprecateFactory(address _newAddress) public onlyOwner {
    require(newAddress == address(0));
    emit FactoryDeprecated(_newAddress);
    newAddress = _newAddress;
  }

  function setMinimumFee(uint256 _minimumFee) public onlyOwner {
    emit MinimumFeeUpdated(minimumFee, _minimumFee);
    minimumFee = _minimumFee;
  }

  function setDutchAuctionTemplate(address _dutchAuctionTemplate) public onlyOwner {
    emit AuctionTemplateUpdated(dutchAuctionTemplate, _dutchAuctionTemplate);
    dutchAuctionTemplate = _dutchAuctionTemplate;
  }

  function deployDutchAuction(
    address _token,
    uint256 _tokenSupply,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address payable _wallet
  ) public payable returns (address dutchAuction) {
    dutchAuction = createClone(dutchAuctionTemplate);
    isChildAuction[address(dutchAuction)] = Auction(true, auctions.length - 1);
    auctions.push(address(dutchAuction));
    require(IERC20(_token).transferFrom(msg.sender, address(this), _tokenSupply));
    require(IERC20(_token).approve(dutchAuction, _tokenSupply));
    IDutchAuction(dutchAuction).initDutchAuction(
      address(this),
      _token,
      _tokenSupply,
      _startDate,
      _endDate,
      _paymentCurrency,
      _startPrice,
      _minimumPrice,
      _wallet
    );
    emit DutchAuctionDeployed(msg.sender, address(dutchAuction), dutchAuctionTemplate, msg.value);
  }

  // footer functions
  function transferAnyERC20Token(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
  {
    return IERC20(tokenAddress).transfer(owner(), tokens);
  }

  receive() external payable {
    revert();
  }
}

pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// CloneFactory.sol
// From
// https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
// ----------------------------------------------------------------------------

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

pragma solidity 0.6.6;

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::: @#::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::: ########: ##:: ##:: DUTCh>: ihD%y: #@Whdqy:::::::::::::::::::::
//::: ###... ###: ##:: ##:: @B... @@7...t: [email protected] [email protected]:::::::::::::::::::
//::: ##::::: ##: ##:: ##:: @Q::: @Q.::::: [email protected]:: [email protected]:::::::::::::::::::
//:::: ##DuTCH##: [email protected]@@#:: hQQQh <[email protected]@Q: [email protected]:: [email protected]:::::::::::::::::::
//::::::.......: [email protected]:::....:::......::...:::...:::::::::::::::::::
//:::::::::::::: [email protected]? [email protected]! 'DW;:::::: KK. [email protected]: NNKNQBdt:::::::::
//:::::::::::::: 'zqRqj*. [email protected] [email protected]: QQ: [email protected] [email protected] [email protected]@: @@U... @Q::::::::
//:::::::::::::::::...... [email protected]^ ^@@[email protected]@[email protected] <@Q^::: @@: @@}::: @@::::::::
//:::::::::::::::::: [email protected]@QKt... [email protected]@L.. [email protected] [email protected]: @@QQ#QQq:::::::::
//:::::::::::::::::::.....::::::...:::...::::.......: @@!.....:::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::01101100:01101111:01101111:01101011::::::::::::::::::::
//:::::01100100:01100101:01100101:01110000:01111001:01110010:::::::::::
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// DutchSwap Auction V1.3
//   Copyright (c) 2020 DutchSwap.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.
// If not, see <https://github.com/deepyr/DutchSwap/>.
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// ---------------------------------------------------------------------

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract DutchSwapAuction {
  using SafeMath for uint256;
  /// @dev The placeholder ETH address.
  address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  uint256 public startDate;
  uint256 public endDate;
  uint256 public startPrice;
  uint256 public minimumPrice;
  uint256 public totalTokens; // Amount to be sold
  uint256 public priceDrop; // Price reduction from startPrice at endDate
  uint256 public commitmentsTotal;
  uint256 public tokenWithdrawn; // the amount of auction tokens already withdrawn
  bool private initialised;
  bool public finalised;
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;

  address public auctionToken;
  address public paymentCurrency;
  address payable public wallet; // Where the auction funds will get paid
  mapping(address => uint256) public commitments;
  mapping(address => uint256) public claimed;

  event AddedCommitment(address addr, uint256 commitment, uint256 price);

  /// @dev Prevents a contract from calling itself, directly or indirectly.
  /// @dev https://eips.ethereum.org/EIPS/eip-2200)
  modifier nonReentrant() {
    require(_status != _ENTERED, "ended"); // ReentrancyGuard: reentrant call
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }

  /// @dev Init function
  function initDutchAuction(
    address _funder,
    address _token,
    uint256 _totalTokens,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address payable _wallet
  ) external {
    require(!initialised, "initialized"); // Already Initialised
    require(_endDate > _startDate, "dates"); // End date earlier than start date
    require(_minimumPrice > 0, "minPrice"); // Minimum price must be greater than 0

    auctionToken = _token;
    paymentCurrency = _paymentCurrency;

    totalTokens = _totalTokens;
    startDate = _startDate;
    endDate = _endDate;
    startPrice = _startPrice;
    minimumPrice = _minimumPrice;
    wallet = _wallet;
    _status = _NOT_ENTERED;

    uint256 numerator = startPrice.sub(minimumPrice);
    uint256 denominator = endDate.sub(startDate);
    priceDrop = numerator.div(denominator);

    // There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
    _safeTransferFrom(auctionToken, _funder, _totalTokens);
    initialised = true;
  }

  // Dutch Auction Price Function
  // ============================
  //
  // Start Price -----
  //                   \
  //                    \
  //                     \
  //                      \ ------------ Clearing Price
  //                     / \            = AmountRaised/TokenSupply
  //      Token Price  --   \
  //                  /      \
  //                --        ----------- Minimum Price
  // Amount raised /          End Time
  //

  /// @notice The average price of each token from all commitments.
  function tokenPrice() public view returns (uint256) {
    return commitmentsTotal.mul(1e18).div(totalTokens);
  }

  /// @notice Returns price during the auction
  function priceFunction() public view returns (uint256) {
    /// @dev Return Auction Price
    if (block.timestamp <= startDate) {
      return startPrice;
    }
    if (block.timestamp >= endDate) {
      return minimumPrice;
    }
    return _currentPrice();
  }

  /// @notice The current clearing price of the Dutch auction
  function clearingPrice() public view returns (uint256) {
    /// @dev If auction successful, return tokenPrice
    if (tokenPrice() > priceFunction()) {
      return tokenPrice();
    }
    return priceFunction();
  }

  /// @notice How many tokens the user is able to claim
  function tokensClaimable(address _user) public view returns (uint256) {
    uint256 tokensAvailable = commitments[_user].mul(1e18).div(clearingPrice());
    return tokensAvailable.sub(claimed[msg.sender]);
  }

  /// @notice Total amount of tokens committed at current auction price–
  function totalTokensCommitted() public view returns (uint256) {
    return commitmentsTotal.mul(1e18).div(clearingPrice());
  }

  /// @notice Total amount of tokens remaining
  function tokensRemaining() public view returns (uint256) {
    uint256 totalCommitted = totalTokensCommitted();
    if (totalCommitted >= totalTokens) {
      return 0;
    } else {
      return totalTokens.sub(totalCommitted);
    }
  }

  /// @notice Returns price during the auction
  function _currentPrice() private view returns (uint256) {
    uint256 elapsed = block.timestamp.sub(startDate);
    uint256 priceDiff = elapsed.mul(priceDrop);
    return startPrice.sub(priceDiff);
  }

  //--------------------------------------------------------
  // Commit to buying tokens!
  //--------------------------------------------------------

  /// @notice Buy Tokens by committing ETH to this contract address
  /// @dev Needs extra gas limit for additional state changes
  receive() external payable {
    commitEthFrom(msg.sender);
  }

  /// @dev Needs extra gas limit for additional state changes
  function commitEth() public payable {
    commitEthFrom(msg.sender);
  }

  /// @notice Commit ETH to buy tokens for any address
  function commitEthFrom(address payable _from) public payable {
    require(!finalised, "finalized"); // Auction was cancelled
    require(address(paymentCurrency) == ETH_ADDRESS, "notEth"); // Payment currency is not ETH
    // Get ETH able to be committed
    uint256 ethToTransfer = calculateCommitment(msg.value);

    // Accept ETH Payments
    uint256 ethToRefund = msg.value.sub(ethToTransfer);
    if (ethToTransfer > 0) {
      _addCommitment(_from, ethToTransfer);
    }
    // Return any ETH to be refunded
    if (ethToRefund > 0) {
      _from.transfer(ethToRefund);
    }
  }

  /// @notice Commit approved ERC20 tokens to buy tokens on sale
  function commitTokens(uint256 _amount) public {
    commitTokensFrom(msg.sender, _amount);
  }

  /// @dev Users must approve contract prior to committing tokens to auction
  function commitTokensFrom(address _from, uint256 _amount) public nonReentrant {
    require(!finalised, "finalized"); // Auction was cancelled
    require(address(paymentCurrency) != ETH_ADDRESS, "address"); // Only token transfers
    uint256 tokensToTransfer = calculateCommitment(_amount);
    if (tokensToTransfer > 0) {
      _safeTransferFrom(paymentCurrency, _from, tokensToTransfer);
      _addCommitment(_from, tokensToTransfer);
    }
  }

  /// @notice Returns the amout able to be committed during an auction
  function calculateCommitment(uint256 _commitment) public view returns (uint256 committed) {
    uint256 maxCommitment = totalTokens.mul(clearingPrice()).div(1e18);
    if (commitmentsTotal.add(_commitment) > maxCommitment) {
      return maxCommitment.sub(commitmentsTotal);
    }
    return _commitment;
  }

  /// @notice Commits to an amount during an auction
  function _addCommitment(address _addr, uint256 _commitment) internal {
    require(block.timestamp >= startDate && block.timestamp <= endDate, "date"); // Outside auction hours
    commitments[_addr] = commitments[_addr].add(_commitment);
    commitmentsTotal = commitmentsTotal.add(_commitment);
    emit AddedCommitment(_addr, _commitment, _currentPrice());
  }

  //--------------------------------------------------------
  // Finalise Auction
  //--------------------------------------------------------

  /// @notice Successful if tokens sold equals totalTokens
  function auctionSuccessful() public view returns (bool) {
    return tokenPrice() >= clearingPrice();
  }

  /// @notice Returns bool if successful or time has ended
  /// @dev able to claim early if auction is successful
  function auctionEnded() public view returns (bool) {
    return auctionSuccessful() || block.timestamp > endDate;
  }

  /// @notice Auction finishes successfully above the reserve
  /// @dev Transfer contract funds to initialised wallet.
  function finaliseAuction() public nonReentrant {
    require(!finalised, "finalized"); // Auction already finalised
    if (auctionSuccessful()) {
      /// @dev Successful auction
      /// @dev Transfer contributed tokens to wallet.
      _tokenPayment(paymentCurrency, wallet, commitmentsTotal);
    } else if (commitmentsTotal == 0 && block.timestamp < startDate) {
      /// @dev Cancelled Auction
      /// @dev You can cancel the auction before it starts
      _tokenPayment(auctionToken, wallet, totalTokens);
    } else {
      /// @dev Failed auction
      /// @dev Return auction tokens back to wallet.
      require(block.timestamp > endDate, "endDate"); // Auction not yet finished
      _tokenPayment(auctionToken, wallet, totalTokens);
    }
    finalised = true;
  }

  /// @notice Withdraw your tokens once the Auction has ended.
  function withdrawTokens() public nonReentrant {
    if (auctionSuccessful()) {
      /// @dev Successful auction! Transfer claimed tokens.
      uint256 tokensToClaim = tokensClaimable(msg.sender);
      require(tokensToClaim > 0, "toClaim"); // No tokens to claim
      claimed[msg.sender] = claimed[msg.sender].add(tokensToClaim);
      tokenWithdrawn = tokenWithdrawn.add(tokensToClaim);
      _tokenPayment(auctionToken, msg.sender, tokensToClaim);
    } else {
      /// @dev Auction did not meet reserve price.
      /// @dev Return committed funds back to user.
      require(block.timestamp > endDate, "endDate"); // Auction not yet finished
      uint256 fundsCommitted = commitments[msg.sender];
      require(fundsCommitted > 0, "fundsCommited"); // No funds committed

      commitments[msg.sender] = 0; // Stop multiple withdrawals and free some gas
      _tokenPayment(paymentCurrency, msg.sender, fundsCommitted);
    }
  }

  //--------------------------------------------------------
  // Helper Functions
  //--------------------------------------------------------

  // There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
  // I'm trying to make it a habit to put external calls last (reentrancy)
  // You can put this in an internal function if you like.
  function _safeTransfer(
    address token,
    address to,
    uint256 amount
  ) internal {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) =
      token.call(
        // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
        abi.encodeWithSelector(0xa9059cbb, to, amount)
      );
    require(success && (data.length == 0 || abi.decode(data, (bool))), "stransfer failed"); // ERC20 Transfer failed
  }

  function _safeTransferFrom(
    address token,
    address from,
    uint256 amount
  ) internal {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) =
      token.call(
        // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
        abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
      );
    require(success && (data.length == 0 || abi.decode(data, (bool))), "stransfrom"); // ERC20 TransferFrom failed
  }

  /// @dev Helper function to handle both ETH and ERC20 payments
  function _tokenPayment(
    address _token,
    address payable _to,
    uint256 _amount
  ) internal {
    if (address(_token) == ETH_ADDRESS) {
      _to.transfer(_amount);
    } else {
      _safeTransfer(_token, _to, _amount);
    }
  }
}

pragma solidity 0.6.6;

import {TypedMemView} from "../summa-tx/TypedMemView.sol";
import {ViewBTC} from "../summa-tx/ViewBTC.sol";
import {ViewSPV} from "../summa-tx/ViewSPV.sol";
import {IRelay} from "../summa-tx/IRelay.sol";

/** @title MockRelay */
/** half-hearted implementation for testing */

contract MockRelay is IRelay {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ViewBTC for bytes29;
  using ViewSPV for bytes29;

  bytes32 bestKnownDigest;
  bytes32 lastReorgCommonAncestor;
  uint256 public currentEpochDiff;
  mapping(bytes32 => uint256) public heights;

  constructor(
    bytes32 _bestKnownDigest,
    uint256 _bestKnownHeight,
    bytes32 _lastReorgCommonAncestor,
    uint256 _lastReorgHeight
  ) public {
    bestKnownDigest = _bestKnownDigest;
    heights[_bestKnownDigest] = _bestKnownHeight;
    lastReorgCommonAncestor = _lastReorgCommonAncestor;
    heights[_lastReorgCommonAncestor] = _lastReorgHeight;
  }

  function addHeader(bytes32 _digest, uint256 _height) external {
    heights[_digest] = _height;
  }

  /// @notice     Getter for bestKnownDigest
  /// @dev        This updated only by calling markNewHeaviest
  /// @return     The hash of the best marked chain tip
  function getBestKnownDigest() public view override returns (bytes32) {
    return bestKnownDigest;
  }

  /// @notice     Getter for relayGenesis
  /// @dev        This is updated only by calling markNewHeaviest
  /// @return     The hash of the shared ancestor of the most recent fork
  function getLastReorgCommonAncestor() public view override returns (bytes32) {
    return lastReorgCommonAncestor;
  }

  /// @notice     Getter for bestKnownDigest
  /// @dev        This updated only by calling markNewHeaviest

  function setBestKnownDigest(bytes32 _bestKnownDigest) external {
    require(heights[_bestKnownDigest] > 0, "not found");
    bestKnownDigest = _bestKnownDigest;
  }

  /// @notice     Getter for relayGenesis
  /// @dev        This is updated only by calling markNewHeaviest

  function setLastReorgCommonAncestor(bytes32 _lrca) external {
    require(heights[_lrca] > 0, "not found");
    require(heights[_lrca] <= heights[bestKnownDigest], "ahead of tip");
    lastReorgCommonAncestor = _lrca;
  }

  /// @notice         Finds the height of a header by its digest
  /// @dev            Will fail if the header is unknown
  /// @param _digest  The header digest to search for
  /// @return         The height of the header, or error if unknown
  function findHeight(bytes32 _digest) external view override returns (uint256) {
    uint256 height = heights[_digest];
    if (height == 0) {
      revert("Not included!");
    }
    return height;
  }

  /// @notice             Checks if a digest is an ancestor of the current one
  /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
  /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
  function isAncestor(
    bytes32,
    bytes32,
    uint256
  ) external view override returns (bool) {
    return true;
  }

  function addHeaders(bytes calldata _anchor, bytes calldata _headers)
    external
    override
    returns (bool)
  {
    require(_headers.length % 80 == 0, "Header array length must be divisible by 80");
    bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();
    bytes29 _anchorView = _anchor.ref(0).tryAsHeader();

    require(_headersView.notNull(), "Header array length must be divisible by 80");
    require(_anchorView.notNull(), "Anchor must be 80 bytes");
    return _addHeaders(_anchorView, _headersView);
  }

  /// @notice             Adds headers to storage after validating
  /// @dev                We check integrity and consistency of the header chain
  /// @param  _anchor     The header immediately preceeding the new chain
  /// @param  _headers    A tightly-packed list of new 80-byte Bitcoin headers to record
  /// @return             True if successfully written, error otherwise
  function _addHeaders(bytes29 _anchor, bytes29 _headers) internal returns (bool) {
    uint256 _height;
    bytes32 _currentDigest;
    bytes32 _previousDigest = _anchor.hash256();

    uint256 _anchorHeight = heights[_previousDigest]; /* NB: errors if unknown */
    require(_anchorHeight > 0, "anchor height can not be 0");

    /*
    NB:
    1. check that the header has sufficient work
    2. check that headers are in a coherent chain (no retargets, hash links good)
    3. Store the block connection
    4. Store the height
    */
    for (uint256 i = 0; i < _headers.len() / 80; i += 1) {
      bytes29 _header = _headers.indexHeaderArray(i);
      _height = _anchorHeight + (i + 1);
      _currentDigest = _header.hash256();
      heights[_currentDigest] = _height;
      require(_header.checkParent(_previousDigest), "Headers do not form a consistent chain");
      _previousDigest = _currentDigest;
    }

    emit Extension(_anchor.hash256(), _currentDigest);
    return true;
  }

  function addHeadersWithRetarget(
    bytes calldata,
    bytes calldata _oldPeriodEndHeader,
    bytes calldata _headers
  ) external override returns (bool) {
    bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();
    bytes29 _anchorView = _oldPeriodEndHeader.ref(0).tryAsHeader();

    require(_headersView.notNull(), "Header array length must be divisible by 80");
    require(_anchorView.notNull(), "Anchor must be 80 bytes");
    return _addHeaders(_anchorView, _headersView);
  }

  function markNewHeaviest(
    bytes32 _ancestor,
    bytes calldata _currentBest,
    bytes calldata _newBest,
    uint256 _limit
  ) external override returns (bool) {
    bytes29 _new = _newBest.ref(0).tryAsHeader();
    bytes29 _current = _currentBest.ref(0).tryAsHeader();
    require(_new.notNull() && _current.notNull(), "Bad args. Check header and array byte lengths.");
    return _markNewHeaviest(_ancestor, _current, _new, _limit);
  }

  /// @notice                   Marks the new best-known chain tip
  /// @param  _ancestor         The digest of the most recent common ancestor
  /// @param  _current          The 80-byte header referenced by bestKnownDigest
  /// @param  _new              The 80-byte header to mark as the new best
  /// @param  _limit            Limit the amount of traversal of the chain
  /// @return                   True if successfully updates bestKnownDigest, error otherwise
  function _markNewHeaviest(
    bytes32 _ancestor,
    bytes29 _current, // Header
    bytes29 _new, // Header
    uint256 _limit
  ) internal returns (bool) {
    require(_limit <= 2016, "Requested limit is greater than 1 difficulty period");
    bytes32 _newBestDigest = _new.hash256();
    bytes32 _currentBestDigest = _current.hash256();
    require(_currentBestDigest == bestKnownDigest, "Passed in best is not best known");
    require(heights[_newBestDigest] > 0, "New best is unknown");

    bestKnownDigest = _newBestDigest;
    lastReorgCommonAncestor = _ancestor;

    uint256 _newDiff = _new.diff();
    if (_newDiff != currentEpochDiff) {
      currentEpochDiff = _newDiff;
    }

    emit NewTip(_currentBestDigest, _newBestDigest, _ancestor);
    return true;
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import {TypedMemView} from "./summa-tx/TypedMemView.sol";
import {ViewBTC} from "./summa-tx/ViewBTC.sol";
import {ViewSPV} from "./summa-tx/ViewSPV.sol";
import "./summa-tx/IRelay.sol";

interface IERC20 {
  function mint(address account, uint256 amount) external returns (bool);

  function transfer(address account, uint256 amount) external returns (bool);
}

/// @title  VBTC Token.
/// @notice This is the VBTC ERC20 contract.
contract BchBridge is OwnableUpgradeSafe {
  using SafeMath for uint256;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ViewBTC for bytes29;
  using ViewSPV for bytes29;

  event Crossing(
    bytes32 indexed btcTxHash,
    address indexed receiver,
    uint256 amount,
    uint32 outputIndex
  );

  uint8 constant ADDR_LEN = 20;
  uint256 constant BCH_CAP = 21 * 10**24;
  uint256 constant BCH_CAP_SQRT = 4582575700000; // sqrt(BCH_CAP)
  bytes3 constant PROTOCOL_ID = 0x07ffff; // a mersenne prime

  // immutable
  IERC20 private strudel;
  IERC20 private bch;

  // gov params
  IRelay public relay;
  uint256 public numConfs;
  uint256 public mintedSupply;

  // working memory
  // marking all sucessfully processed outputs
  mapping(bytes32 => bool) public knownOutpoints;

  constructor(
    address _relay,
    address _strudel,
    address _bch,
    uint256 _minConfs
  ) public {
    __Ownable_init();
    relay = IRelay(_relay);
    strudel = IERC20(_strudel);
    bch = IERC20(_bch);
    numConfs = _minConfs;
  }

  function makeCompressedOutpoint(bytes32 _txid, uint32 _index) internal pure returns (bytes32) {
    // sacrifice 4 bytes instead of hashing
    return ((_txid >> 32) << 32) | bytes32(uint256(_index));
  }

  /// @notice             Verifies inclusion of a tx in a header, and that header in the Relay chain
  /// @dev                Specifically we check that both the best tip and the heaviest common header confirm it
  /// @param  _header     The header containing the merkleroot committing to the tx
  /// @param  _proof      The merkle proof intermediate nodes
  /// @param  _index      The index of the tx in the merkle tree's leaves
  /// @param  _txid       The txid that is the proof leaf
  function _checkInclusion(
    bytes29 _header, // Header
    bytes29 _proof, // MerkleArray
    uint256 _index,
    bytes32 _txid
  ) internal view returns (bool) {
    // check the txn is included in the header
    require(ViewSPV.prove(_txid, _header.merkleRoot(), _proof, _index), "Bad inclusion proof");

    // check the header is included in the chain
    bytes32 headerHash = _header.hash256();
    bytes32 GCD = relay.getLastReorgCommonAncestor();
    require(relay.isAncestor(headerHash, GCD, 2500), "GCD does not confirm header");

    // check offset to tip
    bytes32 bestKnownDigest = relay.getBestKnownDigest();
    uint256 height = relay.findHeight(headerHash);
    require(height > 0, "height not found in relay");
    uint256 offset = relay.findHeight(bestKnownDigest).sub(height);
    require(offset >= numConfs, "Insufficient confirmations");

    return true;
  }

  /// @dev             Mints an amount of the token and assigns it to an account.
  ///                  Uses the internal _mint function.
  /// @param _header   header
  /// @param _proof    proof
  /// @param _version  version
  /// @param _locktime locktime
  /// @param _index    tx index in block
  /// @param _crossingOutputIndex    output index that
  /// @param _vin      vin
  /// @param _vout     vout
  function proofOpReturnAndMint(
    bytes calldata _header,
    bytes calldata _proof,
    bytes4 _version,
    bytes4 _locktime,
    uint256 _index,
    uint32 _crossingOutputIndex,
    bytes calldata _vin,
    bytes calldata _vout
  ) external returns (bool) {
    return
      _provideProof(
        _header,
        _proof,
        _version,
        _locktime,
        _index,
        _crossingOutputIndex,
        _vin,
        _vout
      );
  }

  function _provideProof(
    bytes memory _header,
    bytes memory _proof,
    bytes4 _version,
    bytes4 _locktime,
    uint256 _index,
    uint32 _crossingOutputIndex,
    bytes memory _vin,
    bytes memory _vout
  ) internal returns (bool) {
    bytes32 txId = abi.encodePacked(_version, _vin, _vout, _locktime).ref(0).hash256();
    bytes32 outpoint = makeCompressedOutpoint(txId, _crossingOutputIndex);
    require(!knownOutpoints[outpoint], "already processed outputs");

    _checkInclusion(
      _header.ref(0).tryAsHeader().assertValid(),
      _proof.ref(0).tryAsMerkleArray().assertValid(),
      _index,
      txId
    );

    // mark processed
    knownOutpoints[outpoint] = true;

    // do payouts
    address account;
    uint256 amount;
    (account, amount) = doPayouts(_vout.ref(0).tryAsVout(), _crossingOutputIndex);
    emit Crossing(txId, account, amount, _crossingOutputIndex);
    return true;
  }

  function doPayouts(bytes29 _vout, uint32 _crossingOutputIndex)
    internal
    returns (address account, uint256 amount)
  {
    bytes29 output = _vout.indexVout(_crossingOutputIndex);

    // extract receiver and address
    amount = output.value() * 10**10; // wei / satosh = 10^18 / 10^8 = 10^10
    require(amount > 0, "output has 0 value");

    bytes29 opReturnPayload = output.scriptPubkey().opReturnPayload();
    require(opReturnPayload.len() == ADDR_LEN + 3, "invalid op-return payload length");
    require(bytes3(opReturnPayload.index(0, 3)) == PROTOCOL_ID, "invalid protocol id");
    account = address(bytes20(opReturnPayload.index(3, ADDR_LEN)));

    uint256 sqrtVbtcBefore = Babylonian.sqrt(mintedSupply);
    bch.mint(account, amount);
    mintedSupply = mintedSupply.add(amount);
    //bch.transfer(account, amount);
    uint256 sqrtVbtcAfter = Babylonian.sqrt(mintedSupply);

    // calculate the reward as area h(x) = f(x) - g(x), where f(x) = x^2 and g(x) = |minted|
    // pay out only the delta to the previous claim: H(after) - H(before)
    // this caps all minting rewards to 2/3 of BCH_CAP
    uint256 rewardAmount =
      BCH_CAP
        .mul(3)
        .mul(sqrtVbtcAfter)
        .add(sqrtVbtcBefore**3)
        .sub(BCH_CAP.mul(3).mul(sqrtVbtcBefore))
        .sub(sqrtVbtcAfter**3)
        .div(3)
        .div(BCH_CAP_SQRT);
    strudel.mint(account, rewardAmount);
  }

  function setRelayAddress(address _newRelayAddr) external onlyOwner {
    require(_newRelayAddr != address(0), "!newRelayAddr-0");
    relay = IRelay(_newRelayAddr);
  }

  function setNumConfs(uint256 _numConfs) external onlyOwner {
    require(_numConfs > 0, "!newNumConfs-0");
    require(_numConfs < 100, "!newNumConfs-useless");
    numConfs = _numConfs;
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "./IPriceOracle.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract BtcPriceOracle is OwnableUpgradeSafe, IPriceOracle {
  using FixedPoint for *;

  uint256 public constant PERIOD = 20 minutes;

  event Price(uint256 price);

  address public immutable weth;
  address public immutable factory;

  // governance params
  address[] public referenceTokens;

  // working memory
  mapping(address => uint256) public priceCumulativeLast;
  uint32 public blockTimestampLast;
  FixedPoint.uq112x112 public priceAverage;

  constructor(
    address _factory,
    address _weth,
    address[] memory tokenizedBtcs
  ) public {
    __Ownable_init();
    factory = _factory;
    weth = _weth;
    for (uint256 i = 0; i < tokenizedBtcs.length; i++) {
      _addPair(tokenizedBtcs[i], _factory, _weth);
    }
  }

  function _addPair(
    address tokenizedBtc,
    address _factory,
    address _weth
  ) internal {
    // check inputs
    require(tokenizedBtc != address(0), "zero token");
    require(priceCumulativeLast[tokenizedBtc] == 0, "already known");

    // check pair
    IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(_factory, _weth, tokenizedBtc));
    require(address(pair) != address(0), "no pair");
    uint112 reserve0;
    uint112 reserve1;
    (reserve0, reserve1, ) = pair.getReserves();
    require(reserve0 != 0 && reserve1 != 0, "BtcOracle: NO_RESERVES"); // ensure that there's liquidity in the pair

    // fetch the current accumulated price value (0 / 1)
    priceCumulativeLast[tokenizedBtc] = (pair.token0() == _weth)
      ? pair.price1CumulativeLast()
      : pair.price0CumulativeLast();
    // add to storage
    referenceTokens.push(tokenizedBtc);
  }

  function update() external {
    uint32 blockTimestamp;
    uint224 priceSum = 0;
    for (uint256 i = 0; i < referenceTokens.length; i++) {
      address tokenizedBtc = referenceTokens[i];
      IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, weth, tokenizedBtc));
      uint256 price0Cumulative;
      uint256 price1Cumulative;
      (price0Cumulative, price1Cumulative, blockTimestamp) = UniswapV2OracleLibrary
        .currentCumulativePrices(address(pair));
      uint256 priceCumulative = (pair.token0() == weth) ? price1Cumulative : price0Cumulative;
      uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

      // ensure that at least one full period has passed since the last update
      require(timeElapsed >= PERIOD, "ExampleOracleSimple: PERIOD_NOT_ELAPSED");

      // overflow is desired, casting never truncates
      // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
      uint256 price = (priceCumulative - priceCumulativeLast[tokenizedBtc]) / timeElapsed;
      emit Price(price);
      priceSum += FixedPoint.uq112x112(uint224(price))._x;

      priceCumulativeLast[tokenizedBtc] = priceCumulative;
    }
    // TODO: use weights
    // TODO: use geometric
    priceAverage = FixedPoint.uq112x112(priceSum).div(uint112(referenceTokens.length));
    blockTimestampLast = blockTimestamp;
  }

  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountIn) external view override returns (uint256 amountOut) {
    require(referenceTokens.length > 0, "nothing to track");
    return priceAverage.mul(amountIn / 10**10).decode144();
  }

  // governance functions
  function addPair(address tokenizedBtc) external onlyOwner {
    _addPair(tokenizedBtc, factory, weth);
  }

  function removePair(address tokenizedBtc) external onlyOwner {
    for (uint256 i = 0; i < referenceTokens.length; i++) {
      if (referenceTokens[i] == tokenizedBtc) {
        priceCumulativeLast[tokenizedBtc] = 0;
        referenceTokens[i] = referenceTokens[referenceTokens.length - 1];
        referenceTokens.pop();
        return;
      }
    }
    require(false, "remove not found");
  }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "../VbtcToken.sol";

/// @title  VBTC Token.
/// @notice This is the VBTC ERC20 contract.
contract MockVbtcUpgraded is VbtcToken {
  // TODO: implement
  // bytes calldata _header,
  // bytes calldata _proof,
  // uint256 _index,
  // bytes32 _txid,
  function proofP2FSHAndMint(
    bytes calldata _header,
    bytes calldata _proof,
    uint256 _index,
    bytes32 _txid
  ) external override returns (bool) {
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

/**
 * @author Balancer Labs (and OpenZeppelin)
 * @title Protect against reentrant calls (and also selectively protect view functions)
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {_lock_} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `_lock_` guard, functions marked as
 * `_lock_` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `_lock_` entry
 * points to them.
 *
 * Also adds a _lockview_ modifier, which doesn't create a lock, but fails
 *   if another _lock_ call is in progress
 */
contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() internal {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `_lock_` function from another `_lock_`
   * function is not supported. It is possible to prevent this from happening
   * by making the `_lock_` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier lock() {
    // On the first call to _lock_, _notEntered will be true
    require(_status != _ENTERED, "ERR_REENTRY");

    // Any calls to _lock_ after this point will fail
    _status = _ENTERED;
    _;
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Also add a modifier that doesn't create a lock, but protects functions that
   *      should not be called while a _lock_ function is running
   */
  modifier viewlock() {
    require(_status != _ENTERED, "ERR_REENTRY_VIEW");
    _;
  }
}

pragma solidity 0.6.6;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

pragma solidity 0.6.6;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

pragma solidity 0.6.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity 0.6.6;

interface IWETH9 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address) external view returns (uint256);

  function allowance(address, address) external view returns (uint256);

  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function totalSupply() external view returns (uint256);

  function approve(address guy, uint256 wad) external returns (bool);

  function transfer(address dst, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  }
}