// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IHub.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IVaultRegistry.sol";
import "./interfaces/ICurveRegistry.sol";
import "./interfaces/ICurve.sol";

import "./libs/Details.sol";

/// @title meToken hub
/// @author Carl Farterson (@carlfarterson)
/// @notice This contract tracks all combinations of vaults and curves,
///     and their respective subscribed meTokens
contract Hub is Ownable, Initializable {
    uint256 private immutable _precision = 10**18;
    uint256 private _minSecondsUntilStart = 0; // TODO
    uint256 private _maxSecondsUntilStart = 0; // TODO
    uint256 private _minDuration = 0; // TODO
    uint256 private _maxDuration = 0; // TODO

    uint256 private _count;
    address public foundry;
    IVaultRegistry public vaultRegistry;
    ICurveRegistry public curveRegistry;

    mapping(uint256 => Details.HubDetails) private _hubs;
    mapping(uint256 => address[]) private _subscribedMeTokens;

    modifier exists(uint256 id) {
        require(id <= _count, "id exceeds _count");
        _;
    }

    /*
    // TODO: actually subscribe/resubscribe/unsubscribe meToken
    function subscribeMeToken(uint256 _id, address _meToken)
        public
        exists(_id)
    {
        _subscribedMeTokens[_id].push(_meToken);
    }

    function getSubscribedMeTokenCount(uint256 _id)
        public
        view
        returns (uint256)
    {
        return _subscribedMeTokens[_id].length;
    }

    function getSubscribedMeTokens(uint256 _id)
        external
        view
        returns (address[] memory)
    {
        return _subscribedMeTokens[_id];
    }
    */

    function initialize(
        address _foundry,
        address _vaultRegistry,
        address _curveRegistry
    ) external onlyOwner initializer {
        foundry = _foundry;
        vaultRegistry = IVaultRegistry(_vaultRegistry);
        curveRegistry = ICurveRegistry(_curveRegistry);
    }

    function register(
        address _vaultFactory,
        address _curve,
        address _token,
        uint256 _refundRatio,
        bytes memory _encodedValueSetArgs,
        bytes memory _encodedVaultAdditionalArgs
    ) external {
        // TODO: access control

        require(curveRegistry.isActive(_curve), "_curve !approved");
        require(
            vaultRegistry.isApproved(_vaultFactory),
            "_vaultFactory !approved"
        );
        require(_refundRatio < _precision, "_refundRatio > _precision");
        // Store value set base paramaters to `{CurveName}.sol`
        ICurve(_curve).register(_count, _encodedValueSetArgs);

        // Create new vault
        // ALl new _hubs will create a vault
        address vault = IVaultFactory(_vaultFactory).create(
            _token,
            _encodedVaultAdditionalArgs
        );
        // Save the hub to the registry
        Details.HubDetails storage newHubDetails = _hubs[_count++];
        newHubDetails.active = true;
        newHubDetails.vault = vault;
        newHubDetails.curve = _curve;
        newHubDetails.refundRatio = _refundRatio;
    }

    function initUpdate(
        uint256 _id,
        address _migrationVault,
        address _targetVault,
        address _targetCurve,
        uint256 _targetRefundRatio,
        bytes memory _encodedCurveDetails,
        uint256 _startTime,
        uint256 _duration
    ) external {
        require(
            _startTime - block.timestamp >= _minSecondsUntilStart &&
                _startTime - block.timestamp <= _maxSecondsUntilStart,
            "Unacceptable _startTime"
        );
        require(
            _minDuration <= _duration && _maxDuration >= _duration,
            "Unacceptable update duration"
        );

        bool curveDetails;
        Details.HubDetails storage hubDetails = _hubs[_id];
        require(!hubDetails.updating, "already updating");
        // First, do all checks
        if (_targetRefundRatio != 0) {
            require(
                _targetRefundRatio < _precision,
                "_targetRefundRatio >= _precision"
            );
            require(
                _targetRefundRatio != hubDetails.refundRatio,
                "_targetRefundRatio == refundRatio"
            );
        }

        if (_encodedCurveDetails.length > 0) {
            if (_targetCurve == address(0)) {
                ICurve(hubDetails.curve).registerTarget(
                    _id,
                    _encodedCurveDetails
                );
            } else {
                // _targetCurve != address(0))
                require(
                    curveRegistry.isActive(_targetCurve),
                    "_targetCurve inactive"
                );
                ICurve(_targetCurve).register(_id, _encodedCurveDetails);
            }
            curveDetails = true;
        }

        if (_migrationVault != address(0) && _targetVault != address(0)) {
            hubDetails.migrationVault = _migrationVault;
            hubDetails.targetVault = _targetVault;
        }

        if (_targetRefundRatio != 0) {
            hubDetails.targetRefundRatio = _targetRefundRatio;
        }
        if (_targetCurve != address(0)) {
            hubDetails.targetCurve = _targetCurve;
        }
        if (_migrationVault != address(0) && _targetVault != address(0)) {
            hubDetails.migrationVault = _migrationVault;
            hubDetails.targetVault = _targetVault;
        }

        hubDetails.curveDetails = curveDetails;
        hubDetails.updating = true;
        hubDetails.startTime = _startTime;
        hubDetails.endTime = _startTime + _duration;
    }

    function finishUpdate(uint256 id) external {
        // TODO: only callable from foundry

        Details.HubDetails storage hubDetails = _hubs[id];
        if (hubDetails.targetRefundRatio != 0) {
            hubDetails.refundRatio = hubDetails.targetRefundRatio;
            hubDetails.targetRefundRatio = 0;
        }

        // Updating curve details and staying with the same curve
        if (hubDetails.curveDetails) {
            if (hubDetails.targetCurve == address(0)) {
                ICurve(hubDetails.curve).finishUpdate(id);
            } else {
                hubDetails.curve = hubDetails.targetCurve;
                hubDetails.targetCurve = address(0);
            }
            hubDetails.curveDetails = false;
        }

        hubDetails.updating = false;
    }

    function getCount() external view returns (uint256) {
        return _count;
    }

    function getRefundRatio(uint256 id)
        external
        view
        exists(id)
        returns (uint256)
    {
        Details.HubDetails memory hubDetails = _hubs[id];
        return hubDetails.refundRatio;
    }

    function getDetails(uint256 id)
        external
        view
        exists(id)
        returns (Details.HubDetails memory hubDetails)
    {
        hubDetails = _hubs[id];
    }

    function getCurve(uint256 id) external view exists(id) returns (address) {
        Details.HubDetails memory hubDetails = _hubs[id];
        return hubDetails.curve;
    }

    function getVault(uint256 id) external view exists(id) returns (address) {
        Details.HubDetails memory hubDetails = _hubs[id];
        return hubDetails.vault;
    }

    function isActive(uint256 id) public view returns (bool) {
        Details.HubDetails memory hubDetails = _hubs[id];
        return hubDetails.active;
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
    function finishUpdate(uint256 id) external;

    function initUpdate(
        uint256 _id,
        address _migrationVault,
        address _targetVault,
        address _targetCurve,
        bool _curveDetails,
        uint256 _targetRefundRatio,
        uint256 _startTime,
        uint256 _duration
    ) external;

    /// @notice TODO
    /// @param id Unique hub identifier
    /// @return hubDetails Details of hub
    function getDetails(uint256 id)
        external
        view
        returns (Details.HubDetails memory hubDetails);

    /// @notice Helper to fetch only owner of hubDetails
    /// @param id Unique hub identifier
    /// @return Address of owner
    function getOwner(uint256 id) external view returns (address);

    /// @notice Helper to fetch only vault of hubDetails
    /// @param id Unique hub identifier
    /// @return Address of vault
    function getVault(uint256 id) external view returns (address);

    /// @notice Helper to fetch only curve of hubDetails
    /// @param id Unique hub identifier
    /// @return Address of curve
    function getCurve(uint256 id) external view returns (address);

    /// @notice Helper to fetch only refundRatio of hubDetails
    /// @param id Unique hub identifier
    /// @return uint Return refundRatio
    function getRefundRatio(uint256 id) external view returns (uint256);

    /// @notice TODO
    /// @param id Unique hub identifier
    /// @return bool is the hub active?
    function isActive(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVaultFactory {
    event Create(address vault);

    /// @notice function to create and register a new vault to the vault registry
    /// @param _token address of vault collateral asset
    /// @param _encodedAdditionalArgs Additional arguments passed to create a vault
    /// @return address of new vault
    function create(address _token, bytes memory _encodedAdditionalArgs)
        external
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVaultRegistry {
    event Register(address vault, address factory);
    event Deactivate(address vault);
    event Approve(address factory);
    event Unapprove(address factory);

    /// @notice add a vault to the vault registry
    /// @param _vault address of new vault
    function register(address _vault) external;

    /// @notice TODO
    /// @param _factory TODO
    function approve(address _factory) external;

    /// @notice TODO
    /// @param _factory TODO
    function unapprove(address _factory) external;

    /// @notice TODO
    /// @param _factory TODO
    /// @return TODO
    function isApproved(address _factory) external view returns (bool);

    /// @notice TODO
    /// @param _vault TODO
    function deactivate(address _vault) external;

    /// @notice TODO
    /// @param _vault TODO
    /// @return TODO
    function isActive(address _vault) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICurveRegistry {
    event Register(uint256 count, address curve);
    event Deactivate(uint256 curveId);

    /// @notice TODO
    /// @param curve TODO
    function register(address curve) external;

    /// @notice TODO
    /// @param curve TODO
    function deactivate(address curve) external;

    /// @notice TODO
    /// @param curve TODO
    /// @return bool
    function isActive(address curve) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Curve Interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all Curves
interface ICurve {
    event Updated(uint256 indexed hubId);

    /// @notice Given a hub, baseX, baseY and connector weight, add the configuration to the
    /// BancorZero ValueSet registry
    /// @dev ValueSet need to be encoded as the Hub may register ValueSets for different curves
    ///      that may contain different ValueSet arguments
    /// @param _hubId                   unique hub identifier
    /// @param _encodedValueSet     encoded ValueSet arguments
    function register(uint256 _hubId, bytes calldata _encodedValueSet) external;

    /// @notice TODO
    /// @param _hubId                   unique hub identifier
    /// @param _encodedValueSet     encoded target ValueSet arguments
    function registerTarget(uint256 _hubId, bytes calldata _encodedValueSet)
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

    function finishUpdate(uint256 id) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Details {
    struct MeTokenDetails {
        address owner;
        uint256 hubId;
        uint256 balancePooled;
        uint256 balanceLocked;
        bool updating; // TODO: validate
        uint256 startTime;
        uint256 endTime;
        uint256 targetHub;
    }

    struct HubDetails {
        bool active;
        address vault;
        address curve;
        uint256 refundRatio;
        bool updating;
        uint256 startTime;
        uint256 endTime;
        address migrationVault;
        address targetVault;
        bool curveDetails;
        address targetCurve;
        uint256 targetRefundRatio;
    }

    struct BancorDetails {
        uint256 baseY;
        uint32 reserveWeight;
        // bool updating;
        uint256 targetBaseY;
        uint32 targetReserveWeight;
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