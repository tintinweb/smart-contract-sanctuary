// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IMeowMining.sol";
import "../../interfaces/IMMeowToken.sol";
import "../../interfaces/IWorker.sol";

interface IMeowAPI1 {
  function ibTokenPrice(address _vault) external view returns (uint256);

  function meowPrice() external view returns (uint256);
}

interface IMeowAPI2 {
  function getVaults() external view returns (address[] memory);
}

interface IMeowAPIPrice {
  function tokenPrice(address _token) external view returns (uint256);

  function lpPrice(address _lp) external view returns (uint256);

  function powerDecimals(uint256 _decimals) external view returns (uint256);
}

contract MeowAPIDashboard {
  using SafeMath for uint256;
  IMeowAPI1 API1;
  IMeowAPI2 API2;
  IMeowMining MEOWMINING;
  IMMeowToken MMEOW;
  IMeowAPIPrice APIPrice;
  address MEOW;

  constructor(
    address meowAPI1,
    address meowAPI2,
    address meowmining,
    address mmeow,
    address meowAPIPrice
  ) public {
    API1 = IMeowAPI1(meowAPI1);
    API2 = IMeowAPI2(meowAPI2);
    MEOWMINING = IMeowMining(meowmining);
    MEOW = IMeowMining(meowmining).meow();
    MMEOW = IMMeowToken(mmeow);
    APIPrice = IMeowAPIPrice(meowAPIPrice);
  }

  
  /// @dev Get position info
  /// @dev split 2 function because :: fix stack to deep
  function PositionInfo(address vaultAddress, uint256 id) public view returns (bytes memory info)
  {
    // (address a,address b,address c, uint256 d, uint256 e, uint256 f) = abi.decode(PositionInfo1(vaultAddress,id) , ( address,address,address,uint256,uint256,uint256 ) );
    // (uint256 g, uint256 h, uint256 i, uint256 j) = abi.decode(PositionInfo2(vaultAddress,id) , ( uint256,uint256,uint256,uint256 ) );
    // info = abi.encode(a,b,c,d,e,f,g,h,i,j);
    IVault vault            = IVault(vaultAddress);
    (address workerAddress,,,,,,,,) = vault.positions(id);
    IWorker worker          = IWorker(workerAddress);
    IUniswapV2Pair lp       = IUniswapV2Pair(worker.lpToken());
    bytes memory info1;
    uint256 lpAmount;
    {
      address token0        = lp.token0();
      address token1        = lp.token1();
      lpAmount      = worker.shareToBalance( worker.shares(id));
      //value in BaseToken
      (uint256 positionValue,  uint256 positionDebt) = vault.positionInfo(id);
      //decimal is 6 because price on USDC
      uint256 priceBasetoken  = APIPrice.tokenPrice(vault.token());
      info1 = abi.encode( lp, token0, token1, lpAmount, positionValue.mul(priceBasetoken).div(10**6), positionDebt.mul(priceBasetoken).div(10**6));
    }
    bytes memory info2;
    {
      uint256 LPtotalsupply   = lp.totalSupply();
      (uint256 reserve0, uint256 reserve1,) = lp.getReserves();
      uint256 assetToken0     = lpAmount.mul(reserve0).div(LPtotalsupply);
      uint256 assetToken1     = lpAmount.mul(reserve1).div(LPtotalsupply);
      uint256 token0Price     = APIPrice.tokenPrice(lp.token0());
      uint256 token1Price     = APIPrice.tokenPrice(lp.token1());
      info2 = abi.encode( assetToken0, assetToken1, token0Price, token1Price);
    }
    info= MergeBytes(info1,info2);
  }

  function MergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
    // Store the length of the first array
    uint alen = a.length;
    // Store the length of BOTH arrays
    uint totallen = alen + b.length;
    // Count the loops required for array a (sets of 32 bytes)
    uint loopsa = (a.length + 31) / 32;
    // Count the loops required for array b (sets of 32 bytes)
    uint loopsb = (b.length + 31) / 32;
    assembly {
        let m := mload(0x40)
        // Load the length of both arrays to the head of the new bytes array
        mstore(m, totallen)
        // Add the contents of a to the array
        for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
        // Add the contents of b to the array
        for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
        mstore(0x40, add(m, add(32, totallen)))
        c := m
    }
  } 


  ///@dev total deposit (on hand, staking)
  function getDeposit(address user) public view returns (bytes memory) {
    //vault
    address[] memory allVaults = API2.getVaults();
    uint256 length = allVaults.length + 1;
    address[] memory token = new address[](length);
    uint256[] memory balance = new uint256[](length);
    uint256[] memory value = new uint256[](length);
    for (uint256 i = 0; i < length - 1; i++) {
      token[i] = allVaults[i];
      //On hand
      uint256 balanceVault = IERC20(allVaults[i]).balanceOf(user);
      balance[i] += balanceVault;
      //Staking
      (uint256 amount, , , , , ) = MEOWMINING.userInfo(IVault(allVaults[i]).meowMiningPoolId(), user);
      balance[i] += amount;

      value[i] = getIbValue(token[i], balance[i]);
    }
    //mmeow
    //on hand
    uint256 lastIndex = length - 1;
    token[lastIndex] = address(MMEOW);
    balance[lastIndex] += MMEOW.balanceOf(user);
    //staking
    (uint256 amount, , , , , ) = MEOWMINING.userInfo(14, user);
    balance[lastIndex] += amount;
    value[lastIndex] = getMMeowValue(balance[lastIndex]);
    return abi.encode(token, balance, value);
  }

  function getIbValue(address _vault, uint256 _amount) internal view returns (uint256) {
    address baseToken = IVault(_vault).token();
    uint256 basePrice = APIPrice.tokenPrice(baseToken);
    uint256 decimals = uint256(IERC20(baseToken).decimals());
    uint256 ibPrice = API1.ibTokenPrice(_vault);
    return _amount.mul(ibPrice).mul(basePrice).div(APIPrice.powerDecimals(decimals.mul(uint256(2))));
  }

  function getMMeowValue(uint256 _amount) internal view returns (uint256) {
    return _amount.mul(mMeowPrice()).div(1e18);
  }

  function mMeowPrice() public view returns (uint256) {
    uint256 mMeowTotal = MMEOW.totalSupply();
    if (mMeowTotal == 0) return 0;
    return IERC20(MEOW).balanceOf(address(MMEOW)).mul(API1.meowPrice()).div(mMeowTotal);
  }

  ///@dev total value and reward of staking in meowmining
  function getStaking(address user) public view returns (bytes memory) {
    uint256 length = MEOWMINING.poolLength();
    address[] memory stakeToken = new address[](length);
    uint256[] memory balance = new uint256[](length);
    uint256[] memory stakeTokeValue = new uint256[](length);
    uint256[] memory reward = new uint256[](length);
    uint256[] memory rewardValue = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      (stakeToken[i], , , ) = MEOWMINING.poolInfo(i);
      (balance[i], , , , , ) = MEOWMINING.userInfo(i, user);
      stakeTokeValue[i] = 0;
      reward[i] = MEOWMINING.pendingMeow(i, user);
      rewardValue[i] = 0;
    }
    return abi.encode(stakeToken, balance, stakeTokeValue, reward, rewardValue);
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
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

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
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IVaultConfig.sol";

