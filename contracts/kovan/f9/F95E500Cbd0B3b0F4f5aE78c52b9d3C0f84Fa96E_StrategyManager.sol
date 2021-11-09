// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IIntegrationMap {
    struct Integration {
        bool added;
        string name;
    }

    struct Token {
        uint256 id;
        bool added;
        bool acceptingDeposits;
        bool acceptingWithdrawals;
        uint256 biosRewardWeight;
        uint256 reserveRatioNumerator;
    }

    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    function addIntegration(address contractAddress, string memory name)
        external;

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function addToken(
        address tokenAddress,
        bool acceptingDeposits,
        bool acceptingWithdrawals,
        uint256 biosRewardWeight,
        uint256 reserveRatioNumerator
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
    /// @param rewardWeight The updated token BIOS reward weight
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight)
        external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(
        address tokenAddress,
        uint256 reserveRatioNumerator
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
    /// @return The value that gets divided by the reserve ratio denominator
    function getTokenReserveRatioNumerator(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return The token reserve ratio denominator
    function getReserveRatioDenominator() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IKernel {
    /// @param account The address of the account to check if they are a manager
    /// @return Bool indicating whether the account is a manger
    function isManager(address account) external view returns (bool);

    /// @param account The address of the account to check if they are an owner
    /// @return Bool indicating whether the account is an owner
    function isOwner(address account) external view returns (bool);
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
    StrategyManager // 9
}

interface IModuleMap {
    function getModuleAddress(Modules key) external view returns (address);
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

    /// @param biosRewardsDuration_ The duration in seconds for a BIOS rewards period to last
    function setBiosRewardsDuration(uint32 biosRewardsDuration_) external;

    /// @param sender The account seeding BIOS rewards
    /// @param biosAmount The amount of BIOS to add to rewards
    function seedBiosRewards(address sender, uint256 biosAmount) external;

    /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
    function increaseBiosRewards() external;

    /// @notice User is allowed to deposit whitelisted tokens
    /// @param depositor Address of the account depositing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param ethAmount The amount of ETH sent with the deposit
    function deposit(
        address depositor,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 ethAmount
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

    /// @notice Allows users to claim their BIOS rewards for each token
    /// @param recipient The address of the usuer claiming BIOS rewards
    function claimBiosRewards(address recipient)
        external
        returns (uint256 biosClaimed);

    /// @param asset Address of the ERC20 token contract
    /// @return The total balance of the asset deposited in the system
    function totalTokenBalance(address asset) external view returns (uint256);

    /// @notice Returns the amount that a user has deposited, but that isn't in a strategy
    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userTokenBalance(address asset, address account)
        external
        view
        returns (uint256);

    /// @return The Bios Rewards Duration
    function getBiosRewardsDuration() external view returns (uint32);

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

    function transferClosedPositionsValue(address token, uint256 amount)
        external;
}