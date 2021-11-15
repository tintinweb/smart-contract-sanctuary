// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ISmartInvest.sol";
import "./ISmartWorld.sol";

contract SmartInvest is ISmartInvest, Context {
  using SafeMath for uint256;

  struct Invest {
    uint256 reward;
    uint256 endTime;
  }

  struct UserStruct {
    uint256 id;
    uint256 refID;
    uint256 refAmounts;
    uint256 refPercent;
    uint256 latestWithdraw;
    Invest[] invest;
  }

  ISmartWorld internal STT;

  address public STTS;
  address public BTCB;
  uint256 private PERIOD_HOURS = 17520;
  uint256 private PERIOD_TIMES = 17520 hours;
  uint256 private MINIMUM_INVEST = 500000;
  uint256 private MAXIMUM_INVEST = 5000000;

  uint256 public userID = 1;
  mapping(address => UserStruct) public users;
  mapping(uint256 => address) private userList;

  constructor(address stt) {
    STT = ISmartWorld(stt);
    STTS = STT.STTS();
    BTCB = STT.BTCB();
    users[_msgSender()].id = userID;
    users[_msgSender()].refID = 0;
    users[_msgSender()].latestWithdraw = block.timestamp.sub(1 hours);
    users[_msgSender()].invest.push(Invest(0, block.timestamp));
    userList[userID] = _msgSender();
  }

  function totalReward(uint256 value) public view override returns (uint256) {
    return value.div(5).mul(2).div(STT.sttPrice()).mul(10**8);
  }

  function hourlyReward(uint256 value) public view override returns (uint256) {
    return totalReward(value).div(PERIOD_HOURS);
  }

  function hoursBetween(uint256 time1, uint256 time2) internal pure returns (uint256) {
    return time1.sub(time2).div(1 hours);
  }

  function maxPercent() public view override returns (uint256) {
    uint256 controller = STT.totalSupply().div(10**16).mul(100);
    uint256 max = 1000 - controller;
    return max < 100 ? 100 : max;
  }

  function calculatePercent(address user, uint256 value)
    public
    view
    override
    returns (uint256)
  {
    uint256 userPer = users[user].refPercent;
    uint256 maxPer = maxPercent();
    if (userExpired(user)) userPer = 0;
    if (userPer > maxPer) return userPer;
    uint256 percent = userPer.add(value.mul(maxPer).div(MAXIMUM_INVEST));
    return percent > maxPer ? maxPer : percent;
  }

  function investBnb(address referrer) public payable override returns (bool) {
    require(users[_msgSender()].id == 0, "Error::Investment, User exist!");
    require(users[referrer].id > 0, "Error::Investment, Referrer does not exist!");
    uint256 satoshi = STT.bnbToSatoshi(msg.value);
    require(satoshi >= MINIMUM_INVEST, "Error::Investment, Incorrect Value!");
    require(
      STT.deposit{value: msg.value}(_msgSender(), msg.value),
      "Error::Investment, Deposit failed!"
    );
    return registerUser(referrer, satoshi, false);
  }

  function investStts(address referrer, uint256 value) public override returns (bool) {
    require(users[_msgSender()].id == 0, "Error::Investment, User exist!");
    require(users[referrer].id > 0, "Error::Investment, Referrer does not exist!");
    uint256 satoshi = STT.sttsToSatoshi(value);
    require(satoshi >= MINIMUM_INVEST, "Error::Investment, Incorrect Value!");
    require(STT.depositToken(STTS, _msgSender(), value), "Error::Investment, Deposit failed!");
    return registerUser(referrer, satoshi, true);
  }

  function investBtcb(address referrer, uint256 value) public override returns (bool) {
    require(users[_msgSender()].id == 0, "Error::Investment, User exist!");
    require(users[referrer].id > 0, "Error::Investment, Referrer does not exist!");
    uint256 satoshi = STT.btcToSatoshi(value);
    require(satoshi >= MINIMUM_INVEST, "Error::Investment, Incorrect Value!");
    require(STT.depositToken(BTCB, _msgSender(), value), "Error::Investment, Deposit failed!");
    return registerUser(referrer, satoshi, false);
  }

  function registerUser(
    address referrer,
    uint256 value,
    bool withStts
  ) internal returns (bool) {
    uint256 refID = users[referrer].id;
    userID++;
    userList[userID] = _msgSender();
    users[_msgSender()].id = userID;
    users[_msgSender()].refID = refID;
    users[_msgSender()].invest.push(
      Invest(hourlyReward(value), block.timestamp.add(PERIOD_TIMES))
    );
    users[_msgSender()].latestWithdraw = block.timestamp.sub(1 hours);
    uint256 refValue = withStts ? value.mul(125).div(100) : value;
    users[_msgSender()].refPercent = calculatePercent(_msgSender(), refValue);
    payReferrer(users[_msgSender()].id, totalReward(value));
    emit RegisterUser(_msgSender(), userList[refID], value);
    return true;
  }

  function updateBnb() public payable override returns (bool) {
    require(users[_msgSender()].id > 0, "Error::Investment, User not exist!");
    uint256 satoshi = STT.bnbToSatoshi(msg.value);
    require(satoshi >= MINIMUM_INVEST, "Error::Investment, Incorrect Value!");
    require(
      STT.deposit{value: msg.value}(_msgSender(), msg.value),
      "Error::Investment, Deposit failed!"
    );
    return updateUser(satoshi, false);
  }

  function updateStts(uint256 value) public override returns (bool) {
    require(users[_msgSender()].id > 0, "Error::Investment, User not exist!");
    uint256 satoshi = STT.sttsToSatoshi(value);
    require(satoshi >= MINIMUM_INVEST, "Error::Investment, Incorrect Value!");
    require(STT.depositToken(STTS, _msgSender(), value), "Error::Investment, Deposit failed!");
    return updateUser(satoshi, true);
  }

  function updateBtcb(uint256 value) public override returns (bool) {
    require(users[_msgSender()].id > 0, "Error::Investment, User not exist!");
    uint256 satoshi = STT.btcToSatoshi(value);
    require(satoshi >= MINIMUM_INVEST, "Error::Investment, Incorrect Value!");
    require(STT.depositToken(BTCB, _msgSender(), value), "Error::Investment, Deposit failed!");
    return updateUser(satoshi, false);
  }

  function updateUser(uint256 value, bool withStts) private returns (bool) {
    uint256 refValue = withStts ? value.mul(125).div(100) : value;
    users[_msgSender()].refPercent = calculatePercent(_msgSender(), refValue);

    if (userExpired(_msgSender())) {
      users[_msgSender()].invest.push(users[_msgSender()].invest[0]);
      users[_msgSender()].invest[0].reward = hourlyReward(value);
      users[_msgSender()].invest[0].endTime = block.timestamp.add(PERIOD_TIMES);
    } else {
      users[_msgSender()].invest.push(
        Invest(hourlyReward(value), block.timestamp.add(PERIOD_TIMES))
      );
    }
    payReferrer(users[_msgSender()].id, totalReward(value));
    emit UpdateUser(_msgSender(), value);
    return true;
  }

  function payReferrer(uint256 lastRefId, uint256 value) private {
    for (uint256 i = 0; i < 100; i++) {
      uint256 refParentId = users[userList[lastRefId]].refID;
      address userAddress = userList[refParentId];
      if (users[userAddress].id > 0 && !userExpired(userAddress)) {
        uint256 userReward = value.mul(users[userAddress].refPercent).div(10000);
        users[userAddress].refAmounts = users[userAddress].refAmounts.add(userReward);
      }
      if (refParentId == 0) break;
      lastRefId = refParentId;
    }
  }

  function withdrawInterest() public override returns (bool) {
    (uint256 hourly, uint256 referrals, uint256 savedTime) = calculateInterest(_msgSender());

    require(
      STT.payWithStt(_msgSender(), hourly.add(referrals)),
      "Error::Investment, Withdraw failed!"
    );

    users[_msgSender()].refAmounts = users[_msgSender()].refAmounts.sub(referrals);
    users[_msgSender()].latestWithdraw = savedTime;

    emit WithdrawInterest(_msgSender(), hourly, referrals);
    return true;
  }

  function calculateInterest(address user)
    public
    view
    override
    returns (
      uint256 hourly,
      uint256 referral,
      uint256 requestTime
    )
  {
    require(users[user].id > 0, "Error::Investment, User not exist!");
    requestTime = block.timestamp;
    (, , , uint256 satoshi) = userBalances(user);
    require(satoshi >= MINIMUM_INVEST, "Error::Investment, User dosen't have enough value!");

    referral = users[user].refAmounts;

    if (users[user].latestWithdraw <= requestTime) hourly = calculateHourly(user, requestTime);

    return (hourly, referral, requestTime);
  }

  function calculateHourly(address sender, uint256 time)
    internal
    view
    returns (uint256 hourly)
  {
    for (uint16 i; i < users[sender].invest.length; i++) {
      uint256 endTime = users[sender].invest[i].endTime;
      uint256 latestWithdraw = users[sender].latestWithdraw;
      if (latestWithdraw < endTime) {
        uint256 userHours = hoursBetween(time, latestWithdraw);
        if (userHours > PERIOD_HOURS) userHours = PERIOD_HOURS;
        hourly = hourly.add(userHours.mul(users[sender].invest[i].reward));
      }
    }
  }

  function userBalances(address user)
    public
    view
    override
    returns (
      uint256 bnb,
      uint256 btcb,
      uint256 stts,
      uint256 satoshi
    )
  {
    (, bnb, satoshi) = STT.userBalances(user, address(this));
    stts = STT.userTokens(user, address(this), STTS);
    btcb = STT.userTokens(user, address(this), BTCB);
  }

  function userDepositNumber(address user) public view override returns (uint256) {
    return users[user].invest.length;
  }

  function userDepositDetails(address user, uint256 index)
    public
    view
    override
    returns (uint256 reward, uint256 endTime)
  {
    reward = users[user].invest[index].reward;
    endTime = users[user].invest[index].endTime;
  }

  function userExpireTime(address user) public view override returns (uint256) {
    return users[user].invest[0].endTime;
  }

  function userExpired(address user) public view override returns (bool) {
    if (users[user].invest.length > 0) {
      return userExpireTime(user) <= block.timestamp;
    } else return true;
  }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmartInvest {
  event UpdateUser(address indexed user, uint256 value);
  event WithdrawInterest(address indexed user, uint256 hourly, uint256 referrals);
  event RegisterUser(address indexed user, address indexed referrer, uint256 value);

  function totalReward(uint256 value) external view returns (uint256);

  function hourlyReward(uint256 value) external view returns (uint256);

  function maxPercent() external view returns (uint256);

  function calculatePercent(address user, uint256 value) external view returns (uint256);

  function investBnb(address referrer) external payable returns (bool);

  function investStts(address referrer, uint256 value) external returns (bool);

  function investBtcb(address referrer, uint256 value) external returns (bool);

  function updateBnb() external payable returns (bool);

  function updateStts(uint256 value) external returns (bool);

  function updateBtcb(uint256 value) external returns (bool);

  function withdrawInterest() external returns (bool);

  function calculateInterest(address user)
    external
    view
    returns (
      uint256 hourly,
      uint256 referral,
      uint256 requestTime
    );

  function userBalances(address user)
    external
    view
    returns (
      uint256 bnb,
      uint256 btcb,
      uint256 stts,
      uint256 satoshi
    );

  function userDepositNumber(address user) external view returns (uint256);

  function userDepositDetails(address user, uint256 index)
    external
    view
    returns (uint256 reward, uint256 endTime);

  function userExpireTime(address user) external view returns (uint256);

  function userExpired(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmartWorld {
  function sttPrice() external view returns (uint256);

  function STTS() external view returns (address);

  function BTCB() external view returns (address);

  function totalSupply() external view returns (uint256);

  function totalSatoshi()
    external
    view
    returns (
      uint256 stts,
      uint256 btc,
      uint256 bnb
    );

  function totalBalances()
    external
    view
    returns (
      uint256 stts,
      uint256 btc,
      uint256 bnb
    );

  function btcToSatoshi(uint256 value_) external view returns (uint256);

  function bnbToSatoshi(uint256 value_) external view returns (uint256);

  function sttsToSatoshi(uint256 value_) external view returns (uint256);

  function btcToBnbPrice() external view returns (uint256);

  function sttsToBnb(uint256 value_) external view returns (uint256);

  function sttsToBnbPrice() external view returns (uint256);

  function userBalances(address user_, address contract_)
    external
    view
    returns (
      bool isActive,
      uint256 bnb,
      uint256 satoshi
    );

  function userTokens(
    address token_,
    address user_,
    address contract_
  ) external view returns (uint256);

  function activation(address sender_, uint256 airDrop_) external returns (bool);

  function deposit(address sender_, uint256 value_) external payable returns (bool);

  function withdraw(address payable reciever_, uint256 interest_) external returns (bool);

  function depositToken(
    address token_,
    address spender_,
    uint256 value_
  ) external returns (bool);

  function withdrawToken(
    address token_,
    address reciever_,
    uint256 interest_
  ) external returns (bool);

  function payWithStt(address reciever_, uint256 interest_) external returns (bool);

  function burnWithStt(address from_, uint256 amount_) external returns (bool);
}

