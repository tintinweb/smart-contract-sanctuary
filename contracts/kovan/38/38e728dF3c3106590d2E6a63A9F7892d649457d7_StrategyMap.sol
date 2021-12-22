// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IBiosRewards.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IIntegrationMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

contract BiosRewards is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IBiosRewards
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint256 private totalBiosRewards;
    uint256 private totalClaimedBiosRewards;
    mapping(address => uint256) private totalUserClaimedBiosRewards;
    mapping(address => uint256) public periodFinish;
    mapping(address => uint256) public rewardRate;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewardPerTokenStored;
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    uint32 private _biosRewardsDuration;

    event RewardAdded(address indexed token, uint256 reward, uint32 duration);

    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        uint32 biosRewardsDuration
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        _biosRewardsDuration = biosRewardsDuration;
    }

    modifier updateReward(address token, address account) {
        rewardPerTokenStored[token] = rewardPerToken(token);
        lastUpdateTime[token] = lastTimeRewardApplicable(token);
        if (account != address(0)) {
            rewards[token][account] = earned(token, account);
            userRewardPerTokenPaid[token][account] = rewardPerTokenStored[
                token
            ];
        }
        _;
    }

    /// @param biosRewardsDuration_ The duration in seconds for a BIOS rewards period to last
    function setBiosRewardsDuration(uint32 biosRewardsDuration_)
        external
        override
        onlyController
    {
        require(
            _biosRewardsDuration != biosRewardsDuration_,
            "BiosRewards::setBiosRewardsDuration: Duration must be set to a new value"
        );
        require(
            biosRewardsDuration_ > 0,
            "BiosRewards::setBiosRewardsDuration: Duration must be greater than zero"
        );

        _biosRewardsDuration = biosRewardsDuration_;
    }

    /// @param sender The account seeding BIOS rewards
    /// @param biosAmount The amount of BIOS to add to rewards
    function seedBiosRewards(address sender, uint256 biosAmount)
        external
        override
        onlyController
    {
        require(
            biosAmount > 0,
            "BiosRewards::seedBiosRewards: BIOS amount must be greater than zero"
        );

        IERC20MetadataUpgradeable bios = IERC20MetadataUpgradeable(
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getBiosTokenAddress()
        );

        bios.safeTransferFrom(
            sender,
            moduleMap.getModuleAddress(Modules.Kernel),
            biosAmount
        );

        _increaseBiosRewards();
    }

    /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
    function increaseBiosRewards() external override onlyController {
        _increaseBiosRewards();
    }

    /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
    function _increaseBiosRewards() private {
        IBiosRewards biosRewards = IBiosRewards(
            moduleMap.getModuleAddress(Modules.BiosRewards)
        );
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        address biosAddress = integrationMap.getBiosTokenAddress();
        uint256 kernelBiosBalance = IERC20MetadataUpgradeable(biosAddress)
            .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));

        require(
            kernelBiosBalance >
                biosRewards.getBiosRewards() +
                    userPositions.totalTokenBalance(biosAddress),
            "BiosRewards::increaseBiosRewards: No available BIOS to add to rewards"
        );

        uint256 availableBiosRewards = kernelBiosBalance -
            biosRewards.getBiosRewards() -
            userPositions.totalTokenBalance(biosAddress);

        uint256 tokenCount = integrationMap.getTokenAddressesLength();
        uint256 biosRewardWeightSum = integrationMap.getBiosRewardWeightSum();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address token = integrationMap.getTokenAddress(tokenId);
            uint256 tokenBiosRewardWeight = integrationMap
                .getTokenBiosRewardWeight(token);
            uint256 tokenBiosRewardAmount = (availableBiosRewards *
                tokenBiosRewardWeight) / biosRewardWeightSum;
            _increaseTokenBiosRewards(token, tokenBiosRewardAmount);
        }
    }

    /// @param token The address of the ERC20 token contract
    /// @param biosReward The added reward amount
    function _increaseTokenBiosRewards(address token, uint256 biosReward)
        private
    {
        IBiosRewards biosRewards = IBiosRewards(
            moduleMap.getModuleAddress(Modules.BiosRewards)
        );

        require(
            IERC20MetadataUpgradeable(
                IIntegrationMap(
                    moduleMap.getModuleAddress(Modules.IntegrationMap)
                ).getBiosTokenAddress()
            ).balanceOf(moduleMap.getModuleAddress(Modules.Kernel)) >=
                biosReward + biosRewards.getBiosRewards(),
            "BiosRewards::increaseTokenBiosRewards: Not enough available BIOS for specified amount"
        );

        _notifyRewardAmount(token, biosReward, _biosRewardsDuration);
    }

    /// @notice Allows users to claim their BIOS rewards for each token
    /// @param recipient The address of the user claiming BIOS rewards
    function claimBiosRewards(address recipient)
        external
        override
        onlyController
        returns (uint256 biosClaimed)
    {
        biosClaimed = _claimBiosRewards(recipient);
    }

    /// @notice Allows users to claim their BIOS rewards for each token
    /// @param recipient The address of the user claiming BIOS rewards
    function _claimBiosRewards(address recipient)
        private
        returns (uint256 biosClaimed)
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );

        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address token = integrationMap.getTokenAddress(tokenId);

            if (earned(token, recipient) > 0) {
                biosClaimed += claimReward(token, recipient);
            }
        }

        IERC20MetadataUpgradeable(integrationMap.getBiosTokenAddress())
            .safeTransferFrom(
                moduleMap.getModuleAddress(Modules.Kernel),
                recipient,
                biosClaimed
            );
    }

    /// @param token The address of the ERC20 token contract
    /// @param reward The updated reward amount
    /// @param duration The duration of the rewards period
    function notifyRewardAmount(
        address token,
        uint256 reward,
        uint32 duration
    ) external override {
        _notifyRewardAmount(token, reward, duration);
    }

    function _notifyRewardAmount(
        address token,
        uint256 reward,
        uint32 duration
    ) private updateReward(token, address(0)) {
        if (block.timestamp >= periodFinish[token]) {
            rewardRate[token] = reward / duration;
        } else {
            uint256 remaining = periodFinish[token] - block.timestamp;
            uint256 leftover = remaining * rewardRate[token];
            rewardRate[token] = (reward + leftover) / duration;
        }
        lastUpdateTime[token] = block.timestamp;
        periodFinish[token] = block.timestamp + duration;
        totalBiosRewards += reward;
        emit RewardAdded(token, reward, duration);
    }

    function increaseRewards(
        address token,
        address account,
        uint256 amount
    ) public override onlyController updateReward(token, account) {
        require(amount > 0, "BiosRewards::increaseRewards: Cannot increase 0");
    }

    function decreaseRewards(
        address token,
        address account,
        uint256 amount
    ) public override onlyController updateReward(token, account) {
        require(amount > 0, "BiosRewards::decreaseRewards: Cannot decrease 0");
    }

    function claimReward(address token, address account)
        public
        override
        onlyController
        updateReward(token, account)
        returns (uint256 reward)
    {
        reward = earned(token, account);
        if (reward > 0) {
            rewards[token][account] = 0;
            totalBiosRewards -= reward;
            totalClaimedBiosRewards += reward;
            totalUserClaimedBiosRewards[account] += reward;
        }
        return reward;
    }

    function lastTimeRewardApplicable(address token)
        public
        view
        override
        returns (uint256)
    {
        return MathUpgradeable.min(block.timestamp, periodFinish[token]);
    }

    function rewardPerToken(address token)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalSupply = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        ).totalTokenBalance(token);
        if (totalSupply == 0) {
            return rewardPerTokenStored[token];
        }
        return
            rewardPerTokenStored[token] +
            (((lastTimeRewardApplicable(token) - lastUpdateTime[token]) *
                rewardRate[token] *
                1e18) / totalSupply);
    }

    function earned(address token, address account)
        public
        view
        override
        returns (uint256)
    {
        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        return
            ((userPositions.userTokenBalance(token, account) *
                (rewardPerToken(token) -
                    userRewardPerTokenPaid[token][account])) / 1e18) +
            rewards[token][account];
    }

    function getUserBiosRewards(address account)
        external
        view
        override
        returns (uint256 userBiosRewards)
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );

        for (
            uint256 tokenId;
            tokenId < integrationMap.getTokenAddressesLength();
            tokenId++
        ) {
            userBiosRewards += earned(
                integrationMap.getTokenAddress(tokenId),
                account
            );
        }
    }

    function getTotalClaimedBiosRewards()
        external
        view
        override
        returns (uint256)
    {
        return totalClaimedBiosRewards;
    }

    function getTotalUserClaimedBiosRewards(address account)
        external
        view
        override
        returns (uint256)
    {
        return totalUserClaimedBiosRewards[account];
    }

    function getBiosRewards() external view override returns (uint256) {
        return totalBiosRewards;
    }

    /// @return The Bios Rewards Duration
    function getBiosRewardsDuration() public view override returns (uint32) {
        return _biosRewardsDuration;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IBiosRewards {
    /// @param biosRewardsDuration_ The duration in seconds for a BIOS rewards period to last
    function setBiosRewardsDuration(uint32 biosRewardsDuration_) external;

    /// @param sender The account seeding BIOS rewards
    /// @param biosAmount The amount of BIOS to add to rewards
    function seedBiosRewards(address sender, uint256 biosAmount) external;

    /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
    function increaseBiosRewards() external;

    /// @notice Allows users to claim their BIOS rewards for each token
    /// @param recipient The address of the usuer claiming BIOS rewards
    function claimBiosRewards(address recipient)
        external
        returns (uint256 biosClaimed);

    /// @return The Bios Rewards Duration
    function getBiosRewardsDuration() external view returns (uint32);

    /// @param token The address of the ERC20 token contract
    /// @param reward The updated reward amount
    /// @param duration The duration of the rewards period
    function notifyRewardAmount(
        address token,
        uint256 reward,
        uint32 duration
    ) external;

    function increaseRewards(
        address token,
        address account,
        uint256 amount
    ) external;

    function decreaseRewards(
        address token,
        address account,
        uint256 amount
    ) external;

    function claimReward(address asset, address account)
        external
        returns (uint256 reward);

    function lastTimeRewardApplicable(address token)
        external
        view
        returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function earned(address token, address account)
        external
        view
        returns (uint256);

    function getUserBiosRewards(address account)
        external
        view
        returns (uint256 userBiosRewards);

    function getTotalClaimedBiosRewards() external view returns (uint256);

    function getTotalUserClaimedBiosRewards(address account)
        external
        view
        returns (uint256);

    function getBiosRewards() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;
import "./IStrategyMap.sol";

interface IUserPositions {
    // ##### Structs
    struct TokenMovement {
        address token;
        uint256 amount;
    }

    struct StrategyRecord {
        uint256 strategyId;
        uint256 timestamp;
    }
    struct MigrateStrategy {
        address user;
        TokenMovement[] tokens;
    }
    // ##### Events
    event EnterStrategy(
        uint256 indexed id,
        address indexed user,
        TokenMovement[] tokens
    );
    event ExitStrategy(
        uint256 indexed id,
        address indexed user,
        TokenMovement[] tokens
    );
    event Deposit(
        address indexed user,
        address[] tokens,
        uint256[] tokenAmounts,
        uint256 ethAmount
    );

    // ##### Functions

    /// @notice User is allowed to deposit whitelisted tokens
    /// @param depositor Address of the account depositing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param ethAmount The amount of ETH sent with the deposit
    /// @param migration flag if this is a migration from the old system
    function deposit(
        address depositor,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 ethAmount,
        bool migration
    ) external;

    /// @notice User is allowed to withdraw tokens
    /// @param recipient The address of the user withdrawing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    function withdraw(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bool withdrawWethAsEth
    ) external returns (uint256 ethWithdrawn);

    /// @notice Allows a user to withdraw entire balances of the specified tokens and claim rewards
    /// @param recipient The address of the user withdrawing tokens
    /// @param tokens Array of token address that user is exiting positions from
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    /// @return tokenAmounts The amounts of each token being withdrawn
    /// @return ethWithdrawn The amount of ETH being withdrawn
    /// @return ethClaimed The amount of ETH being claimed from rewards
    /// @return biosClaimed The amount of BIOS being claimed from rewards
    function withdrawAllAndClaim(
        address recipient,
        address[] memory tokens,
        bool withdrawWethAsEth
    )
        external
        returns (
            uint256[] memory tokenAmounts,
            uint256 ethWithdrawn,
            uint256 ethClaimed,
            uint256 biosClaimed
        );

    /// @param user The address of the user claiming ETH rewards
    function claimEthRewards(address user)
        external
        returns (uint256 ethClaimed);

    /// @param asset Address of the ERC20 token contract
    /// @return The total balance of the asset deposited in the system
    function totalTokenBalance(address asset) external view returns (uint256);

    /// @notice Returns the amount that a user has deposited locally, but that isn't in a strategy
    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userTokenBalance(address asset, address account)
        external
        view
        returns (uint256);

    /// @notice Returns the amount that a user can use for strategies (local balance + interconnect balance - deployed)
    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userDeployableBalance(address asset, address account)
        external
        view
        returns (uint256);

    /// @notice Returns the amount that a user has interconnected
    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userInterconnectBalance(address asset, address account)
        external
        view
        returns (uint256);

    /**
    @notice Adds a user's funds to a strategy to be deployed
    @param strategyID  The strategy to enter
    @param tokens  The tokens and amounts to enter into the strategy
     */
    function enterStrategy(uint256 strategyID, TokenMovement[] calldata tokens)
        external;

    /**
    @notice Marks a user's funds as withdrawable
    @param strategyID  The strategy to withdrawfrom
    @param tokens  The tokens and amounts to withdraw
     */
    function exitStrategy(uint256 strategyID, TokenMovement[] calldata tokens)
        external;

    /**
    @notice Updates a user's local balance. Only called by controlled contracts or relayer
    @param assets list of tokens to update
    @param account user 
    @param amounts list of amounts to update 
     */
    function updateUserTokenBalances(
        address[] memory assets,
        address account,
        uint256[] memory amounts,
        bool[] memory add
    ) external;

    /**
    @notice Updates a user's interconnected balance. Only called by controlled contracts or relayer
    @param assets list of tokens to update
    @param account user 
    @param amounts list of amounts to update 
     */
    function updateUserInterconnectBalances(
        address[] memory assets,
        address account,
        uint256[] memory amounts,
        bool[] memory add
    ) external;

    /**
    @notice returns the amount of a given token a user has invested in a given strategy
    @param id  the strategy id
    @param token  the token address
    @param user  the user who holds the funds
    @return amount  the amount of token that the user has invested in the strategy 
     */
    function getUserStrategyBalanceByToken(
        uint256 id,
        address token,
        address user
    ) external view returns (uint256 amount);

    /**
    @notice Returns the amount of a given token that a user has invested across all strategies
    @param token  the token address
    @param user  the user holding the funds
    @return amount  the amount of tokens the user has invested across all strategies
     */
    function getUserInvestedAmountByToken(address token, address user)
        external
        view
        returns (uint256 amount);

    /**
    @notice Returns a user's balances for requested strategies, and the users total invested amounts for each token requested
    @param user  the user to request for
    @param _strategies  the strategies to get balances for
    @param _tokens  the tokens to get balances for
    @return userStrategyBalances  The user's invested funds in the strategies
    @return userBalance  User total token balances
     */
    function getUserBalances(
        address user,
        uint256[] calldata _strategies,
        address[] calldata _tokens
    )
        external
        view
        returns (
            IStrategyMap.StrategyBalance[] memory userStrategyBalances,
            IStrategyMap.GeneralBalance[] memory userBalance
        );

    /**
    @notice Migrates user strategy positions to the new system
    @param users  the user data to add to the strategy
     */
    function migrateUser(uint256 strategyId, MigrateStrategy[] calldata users)
        external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;
import "../libraries/TokenSettings.sol";

interface IIntegrationMap {
    event TokenSettingToggled(
        address indexed token,
        TokenSettings.TokenSettingName indexed settingName,
        bool indexed newValue
    );

    struct Integration {
        bool added;
        string name;
    }

    struct Token {
        uint256 id;
        bool added;
        bool acceptingDeposits;
        bool acceptingWithdrawals;
        bool acceptingLping;
        bool acceptingBridging;
        uint256 biosRewardWeight;
        uint256 reserveRatioNumerator;
        uint256 targetLiquidityRatioNumerator;
        uint256 transferFeeKValueNumerator;
        uint256 transferFeePlatformRatioNumerator;
    }

    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    function addIntegration(address contractAddress, string memory name)
        external;

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param acceptingLping Whether LPing is enabled
    /// @param acceptingBridging Whether bridging is enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    /// @param targetLiquidityRatioNumerator Number that gets divided by target liquidity ratio denominator to get target liquidity ratio
    /// @param transferFeeKValueNumerator Number that gets divided by transfer fee K-value denominator to get K-value
    /// @param transferFeePlatformRatioNumerator Number that gets divided by transfer fee platform ratio denominator to get the ratio of transfer fees sent to the platform instead of LPers
    function addToken(
        address tokenAddress,
        bool acceptingDeposits,
        bool acceptingWithdrawals,
        bool acceptingLping,
        bool acceptingBridging,
        uint256 biosRewardWeight,
        uint256 reserveRatioNumerator,
        uint256 targetLiquidityRatioNumerator,
        uint256 transferFeeKValueNumerator,
        uint256 transferFeePlatformRatioNumerator
    ) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenDeposits(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenDeposits(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenWithdrawals(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenWithdrawals(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenLping(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenLping(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenBridging(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenBridging(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    /// @param rewardWeight The updated token BIOS reward weight
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight)
        external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(
        address tokenAddress,
        uint256 reserveRatioNumerator
    ) external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param targetLiquidityRatioNumerator Number that gets divided by target liquidity ratio denominator to get target liquidity ratio
    function updateTokenTargetLiquidityRatioNumerator(
        address tokenAddress,
        uint256 targetLiquidityRatioNumerator
    ) external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param transferFeeKValueNumerator Number that gets divided by transfer fee K-value denominator to get K-value
    function updateTokenTransferFeeKValueNumerator(
        address tokenAddress,
        uint256 transferFeeKValueNumerator
    ) external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param transferFeePlatformRatioNumerator Number that gets divided by transfer fee platform ratio denominator to get the ratio of transfer fees sent to the platform instead of LPers
    function updateTokenTransferFeePlatformRatioNumerator(
        address tokenAddress,
        uint256 transferFeePlatformRatioNumerator
    ) external;

    /// @param integrationId The ID of the integration
    /// @return The address of the integration contract
    function getIntegrationAddress(uint256 integrationId)
        external
        view
        returns (address);

    /// @param integrationAddress The address of the integration contract
    /// @return The name of the of the protocol being integrated to
    function getIntegrationName(address integrationAddress)
        external
        view
        returns (string memory);

    /// @return The address of the WETH token
    function getWethTokenAddress() external view returns (address);

    /// @return The address of the BIOS token
    function getBiosTokenAddress() external view returns (address);

    /// @param tokenId The ID of the token
    /// @return The address of the token ERC20 contract
    function getTokenAddress(uint256 tokenId) external view returns (address);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The index of the token in the tokens array
    function getTokenId(address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The token BIOS reward weight
    function getTokenBiosRewardWeight(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return rewardWeightSum reward weight of depositable tokens
    function getBiosRewardWeightSum()
        external
        view
        returns (uint256 rewardWeightSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether depositing this token is currently enabled
    function getTokenAcceptingDeposits(address tokenAddress)
        external
        view
        returns (bool);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether withdrawing this token is currently enabled
    function getTokenAcceptingWithdrawals(address tokenAddress)
        external
        view
        returns (bool);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether Lping this token is currently enabled
    function getTokenAcceptingLping(address tokenAddress)
        external
        view
        returns (bool);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether bridging this token is currently enabled
    function getTokenAcceptingBridging(address tokenAddress)
        external
        view
        returns (bool);

    // @param tokenAddress The address of the token ERC20 contract
    // @return bool indicating whether the token has been added
    function getIsTokenAdded(address tokenAddress) external view returns (bool);

    // @param integrationAddress The address of the integration contract
    // @return bool indicating whether the integration has been added
    function getIsIntegrationAdded(address tokenAddress)
        external
        view
        returns (bool);

    /// @notice get the length of supported tokens
    /// @return The quantity of tokens added
    function getTokenAddressesLength() external view returns (uint256);

    /// @notice get the length of supported integrations
    /// @return The quantity of integrations added
    function getIntegrationAddressesLength() external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The number that gets divided by reserve ratio denominator
    function getTokenReserveRatioNumerator(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return The reserve ratio denominator
    function getReserveRatioDenominator() external view returns (uint32);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The number that gets divided by target liquidity ratio denominator
    function getTokenTargetLiquidityRatioNumerator(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return The target liquidity ratio denominator
    function getTargetLiquidityRatioDenominator()
        external
        view
        returns (uint32);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The number that gets divided by transfer fee K-value denominator
    function getTokenTransferFeeKValueNumerator(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return The transfer fee K-value denominator
    function getTransferFeeKValueDenominator() external view returns (uint32);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The number that gets divided by transfer fee platform ratio denominator
    function getTokenTransferFeePlatformRatioNumerator(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return The transfer fee platform ratio denominator
    function getTransferFeePlatformRatioDenominator()
        external
        view
        returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IKernel.sol";

abstract contract Controlled is Initializable, ModuleMapConsumer {
    // controller address => is a controller
    mapping(address => bool) internal _controllers;
    address[] public controllers;

    function __Controlled_init(
        address[] memory controllers_,
        address moduleMap_
    ) public initializer {
        for (uint256 i; i < controllers_.length; i++) {
            _controllers[controllers_[i]] = true;
        }
        controllers = controllers_;
        __ModuleMapConsumer_init(moduleMap_);
    }

    function addController(address controller) external onlyOwner {
        _controllers[controller] = true;
        bool added;
        for (uint256 i; i < controllers.length; i++) {
            if (controller == controllers[i]) {
                added = true;
            }
        }
        if (!added) {
            controllers.push(controller);
        }
    }

    modifier onlyOwner() {
        require(
            IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isOwner(
                msg.sender
            ),
            "Controlled::onlyOwner: Caller is not owner"
        );
        _;
    }

    modifier onlyManager() {
        require(
            IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isManager(
                msg.sender
            ),
            "Controlled::onlyManager: Caller is not manager"
        );
        _;
    }

    modifier onlyController() {
        require(
            _controllers[msg.sender],
            "Controlled::onlyController: Caller is not controller"
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IModuleMap.sol";

abstract contract ModuleMapConsumer is Initializable {
    IModuleMap public moduleMap;

    function __ModuleMapConsumer_init(address moduleMap_) internal initializer {
        moduleMap = IModuleMap(moduleMap_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;
import "../interfaces/IIntegration.sol";
import "./IUserPositions.sol";

interface IStrategyMap {
    // #### Structs
    struct Integration {
        address integration;
        uint32 ammPoolID;
    }
    struct Token {
        uint256 integrationPairIdx;
        address token;
        uint32 weight;
    }

    struct TokenDeploy {
        address integration;
        uint32 ammPoolID;
        address token;
        uint256 amount;
    }

    struct Strategy {
        string name;
        Integration[] integrations;
        Token[] tokens;
        mapping(address => bool) availableTokens;
    }

    struct StrategySummary {
        string name;
        Integration[] integrations;
        Token[] tokens;
    }

    struct StrategyBalance {
        uint256 strategyID;
        GeneralBalance[] tokens;
    }

    struct GeneralBalance {
        address token;
        uint256 balance;
    }

    struct ClosablePosition {
        address integration;
        uint32 ammPoolID;
        uint256 amount;
    }

    // #### Events
    // NewStrategy, UpdateName, UpdateStrategy, DeleteStrategy
    event NewStrategy(
        uint256 indexed id,
        Integration[] integrations,
        Token[] tokens,
        string name
    );
    event UpdateName(uint256 indexed id, string name);
    event UpdateStrategy(
        uint256 indexed id,
        Integration[] integrations,
        Token[] tokens
    );
    event DeleteStrategy(uint256 indexed id);

    // #### Functions
    /**
     @notice Adds a new strategy to the list of available strategies
     @param name  the name of the new strategy
     @param integrations  the integrations and weights that form the strategy
     */
    function addStrategy(
        string calldata name,
        Integration[] calldata integrations,
        Token[] calldata tokens
    ) external;

    /**
    @notice Updates the strategy name
    @param name  the new name
     */
    function updateName(uint256 id, string calldata name) external;

    /**
    @notice Updates a strategy's integrations and tokens
    @param id  the strategy to update
    @param integrations  the new integrations that will be used
    @param tokens  the tokens accepted for new entries
    */
    function updateStrategy(
        uint256 id,
        Integration[] calldata integrations,
        Token[] calldata tokens
    ) external;

    /**
    @notice Deletes a strategy
    @dev This can only be called successfully if the strategy being deleted doesn't have any assets invested in it.
    @dev To delete a strategy with funds deployed in it, first update the strategy so that the existing tokens are no longer available in the strategy, then delete the strategy. This will unwind the users positions, and they will be able to withdraw their funds.
    @param id  the strategy to delete
     */
    function deleteStrategy(uint256 id) external;

    /**
    @notice Increases the amount of a set of tokens in a strategy
    @param id  the strategy to deposit into
    @param tokens  the tokens to deposit
     */
    function increaseStrategy(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external;

    /**
    @notice Decreases the amount of a set of tokens invested in a strategy
    @param id  the strategy to withdraw assets from
    @param tokens  details of the tokens being deposited
     */
    function decreaseStrategy(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external;

    /**
    @notice Getter function to return the nested arrays as well as the name
    @param id  the strategy to return
     */
    function getStrategy(uint256 id)
        external
        view
        returns (StrategySummary memory);

    /**
    @notice Decreases the deployable amount after a deployment/withdrawal
    @param integration  the integration that was changed
    @param poolID  the pool within the integration that handled the tokens
    @param token  the token to decrease for
    @param amount  the amount to reduce the vector by
     */
    function decreaseDeployAmountChange(
        address integration,
        uint32 poolID,
        address token,
        uint256 amount
    ) external;

    /**
    @notice Returns the amount of a given token currently invested in a strategy
    @param id  the strategy id to check
    @param token  The token to retrieve the balance for
    @return amount  the amount of token that is invested in the strategy
     */
    function getStrategyTokenBalance(uint256 id, address token)
        external
        view
        returns (uint256 amount);

    /**
    @notice Returns the total amount of a token invested across all strategies
    @param token  the token to fetch the balance for
    @return amount  the amount of the token currently invested
    */
    function getTokenTotalBalance(address token)
        external
        view
        returns (uint256 amount);

    /**
    @notice Returns the current amount awaiting deployment
    @param integration  the integration to deploy to
    @param poolID  the pool within the integration that should receive the tokens
    @param token  the token to be deployed
    @return the pending deploy amount
     */
    function getDeployAmount(
        address integration,
        uint32 poolID,
        address token
    ) external view returns (int256);

    /**
    @notice Returns balances per strategy, and total invested balances
    @param _strategies  The strategies to retrieve balances for
    @param _tokens  The tokens to retrieve
     */
    function getStrategyBalances(
        uint256[] calldata _strategies,
        address[] calldata _tokens
    )
        external
        view
        returns (
            StrategyBalance[] memory strategyBalances,
            GeneralBalance[] memory generalBalances
        );

    /**
  @notice Returns 1 or more strategies in a single call.
  @param ids  The ids of the strategies to return.
   */
    function getMultipleStrategies(uint256[] calldata ids)
        external
        view
        returns (StrategySummary[] memory);

    /// @notice autogenerated getter definition
    function idCounter() external view returns (uint256);

    /**
    @notice returns the length of the tokens array in a strategy
    @param strategy  the strategy to look up
    @return the length
    */
    function getStrategyTokenLength(uint256 strategy)
        external
        view
        returns (uint256);

    /**
    @notice Clears the list of positions that can be closed to supply a token
    @param tokens  The list of tokens to clear
     */
    function clearClosablePositions(address[] calldata tokens) external;

    /**
    @notice Closes enough positions to provide a requested amount of a token
    @param token  the token to source
    @param amount  the amount to source
     */
    function closePositionsForWithdrawal(address token, uint256 amount)
        external;

    /**
@notice Increases strategy balances without increasing the deploy amount
@param id  The strategy id
@param tokens  the tokens and amounts 
 */
    function increaseTokenBalance(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IIntegration {
    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(address tokenAddress, uint256 amount) external;

    /// @param tokenAddress The address of the withdrawal token
    /// @param amount The amount of the token to withdraw
    function withdraw(address tokenAddress, uint256 amount) external;

    /// @dev Deploys all tokens held in the integration contract to the integrated protocol
    function deploy() external;

    /// @dev Harvests token yield from the integration
    function harvestYield() external;

    /// @dev This returns the total amount of the underlying token that
    /// @dev has been deposited to the integration contract
    /// @param tokenAddress The address of the deployed token
    /// @return The amount of the underlying token that can be withdrawn
    function getBalance(address tokenAddress) external view returns (uint256);

    /// @dev Returns the total amount of yield awaiting to be harvested
    /// @dev using the relevant integration's own function
    /// @param amount The amount of available yield for the specified token
    function getPendingYield(address) external view returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

/// @title TokenSettings contains enum and events for the different token settings used in events in Kernel and IntegrationMap
library TokenSettings {
    enum TokenSettingName {
        rewardWeight,
        reserveRatioNumerator,
        targetLiquidityRatioNumerator,
        transferFeeKValueNumerator,
        transferFeePlatformRatioNumerator,
        deposit,
        withdraw,
        lp,
        bridge
    }

    event TokenSettingUpdated(
        address indexed token,
        TokenSettingName indexed settingName,
        uint256 indexed newValue
    );

    event TokenSettingToggled(
        address indexed token,
        TokenSettingName indexed settingName,
        bool indexed newValue
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;
import "../libraries/TokenSettings.sol";

interface IKernel {
    event Withdraw(
        address indexed user,
        address[] tokens,
        uint256[] tokenAmounts,
        uint256 ethAmount
    );
    event ClaimEthRewards(address indexed user, uint256 ethRewards);
    event ClaimBiosRewards(address indexed user, uint256 biosRewards);
    event WithdrawAllAndClaim(
        address indexed user,
        address[] tokens,
        bool withdrawWethAsEth,
        uint256[] tokenAmounts,
        uint256 ethWithdrawn,
        uint256 ethRewards,
        uint256 biosRewards
    );
    event TokenAdded(
        address indexed tokenAddress,
        bool acceptingDeposits,
        bool acceptingWithdrawals,
        bool acceptingLping,
        bool acceptingBridging,
        uint256 biosRewardWeight,
        uint256 reserveRatioNumerator,
        uint256 targetLiquidityRatioNumerator,
        uint256 transferFeeKValueNumerator,
        uint256 transferFeePlatformRatioNumerator
    );

    event TokenSettingUpdated(
        address indexed token,
        TokenSettings.TokenSettingName indexed settingName,
        uint256 indexed newValue
    );
    event GasAccountUpdated(address gasAccount);
    event TreasuryAccountUpdated(address treasuryAccount);
    event IntegrationAdded(address indexed contractAddress, string name);
    event SetBiosRewardsDuration(uint32 biosRewardsDuration);
    event SeedBiosRewards(uint256 biosAmount);
    event Deploy();
    event HarvestYield();
    event DistributeEth();
    event BiosBuyBack();
    event EthDistributionWeightsUpdated(
        uint32 biosBuyBackEthWeight,
        uint32 treasuryEthWeight,
        uint32 protocolFeeEthWeight,
        uint32 rewardsEthWeight
    );
    event GasAccountTargetEthBalanceUpdated(uint256 gasAccountTargetEthBalance);

    /// @param account The address of the account to check if they are a manager
    /// @return Bool indicating whether the account is a manger
    function isManager(address account) external view returns (bool);

    /// @param account The address of the account to check if they are an owner
    /// @return Bool indicating whether the account is an owner
    function isOwner(address account) external view returns (bool);

    /// @param account The address of the account to check if they are a liquidity provider
    /// @return Bool indicating whether the account is a liquidity provider
    function isLiquidityProvider(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

enum Modules {
    Kernel, // 0
    UserPositions, // 1
    YieldManager, // 2
    IntegrationMap, // 3
    BiosRewards, // 4
    EtherRewards, // 5
    SushiSwapTrader, // 6
    UniswapTrader, // 7
    StrategyMap, // 8
    StrategyManager, // 9
    Interconnects // 10
}

interface IModuleMap {
    function getModuleAddress(Modules key) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../core/Controlled.sol";
import "../interfaces/IIntegration.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IYearnRegistry.sol";
import "../interfaces/IYearnVault.sol";
import "../core/ModuleMapConsumer.sol";

/// @notice Integrates 0x Nodes to Yearn v2 vaults
contract YearnIntegration is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IIntegration
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    address private yearnRegistryAddress;
    mapping(address => uint256) private balances;

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ The address of the module map contract
    /// @param yearnRegistryAddress_ The address of the Yearn registry contract
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address yearnRegistryAddress_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        yearnRegistryAddress = yearnRegistryAddress_;
    }

    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(address tokenAddress, uint256 amount)
        external
        override
        onlyController
    {
        balances[tokenAddress] += amount;
    }

    /// @notice Withdraws token from the integration
    /// @param tokenAddress The address of the underlying token to withdraw
    /// @param amount The amoutn of the token to withdraw
    function withdraw(address tokenAddress, uint256 amount)
        public
        override
        onlyController
    {
        require(
            amount <= balances[tokenAddress],
            "YearnIntegration::withdraw: Withdraw amount exceeds balance"
        );
        address vaultAddress = getVaultAddress(tokenAddress);
        IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
            tokenAddress
        );

        if (token.balanceOf(address(this)) < amount) {
            // Need to withdraw tokens from Yearn vault
            uint256 vaultWithdrawableAmount = getVaultWithdrawableAmount(
                tokenAddress
            );
            if (vaultWithdrawableAmount > 0) {
                // Add 1% to shares amount to withdraw to account for fees
                uint256 sharesAmount = (101 *
                    amount *
                    IERC20MetadataUpgradeable(vaultAddress).balanceOf(
                        address(this)
                    )) /
                    vaultWithdrawableAmount /
                    100;

                if (
                    sharesAmount >
                    IERC20MetadataUpgradeable(vaultAddress).balanceOf(
                        address(this)
                    )
                ) {
                    sharesAmount = IERC20MetadataUpgradeable(vaultAddress)
                        .balanceOf(address(this));
                }

                try IYearnVault(vaultAddress).withdraw(sharesAmount) {} catch {}
            }
        }

        // If there still isn't enough of the withdrawn token, change
        // The withdraw amount to the balance of this contract
        if (token.balanceOf(address(this)) < amount) {
            amount = token.balanceOf(address(this));
        }

        balances[tokenAddress] -= amount;
        token.safeTransfer(moduleMap.getModuleAddress(Modules.Kernel), amount);
    }

    /// @notice Deploys all available tokens to Aave
    function deploy() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
            IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
                integrationMap.getTokenAddress(tokenId)
            );
            uint256 tokenAmount = token.balanceOf(address(this));
            address vaultAddress = getVaultAddress(address(token));

            // Check if a vault for this token exists
            if (vaultAddress != address(0)) {
                if (token.allowance(address(this), vaultAddress) == 0) {
                    token.safeApprove(vaultAddress, type(uint256).max);
                }

                if (tokenAmount > 0) {
                    try
                        IYearnVault(vaultAddress).deposit(
                            tokenAmount,
                            address(this)
                        )
                    {} catch {}
                }
            }
        }
    }

    /// @notice Harvests all token yield from the Aave lending pool
    function harvestYield() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
            IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
                integrationMap.getTokenAddress(tokenId)
            );
            address vaultAddress = getVaultAddress(address(token));

            // Check if a vault exists for the current token
            if (vaultAddress != address(0)) {
                uint256 availableYieldInShares = getAvailableYieldInShares(
                    address(token)
                );
                if (availableYieldInShares > 0) {
                    uint256 balanceBefore = token.balanceOf(address(this));

                    // Harvest the available yield from Yearn vault
                    try
                        IYearnVault(getVaultAddress(address(token))).withdraw(
                            availableYieldInShares
                        )
                    {
                        uint256 harvestedAmount = token.balanceOf(
                            address(this)
                        ) - balanceBefore;
                        if (harvestedAmount > 0) {
                            // Yield has been harvested, transfer it to the Yield Manager
                            token.safeTransfer(
                                moduleMap.getModuleAddress(
                                    Modules.YieldManager
                                ),
                                harvestedAmount
                            );
                        }
                    } catch {}
                }
            }
        }
    }

    /// @dev This returns the total amount of the underlying token that
    /// @dev has been deposited to the integration contract
    /// @param token The address of the deployed token
    /// @return The amount of the underlying token that can be withdrawn
    function getBalance(address token)
        external
        view
        override
        returns (uint256)
    {
        return balances[token];
    }

    /// @param token The address of the token
    /// @return The address of the vault for the specified token
    function getVaultAddress(address token) public view returns (address) {
        try IYearnRegistry(yearnRegistryAddress).latestVault(token) returns (
            address vaultAddress
        ) {
            return vaultAddress;
        } catch {
            return address(0);
        }
    }

    /// @param token The address of the deposited token
    /// @return The price per vault share in the underlying asset
    function getPricePerShare(address token) public view returns (uint256) {
        return IYearnVault(getVaultAddress(token)).pricePerShare();
    }

    /// @param token The address of the deposited token
    /// @return The amount of available yield to be harvested in value of the share token
    function getAvailableYieldInShares(address token)
        public
        view
        returns (uint256)
    {
        uint256 vaultWithdrawableAmount = getVaultWithdrawableAmount(token);

        if (vaultWithdrawableAmount > balances[token]) {
            return vaultWithdrawableAmount - balances[token];
        } else {
            return 0;
        }
    }

    /// @param token The address of the deposited token
    /// @return The amount of the deposited token that can be withdrawn from the vault
    function getVaultWithdrawableAmount(address token)
        public
        view
        returns (uint256)
    {
        IERC20MetadataUpgradeable shareToken = IERC20MetadataUpgradeable(
            getVaultAddress(token)
        );

        return
            (getPricePerShare(token) * shareToken.balanceOf(address(this))) /
            (10**shareToken.decimals());
    }

    /// @dev Returns total amount of pending yield for the specified token in Yearn
    /// @param token The of the token to check for available yield
    /// @return Amount of yield available for harvest
    function getPendingYield(address token)
        external
        view
        override
        returns (uint256)
    {
        return getAvailableYieldInShares(token);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IYearnRegistry {
    /// @notice Gets the vault to use for the specified token
    /// @param token The address of the token
    /// @return The address of the vault
    function latestVault(address token) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IYearnVault {
    function deposit(uint256 amount, address recipient)
        external
        returns (uint256 shares);

    function withdraw(uint256 shares) external;

    function pricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../core/Controlled.sol";
import "../interfaces/IAMMIntegration.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUniswapV3Integration.sol";
import "../vendors/uniswap-v3/INonfungiblePositionManager.sol";
import "../vendors/uniswap-v3/LiquidityAmounts.sol";
import "../vendors/uniswap-v3/IUniswapV3Factory.sol";
import "../vendors/uniswap-v3/IUniswapV3Pool.sol";
import "../vendors/uniswap-v3/TickMath.sol";
import "../core/ModuleMapConsumer.sol";

/// @notice Integrates 0x Nodes into Uniswap V3
/// @notice The Kernel contract should be added as the controller
contract UniswapV3Integration is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IAMMIntegration,
    IUniswapV3Integration,
    IERC721Receiver
{
    /// Libraries
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    /// State
    INonfungiblePositionManager public positionManager;

    IUniswapV3Factory public factory;

    uint32 public override poolIDCounter;

    /// Pool ID => Pool details
    mapping(uint32 => PositionNFT) internal pools;

    // Pool ID => token address => balance held within this contract
    mapping(uint32 => mapping(address => uint256)) public override balances;

    /// Functions

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ The address of the module map contract
    /// @param nonfungiblePositionManager_ The address of the Uniswap Non fungible position mananger
    /// @param uniswapFactory_ the
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address nonfungiblePositionManager_,
        address uniswapFactory_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        positionManager = INonfungiblePositionManager(
            nonfungiblePositionManager_
        );
        factory = IUniswapV3Factory(uniswapFactory_);
    }

    function _verifyPoolAndTokens(address token, uint32 poolID) internal view {
        require(poolID <= poolIDCounter, "invalid pool");
        PositionNFT memory position = pools[poolID];
        if (position.tokenA != token && position.tokenB != token) {
            revert("invalid token");
        }
    }

    modifier verifyPoolAndTokens(address token, uint32 poolID) {
        // Uses a function call to prevent a stack too deep error in the withdraw function
        _verifyPoolAndTokens(token, poolID);
        _;
    }

    function deposit(
        address token,
        uint256 amount,
        uint32 poolID
    ) external override verifyPoolAndTokens(token, poolID) onlyController {
        require(poolID > 0 && poolID <= poolIDCounter, "invalid pool");
        balances[poolID][token] += amount;
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function withdraw(
        address token,
        uint256 amount,
        uint32 poolID
    ) external override verifyPoolAndTokens(token, poolID) onlyController {
        // Fill first from reserves
        require(poolID > 0 && poolID <= poolIDCounter, "invalid pool");
        uint256 transferAmount = amount;
        uint256 reserveAmount = balances[poolID][token];
        PositionNFT memory position = pools[poolID];

        uint256 amount0Withdrawn = 0;
        uint256 amount1Withdrawn = 0;

        if (reserveAmount < amount) {
            // Close positions
            if (reserveAmount > 0) {
                balances[poolID][token] = 0;
            }

            // First, calculate the required drop in liquidity
            // Reduce and collect the calculated amount
            (amount0Withdrawn, amount1Withdrawn) = positionManager
                .decreaseLiquidity(
                    _getDecreaseParams(
                        CalculateDecreaseParams(
                            position.positionID,
                            position.uniPool,
                            token == position.tokenA,
                            amount - reserveAmount
                        )
                    )
                );

            // Attribute the spare token to balances to be redeployed later
            if (token == position.tokenA) {
                balances[poolID][position.tokenB] += amount1Withdrawn;
                transferAmount = amount0Withdrawn + reserveAmount;
            } else {
                balances[poolID][position.tokenA] += amount0Withdrawn;
                transferAmount = amount1Withdrawn + reserveAmount;
            }

            positionManager.collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: position.positionID,
                    recipient: address(this),
                    amount0Max: uint128(amount0Withdrawn),
                    amount1Max: uint128(amount1Withdrawn)
                })
            );
        } else {
            // Transfer from reserves
            balances[poolID][token] -= amount;
        }

        // Transfer the funds
        IERC20MetadataUpgradeable(token).transfer(
            moduleMap.getModuleAddress(Modules.Kernel),
            transferAmount // Change to account for partial inavailability
        );
    }

    struct CalculateDecreaseParams {
        uint256 positionID;
        address uniPool;
        bool isTokenA;
        uint256 amount;
    }

    function _getDecreaseParams(CalculateDecreaseParams memory params)
        internal
        view
        returns (
            INonfungiblePositionManager.DecreaseLiquidityParams memory output
        )
    {
        (
            ,
            ,
            ,
            ,
            ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = positionManager.positions(params.positionID);

        (uint160 currentPrice, , , , , , ) = IUniswapV3Pool(params.uniPool)
            .slot0();
        (uint256 amount0, uint256 amount1) = LiquidityAmounts
            .getAmountsForLiquidity(
                currentPrice,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );

        if (params.isTokenA) {
            if (amount0 <= params.amount) {
                output.liquidity = liquidity;
            } else {
                output.liquidity = LiquidityAmounts.getLiquidityForAmount0(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    params.amount
                );
            }
        } else {
            if (amount1 <= params.amount) {
                output.liquidity = liquidity;
            } else {
                output.liquidity = LiquidityAmounts.getLiquidityForAmount1(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    params.amount
                );
            }
        }
        (uint256 amountA, uint256 amountB) = LiquidityAmounts
            .getAmountsForLiquidity(
                currentPrice,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                output.liquidity
            );

        output.amount0Min = amountA > 0 ? amountA / 10 : amountA;
        output.amount1Min = amountB > 0 ? amountB / 10 : amountB;

        output.deadline = block.timestamp + 1;
        output.tokenId = params.positionID;
    }

    function deploy(uint32 poolID) external override {
        return;
    }

    function manualDeploy(
        uint32 poolID,
        uint256 amount0Min,
        uint256 amount1Min
    ) external onlyController {
        require(poolID > 0 && poolID <= poolIDCounter, "invalid pool");

        PositionNFT memory position = pools[poolID];

        uint256 amountA = 0;
        uint256 amountB = 0;
        if (position.positionID == 0) {
            // Mint new position
            (
                uint256 tokenId,
                ,
                uint256 amount0,
                uint256 amount1
            ) = positionManager.mint(
                    INonfungiblePositionManager.MintParams({
                        token0: position.tokenA,
                        token1: position.tokenB,
                        fee: position.fee,
                        tickLower: position.tickLower,
                        tickUpper: position.tickUpper,
                        amount0Desired: balances[poolID][position.tokenA],
                        amount1Desired: balances[poolID][position.tokenB],
                        amount0Min: amount0Min,
                        amount1Min: amount0Min,
                        recipient: address(this),
                        deadline: block.timestamp
                    })
                );
            pools[poolID].positionID = tokenId;
            balances[poolID][position.tokenA] -= amount0;
            balances[poolID][position.tokenB] -= amount1;
            amountA = amount0;
            amountB = amount1;
        } else {
            // Increase current position
            (, amountA, amountB) = positionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    position.positionID,
                    balances[poolID][position.tokenA],
                    balances[poolID][position.tokenB],
                    amount0Min,
                    amount1Min,
                    block.timestamp
                )
            );
            balances[poolID][position.tokenA] -= amountA;
            balances[poolID][position.tokenB] -= amountB;
        }

        emit DeploySuccess(poolID, amountA, amountB);
    }

    function harvestYield() external override onlyController {
        PositionNFT memory position;
        address yieldManager = moduleMap.getModuleAddress(Modules.YieldManager);
        for (uint32 i = 1; i <= poolIDCounter; i++) {
            position = pools[i];
            if (position.positionID > 0) {
                try
                    positionManager.collect(
                        INonfungiblePositionManager.CollectParams(
                            position.positionID,
                            yieldManager,
                            type(uint128).max,
                            type(uint128).max
                        )
                    )
                returns (uint256 amount0, uint256 amount1) {} catch {
                    emit HarvestYieldError(i);
                }
            }
        }
    }

    function getPoolBalance(uint32 poolID)
        external
        view
        returns (uint256 tokenA, uint256 tokenB)
    {
        require(poolID > 0 && poolID <= poolIDCounter, "invalid pool");
        PositionNFT memory position = pools[poolID];
        // Returns the uniswap pool balances
        (, , , , , , , uint128 liquidity, , , , ) = positionManager.positions(
            position.positionID
        );
        (uint160 price, , , , , , ) = IUniswapV3Pool(position.uniPool).slot0();
        (tokenA, tokenB) = LiquidityAmounts.getAmountsForLiquidity(
            price,
            TickMath.getSqrtRatioAtTick(position.tickLower),
            TickMath.getSqrtRatioAtTick(position.tickUpper),
            liquidity
        );
    }

    function getPool(uint32 poolID)
        external
        view
        override
        returns (PositionNFT memory pool)
    {
        require(poolID > 0 && poolID <= poolIDCounter, "invalid pool");
        return pools[poolID];
    }

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) external onlyManager {
        require(tokenA != address(0), "invalid token A address");
        require(tokenB != address(0), "invalid token B address");
        require(tokenA != tokenB, "same token");
        require(fee > 0, "invalid fee");
        require(tickLower < tickUpper, "invalid ticks");

        // Sort the tokens into the canonical uniswap order
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        poolIDCounter++;
        pools[poolIDCounter] = PositionNFT(
            fee,
            tickLower,
            tickUpper,
            token0,
            token1,
            factory.getPool(token0, token1, fee),
            0
        );
        emit CreatePool(token0, token1, poolIDCounter);
        require(
            IERC20MetadataUpgradeable(tokenA).approve(
                address(positionManager),
                type(uint256).max
            ),
            "approval failed"
        );
        require(
            IERC20MetadataUpgradeable(tokenB).approve(
                address(positionManager),
                type(uint256).max
            ),
            "approval failed"
        );
    }

    function getPendingYield(uint32 poolID)
        external
        view
        returns (uint256 tokenA, uint256 tokenB)
    {
        require(poolID > 0 && poolID <= poolIDCounter, "invalid pool");
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = positionManager.positions(pools[poolID].positionID);

        PositionNFT memory position = pools[poolID];

        if (liquidity > 0) {
            tokenA = uint256(tokensOwed0);
            tokenB = uint256(tokensOwed1);

            tokenA += FullMath.mulDiv(
                IUniswapV3Pool(position.uniPool).feeGrowthGlobal0X128() -
                    feeGrowthInside0LastX128,
                liquidity,
                0x100000000000000000000000000000000 //FixedPoint128.Q128
            );

            tokenB += FullMath.mulDiv(
                IUniswapV3Pool(position.uniPool).feeGrowthGlobal1X128() -
                    feeGrowthInside1LastX128,
                liquidity,
                0x100000000000000000000000000000000 //FixedPoint128.Q128
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IAMMIntegration {
    struct Pool {
        address tokenA;
        address tokenB;
        uint256 positionID; // Used for Uniswap V3
    }

    /// Events
    event CreatePool(
        address indexed tokenA,
        address indexed tokenB,
        uint32 poolID
    );

    event HarvestYieldError(uint32 indexed poolID);

    /// @dev IMPORTANT: poolID must start at 1 for all amm integrations. A poolID of 0 is used to designate a non amm integration.

    /// @param token The address of the deposited token
    /// @param amount The amount of token being deposited
    /// @param poolID  The id of the pool to deposit into
    function deposit(
        address token,
        uint256 amount,
        uint32 poolID
    ) external;

    /// @param token  the token to withdraw
    /// @param amount The amount of token in the pool to withdraw
    /// @param poolID  the pool to withdraw from
    function withdraw(
        address token,
        uint256 amount,
        uint32 poolID
    ) external;

    /// @dev Deploys all the tokens for the specified pools
    function deploy(uint32 poolID) external;

    /// @dev Harvests token yield from the integration
    function harvestYield() external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "../interfaces/IAMMIntegration.sol";

interface IUniswapV3Integration {
    /// Structs
    struct PositionNFT {
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        address tokenA;
        address tokenB;
        address uniPool;
        uint256 positionID;
    }

    // Events
    event DeployError(uint32 indexed poolID);
    event DeploySuccess(
        uint32 indexed poolID,
        uint256 indexed amount0,
        uint256 indexed amount1
    );

    function getPool(uint32 poolID)
        external
        view
        returns (PositionNFT memory pool);

    /// Autogenerated getter function definitions
    function poolIDCounter() external view returns (uint32);

    function balances(uint32 poolID, address token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/// Modified so it compiles with solidity 0.8.4.
pragma solidity 0.8.4;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(
            sqrtRatioAX96,
            sqrtRatioBX96,
            FixedPoint96.Q96
        );
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(
                sqrtRatioX96,
                sqrtRatioBX96,
                amount0
            );
            uint128 liquidity1 = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioX96,
                amount1
            );

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                liquidity,
                sqrtRatioBX96 - sqrtRatioAX96,
                FixedPoint96.Q96
            );
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioX96,
                sqrtRatioBX96,
                liquidity
            );
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioX96,
                liquidity
            );
        } else {
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24 tick)
    {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
            "R"
        );
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24(
            (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
        );
        int24 tickHi = int24(
            (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
        );

        tick = tickLow == tickHi
            ? tickLow
            : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../core/Controlled.sol";
import "../core/ModuleMapConsumer.sol";
import "../interfaces/IAMMIntegration.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/ISushiSwapFactory.sol";
import "../interfaces/ISushiSwapRouter.sol";
import "../interfaces/ISushiSwapPair.sol";
import "../interfaces/ISushiSwapMasterChefV2.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWeth9.sol";

/// @notice Integrates 0x Nodes to SushiSwap
contract SushiSwapIntegrationV2 is Controlled, IAMMIntegration {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
    uint24 slippageNumerator;

    address factoryAddress;
    address swapRouterAddress;
    address masterChef;
    address sushi;
    address wethAddress;

    mapping(uint256 => Pool) private pools;
    uint32 public poolCount;
    uint32[] private poolIds;
    // poolId => MasterChef's poolId
    mapping(uint32 => uint256) private stakings;
    // PoolId => Token => Amount
    mapping(uint256 => mapping(address => uint256)) private balances;

    // Token price ceilings to add some protection against front-runners
    // pairAddress => ratio * 1000
    // This is deprecated but deployed so we cannot remove it!
    mapping(address => uint256) public priceCeilings;

    // yield amounts
    mapping(uint32 => uint256) public yieldBalances;

    event TokensReceived(uint256 amount);
    event LPTokensAcquired(uint256 amount);
    event DepositToPool(uint256 poolId, uint256 amount);
    event WithdrawnFromPool(uint256 poolId, uint256 amount);
    event YieldReceived(uint256 amount);
    event PoolRebalanced(
        uint256 poolId,
        address tokenSold,
        uint256 amountSold,
        address tokenBought,
        uint256 amountBought
    );

    receive() external payable {}

    /// @param controllers_ The address of the controlling contract
    /// @param factoryAddress_ The address of the SushiSwap factory contract
    /// @param swapRouterAddress_ The address of the Sushi swap router contract
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address factoryAddress_,
        address swapRouterAddress_,
        address masterChef_,
        address sushi_,
        uint24 slippageNumerator_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        factoryAddress = factoryAddress_;
        swapRouterAddress = swapRouterAddress_;
        masterChef = masterChef_;
        slippageNumerator = slippageNumerator_;
        sushi = sushi_;
        wethAddress = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getWethTokenAddress();
    }

    // third param is uniswap positionID, not used by sushiswap
    function createPool(
        address tokenA,
        address tokenB,
        uint256
    ) external onlyManager {
        poolCount++;
        pools[poolCount].tokenA = tokenA;
        pools[poolCount].tokenB = tokenB;
        poolIds.push(poolCount);

        if (
            IERC20MetadataUpgradeable(tokenA).allowance(
                address(this),
                swapRouterAddress
            ) == 0
        ) {
            IERC20MetadataUpgradeable(tokenA).safeApprove(
                swapRouterAddress,
                type(uint256).max
            );
        }

        if (
            IERC20MetadataUpgradeable(tokenB).allowance(
                address(this),
                swapRouterAddress
            ) == 0
        ) {
            IERC20MetadataUpgradeable(tokenB).safeApprove(
                swapRouterAddress,
                type(uint256).max
            );
        }
    }

    function configureStaking(uint32 poolId, uint256 masterChefPoolId)
        external
        onlyManager
    {
        _configureStaking(poolId, masterChefPoolId, false);
    }

    function configureStackingOverwrite(uint32 poolId, uint256 masterChefPoolId)
        external
        onlyManager
    {
        _configureStaking(poolId, masterChefPoolId, true);
    }

    function _configureStaking(
        uint32 poolId,
        uint256 masterChefPoolId,
        bool overwrite
    ) internal {
        Pool memory pool = getPool(poolId);
        require(pool.tokenA != address(0), "Pool doesn't exist");

        if (overwrite != true) {
            require(stakings[poolId] == 0, "Staking already configured");
        }

        address pairAddress = pairFor(pool.tokenA, pool.tokenB);

        require(
            ISushiSwapMasterChefV2(masterChef).lpToken(masterChefPoolId) ==
                pairAddress,
            "Incorrect MasterChef's poolId was provided"
        );

        stakings[poolId] = masterChefPoolId;

        // let masterChefV2 pull tokens
        if (
            IERC20MetadataUpgradeable(pairAddress).allowance(
                address(this),
                masterChef
            ) < type(uint256).max
        ) {
            IERC20MetadataUpgradeable(pairAddress).safeApprove(
                masterChef,
                type(uint256).max
            );
        }
    }

    /// @param token The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(
        address token,
        uint256 amount,
        uint32 poolId
    ) external override onlyController {
        balances[poolId][token] += amount;
    }

    /// @param token The address of the deposited token
    /// @param amount The amount of the token being deposited
    function incrementBalance(
        uint32 poolId,
        address token,
        uint256 amount
    ) external onlyManager {
        balances[poolId][token] += amount;
    }

    function getPool(uint32 pid) public view returns (Pool memory) {
        return pools[pid];
    }

    /// @return token The address of the token to get the balance of
    function getBalance(uint32 poolId, address token)
        public
        view
        returns (uint256)
    {
        return balances[poolId][token];
    }

    function getPoolBalance(uint32 poolId)
        external
        view
        returns (uint256 tokenA, uint256 tokenB)
    {
        (tokenA, tokenB) = getTokensPoolValue(poolId);
    }

    function deploy(uint32 poolId) external override onlyController {
        _deploy(poolId);
    }

    function manualDeploy(uint32 poolId) external onlyManager {
        _deploy(poolId);
    }

    function _deploy(uint32 poolId) internal {
        Pool memory pool = getPool(poolId);

        require(pools[poolId].tokenA != address(0), "Pool doesn't exist");

        uint256 balanceA = getBalance(poolId, pool.tokenA);
        uint256 balanceB = getBalance(poolId, pool.tokenB);

        if (balanceA == 0 || balanceB == 0) {
            return;
        } else {
            uint256 amountA;
            uint256 amountB;
            uint256 liquidityAcquired;

            (uint256 reserveA, uint256 reserveB) = getReserves(
                pool.tokenA,
                pool.tokenB
            );

            if (reserveA > reserveB) {
                uint256 k = (reserveA * 1000) / reserveB;
                uint256 balanceBA = (balanceB * k) / 1000;

                if (balanceA < balanceBA) {
                    amountA = balanceA;
                    amountB = (balanceA * 1000) / k;
                } else if (balanceBA < balanceA) {
                    amountA = (balanceB * k) / 1000;
                    amountB = balanceB;
                } else {
                    amountA = balanceA;
                    amountB = balanceB;
                }
            } else if (reserveA < reserveB) {
                uint256 k = (reserveB * 1000) / reserveA;
                uint256 balanceAB = (balanceA * k) / 1000;

                if (balanceB < balanceAB) {
                    amountA = (balanceB * 1000) / k;
                    amountB = balanceB;
                } else if (balanceAB < balanceB) {
                    amountA = balanceA;
                    amountB = (balanceA * k) / 1000;
                } else {
                    amountA = balanceA;
                    amountB = balanceB;
                }
            }

            (, , liquidityAcquired) = ISushiSwapRouter(swapRouterAddress)
                .addLiquidity(
                    pool.tokenA,
                    pool.tokenB,
                    amountA,
                    amountB,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );

            balances[poolId][pool.tokenA] -= amountA;
            balances[poolId][pool.tokenB] -= amountB;

            emit LPTokensAcquired(liquidityAcquired);
            emit DepositToPool(poolId, liquidityAcquired);
        }
    }

    function stakeLPTokens(uint32 poolId) external onlyManager {
        Pool memory pool = getPool(poolId);
        uint256 balance = IERC20MetadataUpgradeable(
            pairFor(pool.tokenA, pool.tokenB)
        ).balanceOf(address(this));
        if (balance > 0) {
            ISushiSwapMasterChefV2(masterChef).deposit(
                stakings[poolId],
                balance,
                address(this)
            );
        }
    }

    function harvestYield() external override onlyController {
        uint256 yieldAmount;
        for (uint32 i = 0; i < poolCount; i++) {
            yieldAmount += yieldBalances[poolIds[i]];
        }
        if (yieldAmount > 0) {
            IERC20MetadataUpgradeable(wethAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.YieldManager),
                yieldAmount
            );
            emit YieldReceived(yieldAmount);
        }
    }

    /// @notice Harvest available yield for all pools positions
    function harvestYieldByPool(
        uint32 poolId,
        uint256 sushiRatioX1000, // SUSHI-WETH
        uint256 tokenARatioX1000, // TOKENA-WETH
        uint256 tokenBRatioX1000, // TOKENB-WETH
        bool convertToWeth
    ) external onlyManager {
        Pool memory pool = getPool(poolId);

        // check ratio ceilings
        if (convertToWeth) {
            checkPriceCeiling(sushi, wethAddress, sushiRatioX1000);
        }

        address biosAddress = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getBiosTokenAddress();
        uint256 yieldAmount;
        // check balances before harvesting
        uint256 tokenABalanceBefore = IERC20MetadataUpgradeable(pool.tokenA)
            .balanceOf(address(this));
        uint256 tokenBBalanceBefore = IERC20MetadataUpgradeable(pool.tokenB)
            .balanceOf(address(this));

        // harvest
        ISushiSwapMasterChefV2(masterChef).harvest(
            stakings[poolId],
            address(this)
        );

        uint256 tokenADiff = IERC20MetadataUpgradeable(pool.tokenA).balanceOf(
            address(this)
        ) - tokenABalanceBefore;
        uint256 tokenBDiff = IERC20MetadataUpgradeable(pool.tokenB).balanceOf(
            address(this)
        ) - tokenBBalanceBefore;

        // convert any rewards received EXCEPT BIOS
        if (tokenADiff > 0) {
            if (address(pool.tokenA) == address(biosAddress)) {
                balances[poolId][pool.tokenA] += tokenADiff;
            } else if (convertToWeth) {
                checkPriceCeiling(pool.tokenA, wethAddress, tokenARatioX1000);
                uint256[] memory amounts = swapExactInput(
                    pool.tokenA,
                    wethAddress,
                    address(this),
                    tokenADiff
                );
                yieldAmount += amounts[1];
            }
        }
        if (tokenBDiff > 0) {
            if (address(pool.tokenB) == address(biosAddress)) {
                balances[poolId][pool.tokenB] += tokenBDiff;
            } else if (convertToWeth) {
                checkPriceCeiling(pool.tokenB, wethAddress, tokenBRatioX1000);
                uint256[] memory amounts = swapExactInput(
                    pool.tokenB,
                    wethAddress,
                    address(this),
                    tokenBDiff
                );
                yieldAmount += amounts[1];
            }
        }
        // check and convert any sushi
        uint256 sushiAmount = IERC20MetadataUpgradeable(sushi).balanceOf(
            address(this)
        );

        if (sushiAmount > 0) {
            uint256[] memory amounts = swapExactInput(
                sushi,
                wethAddress,
                address(this),
                sushiAmount
            );
            yieldAmount += amounts[1];
        }
        if (yieldAmount > 0) {
            yieldBalances[poolId] += yieldAmount;
        }
        emit YieldReceived(yieldAmount);
    }

    /// @notice Withdraws token from the integration
    /// @param tokenAddress The address of the underlying token to withdraw
    /// @param amount The amoutn of the token to withdraw
    function withdraw(
        address tokenAddress,
        uint256 amount,
        uint32 poolId
    ) public override onlyController {
        if (amount <= getBalance(poolId, tokenAddress)) {
            IERC20MetadataUpgradeable(tokenAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amount
            );
            balances[poolId][tokenAddress] -= amount;
        } else {
            _withdraw(tokenAddress, amount, poolId, 0);
        }
    }

    function getTokensPoolValue(uint32 poolId)
        internal
        view
        returns (uint256 amountOfTokenAInPool, uint256 amountOfTokenBInPool)
    {
        Pool memory pool = getPool(poolId);

        uint256 lpAmount = IERC20(pairFor(pool.tokenA, pool.tokenB)).balanceOf(
            address(this)
        ) +
            ISushiSwapMasterChefV2(masterChef)
                .userInfo(stakings[poolId], address(this))
                .amount;

        uint256 sharePercent = (lpAmount * 10000000000) /
            IERC20(pairFor(pool.tokenA, pool.tokenB)).totalSupply();

        amountOfTokenAInPool =
            (IERC20(pool.tokenA).balanceOf(pairFor(pool.tokenA, pool.tokenB)) *
                sharePercent) /
            10000000000;
        amountOfTokenBInPool =
            (IERC20(pool.tokenB).balanceOf(pairFor(pool.tokenA, pool.tokenB)) *
                sharePercent) /
            10000000000;
    }

    function getLiquidityToWithdraw(
        uint256 amountOfTokenAInPool,
        uint256 amountOfTokenBInPool,
        uint32 poolId,
        address tokenAddress,
        uint256 amount
    ) internal view returns (uint256 liquidityToWithdraw) {
        Pool memory pool = getPool(poolId);

        uint256 estimatedTokenAAmount;
        uint256 estimatedTokenBAmount;

        if (tokenAddress == pool.tokenA) {
            estimatedTokenAAmount = amount / 2;
            estimatedTokenBAmount = getAmountOut(
                tokenAddress,
                pool.tokenB,
                amount / 2
            );
        } else if (tokenAddress == pool.tokenB) {
            estimatedTokenAAmount = getAmountOut(
                tokenAddress,
                pool.tokenA,
                amount / 2
            );
            estimatedTokenBAmount = amount / 2;
        }

        uint256 liquidityPercent;

        if (
            estimatedTokenAAmount > amountOfTokenAInPool ||
            estimatedTokenBAmount > amountOfTokenBInPool
        ) {
            liquidityPercent = 100;
        } else {
            liquidityPercent =
                ((estimatedTokenAAmount + estimatedTokenBAmount) * 100) /
                (amountOfTokenAInPool + amountOfTokenBInPool);
        }

        liquidityToWithdraw =
            (ISushiSwapMasterChefV2(masterChef)
                .userInfo(stakings[poolId], address(this))
                .amount * (liquidityPercent)) /
            100;
    }

    function manualWithdraw(
        address tokenAddress,
        uint256 amount,
        uint32 poolId,
        uint256 ratioX1000
    ) external onlyManager {
        if (amount <= getBalance(poolId, tokenAddress)) {
            IERC20MetadataUpgradeable(tokenAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amount
            );
            balances[poolId][tokenAddress] -= amount;
        } else {
            _withdraw(tokenAddress, amount, poolId, ratioX1000);
        }
    }

    function _withdraw(
        address tokenAddress,
        uint256 amount,
        uint32 poolId,
        uint256 ratioX1000
    ) internal {
        Pool memory pool = getPool(poolId);

        if (ratioX1000 > 0) {
            checkPriceCeiling(pool.tokenA, pool.tokenB, ratioX1000);
        }

        (
            uint256 amountOfTokenAInPool,
            uint256 amountOfTokenBInPool
        ) = getTokensPoolValue(poolId);

        uint256 liquidityToWithdraw = getLiquidityToWithdraw(
            amountOfTokenAInPool,
            amountOfTokenBInPool,
            poolId,
            tokenAddress,
            amount
        );

        ISushiSwapMasterChefV2(masterChef).withdraw(
            stakings[poolId],
            liquidityToWithdraw,
            address(this)
        );

        IERC20MetadataUpgradeable(pairFor(pool.tokenA, pool.tokenB))
            .safeApprove(swapRouterAddress, liquidityToWithdraw);

        (uint256 amountTokenA, uint256 amountTokenB) = ISushiSwapRouter(
            swapRouterAddress
        ).removeLiquidity(
                pool.tokenA,
                pool.tokenB,
                liquidityToWithdraw,
                0,
                0,
                address(this),
                block.timestamp + 360
            );

        uint256[] memory amountsOfTokenReceived0;
        uint256[] memory amountsOfTokenReceived1;

        if (tokenAddress == pool.tokenA) {
            amountsOfTokenReceived1 = swapExactInput(
                pool.tokenB,
                tokenAddress,
                address(this),
                amountTokenB
            );

            IERC20MetadataUpgradeable(pool.tokenA).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amountTokenA + amountsOfTokenReceived1[1]
            );

            emit WithdrawnFromPool(
                poolId,
                amountsOfTokenReceived1[1] + amountTokenA
            );
        } else if (tokenAddress == pool.tokenB) {
            amountsOfTokenReceived0 = swapExactInput(
                pool.tokenA,
                tokenAddress,
                address(this),
                amountTokenA
            );

            IERC20MetadataUpgradeable(pool.tokenB).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amountTokenB + amountsOfTokenReceived0[1]
            );

            emit WithdrawnFromPool(
                poolId,
                amountsOfTokenReceived0[1] + amountTokenB
            );
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address of the token out recipient
    /// @param amountIn The exact amount of the input to swap
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn
    ) internal returns (uint256[] memory) {
        uint256 amountOutMin = getAmountOutMinimum(tokenIn, tokenOut, amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256 deadline = block.timestamp;

        if (
            IERC20MetadataUpgradeable(tokenIn).allowance(
                address(this),
                swapRouterAddress
            ) < amountIn
        ) {
            IERC20MetadataUpgradeable(tokenIn).safeApprove(
                swapRouterAddress,
                amountIn
            );
        }

        return
            ISushiSwapRouter(swapRouterAddress).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                recipient,
                deadline
            );
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
    function getAmountOutMinimum(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOutMinimum) {
        amountOutMinimum =
            (getAmountOut(tokenIn, tokenOut, amountIn) *
                (SLIPPAGE_DENOMINATOR - slippageNumerator)) /
            SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        require(amountIn > 0, "amountIn must be greater than zero");
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            tokenIn,
            tokenOut
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "No liquidity in pool reserves"
        );
        uint256 amountInWithFee = amountIn * (997);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return reserveA The reserve balance of tokenA in the pool
    /// @return reserveB The reserve balance of tokenB in the pool
    function getReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = ISushiSwapPair(
            pairFor(tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param token0 The address of sorted token0
    /// @param token1 The address of sorted token1
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Identical token addresses");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Zero address");
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return pair The address of the Sushi pool contract
    function pairFor(address tokenA, address tokenB)
        internal
        view
        returns (address pair)
    {
        pair = ISushiSwapFactory(factoryAddress).getPair(tokenA, tokenB);
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the ordered token0
    /// @return token1 The address of the ordered token1
    function getTokensOrdered(address tokenA, address tokenB)
        public
        pure
        returns (address token0, address token1)
    {
        if (tokenA < tokenB) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }
    }

    /// @dev Returns total amount of pending yield in SUSHI rewards
    /// @return Amount of yield available for harvest
    function getPendingYield(address token, uint256 poolId)
        external
        view
        returns (uint256)
    {
        if (token == address(0)) return 0;

        return
            ISushiSwapMasterChefV2(masterChef).pendingSushi(
                poolId,
                address(this)
            );
    }

    /// @notice Rebalances by attempting to swap up to max to get into position ratio
    /// @param poolId The ID of the pool to rebalance
    /// @param maxSellTokenA max amount of tokenA to sell
    /// @param maxSellTokenB max amount of tokenB to sell
    function rebalancePool(
        uint32 poolId,
        uint256 ratioX1000,
        uint256 maxSellTokenA,
        uint256 maxSellTokenB
    ) external onlyManager {
        Pool memory pool = getPool(poolId);

        require(pools[poolId].tokenA != address(0), "Pool doesn't exist");

        checkPriceCeiling(pool.tokenA, pool.tokenB, ratioX1000);

        // determine which token and how much to swap
        (
            address swapToken,
            uint256 excessAmountToSwap
        ) = calculateExcessTokensToSwap(
                pool,
                getBalance(poolId, pool.tokenA),
                getBalance(poolId, pool.tokenB)
            );

        // handle tokenA vs tokenB, cap at max sell param
        address targetToken;
        uint256 swapAmount;
        if (swapToken == pool.tokenA) {
            targetToken = pool.tokenB;
            swapAmount = excessAmountToSwap < maxSellTokenA
                ? excessAmountToSwap
                : maxSellTokenA;
        } else {
            targetToken = pool.tokenA;
            swapAmount = excessAmountToSwap < maxSellTokenB
                ? excessAmountToSwap
                : maxSellTokenB;
        }

        // track balance change of targetToken
        uint256 targetBalanceBefore = IERC20MetadataUpgradeable(targetToken)
            .balanceOf(address(this));

        // swap tokens
        swapExactInput(swapToken, targetToken, address(this), swapAmount);

        uint256 amountReceived = IERC20MetadataUpgradeable(targetToken)
            .balanceOf(address(this)) - targetBalanceBefore;

        // update pool token balances
        if (amountReceived > 0) {
            balances[poolId][swapToken] -= excessAmountToSwap;
            balances[poolId][targetToken] += amountReceived;

            emit PoolRebalanced(
                poolId,
                swapToken,
                excessAmountToSwap,
                targetToken,
                amountReceived
            );
        }
    }

    function calculateExcessTokensToSwap(
        Pool memory pool,
        uint256 balanceA,
        uint256 balanceB
    ) internal view returns (address swapToken, uint256 excessAmountToSwap) {
        require(balanceA + balanceB > 0, "SushiSwapIntegration: no balance");
        // fetch reserve values from sushi
        (uint256 reserveA, uint256 reserveB) = getReserves(
            pool.tokenA,
            pool.tokenB
        );

        if (reserveA > reserveB) {
            uint256 k = (reserveA * 1000) / reserveB;
            uint256 balanceBA = (balanceB * k) / 1000;

            if (balanceA < balanceBA) {
                // excess tokenB
                excessAmountToSwap = (balanceB - ((balanceA * 1000) / k)) / 2;
                swapToken = pool.tokenB;
            } else if (balanceBA < balanceA) {
                // excess tokenA
                excessAmountToSwap = (balanceA - balanceBA) / 2;
                swapToken = pool.tokenA;
            }
        } else if (reserveA < reserveB) {
            uint256 k = (reserveB * 1000) / reserveA;
            uint256 balanceAB = (balanceA * k) / 1000;

            if (balanceAB < balanceB) {
                // excess tokenB
                excessAmountToSwap = (balanceB - balanceAB) / 2;
                swapToken = pool.tokenB;
            } else if (balanceB < balanceAB) {
                // excess tokenA
                excessAmountToSwap = (balanceA - ((balanceB * 1000) / k)) / 2;
                swapToken = pool.tokenA;
            }
        }
    }

    function checkPriceCeiling(
        address tokenA,
        address tokenB,
        uint256 ratioX1000
    ) internal view {
        address pairAddress = address(pairFor(tokenA, tokenB));
        require(pairAddress != address(0), "SushiSwapIntegration:BadPair");

        uint256 currentRatio;
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB);
        if (reserveA < reserveB) {
            currentRatio = (reserveB * 1000) / reserveA;
        } else if (reserveB < reserveA) {
            currentRatio = (reserveA * 1000) / reserveB;
        } else {
            currentRatio = 1000;
        }

        // limit to 1% off
        if (currentRatio > ratioX1000) {
            require(
                ((currentRatio - ratioX1000) * 100) / ratioX1000 < 1,
                "CeilingLimitReached"
            );
        } else if (ratioX1000 > currentRatio) {
            require(
                ((ratioX1000 - currentRatio) * 100) / ratioX1000 < 1,
                "CeilingLimitReached"
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface ISushiSwapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface ISushiSwapRouter {
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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface ISushiSwapPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "./IERC20.sol";

interface ISushiSwapMasterChefV2 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of SUSHI to distribute per block.
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function updateBalance(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function userInfo(uint256 pid, address user)
        external
        view
        returns (UserInfo memory);

    function lpToken(uint256 input) external view returns (address);

    function rewarder(uint256 input) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    //tmp here
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IWeth9 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    /// @param wad The amount of wETH to withdraw into ETH
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../core/Controlled.sol";
import "../core/ModuleMapConsumer.sol";
import "../interfaces/IAMMIntegration.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/ISushiSwapFactory.sol";
import "../interfaces/ISushiSwapRouter.sol";
import "../interfaces/ISushiSwapPair.sol";
import "../interfaces/ISushiSwapMasterChef.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWeth9.sol";

/// @notice Integrates 0x Nodes to SushiSwap
contract SushiSwapIntegration is Controlled, IAMMIntegration {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
    uint24 slippageNumerator;

    address factoryAddress;
    address swapRouterAddress;
    address masterChef;
    address sushi;
    address wethAddress;

    mapping(uint256 => Pool) private pools;
    uint32 public poolCount;
    uint32[] private poolIds;
    // poolId => MasterChef's poolId
    mapping(uint32 => uint256) private stakings;
    // PoolId => Token => Amount
    mapping(uint256 => mapping(address => uint256)) private balances;

    // Token price ceilings to add some protection against front-runners
    // pairAddress => ratio * 1000
    // DEPRECATED but this var has already been deployed and cannot be removed
    mapping(address => uint256) public priceCeilings;

    // yield amounts
    mapping(uint32 => uint256) public yieldBalances;

    event TokensReceived(uint256 amount);
    event LPTokensAcquired(uint256 amount);
    event DepositToPool(uint256 poolId, uint256 amount);
    event WithdrawnFromPool(uint256 poolId, uint256 amount);
    event YieldReceived(uint256 amount);
    event PoolRebalanced(
        uint256 poolId,
        address tokenSold,
        uint256 amountSold,
        address tokenBought,
        uint256 amountBought
    );

    receive() external payable {}

    /// @param controllers_ The address of the controlling contract
    /// @param factoryAddress_ The address of the SushiSwap factory contract
    /// @param swapRouterAddress_ The address of the Sushi swap router contract
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address factoryAddress_,
        address swapRouterAddress_,
        address masterChef_,
        address sushi_,
        uint24 slippageNumerator_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        factoryAddress = factoryAddress_;
        swapRouterAddress = swapRouterAddress_;
        masterChef = masterChef_;
        slippageNumerator = slippageNumerator_;
        sushi = sushi_;
        wethAddress = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getWethTokenAddress();
    }

    // third param positionID is unused for sushi
    function createPool(
        address tokenA,
        address tokenB,
        uint256
    ) external onlyManager {
        poolCount++;
        pools[poolCount].tokenA = tokenA;
        pools[poolCount].tokenB = tokenB;
        poolIds.push(poolCount);

        if (
            IERC20MetadataUpgradeable(tokenA).allowance(
                address(this),
                swapRouterAddress
            ) < type(uint256).max
        ) {
            IERC20MetadataUpgradeable(tokenA).safeApprove(
                swapRouterAddress,
                type(uint256).max
            );
        }

        if (
            IERC20MetadataUpgradeable(tokenB).allowance(
                address(this),
                swapRouterAddress
            ) < type(uint256).max
        ) {
            IERC20MetadataUpgradeable(tokenB).safeApprove(
                swapRouterAddress,
                type(uint256).max
            );
        }
    }

    function configureStaking(uint32 poolId, uint256 masterChefPoolId)
        external
        onlyController
    {
        _configureStaking(poolId, masterChefPoolId, false);
    }

    function configureStakingOverwrite(uint32 poolId, uint256 masterChefPoolId)
        external
        onlyManager
    {
        _configureStaking(poolId, masterChefPoolId, true);
    }

    function _configureStaking(
        uint32 poolId,
        uint256 masterChefPoolId,
        bool overwrite
    ) internal {
        Pool memory pool = getPool(poolId);
        require(pool.tokenA != address(0), "Pool doesn't exist");

        if (overwrite != true) {
            require(stakings[poolId] == 0, "Staking already configured");
        }

        ISushiSwapMasterChef.PoolInfo memory poolInfo = ISushiSwapMasterChef(
            masterChef
        ).poolInfo(masterChefPoolId);

        address pairAddress = pairFor(pool.tokenA, pool.tokenB);

        require(
            address(poolInfo.lpToken) == pairAddress,
            "Incorrect MasterChef's poolId was provided"
        );

        stakings[poolId] = masterChefPoolId;

        // let master chef pull tokens
        if (
            IERC20MetadataUpgradeable(pairAddress).allowance(
                address(this),
                masterChef
            ) < type(uint256).max
        ) {
            IERC20MetadataUpgradeable(pairAddress).safeApprove(
                masterChef,
                type(uint256).max
            );
        }
    }

    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(
        address tokenAddress,
        uint256 amount,
        uint32 poolId
    ) external override onlyController {
        balances[poolId][tokenAddress] += amount;
    }

    /// @param token The address of the deposited token
    /// @param amount The amount of the token being deposited
    function incrementBalance(
        uint32 poolId,
        address token,
        uint256 amount
    ) external onlyManager {
        balances[poolId][token] += amount;
    }

    function getPool(uint32 pid) public view returns (Pool memory) {
        return pools[pid];
    }

    /// @return tokenAddress The address of the token to get the balance of
    function getBalance(uint32 poolId, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return balances[poolId][tokenAddress];
    }

    function getPoolBalance(uint32 poolId)
        external
        view
        returns (uint256 tokenA, uint256 tokenB)
    {
        (tokenA, tokenB) = getTokensPoolValue(poolId);
    }

    function deploy(uint32 poolId) external override onlyController {
        _deploy(poolId);
    }

    function manualDeploy(uint32 poolId) external onlyManager {
        _deploy(poolId);
    }

    function _deploy(uint32 poolId) internal {
        Pool memory pool = getPool(poolId);

        require(pools[poolId].tokenA != address(0), "Pool doesn't exist");

        uint256 balanceA = getBalance(poolId, pool.tokenA);
        uint256 balanceB = getBalance(poolId, pool.tokenB);

        if (balanceA == 0 || balanceB == 0) {
            return;
        } else {
            uint256 amountA;
            uint256 amountB;
            uint256 liquidityAcquired;

            (uint256 reserveA, uint256 reserveB) = getReserves(
                pool.tokenA,
                pool.tokenB
            );

            if (reserveA > reserveB) {
                uint256 k = (reserveA * 1000) / reserveB;
                uint256 balanceBA = (balanceB * k) / 1000;

                if (balanceA < balanceBA) {
                    amountA = balanceA;
                    amountB = (balanceA * 1000) / k;
                } else if (balanceBA < balanceA) {
                    amountA = (balanceB * k) / 1000;
                    amountB = balanceB;
                } else {
                    amountA = balanceA;
                    amountB = balanceB;
                }
            } else if (reserveA < reserveB) {
                uint256 k = (reserveB * 1000) / reserveA;
                uint256 balanceAB = (balanceA * k) / 1000;

                if (balanceB < balanceAB) {
                    amountA = (balanceB * 1000) / k;
                    amountB = balanceB;
                } else if (balanceAB < balanceB) {
                    amountA = balanceA;
                    amountB = (balanceA * k) / 1000;
                } else {
                    amountA = balanceA;
                    amountB = balanceB;
                }
            }

            (, , liquidityAcquired) = ISushiSwapRouter(swapRouterAddress)
                .addLiquidity(
                    pool.tokenA,
                    pool.tokenB,
                    amountA,
                    amountB,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );

            balances[poolId][pool.tokenA] -= amountA;
            balances[poolId][pool.tokenB] -= amountB;

            emit LPTokensAcquired(liquidityAcquired);
            emit DepositToPool(poolId, liquidityAcquired);
        }
    }

    function stakeLPTokens(uint32 poolId) external onlyManager {
        Pool memory pool = pools[poolId];
        uint256 balance = IERC20MetadataUpgradeable(
            pairFor(pool.tokenA, pool.tokenB)
        ).balanceOf(address(this));
        if (balance > 0) {
            ISushiSwapMasterChef(masterChef).deposit(stakings[poolId], balance);
        }
    }

    function harvestYield() external override onlyController {
        uint256 yieldAmount;
        for (uint32 i = 0; i < poolCount; i++) {
            yieldAmount += yieldBalances[poolIds[i]];
        }
        if (yieldAmount > 0) {
            IERC20MetadataUpgradeable(wethAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.YieldManager),
                yieldAmount
            );
            emit YieldReceived(yieldAmount);
        }
    }

    /// @notice Harvest available yield for desired pool
    function harvestYieldByPool(
        uint32 poolId,
        uint256 sushiRatioX1000, // price ratio for SUSHI!
        bool convertToWeth
    ) external onlyManager {
        // MasterChefV1 does not have an explicit harvest method
        // deposit 0 accomplishes the rewards harvesting
        ISushiSwapMasterChef(masterChef).deposit(stakings[poolId], 0);

        if (convertToWeth) {
            // check and convert any sushi
            uint256 sushiBalance = IERC20MetadataUpgradeable(sushi).balanceOf(
                address(this)
            );

            if (sushiBalance > 0) {
                checkPriceCeiling(sushi, wethAddress, sushiRatioX1000);
                uint256[] memory amounts = swapExactInput(
                    sushi,
                    wethAddress,
                    address(this),
                    sushiBalance,
                    getAmountOutMinimum(sushi, wethAddress, sushiBalance)
                );
                yieldBalances[poolId] += amounts[1];
            }
        }
    }

    /// @notice Withdraws token from the integration
    /// @param tokenAddress The address of the underlying token to withdraw
    /// @param amount The amoutn of the token to withdraw
    function withdraw(
        address tokenAddress,
        uint256 amount,
        uint32 poolId
    ) public override onlyController {
        if (amount <= getBalance(poolId, tokenAddress)) {
            IERC20MetadataUpgradeable(tokenAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amount
            );
            balances[poolId][tokenAddress] -= amount;
        } else {
            _withdraw(tokenAddress, amount, poolId, 0);
        }
    }

    function manualWithdraw(
        address tokenAddress,
        uint256 amount,
        uint32 poolId,
        uint256 ratioX1000
    ) external onlyManager {
        if (amount <= getBalance(poolId, tokenAddress)) {
            IERC20MetadataUpgradeable(tokenAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amount
            );
            balances[poolId][tokenAddress] -= amount;
        } else {
            _withdraw(tokenAddress, amount, poolId, ratioX1000);
        }
    }

    function getTokensPoolValue(uint32 poolId)
        internal
        view
        returns (uint256 amountOfTokenAInPool, uint256 amountOfTokenBInPool)
    {
        Pool memory pool = getPool(poolId);

        uint256 lpAmount = IERC20(pairFor(pool.tokenA, pool.tokenB)).balanceOf(
            address(this)
        ) +
            ISushiSwapMasterChef(masterChef)
                .userInfo(stakings[poolId], address(this))
                .amount;

        uint256 sharePercent = (lpAmount * 10000000000) /
            IERC20(pairFor(pool.tokenA, pool.tokenB)).totalSupply();

        amountOfTokenAInPool =
            (IERC20(pool.tokenA).balanceOf(pairFor(pool.tokenA, pool.tokenB)) *
                sharePercent) /
            10000000000;
        amountOfTokenBInPool =
            (IERC20(pool.tokenB).balanceOf(pairFor(pool.tokenA, pool.tokenB)) *
                sharePercent) /
            10000000000;
    }

    function getLiquidityToWithdraw(
        uint256 amountOfTokenAInPool,
        uint256 amountOfTokenBInPool,
        uint32 poolId,
        address tokenAddress,
        uint256 amount
    ) internal view returns (uint256 liquidityToWithdraw) {
        Pool memory pool = getPool(poolId);

        uint256 estimatedTokenAAmount;
        uint256 estimatedTokenBAmount;

        if (tokenAddress == pool.tokenA) {
            estimatedTokenAAmount = amount / 2;
            estimatedTokenBAmount = getAmountOut(
                tokenAddress,
                pool.tokenB,
                amount / 2
            );
        } else if (tokenAddress == pool.tokenB) {
            estimatedTokenAAmount = getAmountOut(
                tokenAddress,
                pool.tokenA,
                amount / 2
            );
            estimatedTokenBAmount = amount / 2;
        }

        uint256 liquidityPercent;

        if (
            estimatedTokenAAmount > amountOfTokenAInPool ||
            estimatedTokenBAmount > amountOfTokenBInPool
        ) {
            liquidityPercent = 100;
        } else {
            liquidityPercent =
                ((estimatedTokenAAmount + estimatedTokenBAmount) * 100) /
                (amountOfTokenAInPool + amountOfTokenBInPool);
        }

        liquidityToWithdraw =
            (ISushiSwapMasterChef(masterChef)
                .userInfo(stakings[poolId], address(this))
                .amount * (liquidityPercent)) /
            100;
    }

    function _withdraw(
        address tokenAddress,
        uint256 amount,
        uint32 poolId,
        uint256 ratioX1000
    ) internal {
        Pool memory pool = getPool(poolId);

        if (ratioX1000 > 0) {
            checkPriceCeiling(pool.tokenA, pool.tokenB, ratioX1000);
        }

        (
            uint256 amountOfTokenAInPool,
            uint256 amountOfTokenBInPool
        ) = getTokensPoolValue(poolId);

        uint256 liquidityToWithdraw = getLiquidityToWithdraw(
            amountOfTokenAInPool,
            amountOfTokenBInPool,
            poolId,
            tokenAddress,
            amount
        );

        ISushiSwapMasterChef(masterChef).withdraw(
            stakings[poolId],
            liquidityToWithdraw
        );

        IERC20MetadataUpgradeable(pairFor(pool.tokenA, pool.tokenB))
            .safeApprove(swapRouterAddress, liquidityToWithdraw);

        (uint256 amountTokenA, uint256 amountTokenB) = ISushiSwapRouter(
            swapRouterAddress
        ).removeLiquidity(
                pool.tokenA,
                pool.tokenB,
                liquidityToWithdraw,
                0,
                0,
                address(this),
                block.timestamp + 360
            );

        withdrawSwapAndEmit(
            pool,
            poolId,
            tokenAddress,
            amountTokenA,
            amountTokenB
        );
    }

    function withdrawSwapAndEmit(
        Pool memory pool,
        uint32 poolId,
        address tokenAddress,
        uint256 amountTokenA,
        uint256 amountTokenB
    ) internal {
        uint256[] memory amountsOfTokenReceived;

        if (tokenAddress == pool.tokenA) {
            amountsOfTokenReceived = swapExactInput(
                pool.tokenB,
                tokenAddress,
                address(this),
                amountTokenB,
                getAmountOutMinimum(pool.tokenB, tokenAddress, amountTokenB)
            );

            IERC20MetadataUpgradeable(pool.tokenA).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amountTokenA + amountsOfTokenReceived[1]
            );

            emit WithdrawnFromPool(
                poolId,
                amountsOfTokenReceived[1] + amountTokenA
            );
        } else if (tokenAddress == pool.tokenB) {
            amountsOfTokenReceived = swapExactInput(
                pool.tokenA,
                tokenAddress,
                address(this),
                amountTokenA,
                getAmountOutMinimum(pool.tokenA, tokenAddress, amountTokenA)
            );

            IERC20MetadataUpgradeable(pool.tokenB).safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amountTokenB + amountsOfTokenReceived[1]
            );

            emit WithdrawnFromPool(
                poolId,
                amountsOfTokenReceived[1] + amountTokenB
            );
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address of the token out recipient
    /// @param amountIn The exact amount of the input to swap
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256 deadline = block.timestamp;

        if (
            IERC20MetadataUpgradeable(tokenIn).allowance(
                address(this),
                swapRouterAddress
            ) < amountIn
        ) {
            IERC20MetadataUpgradeable(tokenIn).safeApprove(
                swapRouterAddress,
                amountIn
            );
        }

        return
            ISushiSwapRouter(swapRouterAddress).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                recipient,
                deadline
            );
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
    function getAmountOutMinimum(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOutMinimum) {
        amountOutMinimum =
            (getAmountOut(tokenIn, tokenOut, amountIn) *
                (SLIPPAGE_DENOMINATOR - slippageNumerator)) /
            SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        require(amountIn > 0, "amountIn must be greater than zero");
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            tokenIn,
            tokenOut
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "No liquidity in pool reserves"
        );
        uint256 amountInWithFee = amountIn * (997);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return reserveA The reserve balance of tokenA in the pool
    /// @return reserveB The reserve balance of tokenB in the pool
    function getReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = ISushiSwapPair(
            pairFor(tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param token0 The address of sorted token0
    /// @param token1 The address of sorted token1
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Identical token addresses");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Zero address");
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return pair The address of the Sushi pool contract
    function pairFor(address tokenA, address tokenB)
        internal
        view
        returns (address pair)
    {
        pair = ISushiSwapFactory(factoryAddress).getPair(tokenA, tokenB);
    }

    /// @dev Returns total amount of pending yield in SUSHI rewards
    /// @param token  The pool address to check for pending SUSHI rewards
    /// @param poolId  the masterchef pool to retrieve yield for
    /// @return Amount of yield available for harvest
    function getPendingYield(address token, uint256 poolId)
        external
        view
        returns (uint256)
    {
        if (token == address(0)) return 0;

        return
            ISushiSwapMasterChef(masterChef).pendingSushi(
                poolId,
                address(this)
            );
    }

    /// @notice Rebalances by attempting to swap up to max to get into position ratio
    /// @param poolId The ID of the pool to rebalance
    /// @param ratioX1000 reserves ratio to control the price slippage
    /// @param maxSellTokenA max amount of tokenA to sell (to limit rebalancing)
    /// @param maxSellTokenB max amount of tokenB to sell (to limit rebalancing)
    function rebalancePool(
        uint32 poolId,
        uint256 ratioX1000,
        uint256 maxSellTokenA,
        uint256 maxSellTokenB
    ) external onlyManager {
        Pool memory pool = getPool(poolId);

        require(pools[poolId].tokenA != address(0), "Pool doesn't exist");

        checkPriceCeiling(pool.tokenA, pool.tokenB, ratioX1000);

        // determine which token and how much to swap
        (
            address swapToken,
            uint256 excessAmountToSwap
        ) = calculateExcessTokensToSwap(
                pool,
                getBalance(poolId, pool.tokenA),
                getBalance(poolId, pool.tokenB)
            );

        // handle tokenA vs tokenB, cap at max sell param
        address targetToken;
        uint256 swapAmount;
        if (swapToken == pool.tokenA) {
            targetToken = pool.tokenB;
            swapAmount = excessAmountToSwap < maxSellTokenA
                ? excessAmountToSwap
                : maxSellTokenA;
        } else {
            targetToken = pool.tokenA;
            swapAmount = excessAmountToSwap < maxSellTokenB
                ? excessAmountToSwap
                : maxSellTokenB;
        }

        // track balance change of targetToken
        uint256 targetBalanceBefore = IERC20MetadataUpgradeable(targetToken)
            .balanceOf(address(this));

        // swap tokens
        swapExactInput(
            swapToken,
            targetToken,
            address(this),
            swapAmount,
            getAmountOutMinimum(swapToken, targetToken, swapAmount)
        );

        uint256 amountReceived = IERC20MetadataUpgradeable(targetToken)
            .balanceOf(address(this)) - targetBalanceBefore;

        // update pool token balances
        if (amountReceived > 0) {
            balances[poolId][swapToken] -= excessAmountToSwap;
            balances[poolId][targetToken] += amountReceived;

            emit PoolRebalanced(
                poolId,
                swapToken,
                excessAmountToSwap,
                targetToken,
                amountReceived
            );
        }
    }

    function calculateExcessTokensToSwap(
        Pool memory pool,
        uint256 balanceA,
        uint256 balanceB
    ) internal view returns (address swapToken, uint256 excessAmountToSwap) {
        require(balanceA + balanceB > 0, "SushiSwapIntegration: no balance");
        // fetch reserve values from sushi
        (uint256 reserveA, uint256 reserveB) = getReserves(
            pool.tokenA,
            pool.tokenB
        );

        if (reserveA > reserveB) {
            uint256 k = (reserveA * 1000) / reserveB;
            uint256 balanceBA = (balanceB * k) / 1000;

            if (balanceA < balanceBA) {
                // excess tokenB
                excessAmountToSwap = (balanceB - ((balanceA * 1000) / k)) / 2;
                swapToken = pool.tokenB;
            } else if (balanceBA < balanceA) {
                // excess tokenA
                excessAmountToSwap = (balanceA - balanceBA) / 2;
                swapToken = pool.tokenA;
            }
        } else if (reserveA < reserveB) {
            uint256 k = (reserveB * 1000) / reserveA;
            uint256 balanceAB = (balanceA * k) / 1000;

            if (balanceAB < balanceB) {
                // excess tokenB
                excessAmountToSwap = (balanceB - balanceAB) / 2;
                swapToken = pool.tokenB;
            } else if (balanceB < balanceAB) {
                // excess tokenA
                excessAmountToSwap = (balanceA - ((balanceB * 1000) / k)) / 2;
                swapToken = pool.tokenA;
            }
        }
    }

    function checkPriceCeiling(
        address tokenA,
        address tokenB,
        uint256 ratioX1000
    ) internal view {
        address pairAddress = address(pairFor(tokenA, tokenB));
        require(pairAddress != address(0), "SushiSwapIntegration:BadPair");

        uint256 currentRatio;
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB);
        if (reserveA < reserveB) {
            currentRatio = (reserveB * 1000) / reserveA;
        } else if (reserveB < reserveA) {
            currentRatio = (reserveA * 1000) / reserveB;
        } else {
            currentRatio = 1000;
        }

        // limit to 1% off
        if (currentRatio > ratioX1000) {
            require(
                ((currentRatio - ratioX1000) * 100) / ratioX1000 < 1,
                "CeilingLimitReached"
            );
        } else if (ratioX1000 > currentRatio) {
            require(
                ((ratioX1000 - currentRatio) * 100) / ratioX1000 < 1,
                "CeilingLimitReached"
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "./IERC20.sol";

interface ISushiSwapMasterChef {
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    function poolInfo(uint256 input) external returns (PoolInfo memory);

    function deposit(uint256 _pid, uint256 _amount) external;

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (UserInfo memory);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IIntegration.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IYieldManager.sol";
import "./interfaces/IUserPositions.sol";

/// @title Kernel
/// @notice Allows users to deposit/withdraw erc20 tokens
/// @notice Allows a system admin to control which tokens are depositable
contract UserMigration is Initializable, OwnableUpgradeable {
    struct MigrateDeposits {
        address user;
        address[] tokens;
        uint256[] amounts;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function transferFunds(
        address yieldManager,
        address kernel,
        address[] calldata ymTokens,
        uint256[] calldata ymAmounts
    ) external onlyOwner {
        require(ymAmounts.length == ymTokens.length, "incorrect lengths");

        for (uint256 i; i < ymTokens.length; i++) {
            IYieldManager(yieldManager).transferClosedPositionsValue(
                kernel,
                ymTokens[i],
                ymAmounts[i]
            );
        }
    }

    function moveDeposits(
        address newUserPositions,
        MigrateDeposits[] calldata users
    ) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            // Move amount in user positions
            IUserPositions(newUserPositions).deposit(
                users[i].user,
                users[i].tokens,
                users[i].amounts,
                0,
                true
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IYieldManager {
    // #### Structs

    struct DeployRequest {
        address integration;
        address[] tokens; // If ammPoolID > 0, this should contain exactly two addresses
        uint32 ammPoolID; // The pool to deposit into. This is 0 for non-AMM integrations
    }

    struct IntegrationYield {
        address integration;
        address token;
        uint256 amount;
    }

    // #### Functions
    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    function updateGasAccountTargetEthBalance(
        uint256 gasAccountTargetEthBalance_
    ) external;

    /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
    /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
    /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
    /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
    function updateEthDistributionWeights(
        uint32 biosBuyBackEthWeight_,
        uint32 treasuryEthWeight_,
        uint32 protocolFeeEthWeight_,
        uint32 rewardsEthWeight_
    ) external;

    /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
    function updateGasAccount(address payable gasAccount_) external;

    /// @param treasuryAccount_ The address of the system treasury account
    function updateTreasuryAccount(address payable treasuryAccount_) external;

    /// @notice Deploys all tokens to all integrations according to configured weights
    function deploy(DeployRequest[] calldata deployments) external;

    /// @notice Harvests available yield from all tokens and integrations
    function harvestYield(
        address integrationAddress,
        address[] calldata tokenAddresses
    ) external;

    /// @notice Distributes ETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
    function distributeEth() external;

    /// @notice Uses WETH to buy back BIOS which is sent to the Kernel
    function biosBuyBack() external;

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of the token held in the Kernel as reserves
    function getReserveTokenBalance(address tokenAddress)
        external
        view
        returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The desired amount of the token to hold in the Kernel as reserves
    function getDesiredReserveTokenBalance(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return ethWeightSum The sum of ETH distribution weights
    function getEthWeightSum() external view returns (uint32 ethWeightSum);

    /// @return processedWethSum The sum of yields processed into WETH
    function getProcessedWethSum()
        external
        view
        returns (uint256 processedWethSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of WETH received from token yield processing
    function getProcessedWethByToken(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return processedWethByTokenSum The sum of processed WETH
    function getProcessedWethByTokenSum(address[] calldata)
        external
        view
        returns (uint256 processedWethByTokenSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenTotalIntegrationBalance The total amount of the token that can be withdrawn from integrations
    function getTokenTotalIntegrationBalance(address tokenAddress)
        external
        view
        returns (uint256 tokenTotalIntegrationBalance);

    /// @return The address of the gas account
    function getGasAccount() external view returns (address);

    /// @return The address of the treasury account
    function getTreasuryAccount() external view returns (address);

    /// @return The last amount of ETH distributed to rewards
    function getLastEthRewardsAmount() external view returns (uint256);

    /// @return The target ETH balance of the gas account
    function getGasAccountTargetEthBalance() external view returns (uint256);

    /// @return The BIOS buyback ETH weight
    /// @return The Treasury ETH weight
    /// @return The Protocol fee ETH weight
    /// @return The rewards ETH weight
    function getEthDistributionWeights()
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32
        );

    function transferClosedPositionsValue(
        address destination,
        address token,
        uint256 amount
    ) external;

    // function getAllPendingYield(address token)
    //     external
    //     view
    //     returns (IntegrationYield[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IBiosRewards.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IIntegration.sol";
import "../interfaces/IAMMIntegration.sol";
import "../interfaces/IEtherRewards.sol";
import "../interfaces/IYieldManager.sol";
import "../interfaces/IUniswapTrader.sol";
import "../interfaces/ISushiSwapTrader.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IWeth9.sol";
import "../interfaces/IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

/// @title Yield Manager
/// @notice Manages yield deployments, harvesting, processing, and distribution
contract YieldManager is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IYieldManager
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint256 private gasAccountTargetEthBalance;
    uint32 private biosBuyBackEthWeight;
    uint32 private treasuryEthWeight;
    uint32 private protocolFeeEthWeight;
    uint32 private rewardsEthWeight;
    uint256 private lastEthRewardsAmount;

    address payable private gasAccount;
    address payable private treasuryAccount;

    mapping(address => uint256) private processedWethByToken;
    mapping(address => uint256) private lastHarvestTimestampByIntegration;

    event HarvestYield(
        address integration,
        address[] tokenAddresses,
        uint256[] amountsInWeth
    );

    receive() external payable {}

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ Address of the Module Map
    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
    /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
    /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
    /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
    /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
    /// @param treasuryAccount_ The address of the system treasury account
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        uint256 gasAccountTargetEthBalance_,
        uint32 biosBuyBackEthWeight_,
        uint32 treasuryEthWeight_,
        uint32 protocolFeeEthWeight_,
        uint32 rewardsEthWeight_,
        address payable gasAccount_,
        address payable treasuryAccount_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        gasAccountTargetEthBalance = gasAccountTargetEthBalance_;
        biosBuyBackEthWeight = biosBuyBackEthWeight_;
        treasuryEthWeight = treasuryEthWeight_;
        protocolFeeEthWeight = protocolFeeEthWeight_;
        rewardsEthWeight = rewardsEthWeight_;
        gasAccount = gasAccount_;
        treasuryAccount = treasuryAccount_;
    }

    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    function updateGasAccountTargetEthBalance(
        uint256 gasAccountTargetEthBalance_
    ) external override onlyController {
        gasAccountTargetEthBalance = gasAccountTargetEthBalance_;
    }

    /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
    /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
    /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
    /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
    function updateEthDistributionWeights(
        uint32 biosBuyBackEthWeight_,
        uint32 treasuryEthWeight_,
        uint32 protocolFeeEthWeight_,
        uint32 rewardsEthWeight_
    ) external override onlyController {
        biosBuyBackEthWeight = biosBuyBackEthWeight_;
        treasuryEthWeight = treasuryEthWeight_;
        protocolFeeEthWeight = protocolFeeEthWeight_;
        rewardsEthWeight = rewardsEthWeight_;
    }

    /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
    function updateGasAccount(address payable gasAccount_)
        external
        override
        onlyController
    {
        gasAccount = gasAccount_;
    }

    /// @param treasuryAccount_ The address of the system treasury account
    function updateTreasuryAccount(address payable treasuryAccount_)
        external
        override
        onlyController
    {
        treasuryAccount = treasuryAccount_;
    }

    /// @notice Deploys all tokens to all integrations according to configured weights
    function deploy(DeployRequest[] calldata deployments)
        external
        override
        onlyController
    {
        IStrategyMap strategyMap = IStrategyMap(
            moduleMap.getModuleAddress(Modules.StrategyMap)
        );

        for (uint256 i = 0; i < deployments.length; i++) {
            if (deployments[i].ammPoolID > 0) {
                require(deployments[i].tokens.length <= 2, "too many tokens");
            }

            for (uint256 j = 0; j < deployments[i].tokens.length; j++) {
                int256 deployAmount = strategyMap.getDeployAmount(
                    deployments[i].integration,
                    deployments[i].ammPoolID,
                    deployments[i].tokens[j]
                );

                uint256 reserveBalance = IERC20MetadataUpgradeable(
                    deployments[i].tokens[j]
                ).balanceOf(moduleMap.getModuleAddress(Modules.Kernel));
                if (deployAmount > 0 && reserveBalance < abs(deployAmount)) {
                    strategyMap.closePositionsForWithdrawal(
                        deployments[i].tokens[j],
                        type(uint256).max
                    );
                    deployAmount = strategyMap.getDeployAmount(
                        deployments[i].integration,
                        deployments[i].ammPoolID,
                        deployments[i].tokens[j]
                    );
                }

                if (deployments[i].ammPoolID > 0) {
                    IAMMIntegration integration = IAMMIntegration(
                        deployments[i].integration
                    );

                    if (deployAmount > 0) {
                        uint256 balanceBefore = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);

                        IERC20MetadataUpgradeable(deployments[i].tokens[j])
                            .safeTransferFrom(
                                moduleMap.getModuleAddress(Modules.Kernel),
                                deployments[i].integration,
                                abs(deployAmount)
                            );
                        uint256 balanceAfter = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);
                        integration.deposit(
                            deployments[i].tokens[j],
                            balanceAfter - balanceBefore,
                            deployments[i].ammPoolID
                        );
                        integration.deploy(deployments[i].ammPoolID);
                    } else if (deployAmount < 0) {
                        integration.withdraw(
                            deployments[i].tokens[j],
                            abs(deployAmount),
                            deployments[i].ammPoolID
                        );
                    }
                } else {
                    IIntegration integration = IIntegration(
                        deployments[i].integration
                    );
                    if (deployAmount > 0) {
                        uint256 balanceBefore = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);
                        IERC20MetadataUpgradeable(deployments[i].tokens[j])
                            .safeTransferFrom(
                                moduleMap.getModuleAddress(Modules.Kernel),
                                deployments[i].integration,
                                abs(deployAmount)
                            );
                        uint256 balanceAfter = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);

                        integration.deposit(
                            deployments[i].tokens[j],
                            balanceAfter - balanceBefore
                        );
                        integration.deploy();
                    } else if (deployAmount < 0) {
                        integration.withdraw(
                            deployments[i].tokens[j],
                            abs(deployAmount)
                        );
                    }
                }
                strategyMap.decreaseDeployAmountChange(
                    deployments[i].integration,
                    deployments[i].ammPoolID,
                    deployments[i].tokens[j],
                    abs(deployAmount)
                );
            }
            strategyMap.clearClosablePositions(deployments[i].tokens);
        }
    }

    function abs(int256 val) internal pure returns (uint256) {
        return uint256(val >= 0 ? val : -val);
    }

    function _calculateReserveAmount(
        uint256 amount,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        return (amount == 0 ? 1 : amount * numerator) / denominator;
    }

    /// @notice Harvests available yield from provided tokens and integration
    function harvestYield(
        address integrationAddress,
        address[] calldata tokenAddresses
    ) public override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        IERC20MetadataUpgradeable weth = IERC20MetadataUpgradeable(
            integrationMap.getWethTokenAddress()
        );

        uint256[] memory harvestedWethAmounts = new uint256[](
            tokenAddresses.length
        );
        uint256 wethBalanceBeforeHarvest = weth.balanceOf(address(this));

        IIntegration(integrationAddress).harvestYield();
        lastHarvestTimestampByIntegration[integrationAddress] = block.timestamp;

        processedWethByToken[address(weth)] +=
            weth.balanceOf(address(this)) -
            wethBalanceBeforeHarvest;

        for (
            uint256 tokenIterator;
            tokenIterator < tokenAddresses.length;
            tokenIterator++
        ) {
            IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
                tokenAddresses[tokenIterator]
            );

            if (token.balanceOf(address(this)) > 0) {
                token.safeTransfer(
                    moduleMap.getModuleAddress(Modules.Kernel),
                    _calculateReserveAmount(
                        token.balanceOf(address(this)),
                        integrationMap.getTokenReserveRatioNumerator(
                            address(token)
                        ),
                        integrationMap.getReserveRatioDenominator()
                    )
                );
                if (address(token) != address(weth)) {
                    uint256 wethBalanceBefore = weth.balanceOf(address(this));
                    // If token is not WETH, need to swap it for WETH
                    // Swap token harvested yield for WETH. If trade succeeds, update accounting. Otherwise, do not update accounting
                    token.safeTransfer(
                        moduleMap.getModuleAddress(Modules.UniswapTrader),
                        token.balanceOf(address(this))
                    );

                    IUniswapTrader(
                        moduleMap.getModuleAddress(Modules.UniswapTrader)
                    ).swapExactInput(
                            address(token),
                            address(weth),
                            address(this),
                            token.balanceOf(
                                moduleMap.getModuleAddress(
                                    Modules.UniswapTrader
                                )
                            )
                        );
                    // Update accounting
                    processedWethByToken[address(token)] +=
                        weth.balanceOf(address(this)) -
                        wethBalanceBefore;
                }
            }
            harvestedWethAmounts[tokenIterator] = processedWethByToken[
                address(token)
            ];
        }
        emit HarvestYield(
            integrationAddress,
            tokenAddresses,
            harvestedWethAmounts
        );
    }

    /// @notice Distributes ETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
    function distributeEth() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address wethAddress = IIntegrationMap(integrationMap)
            .getWethTokenAddress();

        // First fill up gas wallet with ETH
        ethToGasAccount();

        uint256 wethToDistribute = IERC20MetadataUpgradeable(wethAddress)
            .balanceOf(address(this));

        if (wethToDistribute > 0) {
            uint256 biosBuyBackWethAmount = (wethToDistribute *
                biosBuyBackEthWeight) / getEthWeightSum();
            uint256 treasuryWethAmount = (wethToDistribute *
                treasuryEthWeight) / getEthWeightSum();
            uint256 protocolFeeWethAmount = (wethToDistribute *
                protocolFeeEthWeight) / getEthWeightSum();
            uint256 rewardsWethAmount = wethToDistribute -
                biosBuyBackWethAmount -
                treasuryWethAmount -
                protocolFeeWethAmount;

            // Send WETH to SushiSwap trader for BIOS buy back
            IERC20MetadataUpgradeable(wethAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.SushiSwapTrader),
                biosBuyBackWethAmount
            );

            // Swap WETH for ETH and transfer to the treasury account
            IWeth9(wethAddress).withdraw(treasuryWethAmount);
            payable(treasuryAccount).transfer(treasuryWethAmount);

            // Send ETH to protocol fee accrual rewards (BIOS stakers)
            ethToProtocolFeeAccrual(protocolFeeWethAmount);

            // Send ETH to token rewards
            ethToRewards(rewardsWethAmount);
        }
    }

    /// @notice Distributes WETH to gas wallet
    function ethToGasAccount() private {
        address wethAddress = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getWethTokenAddress();
        uint256 wethBalance = IERC20MetadataUpgradeable(wethAddress).balanceOf(
            address(this)
        );

        if (wethBalance > 0) {
            uint256 gasAccountActualEthBalance = gasAccount.balance;
            if (gasAccountActualEthBalance < gasAccountTargetEthBalance) {
                // Need to send ETH to gas account
                uint256 ethAmountToGasAccount;
                if (
                    wethBalance <
                    gasAccountTargetEthBalance - gasAccountActualEthBalance
                ) {
                    // Send all of WETH to gas wallet
                    ethAmountToGasAccount = wethBalance;
                    IWeth9(wethAddress).withdraw(ethAmountToGasAccount);
                    gasAccount.transfer(ethAmountToGasAccount);
                } else {
                    // Send portion of WETH to gas wallet
                    ethAmountToGasAccount =
                        gasAccountTargetEthBalance -
                        gasAccountActualEthBalance;
                    IWeth9(wethAddress).withdraw(ethAmountToGasAccount);
                    gasAccount.transfer(ethAmountToGasAccount);
                }
            }
        }
    }

    /// @notice Uses any WETH held in the SushiSwap trader to buy back BIOS which is sent to the Kernel
    function biosBuyBack() external override onlyController {
        if (
            IERC20MetadataUpgradeable(
                IIntegrationMap(
                    moduleMap.getModuleAddress(Modules.IntegrationMap)
                ).getWethTokenAddress()
            ).balanceOf(moduleMap.getModuleAddress(Modules.SushiSwapTrader)) > 0
        ) {
            // Use all ETH sent to the SushiSwap trader to buy BIOS
            ISushiSwapTrader(
                moduleMap.getModuleAddress(Modules.SushiSwapTrader)
            ).biosBuyBack();

            // Use all BIOS transferred to the Kernel to increase bios rewards
            IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
                .increaseBiosRewards();
        }
    }

    /// @notice Distributes ETH to Rewards per token
    /// @param ethRewardsAmount The amount of ETH rewards to distribute
    function ethToRewards(uint256 ethRewardsAmount) private {
        uint256 processedWethByTokenSum = getProcessedWethSum();
        require(
            processedWethByTokenSum > 0,
            "YieldManager::ethToRewards: No processed WETH to distribute"
        );

        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address wethAddress = integrationMap.getWethTokenAddress();
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address tokenAddress = integrationMap.getTokenAddress(tokenId);

            if (processedWethByToken[tokenAddress] > 0) {
                IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                    .increaseEthRewards(
                        tokenAddress,
                        (ethRewardsAmount *
                            processedWethByToken[tokenAddress]) /
                            processedWethByTokenSum
                    );

                processedWethByToken[tokenAddress] = 0;
            }
        }

        lastEthRewardsAmount = ethRewardsAmount;

        IWeth9(wethAddress).withdraw(ethRewardsAmount);

        payable(moduleMap.getModuleAddress(Modules.Kernel)).transfer(
            ethRewardsAmount
        );
    }

    /// @notice Distributes ETH to protocol fee accrual (BIOS staker rewards)
    /// @param protocolFeeEthRewardsAmount Amount of ETH to distribute to protocol fee accrual
    function ethToProtocolFeeAccrual(uint256 protocolFeeEthRewardsAmount)
        private
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address biosAddress = integrationMap.getBiosTokenAddress();
        address wethAddress = integrationMap.getWethTokenAddress();

        if (
            IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
                .getTokenTotalBalance(biosAddress) > 0
        ) {
            // BIOS has been deposited, increase Ether rewards for BIOS depositors
            IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                .increaseEthRewards(biosAddress, protocolFeeEthRewardsAmount);

            IWeth9(wethAddress).withdraw(protocolFeeEthRewardsAmount);

            payable(moduleMap.getModuleAddress(Modules.Kernel)).transfer(
                protocolFeeEthRewardsAmount
            );
        } else {
            // No BIOS has been deposited, send WETH back to Kernel as reserves
            IERC20MetadataUpgradeable(wethAddress).transfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                protocolFeeEthRewardsAmount
            );
        }
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of the token held in the Kernel as reserves
    function getReserveTokenBalance(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        require(
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getIsTokenAdded(tokenAddress),
            "YieldManager::getReserveTokenBalance: Token not added"
        );
        return
            IERC20MetadataUpgradeable(tokenAddress).balanceOf(
                moduleMap.getModuleAddress(Modules.Kernel)
            );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The desired amount of the token to hold in the Kernel as reserves
    function getDesiredReserveTokenBalance(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        require(
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getIsTokenAdded(tokenAddress),
            "YieldManager::getDesiredReserveTokenBalance: Token not added"
        );
        uint256 tokenReserveRatioNumerator = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getTokenReserveRatioNumerator(tokenAddress);
        uint256 tokenTotalBalance = IStrategyMap(
            moduleMap.getModuleAddress(Modules.StrategyMap)
        ).getTokenTotalBalance(tokenAddress);
        return
            (tokenTotalBalance * tokenReserveRatioNumerator) /
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getReserveRatioDenominator();
    }

    /// @return ethWeightSum The sum of ETH distribution weights
    function getEthWeightSum()
        public
        view
        override
        returns (uint32 ethWeightSum)
    {
        ethWeightSum =
            biosBuyBackEthWeight +
            treasuryEthWeight +
            protocolFeeEthWeight +
            rewardsEthWeight;
    }

    /// @return processedWethSum The sum of yields processed into WETH
    function getProcessedWethSum()
        public
        view
        override
        returns (uint256 processedWethSum)
    {
        uint256 tokenCount = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getTokenAddressesLength();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address tokenAddress = IIntegrationMap(
                moduleMap.getModuleAddress(Modules.IntegrationMap)
            ).getTokenAddress(tokenId);
            processedWethSum += processedWethByToken[tokenAddress];
        }
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of WETH received from token yield processing
    function getProcessedWethByToken(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        return processedWethByToken[tokenAddress];
    }

    /// @return processedWethByTokenSum The sum of processed WETH
    function getProcessedWethByTokenSum(address[] calldata tokenAddresses)
        public
        view
        override
        returns (uint256 processedWethByTokenSum)
    {
        for (uint256 tokenId; tokenId < tokenAddresses.length; tokenId++) {
            processedWethByTokenSum += processedWethByToken[
                tokenAddresses[tokenId]
            ];
        }
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenTotalIntegrationBalance The total amount of the token that can be withdrawn from integrations
    function getTokenTotalIntegrationBalance(address tokenAddress)
        public
        view
        override
        returns (uint256 tokenTotalIntegrationBalance)
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 integrationCount = integrationMap
            .getIntegrationAddressesLength();

        for (
            uint256 integrationId;
            integrationId < integrationCount;
            integrationId++
        ) {
            tokenTotalIntegrationBalance += IIntegration(
                integrationMap.getIntegrationAddress(integrationId)
            ).getBalance(tokenAddress);
        }
    }

    /// @return The address of the gas account
    function getGasAccount() public view override returns (address) {
        return gasAccount;
    }

    /// @return The address of the treasury account
    function getTreasuryAccount() public view override returns (address) {
        return treasuryAccount;
    }

    /// @return The last amount of ETH distributed to rewards
    function getLastEthRewardsAmount() public view override returns (uint256) {
        return lastEthRewardsAmount;
    }

    /// @return The target ETH balance of the gas account
    function getGasAccountTargetEthBalance()
        public
        view
        override
        returns (uint256)
    {
        return gasAccountTargetEthBalance;
    }

    /// @return The BIOS buyback ETH weight
    /// @return The Treasury ETH weight
    /// @return The Protocol fee ETH weight
    /// @return The rewards ETH weight
    function getEthDistributionWeights()
        public
        view
        override
        returns (
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        return (
            biosBuyBackEthWeight,
            treasuryEthWeight,
            protocolFeeEthWeight,
            rewardsEthWeight
        );
    }

    /// @return The timestamp the harvestYield function was last called
    function getLastHarvestYieldTimestamp(address integrationAddress)
        external
        view
        returns (uint256)
    {
        return lastHarvestTimestampByIntegration[integrationAddress];
    }

    function transferClosedPositionsValue(
        address destination,
        address token,
        uint256 amount
    ) external override onlyController {
        IERC20MetadataUpgradeable(token).safeTransfer(destination, amount);
    }

    function getAllPendingYield(address token)
        external
        view
        returns (IntegrationYield[] memory pendingYieldData)
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 integrationCount = integrationMap
            .getIntegrationAddressesLength();

        pendingYieldData = new IntegrationYield[](integrationCount);

        for (
            uint256 integrationId;
            integrationId < integrationCount;
            integrationId++
        ) {
            address integrationAddress = integrationMap.getIntegrationAddress(
                integrationId
            );
            uint256 pendingYield = IIntegration(integrationAddress)
                .getPendingYield(token);

            pendingYieldData[integrationId] = IntegrationYield(
                integrationAddress,
                token,
                pendingYield
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IEtherRewards {
    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    function updateUserRewards(address token, address user) external;

    /// @param token The address of the token ERC20 contract
    /// @param ethRewardsAmount The amount of Ether rewards to add
    function increaseEthRewards(address token, uint256 ethRewardsAmount)
        external;

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimEthRewards(address user)
        external
        returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserTokenEthRewards(address token, address user)
        external
        view
        returns (uint256 ethRewards);

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserEthRewards(address user)
        external
        view
        returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @return The amount of Ether rewards for the specified token
    function getTokenEthRewards(address token) external view returns (uint256);

    /// @return The total value of ETH claimed by users
    function getTotalClaimedEthRewards() external view returns (uint256);

    /// @return The total value of ETH claimed by a user
    function getTotalUserClaimedEthRewards(address user)
        external
        view
        returns (uint256);

    /// @return The total amount of Ether rewards
    function getEthRewards() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IUniswapTrader {
    struct Path {
        address tokenOut;
        uint256 firstPoolFee;
        address tokenInTokenOut;
        uint256 secondPoolFee;
        address tokenIn;
    }

    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @param fee The Uniswap pool fee
    /// @param slippageNumerator The value divided by the slippage denominator
    /// to calculate the allowable slippage
    function addPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint24 slippageNumerator
    ) external;

    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param poolIndex The index of the pool for the specified token pair
    /// @param slippageNumerator The new slippage numerator to update the pool
    function updatePoolSlippageNumerator(
        address tokenA,
        address tokenB,
        uint256 poolIndex,
        uint24 slippageNumerator
    ) external;

    /// @notice Changes which Uniswap pool to use as the default pool
    /// @notice when swapping between token0 and token1
    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
    function updatePairPrimaryPool(
        address tokenA,
        address tokenB,
        uint256 primaryPoolIndex
    ) external;

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountIn The exact amount of the input to swap
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountOut The exact amount of the output token to receive
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of token being swapped for
    /// @return amountInMaximum The maximum amount of tokenIn to spend, factoring in allowable slippage
    function getAmountInMaximum(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountInMaximum);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getEstimatedTokenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getPathFor(address tokenOut, address tokenIn)
        external
        view
        returns (Path memory);

    function setPathFor(
        address tokenOut,
        address tokenIn,
        uint256 firstPoolFee,
        address tokenInTokenOut,
        uint256 secondPoolFee
    ) external;

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the sorted token0
    /// @return token1 The address of the sorted token1
    function getTokensSorted(address tokenA, address tokenB)
        external
        pure
        returns (address token0, address token1);

    /// @return The number of token pairs configured
    function getTokenPairsLength() external view returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return The quantity of pools configured for the specified token pair
    function getTokenPairPoolsLength(address tokenA, address tokenB)
        external
        view
        returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return feeNumerator The numerator that gets divided by the fee denominator
    function getPoolFeeNumerator(
        address tokenA,
        address tokenB,
        uint256 poolId
    ) external view returns (uint24 feeNumerator);

    function getPoolAddress(address tokenA, address tokenB)
        external
        view
        returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface ISushiSwapTrader {
    /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
    function updateSlippageNumerator(uint24 slippageNumerator_) external;

    /// @notice Swaps all WETH held in this contract for BIOS and sends to the kernel
    /// @return Bool indicating whether the trade succeeded
    function biosBuyBack() external returns (bool);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address of the token out recipient
    /// @param amountIn The exact amount of the input to swap
    /// @param amountOutMin The minimum amount of tokenOut to receive from the swap
    /// @return bool Indicates whether the swap succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../core/Controlled.sol";
import "../interfaces/IIntegration.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IAaveLendingPool.sol";
import "../core/ModuleMapConsumer.sol";

/// @notice Integrates 0x Nodes to the Aave lending pool
/// @notice The Kernel contract should be added as the controller
contract AaveIntegration is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IIntegration
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    address private lendingPoolAddress;
    mapping(address => uint256) private balances;

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ The address of the module map contract
    /// @param lendingPoolAddress_ The address of the Aave lending pool contract
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address lendingPoolAddress_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        lendingPoolAddress = lendingPoolAddress_;
    }

    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(address tokenAddress, uint256 amount)
        external
        override
        onlyController
    {
        balances[tokenAddress] += amount;
    }

    /// @notice Withdraws token from the integration
    /// @param tokenAddress The address of the underlying token to withdraw
    /// @param amount The amoutn of the token to withdraw
    function withdraw(address tokenAddress, uint256 amount)
        public
        override
        onlyController
    {
        require(
            amount <= balances[tokenAddress],
            "AaveIntegration::withdraw: Withdraw amount exceeds balance"
        );

        if (
            amount >
            IERC20MetadataUpgradeable(tokenAddress).balanceOf(address(this))
        ) {
            try
                IAaveLendingPool(lendingPoolAddress).withdraw(
                    tokenAddress,
                    amount,
                    address(this)
                )
            {} catch {}
        }

        if (
            amount >
            IERC20MetadataUpgradeable(tokenAddress).balanceOf(address(this))
        ) {
            amount = IERC20MetadataUpgradeable(tokenAddress).balanceOf(
                address(this)
            );
        }

        balances[tokenAddress] -= amount;
        IERC20MetadataUpgradeable(tokenAddress).safeTransfer(
            moduleMap.getModuleAddress(Modules.Kernel),
            amount
        );
    }

    /// @notice Deploys all available tokens to Aave
    function deploy() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
            IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
                integrationMap.getTokenAddress(tokenId)
            );
            uint256 tokenAmount = token.balanceOf(address(this));

            if (token.allowance(address(this), lendingPoolAddress) == 0) {
                token.safeApprove(lendingPoolAddress, type(uint256).max);
            }

            if (tokenAmount > 0) {
                try
                    IAaveLendingPool(lendingPoolAddress).deposit(
                        address(token),
                        tokenAmount,
                        address(this),
                        0
                    )
                {} catch {}
            }
        }
    }

    /// @notice Harvests all token yield from the Aave lending pool
    function harvestYield() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
            address tokenAddress = integrationMap.getTokenAddress(tokenId);
            address aTokenAddress = getATokenAddress(tokenAddress);
            if (aTokenAddress != address(0)) {
                uint256 aTokenBalance = IERC20MetadataUpgradeable(aTokenAddress)
                    .balanceOf(address(this));
                if (aTokenBalance > balances[tokenAddress]) {
                    try
                        IAaveLendingPool(lendingPoolAddress).withdraw(
                            tokenAddress,
                            aTokenBalance - balances[tokenAddress],
                            address(
                                moduleMap.getModuleAddress(Modules.YieldManager)
                            )
                        )
                    {} catch {}
                }
            }
        }
    }

    /// @dev This returns the total amount of the underlying token that
    /// @dev has been deposited to the integration contract
    /// @param tokenAddress The address of the deployed token
    /// @return The amount of the underlying token that can be withdrawn
    function getBalance(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        return balances[tokenAddress];
    }

    /// @param underlyingTokenAddress The address of the underlying token
    /// @return The address of the corresponding aToken
    function getATokenAddress(address underlyingTokenAddress)
        public
        view
        returns (address)
    {
        IAaveLendingPool.ReserveData memory reserveData = IAaveLendingPool(
            lendingPoolAddress
        ).getReserveData(underlyingTokenAddress);

        return reserveData.aTokenAddress;
    }

    /// @dev This is used to recover lost funds from the contract to the Kernel
    /// @dev Be super careful not to transfer out the wrong tokens!
    /// @dev We should make it a point to remove this function relatively soon
    /// @param tokenAddress The address of the token to recover
    function recoverTokens(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(tokenAddress == address(tokenAddress), "Invalid tokenAddress");
        require(amount > 0, "Amount must be greater than 0");
        IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
            tokenAddress
        );
        require(amount <= token.balanceOf(address(this)));

        if (amount > 0) {
            // Send tokens back to Kernel
            token.safeTransfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                amount
            );
        }
    }

    /// @dev Returns total amount of pending yield for the specified token in Aave
    /// @param token The of the token to check for available yield
    /// @return Amount of yield available for harvest
    function getPendingYield(address token)
        external
        view
        override
        returns (uint256)
    {
        uint256 aTokenBalance = IERC20MetadataUpgradeable(
            getATokenAddress(token)
        ).balanceOf(address(this));
        if (aTokenBalance > balances[token])
            return aTokenBalance - balances[token];
        else return 0;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IAaveLendingPool {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }

    /// @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    /// @param asset The address of the underlying asset to deposit
    /// @param amount The amount to be deposited
    /// @param onBehalfOf The address that will receive the aTokens
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /// @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    /// @param asset The address of the underlying asset to withdraw
    /// @param amount The underlying amount to be withdrawn
    /// @param to Address that will receive the underlying, same as msg.sender if the user
    /// @return The final amount withdrawn
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /// @dev Returns the state and configuration of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The state of the reserve
    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "./IIntegration.sol";

interface IDynamicRangeOrdersIntegration is IIntegration {
    /// @param dynamicRangeOrdersIntegrationDeployerAddress The address of the Uniswap Integration Deployer contract
    function setDynamicRangeOrdersIntegrationDeployer(
        address dynamicRangeOrdersIntegrationDeployerAddress
    ) external;

    /// @param baseStablecoinAddress_ The base stablecoin token that the Uniswap Integration uses for swaps
    function setBaseStablecoin(address baseStablecoinAddress_) external;

    /// @param liquidityPositionKey The key of the liquidity position
    /// @return token0 The address of token0 of the liquidity position
    /// @return token1 The address of token1 of the liquidity position
    /// @return feeNumerator The fee of the liquidity position
    /// @return tickLower The lower tick bound of the liquidity position
    /// @return tickUpper The upper tick bound of the liquidity position
    /// @return minted Boolean indicating whether the position has been minted yet
    /// @return id The token ID of the liquidity position
    /// @return weight The relative weight of the liquidity position
    function getLiquidityPosition(bytes32 liquidityPositionKey)
        external
        view
        returns (
            address token0,
            address token1,
            uint24 feeNumerator,
            int24 tickLower,
            int24 tickUpper,
            bool minted,
            uint256 id,
            uint256 weight
        );

    /// @return The address of the base stablecoin
    function getBaseStablecoinAddress() external view returns (address);

    /// @param tokenAddress The address of the token
    /// @param amount The amount of the token
    /// @return tokenValueInBaseStablecoin The value of the amount of the token converted to the base stablecoin
    function getTokenValueInBaseStablecoin(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256 tokenValueInBaseStablecoin);

    /// @return The number of configured liquidity positions
    function getLiquidityPositionsCount() external view returns (uint256);

    /// @param liquidityPositionKey The key of the liquidity position
    /// @return positionBaseStablecoinValue The value of the liquidity position converted to the base stablecoin
    function getPositionBaseStablecoinValue(bytes32 liquidityPositionKey)
        external
        view
        returns (uint256 positionBaseStablecoinValue);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IBiosRewards.sol";
import "../interfaces/IEtherRewards.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IWeth9.sol";
import "../interfaces/IYieldManager.sol";
import "../interfaces/IIntegration.sol";
import "../interfaces/IAMMIntegration.sol";
import "../interfaces/IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

/// @title User Positions
/// @notice Allows users to deposit/withdraw erc20 tokens
contract UserPositions is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IUserPositions
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    /// @dev This is deprecated - now live in BiosRewards.sol
    uint32 private _biosRewardsDuration;

    // Token address => total supply held by the contract
    mapping(address => uint256) private _totalSupply;

    // Token address => User address => Balance of tokens a user has deposited
    mapping(address => mapping(address => uint256)) private _balances;

    // User => Token => deployed balance
    mapping(address => mapping(address => uint256)) private _deployedBalances;

    // User => strategy => token => balance
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        private _userStrategyBalances;

    // Token address => User address => Balance of tokens a user has from interconnecting from other chains
    mapping(address => mapping(address => uint256))
        private _interconnectBalances;

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ Address of the Module Map
    function initialize(address[] memory controllers_, address moduleMap_)
        public
        initializer
    {
        __Controlled_init(controllers_, moduleMap_);
    }

    /// @notice User is allowed to deposit whitelisted tokens
    /// @param depositor Address of the account depositing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param ethAmount The amount of ETH sent with the deposit
    function deposit(
        address depositor,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 ethAmount,
        bool migration
    ) external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );

        uint256[] memory actualAmounts = new uint256[](tokens.length);

        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            // Token must be accepting deposits
            require(
                integrationMap.getTokenAcceptingDeposits(tokens[tokenId]),
                "UserPositions::deposit: This token is not accepting deposits"
            );

            require(
                amounts[tokenId] > 0,
                "UserPositions::deposit: Deposit amount must be greater than zero"
            );
            uint256 actualAmount;
            if (migration) {
                actualAmount = amounts[tokenId];
            } else {
                IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(
                    tokens[tokenId]
                );
                // Get the balance before the transfer
                uint256 beforeBalance = erc20.balanceOf(
                    moduleMap.getModuleAddress(Modules.Kernel)
                );

                // Transfer the tokens from the depositor to the Kernel
                erc20.safeTransferFrom(
                    depositor,
                    moduleMap.getModuleAddress(Modules.Kernel),
                    amounts[tokenId]
                );

                // Get the balance after the transfer
                uint256 afterBalance = erc20.balanceOf(
                    moduleMap.getModuleAddress(Modules.Kernel)
                );
                actualAmount = afterBalance - beforeBalance;
                // Increase rewards

                IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
                    .increaseRewards(tokens[tokenId], depositor, actualAmount);
                IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                    .updateUserRewards(tokens[tokenId], depositor);
            }
            actualAmounts[tokenId] = actualAmount;

            // Update balances
            _totalSupply[tokens[tokenId]] += actualAmount;
            _balances[tokens[tokenId]][depositor] += actualAmount;
        }

        if (ethAmount > 0) {
            address wethAddress = integrationMap.getWethTokenAddress();

            // Increase rewards
            IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
                .increaseRewards(wethAddress, depositor, ethAmount);
            IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                .updateUserRewards(wethAddress, depositor);

            // Update WETH balances
            _totalSupply[wethAddress] += ethAmount;
            _balances[wethAddress][depositor] += ethAmount;
        }

        emit Deposit(depositor, tokens, actualAmounts, ethAmount);
    }

    /// @notice User is allowed to withdraw tokens
    /// @param recipient The address of the user withdrawing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    function withdraw(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bool withdrawWethAsEth
    ) external override onlyController returns (uint256 ethWithdrawn) {
        ethWithdrawn = _withdraw(recipient, tokens, amounts, withdrawWethAsEth);
    }

    /// @notice Allows a user to withdraw entire balances of the specified tokens and claim rewards
    /// @param recipient The address of the user withdrawing tokens
    /// @param tokens Array of token address that user is exiting positions from
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    /// @return tokenAmounts The amounts of each token being withdrawn
    /// @return ethWithdrawn The amount of ETH being withdrawn
    /// @return ethClaimed The amount of ETH being claimed from rewards
    /// @return biosClaimed The amount of BIOS being claimed from rewards
    function withdrawAllAndClaim(
        address recipient,
        address[] memory tokens,
        bool withdrawWethAsEth
    )
        external
        override
        onlyController
        returns (
            uint256[] memory tokenAmounts,
            uint256 ethWithdrawn,
            uint256 ethClaimed,
            uint256 biosClaimed
        )
    {
        tokenAmounts = new uint256[](tokens.length);
        IBiosRewards biosRewards = IBiosRewards(
            moduleMap.getModuleAddress(Modules.BiosRewards)
        );
        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            tokenAmounts[tokenId] = userTokenBalance(
                tokens[tokenId],
                recipient
            );
        }

        ethWithdrawn = _withdraw(
            recipient,
            tokens,
            tokenAmounts,
            withdrawWethAsEth
        );

        if (
            IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                .getUserEthRewards(recipient) > 0
        ) {
            ethClaimed = _claimEthRewards(recipient);
        }

        biosClaimed = biosRewards.claimBiosRewards(recipient);
    }

    /// @notice User is allowed to withdraw tokens
    /// @param recipient The address of the user withdrawing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    function _withdraw(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bool withdrawWethAsEth
    ) private returns (uint256 ethWithdrawn) {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address wethAddress = integrationMap.getWethTokenAddress();
        ethWithdrawn = 0;
        require(
            tokens.length == amounts.length,
            "UserPositions::_withdraw: Tokens array length does not match amounts array length"
        );

        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            if (amounts[tokenId] == 0) break;
            require(
                integrationMap.getTokenAcceptingWithdrawals(tokens[tokenId]),
                "UserPositions::_withdraw: This token is not accepting withdrawals"
            );
            require(
                amounts[tokenId] <=
                    userTokenBalance(tokens[tokenId], recipient),
                "UserPositions::_withdraw: Withdraw amount exceeds user balance"
            );

            // Process user withdrawal amount management, and close out positions as needed to fund the withdrawal
            uint256 reserveBalance = IERC20MetadataUpgradeable(tokens[tokenId])
                .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));

            if (reserveBalance < amounts[tokenId]) {
                IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
                    .closePositionsForWithdrawal(
                        tokens[tokenId],
                        amounts[tokenId]
                    );
            }

            if (tokens[tokenId] == wethAddress && withdrawWethAsEth) {
                ethWithdrawn = amounts[tokenId];
            } else {
                uint256 currentReserves = IERC20MetadataUpgradeable(
                    tokens[tokenId]
                ).balanceOf(moduleMap.getModuleAddress(Modules.Kernel));
                if (currentReserves < amounts[tokenId]) {
                    // Amounts recovered from the integrations for the user was lower than requested, likely due to fees (see yearn).
                    IERC20MetadataUpgradeable(tokens[tokenId]).safeTransferFrom(
                            moduleMap.getModuleAddress(Modules.Kernel),
                            recipient,
                            currentReserves
                        );
                } else {
                    // Send the tokens back to specified recipient
                    IERC20MetadataUpgradeable(tokens[tokenId]).safeTransferFrom(
                            moduleMap.getModuleAddress(Modules.Kernel),
                            recipient,
                            amounts[tokenId]
                        );
                }
            }

            // Decrease rewards
            IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
                .decreaseRewards(tokens[tokenId], recipient, amounts[tokenId]);

            IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                .updateUserRewards(tokens[tokenId], recipient);

            // Update balances
            _totalSupply[tokens[tokenId]] -= amounts[tokenId];
            _balances[tokens[tokenId]][recipient] -= amounts[tokenId];
        }
    }

    function abs(int256 val) internal pure returns (uint256) {
        return uint256(val >= 0 ? val : -val);
    }

    /// @param recipient The address of the user claiming BIOS rewards
    function claimEthRewards(address recipient)
        external
        override
        onlyController
        returns (uint256 ethClaimed)
    {
        ethClaimed = _claimEthRewards(recipient);
    }

    /// @param recipient The address of the user claiming BIOS rewards
    function _claimEthRewards(address recipient)
        private
        returns (uint256 ethClaimed)
    {
        ethClaimed = IEtherRewards(
            moduleMap.getModuleAddress(Modules.EtherRewards)
        ).claimEthRewards(recipient);
    }

    /// @param asset Address of the ERC20 token contract
    /// @return The total balance of the asset deposited in the system
    function totalTokenBalance(address asset)
        public
        view
        override
        returns (uint256)
    {
        return _totalSupply[asset];
    }

    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userTokenBalance(address asset, address account)
        public
        view
        override
        returns (uint256)
    {
        if (_deployedBalances[account][asset] >= _balances[asset][account]) {
            return 0;
        }
        return _balances[asset][account] - _deployedBalances[account][asset];
    }

    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userInterconnectBalance(address asset, address account)
        public
        view
        override
        returns (uint256)
    {
        return _interconnectBalances[asset][account];
    }

    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userDeployableBalance(address asset, address account)
        public
        view
        override
        returns (uint256)
    {
        uint256 localAndForeignBalance = _balances[asset][account] +
            _interconnectBalances[asset][account];
        if (_deployedBalances[account][asset] >= localAndForeignBalance) {
            return 0;
        }
        return localAndForeignBalance - _deployedBalances[account][asset];
    }

    function enterStrategy(uint256 strategyID, TokenMovement[] calldata tokens)
        external
        override
    {
        _enterStrategy(strategyID, msg.sender, tokens, false);
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .increaseStrategy(strategyID, tokens);
    }

    function exitStrategy(uint256 strategyID, TokenMovement[] calldata tokens)
        external
        override
    {
        require(tokens.length > 0, "tokens required");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i].token != address(0), "invalid token");
            require(tokens[i].amount > 0, "invalid amount");
            require(
                _userStrategyBalances[msg.sender][strategyID][
                    tokens[i].token
                ] >= tokens[i].amount,
                "insufficient funds"
            );
            _deployedBalances[msg.sender][tokens[i].token] -= tokens[i].amount;
            _userStrategyBalances[msg.sender][strategyID][
                tokens[i].token
            ] -= tokens[i].amount;
        }

        emit ExitStrategy(strategyID, msg.sender, tokens);

        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .decreaseStrategy(strategyID, tokens);
    }

    function updateUserTokenBalances(
        address[] memory assets,
        address account,
        uint256[] memory amounts,
        bool[] memory add
    ) external override onlyController {
        require(
            assets.length == amounts.length,
            "UserPositions::updateUserTokenBalances: arrays must be equal length"
        );
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 currBal = _balances[assets[i]][account];
            require(
                0 != amounts[i],
                "UserPositions::updateUserTokenBalances: Must have a positive or negative number to change the balance"
            );
            uint256 newAvailableAmount;
            if (add[i]) {
                newAvailableAmount = currBal + amounts[i];
            } else {
                require(
                    amounts[i] <= currBal,
                    "UserPositions::updateUserTokenBalances: Amount to reduce balance must be no more than current balance"
                );
                newAvailableAmount = currBal - amounts[i];
            }
            _balances[assets[i]][account] = newAvailableAmount;
        }
    }

    function updateUserInterconnectBalances(
        address[] memory assets,
        address account,
        uint256[] memory amounts,
        bool[] memory add
    ) external override onlyController {
        require(
            assets.length == amounts.length,
            "UserPositions::updateUserInterconnectBalances: arrays must be equal length"
        );
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 currBal = _interconnectBalances[assets[i]][account];
            require(
                0 != amounts[i],
                "UserPositions::updateUserInterconnectBalances: Must have a positive or negative number to change the balance"
            );
            uint256 newAvailableAmount;
            if (add[i]) {
                newAvailableAmount = currBal + amounts[i];
            } else {
                require(
                    amounts[i] <= currBal,
                    "UserPositions::updateUserInterconnectBalances: Amount to reduce balance must be no more than current balance"
                );
                newAvailableAmount = currBal - amounts[i];
            }
            _interconnectBalances[assets[i]][account] = newAvailableAmount;
        }
    }

    function getUserStrategyBalanceByToken(
        uint256 id,
        address token,
        address user
    ) external view override returns (uint256 amount) {
        return _userStrategyBalances[user][id][token];
    }

    function getUserInvestedAmountByToken(address token, address user)
        external
        view
        override
        returns (uint256 amount)
    {
        return _deployedBalances[user][token];
    }

    function getUserBalances(
        address user,
        uint256[] calldata _strategies,
        address[] calldata _tokens
    )
        external
        view
        override
        returns (
            IStrategyMap.StrategyBalance[] memory strategyBalance,
            IStrategyMap.GeneralBalance[] memory userBalance
        )
    {
        strategyBalance = new IStrategyMap.StrategyBalance[](
            _strategies.length
        );
        userBalance = new IStrategyMap.GeneralBalance[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            userBalance[i].token = _tokens[i];
            userBalance[i].balance = _balances[_tokens[i]][user];
        }
        address strategyMapAddress = moduleMap.getModuleAddress(
            Modules.StrategyMap
        );
        for (uint256 i = 0; i < _strategies.length; i++) {
            IStrategyMap.Token[] memory strategyTokens = IStrategyMap(
                strategyMapAddress
            ).getStrategy(_strategies[i]).tokens;

            strategyBalance[i].tokens = new IStrategyMap.GeneralBalance[](
                strategyTokens.length
            );
            strategyBalance[i].strategyID = _strategies[i];
            for (uint256 j = 0; j < strategyTokens.length; j++) {
                strategyBalance[i].tokens[j].token = strategyTokens[j].token;
                strategyBalance[i].tokens[j].balance = _userStrategyBalances[
                    user
                ][_strategies[i]][strategyTokens[j].token];
            }
        }
    }

    function _enterStrategy(
        uint256 strategyId,
        address user,
        TokenMovement[] calldata tokens,
        bool migration
    ) internal {
        require(tokens.length > 0, "tokens required");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i].token != address(0), "invalid token");
            require(tokens[i].amount > 0, "invalid amount");
            if (!migration) {
                require(
                    userDeployableBalance(tokens[i].token, user) >=
                        tokens[i].amount,
                    "insufficient funds"
                );
            } else {
                _balances[tokens[i].token][user] += tokens[i].amount;
            }

            _userStrategyBalances[user][strategyId][tokens[i].token] += tokens[
                i
            ].amount;
            _deployedBalances[user][tokens[i].token] += tokens[i].amount;
        }

        emit EnterStrategy(strategyId, user, tokens);
    }

    function migrateUser(uint256 strategyId, MigrateStrategy[] calldata users)
        external
        override
        onlyController
    {
        IStrategyMap strategyMap = IStrategyMap(
            moduleMap.getModuleAddress(Modules.StrategyMap)
        );
        for (uint256 i = 0; i < users.length; i++) {
            _enterStrategy(strategyId, users[i].user, users[i].tokens, true);
            strategyMap.increaseTokenBalance(strategyId, users[i].tokens);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "../interfaces/IStrategyMap.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IIntegration.sol";
import "../interfaces/IAMMIntegration.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IYieldManager.sol";
import "../interfaces/IERC20.sol";

contract StrategyMap is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IStrategyMap
{
    // #### Constants
    uint32 public constant TOKEN_WEIGHT = 100000;

    // #### Global State

    // Strategy id => Strategy
    mapping(uint256 => Strategy) internal strategies;

    // Token => total amount in all strategies
    mapping(address => uint256) internal tokenBalances;

    // Strategy => token => balance
    mapping(uint256 => mapping(address => uint256))
        internal strategyTokenBalances;

    // Integration => pool id => token => amount to deploy
    mapping(address => mapping(uint32 => mapping(address => int256)))
        internal deployAmount;

    // Token => {integration, pool, amount}[]
    mapping(address => ClosablePosition[]) private _closablePositions;

    uint256 public override idCounter;

    // Used for strategy verification. Contents are always deleted at the end of a tx to reduce gas hit.
    mapping(address => uint256) internal tokenWeights;

    // #### Functions

    function initialize(address[] memory controllers_, address moduleMap_)
        public
        initializer
    {
        __Controlled_init(controllers_, moduleMap_);
    }

    function addStrategy(
        string calldata name,
        Integration[] calldata integrations,
        Token[] calldata tokens
    ) external override onlyController {
        require(integrations.length > 0, "integrations missing");
        require(tokens.length > 0, "tokens missing");
        require(bytes(name).length > 0, "must have a name");

        idCounter++;
        uint256 strategyID = idCounter;
        _verifyAndSetStrategy(strategyID, name, integrations, tokens);

        // Emit event
        emit NewStrategy(strategyID, integrations, tokens, name);
    }

    function _verifyAndSetStrategy(
        uint256 strategyID,
        string memory name,
        Integration[] memory integrations,
        Token[] memory tokens
    ) internal {
        for (uint256 i = 0; i < integrations.length; i++) {
            require(
                integrations[i].integration != address(0),
                "bad integration"
            );
        }

        address[] memory uniqueTokens = new address[](tokens.length);
        uint256 idx = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                tokens[i].integrationPairIdx < integrations.length,
                "integration idx out of bounds"
            );
            require(tokens[i].token != address(0), "bad token");

            if (tokenWeights[tokens[i].token] == 0) {
                uniqueTokens[idx] = tokens[i].token;
                idx++;
            }
            tokenWeights[tokens[i].token] += tokens[i].weight;
        }

        // Verify weights
        for (uint256 i = 0; i < idx; i++) {
            require(
                tokenWeights[uniqueTokens[i]] == TOKEN_WEIGHT,
                "invalid token weight"
            );
            strategies[strategyID].availableTokens[uniqueTokens[i]] = true;
            delete tokenWeights[uniqueTokens[i]];
        }

        strategies[strategyID].name = name;

        // Can't copy a memory array directly to storage yet, so we build it manually.
        for (uint256 i = 0; i < integrations.length; i++) {
            strategies[strategyID].integrations.push(integrations[i]);
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            strategies[strategyID].tokens.push(tokens[i]);
        }
    }

    function updateName(uint256 id, string calldata name)
        external
        override
        onlyController
    {
        require(bytes(strategies[id].name).length > 0, "strategy must exist");
        require(bytes(name).length > 0, "invalid name");
        strategies[id].name = name;
        emit UpdateName(id, name);
    }

    function updateStrategy(
        uint256 id,
        Integration[] calldata integrations,
        Token[] calldata tokens
    ) external override onlyController {
        require(integrations.length > 0, "integrations missing");
        require(tokens.length > 0, "tokens missing");
        require(bytes(strategies[id].name).length > 0, "strategy must exist");

        StrategySummary memory currentStrategy = getStrategy(id);

        delete strategies[id].tokens;
        delete strategies[id].integrations;

        // Reduce deploy amount for each current token by: strat token balance * weight / TOKEN_WEIGHT

        for (uint256 i = 0; i < currentStrategy.tokens.length; i++) {
            deployAmount[
                currentStrategy
                    .integrations[currentStrategy.tokens[i].integrationPairIdx]
                    .integration
            ][
                currentStrategy
                    .integrations[currentStrategy.tokens[i].integrationPairIdx]
                    .ammPoolID
            ][currentStrategy.tokens[i].token] -= int256(
                (strategyTokenBalances[id][currentStrategy.tokens[i].token] *
                    currentStrategy.tokens[i].weight) / TOKEN_WEIGHT
            );

            delete strategies[id].availableTokens[
                currentStrategy.tokens[i].token
            ];
        }

        // Increase deploy amount for each new token by: strat token balance * weight / TOKEN_WEIGHT
        for (uint256 i = 0; i < tokens.length; i++) {
            if (strategyTokenBalances[id][tokens[i].token] > 0) {
                deployAmount[
                    integrations[tokens[i].integrationPairIdx].integration
                ][integrations[tokens[i].integrationPairIdx].ammPoolID][
                    tokens[i].token
                ] += int256(
                    (strategyTokenBalances[id][tokens[i].token] *
                        tokens[i].weight) / TOKEN_WEIGHT
                );
            }
        }

        _verifyAndSetStrategy(id, currentStrategy.name, integrations, tokens);

        emit UpdateStrategy(id, integrations, tokens);
    }

    function deleteStrategy(uint256 id) external override onlyController {
        StrategySummary memory strategy = getStrategy(id);
        for (uint256 i = 0; i < strategy.tokens.length; i++) {
            require(
                strategyTokenBalances[id][strategy.tokens[i].token] == 0,
                "strategy in use"
            );
            delete strategies[id].availableTokens[strategy.tokens[i].token];
        }
        delete strategies[id];
        emit DeleteStrategy(id);
    }

    function increaseStrategy(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external override onlyController {
        StrategySummary memory strategy = getStrategy(id);

        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                strategies[id].availableTokens[tokens[i].token],
                "invalid token"
            );
            strategyTokenBalances[id][tokens[i].token] += tokens[i].amount;
            tokenBalances[tokens[i].token] += tokens[i].amount;

            for (uint256 j = 0; j < strategy.tokens.length; j++) {
                if (tokens[i].token == strategy.tokens[j].token) {
                    Integration memory integration = strategy.integrations[
                        strategy.tokens[j].integrationPairIdx
                    ];
                    deployAmount[integration.integration][
                        integration.ammPoolID
                    ][tokens[i].token] += int256(
                        _getTokenAmount(
                            tokens[i].amount,
                            strategy.tokens[j].weight,
                            TOKEN_WEIGHT
                        )
                    );
                }
            }
        }
    }

    function _getTokenAmount(
        uint256 tokenAmount,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        return (tokenAmount * numerator) / denominator;
    }

    function decreaseStrategy(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external override onlyController {
        StrategySummary memory strategy = getStrategy(id);
        require(strategy.tokens.length > 0, "invalid strategy");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                strategyTokenBalances[id][tokens[i].token] >= tokens[i].amount,
                "insufficient funds"
            );
            require(
                tokenBalances[tokens[i].token] >= tokens[i].amount,
                "insufficient funds"
            );
            strategyTokenBalances[id][tokens[i].token] -= tokens[i].amount;
            tokenBalances[tokens[i].token] -= tokens[i].amount;

            for (uint256 j = 0; j < strategy.tokens.length; j++) {
                if (tokens[i].token == strategy.tokens[j].token) {
                    Integration memory integration = strategy.integrations[
                        strategy.tokens[j].integrationPairIdx
                    ];
                    uint256 amount = _getTokenAmount(
                        tokens[i].amount,
                        strategy.tokens[j].weight,
                        TOKEN_WEIGHT
                    );
                    deployAmount[integration.integration][
                        integration.ammPoolID
                    ][tokens[i].token] -= int256(amount);

                    _closablePositions[tokens[i].token].push(
                        ClosablePosition(
                            integration.integration,
                            integration.ammPoolID,
                            amount
                        )
                    );
                }
            }
        }
    }

    function clearClosablePositions(address[] calldata tokens)
        external
        override
        onlyController
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            delete _closablePositions[tokens[i]];
        }
    }

    function closePositionsForWithdrawal(address token, uint256 amount)
        external
        override
        onlyController
    {
        ClosablePosition[] memory positions = _closablePositions[token];
        uint256 amountGathered = 0;
        address kernel = moduleMap.getModuleAddress(Modules.Kernel);
        if (positions.length > 0) {
            for (uint256 i = positions.length - 1; i >= 0; i--) {
                uint256 balanceBefore = IERC20(token).balanceOf(kernel);
                if (positions[i].ammPoolID == 0) {
                    IIntegration(positions[i].integration).withdraw(
                        token,
                        positions[i].amount
                    );
                } else {
                    IAMMIntegration(positions[i].integration).withdraw(
                        token,
                        positions[i].amount,
                        positions[i].ammPoolID
                    );
                }
                uint256 recovered = IERC20(token).balanceOf(kernel) -
                    balanceBefore;

                _closablePositions[token].pop();

                decreaseDeployAmountChange(
                    positions[i].integration,
                    positions[i].ammPoolID,
                    token,
                    positions[i].amount // Still decreasing by the notional amount, since we are erasing the closable position entirely from the vector
                );

                amountGathered += recovered;

                if (amountGathered >= amount) {
                    break;
                }
            }
        }
    }

    function decreaseDeployAmountChange(
        address integration,
        uint32 poolID,
        address token,
        uint256 amount
    ) public override {
        int256 currentAmount = deployAmount[integration][poolID][token];

        if (currentAmount >= 0) {
            deployAmount[integration][poolID][token] -= int256(amount);
        } else {
            deployAmount[integration][poolID][token] += int256(amount);
        }
    }

    function getStrategy(uint256 id)
        public
        view
        override
        returns (StrategySummary memory)
    {
        StrategySummary memory result;
        result.name = strategies[id].name;
        result.integrations = strategies[id].integrations;
        result.tokens = strategies[id].tokens;
        return result;
    }

    function getMultipleStrategies(uint256[] calldata ids)
        external
        view
        override
        returns (StrategySummary[] memory)
    {
        StrategySummary[] memory severalStrategies = new StrategySummary[](
            ids.length
        );
        for (uint256 i = 0; i < ids.length; i++) {
            severalStrategies[i] = getStrategy(ids[i]);
        }
        return severalStrategies;
    }

    function getStrategyTokenBalance(uint256 id, address token)
        public
        view
        override
        returns (uint256 amount)
    {
        amount = strategyTokenBalances[id][token];
    }

    function getTokenTotalBalance(address token)
        public
        view
        override
        returns (uint256 amount)
    {
        amount = tokenBalances[token];
    }

    function getDeployAmount(
        address integration,
        uint32 poolID,
        address token
    ) external view override returns (int256) {
        return deployAmount[integration][poolID][token];
    }

    function getStrategyBalances(
        uint256[] calldata _strategies,
        address[] calldata _tokens
    )
        external
        view
        override
        returns (
            StrategyBalance[] memory strategyBalances,
            GeneralBalance[] memory generalBalances
        )
    {
        strategyBalances = new StrategyBalance[](_strategies.length);
        generalBalances = new GeneralBalance[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            generalBalances[i].token = _tokens[i];
            generalBalances[i].balance = tokenBalances[_tokens[i]];
        }

        for (uint256 i = 0; i < _strategies.length; i++) {
            Token[] memory strategyTokens = strategies[_strategies[i]].tokens;
            strategyBalances[i].tokens = new GeneralBalance[](
                strategyTokens.length
            );
            strategyBalances[i].strategyID = _strategies[i];
            for (uint256 j = 0; j < strategyTokens.length; j++) {
                strategyBalances[i].tokens[j].token = strategyTokens[j].token;
                strategyBalances[i].tokens[j].balance = strategyTokenBalances[
                    _strategies[i]
                ][strategyTokens[j].token];
            }
        }
    }

    function getStrategyTokenLength(uint256 strategy)
        external
        view
        override
        returns (uint256)
    {
        return strategies[strategy].tokens.length;
    }

    function getClosablePositions(address token, uint256 index)
        external
        view
        returns (ClosablePosition memory)
    {
        return _closablePositions[token][index];
    }

    function increaseTokenBalance(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external override onlyController {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                strategies[id].availableTokens[tokens[i].token],
                "invalid token"
            );
            strategyTokenBalances[id][tokens[i].token] += tokens[i].amount;
            tokenBalances[tokens[i].token] += tokens[i].amount;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "../interfaces/IStrategyManager.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IStrategyMap.sol";
import "../interfaces/IYieldManager.sol";

contract StrategyManager is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IStrategyManager
{
    // #### Functions
    function initialize(address[] memory controllers_, address moduleMap_)
        public
        initializer
    {
        __Controlled_init(controllers_, moduleMap_);
    }

    /**
      @notice Adds a new strategy to the strategy map.
      @dev This is a passthrough to StrategyMap.addStrategy
       */
    function addStrategy(
        string calldata name,
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external override onlyManager {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        for (uint256 i = 0; i < integrations.length; i++) {
            require(
                integrationMap.getIsIntegrationAdded(
                    integrations[i].integration
                )
            );
        }
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .addStrategy(name, integrations, tokens);
    }

    /**
    @notice Updates the whitelisted tokens a strategy accepts for new deposits
    @dev This is a passthrough to StrategyMap.updateStrategyTokens
     */
    function updateStrategy(
        uint256 id,
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external override onlyManager {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        for (uint256 i = 0; i < integrations.length; i++) {
            require(
                integrationMap.getIsIntegrationAdded(
                    integrations[i].integration
                )
            );
        }
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .updateStrategy(id, integrations, tokens);
    }

    /**
        @notice Updates a strategy's name
        @dev This is a pass through function to StrategyMap.updateName
     */
    function updateStrategyName(uint256 id, string calldata name)
        external
        override
        onlyManager
    {
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .updateName(id, name);
    }

    /**
        @notice Deletes a strategy
        @dev This is a pass through to StrategyMap.deleteStrategy
        */
    function deleteStrategy(uint256 id) external override onlyManager {
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .deleteStrategy(id);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;
import "../interfaces/IStrategyMap.sol";

interface IStrategyManager {
    // #### Functions
    /**
      @notice Adds a new strategy to the strategy map.
      @dev This is a passthrough to StrategyMap.addStrategy
       */
    function addStrategy(
        string calldata name,
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external;

    /**
        @notice Updates a strategy's name
        @dev This is a pass through function to StrategyMap.updateName
     */
    function updateStrategyName(uint256 id, string calldata name) external;

    /**
      @notice Updates the tokens that a strategy accepts
      @dev This is a passthrough to StrategyMap.updateStrategyTokens
       */
    function updateStrategy(
        uint256 id,
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external;

    /**
        @notice Deletes a strategy
        @dev This is a pass through to StrategyMap.deleteStrategy
        */
    function deleteStrategy(uint256 id) external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUniswapFactory.sol";
import "../interfaces/IUniswapPositionManager.sol";
import "../interfaces/IUniswapSwapRouter.sol";
import "../interfaces/IUniswapTrader.sol";
import "../interfaces/IUniswapPool.sol";
import "../libraries/FullMath.sol";

/// @notice Integrates 0x Nodes to Uniswap v3
/// @notice tokenA/tokenB naming implies tokens are unsorted
/// @notice token0/token1 naming implies tokens are sorted
contract UniswapTrader is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IUniswapTrader
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    struct Pool {
        uint24 feeNumerator;
        uint24 slippageNumerator;
    }

    struct TokenPair {
        address token0;
        address token1;
    }

    uint24 private constant FEE_DENOMINATOR = 1_000_000;
    uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
    address private factoryAddress;
    address private swapRouterAddress;

    mapping(address => mapping(address => Pool[])) private pools;
    mapping(address => mapping(address => Path)) private paths;
    mapping(address => mapping(address => bool)) private isMultihopPair;

    TokenPair[] private tokenPairs;

    event UniswapPoolAdded(
        address indexed token0,
        address indexed token1,
        uint24 fee,
        uint24 slippageNumerator
    );
    event UniswapPoolSlippageNumeratorUpdated(
        address indexed token0,
        address indexed token1,
        uint256 poolIndex,
        uint24 slippageNumerator
    );
    event UniswapPairPrimaryPoolUpdated(
        address indexed token0,
        address indexed token1,
        uint256 primaryPoolIndex
    );

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ Module Map address
    /// @param factoryAddress_ The address of the Uniswap factory contract
    /// @param swapRouterAddress_ The address of the Uniswap swap router contract
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address factoryAddress_,
        address swapRouterAddress_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        factoryAddress = factoryAddress_;
        swapRouterAddress = swapRouterAddress_;
    }

    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @param feeNumerator The Uniswap pool fee numerator
    /// @param slippageNumerator The value divided by the slippage denominator
    /// to calculate the allowable slippage
    /// positions is enabled for this pool
    function addPool(
        address tokenA,
        address tokenB,
        uint24 feeNumerator,
        uint24 slippageNumerator
    ) external override onlyManager {
        require(
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getIsTokenAdded(tokenA),
            "UniswapTrader::addPool: TokenA has not been added in the Integration Map"
        );
        require(
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getIsTokenAdded(tokenB),
            "UniswapTrader::addPool: TokenB has not been added in the Integration Map"
        );
        require(
            slippageNumerator <= SLIPPAGE_DENOMINATOR,
            "UniswapTrader::addPool: Slippage numerator cannot be greater than slippapge denominator"
        );
        require(
            IUniswapFactory(factoryAddress).getPool(
                tokenA,
                tokenB,
                feeNumerator
            ) != address(0),
            "UniswapTrader::addPool: Pool does not exist"
        );

        (address token0, address token1) = getTokensSorted(tokenA, tokenB);

        bool poolAdded;
        for (
            uint256 poolIndex;
            poolIndex < pools[token0][token1].length;
            poolIndex++
        ) {
            if (pools[token0][token1][poolIndex].feeNumerator == feeNumerator) {
                poolAdded = true;
            }
        }

        require(
            !poolAdded,
            "UniswapTrader::addPool: Pool has already been added"
        );

        Pool memory newPool;
        newPool.feeNumerator = feeNumerator;
        newPool.slippageNumerator = slippageNumerator;
        pools[token0][token1].push(newPool);

        bool tokenPairAdded;
        for (uint256 pairIndex; pairIndex < tokenPairs.length; pairIndex++) {
            if (
                tokenPairs[pairIndex].token0 == token0 &&
                tokenPairs[pairIndex].token1 == token1
            ) {
                tokenPairAdded = true;
            }
        }

        if (!tokenPairAdded) {
            TokenPair memory newTokenPair;
            newTokenPair.token0 = token0;
            newTokenPair.token1 = token1;
            tokenPairs.push(newTokenPair);

            if (
                IERC20MetadataUpgradeable(token0).allowance(
                    address(this),
                    moduleMap.getModuleAddress(Modules.YieldManager)
                ) == 0
            ) {
                IERC20MetadataUpgradeable(token0).safeApprove(
                    moduleMap.getModuleAddress(Modules.YieldManager),
                    type(uint256).max
                );
            }

            if (
                IERC20MetadataUpgradeable(token1).allowance(
                    address(this),
                    moduleMap.getModuleAddress(Modules.YieldManager)
                ) == 0
            ) {
                IERC20MetadataUpgradeable(token1).safeApprove(
                    moduleMap.getModuleAddress(Modules.YieldManager),
                    type(uint256).max
                );
            }

            if (
                IERC20MetadataUpgradeable(token0).allowance(
                    address(this),
                    swapRouterAddress
                ) == 0
            ) {
                IERC20MetadataUpgradeable(token0).safeApprove(
                    swapRouterAddress,
                    type(uint256).max
                );
            }

            if (
                IERC20MetadataUpgradeable(token1).allowance(
                    address(this),
                    swapRouterAddress
                ) == 0
            ) {
                IERC20MetadataUpgradeable(token1).safeApprove(
                    swapRouterAddress,
                    type(uint256).max
                );
            }
        }

        emit UniswapPoolAdded(token0, token1, feeNumerator, slippageNumerator);
    }

    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param poolIndex The index of the pool for the specified token pair
    /// @param slippageNumerator The new slippage numerator to update the pool
    function updatePoolSlippageNumerator(
        address tokenA,
        address tokenB,
        uint256 poolIndex,
        uint24 slippageNumerator
    ) external override onlyManager {
        require(
            slippageNumerator <= SLIPPAGE_DENOMINATOR,
            "UniswapTrader:updatePoolSlippageNumerator: Slippage numerator must not be greater than slippage denominator"
        );
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        require(
            pools[token0][token1][poolIndex].slippageNumerator !=
                slippageNumerator,
            "UniswapTrader:updatePoolSlippageNumerator: Slippage numerator must be updated to a new number"
        );
        require(
            pools[token0][token1].length > poolIndex,
            "UniswapTrader:updatePoolSlippageNumerator: Pool does not exist"
        );

        pools[token0][token1][poolIndex].slippageNumerator = slippageNumerator;

        emit UniswapPoolSlippageNumeratorUpdated(
            token0,
            token1,
            poolIndex,
            slippageNumerator
        );
    }

    /// @notice Updates which Uniswap pool to use as the default pool
    /// @notice when swapping between token0 and token1
    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
    function updatePairPrimaryPool(
        address tokenA,
        address tokenB,
        uint256 primaryPoolIndex
    ) external override onlyManager {
        require(
            primaryPoolIndex != 0,
            "UniswapTrader::updatePairPrimaryPool: Specified index is already the primary pool"
        );
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        require(
            primaryPoolIndex < pools[token0][token1].length,
            "UniswapTrader::updatePairPrimaryPool: Specified pool index does not exist"
        );

        uint24 newPrimaryPoolFeeNumerator = pools[token0][token1][
            primaryPoolIndex
        ].feeNumerator;
        uint24 newPrimaryPoolSlippageNumerator = pools[token0][token1][
            primaryPoolIndex
        ].slippageNumerator;

        pools[token0][token1][primaryPoolIndex].feeNumerator = pools[token0][
            token1
        ][0].feeNumerator;
        pools[token0][token1][primaryPoolIndex].slippageNumerator = pools[
            token0
        ][token1][0].slippageNumerator;

        pools[token0][token1][0].feeNumerator = newPrimaryPoolFeeNumerator;
        pools[token0][token1][0]
            .slippageNumerator = newPrimaryPoolSlippageNumerator;

        emit UniswapPairPrimaryPoolUpdated(token0, token1, primaryPoolIndex);
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountIn The exact amount of the input to swap
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn
    ) external override onlyController returns (bool tradeSuccess) {
        IERC20MetadataUpgradeable tokenInErc20 = IERC20MetadataUpgradeable(
            tokenIn
        );

        if (isMultihopPair[tokenIn][tokenOut]) {
            Path memory path = getPathFor(tokenIn, tokenOut);
            IUniswapSwapRouter.ExactInputParams
                memory params = IUniswapSwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        path.tokenIn,
                        path.firstPoolFee,
                        path.tokenInTokenOut,
                        path.secondPoolFee,
                        path.tokenOut
                    ),
                    recipient: recipient,
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: 0
                });

            // Executes the swap.
            try IUniswapSwapRouter(swapRouterAddress).exactInput(params) {
                tradeSuccess = true;
            } catch {
                tradeSuccess = false;
                tokenInErc20.safeTransfer(
                    recipient,
                    tokenInErc20.balanceOf(address(this))
                );
            }

            return tradeSuccess;
        }

        (address token0, address token1) = getTokensSorted(tokenIn, tokenOut);

        require(
            pools[token0][token1].length > 0,
            "UniswapTrader::swapExactInput: Pool has not been added"
        );
        require(
            tokenInErc20.balanceOf(address(this)) >= amountIn,
            "UniswapTrader::swapExactInput: Balance is less than trade amount"
        );

        uint256 amountOutMinimum = getAmountOutMinimum(
            tokenIn,
            tokenOut,
            amountIn
        );

        IUniswapSwapRouter.ExactInputSingleParams memory exactInputSingleParams;
        exactInputSingleParams.tokenIn = tokenIn;
        exactInputSingleParams.tokenOut = tokenOut;
        exactInputSingleParams.fee = pools[token0][token1][0].feeNumerator;
        exactInputSingleParams.recipient = recipient;
        exactInputSingleParams.deadline = block.timestamp;
        exactInputSingleParams.amountIn = amountIn;
        exactInputSingleParams.amountOutMinimum = amountOutMinimum;
        exactInputSingleParams.sqrtPriceLimitX96 = 0;

        try
            IUniswapSwapRouter(swapRouterAddress).exactInputSingle(
                exactInputSingleParams
            )
        {
            tradeSuccess = true;
        } catch {
            tradeSuccess = false;
            tokenInErc20.safeTransfer(
                recipient,
                tokenInErc20.balanceOf(address(this))
            );
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountOut The exact amount of the output token to receive
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut
    ) external override onlyController returns (bool tradeSuccess) {
        IERC20MetadataUpgradeable tokenInErc20 = IERC20MetadataUpgradeable(
            tokenIn
        );

        if (isMultihopPair[tokenIn][tokenOut]) {
            Path memory path = getPathFor(tokenIn, tokenOut);
            IUniswapSwapRouter.ExactOutputParams
                memory params = IUniswapSwapRouter.ExactOutputParams({
                    path: abi.encodePacked(
                        path.tokenIn,
                        path.firstPoolFee,
                        path.tokenInTokenOut,
                        path.secondPoolFee,
                        path.tokenOut
                    ),
                    recipient: recipient,
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: 0
                });

            // Executes the swap.
            try IUniswapSwapRouter(swapRouterAddress).exactOutput(params) {
                tradeSuccess = true;
            } catch {
                tradeSuccess = false;
                tokenInErc20.safeTransfer(
                    recipient,
                    tokenInErc20.balanceOf(address(this))
                );
            }

            return tradeSuccess;
        }
        (address token0, address token1) = getTokensSorted(tokenIn, tokenOut);
        require(
            pools[token0][token1][0].feeNumerator > 0,
            "UniswapTrader::swapExactOutput: Pool has not been added"
        );
        uint256 amountInMaximum = getAmountInMaximum(
            tokenIn,
            tokenOut,
            amountOut
        );
        require(
            tokenInErc20.balanceOf(address(this)) >= amountInMaximum,
            "UniswapTrader::swapExactOutput: Balance is less than trade amount"
        );

        IUniswapSwapRouter.ExactOutputSingleParams
            memory exactOutputSingleParams;
        exactOutputSingleParams.tokenIn = tokenIn;
        exactOutputSingleParams.tokenOut = tokenOut;
        exactOutputSingleParams.fee = pools[token0][token1][0].feeNumerator;
        exactOutputSingleParams.recipient = recipient;
        exactOutputSingleParams.deadline = block.timestamp;
        exactOutputSingleParams.amountOut = amountOut;
        exactOutputSingleParams.amountInMaximum = amountInMaximum;
        exactOutputSingleParams.sqrtPriceLimitX96 = 0;

        try
            IUniswapSwapRouter(swapRouterAddress).exactOutputSingle(
                exactOutputSingleParams
            )
        {
            tradeSuccess = true;
        } catch {
            tradeSuccess = false;
            tokenInErc20.safeTransfer(
                recipient,
                tokenInErc20.balanceOf(address(this))
            );
        }
    }

    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @return pool The pool address
    function getPoolAddress(address tokenA, address tokenB)
        public
        view
        override
        returns (address pool)
    {
        uint24 feeNumerator = getPoolFeeNumerator(tokenA, tokenB, 0);
        pool = IUniswapFactory(factoryAddress).getPool(
            tokenA,
            tokenB,
            feeNumerator
        );
    }

    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    function getSqrtPriceX96(address tokenA, address tokenB)
        public
        view
        returns (uint256)
    {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapPool(
            getPoolAddress(tokenA, tokenB)
        ).slot0();
        return uint256(sqrtPriceX96);
    }

    function getPathFor(address tokenIn, address tokenOut)
        public
        view
        override
        returns (Path memory)
    {
        require(
            isMultihopPair[tokenIn][tokenOut],
            "There is an existing Pool for this pair"
        );

        return paths[tokenIn][tokenOut];
    }

    function setPathFor(
        address tokenIn,
        address tokenOut,
        uint256 firstPoolFee,
        address tokenInTokenOut,
        uint256 secondPoolFee
    ) external override onlyManager {
        paths[tokenIn][tokenOut] = Path(
            tokenIn,
            firstPoolFee,
            tokenInTokenOut,
            secondPoolFee,
            tokenOut
        );
        isMultihopPair[tokenIn][tokenOut] = true;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
    function getAmountOutMinimum(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOutMinimum) {
        uint256 estimatedAmountOut = getEstimatedTokenOut(
            tokenIn,
            tokenOut,
            amountIn
        );
        uint24 poolSlippageNumerator = getPoolSlippageNumerator(
            tokenIn,
            tokenOut,
            0
        );
        amountOutMinimum =
            (estimatedAmountOut *
                (SLIPPAGE_DENOMINATOR - poolSlippageNumerator)) /
            SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of token being swapped for
    /// @return amountInMaximum The maximum amount of tokenIn to spend, factoring in allowable slippage
    function getAmountInMaximum(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) public view override returns (uint256 amountInMaximum) {
        uint256 estimatedAmountIn = getEstimatedTokenIn(
            tokenIn,
            tokenOut,
            amountOut
        );
        uint24 poolSlippageNumerator = getPoolSlippageNumerator(
            tokenIn,
            tokenOut,
            0
        );
        amountInMaximum =
            (estimatedAmountIn *
                (SLIPPAGE_DENOMINATOR + poolSlippageNumerator)) /
            SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getEstimatedTokenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view override returns (uint256 amountOut) {
        if (isMultihopPair[tokenIn][tokenOut]) {
            Path memory path = getPathFor(tokenIn, tokenOut);
            uint256 amountOutTemp = getEstimatedTokenOut(
                path.tokenIn,
                path.tokenInTokenOut,
                amountIn
            );
            return
                getEstimatedTokenOut(
                    path.tokenInTokenOut,
                    path.tokenOut,
                    amountOutTemp
                );
        }

        uint24 feeNumerator = getPoolFeeNumerator(tokenIn, tokenOut, 0);
        uint256 sqrtPriceX96 = getSqrtPriceX96(tokenIn, tokenOut);

        // FullMath is used to allow intermediate calculation values of up to 2^512
        if (tokenIn < tokenOut) {
            amountOut =
                (FullMath.mulDiv(
                    FullMath.mulDiv(amountIn, sqrtPriceX96, 2**96),
                    sqrtPriceX96,
                    2**96
                ) * (FEE_DENOMINATOR - feeNumerator)) /
                FEE_DENOMINATOR;
        } else {
            amountOut =
                (FullMath.mulDiv(
                    FullMath.mulDiv(amountIn, 2**96, sqrtPriceX96),
                    2**96,
                    sqrtPriceX96
                ) * (FEE_DENOMINATOR - feeNumerator)) /
                FEE_DENOMINATOR;
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of the output token to swap for
    /// @return amountIn The estimated amount of tokenIn to spend
    function getEstimatedTokenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) public view returns (uint256 amountIn) {
        if (isMultihopPair[tokenIn][tokenOut]) {
            Path memory path = getPathFor(tokenIn, tokenOut);
            uint256 amountInTemp = getEstimatedTokenIn(
                path.tokenInTokenOut,
                path.tokenOut,
                amountOut
            );
            return
                getEstimatedTokenIn(
                    path.tokenIn,
                    path.tokenInTokenOut,
                    amountInTemp
                );
        }

        uint24 feeNumerator = getPoolFeeNumerator(tokenIn, tokenOut, 0);
        uint256 sqrtPriceX96 = getSqrtPriceX96(tokenIn, tokenOut);

        // FullMath is used to allow intermediate calculation values of up to 2^512
        if (tokenIn < tokenOut) {
            amountIn =
                (FullMath.mulDiv(
                    FullMath.mulDiv(amountOut, 2**96, sqrtPriceX96),
                    2**96,
                    sqrtPriceX96
                ) * (FEE_DENOMINATOR - feeNumerator)) /
                FEE_DENOMINATOR;
        } else {
            amountIn =
                (FullMath.mulDiv(
                    FullMath.mulDiv(amountOut, sqrtPriceX96, 2**96),
                    sqrtPriceX96,
                    2**96
                ) * (FEE_DENOMINATOR - feeNumerator)) /
                FEE_DENOMINATOR;
        }
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return feeNumerator The numerator that gets divided by the fee denominator
    function getPoolFeeNumerator(
        address tokenA,
        address tokenB,
        uint256 poolId
    ) public view override returns (uint24 feeNumerator) {
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        require(
            poolId < pools[token0][token1].length,
            "UniswapTrader::getPoolFeeNumerator: Pool ID does not exist"
        );
        feeNumerator = pools[token0][token1][poolId].feeNumerator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return slippageNumerator The numerator that gets divided by the slippage denominator
    function getPoolSlippageNumerator(
        address tokenA,
        address tokenB,
        uint256 poolId
    ) public view returns (uint24 slippageNumerator) {
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        return pools[token0][token1][poolId].slippageNumerator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the sorted token0
    /// @return token1 The address of the sorted token1
    function getTokensSorted(address tokenA, address tokenB)
        public
        pure
        override
        returns (address token0, address token1)
    {
        if (tokenA < tokenB) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param amountA The amount of tokenA
    /// @param amountB The amount of tokenB
    /// @return token0 The address of sorted token0
    /// @return token1 The address of sorted token1
    /// @return amount0 The amount of sorted token0
    /// @return amount1 The amount of sorted token1
    function getTokensAndAmountsSorted(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    )
        external
        pure
        returns (
            address token0,
            address token1,
            uint256 amount0,
            uint256 amount1
        )
    {
        if (tokenA < tokenB) {
            token0 = tokenA;
            token1 = tokenB;
            amount0 = amountA;
            amount1 = amountB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
            amount0 = amountB;
            amount1 = amountA;
        }
    }

    /// @return The denominator used to calculate the pool fee percentage
    function getFeeDenominator() external pure returns (uint24) {
        return FEE_DENOMINATOR;
    }

    /// @return The denominator used to calculate the allowable slippage percentage
    function getSlippageDenominator() external pure returns (uint24) {
        return SLIPPAGE_DENOMINATOR;
    }

    /// @return The number of token pairs configured
    function getTokenPairsLength() external view override returns (uint256) {
        return tokenPairs.length;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return The quantity of pools configured for the specified token pair
    function getTokenPairPoolsLength(address tokenA, address tokenB)
        external
        view
        override
        returns (uint256)
    {
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        return pools[token0][token1].length;
    }

    /// @param tokenPairIndex The index of the token pair
    /// @return The address of token0
    /// @return The address of token1
    function getTokenPair(uint256 tokenPairIndex)
        external
        view
        returns (address, address)
    {
        require(
            tokenPairIndex < tokenPairs.length,
            "UniswapTrader::getTokenPair: Token pair does not exist"
        );
        return (
            tokenPairs[tokenPairIndex].token0,
            tokenPairs[tokenPairIndex].token1
        );
    }

    /// @param token0 The address of token0 of the pool
    /// @param token1 The address of token1 of the pool
    /// @param poolIndex The index of the pool
    /// @return The pool fee numerator
    /// @return The pool slippage numerator
    function getPool(
        address token0,
        address token1,
        uint256 poolIndex
    ) external view returns (uint24, uint24) {
        require(
            poolIndex < pools[token0][token1].length,
            "UniswapTrader:getPool: Pool does not exist"
        );
        return (
            pools[token0][token1][poolIndex].feeNumerator,
            pools[token0][token1][poolIndex].slippageNumerator
        );
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IUniswapFactory {
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IUniswapPositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IUniswapSwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function exactInput(ExactInputParams calldata params)
        external
        returns (uint256 amountOut);

    function exactOutput(ExactOutputParams calldata params)
        external
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IUniswapPool {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity >=0.7.6;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(
            sqrtRatioAX96,
            sqrtRatioBX96,
            FixedPoint96.Q96
        );
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(
                sqrtRatioX96,
                sqrtRatioBX96,
                amount0
            );
            uint128 liquidity1 = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioX96,
                amount1
            );

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                liquidity,
                sqrtRatioBX96 - sqrtRatioAX96,
                FixedPoint96.Q96
            );
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioX96,
                sqrtRatioBX96,
                liquidity
            );
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioX96,
                liquidity
            );
        } else {
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IBiosRewards.sol";
import "../interfaces/IKernel.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IYieldManager.sol";
import "../interfaces/IInterconnects.sol";
import "../interfaces/IWeth9.sol";
import "../interfaces/IUniswapTrader.sol";
import "../interfaces/ISushiSwapTrader.sol";
import "../interfaces/IStrategyMap.sol";
import "./ModuleMapConsumer.sol";

/// @title Kernel
/// @notice Allows users to deposit/withdraw erc20 tokens
/// @notice Allows a system admin to control which tokens are depositable
contract Kernel is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ModuleMapConsumer,
    IKernel,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant OWNER_ROLE = keccak256("owner_role");
    bytes32 public constant MANAGER_ROLE = keccak256("manager_role");

    uint256 private lastDeployTimestamp;
    uint256 private lastHarvestYieldTimestamp;
    uint256 private lastDistributeEthTimestamp;
    uint256 private lastLastDistributeEthTimestamp;
    uint256 private lastBiosBuyBackTimestamp;
    uint256 private initializationTimestamp;

    bool private lpWhitelistEnabled;

    bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
        keccak256("liquidity_provider_role");

    modifier onlyGasAccount() {
        require(
            msg.sender ==
                IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
                    .getGasAccount(),
            "Caller is not gas account"
        );
        _;
    }

    modifier onlyLpWhitelist() {
        require(
            !lpWhitelistEnabled || hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender),
            "Caller is not whitelisted as a liquidity provider"
        );
        _;
    }

    receive() external payable {}

    /// @notice Initializes contract - used as a replacement for a constructor
    /// @param admin_ default administrator, a cold storage address
    /// @param owner_ single owner account, used to manage the managers
    /// @param moduleMap_ Module Map address
    function initialize(
        address admin_,
        address owner_,
        address moduleMap_
    ) external initializer {
        __ModuleMapConsumer_init(moduleMap_);
        __ReentrancyGuard_init();
        __AccessControl_init();
        // make the "admin_" address the default admin role
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);

        // make the "owner_" address the owner of the system
        _setupRole(OWNER_ROLE, owner_);

        // give the "owner_" address the manager role, too
        _setupRole(MANAGER_ROLE, owner_);

        // give the "owner_" address the liquidity provider role, too
        _setupRole(LIQUIDITY_PROVIDER_ROLE, owner_);

        // owners are admins of managers
        _setRoleAdmin(MANAGER_ROLE, OWNER_ROLE);

        // managers are admins of liquidity providers
        _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, MANAGER_ROLE);

        initializationTimestamp = block.timestamp;
        lpWhitelistEnabled = true;
    }

    /// @param biosRewardsDuration The duration in seconds for a BIOS rewards period to last
    function setBiosRewardsDuration(uint32 biosRewardsDuration)
        external
        onlyRole(MANAGER_ROLE)
    {
        IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
            .setBiosRewardsDuration(biosRewardsDuration);

        emit SetBiosRewardsDuration(biosRewardsDuration);
    }

    /// @param biosAmount The amount of BIOS to add to the rewards
    function seedBiosRewards(uint256 biosAmount)
        external
        onlyRole(MANAGER_ROLE)
    {
        IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
            .seedBiosRewards(msg.sender, biosAmount);

        emit SeedBiosRewards(biosAmount);
    }

    /// @notice This function is used after tokens have been added, and a weight array should be included
    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    function addIntegration(address contractAddress, string memory name)
        external
        onlyRole(MANAGER_ROLE)
    {
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
            .addIntegration(contractAddress, name);

        emit IntegrationAdded(contractAddress, name);
    }

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function addToken(
        address tokenAddress,
        bool acceptingDeposits,
        bool acceptingWithdrawals,
        bool acceptingLping,
        bool acceptingBridging,
        uint256 biosRewardWeight,
        uint256 reserveRatioNumerator,
        uint256 targetLiquidityRatioNumerator,
        uint256 transferFeeKValueNumerator,
        uint256 transferFeePlatformRatioNumerator
    ) external onlyRole(MANAGER_ROLE) {
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
            .addToken(
                tokenAddress,
                acceptingDeposits,
                acceptingWithdrawals,
                acceptingLping,
                acceptingBridging,
                biosRewardWeight,
                reserveRatioNumerator,
                targetLiquidityRatioNumerator,
                transferFeeKValueNumerator,
                transferFeePlatformRatioNumerator
            );

        if (
            IERC20MetadataUpgradeable(tokenAddress).allowance(
                moduleMap.getModuleAddress(Modules.Kernel),
                moduleMap.getModuleAddress(Modules.YieldManager)
            ) == 0
        ) {
            IERC20MetadataUpgradeable(tokenAddress).safeApprove(
                moduleMap.getModuleAddress(Modules.YieldManager),
                type(uint256).max
            );
        }

        if (
            IERC20MetadataUpgradeable(tokenAddress).allowance(
                moduleMap.getModuleAddress(Modules.Kernel),
                moduleMap.getModuleAddress(Modules.UserPositions)
            ) == 0
        ) {
            IERC20MetadataUpgradeable(tokenAddress).safeApprove(
                moduleMap.getModuleAddress(Modules.UserPositions),
                type(uint256).max
            );
        }

        emit TokenAdded(
            tokenAddress,
            acceptingDeposits,
            acceptingWithdrawals,
            acceptingLping,
            acceptingBridging,
            biosRewardWeight,
            reserveRatioNumerator,
            targetLiquidityRatioNumerator,
            transferFeeKValueNumerator,
            transferFeePlatformRatioNumerator
        );
    }

    /// @param biosBuyBackEthWeight The relative weight of ETH to send to BIOS buy back
    /// @param treasuryEthWeight The relative weight of ETH to send to the treasury
    /// @param protocolFeeEthWeight The relative weight of ETH to send to protocol fee accrual
    /// @param rewardsEthWeight The relative weight of ETH to send to user rewards
    function updateEthDistributionWeights(
        uint32 biosBuyBackEthWeight,
        uint32 treasuryEthWeight,
        uint32 protocolFeeEthWeight,
        uint32 rewardsEthWeight
    ) external onlyRole(MANAGER_ROLE) {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
            .updateEthDistributionWeights(
                biosBuyBackEthWeight,
                treasuryEthWeight,
                protocolFeeEthWeight,
                rewardsEthWeight
            );

        emit EthDistributionWeightsUpdated(
            biosBuyBackEthWeight,
            treasuryEthWeight,
            protocolFeeEthWeight,
            rewardsEthWeight
        );
    }

    /// @notice Gives the UserPositions contract approval to transfer BIOS from Kernel
    function tokenApprovals() external onlyRole(MANAGER_ROLE) {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        IERC20MetadataUpgradeable bios = IERC20MetadataUpgradeable(
            integrationMap.getBiosTokenAddress()
        );
        IERC20MetadataUpgradeable weth = IERC20MetadataUpgradeable(
            integrationMap.getWethTokenAddress()
        );

        if (
            bios.allowance(
                address(this),
                moduleMap.getModuleAddress(Modules.BiosRewards)
            ) == 0
        ) {
            bios.safeApprove(
                moduleMap.getModuleAddress(Modules.BiosRewards),
                type(uint256).max
            );
        }
        if (
            bios.allowance(
                address(this),
                moduleMap.getModuleAddress(Modules.YieldManager)
            ) == 0
        ) {
            bios.safeApprove(
                moduleMap.getModuleAddress(Modules.YieldManager),
                type(uint256).max
            );
        }

        if (
            weth.allowance(
                address(this),
                moduleMap.getModuleAddress(Modules.UserPositions)
            ) == 0
        ) {
            weth.safeApprove(
                moduleMap.getModuleAddress(Modules.UserPositions),
                type(uint256).max
            );
        }

        if (
            weth.allowance(
                address(this),
                moduleMap.getModuleAddress(Modules.YieldManager)
            ) == 0
        ) {
            weth.safeApprove(
                moduleMap.getModuleAddress(Modules.YieldManager),
                type(uint256).max
            );
        }
    }

    function enableLpWhitelist() external onlyRole(MANAGER_ROLE) {
        lpWhitelistEnabled = true;
    }

    function disableLpWhitelist() external onlyRole(MANAGER_ROLE) {
        lpWhitelistEnabled = false;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @param updatedWeight The updated token BIOS reward weight
    function updateTokenRewardWeight(
        address tokenAddress,
        uint256 updatedWeight
    ) external onlyRole(MANAGER_ROLE) {
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
            .updateTokenRewardWeight(tokenAddress, updatedWeight);

        emit TokenSettingUpdated(
            tokenAddress,
            TokenSettings.TokenSettingName.rewardWeight,
            updatedWeight
        );
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(
        address tokenAddress,
        uint256 reserveRatioNumerator
    ) external onlyRole(MANAGER_ROLE) {
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
            .updateTokenReserveRatioNumerator(
                tokenAddress,
                reserveRatioNumerator
            );

        emit TokenSettingUpdated(
            tokenAddress,
            TokenSettings.TokenSettingName.reserveRatioNumerator,
            reserveRatioNumerator
        );
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param targetLiquidityRatioNumerator Number that gets divided by target liquidity ratio denominator to get target liquidity ratio
    function updateTokenTargetLiquidityRatioNumerator(
        address tokenAddress,
        uint256 targetLiquidityRatioNumerator
    ) external onlyRole(MANAGER_ROLE) {
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
            .updateTokenTargetLiquidityRatioNumerator(
                tokenAddress,
                targetLiquidityRatioNumerator
            );
        emit TokenSettingUpdated(
            tokenAddress,
            TokenSettings.TokenSettingName.targetLiquidityRatioNumerator,
            targetLiquidityRatioNumerator
        );
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param transferFeeKValueNumerator Number that gets divided by transfer fee K-value denominator to get K-value
    function updateTokenTransferFeeKValueNumerator(
        address tokenAddress,
        uint256 transferFeeKValueNumerator
    ) external onlyRole(MANAGER_ROLE) {
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
            .updateTokenTransferFeeKValueNumerator(
                tokenAddress,
                transferFeeKValueNumerator
            );

        emit TokenSettingUpdated(
            tokenAddress,
            TokenSettings.TokenSettingName.transferFeeKValueNumerator,
            transferFeeKValueNumerator
        );
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param transferFeePlatformRatioNumerator Number that gets divided by transfer fee platform ratio denominator to get the ratio of transfer fees sent to the platform instead of LPers
    function updateTokenTransferFeePlatformRatioNumerator(
        address tokenAddress,
        uint256 transferFeePlatformRatioNumerator
    ) external onlyRole(MANAGER_ROLE) {
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
            .updateTokenTransferFeePlatformRatioNumerator(
                tokenAddress,
                transferFeePlatformRatioNumerator
            );

        emit TokenSettingUpdated(
            tokenAddress,
            TokenSettings.TokenSettingName.transferFeePlatformRatioNumerator,
            transferFeePlatformRatioNumerator
        );
    }

    /// @param gasAccount The address of the account to send ETH to gas for executing bulk system functions
    function updateGasAccount(address payable gasAccount)
        external
        onlyRole(MANAGER_ROLE)
    {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
            .updateGasAccount(gasAccount);

        emit GasAccountUpdated(gasAccount);
    }

    /// @param treasuryAccount The address of the system treasury account
    function updateTreasuryAccount(address payable treasuryAccount)
        external
        onlyRole(MANAGER_ROLE)
    {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
            .updateTreasuryAccount(treasuryAccount);

        emit TreasuryAccountUpdated(treasuryAccount);
    }

    /// @param gasAccountTargetEthBalance The target ETH balance of the gas account
    function updateGasAccountTargetEthBalance(
        uint256 gasAccountTargetEthBalance
    ) external onlyRole(MANAGER_ROLE) {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
            .updateGasAccountTargetEthBalance(gasAccountTargetEthBalance);

        emit GasAccountTargetEthBalanceUpdated(gasAccountTargetEthBalance);
    }

    /// @notice User is allowed to deposit whitelisted tokens
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    function deposit(address[] memory tokens, uint256[] memory amounts)
        external
        payable
        nonReentrant
    {
        if (msg.value > 0) {
            // Convert ETH to WETH
            address wethAddress = IIntegrationMap(
                moduleMap.getModuleAddress(Modules.IntegrationMap)
            ).getWethTokenAddress();
            IWeth9(wethAddress).deposit{value: msg.value}();
        }

        IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions))
            .deposit(msg.sender, tokens, amounts, msg.value, false);
    }

    /// @notice User is allowed to withdraw tokens
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    function withdraw(
        address[] memory tokens,
        uint256[] memory amounts,
        bool withdrawWethAsEth
    ) external nonReentrant {
        uint256 ethWithdrawn = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        ).withdraw(msg.sender, tokens, amounts, withdrawWethAsEth);

        if (ethWithdrawn > 0) {
            IWeth9(
                IIntegrationMap(
                    moduleMap.getModuleAddress(Modules.IntegrationMap)
                ).getWethTokenAddress()
            ).withdraw(ethWithdrawn);

            payable(msg.sender).transfer(ethWithdrawn);
        }

        emit Withdraw(msg.sender, tokens, amounts, ethWithdrawn);
    }

    /// @notice Allows a user to withdraw entire undeployed balances of the specified tokens and claim rewards
    /// @param tokens Array of token address that user is exiting positions from
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    /// @return tokenAmounts The amounts of each token being withdrawn
    /// @return ethWithdrawn The amount of WETH balance being withdrawn as ETH
    /// @return ethClaimed The amount of ETH being claimed from rewards
    /// @return biosClaimed The amount of BIOS being claimed from rewards
    function withdrawAllAndClaim(
        address[] memory tokens,
        bool withdrawWethAsEth
    )
        external
        returns (
            uint256[] memory tokenAmounts,
            uint256 ethWithdrawn,
            uint256 ethClaimed,
            uint256 biosClaimed
        )
    {
        (tokenAmounts, ethWithdrawn, ethClaimed, biosClaimed) = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        ).withdrawAllAndClaim(msg.sender, tokens, withdrawWethAsEth);

        if (ethWithdrawn > 0) {
            IWeth9(
                IIntegrationMap(
                    moduleMap.getModuleAddress(Modules.IntegrationMap)
                ).getWethTokenAddress()
            ).withdraw(ethWithdrawn);
        }

        if (ethWithdrawn + ethClaimed > 0) {
            payable(msg.sender).transfer(ethWithdrawn + ethClaimed);
        }

        emit WithdrawAllAndClaim(
            msg.sender,
            tokens,
            withdrawWethAsEth,
            tokenAmounts,
            ethWithdrawn,
            ethClaimed,
            biosClaimed
        );
    }

    /// @notice User is allowed to LP whitelisted tokens
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    function provideLiquidity(address[] memory tokens, uint256[] memory amounts)
        external
        onlyLpWhitelist
        nonReentrant
    {
        IInterconnects(moduleMap.getModuleAddress(Modules.Interconnects))
            .provideLiquidity(msg.sender, tokens, amounts);
    }

    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    function takeLiquidity(address[] memory tokens, uint256[] memory amounts)
        external
        onlyLpWhitelist
        nonReentrant
    {
        IInterconnects(moduleMap.getModuleAddress(Modules.Interconnects))
            .takeLiquidity(msg.sender, tokens, amounts);
    }

    /// @param tokens Array of token the token addresses
    function claimLpFees(address[] memory tokens)
        external
        onlyLpWhitelist
        nonReentrant
    {
        IInterconnects(moduleMap.getModuleAddress(Modules.Interconnects))
            .claimLpFeeRewards(msg.sender, tokens);
    }

    /// @notice Allows user to claim their BIOS rewards
    /// @return ethClaimed The amount of ETH claimed by the user
    function claimEthRewards()
        public
        nonReentrant
        returns (uint256 ethClaimed)
    {
        ethClaimed = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        ).claimEthRewards(msg.sender);

        payable(msg.sender).transfer(ethClaimed);

        emit ClaimEthRewards(msg.sender, ethClaimed);
    }

    /// @notice Allows user to claim their BIOS rewards
    /// @return biosClaimed The amount of BIOS claimed by the user
    function claimBiosRewards()
        public
        nonReentrant
        returns (uint256 biosClaimed)
    {
        biosClaimed = IBiosRewards(
            moduleMap.getModuleAddress(Modules.BiosRewards)
        ).claimBiosRewards(msg.sender);

        emit ClaimBiosRewards(msg.sender, biosClaimed);
    }

    /// @notice Allows user to claim their ETH and BIOS rewards
    /// @return ethClaimed The amount of ETH claimed by the user
    /// @return biosClaimed The amount of BIOS claimed by the user
    function claimAllRewards()
        external
        nonReentrant
        returns (uint256 ethClaimed, uint256 biosClaimed)
    {
        ethClaimed = claimEthRewards();
        biosClaimed = claimBiosRewards();
    }

    /// @notice Deploys all tokens to all integrations according to configured weights
    function deploy(IYieldManager.DeployRequest[] calldata deployments)
        external
        onlyGasAccount
    {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager)).deploy(
            deployments
        );
        lastDeployTimestamp = block.timestamp;
        emit Deploy();
    }

    /// @notice Harvests available yield from all tokens and integrations
    function harvestYield(
        address integrationAddress,
        address[] calldata tokenAddresses
    ) external onlyGasAccount {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
            .harvestYield(integrationAddress, tokenAddresses);
        lastHarvestYieldTimestamp = block.timestamp;
        emit HarvestYield();
    }

    /// @notice Distributes WETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
    function distributeEth() external onlyGasAccount {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
            .distributeEth();
        lastLastDistributeEthTimestamp = lastDistributeEthTimestamp;
        lastDistributeEthTimestamp = block.timestamp;
        emit DistributeEth();
    }

    /// @notice Uses any WETH held in the SushiSwap integration to buy back BIOS which is sent to the Kernel
    function biosBuyBack() external onlyGasAccount {
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
            .biosBuyBack();
        lastBiosBuyBackTimestamp = block.timestamp;
        emit BiosBuyBack();
    }

    /// @param account The address of the account to check if they are a manager
    /// @return Bool indicating whether the account is a manger
    function isManager(address account) public view override returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

    /// @param account The address of the account to check if they are an owner
    /// @return Bool indicating whether the account is an owner
    function isOwner(address account) public view override returns (bool) {
        return hasRole(OWNER_ROLE, account);
    }

    /// @param account The address of the account to check if they are a liquidity provider
    /// @return Bool indicating whether the account is a liquidity provider
    function isLiquidityProvider(address account)
        public
        view
        override
        returns (bool)
    {
        return hasRole(LIQUIDITY_PROVIDER_ROLE, account);
    }

    /// @return The timestamp the deploy function was last called
    function getLastDeployTimestamp() external view returns (uint256) {
        return lastDeployTimestamp;
    }

    /// @return The timestamp the harvestYield function was last called
    function getLastHarvestYieldTimestamp() external view returns (uint256) {
        return lastHarvestYieldTimestamp;
    }

    /// @return The timestamp the distributeEth function was last called
    function getLastDistributeEthTimestamp() external view returns (uint256) {
        return lastDistributeEthTimestamp;
    }

    /// @return The timestamp the biosBuyBack function was last called
    function getLastBiosBuyBackTimestamp() external view returns (uint256) {
        return lastBiosBuyBackTimestamp;
    }

    /// @return ethRewardsTimePeriod The number of seconds between the last two ETH payouts
    function getEthRewardsTimePeriod()
        external
        view
        returns (uint256 ethRewardsTimePeriod)
    {
        if (lastDistributeEthTimestamp > 0) {
            if (lastLastDistributeEthTimestamp > 0) {
                ethRewardsTimePeriod =
                    lastDistributeEthTimestamp -
                    lastLastDistributeEthTimestamp;
            } else {
                ethRewardsTimePeriod =
                    lastDistributeEthTimestamp -
                    initializationTimestamp;
            }
        } else {
            ethRewardsTimePeriod = 0;
        }
    }

    function getLpWhitelistEnabled() external view returns (bool) {
        return lpWhitelistEnabled;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IInterconnects {
    // ##### Events
    struct lpData {
        uint256 position;
        uint256 rewards;
    }

    event ProvideLiquidity(
        address indexed user,
        address[] tokens,
        uint256[] tokenAmounts
    );
    event TakeLiquidity(
        address indexed user,
        address[] tokens,
        uint256[] tokenAmounts
    );

    event ClaimLpFeeRewards(address indexed user, address[] tokens);

    event BridgeFrom(address indexed user, address[] tokens, uint256[] amounts);

    event UndoBridgeFrom(
        address indexed user,
        address[] tokens,
        uint256[] amounts
    );

    event BridgeTo(address indexed user, address[] tokens, uint256[] amounts);

    event UpdateTokenPoolLpBalances(
        address[] tokens,
        uint256[] tokenAmounts,
        bool[] add
    );

    // ##### Functions
    /// @param relayAccount_ The address of relay account
    function updateRelayAccount(address payable relayAccount_) external;

    /// @return The address of the relay account
    function getRelayAccount() external view returns (address);

    /// @notice User is allowed to LP whitelisted tokens
    /// @param user Address of the account LP-ing
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function provideLiquidity(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /// @param user Address of the account LP-ing
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function takeLiquidity(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /// @param user Address of the account LP-ing
    /// @param tokens Array of the token addresses
    function claimLpFeeRewards(address user, address[] memory tokens) external;

    // @param user Address of the account bridging
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function bridgeFrom(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    // @param user Address of the account bridging
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function undoBridgeFrom(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    // @param user Address of the account bridging
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function bridgeTo(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function getTokenUserLpBalance(address asset, address account)
        external
        view
        returns (uint256);

    /// @param asset Address of the ERC20 token contract
    function getTokenPoolLpBalance(address asset)
        external
        view
        returns (uint256);

    /// @param asset Address of the ERC20 token contract
    function getTokenPoolLpActivePositions(address asset)
        external
        view
        returns (uint256);

    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function getTokenUserLpFeeRewardBalance(address asset, address account)
        external
        view
        returns (uint256);

    /// @param asset Address of the ERC20 token contract
    function getTokenLpUsers(address asset)
        external
        view
        returns (address[] memory);

    /// @param asset Address of the ERC20 token contract
    function getTokenProtocolFeeRewards(address asset)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/ISushiSwapTrader.sol";
import "../interfaces/ISushiSwapFactory.sol";
import "../interfaces/ISushiSwapRouter.sol";
import "../interfaces/ISushiSwapPair.sol";
import "../interfaces/IIntegrationMap.sol";

/// @notice Integrates 0x Nodes to SushiSwap
contract SushiSwapTrader is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    ISushiSwapTrader
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
    uint24 private slippageNumerator;
    address private factoryAddress;
    address private swapRouterAddress;

    event ExecutedSwapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 amountOut
    );

    event FailedSwapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    );

    event SushiSwapSlippageNumeratorUpdated(uint24 slippageNumerator);

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ The address of the module map contract
    /// @param factoryAddress_ The address of the SushiSwap factory contract
    /// @param swapRouterAddress_ The address of the SushiSwap swap router contract
    /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address factoryAddress_,
        address swapRouterAddress_,
        uint24 slippageNumerator_
    ) public initializer {
        require(
            slippageNumerator <= SLIPPAGE_DENOMINATOR,
            "SushiSwapTrader::initialize: Slippage Numerator must be less than or equal to slippage denominator"
        );
        __Controlled_init(controllers_, moduleMap_);
        factoryAddress = factoryAddress_;
        swapRouterAddress = swapRouterAddress_;
        slippageNumerator = slippageNumerator_;
    }

    /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
    function updateSlippageNumerator(uint24 slippageNumerator_)
        external
        override
        onlyManager
    {
        require(
            slippageNumerator_ != slippageNumerator,
            "SushiSwapTrader::setSlippageNumerator: Slippage numerator must be set to a new value"
        );
        require(
            slippageNumerator <= SLIPPAGE_DENOMINATOR,
            "SushiSwapTrader::setSlippageNumerator: Slippage Numerator must be less than or equal to slippage denominator"
        );

        slippageNumerator = slippageNumerator_;

        emit SushiSwapSlippageNumeratorUpdated(slippageNumerator_);
    }

    /// @notice Swaps all WETH held in this contract for BIOS and sends to the kernel
    /// @return Bool indicating whether the trade succeeded
    function biosBuyBack() external override onlyController returns (bool) {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address wethAddress = integrationMap.getWethTokenAddress();
        address biosAddress = integrationMap.getBiosTokenAddress();
        uint256 wethAmountIn = IERC20MetadataUpgradeable(wethAddress).balanceOf(
            address(this)
        );

        uint256 biosAmountOutMin = getAmountOutMinimum(
            wethAddress,
            biosAddress,
            wethAmountIn
        );

        return
            swapExactInput(
                wethAddress,
                integrationMap.getBiosTokenAddress(),
                moduleMap.getModuleAddress(Modules.Kernel),
                wethAmountIn,
                biosAmountOutMin
            );
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address of the token out recipient
    /// @param amountIn The exact amount of the input to swap
    /// @param amountOutMin The minimum amount of tokenOut to receive from the swap
    /// @return bool Indicates whether the swap succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) public override onlyController returns (bool) {
        require(
            IERC20MetadataUpgradeable(tokenIn).balanceOf(address(this)) >=
                amountIn,
            "SushiSwapTrader::swapExactInput: Balance is less than trade amount"
        );

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256 deadline = block.timestamp;

        if (
            IERC20MetadataUpgradeable(tokenIn).allowance(
                address(this),
                swapRouterAddress
            ) == 0
        ) {
            IERC20MetadataUpgradeable(tokenIn).safeApprove(
                swapRouterAddress,
                type(uint256).max
            );
        }

        uint256 tokenOutBalanceBefore = IERC20MetadataUpgradeable(tokenOut)
            .balanceOf(recipient);

        try
            ISushiSwapRouter(swapRouterAddress).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                recipient,
                deadline
            )
        {
            emit ExecutedSwapExactInput(
                tokenIn,
                tokenOut,
                amountIn,
                amountOutMin,
                IERC20MetadataUpgradeable(tokenOut).balanceOf(recipient) -
                    tokenOutBalanceBefore
            );
            return true;
        } catch {
            emit FailedSwapExactInput(
                tokenIn,
                tokenOut,
                amountIn,
                amountOutMin
            );
            return false;
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
    function getAmountOutMinimum(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOutMinimum) {
        amountOutMinimum =
            (getAmountOut(tokenIn, tokenOut, amountIn) *
                (SLIPPAGE_DENOMINATOR - slippageNumerator)) /
            SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        require(
            amountIn > 0,
            "SushiSwapTrader::getAmountOut: amountIn must be greater than zero"
        );
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            tokenIn,
            tokenOut
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "SushiSwapTrader::getAmountOut: No liquidity in pool reserves"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return reserveA The reserve balance of tokenA in the pool
    /// @return reserveB The reserve balance of tokenB in the pool
    function getReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = getTokensSorted(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = ISushiSwapPair(
            getPairFor(tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of sorted token0
    /// @return token1 The address of sorted token1
    function getTokensSorted(address tokenA, address tokenB)
        internal
        view
        returns (address token0, address token1)
    {
        require(
            tokenA != tokenB,
            "SushiSwapTrader::sortToken: Identical token addresses"
        );
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        require(
            token0 != address(0),
            "SushiSwapTrader::sortToken: Zero address"
        );
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return pair The address of the SushiSwap pool contract
    function getPairFor(address tokenA, address tokenB)
        internal
        view
        returns (address pair)
    {
        pair = ISushiSwapFactory(factoryAddress).getPair(tokenA, tokenB);
    }

    /// @return SushiSwap Factory address
    function getFactoryAddress() external view returns (address) {
        return factoryAddress;
    }

    /// @return The slippage numerator
    function getSlippageNumerator() external view returns (uint24) {
        return slippageNumerator;
    }

    /// @return The slippage denominator
    function getSlippageDenominator() external pure returns (uint24) {
        return SLIPPAGE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Controlled.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IInterconnects.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUserPositions.sol";

contract Interconnects is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IInterconnects,
    ReentrancyGuardUpgradeable
{
    // Address of the relay account
    address payable private _relayAccount;

    // Token address => User address => Balance of tokens a user has in that token's liquidity pool
    mapping(address => mapping(address => lpData)) private _tokenUserLpBalances;

    // Token address => total liquidity pool for a token held by the contract
    mapping(address => uint256) private _tokenPoolLpBalances;

    // Token address => total protocol fees from bridging
    mapping(address => uint256) private _tokenProtocolFeeRewards;

    // Token address => The list of users currently LPing the token
    mapping(address => address[]) private _tokenLpUsers;

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ Address of the Module Map
    /// @param relayAccount_ The address of the relay account that will control this account
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address payable relayAccount_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        _relayAccount = relayAccount_;
    }

    modifier onlyRelayAccount() {
        require(
            msg.sender == _relayAccount,
            "Interconnects::onlyRelayAccount: Caller is not relay account"
        );
        _;
    }

    modifier validateBridging(
        address[] memory tokens,
        uint256[] memory amounts
    ) {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        require(
            tokens.length == amounts.length,
            "Interconnects::validateBridging: Length of tokens and amounts must be equal"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                integrationMap.getTokenAcceptingBridging(tokens[i]),
                "Interconnects::validateBridging: Token is not accepting bridging"
            );
        }
        _;
    }

    /// @param relayAccount_ The address of the relay account
    function updateRelayAccount(address payable relayAccount_)
        external
        override
        onlyController
    {
        _relayAccount = relayAccount_;
    }

    /// @return The address of the gas account
    function getRelayAccount() public view override returns (address) {
        return _relayAccount;
    }

    /// @notice User is allowed to LP whitelisted tokens
    /// @param user Address of the account LP-ing
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function provideLiquidity(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    ) external override onlyController {
        require(
            tokens.length == amounts.length,
            "Interconnects::provideLiquidity: Length of tokens and amounts must be equal"
        );

        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        address[] memory tokenArr = new address[](tokens.length);
        uint256[] memory amountArr = new uint256[](amounts.length);
        bool[] memory addArr = new bool[](tokens.length);
        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            require(
                integrationMap.getTokenAcceptingLping(tokens[tokenId]),
                "Interconnects::provideLiquidity: This token is not accepting LP positions"
            );
            address token = tokens[tokenId];
            require(
                amounts[tokenId] > 0 &&
                    amounts[tokenId] <=
                    userPositions.userTokenBalance(token, user),
                "Interconnects::provideLiquidity: LP amount must be greater than zero and no more than the user's balance"
            );
            tokenArr[tokenId] = token;
            amountArr[tokenId] = amounts[tokenId];
            addArr[tokenId] = false;

            // Keep track of who is currently LPing
            if (_tokenUserLpBalances[token][user].position == 0) {
                _tokenLpUsers[token].push(user);
            }

            _tokenUserLpBalances[token][user].position += amounts[tokenId];
            _tokenPoolLpBalances[token] += amounts[tokenId];
        }
        userPositions.updateUserTokenBalances(
            tokenArr,
            user,
            amountArr,
            addArr
        );
        emit ProvideLiquidity(user, tokens, amounts);
    }

    /// @param user Address of the account LP-ing
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function takeLiquidity(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    ) external override onlyController {
        require(
            tokens.length == amounts.length,
            "Interconnects::takeLiquidity: Length of tokens and amounts must be equal"
        );

        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        address[] memory tokenArr = new address[](tokens.length);
        uint256[] memory amountArr = new uint256[](amounts.length);
        bool[] memory addArr = new bool[](tokens.length);

        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            address token = tokens[tokenId];
            require(
                amounts[tokenId] > 0 &&
                    amounts[tokenId] <=
                    _tokenUserLpBalances[token][user].position,
                "Interconnects::takeLiquidity: LP amount must be greater than zero and no more than the user's balance for the token"
            );
            require(
                amounts[tokenId] <= _tokenPoolLpBalances[token],
                "Interconnects::takeLiquidity: LP amount must be no more than the available amount in the token pool"
            );

            tokenArr[tokenId] = token;
            amountArr[tokenId] = amounts[tokenId];
            addArr[tokenId] = true;

            _tokenUserLpBalances[token][user].position -= amounts[tokenId];
            _tokenPoolLpBalances[token] -= amounts[tokenId];

            // User has withdrawn all liquidity, so remove from list of LP users
            if (_tokenUserLpBalances[token][user].position == 0) {
                // Iterate through tokenLpUsers[token] and remove this user
                for (
                    uint256 lpUserIdx;
                    lpUserIdx < _tokenLpUsers[token].length;
                    lpUserIdx++
                ) {
                    if (_tokenLpUsers[token][lpUserIdx] == user) {
                        _tokenLpUsers[token][lpUserIdx] = _tokenLpUsers[token][
                            _tokenLpUsers[token].length - 1
                        ];
                        _tokenLpUsers[token].pop();
                        break;
                    }
                }
            }
        }
        userPositions.updateUserTokenBalances(
            tokenArr,
            user,
            amountArr,
            addArr
        );
        emit TakeLiquidity(user, tokens, amounts);
    }

    /// @notice User is allowed to claim fees
    /// @param user Address of the account LP-ing
    /// @param tokens Array of the token addresses
    function claimLpFeeRewards(address user, address[] memory tokens)
        external
        override
        onlyController
        nonReentrant
    {
        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        uint256[] memory amounts = new uint256[](tokens.length);
        bool[] memory add = new bool[](tokens.length);

        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            address token = tokens[tokenId];
            uint256 fees = _tokenUserLpBalances[token][user].rewards;
            require(
                fees > 0,
                "Interconnects::claimLpFees: LP fee reward balance must be greater than zero"
            );
            _tokenUserLpBalances[token][user].rewards = 0;
            amounts[tokenId] = fees;
            add[tokenId] = true;
        }
        userPositions.updateUserTokenBalances(tokens, user, amounts, add);

        emit ClaimLpFeeRewards(user, tokens);
    }

    /// @dev Wrapper around userPositions func to decrease user's token balance
    /// @param user user bridging
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function bridgeFrom(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    )
        external
        override
        onlyRelayAccount
        validateBridging(tokens, amounts)
        nonReentrant
    {
        // create add array with a false boolean for each address in tokens
        bool[] memory addArr = new bool[](tokens.length);
        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        userPositions.updateUserTokenBalances(tokens, user, amounts, addArr);
        emit BridgeFrom(user, tokens, amounts);
    }

    /// @dev Wrapper around userPositions func to increase user's token balance
    /// @param user user bridging
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function undoBridgeFrom(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    )
        external
        override
        onlyRelayAccount
        validateBridging(tokens, amounts)
        nonReentrant
    {
        // create add array with a true boolean for each address in tokens
        bool[] memory addArr = new bool[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            addArr[i] = true;
        }
        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        userPositions.updateUserTokenBalances(tokens, user, amounts, addArr);
        emit UndoBridgeFrom(user, tokens, amounts);
    }

    /// @dev Wrapper around userPositions func, updateTokenPoolLpBalances, and feeHandler
    /// @param user user bridging
    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function bridgeTo(
        address user,
        address[] memory tokens,
        uint256[] memory amounts
    )
        external
        override
        onlyRelayAccount
        validateBridging(tokens, amounts)
        nonReentrant
    {
        // create add array with a true boolean for each address in tokens
        bool[] memory addArr = new bool[](tokens.length);
        bool[] memory subArr = new bool[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            addArr[i] = true;
        }
        (
            uint256[] memory protocolFees,
            uint256[] memory liquidityProviderFees,
            uint256[] memory netBridgeAmounts
        ) = calculateBridgeFeesAndNetAmount(tokens, amounts);
        updateTokenPoolLpBalances(tokens, amounts, subArr);
        IUserPositions userPositions = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        );
        userPositions.updateUserInterconnectBalances(
            tokens,
            user,
            netBridgeAmounts,
            addArr
        );
        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 lpFee = liquidityProviderFees[i];
            uint256 protocolFee = protocolFees[i];
            updateTokenUserLpFeeRewardBalances(token, lpFee);
            _tokenProtocolFeeRewards[token] += protocolFee;
        }
        emit BridgeTo(user, tokens, amounts);
    }

    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    /// @param add Array of boolean values, true if adding, false if removing
    function updateTokenPoolLpBalances(
        address[] memory tokens,
        uint256[] memory amounts,
        bool[] memory add
    ) internal {
        require(
            tokens.length == amounts.length && tokens.length == add.length,
            "Interconnects::updateTokenPoolLpBalances: Length of tokens, amounts, and add/subtract must be equal"
        );

        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );

        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            require(
                integrationMap.getTokenAcceptingLping(tokens[tokenId]),
                "Interconnects::updateTokenPoolLpBalances: This token is not accepting LP positions"
            );

            uint256 newBalance;
            if (add[tokenId]) {
                newBalance =
                    _tokenPoolLpBalances[tokens[tokenId]] +
                    amounts[tokenId];
            } else {
                newBalance =
                    _tokenPoolLpBalances[tokens[tokenId]] -
                    amounts[tokenId];
            }

            _tokenPoolLpBalances[tokens[tokenId]] = newBalance;
        }
        emit UpdateTokenPoolLpBalances(tokens, amounts, add);
    }

    /// @param asset Address of the ERC20 token contract
    /// @param lpTransferFeeAmt Total fee amount which will be divided among the LPers
    function updateTokenUserLpFeeRewardBalances(
        address asset,
        uint256 lpTransferFeeAmt
    ) internal {
        uint256 totalAmountAllocated = getTokenPoolLpActivePositions(asset);
        for (
            uint256 lpUserIdx;
            lpUserIdx < _tokenLpUsers[asset].length;
            lpUserIdx++
        ) {
            address lpUser = _tokenLpUsers[asset][lpUserIdx];
            // User gets a portion of the fee proportional to their share of the pool
            _tokenUserLpBalances[asset][lpUser].rewards +=
                (lpTransferFeeAmt *
                    _tokenUserLpBalances[asset][lpUser].position) /
                totalAmountAllocated;
        }
    }

    /// @param tokens Array of the token addresses
    /// @param amounts Array of the token amounts
    function calculateBridgeFeesAndNetAmount(
        address[] memory tokens,
        uint256[] memory amounts
    )
        internal
        view
        returns (
            uint256[] memory protocolFees,
            uint256[] memory liquidityProviderFees,
            uint256[] memory netBridgeAmounts
        )
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint32 targetLiquidityRatioDenominator = integrationMap
            .getTargetLiquidityRatioDenominator();
        uint32 kValueDenominator = integrationMap
            .getTransferFeeKValueDenominator();
        uint32 protocolFeeDenominator = integrationMap
            .getTransferFeePlatformRatioDenominator();
        protocolFees = new uint256[](tokens.length);
        liquidityProviderFees = new uint256[](tokens.length);
        netBridgeAmounts = new uint256[](tokens.length);
        for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
            address token = tokens[tokenId];
            uint256 protocolFeeNumerator = integrationMap
                .getTokenTransferFeePlatformRatioNumerator(token);

            // x is the unallocated (currently available) liquidity divided by the target liquidity
            uint256 x = (_tokenPoolLpBalances[token] *
                targetLiquidityRatioDenominator) /
                (integrationMap.getTokenTargetLiquidityRatioNumerator(token) *
                    getTokenPoolLpActivePositions(token));

            uint256 totalFee = (integrationMap
                .getTokenTransferFeeKValueNumerator(token) * amounts[tokenId]) /
                (kValueDenominator * x);

            protocolFees[tokenId] =
                (totalFee * protocolFeeNumerator) /
                protocolFeeDenominator;
            liquidityProviderFees[tokenId] = totalFee - protocolFees[tokenId];
            netBridgeAmounts[tokenId] = amounts[tokenId] - totalFee;
        }

        return (protocolFees, liquidityProviderFees, netBridgeAmounts);
    }

    /// @param asset Address of the ERC20 token contract
    /// @param user Address of the user account
    function getTokenUserLpBalance(address asset, address user)
        public
        view
        override
        returns (uint256)
    {
        return _tokenUserLpBalances[asset][user].position;
    }

    /// @param asset Address of the ERC20 token contract
    function getTokenPoolLpBalance(address asset)
        public
        view
        override
        returns (uint256)
    {
        return _tokenPoolLpBalances[asset];
    }

    /// @dev this returns the sum of all active LP positions for a given token. This is different than the LP balance, as the LP balance is the available amount of this sum. This number is gte the LP balance, usually greater than.
    /// @param asset Address of the ERC20 token contract
    function getTokenPoolLpActivePositions(address asset)
        public
        view
        override
        returns (uint256)
    {
        uint256 sum = 0;
        address[] memory lpUsers = _tokenLpUsers[asset];
        for (uint256 lpUserIdx; lpUserIdx < lpUsers.length; lpUserIdx++) {
            address lpUser = lpUsers[lpUserIdx];
            sum += _tokenUserLpBalances[asset][lpUser].position;
        }
        return sum;
    }

    /// @param asset Address of the ERC20 token contract
    /// @param user Address of the user account
    function getTokenUserLpFeeRewardBalance(address asset, address user)
        public
        view
        override
        returns (uint256)
    {
        return _tokenUserLpBalances[asset][user].rewards;
    }

    /// @param asset Address of the ERC20 token contract
    function getTokenLpUsers(address asset)
        public
        view
        override
        returns (address[] memory)
    {
        return _tokenLpUsers[asset];
    }

    /// @param asset Address of the ERC20 token contract
    function getTokenProtocolFeeRewards(address asset)
        public
        view
        override
        returns (uint256)
    {
        return _tokenProtocolFeeRewards[asset];
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IModuleMap.sol";

contract ModuleMap is IModuleMap, Initializable, OwnableUpgradeable {
    mapping(Modules => address) private _moduleMap;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    function getModuleAddress(Modules key)
        public
        view
        override
        returns (address)
    {
        return _moduleMap[key];
    }

    function setModuleAddress(Modules key, address value) external onlyOwner {
        _moduleMap[key] = value;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "../interfaces/IIntegrationMap.sol";

contract IntegrationMap is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IIntegrationMap
{
    uint32 private constant RESERVE_RATIO_DENOMINATOR = 1_000_000;
    address private wethTokenAddress;
    address private biosTokenAddress;
    address[] private tokenAddresses;
    address[] private integrationAddresses;

    // Integration address => Integration details
    mapping(address => Integration) private integrations;
    // Token address => Token details
    mapping(address => Token) private tokens;

    uint32 private constant TARGET_LIQUIDITY_RATIO_DENOMINATOR = 1_000_000;
    uint32 private constant TRANSFER_FEE_K_VALUE_DENOMINATOR = 1_000_000;
    uint32 private constant TRANSFER_FEE_PLATFORM_RATIO_DENOMINATOR = 1_000_000;

    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address wethTokenAddress_,
        address biosTokenAddress_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        wethTokenAddress = wethTokenAddress_;
        biosTokenAddress = biosTokenAddress_;

        _addToken(
            wethTokenAddress_,
            true,
            true,
            true,
            true,
            1_000,
            50_000,
            100_000,
            40_000,
            50_000
        );
        _addToken(
            biosTokenAddress_,
            true,
            true,
            true,
            true,
            1_000,
            0,
            100_000,
            40_000,
            50_00
        );
    }

    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    function addIntegration(address contractAddress, string memory name)
        external
        override
        onlyController
    {
        require(
            !integrations[contractAddress].added,
            "IntegrationMap::addIntegration: Integration already added"
        );
        integrations[contractAddress].added = true;
        integrations[contractAddress].name = name;
        integrationAddresses.push(contractAddress);
    }

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function _addToken(
        address tokenAddress,
        bool acceptingDeposits,
        bool acceptingWithdrawals,
        bool acceptingLping,
        bool acceptingBridging,
        uint256 biosRewardWeight,
        uint256 reserveRatioNumerator,
        uint256 targetLiquidityRatioNumerator,
        uint256 transferFeeKValueNumerator,
        uint256 transferFeePlatformRatioNumerator
    ) internal {
        // We skip instead of error when you re-add a token due to great migration of 2021
        if (tokens[tokenAddress].added) {
            return;
        }

        require(
            reserveRatioNumerator <= RESERVE_RATIO_DENOMINATOR,
            "IntegrationMap::addToken: reserveRatioNumerator must be less than or equal to reserve ratio denominator"
        );
        require(
            targetLiquidityRatioNumerator <= TARGET_LIQUIDITY_RATIO_DENOMINATOR,
            "IntegrationMap::addToken: targetLiquidityRatioNumerator must be less than or equal to target liquidity ratio denominator"
        );
        require(
            transferFeeKValueNumerator <= TRANSFER_FEE_K_VALUE_DENOMINATOR,
            "IntegrationMap::addToken: transferFeeKValueNumerator must be less than or equal to transfer fee K-value denominator"
        );
        require(
            transferFeePlatformRatioNumerator <=
                TRANSFER_FEE_PLATFORM_RATIO_DENOMINATOR,
            "IntegrationMap::addToken: transferFeePlatformRatioNumerator must be less than or equal to transfer fee platform ratio denominator"
        );

        tokens[tokenAddress].id = tokenAddresses.length;
        tokens[tokenAddress].added = true;
        tokens[tokenAddress].acceptingDeposits = acceptingDeposits;
        tokens[tokenAddress].acceptingWithdrawals = acceptingWithdrawals;
        tokens[tokenAddress].acceptingLping = acceptingLping;
        tokens[tokenAddress].acceptingBridging = acceptingBridging;
        tokens[tokenAddress].biosRewardWeight = biosRewardWeight;
        tokens[tokenAddress].reserveRatioNumerator = reserveRatioNumerator;
        tokens[tokenAddress]
            .targetLiquidityRatioNumerator = targetLiquidityRatioNumerator;
        tokens[tokenAddress]
            .transferFeeKValueNumerator = transferFeeKValueNumerator;
        tokens[tokenAddress]
            .transferFeePlatformRatioNumerator = transferFeePlatformRatioNumerator;
        tokenAddresses.push(tokenAddress);
    }

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio

    function addToken(
        address tokenAddress,
        bool acceptingDeposits,
        bool acceptingWithdrawals,
        bool acceptingLping,
        bool acceptingBridging,
        uint256 biosRewardWeight,
        uint256 reserveRatioNumerator,
        uint256 targetLiquidityRatioNumerator,
        uint256 transferFeeKValueNumerator,
        uint256 transferFeePlatformRatioNumerator
    ) external override onlyController {
        _addToken(
            tokenAddress,
            acceptingDeposits,
            acceptingWithdrawals,
            acceptingLping,
            acceptingBridging,
            biosRewardWeight,
            reserveRatioNumerator,
            targetLiquidityRatioNumerator,
            transferFeeKValueNumerator,
            transferFeePlatformRatioNumerator
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenDeposits(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::enableTokenDeposits: Token does not exist"
        );
        require(
            !tokens[tokenAddress].acceptingDeposits,
            "IntegrationMap::enableTokenDeposits: Token already accepting deposits"
        );

        tokens[tokenAddress].acceptingDeposits = true;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.deposit,
            true
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenDeposits(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::disableTokenDeposits: Token does not exist"
        );
        require(
            tokens[tokenAddress].acceptingDeposits,
            "IntegrationMap::disableTokenDeposits: Token deposits already disabled"
        );

        tokens[tokenAddress].acceptingDeposits = false;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.deposit,
            false
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenWithdrawals(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::enableTokenWithdrawals: Token does not exist"
        );
        require(
            !tokens[tokenAddress].acceptingWithdrawals,
            "IntegrationMap::enableTokenWithdrawals: Token already accepting withdrawals"
        );

        tokens[tokenAddress].acceptingWithdrawals = true;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.withdraw,
            true
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenWithdrawals(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::disableTokenWithdrawals: Token does not exist"
        );
        require(
            tokens[tokenAddress].acceptingWithdrawals,
            "IntegrationMap::disableTokenWithdrawals: Token withdrawals already disabled"
        );

        tokens[tokenAddress].acceptingWithdrawals = false;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.withdraw,
            false
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenLping(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::enableTokenLping: Token does not exist"
        );
        require(
            !tokens[tokenAddress].acceptingLping,
            "IntegrationMap::enableTokenLping: Token already accepting LPing"
        );

        tokens[tokenAddress].acceptingLping = true;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.lp,
            true
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenLping(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::disableTokenLping: Token does not exist"
        );
        require(
            tokens[tokenAddress].acceptingLping,
            "IntegrationMap::disableTokenLping: Token LPing already disabled"
        );

        tokens[tokenAddress].acceptingLping = false;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.lp,
            false
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenBridging(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::enableTokenBridging: Token does not exist"
        );
        require(
            !tokens[tokenAddress].acceptingBridging,
            "IntegrationMap::enableTokenBridging: Token already accepting bridging"
        );

        tokens[tokenAddress].acceptingBridging = true;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.bridge,
            true
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenBridging(address tokenAddress)
        external
        override
        onlyManager
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::disableTokenBridging: Token does not exist"
        );
        require(
            tokens[tokenAddress].acceptingBridging,
            "IntegrationMap::disableTokenBridging: Token bridging already disabled"
        );

        tokens[tokenAddress].acceptingBridging = false;
        emit TokenSettingToggled(
            tokenAddress,
            TokenSettings.TokenSettingName.bridge,
            false
        );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @param rewardWeight The updated token BIOS reward weight
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight)
        external
        override
        onlyController
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::updateTokenRewardWeight: Token does not exist"
        );

        tokens[tokenAddress].biosRewardWeight = rewardWeight;
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(
        address tokenAddress,
        uint256 reserveRatioNumerator
    ) external override onlyController {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::updateTokenReserveRatioNumerator: Token does not exist"
        );
        require(
            reserveRatioNumerator <= RESERVE_RATIO_DENOMINATOR,
            "IntegrationMap::updateTokenReserveRatioNumerator: reserveRatioNumerator must be less than or equal to reserve ratio denominator"
        );

        tokens[tokenAddress].reserveRatioNumerator = reserveRatioNumerator;
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param targetLiquidityRatioNumerator Number that gets divided by target liquidity ratio denominator to get target liquidity ratio
    function updateTokenTargetLiquidityRatioNumerator(
        address tokenAddress,
        uint256 targetLiquidityRatioNumerator
    ) external override onlyController {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::updateTokenTargetLiquidityRatioNumerator: Token does not exist"
        );
        require(
            targetLiquidityRatioNumerator <= TARGET_LIQUIDITY_RATIO_DENOMINATOR,
            "IntegrationMap::updateTokenTargetLiquidityRatioNumerator: targetLiquidityRatioNumerator must be less than or equal to target liquidity ratio denominator"
        );

        tokens[tokenAddress]
            .targetLiquidityRatioNumerator = targetLiquidityRatioNumerator;
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param transferFeeKValueNumerator Number that gets divided by transfer fee K-value denominator to get K-value
    function updateTokenTransferFeeKValueNumerator(
        address tokenAddress,
        uint256 transferFeeKValueNumerator
    ) external override onlyController {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::updateTokenTransferFeeKValueNumerator: Token does not exist"
        );
        require(
            transferFeeKValueNumerator <= TRANSFER_FEE_K_VALUE_DENOMINATOR,
            "IntegrationMap::updateTokenTransferFeeKValueNumerator: transferFeeKValueNumerator must be less than or equal to transfer fee K-value denominator"
        );

        tokens[tokenAddress]
            .transferFeeKValueNumerator = transferFeeKValueNumerator;
    }

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param transferFeePlatformRatioNumerator Number that gets divided by transfer fee platform ratio denominator to get the ratio of transfer fees sent to the platform instead of LPers
    function updateTokenTransferFeePlatformRatioNumerator(
        address tokenAddress,
        uint256 transferFeePlatformRatioNumerator
    ) external override onlyController {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::updateTokenTransferFeePlatformRatioNumerator: Token does not exist"
        );
        require(
            transferFeePlatformRatioNumerator <=
                TRANSFER_FEE_PLATFORM_RATIO_DENOMINATOR,
            "IntegrationMap::updateTokenTransferFeePlatformRatioNumerator: transferFeePlatformRatioNumerator must be less than or equal to transfer fee platform ratio denominator"
        );

        tokens[tokenAddress]
            .transferFeePlatformRatioNumerator = transferFeePlatformRatioNumerator;
    }

    /// @param integrationId The ID of the integration
    /// @return The address of the integration contract
    function getIntegrationAddress(uint256 integrationId)
        external
        view
        override
        returns (address)
    {
        require(
            integrationId < integrationAddresses.length,
            "IntegrationMap::getIntegrationAddress: Integration does not exist"
        );

        return integrationAddresses[integrationId];
    }

    /// @param integrationAddress The address of the integration contract
    /// @return The name of the of the protocol being integrated to
    function getIntegrationName(address integrationAddress)
        external
        view
        override
        returns (string memory)
    {
        require(
            integrations[integrationAddress].added,
            "IntegrationMap::getIntegrationName: Integration does not exist"
        );

        return integrations[integrationAddress].name;
    }

    /// @return The address of the WETH token
    function getWethTokenAddress() external view override returns (address) {
        return wethTokenAddress;
    }

    /// @return The address of the BIOS token
    function getBiosTokenAddress() external view override returns (address) {
        return biosTokenAddress;
    }

    /// @param tokenId The ID of the token
    /// @return The address of the token ERC20 contract
    function getTokenAddress(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        require(
            tokenId < tokenAddresses.length,
            "IntegrationMap::getTokenAddress: Token does not exist"
        );
        return (tokenAddresses[tokenId]);
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The index of the token in the tokens array
    function getTokenId(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenId: Token does not exist"
        );
        return (tokens[tokenAddress].id);
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The token BIOS reward weight
    function getTokenBiosRewardWeight(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenBiosRewardWeight: Token does not exist"
        );
        return (tokens[tokenAddress].biosRewardWeight);
    }

    /// @return rewardWeightSum reward weight of depositable tokens
    function getBiosRewardWeightSum()
        external
        view
        override
        returns (uint256 rewardWeightSum)
    {
        for (uint256 tokenId; tokenId < tokenAddresses.length; tokenId++) {
            rewardWeightSum += tokens[tokenAddresses[tokenId]].biosRewardWeight;
        }
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether depositing this token is currently enabled
    function getTokenAcceptingDeposits(address tokenAddress)
        external
        view
        override
        returns (bool)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenAcceptingDeposits: Token does not exist"
        );
        return tokens[tokenAddress].acceptingDeposits;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether withdrawing this token is currently enabled
    function getTokenAcceptingWithdrawals(address tokenAddress)
        external
        view
        override
        returns (bool)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenAcceptingWithdrawals: Token does not exist"
        );
        return tokens[tokenAddress].acceptingWithdrawals;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether Lping this token is currently enabled
    function getTokenAcceptingLping(address tokenAddress)
        external
        view
        override
        returns (bool)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenAcceptingLping: Token does not exist"
        );
        return tokens[tokenAddress].acceptingLping;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether Lping this token is currently enabled
    function getTokenAcceptingBridging(address tokenAddress)
        external
        view
        override
        returns (bool)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenAcceptingBridging: Token does not exist"
        );
        return tokens[tokenAddress].acceptingBridging;
    }

    // @param tokenAddress The address of the token ERC20 contract
    // @return bool indicating whether the token has been added
    function getIsTokenAdded(address tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return tokens[tokenAddress].added;
    }

    // @param integrationAddress The address of the integration contract
    // @return bool indicating whether the integration has been added
    function getIsIntegrationAdded(address integrationAddress)
        external
        view
        override
        returns (bool)
    {
        return integrations[integrationAddress].added;
    }

    /// @notice Gets the length of supported tokens
    /// @return The quantity of tokens added
    function getTokenAddressesLength()
        external
        view
        override
        returns (uint256)
    {
        return tokenAddresses.length;
    }

    /// @notice Gets the length of supported integrations
    /// @return The quantity of Integrations added
    function getIntegrationAddressesLength()
        external
        view
        override
        returns (uint256)
    {
        return integrationAddresses.length;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The token reserve ratio numerator
    function getTokenReserveRatioNumerator(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenReserveRatioNumerator: Token does not exist"
        );
        return tokens[tokenAddress].reserveRatioNumerator;
    }

    /// @return The token reserve ratio denominator
    function getReserveRatioDenominator()
        external
        pure
        override
        returns (uint32)
    {
        return RESERVE_RATIO_DENOMINATOR;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The number that gets divided by target liquidity ratio denominator
    function getTokenTargetLiquidityRatioNumerator(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenTargetLiquidityRatioNumerator: Token does not exist"
        );
        return tokens[tokenAddress].targetLiquidityRatioNumerator;
    }

    /// @return The target liquidity ratio denominator
    function getTargetLiquidityRatioDenominator()
        external
        pure
        override
        returns (uint32)
    {
        return TARGET_LIQUIDITY_RATIO_DENOMINATOR;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The number that gets divided by transfer fee K-value denominator
    function getTokenTransferFeeKValueNumerator(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenTransferFeeKValueNumerator: Token does not exist"
        );
        return tokens[tokenAddress].transferFeeKValueNumerator;
    }

    /// @return The transfer fee K-value denominator
    function getTransferFeeKValueDenominator()
        external
        pure
        override
        returns (uint32)
    {
        return TRANSFER_FEE_K_VALUE_DENOMINATOR;
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The number that gets divided by transfer fee platform ratio denominator
    function getTokenTransferFeePlatformRatioNumerator(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        require(
            tokens[tokenAddress].added,
            "IntegrationMap::getTokenTransferFeePlatformRatioNumerator: Token does not exist"
        );
        return tokens[tokenAddress].transferFeePlatformRatioNumerator;
    }

    /// @return The transfer fee platform ratio denominator
    function getTransferFeePlatformRatioDenominator()
        external
        pure
        override
        returns (uint32)
    {
        return TRANSFER_FEE_PLATFORM_RATIO_DENOMINATOR;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "../interfaces/IEtherRewards.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

contract EtherRewards is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IEtherRewards
{
    /// @param controllers_ The array of controllers for this contract
    /// @param moduleMap_ The address of the ModuleMap contract
    function initialize(address[] memory controllers_, address moduleMap_)
        public
        initializer
    {
        __Controlled_init(controllers_, moduleMap_);
    }

    uint256 private totalEthRewards;
    uint256 private totalClaimedEthRewards;
    mapping(address => uint256) private totalUserClaimedEthRewards;
    mapping(address => uint256) private tokenRewardRate;
    mapping(address => uint256) private tokenEthRewards;
    mapping(address => mapping(address => uint256)) private userTokenRewardRate;
    mapping(address => mapping(address => uint256))
        private userTokenAccumulatedRewards;

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    function updateUserRewards(address token, address user)
        public
        override
        onlyController
    {
        uint256 userTokenDeposits = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        ).getUserInvestedAmountByToken(token, user);

        userTokenAccumulatedRewards[token][user] +=
            ((tokenRewardRate[token] - userTokenRewardRate[token][user]) *
                userTokenDeposits) /
            10**18;

        userTokenRewardRate[token][user] = tokenRewardRate[token];
    }

    /// @param token The address of the token ERC20 contract
    /// @param ethRewardsAmount The amount of Ether rewards to add
    function increaseEthRewards(address token, uint256 ethRewardsAmount)
        external
        override
        onlyController
    {
        uint256 tokenTotalDeposits = IStrategyMap(
            moduleMap.getModuleAddress(Modules.StrategyMap)
        ).getTokenTotalBalance(token);
        require(
            tokenTotalDeposits > 0,
            "EtherRewards::increaseEthRewards: Token has not been deposited yet"
        );

        totalEthRewards += ethRewardsAmount;
        tokenEthRewards[token] += ethRewardsAmount;
        tokenRewardRate[token] +=
            (ethRewardsAmount * 10**18) /
            tokenTotalDeposits;
    }

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimEthRewards(address user)
        external
        override
        onlyController
        returns (uint256 ethRewards)
    {
        address integrationMap = moduleMap.getModuleAddress(
            Modules.IntegrationMap
        );
        uint256 tokenCount = IIntegrationMap(integrationMap)
            .getTokenAddressesLength();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address token = IIntegrationMap(integrationMap).getTokenAddress(
                tokenId
            );
            ethRewards += claimTokenEthRewards(token, user);
        }
    }

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimTokenEthRewards(address token, address user)
        private
        returns (uint256 ethRewards)
    {
        updateUserRewards(token, user);
        ethRewards = userTokenAccumulatedRewards[token][user];

        userTokenAccumulatedRewards[token][user] = 0;
        tokenEthRewards[token] -= ethRewards;
        totalEthRewards -= ethRewards;
        totalClaimedEthRewards += ethRewards;
        totalUserClaimedEthRewards[user] += ethRewards;
    }

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserTokenEthRewards(address token, address user)
        public
        view
        override
        returns (uint256 ethRewards)
    {
        uint256 userTokenDeposits = IUserPositions(
            moduleMap.getModuleAddress(Modules.UserPositions)
        ).getUserInvestedAmountByToken(token, user);

        ethRewards =
            userTokenAccumulatedRewards[token][user] +
            ((tokenRewardRate[token] - userTokenRewardRate[token][user]) *
                userTokenDeposits) /
            10**18;
    }

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserEthRewards(address user)
        external
        view
        override
        returns (uint256 ethRewards)
    {
        address integrationMap = moduleMap.getModuleAddress(
            Modules.IntegrationMap
        );
        uint256 tokenCount = IIntegrationMap(integrationMap)
            .getTokenAddressesLength();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address token = IIntegrationMap(integrationMap).getTokenAddress(
                tokenId
            );
            ethRewards += getUserTokenEthRewards(token, user);
        }
    }

    /// @param token The address of the token ERC20 contract
    /// @return The amount of Ether rewards for the specified token
    function getTokenEthRewards(address token)
        external
        view
        override
        returns (uint256)
    {
        return tokenEthRewards[token];
    }

    /// @return The total value of ETH claimed by users
    function getTotalClaimedEthRewards()
        external
        view
        override
        returns (uint256)
    {
        return totalClaimedEthRewards;
    }

    /// @return The total value of ETH claimed by a user
    function getTotalUserClaimedEthRewards(address account)
        external
        view
        override
        returns (uint256)
    {
        return totalUserClaimedEthRewards[account];
    }

    /// @return The total amount of Ether rewards
    function getEthRewards() external view override returns (uint256) {
        return totalEthRewards;
    }
}