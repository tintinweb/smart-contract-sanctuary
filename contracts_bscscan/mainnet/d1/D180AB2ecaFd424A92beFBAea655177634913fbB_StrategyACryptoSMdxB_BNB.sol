/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// File: openzeppelin-contracts-2.5.1/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: openzeppelin-contracts-2.5.1/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-contracts-2.5.1/contracts/math/Math.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-contracts-2.5.1/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: openzeppelin-contracts-2.5.1/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

// File: interfaces/yearn/IController.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);
}

// File: contracts/strategies/StrategyACryptoSMdxB_BNB.sol

pragma solidity ^0.5.17;







contract StrategyACryptoSMdxB_BNB {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Math for uint256;

    address public constant rewardToken = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address public constant hmdx = address(0xAEE4164c1ee46ed0bbC34790f1a3d1Fc87796668);
    address public constant mdxBFarmBNB = address(0xDF484250C063C46F2E1F228954F82266CB987D78);
    address public constant mdxSwapFarm = address(0x782395303692aBeD877d2737Aa7982345eB44c11);
    address public constant mdexRouter = address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8);

    address public want;
    address public tokenA;
    address public tokenB;
    uint256 public farmPid;
    address[] public rewardToTokenAPath;

    address public governance;
    address public controller;
    address public strategist;

    uint256 public performanceFee = 2450;
    uint256 public strategistReward = 50;
    uint256 public withdrawalFee = 10;
    uint256 public harvesterReward = 30;
    uint256 public constant FEE_DENOMINATOR = 10000;

    bool public paused;

    bool public enableHarvestMdxSwapFarm;

    constructor(address _governance, address _strategist, address _controller, address _want, address _tokenA, address _tokenB, uint256 _farmPid, address[] memory _rewardToTokenAPath, bool _enableHarvestMdxSwapFarm) public {
        want = _want;
        tokenA = _tokenA;
        tokenB = _tokenB;
        farmPid = _farmPid;
        rewardToTokenAPath = _rewardToTokenAPath;

        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        enableHarvestMdxSwapFarm = _enableHarvestMdxSwapFarm;
    }

    function getName() external pure returns (string memory) {
        return "StrategyACryptoSMdxB_BNB";
    }

    function deposit() public {
      _stakeWant(false);

      if(want == rewardToken) {
        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this)); 
        if (_rewardToken > 0) {
          uint256 _fee = _rewardToken.mul(performanceFee).div(FEE_DENOMINATOR);
          uint256 _reward = _rewardToken.mul(strategistReward).div(FEE_DENOMINATOR);
          IERC20(rewardToken).safeTransfer(IController(controller).rewards(), _fee);
          IERC20(rewardToken).safeTransfer(strategist, _reward);
          _stakeWant(false);
        }
      }
    }

    function _stakeWant(bool _force) internal {
      if(paused) return;
      uint256 _want = IERC20(want).balanceOf(address(this));
      if (_want > 0) {
        IERC20(want).safeApprove(mdxBFarmBNB, 0);
        IERC20(want).safeApprove(mdxBFarmBNB, _want);
      }
      if (_want > 0 || _force) {
        IMdxBFarm(mdxBFarmBNB).deposit(farmPid, _want);
      }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
      require(msg.sender == controller, "!controller");
      uint256 _balance = IERC20(want).balanceOf(address(this));
      if (_balance < _amount) {
          _amount = _withdrawSome(_amount.sub(_balance));
          _amount = _amount.add(_balance);
      }

      uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);
      IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
      address _vault = IController(controller).vaults(address(want));
      require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
      IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
      if(want == rewardToken) {
        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this)); 
        IMdxBFarm(mdxBFarmBNB).withdraw(farmPid, _amount);
        _rewardToken = IERC20(rewardToken).balanceOf(address(this)).sub(_rewardToken).sub(_amount);
        if (_rewardToken > 0) {
          uint256 _fee = _rewardToken.mul(performanceFee).div(FEE_DENOMINATOR);
          uint256 _reward = _rewardToken.mul(strategistReward).div(FEE_DENOMINATOR);
          IERC20(rewardToken).safeTransfer(IController(controller).rewards(), _fee);
          IERC20(rewardToken).safeTransfer(strategist, _reward);

          IERC20(want).safeApprove(mdxBFarmBNB, 0);
          IERC20(want).safeApprove(mdxBFarmBNB, _rewardToken.sub(_fee).sub(_reward));
          IMdxBFarm(mdxBFarmBNB).deposit(farmPid, _rewardToken.sub(_fee).sub(_reward));
        }
      } else {
        IMdxBFarm(mdxBFarmBNB).withdraw(farmPid, _amount);        
      }

      return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
      require(msg.sender == controller || msg.sender == strategist || msg.sender == governance, "!authorized");
      _withdrawAll();

      balance = IERC20(want).balanceOf(address(this));

      address _vault = IController(controller).vaults(address(want));
      require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
      IERC20(want).safeTransfer(_vault, balance);

      //waste not - send dust tokenA to rewards
      IERC20(tokenA).safeTransfer(IController(controller).rewards(),
          IERC20(tokenA).balanceOf(address(this))
        );

    }

    function _withdrawAll() internal {
      IMdxBFarm(mdxBFarmBNB).emergencyWithdraw(farmPid);
    }

    function _convertRewardsToWant() internal {
      if(rewardToken != tokenA) {
        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        if(_rewardToken > 0 ) {
          IERC20(rewardToken).safeApprove(mdexRouter, 0);
          IERC20(rewardToken).safeApprove(mdexRouter, _rewardToken);

          IMdexRouter(mdexRouter).swapExactTokensForTokens(_rewardToken, uint256(0), rewardToTokenAPath, address(this), now.add(1800));
        }
      }
      if(want != tokenA) {
        uint256 _tokenA = IERC20(tokenA).balanceOf(address(this));
        if(_tokenA > 0 ) {
          //convert tokenA
          IERC20(tokenA).safeApprove(mdexRouter, 0);
          IERC20(tokenA).safeApprove(mdexRouter, _tokenA.div(2));

          address[] memory path = new address[](2);
          path[0] = tokenA;
          path[1] = tokenB;

          IMdexRouter(mdexRouter).swapExactTokensForTokens(_tokenA.div(2), uint256(0), path, address(this), now.add(1800));

          //add liquidity
          _tokenA = IERC20(tokenA).balanceOf(address(this));
          uint256 _tokenB = IERC20(tokenB).balanceOf(address(this));

          IERC20(tokenA).safeApprove(mdexRouter, 0);
          IERC20(tokenA).safeApprove(mdexRouter, _tokenA);
          IERC20(tokenB).safeApprove(mdexRouter, 0);
          IERC20(tokenB).safeApprove(mdexRouter, _tokenB);

          IMdexRouter(mdexRouter).addLiquidity(
            tokenA, // address tokenA,
            tokenB, // address tokenB,
            _tokenA, // uint amountADesired,
            _tokenB, // uint amountBDesired,
            0, // uint amountAMin,
            0, // uint amountBMin,
            address(this), // address to,
            now.add(1800)// uint deadline
          );
        }
      }
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfStakedWant() public view returns (uint256) {
      (uint256 _amount,) = IMdxBFarm(mdxBFarmBNB).userInfo(farmPid,address(this));
      return _amount;
    }

    function harvest() public returns (uint harvesterRewarded) {
      require(msg.sender == tx.origin, "not eoa");

      _stakeWant(true);
      if(enableHarvestMdxSwapFarm) IMdxSwapFarm(mdxSwapFarm).takerWithdraw(); //harvest rewardToken from swap farm

      uint _rewardToken = IERC20(rewardToken).balanceOf(address(this)); 
      uint256 _harvesterReward;
      if (_rewardToken > 0) {
        uint256 _fee = _rewardToken.mul(performanceFee).div(FEE_DENOMINATOR);
        uint256 _reward = _rewardToken.mul(strategistReward).div(FEE_DENOMINATOR);
        _harvesterReward = _rewardToken.mul(harvesterReward).div(FEE_DENOMINATOR);
        IERC20(rewardToken).safeTransfer(IController(controller).rewards(), _fee);
        IERC20(rewardToken).safeTransfer(strategist, _reward);
        IERC20(rewardToken).safeTransfer(msg.sender, _harvesterReward);
      }

      _convertRewardsToWant();
      _stakeWant(false);

      return _harvesterReward;
    }

    function balanceOf() public view returns (uint256) {
      return balanceOfWant()
        .add(balanceOfStakedWant());
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        performanceFee = _performanceFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        strategistReward = _strategistReward;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setHarvesterReward(uint256 _harvesterReward) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        harvesterReward = _harvesterReward;
    }

    function setRewardToTokenAPath(address[] calldata _rewardToTokenAPath) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        rewardToTokenAPath = _rewardToTokenAPath;
    }

    function setEnableHarvestMdxSwapFarm(bool _enableHarvestMdxSwapFarm) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        enableHarvestMdxSwapFarm = _enableHarvestMdxSwapFarm;
    }

    function pause() external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        _withdrawAll();
        paused = true;
    }

    function unpause() external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        paused = false;
        _stakeWant(false);
    }


    //In case anything goes wrong. Mdex contracts implement blacklists.
    //This does not increase user risk. Governance already controls funds via strategy upgrade, and is behind timelock and/or multisig.
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable returns (bytes memory) {
        require(msg.sender == governance, "!governance");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        return returnData;
    }
}


