// File: contracts/SafeMath.sol

pragma solidity 0.5.17;

// Note: This file has been modified to include the sqrt function for quadratic voting
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

    /**
    * Imported from: https://github.com/alianse777/solidity-standard-library/blob/master/Math.sol
    * @dev Compute square root of x
    * @return sqrt(x)
    */
   function sqrt(uint256 x) internal pure returns (uint256) {
       uint256 n = x / 2;
       uint256 lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2;
       }
       return uint256(n);
   }
}

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

// File: contracts/zeppelin/Address.sol

pragma solidity 0.5.17;


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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

// File: contracts/IERC20.sol

//SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.5.17;


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

// File: contracts/zeppelin/SafeERC20.sol

pragma solidity 0.5.17;




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

// File: contracts/ITreasury.sol

pragma solidity 0.5.17;



interface ITreasury {
    function defaultToken() external view returns (IERC20);
    function deposit(IERC20 token, uint256 amount) external;
    function withdraw(uint256 amount, address withdrawAddress) external;
}

// File: contracts/vaults/IVault.sol

pragma solidity 0.5.17;



interface IVault {
    function want() external view returns (IERC20);
    function transferFundsToStrategy(address strategy, uint256 amount) external;
    function availableFunds() external view returns (uint256);
}

// File: contracts/vaults/IVaultRewards.sol

pragma solidity 0.5.17;



interface IVaultRewards {
    function want() external view returns (IERC20);
    function notifyRewardAmount(uint256 reward) external;
}

// File: contracts/vaults/IController.sol

pragma solidity 0.5.17;






interface IController {
    function currentEpochTime() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function rewards(address token) external view returns (IVaultRewards);
    function vault(address token) external view returns (IVault);
    function allowableAmount(address) external view returns (uint256);
    function treasury() external view returns (ITreasury);
    function approvedStrategies(address, address) external view returns (bool);
    function getHarvestInfo(address strategy, address user)
        external view returns (
        uint256 vaultRewardPercentage,
        uint256 hurdleAmount,
        uint256 harvestPercentage
    );
    function withdraw(address, uint256) external;
    function earn(address, uint256) external;
    function increaseHurdleRate(address token) external;
}

// File: contracts/LPTokenWrapper.sol

//SPDX-License-Identifier: GPL-3.0-only


pragma solidity ^0.5.17;




contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 _stakeToken) public {
        stakeToken = _stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        // safeTransferFrom shifted to overriden method
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        // safeTransferFrom shifted to overriden method
    }
}

// File: contracts/vaults/BoostVaultRewards.sol

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.5.17;







