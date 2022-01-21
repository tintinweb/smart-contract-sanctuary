// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IHub.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/IFoundry.sol";

import "./libs/Details.sol";

/// @title meToken hub
/// @author Carl Farterson (@carlfarterson)
/// @notice This contract tracks all combinations of vaults and curves,
///     and their respective subscribed meTokens
contract Hub is IHub, Ownable, Initializable {
    uint256 public constant MAX_REFUND_RATIO = 10**6;
    uint256 private _warmup;
    uint256 private _duration;
    uint256 private _cooldown;

    uint256 private _count;
    address public registerer;
    IFoundry public foundry;
    IRegistry public vaultRegistry;
    IRegistry public curveRegistry;

    mapping(uint256 => Details.Hub) private _hubs;

    modifier onlyRegisterer() {
        require(msg.sender == registerer, "!registerer");
        _;
    }

    function initialize(
        address _foundry,
        address _vaultRegistry,
        address _curveRegistry
    ) external onlyOwner initializer {
        foundry = IFoundry(_foundry);
        vaultRegistry = IRegistry(_vaultRegistry);
        curveRegistry = IRegistry(_curveRegistry);
        registerer = owner();
    }

    /// @inheritdoc IHub
    function register(
        address _owner,
        address _asset,
        IVault _vault,
        ICurve _curve,
        uint256 _refundRatio,
        bytes memory _encodedCurveDetails,
        bytes memory _encodedVaultArgs
    ) external override onlyRegisterer {
        // TODO: access control

        require(curveRegistry.isApproved(address(_curve)), "_curve !approved");
        require(vaultRegistry.isApproved(address(_vault)), "_vault !approved");
        require(_refundRatio < MAX_REFUND_RATIO, "_refundRatio > MAX");
        require(_refundRatio > 0, "_refundRatio == 0");

        // Ensure asset is valid based on encoded args and vault validation logic
        require(_vault.isValid(_asset, _encodedVaultArgs), "asset !valid");

        // Store value set base parameters to `{CurveName}.sol`
        _curve.register(++_count, _encodedCurveDetails);

        // Save the hub to the registry
        Details.Hub storage hub_ = _hubs[_count];
        hub_.active = true;
        hub_.owner = _owner;
        hub_.asset = _asset;
        hub_.vault = address(_vault);
        hub_.curve = address(_curve);
        hub_.refundRatio = _refundRatio;
        emit Register(
            _count,
            _owner,
            _asset,
            address(_vault),
            address(_curve),
            _refundRatio,
            _encodedCurveDetails,
            _encodedVaultArgs
        );
    }

    /// @inheritdoc IHub
    function deactivate(uint256 _id) external override {
        Details.Hub storage hub_ = _hubs[_id];
        require(msg.sender == hub_.owner, "!owner");
        require(hub_.active, "!active");
        hub_.active = false;
        emit Deactivate(_id);
    }

    /// @inheritdoc IHub
    function initUpdate(
        uint256 _id,
        address _targetCurve,
        uint256 _targetRefundRatio,
        bytes memory _encodedCurveDetails
    ) external override {
        Details.Hub storage hub_ = _hubs[_id];
        require(msg.sender == hub_.owner, "!owner");
        if (hub_.updating && block.timestamp > hub_.endTime) {
            finishUpdate(_id);
        }
        require(!hub_.updating, "already updating");
        require(block.timestamp >= hub_.endCooldown, "Still cooling down");
        // Make sure at least one of the values is different
        require(
            (_targetRefundRatio != 0) || (_encodedCurveDetails.length > 0),
            "Nothing to update"
        );

        if (_targetRefundRatio != 0) {
            require(
                _targetRefundRatio < MAX_REFUND_RATIO,
                "_targetRefundRatio >= MAX"
            );
            require(
                _targetRefundRatio != hub_.refundRatio,
                "_targetRefundRatio == refundRatio"
            );
            hub_.targetRefundRatio = _targetRefundRatio;
        }
        bool reconfigure;
        if (_encodedCurveDetails.length > 0) {
            if (_targetCurve == address(0)) {
                ICurve(hub_.curve).initReconfigure(_id, _encodedCurveDetails);
                reconfigure = true;
            } else {
                require(
                    curveRegistry.isApproved(_targetCurve),
                    "_targetCurve !approved"
                );
                require(_targetCurve != hub_.curve, "targetCurve==curve");
                ICurve(_targetCurve).register(_id, _encodedCurveDetails);
                hub_.targetCurve = _targetCurve;
            }
        }

        hub_.reconfigure = reconfigure;
        hub_.updating = true;
        hub_.startTime = block.timestamp + _warmup;
        hub_.endTime = block.timestamp + _warmup + _duration;
        hub_.endCooldown = block.timestamp + _warmup + _duration + _cooldown;

        emit InitUpdate(
            _id,
            _targetCurve,
            _targetRefundRatio,
            _encodedCurveDetails,
            reconfigure,
            hub_.startTime,
            hub_.endTime,
            hub_.endCooldown
        );
    }

    /// @inheritdoc IHub
    function cancelUpdate(uint256 _id) external override {
        Details.Hub storage hub_ = _hubs[_id];
        require(msg.sender == hub_.owner, "!owner");
        require(hub_.updating, "!updating");
        require(block.timestamp < hub_.startTime, "Update has started");

        hub_.targetRefundRatio = 0;
        hub_.reconfigure = false;
        hub_.targetCurve = address(0);
        hub_.updating = false;
        hub_.startTime = 0;
        hub_.endTime = 0;
        hub_.endCooldown = 0;

        emit CancelUpdate(_id);
    }

    function transferHubOwnership(uint256 _id, address _newOwner) external {
        Details.Hub storage hub_ = _hubs[_id];
        require(msg.sender == hub_.owner, "!owner");
        require(_newOwner != hub_.owner, "Same owner");
        hub_.owner = _newOwner;

        emit TransferHubOwnership(_id, _newOwner);
    }

    function setRegisterer(address _registerer) external onlyRegisterer {
        require(_registerer != registerer, "_registerer == registerer");
        registerer = _registerer;
    }

    /// @inheritdoc IHub
    function setWarmup(uint256 warmup_) external override onlyOwner {
        require(warmup_ != _warmup, "warmup_ == _warmup");
        _warmup = warmup_;
    }

    /// @inheritdoc IHub
    function setDuration(uint256 duration_) external override onlyOwner {
        require(duration_ != _duration, "duration_ == _duration");
        _duration = duration_;
    }

    /// @inheritdoc IHub
    function setCooldown(uint256 cooldown_) external override onlyOwner {
        require(cooldown_ != _cooldown, "cooldown_ == _cooldown");
        _cooldown = cooldown_;
    }

    /// @inheritdoc IHub
    function count() external view override returns (uint256) {
        return _count;
    }

    /// @inheritdoc IHub
    function getDetails(uint256 id)
        external
        view
        override
        returns (Details.Hub memory hub_)
    {
        hub_ = _hubs[id];
    }

    /// @inheritdoc IHub
    function warmup() external view override returns (uint256) {
        return _warmup;
    }

    /// @inheritdoc IHub
    function duration() external view override returns (uint256) {
        return _duration;
    }

    /// @inheritdoc IHub
    function cooldown() external view override returns (uint256) {
        return _cooldown;
    }

    /// @inheritdoc IHub
    function finishUpdate(uint256 id)
        public
        override
        returns (Details.Hub memory)
    {
        Details.Hub storage hub_ = _hubs[id];
        require(block.timestamp > hub_.endTime, "Still updating");

        if (hub_.targetRefundRatio != 0) {
            hub_.refundRatio = hub_.targetRefundRatio;
            hub_.targetRefundRatio = 0;
        }

        if (hub_.reconfigure) {
            ICurve(hub_.curve).finishReconfigure(id);
            hub_.reconfigure = false;
        }
        if (hub_.targetCurve != address(0)) {
            hub_.curve = hub_.targetCurve;
            hub_.targetCurve = address(0);
        }

        hub_.updating = false;
        hub_.startTime = 0;
        hub_.endTime = 0;

        emit FinishUpdate(id);
        return hub_;
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

import "./IVault.sol";
import "./ICurve.sol";
import "../libs/Details.sol";

/// @title MeTokens hub interface
/// @author Carl Farterson (@carlfarterson)
interface IHub {
    /// @notice Event of registering a hub
    /// @param _id                  unique hub identifer
    /// @param _owner               address to own hub
    /// @param _asset               address of underlying asset
    /// @param _vault               address of vault
    /// @param _curve               address of curve
    /// @param _refundRatio         rate to refund burners
    /// @param _encodedCurveDetails additional encoded curve details
    /// @param _encodedVaultArgs    additional encoded vault arguments
    event Register(
        uint256 _id,
        address _owner,
        address _asset,
        address _vault,
        address _curve,
        uint256 _refundRatio,
        bytes _encodedCurveDetails,
        bytes _encodedVaultArgs
    );

    /// @notice Event of making a hub inactive, preventing new subscriptions to the hub
    /// @param _id  unique hub identifier
    event Deactivate(uint256 _id);

    /// @notice Event of initializing a hub update
    /// @param _id                     unique hub identifier
    /// @param _targetCurve            address of target curve
    /// @param _targetRefundRatio      target rate to refund burners
    /// @param _encodedCurveDetails    additional encoded curve details
    /// @param _reconfigure            boolean to show if we're changing the
    ///                                 curveDetails but not the curve address
    /// @param _startTime              timestamp to start updating
    /// @param _endTime                timestamp to end updating
    /// @param _endCooldown            timestamp to allow another update
    event InitUpdate(
        uint256 _id,
        address _targetCurve,
        uint256 _targetRefundRatio,
        bytes _encodedCurveDetails,
        bool _reconfigure,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _endCooldown
    );

    /// @notice Event of canceling a hub update
    /// @param _id unique hub identifier
    event CancelUpdate(uint256 _id);

    /// @notice Event of transfering hub ownership
    /// @param _id          unique hub identifier
    /// @param _newOwner    address to own the hub
    event TransferHubOwnership(uint256 _id, address _newOwner);

    /// @notice Event of finishing a hub update
    /// @param _id unique hub identifier
    event FinishUpdate(uint256 _id);

    /// @notice Register a new hub
    /// @param _owner               address to own hub
    /// @param _asset               address of vault asset
    /// @param _vault               address of vault
    /// @param _curve               address of curve
    /// @param _refundRatio         rate to refund burners
    /// @param _encodedCurveDetails additional encoded curve details
    /// @param _encodedVaultArgs    additional encoded vault arguments
    function register(
        address _owner,
        address _asset,
        IVault _vault,
        ICurve _curve,
        uint256 _refundRatio,
        bytes memory _encodedCurveDetails,
        bytes memory _encodedVaultArgs
    ) external;

    function deactivate(uint256 _id) external;

    /// @notice Intialize a hub update
    /// @param _id                  unique hub identifier
    /// @param _targetCurve         address of target curve
    /// @param _targetRefundRatio   target rate to refund burners
    /// @param _encodedCurveDetails additional encoded curve details
    function initUpdate(
        uint256 _id,
        address _targetCurve,
        uint256 _targetRefundRatio,
        bytes memory _encodedCurveDetails
    ) external;

    /// @notice Cancel a hub update
    /// @dev Can only be called before _startTime
    /// @param _id unique hub identifier
    function cancelUpdate(uint256 _id) external;

    /// @notice Finish updating a hub
    /// @param _id  unique hub identifier
    /// @return     details of hub
    function finishUpdate(uint256 _id) external returns (Details.Hub memory);

    /// @notice Get the details of a hub
    /// @param _id  unique hub identifier
    /// @return     details of hub
    function getDetails(uint256 _id) external view returns (Details.Hub memory);

    /// @notice Counter of hubs registered
    /// @return uint256
    function count() external view returns (uint256);

    function warmup() external view returns (uint256);

    function setWarmup(uint256 warmup_) external;

    function duration() external view returns (uint256);

    function setDuration(uint256 duration_) external;

    function cooldown() external view returns (uint256);

    function setCooldown(uint256 cooldown_) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title generic vault interface
/// @author Carl Farterson (@carlfarterson)
abstract contract IVault {
    /// @notice Event when an asset is deposited to the vault
    /// @param _from            address which is depositing the asset
    /// @param _asset           address of asset
    /// @param _depositAmount   amount of assets deposited
    /// @param _feeAmount       amount of fees paid
    event HandleDeposit(
        address _from,
        address _asset,
        uint256 _depositAmount,
        uint256 _feeAmount
    );

    /// @notice Event when an asset is withdrawn from the vault
    /// @param _to                  address which will receive the asset
    /// @param _asset               address of asset
    /// @param _withdrawalAmount    amount of assets withdrawn
    /// @param _feeAmount           amount of fees paid
    event HandleWithdrawal(
        address _to,
        address _asset,
        uint256 _withdrawalAmount,
        uint256 _feeAmount
    );

    /// @notice Event when claiming the accrued fees of an asset
    /// @param _recipient   Recipient of the asset
    /// @param _asset       address of asset
    /// @param _amount      amount of asset
    event Claim(address _recipient, address _asset, uint256 _amount);

    /// @dev key: addr of asset, value: cumulative fees paid in the asset
    mapping(address => uint256) public accruedFees;

    /// @notice Claim the accrued fees of an asset
    /// @param _asset   address of asset
    /// @param _max     true if claiming all accrued fees of the asset, else false
    /// @param _amount  amount of asset to claim
    function claim(
        address _asset,
        bool _max,
        uint256 _amount
    ) external virtual;

    /// @notice Deposit an asset to the vault
    /// @param _from            address which is depositing the asset
    /// @param _asset           address of asset
    /// @param _depositAmount   amount of assets deposited
    /// @param _feeAmount       amount of fees paid
    function handleDeposit(
        address _from,
        address _asset,
        uint256 _depositAmount,
        uint256 _feeAmount
    ) external virtual;

    /// @notice Withdraw an asset from the vault
    /// @param _to                  address which will receive the asset
    /// @param _asset               address of asset
    /// @param _withdrawalAmount    amount of assets withdrawn
    function handleWithdrawal(
        address _to,
        address _asset,
        uint256 _withdrawalAmount,
        uint256 _feeAmount
    ) external virtual;

    /// @notice View to see if an asset with encoded arguments passed
    ///         when a vault is registered to a new hub
    /// @param _asset       address of asset
    /// @param _encodedArgs additional encoded arguments
    function isValid(address _asset, bytes memory _encodedArgs)
        external
        virtual
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title generic registry interface
/// @author Carl Farterson (@carlfarterson)
interface IRegistry {
    /// @notice Event of approving an address
    /// @param _addr address to approve
    event Approve(address _addr);

    /// @notice Event of unapproving an address
    /// @param _addr address to unapprove
    event Unapprove(address _addr);

    /// @notice Approve an address
    /// @param _addr address to approve
    function approve(address _addr) external;

    /// @notice Unapprove an address
    /// @param _addr address to unapprove
    function unapprove(address _addr) external;

    /// @notice View to see if an address is approved
    /// @param _addr address to view
    /// @return true if address is approved, else false
    function isApproved(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Generic Curve interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all Curves
interface ICurve {
    /// @notice Event when curveDetails are updated from target values to actual values
    event Updated(uint256 indexed _hubId);

    /// @notice Given a hub, baseX, baseY and connector weight, add the configuration to the
    /// BancorZero Curve registry
    /// @dev Curve need to be encoded as the Hub may register Curves for different curves
    ///      that may contain different Curve arguments
    /// @param _hubId           unique hub identifier
    /// @param _encodedDetails  encoded Curve arguments
    function register(uint256 _hubId, bytes calldata _encodedDetails) external;

    /// @notice Initialize reconfiguring curveDetails for a hub
    /// @param _hubId           unique hub identifier
    /// @param _encodedDetails  encoded target Curve arguments
    function initReconfigure(uint256 _hubId, bytes calldata _encodedDetails)
        external;

    /// @notice Finish reconfiguring curveDetails for a hub
    /// @param _hubId uinque hub identifier
    function finishReconfigure(uint256 _hubId) external;

    /// @notice Get curveDetails for a hub
    /// @return curveDetails (TODO: curve w/ more than 4 curveDetails)
    function getDetails(uint256 _hubId)
        external
        view
        returns (uint256[4] memory);

    /// @notice Calculate meTokens minted based on a curve's active details
    /// @param _assetsDeposited Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return meTokensMinted  amount of MeTokens minted
    function viewMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    /// @notice Calculate assets returned based on a curve's active details
    /// @param _meTokensBurned  Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return assetsReturned  amount of assets returned
    function viewAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);

    /// @notice Calculate meTokens minted based on a curve's target details
    /// @param _assetsDeposited Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return meTokensMinted  amount of MeTokens minted
    function viewTargetMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    /// @notice Calculate assets returned based on a curve's target details
    /// @param _meTokensBurned  Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return assetsReturned  amount of assets returned
    function viewTargetAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title MeTokens foundry interface
/// @author Carl Farterson (@carlfarterson)
interface IFoundry {
    /// @notice Event of minting a meToken
    /// @param _meToken         address of meToken minted
    /// @param _asset           address of asset deposited
    /// @param _depositor       address to deposit asset
    /// @param _recipient       address to receive minted meTokens
    /// @param _assetsDeposited amount of assets deposited
    /// @param _meTokensMinted  amount of meTokens minted
    event Mint(
        address _meToken,
        address _asset,
        address _depositor,
        address _recipient,
        uint256 _assetsDeposited,
        uint256 _meTokensMinted
    );

    /// @notice Event of burning a meToken
    /// @param _meToken         address of meToken burned
    /// @param _asset           address of asset returned
    /// @param _burner          address to burn meTokens
    /// @param _recipient       address to receive underlying asset
    /// @param _meTokensBurned  amount of meTokens to burn
    /// @param _assetsReturned  amount of assets
    event Burn(
        address _meToken,
        address _asset,
        address _burner,
        address _recipient,
        uint256 _meTokensBurned,
        uint256 _assetsReturned
    );

    /// @notice Mint a meToken by depositing the underlying asset
    /// @param _meToken         address of meToken to mint
    /// @param _assetsDeposited amount of assets to deposit
    /// @param _recipient       address to receive minted meTokens
    function mint(
        address _meToken,
        uint256 _assetsDeposited,
        address _recipient
    ) external;

    /// @notice Burn a meToken to receive the underlying asset
    /// @param _meToken         address of meToken to burn
    /// @param _meTokensBurned  amount of meTokens to burn
    /// @param _recipient       address to receive the underlying assets
    function burn(
        address _meToken,
        uint256 _meTokensBurned,
        address _recipient
    ) external;
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
        address owner;
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