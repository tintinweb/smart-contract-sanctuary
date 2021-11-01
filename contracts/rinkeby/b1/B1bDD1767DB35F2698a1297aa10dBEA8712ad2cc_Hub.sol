// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IHub.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/ICurve.sol";

import "./libs/Details.sol";

/// @title meToken hub
/// @author Carl Farterson (@carlfarterson)
/// @notice This contract tracks all combinations of vaults and curves,
///     and their respective subscribed meTokens
contract Hub is Ownable, Initializable {
    uint256 public constant MAX_REFUND_RATIO = 10**6;
    uint256 private _warmup;
    uint256 private _duration;
    uint256 private _cooldown;

    uint256 private _count;
    IRegistry public vaultRegistry;
    IRegistry public curveRegistry;

    mapping(uint256 => Details.Hub) private _hubs;

    modifier exists(uint256 id) {
        require(id <= _count, "id exceeds _count");
        _;
    }

    function initialize(address _vaultRegistry, address _curveRegistry)
        external
        onlyOwner
        initializer
    {
        vaultRegistry = IRegistry(_vaultRegistry);
        curveRegistry = IRegistry(_curveRegistry);
    }

    function register(
        address _asset,
        IVault _vault,
        ICurve _curve,
        uint256 _refundRatio,
        bytes memory _encodedCurveDetails,
        bytes memory _encodedVaultArgs
    ) external {
        // TODO: access control

        require(curveRegistry.isApproved(address(_curve)), "_curve !approved");
        require(vaultRegistry.isApproved(address(_vault)), "_vault !approved");
        require(_refundRatio < MAX_REFUND_RATIO, "_refundRatio > MAX");

        // Ensure asset is valid based on encoded args and vault validation logic
        require(_vault.isValid(_asset, _encodedVaultArgs), "asset !valid");

        // Store value set base parameters to `{CurveName}.sol`
        _curve.register(_count, _encodedCurveDetails);

        // Save the hub to the registry
        Details.Hub storage hub_ = _hubs[_count++];
        hub_.active = true;
        hub_.asset = _asset;
        hub_.vault = address(_vault);
        hub_.curve = address(_curve);
        hub_.refundRatio = _refundRatio;
    }

    function initUpdate(
        uint256 _id,
        address _targetCurve,
        uint256 _targetRefundRatio,
        bytes memory _encodedCurveDetails
    ) external {
        Details.Hub storage hub_ = _hubs[_id];
        require(!hub_.updating, "already updating");
        require(block.timestamp >= hub_.endCooldown, "Still cooling down");
        if (_targetRefundRatio != 0) {
            require(
                _targetRefundRatio < MAX_REFUND_RATIO,
                "_targetRefundRatio >= MAX"
            );
            require(
                _targetRefundRatio != hub_.refundRatio,
                "_targetRefundRatio == refundRatio"
            );
        }
        bool reconfigure;
        if (_encodedCurveDetails.length > 0) {
            if (_targetCurve == address(0)) {
                reconfigure = true;
                ICurve(hub_.curve).initReconfigure(_id, _encodedCurveDetails);
            } else {
                require(
                    curveRegistry.isApproved(_targetCurve),
                    "_targetCurve !approved"
                );
                ICurve(_targetCurve).register(_id, _encodedCurveDetails);
                hub_.targetCurve = _targetCurve;
            }
        }

        if (_targetRefundRatio != 0) {
            hub_.targetRefundRatio = _targetRefundRatio;
        }

        hub_.reconfigure = reconfigure;
        hub_.updating = true;
        hub_.startTime = block.timestamp + _warmup;
        hub_.endTime = block.timestamp + _warmup + _duration;
        hub_.endCooldown = block.timestamp + _warmup + _duration + _cooldown;
    }

    function finishUpdate(uint256 id) external returns (Details.Hub memory) {
        Details.Hub storage hub_ = _hubs[id];
        require(block.timestamp > hub_.endTime, "Still updating");

        if (hub_.targetRefundRatio != 0) {
            hub_.refundRatio = hub_.targetRefundRatio;
            hub_.targetRefundRatio = 0;
        }

        if (hub_.reconfigure) {
            if (hub_.targetCurve == address(0)) {
                ICurve(hub_.curve).finishReconfigure(id);
            } else {
                hub_.curve = hub_.targetCurve;
                hub_.targetCurve = address(0);
            }
            hub_.reconfigure = false;
        }

        hub_.updating = false;
        hub_.startTime = 0;
        hub_.endTime = 0;
        return hub_;
    }

    function setWarmup(uint256 warmup_) external onlyOwner {
        require(warmup_ != _warmup, "warmup_ == _warmup");
        _warmup = warmup_;
    }

    function setDuration(uint256 duration_) external onlyOwner {
        require(duration_ != _duration, "duration_ == _duration");
        _duration = duration_;
    }

    function setCooldown(uint256 cooldown_) external onlyOwner {
        require(cooldown_ != _cooldown, "cooldown_ == _cooldown");
        _cooldown = cooldown_;
    }

    function count() external view returns (uint256) {
        return _count;
    }

    function getDetails(uint256 id)
        external
        view
        exists(id)
        returns (Details.Hub memory hub_)
    {
        hub_ = _hubs[id];
    }

    function getWarmup() external view returns (uint256) {
        return _warmup;
    }

    function getDuration() external view returns (uint256) {
        return _duration;
    }

    function getCooldown() external view returns (uint256) {
        return _cooldown;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libs/Details.sol";

interface IHub {
    event Register(string name, address indexed vault); // TODO: decide on arguments
    event Deactivate(uint256 id);

    function subscribeMeToken(uint256 _id, address _meToken) external;

    function getSubscribedMeTokenCount(uint256 _id)
        external
        view
        returns (uint256);

    function getSubscribedMeTokens(uint256 _id)
        external
        view
        returns (address[] memory);

    /// @notice Function to modify a hubs' status to INACTIVE
    /// @param id Unique hub identifier
    function deactivate(uint256 id) external;

    /// @notice Function to modify a hubs' status to QUEUED
    /// @param id Unique hub identifier
    function startUpdate(uint256 id) external;

    /// @notice Function to end the update, setting the target values of the hub,
    ///         as well as modifying a hubs' status to ACTIVE
    /// @param id Unique hub identifier
    function finishUpdate(uint256 id) external returns (Details.Hub memory);

    function initUpdate(
        uint256 _id,
        address _migration,
        address _targetVault,
        address _targetCurve,
        bool _reconfigure,
        uint256 _targetRefundRatio,
        uint256 _startTime,
        uint256 _duration
    ) external;

    /// @notice TODO
    /// @param id Unique hub identifier
    /// @return hub_ Details of hub
    function getDetails(uint256 id)
        external
        view
        returns (Details.Hub memory hub_);

    /// @notice TODO
    /// @return count of hubs created
    function count() external view returns (uint256);

    function getWarmup() external view returns (uint256);

    function setWarmup(uint256 warmup_) external;

    function getDuration() external view returns (uint256);

    function setDuration(uint256 duration_) external;

    function getCooldown() external view returns (uint256);

    function setCooldown(uint256 cooldown_) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVault {
    event Withdraw(uint256 amount, address to);
    event AddFee(uint256 amount);
    event StartMigration(address migration);
    event Migrate();

    function withdraw(
        address _asset,
        bool _max,
        uint256 _amount
    ) external;

    function approveAsset(address _asset, uint256 _amount) external;

    function isValid(address _asest, bytes memory _encodedArgs)
        external
        returns (bool);

    function addFee(address _meToken, uint256 _amount) external;

    function getAccruedFees(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IRegistry {
    event Approve(address _addr);
    event UnApprove(address _addr);

    function approve(address _addr) external;

    function unapprove(address _addr) external;

    function isApproved(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Curve Interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all Curves
interface ICurve {
    event Updated(uint256 indexed hubId);

    /// @notice Given a hub, baseX, baseY and connector weight, add the configuration to the
    /// BancorZero Curve registry
    /// @dev Curve need to be encoded as the Hub may register Curves for different curves
    ///      that may contain different Curve arguments
    /// @param _hubId                   unique hub identifier
    /// @param _encodedDetails          encoded Curve arguments
    function register(uint256 _hubId, bytes calldata _encodedDetails) external;

    /// @notice TODO
    /// @param _hubId                   unique hub identifier
    /// @param _encodedDetails          encoded target Curve arguments
    function initReconfigure(uint256 _hubId, bytes calldata _encodedDetails)
        external;

    function calculateMintReturn(
        uint256 _tokensDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensReturned);

    function calculateBurnReturn(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 tokensReturned);

    function calculateTargetMintReturn(
        uint256 _tokensDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensReturned);

    function calculateTargetBurnReturn(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 tokensReturned);

    function finishReconfigure(uint256 id) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Details {
    struct MeToken {
        address owner;
        uint256 hubId;
        uint256 balancePooled;
        uint256 balanceLocked;
        uint256 startTime;
        uint256 endTime;
        uint256 endCooldown;
        uint256 targetHubId;
        address migration;
    }

    struct Hub {
        bool active;
        address vault;
        address asset;
        address curve;
        uint256 refundRatio;
        bool updating;
        uint256 startTime;
        uint256 endTime;
        uint256 endCooldown;
        bool reconfigure;
        address targetCurve;
        uint256 targetRefundRatio;
    }

    struct Bancor {
        uint256 baseY;
        uint32 reserveWeight;
        uint256 targetBaseY;
        uint32 targetReserveWeight;
    }

    struct UniswapSingleTransfer {
        // The earliest time that the swap can occur
        uint256 soonest;
        // Fee configured to pay on swap
        uint24 fee;
        // if migration is active and startMigration() has not been triggered
        bool started;
        // meToken has executed the swap and can finish migrating
        bool swapped;
        // finishMigration() has been called so it's not recallable
        bool finished;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}