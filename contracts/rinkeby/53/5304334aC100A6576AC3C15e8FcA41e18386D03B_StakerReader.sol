// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IStakerData.sol";

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}

contract StakerReader {
  using SafeMath for uint256;

  struct stakerDevData{
    uint256 developerCount;
    uint256 poolCount;
    uint256 remainingToken;
    uint256 tokenEmissionBlockCount;
  }

  function readData(IStakerData _stakerContract) external view returns (stakerDevData memory) {
    IStakerData staker = _stakerContract;
    uint256 getDeveloperCount = staker.getDeveloperCount();
    uint256 getPoolCount = staker.getPoolCount();
    uint256 getRemainingToken = staker.getRemainingToken();
    uint256 tokenEmission = staker.tokenEmissionBlockCount();

    return stakerDevData({
      developerCount: getDeveloperCount,
      poolCount: getPoolCount,
      remainingToken: getRemainingToken,
      tokenEmissionBlockCount: tokenEmission
    });
  }

  struct FarmData {
    IStakerData stakerContract;
    string farmName;
    RewardToken rewardToken;
    PoolToken[] poolTokens;
    UserInfo[] poolUserData;
    uint256 totalTokenStrength;
    uint256 totalPointStrength;
    uint256 currentTokenRate;
    uint256 currentPointRate;
  }

  struct RewardToken {
    string name;
    string symbol;
    address token;
  }

  struct FarmPoint {
    string pointName;
    string pointSymbol;
  }

  struct PoolToken {
    IERC20 poolToken;
    uint256 valueWeth;
    string poolTokenName;
    string poolTokenSymbol;
    uint256 tokenStrength;
    uint256 tokensPerShare;
    uint256 pointStrength;
    uint256 pointsPerShare;
    uint256 lastRewardBlock;
    uint256 poolTotalSupply;
  }

  struct UserInfo {
    uint256 amount;
    uint256 userWalletBalance;
    uint256 tokenPaid;
    uint256 pointPaid;
    uint256 pendingRewards;
    uint256 pendingPoints;
    uint256 userAllowance;
  }

  function getFarmData(address _user, IStakerData _stakercontract, IERC20 _weth) external view returns (FarmData memory) {
    RewardToken memory rToken = _buildRewardToken(_stakercontract);

    PoolToken[] memory pts;
    UserInfo[] memory poolUserData;

    for (uint256 i = 0; i < _stakercontract.getPoolCount(); i++) {
      IERC20Detailed _pt = IERC20Detailed(_stakercontract.poolTokens(i));
      pts[i] = _buildPoolData(_stakercontract, _pt, rToken.token, _weth); //pt;

      if(_user != address(0)){
        poolUserData[i] = _buildUserInfo(_pt, _stakercontract, _user);
      }
    }

    return FarmData({
      stakerContract: _stakercontract,
      farmName: _stakercontract.name(),
      rewardToken: rToken,
      poolUserData: poolUserData,
      poolTokens: pts,
      totalTokenStrength: _stakercontract.totalTokenStrength(),
      totalPointStrength: _stakercontract.totalPointStrength(),
      currentTokenRate: _stakercontract.getTotalEmittedTokens(block.number, block.number + 1),
      currentPointRate: _stakercontract.getTotalEmittedPoints(block.number, block.number + 1)
    });
  }

  function _calcWethValue(IERC20 _weth, IERC20 _pt, IERC20 _ft) internal view returns (uint256) {
    uint256 wethBalance = _weth.balanceOf(address(_ft));
    uint256 lpSupply = _pt.totalSupply();
    return wethBalance.mul(2).mul(1000000).div(lpSupply);
  }

  function _buildRewardToken(IStakerData _stakercontract) internal view returns (RewardToken memory) {
    IERC20Detailed _ft = IERC20Detailed(_stakercontract.token());
    return RewardToken({
      name: _ft.name(),
      token: address(_ft),
      symbol: _ft.symbol()
    });
  }

  function _buildUserInfo(IERC20 _pt, IStakerData _stakercontract, address _user) internal view returns (UserInfo memory) {
    (
      uint256 _amount,
      uint256 _tokenPaid,
      uint256 _pointPaid
    ) = _stakercontract.userInfo(address(_pt), _user);
    return UserInfo({
      amount: _amount,
      userWalletBalance: _pt.balanceOf(_user),
      tokenPaid: _tokenPaid,
      pointPaid: _pointPaid,
      pendingRewards: _stakercontract.getPendingTokens(address(_pt), _user),
      pendingPoints: _stakercontract.getPendingPoints(address(_pt), _user),
      userAllowance: _pt.allowance(_user, address(_stakercontract))
    });
  }

  function _buildPoolData(IStakerData _stakercontract, IERC20Detailed _pt, address rewardToken, IERC20 _weth) internal view returns (PoolToken memory) {
    (
      address _pToken,
      uint256 _tokenStrength,
      uint256 _tokensPerShare,
      uint256 _pointStrength,
      uint256 _pointsPerShare,
      uint256 _lastRewardBlock
    ) = _stakercontract.poolInfo(address(_pt));
    return PoolToken({
      poolToken: _pt,
      valueWeth: _calcWethValue(_weth, _pt, IERC20(rewardToken)),
      poolTokenName: _pt.name(),
      poolTokenSymbol: _pt.symbol(),
      tokenStrength: _tokenStrength,
      tokensPerShare: _tokensPerShare,
      pointStrength: _pointStrength,
      pointsPerShare: _pointsPerShare,
      lastRewardBlock: _lastRewardBlock,
      poolTotalSupply: (address(_pToken) == rewardToken) ? _stakercontract.totalTokenDeposited() : _pt.balanceOf(rewardToken)
    });
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IStakerData {
  function getAvailablePoints ( address _user ) external view returns ( uint256 );
  function getSpentPoints ( address _user ) external view returns ( uint256 );
  function getTotalPoints ( address _user ) external view returns ( uint256 );
  function userPoints ( address ) external view returns ( uint256 );
  function userSpentPoints ( address ) external view returns ( uint256 );

  function canAlterDevelopers (  ) external view returns ( bool );
  function canAlterPointEmissionSchedule (  ) external view returns ( bool );
  function canAlterTokenEmissionSchedule (  ) external view returns ( bool );
  function getDeveloperCount (  ) external view returns ( uint256 );
  function getPoolCount (  ) external view returns ( uint256 );
  function getRemainingToken (  ) external view returns ( uint256 );
  function tokenEmissionBlockCount (  ) external view returns ( uint256 );
  function totalPointStrength (  ) external view returns ( uint256 );
  function totalTokenDeposited (  ) external view returns ( uint256 );
  function totalTokenDisbursed (  ) external view returns ( uint256 );
  function totalTokenStrength (  ) external view returns ( uint256 );
  function pointEmissionBlockCount (  ) external view returns ( uint256 );
  function token (  ) external view returns ( address );
  function name (  ) external view returns ( string memory );

  function getPendingPoints ( address _token, address _user ) external view returns ( uint256 );
  function getPendingTokens ( address _token, address _user ) external view returns ( uint256 );

  function getTotalEmittedPoints ( uint256 _fromBlock, uint256 _toBlock ) external view returns ( uint256 );
  function getTotalEmittedTokens ( uint256 _fromBlock, uint256 _toBlock ) external view returns ( uint256 );

  function tokenEmissionBlocks ( uint256 ) external view returns ( uint256 blockNumber, uint256 rate );
  function pointEmissionBlocks ( uint256 ) external view returns ( uint256 blockNumber, uint256 rate );
  function poolTokens ( uint256 ) external view returns ( address );

  function poolInfo ( address ) external view returns ( address _token, uint256 _tokenStrength, uint256 _tokensPerShare, uint256 _pointStrength, uint256 _pointsPerShare, uint256 _lastRewardBlock );

  function userInfo ( address, address ) external view returns ( uint256 amount, uint256 tokenPaid, uint256 pointPaid );
}