interface IMdexRouter {
  // function WBNB (  ) external view returns ( address );
  function addLiquidity ( address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB, uint256 liquidity );
  // function addLiquidityETH ( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH, uint256 liquidity );
  // function factory (  ) external view returns ( address );
  // function getAmountIn ( uint256 amountOut, uint256 reserveIn, uint256 reserveOut, address token0, address token1 ) external view returns ( uint256 amountIn );
  // function getAmountOut ( uint256 amountIn, uint256 reserveIn, uint256 reserveOut, address token0, address token1 ) external view returns ( uint256 amountOut );
  // function getAmountsIn ( uint256 amountOut, address[] path ) external view returns ( uint256[] amounts );
  // function getAmountsOut ( uint256 amountIn, address[] path ) external view returns ( uint256[] amounts );
  // function isOwner ( address account ) external view returns ( bool );
  // function owner (  ) external view returns ( address );
  // function pairFor ( address tokenA, address tokenB ) external view returns ( address pair );
  // function quote ( uint256 amountA, uint256 reserveA, uint256 reserveB ) external view returns ( uint256 amountB );
  // function removeLiquidity ( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB );
  // function removeLiquidityETH ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH );
  // function removeLiquidityETHSupportingFeeOnTransferTokens ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountETH );
  // function removeLiquidityETHWithPermit ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountToken, uint256 amountETH );
  // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountETH );
  // function removeLiquidityWithPermit ( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountA, uint256 amountB );
  // function renounceOwnership (  ) external;
  // function setSwapMining ( address _swapMininng ) external;
  // function swapETHForExactTokens ( uint256 amountOut, address[] path, address to, uint256 deadline ) external returns ( uint256[] amounts );
  // function swapExactETHForTokens ( uint256 amountOutMin, address[] path, address to, uint256 deadline ) external returns ( uint256[] amounts );
  // function swapExactETHForTokensSupportingFeeOnTransferTokens ( uint256 amountOutMin, address[] path, address to, uint256 deadline ) external;
  // function swapExactTokensForETH ( uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline ) external returns ( uint256[] amounts );
  // function swapExactTokensForETHSupportingFeeOnTransferTokens ( uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline ) external;
  function swapExactTokensForTokens ( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
  // function swapExactTokensForTokensSupportingFeeOnTransferTokens ( uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline ) external;
  // function swapMining (  ) external view returns ( address );
  // function swapTokensForExactETH ( uint256 amountOut, uint256 amountInMax, address[] path, address to, uint256 deadline ) external returns ( uint256[] amounts );
  // function swapTokensForExactTokens ( uint256 amountOut, uint256 amountInMax, address[] path, address to, uint256 deadline ) external returns ( uint256[] amounts );
  // function transferOwnership ( address newOwner ) external;
}

interface IMdxBFarm {
  // function add ( uint256 _allocPoint, address _lpToken, bool _withUpdate ) external;
  // function addBadAddress ( address _bad ) external returns ( bool );
  // function cycle (  ) external view returns ( uint256 );
  // function delBadAddress ( address _bad ) external returns ( bool );
  function deposit ( uint256 _pid, uint256 _amount ) external;
  function emergencyWithdraw ( uint256 _pid ) external;
  // function endBlock (  ) external view returns ( uint256 );
  // function getBadAddress ( uint256 _index ) external view returns ( address );
  // function getBlackListLength (  ) external view returns ( uint256 );
  // function isBadAddress ( address account ) external view returns ( bool );
  // function massUpdatePools (  ) external;
  // function mdx (  ) external view returns ( address );
  // function mdxPerBlock (  ) external view returns ( uint256 );
  // function newReward ( uint256 _mdxAmount, uint256 _newPerBlock, uint256 _startBlock ) external;
  // function owner (  ) external view returns ( address );
  // function pending ( uint256 _pid, address _user ) external view returns ( uint256 );
  // function poolInfo ( uint256 ) external view returns ( address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accMDXPerShare, uint256 mdxAmount );
  // function poolLength (  ) external view returns ( uint256 );
  // function renounceOwnership (  ) external;
  // function set ( uint256 _pid, uint256 _allocPoint, bool _withUpdate ) external;
  // function setCycle ( uint256 _newCycle ) external;
  // function startBlock (  ) external view returns ( uint256 );
  // function totalAllocPoint (  ) external view returns ( uint256 );
  // function transferOwnership ( address newOwner ) external;
  // function updatePool ( uint256 _pid ) external;
  function userInfo ( uint256, address ) external view returns ( uint256 amount, uint256 rewardDebt );
  function withdraw ( uint256 _pid, uint256 _amount ) external;
}

interface IMdxSwapFarm {
  // function addPair ( uint256 _allocPoint, address _pair, bool _withUpdate ) external;
  // function addWhitelist ( address _addToken ) external returns ( bool );
  // function delWhitelist ( address _delToken ) external returns ( bool );
  // function factory (  ) external view returns ( address );
  // function getMdxReward ( uint256 _lastRewardBlock ) external view returns ( uint256 );
  // function getPoolInfo ( uint256 _pid ) external view returns ( address, address, uint256, uint256, uint256, uint256 );
  // function getQuantity ( address outputToken, uint256 outputAmount, address anchorToken ) external view returns ( uint256 );
  // function getUserReward ( uint256 _pid ) external view returns ( uint256, uint256 );
  // function getWhitelist ( uint256 _index ) external view returns ( address );
  // function getWhitelistLength (  ) external view returns ( uint256 );
  // function halvingPeriod (  ) external view returns ( uint256 );
  // function isOwner ( address account ) external view returns ( bool );
  // function isWhitelist ( address _token ) external view returns ( bool );
  // function massMintPools (  ) external;
  // function mdx (  ) external view returns ( address );
  // function mdxPerBlock (  ) external view returns ( uint256 );
  // function mint ( uint256 _pid ) external returns ( bool );
  // function oracle (  ) external view returns ( address );
  // function owner (  ) external view returns ( address );
  // function pairOfPid ( address ) external view returns ( uint256 );
  // function phase ( uint256 blockNumber ) external view returns ( uint256 );
  // function phase (  ) external view returns ( uint256 );
  // function poolInfo ( uint256 ) external view returns ( address pair, uint256 quantity, uint256 totalQuantity, uint256 allocPoint, uint256 allocMdxAmount, uint256 lastRewardBlock );
  // function poolLength (  ) external view returns ( uint256 );
  // function renounceOwnership (  ) external;
  // function reward (  ) external view returns ( uint256 );
  // function reward ( uint256 blockNumber ) external view returns ( uint256 );
  // function router (  ) external view returns ( address );
  // function setHalvingPeriod ( uint256 _block ) external;
  // function setMdxPerBlock ( uint256 _newPerBlock ) external;
  // function setOracle ( address _oracle ) external;
  // function setPair ( uint256 _pid, uint256 _allocPoint, bool _withUpdate ) external;
  // function setRouter ( address newRouter ) external;
  // function startBlock (  ) external view returns ( uint256 );
  // function swap ( address account, address input, address output, uint256 amount ) external returns ( bool );
  function takerWithdraw (  ) external;
  // function targetToken (  ) external view returns ( address );
  // function totalAllocPoint (  ) external view returns ( uint256 );
  // function transferOwnership ( address newOwner ) external;
  // function userInfo ( uint256, address ) external view returns ( uint256 quantity, uint256 blockNumber );
}