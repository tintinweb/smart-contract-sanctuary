// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/IPlexusOracle.sol";

// TokenRewards contract on Mainnet: 0x2ae7b37ab144b5f8c803546b83e81ad297d8c2c4

contract TokenRewards is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    address public stakingTokensAddress;
    address public stakingLPTokensAddress;
    address ETH_TOKEN_ADDRESS;
    address public oracleAddress;
    uint256 public tokensInRewardsReserve;
    uint256 public lpTokensInRewardsReserve;
    //(100% APR = 100000), .01% APR = 10)
    mapping (address => uint256) public tokenAPRs;
    mapping (address => bool) public stakingTokenWhitelist;
    mapping (address => mapping(address => uint256[])) public depositBalances;
    mapping (address => mapping(address => uint256)) public tokenDeposits;
    mapping (address => mapping(address => uint256[])) public depositBalancesDelegated;
    mapping (address => mapping(address => uint256)) public tokenDepositsDelegated;
    IPlexusOracle private oracle;

    constructor() payable {
    }

    modifier onlyTier1 {
        require(
            msg.sender == oracle.getAddress("TIER1"),
            "Only oracles TIER1 can call this function."
        );
        _;
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    function initialize() external initializeOnceOnly {
        tokensInRewardsReserve = 0;
        lpTokensInRewardsReserve  = 0;
        ETH_TOKEN_ADDRESS  = address(0x0);
    }

    function updateOracleAddress(address newOracleAddress) external onlyOwner returns (bool) {
        oracleAddress = newOracleAddress;
        oracle = IPlexusOracle(newOracleAddress);
        return true;
    }

    function updateStakingTokenAddress(address newAddress) external onlyOwner returns (bool) {
        stakingTokensAddress = newAddress;
        return true;
    }

    function updateLPStakingTokenAddress(address newAddress) external onlyOwner returns (bool) {
        stakingLPTokensAddress = newAddress;
        return true;
    }

    function addTokenToWhitelist(address newTokenAddress) external onlyOwner returns (bool) {
        stakingTokenWhitelist[newTokenAddress] = true;
        return true;
    }

    function removeTokenFromWhitelist(address tokenAddress) external onlyOwner returns (bool) {
        stakingTokenWhitelist[tokenAddress] = false;
        return true;
    }

    // APR should have be in this format (uint representing decimals): 
    // (100% APR = 100000), .01% APR = 10)
    function updateAPR(
        uint256 newAPR, 
        address stakedToken
    ) 
        external 
        onlyOwner 
        returns (bool) 
    {
        tokenAPRs[stakedToken] = newAPR;
        return true;
    }

    function getTokenWhiteListValue(
        address newTokenAddress
    ) 
        external 
        view 
        onlyOwner 
        returns(bool) 
    {
        return stakingTokenWhitelist[newTokenAddress];
    }

    function checkIfTokenIsWhitelistedForStaking(
        address tokenAddress
    )
        external
        view 
        returns (bool) 
    {
        return stakingTokenWhitelist[tokenAddress];
    }

    function stake(
        uint256 amount,
        address tokenAddress,
        address onBehalfOf
    ) 
        public 
        nonZeroAmount(amount) 
        returns (bool) 
    {
        require(
            stakingTokenWhitelist[tokenAddress] == true,
            "The token you are staking is not whitelisted to earn rewards"
        );

        IERC20Metadata token = IERC20Metadata(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        bool redepositing = false;

        if (tokenDeposits[onBehalfOf][tokenAddress] != 0) {
            // uint256 originalUserBalance = depositBalances[onBehalfOf];
            // uint256 amountAfterRewards = unstakeAndClaim(onBehalfOf, address(this));
            redepositing = true;
        }

        if (redepositing == true) {
            depositBalances[onBehalfOf][tokenAddress] = 
                [block.timestamp, (tokenDeposits[onBehalfOf][tokenAddress].add(amount))];
            tokenDeposits[onBehalfOf][tokenAddress] = 
                tokenDeposits[onBehalfOf][tokenAddress].add(amount);
        } else {
            depositBalances[onBehalfOf][tokenAddress] = [block.timestamp, amount];
            tokenDeposits[onBehalfOf][tokenAddress] = amount;
        }

        return true;
    }

    function stakeDelegated(
        uint256 amount,
        address tokenAddress,
        address onBehalfOf
    ) 
        public 
        onlyTier1 
        nonZeroAmount(amount) 
        returns (bool) 
    {
        require(
            stakingTokenWhitelist[tokenAddress] == true,
            "The token you are staking is not whitelisted to earn rewards"
        );

        bool redepositing = false;

        if (tokenDepositsDelegated[onBehalfOf][tokenAddress] != 0) {
            // uint256 originalUserBalance = depositBalances[onBehalfOf];
            // uint256 amountAfterRewards = unstakeAndClaim(onBehalfOf, address(this));
            redepositing = true;
        }

        if (redepositing == true) {
            depositBalancesDelegated[onBehalfOf][tokenAddress] = 
                [block.timestamp, (tokenDepositsDelegated[onBehalfOf][tokenAddress].add(amount))];
            tokenDepositsDelegated[onBehalfOf][tokenAddress] = 
                tokenDepositsDelegated[onBehalfOf][tokenAddress].add(amount);
        } else {
            depositBalancesDelegated[onBehalfOf][tokenAddress] = [block.timestamp, amount];
            tokenDepositsDelegated[onBehalfOf][tokenAddress] = amount;
        }

        return true;
    }

    // when standalone, this is called. It's brother 
    // (delegated version that does not deal with transfers is called in other instances)
    function unstakeAndClaim(
        address onBehalfOf,
        address tokenAddress,
        address recipient
    ) 
        public 
        returns (uint256) 
    {
        require(
            stakingTokenWhitelist[tokenAddress] == true,
            "The token you are staking is not whitelisted"
        );

        require(
            tokenDeposits[onBehalfOf][tokenAddress] > 0,
            "This user address does not have a staked balance for the token"
        );

        uint256 rewards =
            calculateRewards(
                depositBalances[onBehalfOf][tokenAddress][0],
                block.timestamp,
                tokenDeposits[onBehalfOf][tokenAddress],
                tokenAPRs[tokenAddress]
            );
        
        IERC20Metadata principalToken = IERC20Metadata(tokenAddress);
        IERC20Metadata rewardToken = IERC20Metadata(stakingTokensAddress);

        uint256 principalTokenDecimals = principalToken.decimals();
        uint256 rewardTokenDecimals = rewardToken.decimals();

        // account for different token decimals places/denoms
        if (principalTokenDecimals < rewardToken.decimals()) {
            uint256 decimalDiff =
                rewardTokenDecimals.sub(principalTokenDecimals);
            rewards = rewards.mul(10**decimalDiff);
        }

        if (principalTokenDecimals > rewardTokenDecimals) {
            uint256 decimalDiff =
                principalTokenDecimals.sub(rewardTokenDecimals);
            rewards = rewards.div(10**decimalDiff);
        }

        principalToken.safeTransfer(recipient, tokenDeposits[onBehalfOf][tokenAddress]);

        // not requiring this below, as we need to ensure at the very least
        // the user gets their deposited tokens above back.
        rewardToken.safeTransfer(recipient, rewards);

        tokenDeposits[onBehalfOf][tokenAddress] = 0;
        depositBalances[onBehalfOf][tokenAddress] = [block.timestamp, 0];

        return rewards;
    }

    // when apart of ecosystem, delegated is called
    function unstakeAndClaimDelegated(
        address onBehalfOf,
        address tokenAddress,
        address recipient
    ) 
        public 
        onlyTier1 
        returns (uint256) 
    {
        require(
            stakingTokenWhitelist[tokenAddress] == true,
            "The token you are staking is not whitelisted"
        );

        require(
            tokenDepositsDelegated[onBehalfOf][tokenAddress] > 0,
            "This user address does not have a staked balance for the token"
        );

        uint256 rewards =
            calculateRewards(
                depositBalancesDelegated[onBehalfOf][tokenAddress][0],
                block.timestamp,
                tokenDepositsDelegated[onBehalfOf][tokenAddress],
                tokenAPRs[tokenAddress]
            );
        // uint256 principalPlusRewards = 
        //     tokenDepositsDelegated[onBehalfOf][tokenAddress].add(rewards);

        IERC20Metadata principalToken = IERC20Metadata(tokenAddress);
        IERC20Metadata rewardToken = IERC20Metadata(stakingTokensAddress);

        uint256 principalTokenDecimals = principalToken.decimals();
        uint256 rewardTokenDecimals = rewardToken.decimals();

        // account for different token decimals places/denoms
        if (principalTokenDecimals < rewardToken.decimals()) {
            uint256 decimalDiff = rewardTokenDecimals.sub(principalTokenDecimals);
            rewards = rewards.mul(10**decimalDiff);
        }

        if (principalTokenDecimals > rewardTokenDecimals) {
            uint256 decimalDiff = principalTokenDecimals.sub(rewardTokenDecimals);
            rewards = rewards.div(10**decimalDiff);
        }

        rewardToken.safeTransfer(recipient, rewards);

        tokenDepositsDelegated[onBehalfOf][tokenAddress] = 0;
        depositBalancesDelegated[onBehalfOf][tokenAddress] = [block.timestamp, 0];

        return rewards;
    }

    function adminEmergencyWithdrawTokens(
        address token,
        uint256 amount,
        address payable destination
    ) 
        public 
        onlyOwner 
        returns (bool) 
    {
        if (address(token) == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            IERC20Metadata token_ = IERC20Metadata(token);
            token_.safeTransfer(destination, amount);
        }

        return true;
    }

    // APR should have 3 zeroes after decimal (100% APR = 100000), .01% APR = 10)
    function calculateRewards(
        uint256 timestampStart,
        uint256 timestampEnd,
        uint256 principalAmount,
        uint256 apr
    ) public pure returns (uint256) {
        uint256 timeDiff = timestampEnd.sub(timestampStart);
        if (timeDiff <= 0) {
            return 0;
        }

        apr = apr.mul(10000000);
        
        // 365.25 days, accounting for leap years. We should just have 1/4 days
        // at the end of each year and cause more mass confusion than daylight savings. 
        // "Please set your clocks back 6 hours on Jan 1st, Thank you""
        // Imagine new years. 
        // You get to do it twice after 6hours. 
        // Or would it be recursive and end up in an infinite loop. 
        // Is that the secret to freezing time and staying young?
        // Maybe because it's 2020.
        uint256 secondsInAvgYear = 31557600;

        uint256 rewardsPerSecond = (principalAmount.mul(apr)).div(secondsInAvgYear);
        uint256 rawRewards = timeDiff.mul(rewardsPerSecond);
        uint256 normalizedRewards = rawRewards.div(10000000000);
        return normalizedRewards;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import './OwnableProxied.sol';

contract OwnableUpgradeable is OwnableProxied {
    /*
     * @notice Modifier to make body of function only execute if the contract has not already been initialized.
     */
    address payable public proxy;
    modifier initializeOnceOnly() {
         if(!initialized[target]) {
             initialized[target] = true;
             emit EventInitialized(target);
             _;
         } else revert();
     }

    modifier onlyProxy() {
        require(msg.sender == proxy);
        _;
    }

    /**
     * @notice Will always fail if called. This is used as a placeholder for the contract ABI.
     * @dev This is code is never executed by the Proxy using delegate call
     */
    function upgradeTo(address) public pure override {
        assert(false);
    }

    /**
     * @notice Initialize any state variables that would normally be set in the contructor.
     * @dev Initialization functionality MUST be implemented in inherited upgradeable contract if the child contract requires
     * variable initialization on creation. This is because the contructor of the child contract will not execute
     * and set any state when the Proxy contract targets it.
     * This function MUST be called stright after the Upgradeable contract is set as the target of the Proxy. This method
     * can be overwridden so that it may have arguments. Make sure that the initializeOnceOnly() modifier is used to protect
     * from being initialized more than once.
     * If a contract is upgraded twice, pay special attention that the state variables are not initialized again
     */
    /*function initialize() public initializeOnceOnly {
        // initialize contract state variables here
    }*/

    function setProxy(address payable theAddress) public onlyOwner {
        proxy = theAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPlexusOracle {
    function getTotalValueLockedInternalByToken(
        address tokenAddress,
        address tier2Address
    ) 
        external 
        view 
        returns (uint256);

    function getTotalValueLockedAggregated(uint256 optionIndex)
        external
        view
        returns (uint256);

    function getStakableTokens()
        external
        view
        returns (address[] memory, string[] memory);

    function getAPR(
        address tier2Address, 
        address tokenAddress
    )
        external
        view
        returns (uint256);

    function getAmountStakedByUser(
        address tokenAddress,
        address userAddress,
        address tier2Address
    ) 
        external 
        view 
        returns (uint256);

    function getUserCurrentReward(
        address userAddress,
        address tokenAddress,
        address tier2FarmAddress
    ) 
        external 
        view 
        returns (uint256);

    function getTokenPrice(address tokenAddress)
        external
        view
        returns (uint256);

    function getUserWalletBalance(
        address userAddress, 
        address tokenAddress
    )
        external
        view
        returns (uint256);
        
    function getAddress(string memory) external view returns (address);
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

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

/*
 * @title Proxied v0.5
 * @author Jack Tanner
 * @notice The Proxied contract acts as the parent contract to Proxy and Upgradeable with and creates space for
 * state variables, functions and events that will be used in the upgraeable system.
 *
 * @dev Both the Proxy and Upgradeable need to hae the target and initialized state variables stored in the exact
 * same storage location, which is why they must both inherit from Proxied. Defining them in the saparate contracts
 * does not work.
 *
 * @param target - This stores the current address of the target Upgradeable contract, which can be modified by
 * calling upgradeTo()
 *
 * @param initialized - This mapping records which targets have been initialized with the Upgradeable.initialize()
 * function. Target Upgradeable contracts can only be intitialed once.
 */
abstract contract OwnableProxied is Ownable {
    address public target;
    mapping(address => bool) public initialized;

    event EventUpgrade(
        address indexed newTarget,
        address indexed oldTarget,
        address indexed admin
    );
    event EventInitialized(address indexed target);

    function upgradeTo(address _target) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        _owner = newOwner;
        return true;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

