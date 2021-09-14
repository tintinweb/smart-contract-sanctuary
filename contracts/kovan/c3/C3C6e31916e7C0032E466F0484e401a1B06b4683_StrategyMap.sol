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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IKernel.sol";

abstract contract Controlled is 
    Initializable,
    ModuleMapConsumer
{
    address[] public controllers;

    function __Controlled_init(address[] memory controllers_, address moduleMap_) public initializer {
        controllers = controllers_;
        __ModuleMapConsumer_init(moduleMap_);
    }

    function addController(address controller) external onlyOwner {
        bool controllerAdded;
        for(uint256 i; i < controllers.length; i++) {
            if(controller == controllers[i]) {
                controllerAdded = true;
            }
        }
        require(!controllerAdded, "Controlled::addController: Address is already a controller");
        controllers.push(controller);
    }

    modifier onlyOwner() {
        require(IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isOwner(msg.sender), "Controlled::onlyOwner: Caller is not owner");
        _;
    }

    modifier onlyManager() {
        require(IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isManager(msg.sender), "Controlled::onlyManager: Caller is not manager");
        _;
    }

    modifier onlyController() {
        bool senderIsController;
        for(uint256 i; i < controllers.length; i++) {
            if(msg.sender == controllers[i]) {
                senderIsController = true;
                break;
            }
        }
        require(senderIsController, "Controlled::onlyController: Caller is not controller");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IModuleMap.sol";

abstract contract ModuleMapConsumer is Initializable {
    IModuleMap public moduleMap;

    function __ModuleMapConsumer_init(address moduleMap_) internal initializer {
        moduleMap = IModuleMap(moduleMap_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "../interfaces/IStrategyMap.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IYieldManager.sol";

contract StrategyMap is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IStrategyMap
{
  // #### Global State
  // Strategy id => Strategy
  mapping(uint256 => Strategy) internal strategies;

  // Strategy => token => balance
  mapping(uint256 => mapping(address => uint256)) internal strategyBalances;

  // User => strategy => token => balance
  mapping(address => mapping(uint256 => mapping(address => uint256)))
    internal userStrategyBalances;

  // User => token => balance
  mapping(address => mapping(address => uint256)) internal userInvestedBalances;

  // Token => balance
  mapping(address => uint256) internal totalBalances;

  // Integration => token => gross balance inclusive of reserve amount
  mapping(address => mapping(address => uint256)) internal integrationBalances;

  // Integration => weight
  mapping(address => uint256) internal integrationWeights;
  uint256 internal totalSystemWeight;

  uint256 internal idCounter;

  // #### Functions
  function initialize(address[] memory controllers_, address moduleMap_)
    public
    initializer
  {
    __Controlled_init(controllers_, moduleMap_);
  }

  function addStrategy(
    string calldata name,
    WeightedIntegration[] memory integrations
  ) external override onlyController {
    require(bytes(name).length > 0, "Must have a name");
    require(integrations.length > 0, "Must have >= 1 integration");

    idCounter++;
    uint256 strategyID = idCounter;
    strategies[strategyID].name = name;

    uint256 totalStrategyWeight = 0;
    uint256 _systemWeight = totalSystemWeight;
    for (uint256 i = 0; i < integrations.length; i++) {
      if (integrations[i].weight > 0) {
        _systemWeight += integrations[i].weight;
        integrationWeights[integrations[i].integration] += integrations[i]
          .weight;
        strategies[strategyID].integrations.push(integrations[i]);
        totalStrategyWeight += integrations[i].weight;
      }
    }
    totalSystemWeight = _systemWeight;
    strategies[strategyID].totalStrategyWeight = totalStrategyWeight;

    emit NewStrategy(strategyID, name, integrations);
  }

  function updateName(uint256 id, string calldata name)
    external
    override
    onlyController
  {
    require(bytes(name).length > 0, "Must have a name");
    Strategy memory currentStrategy = strategies[id];
    require(
      currentStrategy.integrations.length > 0 &&
        bytes(currentStrategy.name).length > 0,
      "Strategy must exist"
    );
    strategies[id].name = name;
    emit UpdateName(id, name);
  }

  function updateIntegrations(
    uint256 id,
    WeightedIntegration[] memory integrations
  ) external override onlyController {
    Strategy memory currentStrategy = strategies[id];
    require(
      currentStrategy.integrations.length > 0 &&
        bytes(currentStrategy.name).length > 0,
      "Strategy must exist"
    );

    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    WeightedIntegration[] memory currentIntegrations = strategies[id]
      .integrations;

    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    uint256 _systemWeight = totalSystemWeight;
    for (uint256 i = 0; i < currentIntegrations.length; i++) {
      _systemWeight -= currentIntegrations[i].weight;
      integrationWeights[
        currentIntegrations[i].integration
      ] -= currentIntegrations[i].weight;
    }
    delete strategies[id].integrations;

    uint256 newStrategyTotalWeight;
    for (uint256 i = 0; i < integrations.length; i++) {
      if (integrations[i].weight > 0) {
        newStrategyTotalWeight += integrations[i].weight;
        strategies[id].integrations.push(integrations[i]);
        _systemWeight += integrations[i].weight;
        integrationWeights[integrations[i].integration] += integrations[i]
          .weight;
      }
    }

    totalSystemWeight = _systemWeight;
    strategies[id].totalStrategyWeight = newStrategyTotalWeight;

    for (uint256 i = 0; i < tokenCount; i++) {
      address token = integrationMap.getTokenAddress(i);
      if (strategyBalances[id][token] > 0) {
        for (uint256 j = 0; j < currentIntegrations.length; j++) {
          // Remove token amounts from integration balances

          integrationBalances[currentIntegrations[j].integration][
            token
          ] -= _calculateIntegrationAllocation(
            strategyBalances[id][token],
            currentIntegrations[j].weight,
            currentStrategy.totalStrategyWeight
          );
        }
        for (uint256 j = 0; j < integrations.length; j++) {
          if (integrations[j].weight > 0) {
            // Add new token balances
            integrationBalances[integrations[j].integration][
              token
            ] += _calculateIntegrationAllocation(
              strategyBalances[id][token],
              integrations[j].weight,
              newStrategyTotalWeight
            );
          }
        }
      }
    }

    emit UpdateIntegrations(id, integrations);
  }

  function deleteStrategy(uint256 id) external override onlyController {
    Strategy memory currentStrategy = strategies[id];
    // Checks
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 i = 0; i < tokenCount; i++) {
      require(
        getStrategyTokenBalance(id, integrationMap.getTokenAddress(i)) == 0,
        "Strategy in use"
      );
    }
    uint256 _systemWeight = totalSystemWeight;
    for (uint256 i = 0; i < currentStrategy.integrations.length; i++) {
      _systemWeight -= currentStrategy.integrations[i].weight;
      integrationWeights[
        currentStrategy.integrations[i].integration
      ] -= currentStrategy.integrations[i].weight;
    }
    totalSystemWeight = _systemWeight;

    delete strategies[id];

    emit DeleteStrategy(id, currentStrategy.name, currentStrategy.integrations);
  }

  function _deposit(
    uint256 id,
    address user,
    StrategyTransaction memory deposits
  ) internal {
    Strategy memory strategy = strategies[id];
    require(strategy.integrations.length > 0, "Strategy doesn't exist");

    strategyBalances[id][deposits.token] += deposits.amount;
    userInvestedBalances[user][deposits.token] += deposits.amount;
    userStrategyBalances[user][id][deposits.token] += deposits.amount;
    totalBalances[deposits.token] += deposits.amount;

    for (uint256 j = 0; j < strategy.integrations.length; j++) {
      integrationBalances[strategy.integrations[j].integration][
        deposits.token
      ] += _calculateIntegrationAllocation(
        deposits.amount,
        strategy.integrations[j].weight,
        strategy.totalStrategyWeight
      );
    }
  }

  function _withdraw(
    uint256 id,
    address user,
    StrategyTransaction memory withdrawals
  ) internal {
    Strategy memory strategy = strategies[id];
    require(strategy.integrations.length > 0, "Strategy doesn't exist");

    strategyBalances[id][withdrawals.token] -= withdrawals.amount;
    userInvestedBalances[user][withdrawals.token] -= withdrawals.amount;
    userStrategyBalances[user][id][withdrawals.token] -= withdrawals.amount;
    totalBalances[withdrawals.token] -= withdrawals.amount;

    for (uint256 j = 0; j < strategy.integrations.length; j++) {
      integrationBalances[strategy.integrations[j].integration][
        withdrawals.token
      ] -= _calculateIntegrationAllocation(
        withdrawals.amount,
        strategy.integrations[j].weight,
        strategy.totalStrategyWeight
      );
    }
  }

  function enterStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external override onlyController {
    require(amounts.length == tokens.length, "Length mismatch");
    require(strategies[id].integrations.length > 0, "Strategy must exist");
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );

    IUserPositions userPositions = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    );
    for (uint256 i = 0; i < tokens.length; i++) {
      require(amounts[i] > 0, "Amount is 0");
      require(
        integrationMap.getTokenAcceptingDeposits(tokens[i]),
        "Token unavailable"
      );

      // Check that a user has enough funds on deposit
      require(
        userPositions.userTokenBalance(tokens[i], user) >= amounts[i],
        "User lacks funds"
      );
      _deposit(
        id,
        user,
        IStrategyMap.StrategyTransaction(amounts[i], tokens[i])
      );
    }

    emit EnterStrategy(id, user, tokens, amounts);
  }

  function exitStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external override onlyController {
    require(amounts.length == tokens.length, "Length mismatch");
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );

    for (uint256 i = 0; i < tokens.length; i++) {
      require(
        getUserInvestedAmountByToken(tokens[i], user) >= amounts[i],
        "Insufficient Funds"
      );

      require(
        integrationMap.getTokenAcceptingWithdrawals(tokens[i]),
        "Token unavailable"
      );
      // require(
      //   IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      //     .getReserveTokenBalance(tokens[i]) >= amounts[i],
      //   "Insufficient reserves"
      // );
      require(amounts[i] > 0, "Amount is 0");

      _withdraw(
        id,
        user,
        IStrategyMap.StrategyTransaction(amounts[i], tokens[i])
      );
    }

    emit ExitStrategy(id, user, tokens, amounts);
  }

  /**
    @notice Calculates the amount of tokens to adjust an integration's expected invested amount by
    @param totalDepositedAmount  the total amount a user is depositing or withdrawing from a strategy
    @param integrationWeight  the weight of the integration as part of the strategy
    @param strategyWeight  the sum of all weights in the strategy
    @return amount  the amount to adjust the integration balance by
     */
  function _calculateIntegrationAllocation(
    uint256 totalDepositedAmount,
    uint256 integrationWeight,
    uint256 strategyWeight
  ) internal pure returns (uint256 amount) {
    return (totalDepositedAmount * integrationWeight) / strategyWeight;
  }

  function getStrategyTokenBalance(uint256 id, address token)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = strategyBalances[id][token];
  }

  function getUserStrategyBalanceByToken(
    uint256 id,
    address token,
    address user
  ) public view override returns (uint256 amount) {
    amount = userStrategyBalances[user][id][token];
  }

  function getUserInvestedAmountByToken(address token, address user)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = userInvestedBalances[user][token];
  }

  function getTokenTotalBalance(address token)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = totalBalances[token];
  }

  function getStrategy(uint256 id)
    external
    view
    override
    returns (Strategy memory)
  {
    return strategies[id];
  }

  function getExpectedBalance(address integration, address token)
    external
    view
    override
    returns (uint256 balance)
  {
    return integrationBalances[integration][token];
  }

  function getIntegrationWeight(address integration)
    external
    view
    override
    returns (uint256)
  {
    return integrationWeights[integration];
  }

  function getIntegrationWeightSum() external view override returns (uint256) {
    return totalSystemWeight;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IIntegration {
    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(address tokenAddress, uint256 amount) external;

    /// @param tokenAddress The address of the withdrawal token
    /// @param amount The amount of the token to withdraw
    function withdraw(address tokenAddress, uint256 amount) external;

    /// @dev Deploys all tokens held in the integration contract to the integrated protocol
    function deploy() external;

    /// @dev Harvests token yield from the Aave lending pool
    function harvestYield() external;

    /// @dev This returns the total amount of the underlying token that
    /// @dev has been deposited to the integration contract
    /// @param tokenAddress The address of the deployed token
    /// @return The amount of the underlying token that can be withdrawn
    function getBalance(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    function addIntegration(address contractAddress, string memory name) external;

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
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight) external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(address tokenAddress, uint256 reserveRatioNumerator) external;

    /// @param integrationId The ID of the integration
    /// @return The address of the integration contract
    function getIntegrationAddress(uint256 integrationId) external view returns (address);

    /// @param integrationAddress The address of the integration contract
    /// @return The name of the of the protocol being integrated to
    function getIntegrationName(address integrationAddress) external view returns (string memory);

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
    function getTokenBiosRewardWeight(address tokenAddress) external view returns (uint256);

    /// @return rewardWeightSum reward weight of depositable tokens
    function getBiosRewardWeightSum() external view returns (uint256 rewardWeightSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether depositing this token is currently enabled
    function getTokenAcceptingDeposits(address tokenAddress) external view returns (bool);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether withdrawing this token is currently enabled
    function getTokenAcceptingWithdrawals(address tokenAddress) external view returns (bool);

    // @param tokenAddress The address of the token ERC20 contract
    // @return bool indicating whether the token has been added
    function getIsTokenAdded(address tokenAddress) external view returns (bool);

    // @param integrationAddress The address of the integration contract
    // @return bool indicating whether the integration has been added
    function getIsIntegrationAdded(address tokenAddress) external view returns (bool);

    /// @notice get the length of supported tokens
    /// @return The quantity of tokens added
    function getTokenAddressesLength() external view returns (uint256);

    /// @notice get the length of supported integrations
    /// @return The quantity of integrations added
    function getIntegrationAddressesLength() external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The value that gets divided by the reserve ratio denominator
    function getTokenReserveRatioNumerator(address tokenAddress) external view returns (uint256);

    /// @return The token reserve ratio denominator
    function getReserveRatioDenominator() external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IKernel {




    /// @param account The address of the account to check if they are a manager
    /// @return Bool indicating whether the account is a manger
    function isManager(address account) external view returns (bool);

    /// @param account The address of the account to check if they are an owner
    /// @return Bool indicating whether the account is an owner
    function isOwner(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../interfaces/IIntegration.sol";

interface IStrategyMap {
  // #### Structs
  struct WeightedIntegration {
    address integration;
    uint256 weight;
  }

  struct Strategy {
    string name;
    uint256 totalStrategyWeight;
    WeightedIntegration[] integrations;
  }

  struct StrategyTransaction {
    uint256 amount;
    address token;
  }

  // #### Events
  event NewStrategy(
    uint256 indexed id,
    string name,
    WeightedIntegration[] integrations
  );
  event UpdateName(uint256 indexed id, string name);
  event UpdateIntegrations(
    uint256 indexed id,
    WeightedIntegration[] integrations
  );
  event DeleteStrategy(
    uint256 indexed id,
    string name,
    WeightedIntegration[] integrations
  );

  event EnterStrategy(
    uint256 indexed id,
    address indexed user,
    address[] tokens,
    uint256[] amounts
  );
  event ExitStrategy(
    uint256 indexed id,
    address indexed user,
    address[] tokens,
    uint256[] amounts
  );

  // #### Functions
  /**
     @notice Adds a new strategy to the list of available strategies
     @param name  the name of the new strategy
     @param integrations  the integrations and weights that form the strategy
     */
  function addStrategy(
    string calldata name,
    WeightedIntegration[] memory integrations
  ) external;

  /**
    @notice Updates the strategy name
    @param name  the new name
     */
  function updateName(uint256 id, string calldata name) external;

  /**
    @notice Updates the strategy integrations 
    @param integrations  the new integrations
     */
  function updateIntegrations(
    uint256 id,
    WeightedIntegration[] memory integrations
  ) external;

  /**
    @notice Deletes a strategy
    @dev This can only be called successfully if the strategy being deleted doesn't have any assets invested in it
    @param id  the strategy to delete
     */
  function deleteStrategy(uint256 id) external;

  /**
    @notice Increases the amount of a set of tokens in a strategy
    @param id  the strategy to deposit into
    @param tokens  the tokens to deposit
    @param amounts  The amounts to be deposited
     */
  function enterStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external;

  /**
    @notice Decreases the amount of a set of tokens invested in a strategy
    @param id  the strategy to withdraw assets from
    @param tokens  the tokens to withdraw
    @param amounts  The amounts to be withdrawn
     */
  function exitStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external;

  /**
    @notice Getter function to return the nested arrays as well as the name
    @param id  the strategy to return
     */
  function getStrategy(uint256 id) external view returns (Strategy memory);

  /**
    @notice Returns the expected balance of a given token in a given integration
    @param integration  the integration the amount should be invested in
    @param token  the token that is being invested
    @return balance  the balance of the token that should be currently invested in the integration 
     */
  function getExpectedBalance(address integration, address token)
    external
    view
    returns (uint256 balance);

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
    @notice Returns the total amount of a token invested across all strategies
    @param token  the token to fetch the balance for
    @return amount  the amount of the token currently invested
    */
  function getTokenTotalBalance(address token)
    external
    view
    returns (uint256 amount);

  /**
  @notice Returns the weight of an individual integration within the system
  @param integration  the integration to look up
  @return The weight of the integration
   */
  function getIntegrationWeight(address integration)
    external
    view
    returns (uint256);

  /**
  @notice Returns the sum of all weights in the system.
  @return The sum of all integration weights within the system
   */
  function getIntegrationWeightSum() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserPositions {
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
  function claimEthRewards(address user) external returns (uint256 ethClaimed);

  /// @notice Allows users to claim their BIOS rewards for each token
  /// @param recipient The address of the usuer claiming BIOS rewards
  function claimBiosRewards(address recipient)
    external
    returns (uint256 biosClaimed);

  /// @param asset Address of the ERC20 token contract
  /// @return The total balance of the asset deposited in the system
  function totalTokenBalance(address asset) external view returns (uint256);

  /// @param asset Address of the ERC20 token contract
  /// @param account Address of the user account
  function userTokenBalance(address asset, address account)
    external
    view
    returns (uint256);

  /// @return The Bios Rewards Duration
  function getBiosRewardsDuration() external view returns (uint32);

  /// @notice Transfers tokens to the StrategyMap
  /// @dev This is a ledger adjustment. The tokens remain in the kernel.
  /// @param recipient  The user to transfer funds for
  /// @param tokens  the tokens to be moved
  /// @param amounts  the amounts of each token to move
  function transferToStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external;

  /// @notice Transfers tokens from the StrategyMap
  /// @dev This is a ledger adjustment. The tokens remain in the kernel.
  /// @param recipient  The user to transfer funds for
  /// @param tokens  the tokens to be moved
  /// @param amounts  the amounts of each token to move
  function transferFromStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IYieldManager {
    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    function updateGasAccountTargetEthBalance(uint256 gasAccountTargetEthBalance_) external;

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

    /// @notice Withdraws and then re-deploys tokens to integrations according to configured weights
    function rebalance() external;

    /// @notice Deploys all tokens to all integrations according to configured weights
    function deploy() external;

    /// @notice Harvests available yield from all tokens and integrations
    function harvestYield() external;

    /// @notice Swaps harvested yield for all tokens for ETH
    function processYield() external;

    /// @notice Distributes ETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
    function distributeEth() external;

    /// @notice Uses WETH to buy back BIOS which is sent to the Kernel
    function biosBuyBack() external;

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return harvestedTokenBalance The amount of the token yield harvested held in the Kernel
    function getHarvestedTokenBalance(address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of the token held in the Kernel as reserves
    function getReserveTokenBalance(address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The desired amount of the token to hold in the Kernel as reserves
    function getDesiredReserveTokenBalance(address tokenAddress) external view returns (uint256);

    /// @return ethWeightSum The sum of ETH distribution weights
    function getEthWeightSum() external view returns (uint32 ethWeightSum);

    /// @return processedWethSum The sum of yields processed into WETH
    function getProcessedWethSum() external view returns (uint256 processedWethSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of WETH received from token yield processing
    function getProcessedWethByToken(address tokenAddress) external view returns (uint256);

    /// @return processedWethByTokenSum The sum of processed WETH
    function getProcessedWethByTokenSum() external view returns (uint256 processedWethByTokenSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenTotalIntegrationBalance The total amount of the token that can be withdrawn from integrations
    function getTokenTotalIntegrationBalance(address tokenAddress) external view returns (uint256 tokenTotalIntegrationBalance);

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
    function getEthDistributionWeights() external view returns (uint32, uint32, uint32, uint32);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}