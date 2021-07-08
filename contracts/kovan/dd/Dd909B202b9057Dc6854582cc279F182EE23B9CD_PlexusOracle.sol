// SPDX-License-Identifier: MIT

/**
_____  _
|  __ \| |
| |__) | | _____  ___   _ ___
|  ___/| |/ _ \ \/ / | | / __|
| |    | |  __/>  <| |_| \__ \
|_|   _|_|\___/_/\_\\__,_|___/ 
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/IExternalPlatform.sol";
import "./interfaces/uniswap/IUniswapV2RouterLite.sol";
import "./interfaces/staking/ITokenRewards.sol";
import "./interfaces/ITVLOracle.sol";

contract PlexusOracle is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string[] public farmTokenPlusFarmNames;
    address[] public farmAddresses;
    address[] public farmTokens;
    address public uniswapAddress;
    address public rewardAddress;
    address public coreAddress;
    address public tier1Address;
    address private usdcCoinAddress;
    address private tvlOracleAddress;
    mapping (string  => address) public platformDirectory;
    mapping (string => address) private farmDirectoryByName;
    mapping (address => mapping(address =>uint256)) private farmManuallyEnteredAPYs;
    mapping (address => mapping (address  => address )) private farmOracleObtainedAPYs;
    IUniswapV2RouterLite private uniswap;
    ITokenRewards private reward;
    ITVLOracle private tvlOracle;

    constructor() payable {
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function initialize(address _uniswap, address _usdc) external initializeOnceOnly {
        uniswapAddress = _uniswap;
        uniswap = IUniswapV2RouterLite(uniswapAddress);
        usdcCoinAddress = _usdc;
    }

    function updateTVLAddress(address theAddress) external onlyOwner returns (bool) {
        tvlOracleAddress = theAddress;
        tvlOracle = ITVLOracle(theAddress);
        updateDirectory("TVLORACLE", theAddress);
        return true;
    }

    function updatePriceOracleAddress(address theAddress) external onlyOwner returns (bool) {
        uniswapAddress = theAddress;
        uniswap = IUniswapV2RouterLite(theAddress);
        updateDirectory("UNISWAP", theAddress);
        return true;
    }

    function updateUSD(address theAddress) external onlyOwner returns (bool) {
        usdcCoinAddress = theAddress;
        updateDirectory("USD", theAddress);
        return true;
    }

    function updateRewardAddress(address theAddress) external onlyOwner returns (bool) {
        rewardAddress = theAddress;
        reward = ITokenRewards(theAddress);
        updateDirectory("REWARDS", theAddress);
        return true;
    }

    function updateCoreAddress(address theAddress) external onlyOwner returns (bool) {
        coreAddress = theAddress;
        updateDirectory("CORE", theAddress);
        return true;
    }

    function updateTier1Address(address theAddress) external onlyOwner returns (bool) {
        tier1Address = theAddress;
        updateDirectory("TIER1", theAddress);
        return true;
    }

    function setPlatformContract(
        string memory name,
        address farmAddress,
        address farmToken,
        address platformAddress
    ) external onlyOwner returns (bool) {
        farmTokenPlusFarmNames.push(name);
        farmAddresses.push(farmAddress);
        farmTokens.push(farmToken);

        farmOracleObtainedAPYs[farmAddress][farmToken] = platformAddress;
        farmDirectoryByName[name] = platformAddress;

        return true;
    }

    function replaceAllStakableDirectory(
        string[] memory theNames,
        address[] memory theFarmAddresses,
        address[] memory theFarmTokens
    ) external onlyOwner returns (bool) {
        farmTokenPlusFarmNames = theNames;
        farmAddresses = theFarmAddresses;
        farmTokens = theFarmTokens;
        return true;
    }

    function getTotalValueLockedInternalByToken(
        address tokenAddress,
        address tier2Address
    ) external view returns (uint256) {
        uint256 result = tvlOracle.getTotalValueLockedInternalByToken(tokenAddress, tier2Address);
        return result;
    }

    function getTotalValueLockedAggregated(uint256 optionIndex) external view returns (uint256) {
        uint256 result = tvlOracle.getTotalValueLockedAggregated(optionIndex);
        return result;
    }

    function getStakableTokens() external view returns (address[] memory, string[] memory) {
        address[] memory stakableAddrs = farmAddresses;
        string[] memory stakableNames = farmTokenPlusFarmNames;
        return (stakableAddrs, stakableNames);
    }

    function getAmountStakedByUser(
        address tokenAddress,
        address userAddress,
        address tier2Address
    ) external view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(tier2Address);
        return exContract.getStakedPoolBalanceByUser(userAddress, tokenAddress);
    }

    function getUserCurrentReward(
        address userAddress,
        address tokenAddress,
        address tier2FarmAddress
    ) external view returns (uint256) {
        uint256 userStartTime = reward.depositBalancesDelegated(userAddress, tokenAddress, 0);

        uint256 principalAmount = reward.depositBalancesDelegated(userAddress, tokenAddress, 1);
        uint256 apr = reward.tokenAPRs(tokenAddress);
        uint256 result = reward.calculateRewards(
            userStartTime, 
            block.timestamp, 
            principalAmount, 
            apr
        );
        return result;
    }

    function getTokenPrice(address tokenAddress, uint256 amount) external view returns (uint256) {
        address[] memory addresses = new address[](2);
        addresses[0] = tokenAddress;
        addresses[1] = usdcCoinAddress;
        uint256[] memory amounts = getUniswapPrice(addresses, amount);
        uint256 resultingTokens = amounts[1];
        return resultingTokens;
    }

    function getUserWalletBalance(
        address userAddress, 
        address tokenAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    function getCommissionByContract(address platformContract) external view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.commission();
    }

    function getTotalStakedByContract(
        address platformContract,
        address tokenAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.totalAmountStaked(tokenAddress);
    }

    function getAmountCurrentlyDepositedByContract(
        address platformContract,
        address tokenAddress,
        address userAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.depositBalances(userAddress, tokenAddress);
    }

    function getAmountCurrentlyFarmStakedByContract(
        address platformContract,
        address tokenAddress,
        address userAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.getStakedPoolBalanceByUser(userAddress, tokenAddress);
    }

    function getUserTokenBalance(
        address userAddress, 
        address tokenAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    function updateDirectory(
        string memory name, 
        address theAddress
    ) 
        public 
        onlyOwner 
        returns (bool) 
    {
        platformDirectory[name] = theAddress;
        return true;
    }

    function getAPR(address farmAddress, address farmToken) public view returns (uint256) {
        uint256 obtainedAPY = farmManuallyEnteredAPYs[farmAddress][farmToken];

        if (obtainedAPY == 0) {
            IExternalPlatform exContract = IExternalPlatform(
                farmOracleObtainedAPYs[farmAddress][farmToken]
            );
            try exContract.getAPR(farmAddress, farmToken) returns (uint256 apy) {
                return apy;
            } catch (bytes memory) {
                return (0);
            }
        } else {
            return obtainedAPY;
        }
    }

    function getAddress(string memory component) public view returns (address) {
        return platformDirectory[component];
    }

    function calculateCommission(
        uint256 amount, 
        uint256 commission
    ) 
        public 
        pure 
        returns (uint256) 
    {
        uint256 commissionForDAO = (amount.mul(1000).mul(commission)).div(10000000);
        return commissionForDAO;
    }

    function getUniswapPrice(
        address[] memory theAddresses, 
        uint256 amount
    ) 
        internal 
        view 
        returns (uint256[] memory amounts1) 
    {
        uint256[] memory amounts = uniswap.getAmountsOut(amount, theAddresses);
        return amounts;
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

interface IExternalPlatform {
    function getAPR(address _farmAddress, address _tokenAddress)
        external
        view
        returns (uint256 apy);

    function getStakedPoolBalanceByUser(address _owner, address tokenAddress)
        external
        view
        returns (uint256);

    function depositBalances(address userAddress, address tokenAddress)
        external
        view
        returns (uint256);

    function totalAmountStaked(address tokenAddress)
        external
        view
        returns (uint256);
        
    function commission() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IUniswapV2RouterLite {
    function getAmountsOut(
        uint256 amountIn, 
        address[] memory path
    )
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ITokenRewards {
    function addTokenToWhitelist(address newTokenAddress)
        external
        returns (bool);

    function removeTokenFromWhitelist(address tokenAddress)
        external
        returns (bool);

    function stake(
        uint256 amount,
        address tokenAddress,
        address onBehalfOf
    ) external returns (bool);

    function stakeDelegated(
        uint256 amount,
        address tokenAddress,
        address onBehalfOf
    ) external returns (bool);

    function unstakeAndClaim(
        address onBehalfOf,
        address tokenAddress,
        address recipient
    ) external returns (uint256);

    function unstakeAndClaimDelegated(
        address onBehalfOf,
        address tokenAddress,
        address recipient
    ) external returns (uint256);

    function updateAPR(uint256 newAPR, address stakedToken)
        external
        returns (bool);

    function updateLPStakingTokenAddress(address newAddress)
        external
        returns (bool);

    function updateStakingTokenAddress(address newAddress)
        external
        returns (bool);

    function calculateRewards(
        uint256 timestampStart,
        uint256 timestampEnd,
        uint256 principalAmount,
        uint256 apr
    ) external view returns (uint256);

    function depositBalances(
        address,
        address,
        uint256
    ) external view returns (uint256);

    function depositBalancesDelegated(
        address,
        address,
        uint256
    ) external view returns (uint256);

    function lpTokensInRewardsReserve() external view returns (uint256);
    function owner() external view returns (address);
    function stakingLPTokensAddress() external view returns (address);
    function stakingTokenWhitelist(address) external view returns (bool);
    function stakingTokensAddress() external view returns (address);
    function tokenAPRs(address) external view returns (uint256);
    function tokenDeposits(address, address) external view returns (uint256);

    function tokenDepositsDelegated(address, address)
        external
        view
        returns (uint256);

    function tokensInRewardsReserve() external view returns (uint256);
    
    function checkIfTokenIsWhitelistedForStaking(address tokenAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ITVLOracle {
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

{
  "optimizer": {
    "enabled": true,
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
  "libraries": {}
}