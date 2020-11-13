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

// File: contracts/vaults/IStrategy.sol

/*
 A strategy must implement the following functions:
 - getName(): Name of strategy
 - want(): Desired token for investment. Should be same as underlying vault token (Eg. USDC)
 - deposit function that will calls controller.earn()
 - withdraw(address): For miscellaneous tokens, must exclude any tokens used in the yield
    - Should return to Controller
 - withdraw(uint): Controller | Vault role - withdraw should always return to vault
 - withdrawAll(): Controller | Vault role - withdraw should always return to vault
 - balanceOf(): Should return underlying vault token amount
*/

pragma solidity 0.5.17;


interface IStrategy {
    function getName() external pure returns (string memory);
    function want() external view returns (address);
    function withdraw(address) external;
    function withdraw(uint256) external;
    function withdrawAll() external returns (uint256);
    function balanceOf() external view returns (uint256);
}

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

// File: contracts/vaults/BoostController.sol

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






contract BoostController is IController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    struct TokenStratInfo {
        IVault vault;
        IVaultRewards rewards;
        IStrategy[] strategies;
        uint256 currentHurdleRate;
        uint256 nextHurdleRate;
        uint256 hurdleLastUpdateTime;
        uint256 harvestPrice;
        uint256 globalHarvestLastUpdateTime;
        mapping(address => uint256) harvestPercentages;
        mapping(address => uint256) harvestLastUpdateTime;
    }

    address public gov;
    address public strategist;
    ITreasury public treasury;
    IERC20 public boostToken;

    mapping(address => TokenStratInfo) public tokenStratsInfo;
    mapping(address => uint256) public capAmounts;
    mapping(address => uint256) public investedAmounts;
    mapping(address => mapping(address => bool)) public approvedStrategies;

    uint256 public currentEpochTime;
    uint256 public constant EPOCH_DURATION = 1 weeks;
    uint256 internal constant DENOM = 10000;
    uint256 internal constant HURDLE_RATE_MAX = 500; // max 5%
    uint256 internal constant BASE_HARVEST_PERCENTAGE = 50; // 0.5%
    uint256 internal constant BASE_REWARD_PERCENTAGE = 5000; // 50%
    uint256 internal constant HARVEST_PERCENTAGE_MAX = 100; // max 1% extra
    uint256 internal constant PRICE_INCREASE = 10100; // 1.01x
    uint256 internal constant EPOCH_PRICE_REDUCTION = 8000; // 0.8x

    uint256 vaultRewardChangePrice = 10e18; // initial cost of 10 boosts
    uint256 public globalVaultRewardPercentage = BASE_REWARD_PERCENTAGE;
    uint256 vaultRewardLastUpdateTime;

    constructor(
        address _gov,
        address _strategist,
        ITreasury _treasury,
        IERC20 _boostToken,
        uint256 _epochStart
    ) public {
        gov = _gov;
        strategist = _strategist;
        treasury = _treasury;
        boostToken = _boostToken;
        currentEpochTime = _epochStart;
    }

    modifier updateEpoch() {
        if (block.timestamp > currentEpochTime.add(EPOCH_DURATION)) {
            currentEpochTime = currentEpochTime.add(EPOCH_DURATION);
        }
        _;
    }

    function rewards(address token) external view returns (IVaultRewards) {
        return tokenStratsInfo[token].rewards;
    }

    function vault(address token) external view returns (IVault) {
        return tokenStratsInfo[token].vault;
    }

    function balanceOf(address token) external view returns (uint256) {
        IStrategy[] storage strategies = tokenStratsInfo[token].strategies;
        uint256 totalBalance;
        for (uint256 i = 0; i < strategies.length; i++) {
            totalBalance = totalBalance.add(strategies[i].balanceOf());
        }
        return totalBalance;
    }

    function allowableAmount(address strategy) external view returns(uint256) {
        return capAmounts[strategy].sub(investedAmounts[strategy]);
    }

    function getHarvestInfo(
        address strategy,
        address user
    ) external view returns (
        uint256 vaultRewardPercentage,
        uint256 hurdleAmount,
        uint256 harvestPercentage
    ) {
        address token = IStrategy(strategy).want();
        vaultRewardPercentage = globalVaultRewardPercentage;
        hurdleAmount = getHurdleAmount(strategy, token);
        harvestPercentage = getHarvestPercentage(user, token);
    }

    function getHarvestUserInfo(address user, address token)
        external
        view
        returns (uint256 harvestPercentage, uint256 lastUpdateTime)
    {
        TokenStratInfo storage info = tokenStratsInfo[token];
        harvestPercentage = info.harvestPercentages[user];
        lastUpdateTime = info.harvestLastUpdateTime[user];
    }

    function getStrategies(address token) external view returns (IStrategy[] memory strategies) {
        return tokenStratsInfo[token].strategies;
    }

    function setTreasury(ITreasury _treasury) external updateEpoch {
        require(msg.sender == gov, "!gov");
        treasury = _treasury;
    }

    function setStrategist(address _strategist) external updateEpoch {
        require(msg.sender == gov, "!gov");
        strategist = _strategist;
    }

    function setGovernance(address _gov) external updateEpoch {
        require(msg.sender == gov, "!gov");
        gov = _gov;
    }

    function setRewards(IVaultRewards _rewards) external updateEpoch {
        require(msg.sender == strategist || msg.sender == gov, "!authorized");
        address token = address(_rewards.want());
        require(tokenStratsInfo[token].rewards == IVaultRewards(0), "rewards exists");
        tokenStratsInfo[token].rewards = _rewards;
    }

    function setVaultAndInitHarvestInfo(IVault _vault) external updateEpoch {
        require(msg.sender == strategist || msg.sender == gov, "!authorized");
        address token = address(_vault.want());
        TokenStratInfo storage info = tokenStratsInfo[token];
        require(info.vault == IVault(0), "vault exists");
        info.vault = _vault;
        // initial harvest booster price of 1 boost
        info.harvestPrice = 1e18;
        info.globalHarvestLastUpdateTime = currentEpochTime;
    }

    function approveStrategy(address _strategy, uint256 _cap) external updateEpoch {
        require(msg.sender == gov, "!gov");
        address token = IStrategy(_strategy).want();
        require(!approvedStrategies[token][_strategy], "strat alr approved");
        require(tokenStratsInfo[token].vault.want() == IERC20(token), "unequal wants");
        capAmounts[_strategy] = _cap;
        tokenStratsInfo[token].strategies.push(IStrategy(_strategy));
        approvedStrategies[token][_strategy] = true;
    }

    function changeCap(address strategy, uint256 _cap) external updateEpoch {
        require(msg.sender == gov, "!gov");
        capAmounts[strategy] = _cap;
    }

    function revokeStrategy(address _strategy, uint256 _index) external updateEpoch {
        require(msg.sender == gov, "!gov");
        address token = IStrategy(_strategy).want();
        require(approvedStrategies[token][_strategy], "strat alr revoked");
        IStrategy[] storage tokenStrategies = tokenStratsInfo[token].strategies;
        require(address(tokenStrategies[_index]) == _strategy, "wrong index");

        // replace revoked strategy with last element in array
        tokenStrategies[_index] = tokenStrategies[tokenStrategies.length - 1];
        delete tokenStrategies[tokenStrategies.length - 1];
        tokenStrategies.length--;
        capAmounts[_strategy] = 0;
        approvedStrategies[token][_strategy] = false;
    }

    function getHurdleAmount(address strategy, address token) public view returns (uint256) {
        TokenStratInfo storage info = tokenStratsInfo[token];
        return (info.hurdleLastUpdateTime < currentEpochTime ||
        (block.timestamp > currentEpochTime.add(EPOCH_DURATION))) ?
            0 :
            info.currentHurdleRate
            .mul(investedAmounts[strategy])
            .div(DENOM);
    }

    function getHarvestPercentage(address user, address token) public view returns (uint256) {
        TokenStratInfo storage info = tokenStratsInfo[token];
        return (info.harvestLastUpdateTime[user] < currentEpochTime ||
            (block.timestamp > currentEpochTime.add(EPOCH_DURATION))) ?
            BASE_HARVEST_PERCENTAGE :
            info.harvestPercentages[user];
    }

    /// @dev check that vault has sufficient funds is done by the call to vault
    function earn(address strategy, uint256 amount) public updateEpoch {
        require(msg.sender == strategy, "!strategy");
        address token = IStrategy(strategy).want();
        require(approvedStrategies[token][strategy], "strat !approved");
        TokenStratInfo storage info = tokenStratsInfo[token];
        uint256 newInvestedAmount = investedAmounts[strategy].add(amount);
        require(newInvestedAmount <= capAmounts[strategy], "hit strategy cap");
        // update invested amount
        investedAmounts[strategy] = newInvestedAmount;
        // transfer funds to strategy
        info.vault.transferFundsToStrategy(strategy, amount);
    }

    // Anyone can withdraw non-core strategy tokens => sent to treasury
    function earnMiscTokens(IStrategy strategy, IERC20 token) external updateEpoch {
        // should send tokens to this contract
        strategy.withdraw(address(token));
        uint256 bal = token.balanceOf(address(this));
        token.safeApprove(address(treasury), bal);
        // send funds to treasury
        treasury.deposit(token, bal);
    }

    function increaseHarvestPercentageHurdleRate(address token) external updateEpoch {
        TokenStratInfo storage info = tokenStratsInfo[token];
        // first, handle vault global price and update time
        // if new epoch, reduce price by 20%
        if (info.globalHarvestLastUpdateTime < currentEpochTime) {
            info.harvestPrice = info.harvestPrice.mul(EPOCH_PRICE_REDUCTION).div(DENOM);
        }

        // get funds from user, send to treasury
        boostToken.safeTransferFrom(msg.sender, address(this), info.harvestPrice);
        boostToken.safeApprove(address(treasury), info.harvestPrice);
        treasury.deposit(boostToken, info.harvestPrice);

        // increase price
        info.harvestPrice = info.harvestPrice.mul(PRICE_INCREASE).div(DENOM);
        // update globalHarvestLastUpdateTime
        info.globalHarvestLastUpdateTime = block.timestamp;

        // next, handle effect on harvest percentage and update user's harvest time
        // see if percentage needs to be reset
        if (info.harvestLastUpdateTime[msg.sender] < currentEpochTime) {
            info.harvestPercentages[msg.sender] = BASE_HARVEST_PERCENTAGE;
        }
        info.harvestLastUpdateTime[msg.sender] = block.timestamp;

        // increase harvest percentage by 0.25%
        info.harvestPercentages[msg.sender] = Math.min(
            HARVEST_PERCENTAGE_MAX,
            info.harvestPercentages[msg.sender].add(25)
        );
        increaseHurdleRate(token);
    }

    function changeVaultRewardPercentage(bool isIncrease) external updateEpoch {
        // if new epoch, reduce price by 20%
        if ((vaultRewardLastUpdateTime != 0) && (vaultRewardLastUpdateTime < currentEpochTime)) {
            vaultRewardChangePrice = vaultRewardChangePrice.mul(EPOCH_PRICE_REDUCTION).div(DENOM);
        }

        // get funds from user, send to treasury
        boostToken.safeTransferFrom(msg.sender, address(this), vaultRewardChangePrice);
        boostToken.safeApprove(address(treasury), vaultRewardChangePrice);
        treasury.deposit(boostToken, vaultRewardChangePrice);

        // increase price
        vaultRewardChangePrice = vaultRewardChangePrice.mul(PRICE_INCREASE).div(DENOM);
        // update vaultRewardLastUpdateTime
        vaultRewardLastUpdateTime = block.timestamp;
        if (isIncrease) {
            globalVaultRewardPercentage = Math.min(DENOM, globalVaultRewardPercentage.add(25));
        } else {
            globalVaultRewardPercentage = globalVaultRewardPercentage.sub(25);
        }
    }

    // handle vault withdrawal
    function withdraw(address token, uint256 withdrawAmount) external updateEpoch {
        TokenStratInfo storage info = tokenStratsInfo[token];
        require(msg.sender == (address(info.vault)), "!vault");
        uint256 remainingWithdrawAmount = withdrawAmount;

        for (uint256 i = 0; i < info.strategies.length; i++) {
            if (remainingWithdrawAmount == 0) break;
            IStrategy strategy = info.strategies[i];
            // withdraw maximum amount possible
            uint256 actualWithdrawAmount = Math.min(
                investedAmounts[address(strategy)], remainingWithdrawAmount
            );
            // update remaining withdraw amt
            remainingWithdrawAmount = remainingWithdrawAmount.sub(actualWithdrawAmount);
            // update strat invested amt
            investedAmounts[address(strategy)] = investedAmounts[address(strategy)]
                    .sub(actualWithdrawAmount);
            // do the actual withdrawal
            strategy.withdraw(actualWithdrawAmount);
        }
    }

    function withdrawAll(address strategy) external updateEpoch {
        require(
            msg.sender == strategist ||
            msg.sender == gov,
            "!authorized"
        );
        investedAmounts[strategy] = 0;
        IStrategy(strategy).withdrawAll();
    }

    function increaseHurdleRate(address token) public updateEpoch {
        TokenStratInfo storage info = tokenStratsInfo[token];
        require(msg.sender == address(info.rewards) || msg.sender == address(this), "!authorized");
        // see if hurdle rate has to update
        if (info.hurdleLastUpdateTime < currentEpochTime) {
            info.currentHurdleRate = info.nextHurdleRate;
            info.nextHurdleRate = 0;
        }
        info.hurdleLastUpdateTime = block.timestamp;
        // increase hurdle rate by 0.01%
        info.nextHurdleRate = Math.min(HURDLE_RATE_MAX, info.nextHurdleRate.add(1));
    }

    function inCaseTokensGetStuck(address token, uint amount) public updateEpoch {
        require(msg.sender == strategist || msg.sender == gov, "!authorized");
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function inCaseStrategyTokenGetStuck(IStrategy strategy, address token) public updateEpoch {
        require(msg.sender == strategist || msg.sender == gov, "!authorized");
        strategy.withdraw(token);
    }
}