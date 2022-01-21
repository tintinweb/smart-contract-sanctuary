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

    /// @dev key: address of meToken, value: meToken Details struct
    mapping(address => Details.MeToken) private _meTokens;
    /// @dev key: address of meToken owner, value: address of meToken
    mapping(address => address) private _owners;
    /// @dev key: address of meToken owner, value: address to transfer meToken ownership to
    mapping(address => address) private _pendingOwners;

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
        }

        // Create meToken erc20 contract
        address meTokenAddr = meTokenFactory.create(
            _name,
            _symbol,
            foundry,
            address(this)
        );

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
        require(targetHub_.active, "targetHub inactive");
        require(!hub_.updating, "hub updating");
        require(!targetHub_.updating, "targetHub updating");

        // TODO: what if asset is same?  Is a migration vault needed since it'll start/end
        // at the same and not change to a different asset?
        require(hub_.asset != targetHub_.asset, "asset same");
        require(_migration != address(0), "migration address(0)");

        // Ensure the migration we're using is approved
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
        IMigration(_migration).initMigration(_meToken, _encodedMigrationArgs);

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

    function cancelResubscribe(address _meToken) external override {
        Details.MeToken storage meToken_ = _meTokens[_meToken];
        require(msg.sender == meToken_.owner, "!owner");
        require(meToken_.targetHubId != 0, "!resubscribing");
        require(
            block.timestamp < meToken_.startTime,
            "Resubscription has started"
        );

        meToken_.startTime = 0;
        meToken_.endTime = 0;
        meToken_.targetHubId = 0;
        meToken_.migration = address(0);

        emit CancelResubscribe(_meToken);
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

        meToken_.balancePooled =
            (meToken_.balancePooled * (PRECISION * _newBalance)) /
            (oldBalance * PRECISION);
        meToken_.balanceLocked =
            (meToken_.balanceLocked * PRECISION * _newBalance) /
            (oldBalance * PRECISION);

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
        require(
            _pendingOwners[msg.sender] == address(0),
            "transfer ownership already pending"
        );
        require(!isOwner(_newOwner), "_newOwner already owns a meToken");
        require(_newOwner != address(0), "Cannot transfer to 0 address");
        address meToken_ = _owners[msg.sender];
        require(meToken_ != address(0), "meToken does not exist");
        _pendingOwners[msg.sender] = _newOwner;

        emit TransferMeTokenOwnership(msg.sender, _newOwner, meToken_);
    }

    /// @inheritdoc IMeTokenRegistry
    function cancelTransferMeTokenOwnership() external override {
        address _meToken = _owners[msg.sender];
        require(_meToken != address(0), "meToken does not exist");

        require(
            _pendingOwners[msg.sender] != address(0),
            "transferMeTokenOwnership() not initiated"
        );

        delete _pendingOwners[msg.sender];
        emit CancelTransferMeTokenOwnership(msg.sender, _meToken);
    }

    /// @inheritdoc IMeTokenRegistry
    function claimMeTokenOwnership(address _oldOwner) external override {
        require(!isOwner(msg.sender), "Already owns a meToken");
        require(msg.sender == _pendingOwners[_oldOwner], "!_pendingOwner");

        address _meToken = _owners[_oldOwner];
        Details.MeToken storage meToken_ = _meTokens[_meToken];

        meToken_.owner = msg.sender;
        _owners[msg.sender] = _meToken;

        delete _owners[_oldOwner];
        delete _pendingOwners[_oldOwner];

        emit ClaimMeTokenOwnership(_oldOwner, msg.sender, _meToken);
    }

    function setWarmup(uint256 warmup_) external onlyOwner {
        require(warmup_ != _warmup, "warmup_ == _warmup");
        require(warmup_ + _duration < hub.warmup(), "too long");
        _warmup = warmup_;
    }

    function setDuration(uint256 duration_) external onlyOwner {
        require(duration_ != _duration, "duration_ == _duration");
        require(duration_ + _warmup < hub.warmup(), "too long");
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
    function getPendingOwner(address _oldOwner)
        external
        view
        override
        returns (address)
    {
        return _pendingOwners[_oldOwner];
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

    function warmup() external view returns (uint256) {
        return _warmup;
    }

    function duration() external view returns (uint256) {
        return _duration;
    }

    function cooldown() external view returns (uint256) {
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

/// @title meToken
/// @author Carl Farterson (@carlfarterson)
/// @notice Base erc20-like meToken contract used for all meTokens
contract MeToken is ERC20Burnable {
    string public version;
    address public foundry;
    address public meTokenRegistry;

    constructor(
        string memory _name,
        string memory _symbol,
        address _foundry,
        address _meTokenRegistry
    ) ERC20(_name, _symbol) {
        version = "0.2";
        foundry = _foundry;
        meTokenRegistry = _meTokenRegistry;
    }

    function mint(address to, uint256 amount) external {
        require(
            msg.sender == foundry || msg.sender == meTokenRegistry,
            "!authorized"
        );
        _mint(to, amount);
    }

    function burn(address from, uint256 value) external {
        require(
            msg.sender == foundry || msg.sender == meTokenRegistry,
            "!authorized"
        );
        _burn(from, value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Generic migration vault interface
/// @author Carl Farterson (@carlfarterson)
interface IMigration {
    /// @notice Method to trigger actions from the migration vault if needed
    /// @param _meToken address of meToken
    function poke(address _meToken) external;

    /// @notice Method called when a meToken starts resubscribing to a new hub
    /// @dev This is called within meTokenRegistry.initResubscribe()
    /// @param _meToken     address of meToken
    /// @param _encodedArgs additional encoded arguments
    function initMigration(address _meToken, bytes memory _encodedArgs)
        external;

    /// @notice Method to send assets from migration vault to the vault of the
    ///         target hub
    /// @param _meToken address of meToken
    function finishMigration(address _meToken) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title meToken migration registry interface
/// @author Carl Farterson (@carlfarterson)
interface IMigrationRegistry {
    /// @notice Event of approving a meToken migration route
    /// @param _initialVault    vault for meToken to start migration from
    /// @param _targetVault     vault for meToken to migrate to
    /// @param _migration       address of migration vault
    event Approve(
        address _initialVault,
        address _targetVault,
        address _migration
    );

    /// @notice Event of unapproving a meToken migration route
    /// @param _initialVault    vault for meToken to start migration from
    /// @param _targetVault     vault for meToken to migrate to
    /// @param _migration       address of migration vault
    event Unapprove(
        address _initialVault,
        address _targetVault,
        address _migration
    );

    /// @notice Approve a vault migration route
    /// @param _initialVault    vault for meToken to start migration from
    /// @param _targetVault     vault for meToken to migrate to
    /// @param _migration       address of migration vault
    function approve(
        address _initialVault,
        address _targetVault,
        address _migration
    ) external;

    /// @notice Unapprove a vault migration route
    /// @param _initialVault    vault for meToken to start migration from
    /// @param _targetVault     vault for meToken to migrate to
    /// @param _migration       address of migration vault
    function unapprove(
        address _initialVault,
        address _targetVault,
        address _migration
    ) external;

    /// @notice View to see if a specific migration route is approved
    /// @param _initialVault    vault for meToken to start migration from
    /// @param _targetVault     vault for meToken to migrate to
    /// @param _migration       address of migration vault
    /// @return true if migration route is approved, else false
    function isApproved(
        address _initialVault,
        address _targetVault,
        address _migration
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libs/Details.sol";

/// @title meToken registry interface
/// @author Carl Farterson (@carlfarterson)
interface IMeTokenRegistry {
    /// @notice Event of subscribing (creating) a new meToken
    /// @param _meToken         address of created meToken
    /// @param _owner           address of meToken owner
    /// @param _minted          amount of meToken minted to owner
    /// @param _asset           address of underlying asset
    /// @param _assetsDeposited amount of assets deposited
    /// @param _name            name of meToken
    /// @param _symbol          symbol of meToken
    /// @param _hubId           unique hub identifier
    event Subscribe(
        address indexed _meToken,
        address indexed _owner,
        uint256 _minted,
        address _asset,
        uint256 _assetsDeposited,
        string _name,
        string _symbol,
        uint256 _hubId
    );

    /// @notice Event of initializing a meToken subscription to a different hub
    /// @param _meToken                 address of meToken
    /// @param _targetHubId             target hub to suscribe to
    /// @param _migration               address of migration vault
    /// @param _encodedMigrationArgs    additional encoded migration vault arguments
    event InitResubscribe(
        address indexed _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes _encodedMigrationArgs
    );
    /// @notice Event of canceling a meToken resubscription
    /// @param _meToken address of meToken
    event CancelResubscribe(address indexed _meToken);

    /// @notice Event of finishing a meToken resubscription
    /// @param _meToken address of meToken
    event FinishResubscribe(address indexed _meToken);

    /// @notice Event of updating a meToken's balancePooled and balanceLocked
    /// @param _meToken     address of meToken
    /// @param _newBalance  rate to multiply balances by
    event UpdateBalances(address _meToken, uint256 _newBalance);

    /// @notice Event of transfering meToken ownership to a new owner
    /// @param _from    address of current meToken owner
    /// @param _to      address to own the meToken
    /// @param _meToken address of meToken
    event TransferMeTokenOwnership(
        address _from,
        address _to,
        address _meToken
    );

    /// @notice Event of cancelling the transfer of meToken ownership
    /// @param _from    address of current meToken owner
    /// @param _meToken address of meToken
    event CancelTransferMeTokenOwnership(address _from, address _meToken);

    /// @notice Event of claiming the transfer of meToken ownership
    /// @param _from    address of current meToken owner
    /// @param _to      address to own the meToken
    /// @param _meToken address of meToken
    event ClaimMeTokenOwnership(address _from, address _to, address _meToken);

    /// @notice Event of updating a meToken's balancePooled
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    event UpdateBalancePooled(bool _add, address _meToken, uint256 _amount);

    /// @notice Event of updating a meToken's balanceLocked
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    event UpdateBalanceLocked(bool _add, address _meToken, uint256 _amount);

    /// @notice Create and subscribe a meToken to a hub
    /// @param _name            name of meToken
    /// @param _symbol          symbol of meToken
    /// @param _hubId           initial hub to subscribe to
    /// @param _assetsDeposited amount of assets deposited at meToken initialization
    function subscribe(
        string calldata _name,
        string calldata _symbol,
        uint256 _hubId,
        uint256 _assetsDeposited
    ) external;

    /// @notice Initialize a meToken resubscription to a new hub
    /// @param _meToken                 address of meToken
    /// @param _targetHubId             hub which meToken is resubscribing to
    /// @param _migration               address of migration vault
    /// @param _encodedMigrationArgs    additional encoded migration vault arguments
    function initResubscribe(
        address _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes memory _encodedMigrationArgs
    ) external;

    /// @notice Cancel a meToken resubscription
    /// @dev can only be done during the warmup period
    /// @param _meToken address of meToken
    function cancelResubscribe(address _meToken) external;

    /// @notice Finish a meToken's resubscription to a new hub
    /// @param _meToken address of meToken
    /// @return details of meToken
    function finishResubscribe(address _meToken)
        external
        returns (Details.MeToken memory);

    /// @notice Update a meToken's balanceLocked and balancePooled
    /// @param _meToken     address of meToken
    /// @param _newBalance  rate to multiply balances by
    function updateBalances(address _meToken, uint256 _newBalance) external;

    /// @notice Update a meToken's balancePooled
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    function updateBalancePooled(
        bool _add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice Update a meToken's balanceLocked
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    function updateBalanceLocked(
        bool _add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice Transfer meToken ownership to a new owner
    /// @param _newOwner address to claim meToken ownership of msg.sender
    function transferMeTokenOwnership(address _newOwner) external;

    /// @notice Cancel the transfer of meToken ownership
    function cancelTransferMeTokenOwnership() external;

    /// @notice Claim the transfer of meToken ownership
    /// @param _from address of current meToken owner
    function claimMeTokenOwnership(address _from) external;

    /// @notice View to return address of meToken owned by _owner
    /// @param _owner   address of meToken owner
    /// @return         address of meToken
    function getOwnerMeToken(address _owner) external view returns (address);

    /// @notice View to see the address to claim meToken ownership from _from
    /// @param _from    address to transfer meToken ownership
    /// @return         address of pending meToken owner
    function getPendingOwner(address _from) external view returns (address);

    /// @notice View to get details of a meToken
    /// @param meToken      address of meToken queried
    /// @return meToken_    details of meToken
    function getDetails(address meToken)
        external
        view
        returns (Details.MeToken memory meToken_);

    /// @notice View to return if an address owns a meToken or not
    /// @param _owner   address to query
    /// @return         true if owns a meToken, else false
    function isOwner(address _owner) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title meToken factory interface
/// @author Carl Farterson (@carlfarterson)
interface IMeTokenFactory {
    /// @notice Create a meToken
    /// @param _name            name of meToken
    /// @param _symbol          symbol of meToken
    /// @param _foundry         address of foundry
    /// @param _meTokenRegistry address of meTokenRegistry
    function create(
        string calldata _name,
        string calldata _symbol,
        address _foundry,
        address _meTokenRegistry
    ) external returns (address);
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

/// @title meToken interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all meTokens
interface IMeToken {
    // TODO: are these needed, or can we do IERC20?
    function initialize(
        string calldata name,
        address owner,
        string calldata symbol
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
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