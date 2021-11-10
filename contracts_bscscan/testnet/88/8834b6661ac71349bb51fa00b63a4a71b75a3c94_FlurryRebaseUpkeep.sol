//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IFlurryUpkeep.sol";
import "../interfaces/IVault.sol";

contract FlurryRebaseUpkeep is OwnableUpgradeable, IFlurryUpkeep {
    uint256 public rebaseInterval; // Daily rebasing interval with 1 = 1 second
    uint256 public lastTimeStamp;

    IVault[] public vaults;
    mapping(address => bool) public vaultRegistered;

    function initialize(uint256 interval) public initializer {
        OwnableUpgradeable.__Ownable_init();
        rebaseInterval = interval;
        lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) >= rebaseInterval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        for (uint256 i = 0; i < vaults.length; i++) {
            vaults[i].rebase();
        }
        performData;
    }

    function setRebaseInterval(uint256 interval) external onlyOwner {
        rebaseInterval = interval;
    }

    function registerVault(address vaultAddr) external override onlyOwner {
        require(vaultAddr != address(0), "Vault address is 0");
        require(!vaultRegistered[vaultAddr], "This vault is already registered.");
        vaults.push(IVault(vaultAddr));
        vaultRegistered[vaultAddr] = true;
    }
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFlurryUpkeep {
    /**
     * @dev checkUpkeep compatible.
     * Return upkeepNeeded (in bool) and performData (in bytes) and untilKeepNeeded (in uint).
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @dev performUpkeep compatible.
     */
    function performUpkeep(bytes calldata performData) external;

    /**
     * @dev Register vaults into Flurry Rebase Keeper contract.
     */
    function registerVault(address vaultAddr) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IVaultConfig.sol";

interface IVault {
    event CollectRewardError(address indexed _from, address indexed _strategy, string _reason);
    event CollectRewardUnknownError(address indexed _from, address indexed _strategy);

    /**
     * @dev getter function for cash reserve
     * @return return cash reserve balance (in underlying) for vault
     */
    function reserve() external view returns (uint256);

    /**
     * @return True if the asset is supported by this vault
     */
    function supportsAsset(address _asset) external view returns (bool);

    /**
     * @dev function that trigggers the distribution of interest earned to Rho token holders
     */
    function rebase() external;

    /**
     * @dev function that trigggers allocation and unallocation of funds based on reserve pool bounds
     */
    function rebalance() external;

    /**
     * @dev function to mint RhoToken
     * @param amount amount in underlying stablecoin
     */
    function mint(uint256 amount) external;

    /**
     * @dev function to redeem RhoToken
     * @param amount amount of rhoTokens to be redeemed
     */
    function redeem(uint256 amount) external;

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

    function sweepRhoTokenContractERC20Token(address token, address to) external;

    /**
     * @dev function to check strategies shoud collect reward
     * @return List of boolean
     */
    function checkStrategiesCollectReward() external view returns (bool[] memory);

    function supplyRate() external view returns (uint256);

    /**
     * @dev function to collect strategies reward token
     * @param collectList strategies to be collect
     */
    function collectStrategiesRewardTokenByIndex(uint16[] memory collectList) external returns (bool[] memory);

    /**
     * admin functions to withdraw fees
     */
    function withdrawFees(uint256 amount, address to) external;

    function config() external view returns (IVaultConfig);

    function getStrategiesList() external view returns (IVaultConfig.Strategy[] memory);

    function getStrategiesListLength() external view returns (uint256);

    function indicativeSupplyRate() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IRhoStrategy.sol";

interface IVaultConfig {
    event Log(string message);
    event StrategyAdded(string name, address addr);
    event StrategyRemoved(string name, address addr);

    struct Strategy {
        string name;
        IRhoStrategy target;
    }

    /**
     * @return Returns the address of the Rho token contract
     */
    function rhoToken() external view returns (address);

    function rhoOne() external view returns (uint256);

    /**
     * Each Vault currently only supports one underlying asset
     * @return Returns the contract address of the underlying asset
     */
    function underlying() external view returns (address);

    function underlyingOne() external view returns (uint256);

    /**
     * @dev Getter function for Rho token minting fee
     * @return Return the minting fee (in bps)
     */
    function mintingFee() external view returns (uint256);

    /**
     * @dev Getter function for Rho token redemption fee
     * @return Return the redeem fee (in bps)
     */
    function redeemFee() external view returns (uint256);

    /**
     * @dev Getter function for allocation lowerbound and upperbound
     */
    function reserveBoundary(uint256 index) external view returns (uint256);

    function managementFee() external view returns (uint256);

    /**
     * @dev The threshold (denominated in underlying asset ) over which rewards tokens will automatically
     * be converted into the underlying asset
     */

    function rewardCollectThreshold() external view returns (uint256);

    function underlyingNativePriceOracle() external view returns (address);

    function setUnderlyingNativePriceOracle(address addr) external;

    /**
     * @dev Setter function for Rho token redemption fee
     */
    function setRedeemFee(uint256 _feeInBps) external;

    /**
     * @dev set the threshold for collect reward (denominated in underlying asset)
     */
    function setRewardCollectThreshold(uint256 _rewardCollectThreshold) external;

    function setManagementFee(uint256 _feeInBps) external;

    /**
     * @dev set the allocation threshold (denominated in underlying asset)
     */
    function setReserveBoundary(uint256 _lowerBound, uint256 _upperBound) external;

    /**
     * @dev Setter function for minting fee (in bps)
     */
    function setMintingFee(uint256 _feeInBps) external;

    function reserveLowerBound(uint256 tvl) external view returns (uint256);

    function reserveUpperBound(uint256 tvl) external view returns (uint256);

    function supplyRate() external view returns (uint256);

    /**
     * @dev Add strategy contract which implments the IRhoStrategy interface to the vault
     */
    function addStrategy(string memory name, address strategy) external;

    /**
     * @dev Remove strategy contract which implments the IRhoStrategy interface from the vault
     */
    function removeStrategy(address strategy) external;

    /**
     * @dev Check if a strategy is registered
     * @param s address of strategy contract
     * @return boolean
     */
    function isStrategyRegistered(address s) external view returns (bool);

    function getStrategiesList() external view returns (Strategy[] memory);

    function getStrategiesListLength() external view returns (uint256);

    function updateStrategiesDetail(uint256 vaultUnderlyingBalance)
        external
        returns (
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256,
            uint256
        );

    function checkStrategiesCollectReward() external view returns (bool[] memory collectList);
    function indicativeSupplyRate() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title RhoStrategy Interface
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoStrategy {
    /**
     * Events
     */
    event WithdrawAllCashAvailable();
    event WithdrawUnderlying(uint256 amount);
    event Deploy(uint256 amount);
    event StrategyOutOfCash(uint256 balance, uint256 withdrawable);

    /**
     * @return name of protocol
     */
    function NAME() external view returns (string memory);

    /**
     * @dev for conversion bwtween APY and per block rate
     * @return number of blocks per year
     */
    function BLOCK_PER_YEAR() external view returns (uint256);

    /**
     * @dev setter function for `BLOCK_PER_YEAR`
     * @param blocksPerYear new number of blocks per year
     */
    function setBlocksPerYear(uint256 blocksPerYear) external;

    /**
     * @return underlying ERC20 token
     */
    function underlying() external view returns (IERC20MetadataUpgradeable);

    /**
     * @dev unlock when TVL exceed the this target
     */
    function switchingLockTarget() external view returns (uint256);

    /**
     * @dev duration for locking the strategy
     */
    function switchLockDuration() external view returns (uint256);

    /**
     * @return block number after which rewards are unlocked
     */
    function switchLockedUntil() external view returns (uint256);

    /**
     * @dev setter of switchLockDuration
     */
    function setSwitchLockDuration(uint256 durationInBlock) external;

    /**
     * @dev lock the strategy with a lock target
     */
    function switchingLock(uint256 lockTarget, bool extend) external;

    /**
     * @dev view function to return balance in underlying
     * @return balance (interest included) from DeFi protocol, in terms of underlying (in wei)
     */
    function balanceOfUnderlying() external view returns (uint256);

    /**
     * @dev updates the balance in underlying, and returns it
     * @return updated balance (interest included) from DeFi protocol, in terms of underlying (in wei)
     */
    function updateBalanceOfUnderlying() external returns (uint256);

    /**
     * @dev deploy the underlying to DeFi platform
     * @param _amount amount of underlying (in wei) to deploy
     */
    function deploy(uint256 _amount) external;

    /**
     * @notice current supply rate per block excluding bonus token (such as Aave / Comp)
     * @return supply rate per block, excluding yield from reward token if any
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice current supply rate excluding bonus token (such as Aave / Comp)
     * @return supply rate per year, excluding yield from reward token if any
     */
    function supplyRate() external view returns (uint256);

    /**
     * @return address of bonus token contract, or 0 if no bonus token
     */
    function bonusToken() external view returns (address);

    /**
     * @notice current bonus rate per block for bonus token (such as Aave / Comp)
     * @return bonus supply rate per block
     */
    function bonusRatePerBlock() external view returns (uint256);

    /**
     * @return bonus tokens accrued
     */
    function bonusTokensAccrued() external view returns (uint256);

    /**
     * @notice current bonus supply rate (such as Aave / Comp)
     * @return bonus supply rate per year
     */
    function bonusSupplyRate() external view returns (uint256);

    /**
     * @notice effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens
     * @return supply rate per year, including yield from reward token if any (in wei)
     */
    function effectiveSupplyRate() external view returns (uint256);

    /**
     * @notice effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens AND the change in deployed amount.
     * @param delta magnitude of underlying to be deployed / withdrawn
     * @param isPositive true if `delta` is deployed, false if `delta` is withdrawn
     * @return supply rate per year, including yield from reward token if any (in wei)
     */
    function effectiveSupplyRate(uint256 delta, bool isPositive) external view returns (uint256);

    /**
     * @dev Withdraw the amount in underlying from DeFi protocol and transfer to vault
     * @param _amount amount of underlying (in wei) to withdraw
     */
    function withdrawUnderlying(uint256 _amount) external;

    /**
     * @dev Withdraw all underlying from DeFi protocol and transfer to vault
     */
    function withdrawAllCashAvailable() external;

    /**
     * @dev Collect any bonus reward tokens available for the strategy
     */
    function collectRewardToken() external;

    /**
     * @dev admin function - withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

    function isLocked() external view returns (bool);

    /**
     * @notice Set the threshold (denominated in reward tokens) over which rewards tokens will automatically
     * be converted into the underlying asset
     * @dev default returns false. Override if the Protocol offers reward token (e.g. COMP for Compound)
     * @param rewardCollectThreshold minimum threshold for collecting reward token
     * @return true if reward in underlying > `rewardCollectThreshold`, false otherwise
     */
    function shouldCollectReward(uint256 rewardCollectThreshold) external view returns (bool);

    /**
     * @notice not all of the funds deployed to a strategy might be available for withdrawal
     * @return the amount of underlying tokens available for withdrawal from the rho strategy
     */
    function underlyingWithdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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