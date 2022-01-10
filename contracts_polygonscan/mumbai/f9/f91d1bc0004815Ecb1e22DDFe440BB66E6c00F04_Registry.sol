// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Governable.sol";
import "./interface/IRegistry.sol";

/**
 * @title IRegistry
 * @author softtech
 * @notice Tracks the contracts of the Is marketplace.
*/
contract Registry is IRegistry, Governable {

    /***************************************
    STATE VARIABLES
    ***************************************/

    /// @notice NFT token address.
    address private _token;

    /// @notice Marketplace manager address.
    address private _marketplace;

    /**
     * @notice Constructs the registry contract.
     * @param governance The address of the governance.
    */
    // solhint-disable-next-line no-empty-blocks
    constructor(address governance) Governable(governance) { }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/
    
    /**
     * @notice Sets the Is NFT marketplace token.
     * @param token The address of the [`Is NFT Token`](../Token) contract.
    */
    function setToken(address token) external override onlyGovernance {
        require(token != address(0x0), "zero address token");
        _token = token;
        emit TokenSet(token);
    }

    /**
     * @notice Sets the marketplace manager.
     * @param marketplace The address of the [`Marketplace Manager`](../MarketplaceManager) contract.
    */
    function setMarketplaceManager(address marketplace) external override onlyGovernance {
        require(marketplace != address(0x0), "zero address marketplace");
        _marketplace = marketplace;
        emit MarketplaceManagerSet(marketplace);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the [`Is NFT Token`](../Token) contract.
     * @return token The address of the [`Is NFT Token`](../Token).
    */
    function getToken() external view override returns (address token) {
        return _token;
    }

    /**
     * @notice Returns the [`Marketplace Manager`](../MarketplaceManager) contract.
     * @return marketplace The address of the marketplace manager contract.
    */
    function getMarketplaceManager() external view override returns (address marketplace) {
        return _marketplace;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IGovernable.sol";

/**
 * @title Governable
 * @author softtech
 * @notice Enforces access control for importan functions to governor.
*/
contract Governable is IGovernable {

    /***************************************
    STATE VARIABLES
    ***************************************/
    
    /// @notice governor.
    address private _governance;

    /// @notice governance to take over
    address private _pendingGovernance;

    /// @notice governance locking status.
    bool private _locked;

    /***************************************
    MODIFIERS
    ***************************************/

    /** 
     * Can only be called by governor.
     * Can only be called while unlocked.
    */
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    /** 
     * Can only be called by pending governor.
     * Can only be called while unlocked.
    */
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /**
     * @notice Contructs the governable constract.
     * @param governance The address of the governor.
    */
    constructor(address governance) {
        require(governance != address(0x0), "zero address governance");
        _governance = governance;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governance.
     * @param pendingGovernance The new governor.
    */
    function setPendingGovernance(address pendingGovernance) external override onlyGovernance {
        _pendingGovernance = pendingGovernance;
        emit GovernancePending(pendingGovernance);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
    */
    function acceptGovernance() external override onlyPendingGovernance {
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contracts's governance role and any of its functions that require the role.
     * This action cannot be reversed. Think twice before calling it.
     * Can only be called by the current governor.
    */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns current address of the current governor.
     * @return governor The current governor address.
    */
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /**
     * @notice Returns the address of the pending governor.
     * @return pendingGovernor The address of the pending governor.
    */
    function getPendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /**
     * @notice Returns true if the governance is locked.
     * @return status True if the governance is locked.
    */
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IRegistry
 * @author softtech
 * @notice Tracks the contracts of the Is marketplace.
*/
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when Is NFT token is set.
    event TokenSet(address token);
    
    /// @notice Emitted when Marketplace manager is set.
    event MarketplaceManagerSet(address marketplace);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/
    
    /**
     * @notice Sets the Is NFT marketplace token.
     * @param token The address of the [`Is NFT Token`](../Token) contract.
    */
    function setToken(address token) external;

    /**
     * @notice Sets the marketplace manager.
     * @param marketplace The address of the [`Marketplace Manager`](../MarketplaceManager) contract.
    */
    function setMarketplaceManager(address marketplace) external;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the [`Is NFT Token`](../Token) contract.
     * @return token The address of the [`Is NFT Token`](../Token).
    */
    function getToken() external view returns (address token);

    /**
     * @notice Returns the [`Marketplace Manager`](../MarketplaceManager) contract.
     * @return marketplace The address of the marketplace manager contract.
    */
    function getMarketplaceManager() external view returns (address marketplace);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IGovernable
 * @author softtech
 * @notice Enforces access control for important functions to governance.
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

    /**
     * @notice Returns current address of the current governor.
     * @return governor The current governor address.
    */
    function getGovernance() external view returns (address governor);

    /**
     * @notice Returns the address of the pending governor.
     * @return pendingGovernor The address of the pending governor.
    */
    function getPendingGovernance() external view returns (address pendingGovernor);

    /**
     * @notice Returns true if the governance is locked.
     * @return status True if the governance is locked.
    */
    function governanceIsLocked() external view returns (bool status);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governance.
     * @param pendingGovernance The new governor.
    */
    function setPendingGovernance(address pendingGovernance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
    */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contracts's governance role and any of its functions that require the role.
     * This action cannot be reversed. Think twice before calling it.
     * Can only be called by the current governor.
    */
    function lockGovernance() external;
}