interface IVault {
  // Return address of token to deposit to Vault.
  function token() external view returns (address);

  // Return the total token entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  // Return VaultConfig's address of the Vault.
  function config() external view returns (IVaultConfig);

  // Return TotalDebt Value.
  function vaultDebtVal() external view returns (uint256);

  // Return next position id of the Vault.
  function nextPositionID() external view returns (uint256);

  // Return info of the given Position.
  function positions(uint256 id)
    external
    view
    returns (
      address,
      address,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  // Return Token value and debt of the given position. Be careful of unaccrued interests.
  function positionInfo(uint256 id) external view returns (uint256, uint256);

  // Return pool id of borrower MeowMining of this Vault.
  function meowMiningPoolId() external view returns (uint256);

  // Add more token to the Vault.
  function deposit(uint256 amountToken) external payable;

  // Withdraw token from the Vault by burning the share tokens.
  function withdraw(uint256 share) external;

  // Request funds from user through Vault
  function requestFunds(address targetedToken, uint256 amount) external;

  // Return reservePool of Vault.
  function reservePool() external view returns (uint256);
}

pragma solidity 0.6.12;

interface IMeowMining {
  function MAX_DEV_FUND() external view returns (uint256);

  function MAX_MEOW_REWARD() external view returns (uint256);

  function addPool(uint256 _allocPoint, address _stakeToken) external;

  function availableUnlock(uint256 _pid, address _holder) external view returns (uint256);