contract BoostVaultRewards is LPTokenWrapper, IVaultRewards {
    struct EpochRewards {
        uint256 rewardsAvailable;
        uint256 rewardsClaimed;
        uint256 rewardPerToken;
    }

    IERC20 public boostToken;
    IERC20 public want;
    IController public controller;
    address public gov;

    EpochRewards public previousEpoch;
    EpochRewards public currentEpoch;
    mapping(address => uint256) public previousEpochUserRewardPerTokenPaid;
    mapping(address => uint256) public currentEpochUserRewardPerTokenPaid;
    mapping(address => uint256) public previousEpochRewardsClaimable;
    mapping(address => uint256) public currentEpochRewardsClaimable;

    uint256 public constant EPOCH_DURATION = 1 weeks;
    uint256 public currentEpochTime;
    uint256 public unclaimedRewards;

    // booster variables
    // variables to keep track of totalSupply and balances (after accounting for multiplier)
    uint256 public boostedTotalSupply;
    uint256 public lastBoostPurchase; // timestamp of lastBoostPurchase
    mapping(address => uint256) public boostedBalances;
    mapping(address => uint256) public numBoostersBought; // each booster = 5% increase in stake amt
    mapping(address => uint256) public nextBoostPurchaseTime; // timestamp for which user is eligible to purchase another booster
    mapping(address => uint256) public lastActionTime;

    uint256 public globalBoosterPrice = 1e18;
    uint256 public scaleFactor = 125;
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant DENOM = 10000;
    uint256 internal constant TREASURY_FEE = 250;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        IERC20 _stakeToken, // bf-token
        IERC20 _boostToken,
        IController _controller,
        address _gov
    ) public LPTokenWrapper(_stakeToken) {
        boostToken = _boostToken;
        want = IVault(address(_stakeToken)).want();
        controller = _controller;
        gov = _gov;
        currentEpochTime = controller.currentEpochTime();
    }

    modifier updateEpochRewards() {
        if (block.timestamp > currentEpochTime.add(EPOCH_DURATION)) {
            currentEpochTime = currentEpochTime.add(EPOCH_DURATION);
            // update unclaimed rewards
            unclaimedRewards = unclaimedRewards.add(
                previousEpoch.rewardsAvailable.sub(previousEpoch.rewardsClaimed)
            );
            // replace previous with current epoch
            previousEpoch = currentEpoch;
            // instantiate new epoch
            currentEpoch = EpochRewards({
                rewardsAvailable: 0,
                rewardsClaimed: 0,
                rewardPerToken: 0
            });
        }
        _;
    }

    function earned(address user) external view returns (uint256) {
        return (block.timestamp > currentEpochTime + EPOCH_DURATION) ?
            _earned(user, true) :
            _earned(user, false).add(_earned(user, true));
    }

    function setGovernance(address _gov) external updateEpochRewards {
        require(msg.sender == gov, "not gov");
        gov = _gov;
    }

    function setController(IController _controller) external updateEpochRewards {
        require(msg.sender == gov, "not gov");
        controller = _controller;
    }

    function getReward(address user) external updateEpochRewards {
        updateClaimUserRewardAndBooster(user);
    }

    function sendUnclaimedRewards() external updateEpochRewards {
        uint256 pendingRewards = unclaimedRewards;
        unclaimedRewards = 0;
        want.safeTransfer(address(controller.vault(address(want))), pendingRewards);
    }

    function sendTreasuryBoost() external updateEpochRewards {
        // transfer all collected boost tokens to treasury
        uint256 boosterAmount = boostToken.balanceOf(address(this));
        boostToken.safeApprove(address(controller.treasury()), boosterAmount);
        controller.treasury().deposit(boostToken, boosterAmount);
    }

    function boost() external updateEpochRewards {
        require(
            block.timestamp > nextBoostPurchaseTime[msg.sender],
            "early boost purchase"
        );
        updateClaimUserRewardAndBooster(msg.sender);

        // save current booster price, since transfer is done last
        // since getBoosterPrice() returns new boost balance, avoid re-calculation
        (uint256 boosterAmount, uint256 newBoostBalance) = getBoosterPrice(msg.sender);
        // user's balance and boostedSupply will be changed in this function
        applyBoost(msg.sender, newBoostBalance);

        // increase hurdle rate
        controller.increaseHurdleRate(address(want));

        boostToken.safeTransferFrom(msg.sender, address(this), boosterAmount);
    }

    // can only be called by vault (withdrawal fee) or approved strategy
    // since funds are assumed to have been sent
    function notifyRewardAmount(uint256 reward)
        external
        updateEpochRewards
    {
        require(
            msg.sender == address(stakeToken) ||
            controller.approvedStrategies(address(want), msg.sender),
            "!authorized"
        );

        // send treasury fees
        uint256 rewardAmount = reward.mul(TREASURY_FEE).div(DENOM);
        want.safeApprove(address(controller.treasury()), rewardAmount);
        controller.treasury().deposit(want, rewardAmount);

        // distribute remaining fees
        rewardAmount = reward.sub(rewardAmount);
        currentEpoch.rewardsAvailable = currentEpoch.rewardsAvailable.add(rewardAmount);
        currentEpoch.rewardPerToken = currentEpoch.rewardPerToken.add(
            (boostedTotalSupply == 0) ?
            rewardAmount :
            rewardAmount.mul(PRECISION).div(boostedTotalSupply)
        );
        emit RewardAdded(reward);
    }

    function getBoosterPrice(address user)
        public view returns (uint256 boosterPrice, uint256 newBoostBalance)
    {
        if (boostedTotalSupply == 0) return (0,0);

        // 5% increase for each previously user-purchased booster
        uint256 boostersBought = numBoostersBought[user];
        boosterPrice = globalBoosterPrice.mul(boostersBought.mul(5).add(100)).div(100);

        // increment boostersBought by 1
        boostersBought = boostersBought.add(1);

        // 2.5% decrease for every 2 hour interval since last global boost purchase
        boosterPrice = pow(boosterPrice, 975, 1000, (block.timestamp.sub(lastBoostPurchase)).div(2 hours));

        // adjust price based on expected increase in boost supply
        // boostersBought has been incremented by 1 already
        newBoostBalance = balanceOf(user)
            .mul(boostersBought.mul(5).add(100))
            .div(100);
        uint256 boostBalanceIncrease = newBoostBalance.sub(boostedBalances[user]);
        boosterPrice = boosterPrice
            .mul(boostBalanceIncrease)
            .mul(scaleFactor)
            .div(boostedTotalSupply);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateEpochRewards {
        require(amount > 0, "Cannot stake 0");
        updateClaimUserRewardAndBooster(msg.sender);
        super.stake(amount);

        // previous boosters do not affect new amounts
        boostedBalances[msg.sender] = boostedBalances[msg.sender].add(amount);
        boostedTotalSupply = boostedTotalSupply.add(amount);

        // transfer token last, to follow CEI pattern
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public updateEpochRewards {
        require(amount > 0, "Cannot withdraw 0");
        updateClaimUserRewardAndBooster(msg.sender);
        super.withdraw(amount);

        // update boosted balance and supply
        updateBoostBalanceAndSupply(msg.sender, 0);
        stakeToken.safeTransfer(msg.sender, amount);
    }

    // simpler withdraw method, in case rewards don't update properly
    // does not claim rewards nor update user's lastActionTime
    function emergencyWithdraw(uint256 amount) public {
        super.withdraw(amount);
        // reset numBoostersBought
        numBoostersBought[msg.sender] = 0;
        // update boosted balance and supply
        updateBoostBalanceAndSupply(msg.sender, 0);
        // transfer tokens to user
        stakeToken.safeTransfer(msg.sender, amount);
    }

    function exit() public updateEpochRewards {
        withdraw(balanceOf(msg.sender));
    }

    function updateBoostBalanceAndSupply(address user, uint256 newBoostBalance) internal {
        // subtract existing balance from boostedSupply
        boostedTotalSupply = boostedTotalSupply.sub(boostedBalances[user]);

        // when applying boosts,
        // newBoostBalance has already been calculated in getBoosterPrice()
        if (newBoostBalance == 0) {
            // each booster adds 5% to current stake amount
            newBoostBalance = balanceOf(user).mul(numBoostersBought[user].mul(5).add(100)).div(100);
        }

        // update user's boosted balance
        boostedBalances[user] = newBoostBalance;

        // update boostedSupply
        boostedTotalSupply = boostedTotalSupply.add(newBoostBalance);
    }

    function updateClaimUserRewardAndBooster(address user) internal {
        // first, reset previous epoch stats and booster count if user's last action exceeds 1 epoch
        if (lastActionTime[user].add(EPOCH_DURATION) <= currentEpochTime) {
            previousEpochRewardsClaimable[user] = 0;
            previousEpochUserRewardPerTokenPaid[user] = 0;
            numBoostersBought[user] = 0;
        }
        // then, update user's claimable amount and booster count for the previous epoch
        if (lastActionTime[user] <= currentEpochTime) {
            previousEpochRewardsClaimable[user] = _earned(user, false);
            previousEpochUserRewardPerTokenPaid[user] = previousEpoch.rewardPerToken;
            numBoostersBought[user] = 0;
        }
        // finally, update user's claimable amount for current epoch
        currentEpochRewardsClaimable[user] = _earned(user, true);
        currentEpochUserRewardPerTokenPaid[user] = currentEpoch.rewardPerToken;

        // get reward claimable for previous epoch
        previousEpoch.rewardsClaimed = previousEpoch.rewardsClaimed.add(previousEpochRewardsClaimable[user]);
        uint256 reward = previousEpochRewardsClaimable[user];
        previousEpochRewardsClaimable[user] = 0;

        // get reward claimable for current epoch
        currentEpoch.rewardsClaimed = currentEpoch.rewardsClaimed.add(currentEpochRewardsClaimable[user]);
        reward = reward.add(currentEpochRewardsClaimable[user]);
        currentEpochRewardsClaimable[user] = 0;

        if (reward > 0) {
            want.safeTransfer(user, reward);
            emit RewardPaid(user, reward);
        }

        // last, update user's action timestamp
        lastActionTime[user] = block.timestamp;
    }

    function applyBoost(address user, uint256 newBoostBalance) internal {
        // increase no. of boosters bought
        numBoostersBought[user] = numBoostersBought[user].add(1);

        updateBoostBalanceAndSupply(user, newBoostBalance);

        // increase next purchase eligibility by an hour
        nextBoostPurchaseTime[user] = block.timestamp.add(3600);

        // increase global booster price by 1%
        globalBoosterPrice = globalBoosterPrice.mul(101).div(100);

        lastBoostPurchase = block.timestamp;
    }

    function _earned(address account, bool isCurrentEpoch) internal view returns (uint256) {
        uint256 rewardPerToken;
        uint256 userRewardPerTokenPaid;
        uint256 rewardsClaimable;

        if (isCurrentEpoch) {
            rewardPerToken = currentEpoch.rewardPerToken;
            userRewardPerTokenPaid = currentEpochUserRewardPerTokenPaid[account];
            rewardsClaimable = currentEpochRewardsClaimable[account];
        } else {
            rewardPerToken = previousEpoch.rewardPerToken;
            userRewardPerTokenPaid = previousEpochUserRewardPerTokenPaid[account];
            rewardsClaimable = previousEpochRewardsClaimable[account];
        }
        return
            boostedBalances[account]
                .mul(rewardPerToken.sub(userRewardPerTokenPaid))
                .div(1e18)
                .add(rewardsClaimable);
    }

   /// Imported from: https://forum.openzeppelin.com/t/does-safemath-library-need-a-safe-power-function/871/7
   /// Modified so that it takes in 3 arguments for base
   /// @return a * (b / c)^exponent
   function pow(uint256 a, uint256 b, uint256 c, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return a;
        }
        else if (exponent == 1) {
            return a.mul(b).div(c);
        }
        else if (a == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = a.mul(b).div(c);
            for (uint256 i = 1; i < exponent; i++)
                z = z.mul(b).div(c);
            return z;
        }
    }
}