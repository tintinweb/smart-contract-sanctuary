// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "../periphery/PermissionsV2.sol";
import "../interfaces/IPendlePausingManager.sol";

contract PendlePausingManager is PermissionsV2, IPendlePausingManager {
    struct EmergencyHandlerSetting {
        address handler;
        address pendingHandler;
        uint256 timelockDeadline;
    }

    struct CachedStatus {
        uint128 timestamp;
        bool paused;
        bool locked;
    }

    uint256 private constant EMERGENCY_HANDLER_CHANGE_TIMELOCK = 7 days;

    mapping(bytes32 => mapping(address => mapping(uint256 => bool))) public forgeAssetExpiryPaused; // reversible
    mapping(bytes32 => mapping(address => bool)) public forgeAssetPaused; // reversible
    mapping(bytes32 => bool) public forgePaused; // reversible

    mapping(bytes32 => mapping(address => mapping(uint256 => bool))) public forgeAssetExpiryLocked; // non-reversible
    mapping(bytes32 => mapping(address => bool)) public forgeAssetLocked; // non-reversible
    mapping(bytes32 => bool) public forgeLocked; // non-reversible

    mapping(bytes32 => mapping(address => bool)) public marketPaused; // reversible
    mapping(bytes32 => bool) public marketFactoryPaused; // reversible

    mapping(bytes32 => mapping(address => bool)) public marketLocked; // non-reversible
    mapping(bytes32 => bool) public marketFactoryLocked; // non-reversible

    mapping(address => bool) public liqMiningPaused; // reversible
    mapping(address => bool) public liqMiningLocked;

    EmergencyHandlerSetting public override forgeEmergencyHandler;
    EmergencyHandlerSetting public override marketEmergencyHandler;
    EmergencyHandlerSetting public override liqMiningEmergencyHandler;

    bool public override permLocked;
    bool public override permForgeHandlerLocked;
    bool public override permMarketHandlerLocked;
    bool public override permLiqMiningHandlerLocked;

    uint256 internal lastUpdated;
    mapping(bytes32 => mapping(address => mapping(uint256 => CachedStatus)))
        public forgeAssetExpiryCachedStatus;
    mapping(bytes32 => mapping(address => CachedStatus)) public marketCachedStatus;
    mapping(address => CachedStatus) public liqMiningCachedStatus;

    mapping(address => bool) public override isPausingAdmin;

    // only governance can unpause; pausing admins can pause
    modifier isAllowedToSetPaused(bool settingToPaused) {
        if (settingToPaused) {
            require(isPausingAdmin[msg.sender], "FORBIDDEN");
        } else {
            require(msg.sender == _governance(), "ONLY_GOVERNANCE");
        }
        _;
    }

    modifier notPermLocked {
        require(!permLocked, "PERMANENTLY_LOCKED");
        _;
    }

    // This must be used in every function that changes any of the pausing/locked status
    modifier updateSomeStatus {
        _;
        lastUpdated = block.timestamp;
    }

    constructor(
        address _governanceManager,
        address initialForgeHandler,
        address initialMarketHandler,
        address initialLiqMiningHandler
    ) PermissionsV2(_governanceManager) {
        forgeEmergencyHandler.handler = initialForgeHandler;
        marketEmergencyHandler.handler = initialMarketHandler;
        liqMiningEmergencyHandler.handler = initialLiqMiningHandler;
        lastUpdated = block.timestamp;
    }

    /////////////////////////
    //////// ADMIN FUNCTIONS
    ////////
    function setPausingAdmin(address admin, bool isAdmin)
        external
        override
        onlyGovernance
        notPermLocked
    {
        require(isPausingAdmin[admin] != isAdmin, "REDUNDANT_SET");
        isPausingAdmin[admin] = isAdmin;
        if (isAdmin) {
            emit AddPausingAdmin(admin);
        } else {
            emit RemovePausingAdmin(admin);
        }
    }

    //// Changing forgeEmergencyHandler and marketEmergencyHandler
    function requestForgeHandlerChange(address _pendingForgeHandler)
        external
        override
        onlyGovernance
        notPermLocked
    {
        require(!permForgeHandlerLocked, "FORGE_HANDLER_LOCKED");
        require(_pendingForgeHandler != address(0), "ZERO_ADDRESS");
        forgeEmergencyHandler.pendingHandler = _pendingForgeHandler;
        forgeEmergencyHandler.timelockDeadline =
            block.timestamp +
            EMERGENCY_HANDLER_CHANGE_TIMELOCK;

        emit PendingForgeEmergencyHandler(_pendingForgeHandler);
    }

    function requestMarketHandlerChange(address _pendingMarketHandler)
        external
        override
        onlyGovernance
        notPermLocked
    {
        require(!permMarketHandlerLocked, "MARKET_HANDLER_LOCKED");
        require(_pendingMarketHandler != address(0), "ZERO_ADDRESS");
        marketEmergencyHandler.pendingHandler = _pendingMarketHandler;
        marketEmergencyHandler.timelockDeadline =
            block.timestamp +
            EMERGENCY_HANDLER_CHANGE_TIMELOCK;

        emit PendingMarketEmergencyHandler(_pendingMarketHandler);
    }

    function requestLiqMiningHandlerChange(address _pendingLiqMiningHandler)
        external
        override
        onlyGovernance
        notPermLocked
    {
        require(!permLiqMiningHandlerLocked, "LIQUIDITY_MINING_HANDLER_LOCKED");
        require(_pendingLiqMiningHandler != address(0), "ZERO_ADDRESS");
        liqMiningEmergencyHandler.pendingHandler = _pendingLiqMiningHandler;
        liqMiningEmergencyHandler.timelockDeadline =
            block.timestamp +
            EMERGENCY_HANDLER_CHANGE_TIMELOCK;

        emit PendingLiqMiningEmergencyHandler(_pendingLiqMiningHandler);
    }

    function applyForgeHandlerChange() external override notPermLocked {
        require(forgeEmergencyHandler.pendingHandler != address(0), "INVALID_HANDLER");
        require(block.timestamp > forgeEmergencyHandler.timelockDeadline, "TIMELOCK_NOT_OVER");
        forgeEmergencyHandler.handler = forgeEmergencyHandler.pendingHandler;
        forgeEmergencyHandler.pendingHandler = address(0);
        forgeEmergencyHandler.timelockDeadline = uint256(-1);

        emit ForgeEmergencyHandlerSet(forgeEmergencyHandler.handler);
    }

    function applyMarketHandlerChange() external override notPermLocked {
        require(marketEmergencyHandler.pendingHandler != address(0), "INVALID_HANDLER");
        require(block.timestamp > marketEmergencyHandler.timelockDeadline, "TIMELOCK_NOT_OVER");
        marketEmergencyHandler.handler = marketEmergencyHandler.pendingHandler;
        marketEmergencyHandler.pendingHandler = address(0);
        marketEmergencyHandler.timelockDeadline = uint256(-1);

        emit MarketEmergencyHandlerSet(marketEmergencyHandler.handler);
    }

    function applyLiqMiningHandlerChange() external override notPermLocked {
        require(liqMiningEmergencyHandler.pendingHandler != address(0), "INVALID_HANDLER");
        require(block.timestamp > liqMiningEmergencyHandler.timelockDeadline, "TIMELOCK_NOT_OVER");
        liqMiningEmergencyHandler.handler = liqMiningEmergencyHandler.pendingHandler;
        liqMiningEmergencyHandler.pendingHandler = address(0);
        liqMiningEmergencyHandler.timelockDeadline = uint256(-1);

        emit LiqMiningEmergencyHandlerSet(liqMiningEmergencyHandler.handler);
    }

    //// Lock permanently parts of the features
    function lockPausingManagerPermanently() external override onlyGovernance notPermLocked {
        permLocked = true;
        emit PausingManagerLocked();
    }

    function lockForgeHandlerPermanently() external override onlyGovernance notPermLocked {
        permForgeHandlerLocked = true;
        emit ForgeHandlerLocked();
    }

    function lockMarketHandlerPermanently() external override onlyGovernance notPermLocked {
        permMarketHandlerLocked = true;
        emit MarketHandlerLocked();
    }

    function lockLiqMiningHandlerPermanently() external override onlyGovernance notPermLocked {
        permLiqMiningHandlerLocked = true;
        emit LiqMiningHandlerLocked();
    }

    /////////////////////////
    //////// FORGE
    ////////
    function setForgePaused(bytes32 forgeId, bool settingToPaused)
        external
        override
        updateSomeStatus
        isAllowedToSetPaused(settingToPaused)
        notPermLocked
    {
        forgePaused[forgeId] = settingToPaused;
        emit SetForgePaused(forgeId, settingToPaused);
    }

    function setForgeAssetPaused(
        bytes32 forgeId,
        address underlyingAsset,
        bool settingToPaused
    ) external override updateSomeStatus isAllowedToSetPaused(settingToPaused) notPermLocked {
        forgeAssetPaused[forgeId][underlyingAsset] = settingToPaused;
        emit SetForgeAssetPaused(forgeId, underlyingAsset, settingToPaused);
    }

    function setForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool settingToPaused
    ) external override updateSomeStatus isAllowedToSetPaused(settingToPaused) notPermLocked {
        forgeAssetExpiryPaused[forgeId][underlyingAsset][expiry] = settingToPaused;
        emit SetForgeAssetExpiryPaused(forgeId, underlyingAsset, expiry, settingToPaused);
    }

    function setForgeLocked(bytes32 forgeId)
        external
        override
        updateSomeStatus
        onlyGovernance
        notPermLocked
    {
        forgeLocked[forgeId] = true;
        emit SetForgeLocked(forgeId);
    }

    function setForgeAssetLocked(bytes32 forgeId, address underlyingAsset)
        external
        override
        updateSomeStatus
        onlyGovernance
        notPermLocked
    {
        forgeAssetLocked[forgeId][underlyingAsset] = true;
        emit SetForgeAssetLocked(forgeId, underlyingAsset);
    }

    function setForgeAssetExpiryLocked(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external override updateSomeStatus onlyGovernance notPermLocked {
        forgeAssetExpiryLocked[forgeId][underlyingAsset][expiry] = true;
        emit SetForgeAssetExpiryLocked(forgeId, underlyingAsset, expiry);
    }

    function _isYieldContractPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) internal view returns (bool _paused) {
        _paused =
            forgePaused[forgeId] ||
            forgeAssetPaused[forgeId][underlyingAsset] ||
            forgeAssetExpiryPaused[forgeId][underlyingAsset][expiry];
    }

    function _isYieldContractLocked(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) internal view returns (bool _locked) {
        _locked =
            forgeLocked[forgeId] ||
            forgeAssetLocked[forgeId][underlyingAsset] ||
            forgeAssetExpiryLocked[forgeId][underlyingAsset][expiry];
    }

    function checkYieldContractStatus(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external override returns (bool _paused, bool _locked) {
        CachedStatus memory status =
            forgeAssetExpiryCachedStatus[forgeId][underlyingAsset][expiry];
        if (status.timestamp > lastUpdated) {
            return (status.paused, status.locked);
        }

        _locked = _isYieldContractLocked(forgeId, underlyingAsset, expiry);
        if (_locked) {
            _paused = true; // if a yield contract is locked, its paused by default as well
        } else {
            _paused = _isYieldContractPaused(forgeId, underlyingAsset, expiry);
        }

        // update the cache
        CachedStatus storage statusInStorage =
            forgeAssetExpiryCachedStatus[forgeId][underlyingAsset][expiry];
        statusInStorage.timestamp = uint128(block.timestamp);
        statusInStorage.locked = _locked;
        statusInStorage.paused = _paused;
    }

    /////////////////////////
    //////// MARKET
    ////////
    function setMarketFactoryPaused(bytes32 marketFactoryId, bool settingToPaused)
        external
        override
        updateSomeStatus
        isAllowedToSetPaused(settingToPaused)
        notPermLocked
    {
        marketFactoryPaused[marketFactoryId] = settingToPaused;
        emit SetMarketFactoryPaused(marketFactoryId, settingToPaused);
    }

    function setMarketPaused(
        bytes32 marketFactoryId,
        address market,
        bool settingToPaused
    ) external override updateSomeStatus isAllowedToSetPaused(settingToPaused) notPermLocked {
        marketPaused[marketFactoryId][market] = settingToPaused;
        emit SetMarketPaused(marketFactoryId, market, settingToPaused);
    }

    function setMarketFactoryLocked(bytes32 marketFactoryId)
        external
        override
        updateSomeStatus
        onlyGovernance
        notPermLocked
    {
        marketFactoryLocked[marketFactoryId] = true;
        emit SetMarketFactoryLocked(marketFactoryId);
    }

    function setMarketLocked(bytes32 marketFactoryId, address market)
        external
        override
        updateSomeStatus
        onlyGovernance
        notPermLocked
    {
        marketLocked[marketFactoryId][market] = true;
        emit SetMarketLocked(marketFactoryId, market);
    }

    function _isMarketPaused(bytes32 marketFactoryId, address market)
        internal
        view
        returns (bool _paused)
    {
        _paused = marketFactoryPaused[marketFactoryId] || marketPaused[marketFactoryId][market];
    }

    function _isMarketLocked(bytes32 marketFactoryId, address market)
        internal
        view
        returns (bool _locked)
    {
        _locked = marketFactoryLocked[marketFactoryId] || marketLocked[marketFactoryId][market];
    }

    function checkMarketStatus(bytes32 marketFactoryId, address market)
        external
        override
        returns (bool _paused, bool _locked)
    {
        CachedStatus memory status = marketCachedStatus[marketFactoryId][market];
        if (status.timestamp > lastUpdated) {
            return (status.paused, status.locked);
        }

        _locked = _isMarketLocked(marketFactoryId, market);
        if (_locked) {
            _paused = true; // if a yield contract is locked, its paused by default as well
        } else {
            _paused = _isMarketPaused(marketFactoryId, market);
        }

        // update the cache
        CachedStatus storage statusInStorage = marketCachedStatus[marketFactoryId][market];
        statusInStorage.timestamp = uint128(block.timestamp);
        statusInStorage.locked = _locked;
        statusInStorage.paused = _paused;
    }

    /////////////////////////
    //////// Liquidity Mining
    ////////
    function setLiqMiningPaused(address liqMiningContract, bool settingToPaused)
        external
        override
        updateSomeStatus
        isAllowedToSetPaused(settingToPaused)
        notPermLocked
    {
        liqMiningPaused[liqMiningContract] = settingToPaused;
        emit SetLiqMiningPaused(liqMiningContract, settingToPaused);
    }

    function setLiqMiningLocked(address liqMiningContract)
        external
        override
        updateSomeStatus
        onlyGovernance
        notPermLocked
    {
        liqMiningLocked[liqMiningContract] = true;
        emit SetLiqMiningLocked(liqMiningContract);
    }

    function checkLiqMiningStatus(address liqMiningContract)
        external
        override
        returns (bool _paused, bool _locked)
    {
        CachedStatus memory status = liqMiningCachedStatus[liqMiningContract];
        if (status.timestamp > lastUpdated) {
            return (status.paused, status.locked);
        }

        _locked = liqMiningLocked[liqMiningContract];
        if (_locked) {
            _paused = true; // if a yield contract is locked, its paused by default as well
        } else {
            _paused = liqMiningPaused[liqMiningContract];
        }

        // update the cache
        CachedStatus storage statusInStorage = liqMiningCachedStatus[liqMiningContract];
        statusInStorage.timestamp = uint128(block.timestamp);
        statusInStorage.locked = _locked;
        statusInStorage.paused = _paused;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../core/PendleGovernanceManager.sol";
import "../interfaces/IPermissionsV2.sol";

abstract contract PermissionsV2 is IPermissionsV2 {
    PendleGovernanceManager public immutable override governanceManager;
    address internal initializer;

    constructor(address _governanceManager) {
        require(_governanceManager != address(0), "ZERO_ADDRESS");
        initializer = msg.sender;
        governanceManager = PendleGovernanceManager(_governanceManager);
    }

    modifier initialized() {
        require(initializer == address(0), "NOT_INITIALIZED");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == _governance(), "ONLY_GOVERNANCE");
        _;
    }

    function _governance() internal view returns (address) {
        return governanceManager.governance();
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendlePausingManager {
    event AddPausingAdmin(address admin);
    event RemovePausingAdmin(address admin);
    event PendingForgeEmergencyHandler(address _pendingForgeHandler);
    event PendingMarketEmergencyHandler(address _pendingMarketHandler);
    event PendingLiqMiningEmergencyHandler(address _pendingLiqMiningHandler);
    event ForgeEmergencyHandlerSet(address forgeEmergencyHandler);
    event MarketEmergencyHandlerSet(address marketEmergencyHandler);
    event LiqMiningEmergencyHandlerSet(address liqMiningEmergencyHandler);

    event PausingManagerLocked();
    event ForgeHandlerLocked();
    event MarketHandlerLocked();
    event LiqMiningHandlerLocked();

    event SetForgePaused(bytes32 forgeId, bool settingToPaused);
    event SetForgeAssetPaused(bytes32 forgeId, address underlyingAsset, bool settingToPaused);
    event SetForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool settingToPaused
    );

    event SetForgeLocked(bytes32 forgeId);
    event SetForgeAssetLocked(bytes32 forgeId, address underlyingAsset);
    event SetForgeAssetExpiryLocked(bytes32 forgeId, address underlyingAsset, uint256 expiry);

    event SetMarketFactoryPaused(bytes32 marketFactoryId, bool settingToPaused);
    event SetMarketPaused(bytes32 marketFactoryId, address market, bool settingToPaused);

    event SetMarketFactoryLocked(bytes32 marketFactoryId);
    event SetMarketLocked(bytes32 marketFactoryId, address market);

    event SetLiqMiningPaused(address liqMiningContract, bool settingToPaused);
    event SetLiqMiningLocked(address liqMiningContract);

    function forgeEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function marketEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function liqMiningEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function permLocked() external view returns (bool);

    function permForgeHandlerLocked() external view returns (bool);

    function permMarketHandlerLocked() external view returns (bool);

    function permLiqMiningHandlerLocked() external view returns (bool);

    function isPausingAdmin(address) external view returns (bool);

    function setPausingAdmin(address admin, bool isAdmin) external;

    function requestForgeHandlerChange(address _pendingForgeHandler) external;

    function requestMarketHandlerChange(address _pendingMarketHandler) external;

    function requestLiqMiningHandlerChange(address _pendingLiqMiningHandler) external;

    function applyForgeHandlerChange() external;

    function applyMarketHandlerChange() external;

    function applyLiqMiningHandlerChange() external;

    function lockPausingManagerPermanently() external;

    function lockForgeHandlerPermanently() external;

    function lockMarketHandlerPermanently() external;

    function lockLiqMiningHandlerPermanently() external;

    function setForgePaused(bytes32 forgeId, bool paused) external;

    function setForgeAssetPaused(
        bytes32 forgeId,
        address underlyingAsset,
        bool paused
    ) external;

    function setForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool paused
    ) external;

    function setForgeLocked(bytes32 forgeId) external;

    function setForgeAssetLocked(bytes32 forgeId, address underlyingAsset) external;

    function setForgeAssetExpiryLocked(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external;

    function checkYieldContractStatus(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (bool _paused, bool _locked);

    function setMarketFactoryPaused(bytes32 marketFactoryId, bool paused) external;

    function setMarketPaused(
        bytes32 marketFactoryId,
        address market,
        bool paused
    ) external;

    function setMarketFactoryLocked(bytes32 marketFactoryId) external;

    function setMarketLocked(bytes32 marketFactoryId, address market) external;

    function checkMarketStatus(bytes32 marketFactoryId, address market)
        external
        returns (bool _paused, bool _locked);

    function setLiqMiningPaused(address liqMiningContract, bool settingToPaused) external;

    function setLiqMiningLocked(address liqMiningContract) external;

    function checkLiqMiningStatus(address liqMiningContract)
        external
        returns (bool _paused, bool _locked);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

contract PendleGovernanceManager {
    address public governance;
    address public pendingGovernance;

    event GovernanceClaimed(address newGovernance, address previousGovernance);

    event TransferGovernancePending(address pendingGovernance);

    constructor(address _governance) {
        require(_governance != address(0), "ZERO_ADDRESS");
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }

    /**
     * @dev Allows the pendingGovernance address to finalize the change governance process.
     */
    function claimGovernance() external {
        require(pendingGovernance == msg.sender, "WRONG_GOVERNANCE");
        emit GovernanceClaimed(pendingGovernance, governance);
        governance = pendingGovernance;
        pendingGovernance = address(0);
    }

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param _governance The address to transfer ownership to.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "ZERO_ADDRESS");
        pendingGovernance = _governance;

        emit TransferGovernancePending(pendingGovernance);
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "../core/PendleGovernanceManager.sol";

interface IPermissionsV2 {
    function governanceManager() external returns (PendleGovernanceManager);
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