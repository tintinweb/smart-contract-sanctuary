// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IEtherRewards.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IIntegrationMap.sol";
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
    function initialize(address[] memory controllers_, address moduleMap_) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        __ModuleMapConsumer_init(moduleMap_);
    }

    uint256 private totalEthRewards;
    uint256 private totalClaimedEthRewards;
    mapping(address => uint256) private totalUserClaimedEthRewards;
    mapping(address => uint256) private tokenRewardRate;
    mapping(address => uint256) private tokenEthRewards;
    mapping(address => mapping(address => uint256)) private userTokenRewardRate;
    mapping(address => mapping(address => uint256)) private userTokenAccumulatedRewards;

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    function updateUserRewards(address token, address user) public override onlyController {
        uint256 userTokenDeposits = IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions)).userTokenBalance(token, user);

        userTokenAccumulatedRewards[token][user] += (tokenRewardRate[token] - userTokenRewardRate[token][user]) * userTokenDeposits / 10**18;

        userTokenRewardRate[token][user] = tokenRewardRate[token];
    }
    
    /// @param token The address of the token ERC20 contract
    /// @param ethRewardsAmount The amount of Ether rewards to add
    function increaseEthRewards(address token, uint256 ethRewardsAmount) external override onlyController {
        uint256 tokenTotalDeposits = IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions)).totalTokenBalance(token);
        require(tokenTotalDeposits > 0, "EtherRewards::increaseEthRewards: Token has not been deposited yet");

        totalEthRewards += ethRewardsAmount;
        tokenEthRewards[token] += ethRewardsAmount;
        tokenRewardRate[token] += ethRewardsAmount * 10**18 / tokenTotalDeposits;
    }

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimEthRewards(address user) external override onlyController returns (uint256 ethRewards) {
        address integrationMap = moduleMap.getModuleAddress(Modules.IntegrationMap);
        uint256 tokenCount = IIntegrationMap(integrationMap).getTokenAddressesLength();

        for(uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address token = IIntegrationMap(integrationMap).getTokenAddress(tokenId);
            ethRewards += claimTokenEthRewards(token, user);
        }
    }

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimTokenEthRewards(address token, address user) private returns (uint256 ethRewards) {
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
    function getUserTokenEthRewards(address token, address user) public view override returns (uint256 ethRewards) {
        uint256 userTokenDeposits = IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions)).userTokenBalance(token, user);

        ethRewards = userTokenAccumulatedRewards[token][user] + (tokenRewardRate[token] - userTokenRewardRate[token][user]) * userTokenDeposits / 10**18;
    }

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserEthRewards(address user) external view override returns (uint256 ethRewards) {
        address integrationMap = moduleMap.getModuleAddress(Modules.IntegrationMap);
        uint256 tokenCount = IIntegrationMap(integrationMap).getTokenAddressesLength();
        
        for(uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address token = IIntegrationMap(integrationMap).getTokenAddress(tokenId);
            ethRewards += getUserTokenEthRewards(token, user);
        }
    }

    /// @param token The address of the token ERC20 contract
    /// @return The amount of Ether rewards for the specified token
    function getTokenEthRewards(address token) external view override returns (uint256) {
        return tokenEthRewards[token];
    }

    /// @return The total value of ETH claimed by users
    function getTotalClaimedEthRewards() external view override returns (uint256) {
        return totalClaimedEthRewards;
    }

    /// @return The total value of ETH claimed by a user
    function getTotalUserClaimedEthRewards(address account) external view override returns (uint256) {
        return totalUserClaimedEthRewards[account];
    }

    /// @return The total amount of Ether rewards
    function getEthRewards() external view override returns (uint256) {
        return totalEthRewards;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEtherRewards {
    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    function updateUserRewards(address token, address user) external;
    
    /// @param token The address of the token ERC20 contract
    /// @param ethRewardsAmount The amount of Ether rewards to add
    function increaseEthRewards(address token, uint256 ethRewardsAmount) external;

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimEthRewards(address user) external returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserTokenEthRewards(address token, address user) external view returns (uint256 ethRewards);

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserEthRewards(address user) external view returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @return The amount of Ether rewards for the specified token
    function getTokenEthRewards(address token) external view returns (uint256);

    /// @return The total value of ETH claimed by users
    function getTotalClaimedEthRewards() external view returns (uint256);

    /// @return The total value of ETH claimed by a user
    function getTotalUserClaimedEthRewards(address user) external view returns (uint256);

    /// @return The total amount of Ether rewards
    function getEthRewards() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserPositions{
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
    function deposit(address depositor, address[] memory tokens, uint256[] memory amounts, uint256 ethAmount) external;

    /// @notice User is allowed to withdraw tokens
    /// @param recipient The address of the user withdrawing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    function withdraw(
        address recipient, 
        address[] memory tokens, 
        uint256[] memory amounts, 
        bool withdrawWethAsEth) 
    external returns (
        uint256 ethWithdrawn
    );

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
    ) external returns (
        uint256[] memory tokenAmounts,
        uint256 ethWithdrawn,
        uint256 ethClaimed,
        uint256 biosClaimed
    );

    /// @param user The address of the user claiming ETH rewards
    function claimEthRewards(address user) external returns (uint256 ethClaimed);

    /// @notice Allows users to claim their BIOS rewards for each token
    /// @param recipient The address of the usuer claiming BIOS rewards
    function claimBiosRewards(address recipient) external returns (uint256 biosClaimed);

    /// @param asset Address of the ERC20 token contract
    /// @return The total balance of the asset deposited in the system
    function totalTokenBalance(address asset) external view returns (uint256);

    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userTokenBalance(address asset, address account) external view returns (uint256);

    /// @return The Bios Rewards Duration
    function getBiosRewardsDuration() external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IIntegrationMap {
    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    /// @param weightsByTokenId The weights of each token for the added integration
    function addIntegration(address contractAddress, string memory name, uint256[] memory weightsByTokenId) external;

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    /// @param weightsByIntegrationId The weights of each integration for the added token
    function addToken(
        address tokenAddress, 
        bool acceptingDeposits, 
        bool acceptingWithdrawals, 
        uint256 biosRewardWeight, 
        uint256 reserveRatioNumerator, 
        uint256[] memory weightsByIntegrationId
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

    /// @param integrationAddress The address of the integration contract
    /// @param tokenAddress the address of the token ERC20 contract
    /// @param updatedWeight The updated token integration weight
    function updateTokenIntegrationWeight(address integrationAddress, address tokenAddress, uint256 updatedWeight) external;

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

    /// @param integrationAddress The address of the integration contract
    /// @param tokenAddress the address of the token ERC20 contract
    /// @return The weight of the specified integration & token combination
    function getTokenIntegrationWeight(address integrationAddress, address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenWeightSum The sum of the specified token weights
    function getTokenIntegrationWeightSum(address tokenAddress) external view returns (uint256 tokenWeightSum);

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
    UniswapTrader // 7
}

interface IModuleMap {
    function getModuleAddress(Modules key) external view returns (address);
}

