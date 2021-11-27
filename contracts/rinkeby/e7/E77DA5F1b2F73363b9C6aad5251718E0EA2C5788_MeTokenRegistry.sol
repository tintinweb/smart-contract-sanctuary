// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../MeToken.sol";

import "../interfaces/IMigration.sol";
import "../interfaces/IMigrationRegistry.sol";
import "../interfaces/IMeTokenRegistry.sol";
import "../interfaces/IMeTokenFactory.sol";
import "../interfaces/IHub.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IMeToken.sol";

import "../libs/Details.sol";

/// @title meToken registry
/// @author Carl Farterson (@carlfarterson)
/// @notice This contract tracks basic information about all meTokens
contract MeTokenRegistry is Ownable, IMeTokenRegistry {
    uint256 public constant PRECISION = 10**18;
    uint256 private _warmup;
    uint256 private _duration;
    uint256 private _cooldown;

    address public foundry;
    IHub public hub;
    IMeTokenFactory public meTokenFactory;
    IMigrationRegistry public migrationRegistry;

    mapping(address => Details.MeToken) private _meTokens; // key pair: ERC20 address
    mapping(address => address) private _owners; // key: address of owner, value: address of meToken

    constructor(
        address _foundry,
        IHub _hub,
        IMeTokenFactory _meTokenFactory,
        IMigrationRegistry _migrationRegistry
    ) {
        foundry = _foundry;
        hub = _hub;
        meTokenFactory = _meTokenFactory;
        migrationRegistry = _migrationRegistry;
    }

    /// @inheritdoc IMeTokenRegistry
    function subscribe(
        string calldata _name,
        string calldata _symbol,
        uint256 _hubId,
        uint256 _assetsDeposited
    ) external override {
        // TODO: access control
        require(!isOwner(msg.sender), "msg.sender already owns a meToken");
        Details.Hub memory hub_ = hub.getDetails(_hubId);
        require(hub_.active, "Hub inactive");
        require(!hub_.updating, "Hub updating");

        if (_assetsDeposited > 0) {
            require(
                IERC20(hub_.asset).transferFrom(
                    msg.sender,
                    hub_.vault,
                    _assetsDeposited
                ),
                "transfer failed"
            );
            // we need to approve asset otherwise burning can't transfer the asset
            IVault(hub_.vault).approveAsset(hub_.asset, _assetsDeposited);
        }

        // Create meToken erc20 contract
        address meTokenAddr = meTokenFactory.create(_name, _symbol);

        // Mint meToken to user
        uint256 _meTokensMinted;
        if (_assetsDeposited > 0) {
            _meTokensMinted = ICurve(hub_.curve).viewMeTokensMinted(
                _assetsDeposited, // _deposit_amount
                _hubId, // _hubId
                0, // _supply
                0 // _balancePooled
            );
            IMeToken(meTokenAddr).mint(msg.sender, _meTokensMinted);
        }

        // Register the address which created a meToken
        _owners[msg.sender] = meTokenAddr;

        // Add meToken to registry
        Details.MeToken storage meToken_ = _meTokens[meTokenAddr];
        meToken_.owner = msg.sender;
        meToken_.hubId = _hubId;
        meToken_.balancePooled = _assetsDeposited;

        emit Subscribe(
            meTokenAddr,
            msg.sender,
            _meTokensMinted,
            hub_.asset,
            _assetsDeposited,
            _name,
            _symbol,
            _hubId
        );
    }

    /// @inheritdoc IMeTokenRegistry
    function initResubscribe(
        address _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes memory _encodedMigrationArgs
    ) external override {
        Details.MeToken storage meToken_ = _meTokens[_meToken];
        Details.Hub memory hub_ = hub.getDetails(meToken_.hubId);
        Details.Hub memory targetHub_ = hub.getDetails(_targetHubId);

        require(msg.sender == meToken_.owner, "!owner");
        require(
            block.timestamp >= meToken_.endCooldown,
            "Cooldown not complete"
        );
        require(meToken_.hubId != _targetHubId, "same hub");
        require(hub_.active, "hub inactive");
        require(targetHub_.active, "targetHub inactive");
        require(!hub_.updating, "hub updating");
        require(!targetHub_.updating, "targetHub updating");

        // Ensure the migration we're using is approved
        if (hub_.asset != targetHub_.asset || _migration != address(0)) {
            require(
                migrationRegistry.isApproved(
                    hub_.vault,
                    targetHub_.vault,
                    _migration
                ),
                "!approved"
            );
            require(
                IVault(_migration).isValid(_meToken, _encodedMigrationArgs),
                "Invalid _encodedMigrationArgs"
            );
            IMigration(_migration).initMigration(
                _meToken,
                _encodedMigrationArgs
            );
        }

        meToken_.startTime = block.timestamp + _warmup;
        meToken_.endTime = block.timestamp + _warmup + _duration;
        meToken_.endCooldown =
            block.timestamp +
            _warmup +
            _duration +
            _cooldown;
        meToken_.targetHubId = _targetHubId;
        meToken_.migration = _migration;

        emit InitResubscribe(
            _meToken,
            _targetHubId,
            _migration,
            _encodedMigrationArgs
        );
    }

    /// @inheritdoc IMeTokenRegistry
    function finishResubscribe(address _meToken)
        external
        override
        returns (Details.MeToken memory)
    {
        Details.MeToken storage meToken_ = _meTokens[_meToken];

        require(meToken_.targetHubId != 0, "No targetHubId");
        require(
            block.timestamp > meToken_.endTime,
            "block.timestamp < endTime"
        );
        // Update balancePooled / balanceLocked
        // solhint-disable-next-line
        uint256 newBalance = IMigration(meToken_.migration).finishMigration(
            _meToken
        );

        // Finish updating metoken details
        meToken_.startTime = 0;
        meToken_.endTime = 0;
        meToken_.hubId = meToken_.targetHubId;
        meToken_.targetHubId = 0;
        meToken_.migration = address(0);

        emit FinishResubscribe(_meToken);
        return meToken_;
    }

    /// @inheritdoc IMeTokenRegistry
    function updateBalances(address _meToken, uint256 _newBalance)
        external
        override
    {
        Details.MeToken storage meToken_ = _meTokens[_meToken];
        require(msg.sender == meToken_.migration, "!migration");

        uint256 oldBalance = meToken_.balancePooled + meToken_.balanceLocked;
        meToken_.balancePooled *=
            (PRECISION * _newBalance) /
            oldBalance /
            PRECISION;
        meToken_.balanceLocked *=
            (PRECISION * _newBalance) /
            oldBalance /
            PRECISION;

        emit UpdateBalances(_meToken, _newBalance);
    }

    /// @inheritdoc IMeTokenRegistry
    function updateBalancePooled(
        bool add,
        address _meToken,
        uint256 _amount
    ) external override {
        require(msg.sender == foundry, "!foundry");
        Details.MeToken storage meToken_ = _meTokens[_meToken];
        if (add) {
            meToken_.balancePooled += _amount;
        } else {
            meToken_.balancePooled -= _amount;
        }

        emit UpdateBalancePooled(add, _meToken, _amount);
    }

    /// @inheritdoc IMeTokenRegistry
    function updateBalanceLocked(
        bool add,
        address _meToken,
        uint256 _amount
    ) external override {
        require(msg.sender == foundry, "!foundry");
        Details.MeToken storage meToken_ = _meTokens[_meToken];

        if (add) {
            meToken_.balanceLocked += _amount;
        } else {
            meToken_.balanceLocked -= _amount;
        }

        emit UpdateBalanceLocked(add, _meToken, _amount);
    }

    /// @inheritdoc IMeTokenRegistry
    function transferMeTokenOwnership(address _newOwner) external override {
        require(!isOwner(_newOwner), "_newOwner already owns a meToken");

        // TODO: what happens if multiple people want to revoke ownership to 0 address?
        address _meToken = _owners[msg.sender];

        require(_meToken != address(0), "!meToken");
        Details.MeToken storage meToken_ = _meTokens[_meToken];
        meToken_.owner = _newOwner;
        _owners[msg.sender] = address(0);
        _owners[_newOwner] = _meToken;

        emit TransferMeTokenOwnership(msg.sender, _newOwner, _meToken);
    }

    function setWarmup(uint256 warmup_) external onlyOwner {
        require(warmup_ != _warmup, "warmup_ == _warmup");
        require(warmup_ + _duration < hub.getWarmup(), "too long");
        _warmup = warmup_;
    }

    function setDuration(uint256 duration_) external onlyOwner {
        require(duration_ != _duration, "duration_ == _duration");
        require(duration_ + _warmup < hub.getWarmup(), "too long");
        _duration = duration_;
    }

    function setCooldown(uint256 cooldown_) external onlyOwner {
        require(cooldown_ != _cooldown, "cooldown_ == _cooldown");
        _cooldown = cooldown_;
    }

    /// @inheritdoc IMeTokenRegistry
    function getOwnerMeToken(address _owner)
        external
        view
        override
        returns (address)
    {
        return _owners[_owner];
    }

    /// @inheritdoc IMeTokenRegistry
    function getDetails(address _meToken)
        external
        view
        override
        returns (Details.MeToken memory meToken_)
    {
        meToken_ = _meTokens[_meToken];
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

    /// @inheritdoc IMeTokenRegistry
    function isOwner(address _owner) public view override returns (bool) {
        return _owners[_owner] != address(0);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./Roles.sol";

/// @title meToken
/// @author Carl Farterson (@carlfarterson)
/// @notice Base erc20-like meToken contract used for all meTokens
contract MeToken is Initializable, ERC20Burnable {
    string public version;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        version = "0.2";
    }

    function mint(address to, uint256 amount) external {
        /*  require(
            hasRole(FOUNDRY, msg.sender) ||
                hasRole(METOKEN_REGISTRY, msg.sender)
        ); */
        _mint(to, amount);
    }

    function burn(address from, uint256 value) external {
        /*  require(
            hasRole(FOUNDRY, msg.sender) ||
                hasRole(METOKEN_REGISTRY, msg.sender)
        ); */
        _burn(from, value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMigration {
    function poke(address _meToken) external;

    function initMigration(address _meToken, bytes memory _encodedArgs)
        external;

    function finishMigration(address _meToken) external returns (uint256);

    // function isReady() external view returns (bool);
    // function hasFinished() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMigrationRegistry {
    event Approve(address initialVault, address targetVault, address migration);
    event Unapprove(
        address initialVault,
        address targetVault,
        address migration
    );

    /// @notice TODO
    /// @param initialVault TODO
    /// @param targetVault TODO
    /// @param migration TODO
    function unapprove(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice TODO
    /// @param initialVault) TODO
    /// @param targetVault TODO
    /// @param migration TODO
    function approve(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice TODO
    /// @param initialVault TODO
    /// @param targetVault TODO
    /// @param migration TODO
    /// @return bool status of factory
    function isApproved(
        address initialVault,
        address targetVault,
        address migration
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libs/Details.sol";

interface IMeTokenRegistry {
    event Subscribe(
        address indexed _meToken,
        address indexed _owner,
        uint256 _minted,
        address _collateralToken,
        uint256 _collateralDeposited,
        string _name,
        string _symbol,
        uint256 _hubId
    );
    event InitResubscribe(
        address indexed _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes _encodedMigrationArgs
    );
    event FinishResubscribe(address indexed _meToken);
    event UpdateBalances(address _meToken, uint256 _newBalance);
    event TransferMeTokenOwnership(
        address _from,
        address _to,
        address _meToken
    );
    event UpdateBalancePooled(bool add, address _meToken, uint256 _amount);
    event UpdateBalanceLocked(bool add, address _meToken, uint256 _amount);

    /// @notice TODO
    /// @param _name TODO
    /// @param _symbol TODO
    /// @param _hubId TODO
    /// @param _assetsDeposited TODO
    function subscribe(
        string calldata _name,
        string calldata _symbol,
        uint256 _hubId,
        uint256 _assetsDeposited
    ) external;

    /// @notice TODO
    /// @param _meToken TODO
    /// @param _targetHubId TODO
    /// @param _migration TODO
    /// @param _encodedMigrationArgs TODO
    function initResubscribe(
        address _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes memory _encodedMigrationArgs
    ) external;

    /// @notice TODO
    /// @param _meToken TODO
    /// @return TODO
    function finishResubscribe(address _meToken)
        external
        returns (Details.MeToken memory);

    /// @notice TODO
    /// @param _meToken TODO
    /// @param _newBalance TODO
    function updateBalances(address _meToken, uint256 _newBalance) external;

    /// @notice TODO
    /// @param add TODO
    /// @param _meToken TODO
    /// @param _amount TODO
    function updateBalancePooled(
        bool add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice TODO
    /// @param add TODO
    /// @param _meToken TODO
    /// @param _amount TODO
    function updateBalanceLocked(
        bool add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice TODO
    /// @param _newOwner TODO
    function transferMeTokenOwnership(address _newOwner) external;

    /// @notice TODO
    /// @param _owner TODO
    /// @return TODO
    function getOwnerMeToken(address _owner) external view returns (address);

    /// @notice TODO
    /// @param meToken Address of meToken queried
    /// @return meToken_ details of the meToken
    function getDetails(address meToken)
        external
        view
        returns (Details.MeToken memory meToken_);

    /// @notice TODO
    /// @param _owner TODO
    /// @return TODO
    function isOwner(address _owner) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMeTokenFactory {
    function create(string calldata name, string calldata symbol)
        external
        returns (address);
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
    event Withdraw(address _asset, uint256 _amount);
    event AddFee(address _asset, uint256 _amount);

    function withdraw(
        address _asset,
        bool _max,
        uint256 _amount
    ) external;

    function approveAsset(address _asset, uint256 _amount) external;

    function isValid(address _asset, bytes memory _encodedArgs)
        external
        returns (bool);

    function addFee(address _meToken, uint256 _amount) external;

    function getAccruedFees(address _asset) external view returns (uint256);
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

    function viewMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    function viewAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);

    function viewTargetMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    function viewTargetAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);

    function viewAssetsDeposited(
        uint256 _desiredMeTokensMinted,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsDeposited);

    function viewTargetAssetsDeposited(
        uint256 _desiredMeTokensMinted,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsDeposited);

    function finishReconfigure(uint256 id) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMeToken {
    function initialize(
        string calldata name,
        address owner,
        string calldata symbol
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function canMigrate() external view returns (bool);

    function switchUpdating() external returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {
    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    bytes32 public constant DAO_MULTISIG = keccak256("DAO_MULTISIG");
    bytes32 public constant DEV_MULTISIG = keccak256("DEV_MULTISIG");
    bytes32 public constant FOUNDRY = keccak256("FOUNDRY");
    bytes32 public constant METOKEN_REGISTRY = keccak256("METOKEN_REGISTRY");

    // address public constant devMultisig = address(0); // TODO
    // address public constant daoMultisig = address(0); // TODO
    address public foundry;
    address public meTokenRegistry;

    constructor() {
        _setupRole(DEVELOPER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(DAO_MULTISIG, daoMultisig);
        // _setupRole(DEV_MULTISIG, devMultisig);
        _setupRole(FOUNDRY, foundry);
        _setupRole(METOKEN_REGISTRY, meTokenRegistry);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}