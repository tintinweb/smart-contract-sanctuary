/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

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

interface IBEP20 {
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

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
}

interface IFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external;

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IWETH {
  function deposit() external payable;
}

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
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
  uint8 constant REQUIRED_UNLOCKS = 2;

  address private _owner;

  address[] public multisigWallets;
  mapping (address => mapping (string => uint256)) public timelocks;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event MultisigWalletAdded(address indexed multisigWallet);
  event MultisigWalletRemoved(address indexed multisigWallet);
  event Unlocking(string indexed id, uint256 unlockTimestamp);
  event Locked(string indexed id);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  modifier onlyMultisigWallet() {
    bool authorized = false;

    for (uint8 i = 0; i < multisigWallets.length; i++) {
      if (multisigWallets[i] == _msgSender()) {
        authorized = true;
        break;
      }
    }

    require(authorized, "Multisig: caller is not a multisig wallet");
    _;
  }

  modifier onlyUnlocked(string memory id) {
    uint8 count = 0;

    for (uint8 i = 0; i < multisigWallets.length; i++) {
      uint256 timelock = timelocks[multisigWallets[i]][id];

      if (timelock != 0 && timelock <= block.timestamp) {
        count++;
      }
    }

    require(count >= REQUIRED_UNLOCKS, "Timelock: action is not unlocked by enough multisig wallets");
    _;

    for (uint256 i = 0; i < multisigWallets.length; i++) {
      timelocks[multisigWallets[i]][id] = 0;
    }

    emit Locked(id);
  }

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
    multisigWallets = new address[](3);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner onlyUnlocked("OWNERSHIP") {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner onlyUnlocked("OWNERSHIP") {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function addMultisigWallet(address multisigWallet) public onlyOwner {
    for (uint8 i = 0; i < multisigWallets.length; i++) {
      if (multisigWallets[i] == address(0)) {
        multisigWallets[i] = multisigWallet;
        emit MultisigWalletAdded(multisigWallet);
        return;
      }
    }

    revert("Multisig: maximum reached");
  }

  function removeMultisigWallet() external onlyMultisigWallet {
    for (uint8 i = 0; i < multisigWallets.length; i++) {
      if (multisigWallets[i] == _msgSender()) {
        multisigWallets[i] = address(0);
        emit MultisigWalletRemoved(_msgSender());
        return;
      }
    }
  }

  function unlocking(string memory id) private view returns (bool) {
    uint8 count = 0;

    for (uint8 i = 0; i < multisigWallets.length; i++) {
      if (timelocks[multisigWallets[i]][id] != 0) {
        count++;
      }
    }

    return count >= REQUIRED_UNLOCKS;
  }

  function unlock(string memory id) external onlyMultisigWallet {
    uint256 unlockTimestamp = block.timestamp + 3 minutes;
    timelocks[_msgSender()][id] = unlockTimestamp < block.timestamp ? 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff : unlockTimestamp;

    if (unlocking(id)) {
      emit Unlocking(id, unlockTimestamp);
    }
  }

  function lock(string memory id) external onlyMultisigWallet {
    timelocks[_msgSender()][id] = 0;

    if (!unlocking(id)) {
      emit Locked(id);
    }
  }
}

contract Booster is Ownable, IBEP20 {
  using SafeMath for uint256;

  address constant ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

  string constant NAME = "Booster";
  string constant SYMBOL = "BOOST";
  uint8 constant DECIMALS = 18;
  uint256 constant TOTAL_SUPPLY = 10 ** uint256(DECIMALS) * 1e15; // 1 Quadtrillion

  address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 public holders;
  mapping (address => uint256) public lastTransfer;
  bool public tradingEnabled;

  address private _pair;

  address public signer;
  address public dev;
  address public rewardSetter;
  address public rewardToken;
  address[] private _rewardTokens;
  mapping (address => uint256) public totalRewards;
  mapping (address => uint256) private _accumulatedRewardPerShare;
  mapping (address => mapping (address => uint256)) private _rewards;
  mapping (address => mapping (address => uint256)) private _rewardDebts;
  mapping (address => mapping (address => uint256)) public claimNonce;

  event TradingEnabled(uint256 timestamp);
  event SignerUpdated(address indexed previousSigner, address indexed newSigner);
  event DevUpdated(address indexed previousDev, address indexed newDev);
  event RewardSetterUpdated(address indexed previousRewardSetter, address indexed newRewardSetter);
  event RewardTokenUpdated(address indexed previousRewardToken, address indexed newRewardToken);
  event RewardClaimed(address indexed account, address indexed rewardToken, uint256 userReward, uint256 devReward);

  constructor() {
    _updateBalance(_msgSender(), TOTAL_SUPPLY, true);
    emit Transfer(address(0), _msgSender(), TOTAL_SUPPLY);
    _transfer(_msgSender(), BURN_ADDRESS, TOTAL_SUPPLY.div(2));

    IRouter router = IRouter(ROUTER);
    _pair = IFactory(router.factory()).createPair(address(this), router.WETH());

    signer = 0x05812C5691649ca4e26642c9233A3bf428d4F72d;
    dev = _msgSender();
    rewardSetter = _msgSender();
    rewardToken = address(this);

    _rewardTokens = [
      rewardToken,
      router.WETH(),
      0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7 // BUSD
    ];
  }

  receive() external payable { }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view override returns (address) {
    return owner();
  }

  /**
  * @dev Returns the token name.
  */
  function name() external pure override returns (string memory) {
    return NAME;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external pure override returns (string memory) {
    return SYMBOL;
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external pure override returns (uint8) {
    return DECIMALS;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external pure override returns (uint256) {
    return TOTAL_SUPPLY;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
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
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    uint256 minBalance = 10 ** uint256(DECIMALS);

    if (_balances[sender].sub(amount, "BEP20: transfer amount exceeds balance") < minBalance) {
      require(_balances[sender] > minBalance, "Booster: 1 BOOST must remain in wallet");
      amount = _balances[sender].sub(minBalance);
    }

    _updateBalance(sender, amount, false);

    if (_balances[_pair] != 0) { // initial liquidity provided
      require(tradingEnabled, "Booster: trading not enabled yet");

      if (sender != address(this) && recipient == _pair) { // address other than this selling
        uint256 fee = amount.div(10); // 10%
        amount = amount.sub(fee);
        _updateBalance(address(this), fee, true);
        emit Transfer(sender, address(this), fee);
        uint256 _reward;
        IRouter router = IRouter(ROUTER);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balance = address(this).balance;
        IWETH weth = IWETH(router.WETH());
        IBEP20 wethToken = IBEP20(router.WETH());

        if (rewardToken == address(this)) {
          uint256 swap = fee.div(2);
          _reward = fee.sub(swap);
          _approve(address(this), ROUTER, swap);
          router.swapExactTokensForETHSupportingFeeOnTransferTokens(swap, router.getAmountsOut(swap, path)[1].mul(85).div(100), path, address(this), block.timestamp);
          balance = address(this).balance.sub(balance);
          weth.deposit{ value: balance }();
          wethToken.transfer(_pair, balance);
        } else {
          _approve(address(this), ROUTER, fee);
          router.swapExactTokensForETHSupportingFeeOnTransferTokens(fee, router.getAmountsOut(fee, path)[1].mul(85).div(100), path, address(this), block.timestamp);
          balance = address(this).balance.sub(balance);
          uint256 liquidity = balance.div(2);
          balance = balance.sub(liquidity);
          weth.deposit{ value: liquidity }();
          wethToken.transfer(_pair, liquidity);

          if (rewardToken == router.WETH()) {
            _reward = balance;
          } else {
            IBEP20 token = IBEP20(rewardToken);
            _reward = token.balanceOf(address(this));
            path[0] = router.WETH();
            path[1] = rewardToken;
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: balance }(router.getAmountsOut(balance, path)[1].mul(95).div(100), path, address(this), block.timestamp);
            _reward = token.balanceOf(address(this)).sub(_reward);
          }
        }

        totalRewards[rewardToken] = totalRewards[rewardToken].add(_reward);
        uint256 supply = TOTAL_SUPPLY.sub(_balances[BURN_ADDRESS]).sub(_balances[address(this)]).sub(_balances[_pair]).sub(amount);

        if (supply != 0) {
          _accumulatedRewardPerShare[rewardToken] = _accumulatedRewardPerShare[rewardToken].add(_reward.mul(1e18).div(supply));
        }
      }
    }

    _updateBalance(recipient, amount, true);
    emit Transfer(sender, recipient, amount);
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
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _updateBalance(address account, uint256 amount, bool add) private {
    if (account != BURN_ADDRESS && account != address(this) && account != _pair) {
      for (uint8 i = 0; i < _rewardTokens.length; i++) {
        _rewards[account][_rewardTokens[i]] = _rewards[account][_rewardTokens[i]].add(_accumulatedRewardPerShare[_rewardTokens[i]].mul(_balances[account]).div(1e18).sub(_rewardDebts[account][_rewardTokens[i]]));
      }
    }

    if (amount != 0) {
      if (add) {
        if (_balances[account] == 0) {
          holders = holders.add(1);
        }

        _balances[account] = _balances[account].add(amount);

        if (lastTransfer[account] == 0) {
          lastTransfer[account] = block.timestamp;
        }
      } else {
        _balances[account] = _balances[account].sub(amount);
        lastTransfer[account] = block.timestamp;
      }
    }

    if (account != BURN_ADDRESS && account != address(this) && account != _pair) {
      for (uint8 i = 0; i < _rewardTokens.length; i++) {
        _rewardDebts[account][_rewardTokens[i]] = _accumulatedRewardPerShare[_rewardTokens[i]].mul(_balances[account]).div(1e18);
      }
    }
  }

  function enableTrading() external onlyOwner {
    tradingEnabled = true;
    emit TradingEnabled(block.timestamp);
  }

  function withdrawLiquidity() external onlyOwner onlyUnlocked("LIQUIDITY") {
    IBEP20 pair = IBEP20(_pair);
    uint256 amount = pair.balanceOf(address(this));
    pair.transfer(_msgSender(), amount);
  }

  function setSigner(address _signer) external onlyOwner onlyUnlocked("SIGNER") {
    emit SignerUpdated(signer, _signer);
    signer = _signer;
  }

  function setDev(address _dev) external onlyOwner onlyUnlocked("DEV") {
    emit DevUpdated(dev, _dev);
    dev = _dev;
  }

  function setRewardSetter(address _rewardSetter) external onlyOwner onlyUnlocked("REWARD_SETTER") {
    emit RewardSetterUpdated(rewardSetter, _rewardSetter);
    rewardSetter = _rewardSetter;
  }

  function setRewardToken(address _rewardToken) external {
    require(_msgSender() == rewardSetter, "Booster: caller is not the reward setter");
    bool valid;

    for (uint8 i = 0; i < _rewardTokens.length; i++) {
      if (_rewardTokens[i] == _rewardToken) {
        valid = true;
        break;
      }
    }

    require(valid, "Booster: invalid reward token");
    emit RewardTokenUpdated(rewardToken, _rewardToken);
    rewardToken = _rewardToken;
  }

  function reward(address account, address _rewardToken) public view returns (uint256) {
    if (account == BURN_ADDRESS || account == address(this) || account == _pair) {
      return 0;
    }

    return _rewards[account][_rewardToken].add(_accumulatedRewardPerShare[_rewardToken].mul(_balances[account]).div(1e18).sub(_rewardDebts[account][_rewardToken]));
  }

  function claimReward(address _rewardToken, uint8 level, uint256 nonce, bytes memory signature) external {
    if (signature.length == 0) {
      level = 50;
    } else {
      require(signature.length == 65, "Booster: invalid signature length");
      bytes32 r;
      bytes32 s;
      uint8 v;

      assembly {
        r := mload(add(signature, 32))
        s := mload(add(signature, 64))
        v := byte(0, mload(add(signature, 96)))
      }

      require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_msgSender(), _rewardToken, level, nonce)))), v, r, s) == signer, "Booster: invalid signature");
      require(nonce == claimNonce[_msgSender()][_rewardToken] + 1, "Booster: claim nonce must increment");
      claimNonce[_msgSender()][_rewardToken] = nonce;
    }

    uint256 _reward = reward(_msgSender(), _rewardToken);
    require(_reward != 0, "Booster: no reward to claim");
    _rewards[_msgSender()][_rewardToken] = _reward;
    _rewardDebts[_msgSender()][_rewardToken] = _accumulatedRewardPerShare[_rewardToken].mul(_balances[_msgSender()]).div(1e18);
    IRouter router = IRouter(ROUTER);
    uint256 balance = _rewardToken == router.WETH() ? address(this).balance : IBEP20(_rewardToken).balanceOf(address(this));

    if (_reward > balance) {
      _reward = balance;
    }

    _rewards[_msgSender()][_rewardToken] = _rewards[_msgSender()][_rewardToken].sub(_reward);
    uint256 userReward = _reward.mul(level).div(100);
    uint256 devReward = _reward.sub(userReward);

    if (_rewardToken == router.WETH()) {
      if (userReward != 0) {
        (bool success, ) = _msgSender().call{ value: userReward }("");
        require(success, "Booster: sending BNB to user failed");
      }

      if (devReward != 0) {
        (bool success, ) = dev.call{ value: devReward }("");
        require(success, "Booster: sending BNB to dev failed");
      }
    } else {
      IBEP20 token = IBEP20(_rewardToken);

      if (userReward != 0) {
        token.transfer(_msgSender(), userReward);
      }

      if (devReward != 0) {
        token.transfer(dev, devReward);
      }
    }

    emit RewardClaimed(_msgSender(), _rewardToken, userReward, devReward);
  }
}