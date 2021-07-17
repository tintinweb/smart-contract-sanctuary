/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/interface/IRegistry.sol


pragma solidity 0.8.0;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts in the Solaverse.
 */
interface IRegistry {

    /// @notice Governance.
    function governance() external view returns (address);

    /// @notice Governance to take over.
    function newGovernance() external view returns (address);

    /// Protocol contract address getters
    function master() external view returns (address);
    function vault() external view returns (address);
    function treasury() external view returns (address);
    function solace() external view returns (address);
    function locker() external view returns (address);
    function claimsEscrow() external view returns (address);
    function policyManager() external view returns (address);

    // events
    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);
    // Emitted when Solace Token is set
    event SolaceSet(address _solace);
    // Emitted when Master is set
    event MasterSet(address _master);
    // Emitted when Vault is set
    event VaultSet(address _vault);
    // Emitted when Treasury is set
    event TreasurySet(address _treasury);
    // Emitted when Locker is set
    event LockerSet(address _locker);
    // Emitted when ClaimsEscrow is set
    event ClaimsEscrowSet(address _claimsEscrow);
    // Emitted when PolicyManager is set
    event PolicyManagerSet(address _policyManager);

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Sets the solace token contract.
     * Can only be called by the current governor.
     * @param _solace The solace token address.
     */
    function setSolace(address _solace) external;

    /**
     * @notice Sets the master contract.
     * Can only be called by the current governor.
     * @param _master The master contract address.
     */
    function setMaster(address _master) external;

    /**
     * @notice Sets the vault contract.
     * Can only be called by the current governor.
     * @param _vault The vault contract address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets the treasury contract.
     * Can only be called by the current governor.
     * @param _treasury The treasury contract address.
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Sets the locker contract.
     * Can only be called by the current governor.
     * @param _locker The locker address.
     */
    function setLocker(address _locker) external;

    /**
     * @notice Sets the Claims Escrow contract.
     * Can only be called by the current governor.
     * @param _claimsEscrow The Claims Escrow address.
     */
    function setClaimsEscrow(address _claimsEscrow) external;

    /**
     * @notice Sets the PolicyManager contract.
     * Can only be called by the current governor.
     * @param _policyManager The PolicyManager address.
     */
    function setPolicyManager(address _policyManager) external;
}


// File contracts/Registry.sol


pragma solidity 0.8.0;

/**
 * @title Registry
 * @author solace.fi
 * @notice Tracks the contracts in the Solaverse.
 */
contract Registry is IRegistry {

    /// @notice Governor.
    address public override governance;
    /// @notice Governance to take over.
    address public override newGovernance;
    /// @notice Solace Token.
    address public override solace;
    /// @notice Master contract.
    address public override master;
    /// @notice Vault contract.
    address public override vault;
    /// @notice Treasury contract.
    address public override treasury;
    /// @notice Locker contract.
    address public override locker;
    /// @notice Claims Escrow contract.
    address public override claimsEscrow;
    /// @notice Policy Manager contract.
    address public override policyManager;

    /**
     * @notice Constructs the registry contract.
     * @param _governance Address of the governor.
     */
    constructor(address _governance) {
        governance = _governance;
    }

    /**
     * @notice Allows governance to be transferred to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        newGovernance = _governance;
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external override {
        // can only be called by new governor
        require(msg.sender == newGovernance, "!governance");
        governance = newGovernance;
        newGovernance = address(0x0);
        emit GovernanceTransferred(msg.sender);
    }

    /**
     * @notice Sets the solace token contract.
     * Can only be called by the current governor.
     * @param _solace The solace token address.
     */
    function setSolace(address _solace) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        solace = _solace;
        emit SolaceSet(_solace);
    }

    /**
     * @notice Sets the master contract.
     * Can only be called by the current governor.
     * @param _master The master contract address.
     */
    function setMaster(address _master) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        master = _master;
        emit MasterSet(_master);
    }

    /**
     * @notice Sets the Claims Escrow contract.
     * Can only be called by the current governor.
     * @param _claimsEscrow The sClaims Escrow address.
     */
    function setClaimsEscrow(address _claimsEscrow) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        claimsEscrow = _claimsEscrow;
        emit ClaimsEscrowSet(_claimsEscrow);
    }

    /**
     * @notice Sets the vault contract.
     * Can only be called by the current governor.
     * @param _vault The vault contract address.
     */
    function setVault(address _vault) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        vault = _vault;
        emit VaultSet(_vault);
    }

    /**
     * @notice Sets the treasury contract.
     * Can only be called by the current governor.
     * @param _treasury The treasury contract address.
     */
    function setTreasury(address _treasury) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    /**
     * @notice Sets the locker contract.
     * Can only be called by the current governor.
     * @param _locker The locker address.
     */
    function setLocker(address _locker) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        locker = _locker;
        emit LockerSet(_locker);
    }

    /**
     * @notice Sets the PolicyManager contract.
     * Can only be called by the current governor.
     * @param _policyManager The policy manager address.
     */
    function setPolicyManager(address _policyManager) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        policyManager = _policyManager;
        emit PolicyManagerSet(_policyManager);
    }
}