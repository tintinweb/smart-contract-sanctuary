// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Governable.sol";
import "./interface/IRegistry.sol";

/**
 * @title Registry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * Note that `Registry` doesn't track all Solace contracts. Farms are tracked in [`FarmController`](./FarmController), Products are tracked in [`PolicyManager`](./PolicyManager), and the `Registry` is untracked.
 */
contract Registry is IRegistry, Governable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // WETH contract.
    address internal _weth;
    // Vault contract.
    address internal _vault;
    // Claims Escrow contract.
    address internal _claimsEscrow;
    // Treasury contract.
    address internal _treasury;
    // Policy Manager contract.
    address internal _policyManager;
    // Risk Manager contract.
    address internal _riskManager;
    // SOLACE contract.
    address internal _solace;
    // OptionsFarming contract.
    address internal _optionsFarming;
    // FarmController contract.
    address internal _farmController;
    // Locker contract.
    address internal _locker;

    /**
     * @notice Constructs the registry contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) Governable(governance_) { }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the [**WETH**](./WETH9) contract.
     * @return weth_ The address of the [**WETH**](./WETH9) contract.
     */
    function weth() external view override returns (address weth_) {
        return _weth;
    }

    /**
     * @notice Gets the [`Vault`](./Vault) contract.
     * @return vault_ The address of the [`Vault`](./Vault) contract.
     */
    function vault() external view override returns (address vault_) {
        return _vault;
    }

    /**
     * @notice Gets the [`ClaimsEscrow`](./ClaimsEscrow) contract.
     * @return claimsEscrow_ The address of the [`ClaimsEscrow`](./ClaimsEscrow) contract.
     */
    function claimsEscrow() external view override returns (address claimsEscrow_) {
        return _claimsEscrow;
    }

    /**
     * @notice Gets the [`Treasury`](./Treasury) contract.
     * @return treasury_ The address of the [`Treasury`](./Treasury) contract.
     */
    function treasury() external view override returns (address treasury_) {
        return _treasury;
    }

    /**
     * @notice Gets the [`PolicyManager`](./PolicyManager) contract.
     * @return policyManager_ The address of the [`PolicyManager`](./PolicyManager) contract.
     */
    function policyManager() external view override returns (address policyManager_) {
        return _policyManager;
    }

    /**
     * @notice Gets the [`RiskManager`](./RiskManager) contract.
     * @return riskManager_ The address of the [`RiskManager`](./RiskManager) contract.
     */
    function riskManager() external view override returns (address riskManager_) {
        return _riskManager;
    }

    /**
     * @notice Gets the [**SOLACE**](./SOLACE) contract.
     * @return solace_ The address of the [**SOLACE**](./SOLACE) contract.
     */
    function solace() external view override returns (address solace_) {
        return _solace;
    }

    /**
     * @notice Gets the [`OptionsFarming`](./OptionsFarming) contract.
     * @return optionsFarming_ The address of the [`OptionsFarming`](./OptionsFarming) contract.
     */
    function optionsFarming() external view override returns (address optionsFarming_) {
        return _optionsFarming;
    }

    /**
     * @notice Gets the [`FarmController`](./FarmController) contract.
     * @return farmController_ The address of the [`FarmController`](./FarmController) contract.
     */
    function farmController() external view override returns (address farmController_) {
        return _farmController;
    }

    /**
     * @notice Gets the [`Locker`](./Locker) contract.
     * @return locker_ The address of the [`Locker`](./Locker) contract.
     */
    function locker() external view override returns (address) {
        return _locker;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [**WETH**](./WETH9) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](./WETH9) contract.
     */
    function setWeth(address weth_) external override onlyGovernance {
        require(weth_ != address(0x0), "zero address weth");
        _weth = weth_;
        emit WethSet(weth_);
    }

    /**
     * @notice Sets the [`Vault`](./Vault) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param vault_ The address of the [`Vault`](./Vault) contract.
     */
    function setVault(address vault_) external override onlyGovernance {
        require(vault_ != address(0x0), "zero address vault");
        _vault = vault_;
        emit VaultSet(vault_);
    }

    /**
     * @notice Sets the [`Claims Escrow`](./ClaimsEscrow) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param claimsEscrow_ The address of the [`Claims Escrow`](./ClaimsEscrow) contract.
     */
    function setClaimsEscrow(address claimsEscrow_) external override onlyGovernance {
        require(claimsEscrow_ != address(0x0), "zero address claims escrow");
        _claimsEscrow = claimsEscrow_;
        emit ClaimsEscrowSet(claimsEscrow_);
    }

    /**
     * @notice Sets the [`Treasury`](./Treasury) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param treasury_ The address of the [`Treasury`](./Treasury) contract.
     */
    function setTreasury(address treasury_) external override onlyGovernance {
        require(treasury_ != address(0x0), "zero address treasury");
        _treasury = treasury_;
        emit TreasurySet(treasury_);
    }

    /**
     * @notice Sets the [`Policy Manager`](./PolicyManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param policyManager_ The address of the [`Policy Manager`](./PolicyManager) contract.
     */
    function setPolicyManager(address policyManager_) external override onlyGovernance {
        require(policyManager_ != address(0x0), "zero address policymanager");
        _policyManager = policyManager_;
        emit PolicyManagerSet(policyManager_);
    }

    /**
     * @notice Sets the [`Risk Manager`](./RiskManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param riskManager_ The address of the [`Risk Manager`](./RiskManager) contract.
     */
    function setRiskManager(address riskManager_) external override onlyGovernance {
        require(riskManager_ != address(0x0), "zero address riskmanager");
        _riskManager = riskManager_;
        emit RiskManagerSet(riskManager_);
    }

    /**
     * @notice Sets the [**SOLACE**](./SOLACE) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace_ The address of the [**SOLACE**](./SOLACE) contract.
     */
    function setSolace(address solace_) external override onlyGovernance {
        require(solace_ != address(0x0), "zero address solace");
        _solace = solace_;
        emit SolaceSet(solace_);
    }

    /**
     * @notice Sets the [`OptionsFarming`](./OptionsFarming) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param optionsFarming_ The address of the [`OptionsFarming`](./OptionsFarming) contract.
     */
    function setOptionsFarming(address optionsFarming_) external override onlyGovernance {
        _optionsFarming = optionsFarming_;
        emit OptionsFarmingSet(optionsFarming_);
    }

    /**
     * @notice Sets the [`FarmController`](./FarmController) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param farmController_ The address of the [`FarmController`](./FarmController) contract.
     */
    function setFarmController(address farmController_) external override onlyGovernance {
        require(farmController_ != address(0x0), "zero address farmcontroller");
        _farmController = farmController_;
        emit FarmControllerSet(farmController_);
    }

    /**
     * @notice Sets the [`Locker`](./Locker) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param locker_ The address of the [`Locker`](./Locker) contract.
     */
    function setLocker(address locker_) external override onlyGovernance {
        require(locker_ != address(0x0), "zero address locker");
        _locker = locker_;
        emit LockerSet(locker_);
    }

    /**
     * @notice Sets multiple contracts in one call.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](../WETH9) contract.
     * @param vault_ The address of the [`Vault`](../Vault) contract.
     * @param claimsEscrow_ The address of the [`Claims Escrow`](../ClaimsEscrow) contract.
     * @param treasury_ The address of the [`Treasury`](../Treasury) contract.
     * @param policyManager_ The address of the [`Policy Manager`](../PolicyManager) contract.
     * @param riskManager_ The address of the [`Risk Manager`](../RiskManager) contract.
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     * @param optionsFarming_ The address of the [`OptionsFarming`](./OptionsFarming) contract.
     * @param farmController_ The address of the [`FarmController`](./FarmController) contract.
     * @param locker_ The address of the [`Locker`](../Locker) contract.
     */
    function setMultiple(
        address weth_,
        address vault_,
        address claimsEscrow_,
        address treasury_,
        address policyManager_,
        address riskManager_,
        address solace_,
        address optionsFarming_,
        address farmController_,
        address locker_
    ) external override onlyGovernance {
        require(weth_ != address(0x0), "zero address weth");
        require(vault_ != address(0x0), "zero address vault");
        require(claimsEscrow_ != address(0x0), "zero address claims escrow");
        require(treasury_ != address(0x0), "zero address treasury");
        require(policyManager_ != address(0x0), "zero address policymanager");
        require(riskManager_ != address(0x0), "zero address riskmanager");
        require(solace_ != address(0x0), "zero address solace");
        require(optionsFarming_ != address(0x0), "zero address optionsfarming");
        require(farmController_ != address(0x0), "zero address farmcontroller");
        require(locker_ != address(0x0), "zero address locker");
        _weth = weth_;
        emit WethSet(weth_);
        _vault = vault_;
        emit VaultSet(vault_);
        _claimsEscrow = claimsEscrow_;
        emit ClaimsEscrowSet(claimsEscrow_);
        _treasury = treasury_;
        emit TreasurySet(treasury_);
        _policyManager = policyManager_;
        emit PolicyManagerSet(policyManager_);
        _riskManager = riskManager_;
        emit RiskManagerSet(riskManager_);
        _solace = solace_;
        emit SolaceSet(solace_);
        _optionsFarming = optionsFarming_;
        emit OptionsFarmingSet(optionsFarming_);
        _farmController = farmController_;
        emit FarmControllerSet(farmController_);
        _locker = locker_;
        emit LockerSet(locker_);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./interface/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * Note that `Registry` doesn't track all Solace contracts. FarmController is tracked in [`OptionsFarming`](../OptionsFarming), farms are tracked in FarmController, Products are tracked in [`PolicyManager`](../PolicyManager), and the `Registry` is untracked.
 */
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    // Emitted when WETH is set.
    event WethSet(address weth);
    // Emitted when Vault is set.
    event VaultSet(address vault);
    // Emitted when ClaimsEscrow is set.
    event ClaimsEscrowSet(address claimsEscrow);
    // Emitted when Treasury is set.
    event TreasurySet(address treasury);
    // Emitted when PolicyManager is set.
    event PolicyManagerSet(address policyManager);
    // Emitted when RiskManager is set.
    event RiskManagerSet(address riskManager);
    // Emitted when Solace Token is set.
    event SolaceSet(address solace);
    // Emitted when OptionsFarming is set.
    event OptionsFarmingSet(address optionsFarming);
    // Emitted when FarmController is set.
    event FarmControllerSet(address farmController);
    // Emitted when Locker is set.
    event LockerSet(address locker);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the [**WETH**](../WETH9) contract.
     * @return weth_ The address of the [**WETH**](../WETH9) contract.
     */
    function weth() external view returns (address weth_);

    /**
     * @notice Gets the [`Vault`](../Vault) contract.
     * @return vault_ The address of the [`Vault`](../Vault) contract.
     */
    function vault() external view returns (address vault_);

    /**
     * @notice Gets the [`ClaimsEscrow`](../ClaimsEscrow) contract.
     * @return claimsEscrow_ The address of the [`ClaimsEscrow`](../ClaimsEscrow) contract.
     */
    function claimsEscrow() external view returns (address claimsEscrow_);

    /**
     * @notice Gets the [`Treasury`](../Treasury) contract.
     * @return treasury_ The address of the [`Treasury`](../Treasury) contract.
     */
    function treasury() external view returns (address treasury_);

    /**
     * @notice Gets the [`PolicyManager`](../PolicyManager) contract.
     * @return policyManager_ The address of the [`PolicyManager`](../PolicyManager) contract.
     */
    function policyManager() external view returns (address policyManager_);

    /**
     * @notice Gets the [`RiskManager`](../RiskManager) contract.
     * @return riskManager_ The address of the [`RiskManager`](../RiskManager) contract.
     */
    function riskManager() external view returns (address riskManager_);

    /**
     * @notice Gets the [**SOLACE**](../SOLACE) contract.
     * @return solace_ The address of the [**SOLACE**](../SOLACE) contract.
     */
    function solace() external view returns (address solace_);

    /**
     * @notice Gets the [`OptionsFarming`](../OptionsFarming) contract.
     * @return optionsFarming_ The address of the [`OptionsFarming`](../OptionsFarming) contract.
     */
    function optionsFarming() external view returns (address optionsFarming_);

    /**
     * @notice Gets the [`FarmController`](../FarmController) contract.
     * @return farmController_ The address of the [`FarmController`](../FarmController) contract.
     */
    function farmController() external view returns (address farmController_);

    /**
     * @notice Gets the [`Locker`](../Locker) contract.
     * @return locker_ The address of the [`Locker`](../Locker) contract.
     */
    function locker() external view returns (address locker_);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [**WETH**](../WETH9) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](../WETH9) contract.
     */
    function setWeth(address weth_) external;

    /**
     * @notice Sets the [`Vault`](../Vault) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param vault_ The address of the [`Vault`](../Vault) contract.
     */
    function setVault(address vault_) external;

    /**
     * @notice Sets the [`Claims Escrow`](../ClaimsEscrow) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param claimsEscrow_ The address of the [`Claims Escrow`](../ClaimsEscrow) contract.
     */
    function setClaimsEscrow(address claimsEscrow_) external;

    /**
     * @notice Sets the [`Treasury`](../Treasury) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param treasury_ The address of the [`Treasury`](../Treasury) contract.
     */
    function setTreasury(address treasury_) external;

    /**
     * @notice Sets the [`Policy Manager`](../PolicyManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param policyManager_ The address of the [`Policy Manager`](../PolicyManager) contract.
     */
    function setPolicyManager(address policyManager_) external;

    /**
     * @notice Sets the [`Risk Manager`](../RiskManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param riskManager_ The address of the [`Risk Manager`](../RiskManager) contract.
     */
    function setRiskManager(address riskManager_) external;

    /**
     * @notice Sets the [**SOLACE**](../SOLACE) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     */
    function setSolace(address solace_) external;

    /**
     * @notice Sets the [`OptionsFarming`](../OptionsFarming) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param optionsFarming_ The address of the [`OptionsFarming`](../OptionsFarming) contract.
     */
    function setOptionsFarming(address optionsFarming_) external;

    /**
     * @notice Sets the [`FarmController`](../FarmController) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param farmController_ The address of the [`FarmController`](../FarmController) contract.
     */
    function setFarmController(address farmController_) external;

    /**
     * @notice Sets the [`Locker`](../Locker) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param locker_ The address of the [`Locker`](../Locker) contract.
     */
    function setLocker(address locker_) external;

    /**
     * @notice Sets multiple contracts in one call.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](../WETH9) contract.
     * @param vault_ The address of the [`Vault`](../Vault) contract.
     * @param claimsEscrow_ The address of the [`Claims Escrow`](../ClaimsEscrow) contract.
     * @param treasury_ The address of the [`Treasury`](../Treasury) contract.
     * @param policyManager_ The address of the [`Policy Manager`](../PolicyManager) contract.
     * @param riskManager_ The address of the [`Risk Manager`](../RiskManager) contract.
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     * @param optionsFarming_ The address of the [`OptionsFarming`](./OptionsFarming) contract.
     * @param farmController_ The address of the [`FarmController`](./FarmController) contract.
     * @param locker_ The address of the [`Locker`](../Locker) contract.
     */
    function setMultiple(
        address weth_,
        address vault_,
        address claimsEscrow_,
        address treasury_,
        address policyManager_,
        address riskManager_,
        address solace_,
        address optionsFarming_,
        address farmController_,
        address locker_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}