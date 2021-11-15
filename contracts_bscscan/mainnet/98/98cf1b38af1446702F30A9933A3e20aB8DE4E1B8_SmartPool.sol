// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapRouter.sol";
import "./ISmartWorld.sol";
import "./ISmartPool.sol";
import "./Secure.sol";

contract SmartPool is Secure, ISmartPool {
  using SafeMath for uint256;

  struct UserStruct {
    address referrer;
    uint256 liquidity;
    uint256 totalStts;
    uint256 refAmounts;
    uint256 latestWithdraw;
    uint256[] startTimes;
  }

  ISmartWorld internal SmartWorld;
  IUniswapRouter internal UniswapRouter;

  address internal constant STT = 0xbBe476b50D857BF41bBd1EB02F777cb9084C1564;
  address internal constant STTS = 0x88469567A9e6b2daE2d8ea7D8C77872d9A0d43EC;
  address internal constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address internal constant LPTOKEN = 0x45Ee99347E4E3946bE250fEC8172401965E2DFB3;

  uint256 public MIN_PERCENT = 50;
  uint256 public PERIOD_DAYS = 37;
  uint256 public PERIOD_TIMES = 37 days;
  uint256 internal MAX_PERCENT = 10000;
  uint256 internal MINIMUM_STTS = 175000000;
  uint40[3] internal PERCENTAGE = [2000_00000000, 1000_00000000, 500_00000000];

  mapping(address => UserStruct) public users;
  mapping(address => bool) public lockedUsers;

  constructor() {
    SmartWorld = ISmartWorld(STT);
    UniswapRouter = IUniswapRouter(ROUTER);
    owner = _msgSender();
    preApprove();
    users[_msgSender()].referrer = STT;
  }

  function transferBNB() external onlyOwner {
    uint256 value = address(this).balance;
    SmartWorld.deposit{value: value}(owner, value);
  }

  function changePercent(uint256 percent) external onlyOwner {
    MIN_PERCENT = percent;
  }

  function preApprove() public onlyOwner {
    require(
      IERC20(STTS).approve(ROUTER, type(uint256).max),
      "Error::SmartPool, Approve failed!"
    );
  }

  function maxStts() public view override returns (uint256 stts) {
    for (uint256 i = SmartWorld.sttPrice(); i > 0; i--) {
      if ((2**i).mod(i) == 0) return i.mul(MINIMUM_STTS);
    }
  }

  function calulateBnb(uint256 stts) public view override returns (uint256 bnb) {
    bnb = SmartWorld.sttsToBnb(stts);
  }

  function freezePrice() public view override returns (uint256 stts, uint256 bnb) {
    stts = maxStts();
    bnb = calulateBnb(stts);
  }

  function updatePrice(address user) public view override returns (uint256 stts, uint256 bnb) {
    uint256 _userStts = users[user].totalStts;
    uint256 _maxStts = maxStts();
    if (_maxStts > _userStts) {
      stts = _maxStts.sub(_userStts);
      bnb = calulateBnb(stts);
    }
  }

  function priceInfo(uint256 stts, uint256 percent)
    external
    view
    override
    returns (
      uint256 bnb,
      uint256 minStts,
      uint256 minBnb,
      uint256 slippage
    )
  {
    bnb = calulateBnb(stts);
    slippage = percent > 0 ? percent : MIN_PERCENT;
    minStts = stts.mul(MAX_PERCENT.sub(slippage)).div(MAX_PERCENT);
    minBnb = bnb.mul(MAX_PERCENT.sub(slippage)).div(MAX_PERCENT);
  }

  function userFreezeInfo(address user, uint256 percent)
    external
    view
    override
    returns (
      uint256 stts,
      uint256 bnb,
      uint256 minStts,
      uint256 minBnb,
      uint256 slippage
    )
  {
    (stts, bnb) = user != address(0) ? updatePrice(user) : freezePrice();
    slippage = percent > 0 ? percent : MIN_PERCENT;
    minStts = stts.mul(MAX_PERCENT.sub(slippage)).div(MAX_PERCENT);
    minBnb = bnb.mul(MAX_PERCENT.sub(slippage)).div(MAX_PERCENT);
  }

  function userUnfreezeInfo(address user, uint256 percent)
    external
    view
    override
    returns (
      uint256 stts,
      uint256 bnb,
      uint256 minStts,
      uint256 minBnb,
      uint256 slippage
    )
  {
    stts = users[user].totalStts;
    bnb = calulateBnb(stts);
    slippage = percent > 0 ? percent : MIN_PERCENT;
    minStts = stts.mul(MAX_PERCENT.sub(slippage)).div(MAX_PERCENT);
    minBnb = bnb.mul(MAX_PERCENT.sub(slippage)).div(MAX_PERCENT);
  }

  function freeze(
    address referrer,
    uint256 amountSTTSMin,
    uint256 amountBNBMin,
    uint256 deadline
  ) external payable override notLocked ensure(deadline) {
    require(users[_msgSender()].referrer == address(0), "Error::SmartPool, User exist!");
    require(users[referrer].referrer != address(0), "Error::SmartPool, Referrer not exist!");

    (uint256 sttsAmount, uint256 bnbAmount) = freezePrice();

    require(
      IERC20(STTS).balanceOf(_msgSender()) >= sttsAmount,
      "Error::SmartPool, Not enough STTS!"
    );

    require(msg.value >= bnbAmount, "Error::SmartPool, Incorrect value!");

    require(
      IERC20(STTS).transferFrom(_msgSender(), address(this), sttsAmount),
      "Error::SmartPool, Transfer failed"
    );

    (, , uint256 liquidity) =
      UniswapRouter.addLiquidityETH{value: bnbAmount}(
        STTS,
        sttsAmount,
        amountSTTSMin,
        amountBNBMin,
        address(this),
        deadline
      );

    SmartWorld.activation(_msgSender(), 0);

    users[_msgSender()].referrer = referrer;
    users[_msgSender()].liquidity = liquidity;
    users[_msgSender()].totalStts = sttsAmount;
    users[_msgSender()].latestWithdraw = block.timestamp.sub(1 days);
    users[_msgSender()].startTimes.push(block.timestamp);

    payReferrer(_msgSender());

    emit Freeze(_msgSender(), referrer, sttsAmount);
  }

  function updateFreeze(
    uint256 amountSTTSMin,
    uint256 amountBNBMin,
    uint256 deadline
  ) external payable override notLocked ensure(deadline) {
    require(!lockedUsers[_msgSender()], "Error::SmartPool, User locked!");
    require(users[_msgSender()].referrer != address(0), "Error::SmartPool, User not exist!");

    (uint256 sttsAmount, uint256 bnbAmount) = updatePrice(_msgSender());

    require(sttsAmount > 0, "Error::SmartPool, Update is not available!");

    require(
      IERC20(STTS).balanceOf(_msgSender()) >= sttsAmount,
      "Error::SmartPool, Not enough STTS!"
    );

    require(msg.value >= bnbAmount, "Error::SmartPool, Incorrect value!");

    require(
      IERC20(STTS).transferFrom(_msgSender(), address(this), sttsAmount),
      "Error::SmartPool, Transfer failed"
    );

    (, , uint256 liquidity) =
      UniswapRouter.addLiquidityETH{value: bnbAmount}(
        STTS,
        sttsAmount,
        amountSTTSMin,
        amountBNBMin,
        address(this),
        deadline
      );

    users[_msgSender()].liquidity = users[_msgSender()].liquidity.add(liquidity);
    users[_msgSender()].totalStts = users[_msgSender()].totalStts.add(sttsAmount);
    users[_msgSender()].startTimes.push(block.timestamp);

    payReferrer(_msgSender());

    emit UpdateFreeze(_msgSender(), sttsAmount);
  }

  function payReferrer(address lastRef) internal {
    for (uint8 i; i < 15; i++) {
      address refParent = users[lastRef].referrer;
      if (refParent == address(0)) break;
      if (users[refParent].totalStts >= maxStts())
        users[refParent].refAmounts = users[refParent].refAmounts.add(
          PERCENTAGE[i < 2 ? i : 2]
        );
      lastRef = refParent;
    }
  }

  function unfreeze(
    uint256 amountSTTSMin,
    uint256 amountBNBMin,
    uint256 deadline
  ) external override ensure(deadline) {
    require(userExpired(_msgSender()), "Error::SmartPool, User is not expired!");

    uint256 liquidity = users[_msgSender()].liquidity;

    require(liquidity > 0, "Error::SmartPool, User dosent have value!");

    require(IERC20(LPTOKEN).approve(ROUTER, liquidity), "Error::SmartPool, Approve failed!");

    require(withdrawInterest(), "Error::SmartPool, Withdraw failed!");

    users[_msgSender()].liquidity = 0;
    users[_msgSender()].totalStts = 0;
    lockedUsers[_msgSender()] = true;

    (uint256 amountToken, uint256 amountBNB) =
      UniswapRouter.removeLiquidityETH(
        STTS,
        liquidity,
        amountSTTSMin,
        amountBNBMin,
        _msgSender(),
        deadline
      );

    emit Unfreeze(_msgSender(), amountToken, amountBNB);
  }

  function withdrawInterest() public override returns (bool) {
    (uint256 daily, uint256 referrals, uint256 savedTime) = calculateInterest(_msgSender());

    require(
      SmartWorld.payWithStt(_msgSender(), daily.add(referrals)),
      "Error::SmartPool, STT Mine failed!"
    );

    users[_msgSender()].latestWithdraw = savedTime;
    users[_msgSender()].refAmounts = users[_msgSender()].refAmounts.sub(referrals);

    emit WithdrawInterest(_msgSender(), daily, referrals);
    return true;
  }

  function calculateInterest(address user)
    public
    view
    override
    returns (
      uint256 daily,
      uint256 referral,
      uint256 requestTime
    )
  {
    require(users[user].referrer != address(0), "Error::SmartPool, User not exist!");
    require(users[user].totalStts > 0, "Error::SmartPool, User dosen't have value!");

    requestTime = block.timestamp;

    referral = users[user].refAmounts;

    if (users[user].latestWithdraw.add(1 days) <= requestTime)
      daily = calculateDaily(user, requestTime);

    return (daily, referral, requestTime);
  }

  function calculateDaily(address sender, uint256 time)
    public
    view
    override
    returns (uint256 daily)
  {
    for (uint16 i; i < users[sender].startTimes.length; i++) {
      uint256 startTime = users[sender].startTimes[i];
      uint256 endTime = startTime.add(PERIOD_TIMES);
      uint256 latestWithdraw = users[sender].latestWithdraw;
      if (latestWithdraw < endTime) {
        if (startTime > latestWithdraw) latestWithdraw = startTime;
        uint256 lastAmount;
        uint256 withdrawDay = daysBetween(time, startTime);
        if (withdrawDay > PERIOD_DAYS) withdrawDay = PERIOD_DAYS;
        if (latestWithdraw > startTime.add(1 days))
          lastAmount = (2**daysBetween(latestWithdraw, startTime)).mul(5);
        daily = daily.add((2**withdrawDay).mul(5).sub(lastAmount));
      }
    }
  }

  function daysBetween(uint256 time1, uint256 time2) internal pure returns (uint256) {
    return time1.sub(time2).div(1 days);
  }

  function userDepositNumber(address user) external view override returns (uint256) {
    return users[user].startTimes.length;
  }

  function userRemainingDays(address user) external view override returns (uint256) {
    if (userExpired(user)) return 0;
    return daysBetween(userExpireTime(user), block.timestamp);
  }

  function userDepositTimes(address user) external view override returns (uint256[] memory) {
    return users[user].startTimes;
  }

  function userExpireTime(address user) public view override returns (uint256) {
    if (users[user].startTimes.length > 0) {
      uint256 lastElement = users[user].startTimes.length.sub(1);
      return users[user].startTimes[lastElement].add(PERIOD_TIMES);
    } else return 0;
  }

  function userExpired(address user) public view override returns (bool) {
    return userExpireTime(user) <= block.timestamp;
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapRouter {
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

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmartWorld {
  function sttPrice() external view returns (uint256);

  function sttsToBnbPrice() external view returns (uint256);

  function sttsToBnb(uint256 value_) external view returns (uint256);

  function deposit(address sender_, uint256 value_) external payable returns (bool);

  function activation(address sender_, uint256 airDrop_) external returns (bool);

  function payWithStt(address reciever_, uint256 interest_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmartPool {
  event WithdrawInterest(address indexed user, uint256 daily, uint256 referrals);
  event Freeze(address indexed user, address indexed referrer, uint256 amount);
  event Unfreeze(address indexed user, uint256 sttsAmount, uint256 bnbAmount);
  event UpdateFreeze(address indexed user, uint256 amount);

  function maxStts() external view returns (uint256);

  function freezePrice() external view returns (uint256 stts, uint256 bnb);

  function updatePrice(address user) external view returns (uint256 stts, uint256 bnb);

  function userFreezeInfo(address user, uint256 percent)
    external
    view
    returns (
      uint256 stts,
      uint256 bnb,
      uint256 minStts,
      uint256 minBnb,
      uint256 slippage
    );

  function userUnfreezeInfo(address user, uint256 percent)
    external
    view
    returns (
      uint256 stts,
      uint256 bnb,
      uint256 minStts,
      uint256 minBnb,
      uint256 slippage
    );

  function priceInfo(uint256 stts, uint256 percent)
    external
    view
    returns (
      uint256 bnb,
      uint256 minStts,
      uint256 minBnb,
      uint256 slippage
    );

  function freeze(
    address referrer,
    uint256 amountSTTSMin,
    uint256 amountBNBMin,
    uint256 deadline
  ) external payable;

  function updateFreeze(
    uint256 amountSTTSMin,
    uint256 amountBNBMin,
    uint256 deadline
  ) external payable;

  function unfreeze(
    uint256 amountSTTSMin,
    uint256 amountBNBMin,
    uint256 deadline
  ) external;

  function calulateBnb(uint256 stts) external view returns (uint256 bnb);

  function withdrawInterest() external returns (bool);

  function calculateInterest(address user)
    external
    view
    returns (
      uint256 daily,
      uint256 referral,
      uint256 requestTime
    );

  function calculateDaily(address sender, uint256 time) external view returns (uint256 daily);

  function userRemainingDays(address user) external view returns (uint256);

  function userDepositNumber(address user) external view returns (uint256);

  function userDepositTimes(address user) external view returns (uint256[] memory);

  function userExpireTime(address user) external view returns (uint256);

  function userExpired(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Secure is Context {
  address public owner;
  bool private locked;

  modifier onlyOwner() {
    require(_msgSender() == owner, "Error::SmartPool, Only from owner!");
    _;
  }

  modifier notLocked() {
    require(!locked, "Error::SmartPool, Deposit is not available!");
    _;
  }

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "Error::SmartPool, Transaction exapired!");
    _;
  }

  function toggleLock() external onlyOwner {
    locked = !locked;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