  function deposit(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external;

  function devaddr() external view returns (address);

  function developmentFund() external view returns (address);

  function emergencyWithdraw(uint256 _pid) external;

  function harvest(uint256 _pid) external;

  function isPoolExist(address) external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function massUpdatePools() external;

  function meow() external view returns (address);

  function meowPerSecond() external view returns (uint256);

  function mintedDevFund() external view returns (uint256);

  function mintedMeowReward() external view returns (uint256);

  function owner() external view returns (address);

  function pendingMeow(uint256 _pid, address _user) external view returns (uint256);

  function poolInfo(uint256)
    external
    view
    returns (
      address stakeToken,
      uint256 allocPoint,
      uint256 lastRewardTime,
      uint256 accMeowPerShare
    );

  function poolLength() external view returns (uint256);

  function preShare() external view returns (uint256);

  function renounceOwnership() external;

  function setDev(address _devaddr) external;

  function setMeowPerSecond(uint256 _meowPerSecond) external;

  function setPool(uint256 _pid, uint256 _allocPoint) external;

  function startTime() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function totalLock() external view returns (uint256);

  function transferOwnership(address newOwner) external;

  function unlock(uint256 _pid) external;

  function updatePool(uint256 _pid) external;

  function userInfo(uint256, address)
    external
    view
    returns (
      uint256 amount,
      uint256 rewardDebt,
      address fundedBy,
      uint256 lockedAmount,
      uint256 lastUnlockTime,
      uint256 lockTo
    );

  function withdraw(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external;

  function withdrawAll(address _for, uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMMeowToken {
  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function burn(uint256 _amount) external;

  function decimals() external view returns (uint8);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  function deposit(address _for, uint256 _amount) external;

  function depositTime() external view returns (uint256);

  function endDeposit() external view returns (uint256);

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function isLockEnd() external view returns (bool);

  function isStart() external view returns (bool);

  function lockTime() external view returns (uint256);

  function meow() external view returns (address);

  function name() external view returns (string memory);

  function owner() external view returns (address);

  function renounceOwnership() external;

  function start() external;

  function startWithdraw() external view returns (uint256);

  function symbol() external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function transferOwnership(address newOwner) external;

  function withdraw(uint256 _share) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../apis/IUniswapV2Router02.sol";

interface IWorker {
  /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;

  /// @dev Re-invest whatever the worker is working on.
  function reinvest() external;

  // Return address of operator of this worker.
  function operator() external view returns (address);

  /// @dev Return the amount of wei to get back if we are to liquidate the position.
  function health(uint256 id) external view returns (uint256);

  /// @dev Liquidate the given position to token. Send all token back to its Vault.
  function liquidate(uint256 id) external;

  /// @dev SetStretegy that be able to executed by the worker.
  function setStrategyOk(address[] calldata strats, bool isOk) external;

  /// @dev Set address that can be reinvest
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

  /// @dev LP token holds by worker
  function lpToken() external view returns (IUniswapV2Pair);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);

  /// @dev Return the reward bounty for calling reinvest operation.
  function reinvestBountyBps() external view returns (uint256);

  /// @dev Return address of router.
  function router() external view returns (IUniswapV2Router02);

  function shareToBalance(uint256 share) external view returns (uint256);

  function shares(uint256 id) external view returns (uint256);
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
pragma solidity 0.6.12;

interface IVaultConfig {
  /// @dev Return minimum BaseToken debt size per position.
  function minDebtSize() external view returns (uint256);

  /// @dev Return the interest rate per year.
  function getInterestRate(
    uint256 debt,
    uint256 floating,
    uint8 decimals
  ) external view returns (uint256);

  /// @dev Return the address of wrapped native token.
  function getWrappedNativeAddr() external view returns (address);

  /// @dev Return the address of wNative relayer.
  function getWNativeRelayer() external view returns (address);

  /// @dev Return the address of MeowMining contract.
  function getMeowMiningAddr() external view returns (address);

  /// @dev Return the address of MMeowFee contract.
  function mMeowFee() external view returns (address);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint256);

  /// @dev Return if the caller is whitelisted.
  function whitelistedCallers(address caller) external view returns (bool);

  /// @dev Return if the caller is whitelisted bot.
  function whitelistedBots(address bot) external view returns (bool);

  /// @dev Return whether the given address is a worker.
  function isWorker(address worker) external view returns (bool);

  /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
  function acceptDebt(address worker) external view returns (bool);

  /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function workFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function killFactor(address worker, uint256 debt) external view returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
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
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}