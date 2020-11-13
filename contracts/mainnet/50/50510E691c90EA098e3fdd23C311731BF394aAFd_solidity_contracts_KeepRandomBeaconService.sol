/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/Proxy.sol";

/// @title Keep Random Beacon service
/// @notice A proxy contract to provide upgradable Random Beacon functionality.
/// All calls to this proxy contract are delegated to the implementation contract.
contract KeepRandomBeaconService is Proxy {
    using SafeMath for uint256;

    /// @dev Storage slot with the admin of the contract.
    /// This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
    /// It is validated in the constructor.
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @dev Storage slot with the address of the current implementation.
    /// This is the keccak-256 hash of "eip1967.proxy.implementation"
    /// subtracted by 1. It is validated in the constructor.
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Storage slot with the upgrade time delay. Upgrade time delay
    /// defines a period for implementation upgrade. This is the keccak-256
    /// hash of "network.keep.randombeacon.proxy.upgradeTimeDelay"
    /// subtracted by 1. It is validated in the constructor.
    bytes32 internal constant UPGRADE_TIME_DELAY_SLOT = 0x73bbd307af06a74c12a4f925288c98f759a1ee8fee7eae47a0c215cb63ef2c6b;

    /// @dev Storage slot with the new implementation address. This is the
    /// keccak-256 hash of "network.keep.randombeacon.proxy.upgradeImplementation"
    /// subtracted by 1. It is validated in the constructor.
    bytes32 internal constant UPGRADE_IMPLEMENTATION_SLOT = 0x3c3c1acab6a17c8ef7a1d07995c8ed2942488afd9e13cf89bd5c6e4828160276;

    /// @dev Storage slot with the implementation address upgrade initiation.
    /// This is the keccak-256 hash of "network.keep.randombeacon.proxy.upgradeInitiatedTimestamp"
    /// subtracted by 1. It is validated in the constructor.
    bytes32 internal constant UPGRADE_INIT_TIMESTAMP_SLOT = 0xb49edbaf3913780c2ef1ff781deec1eb653eab7236ff107428d60052d0f0d18d;

    /// @notice Implementation initialization data to be used on the second step
    /// of upgrade.
    /// @dev Mapping is stored at the position calculated with keccak256 of the
    /// new implementation address. Hence, it should be protected from clashing
    /// with implementation's fields.
    mapping(address => bytes) public initializationData;

    event UpgradeStarted(address implementation, uint256 timestamp);
    event UpgradeCompleted(address implementation);

    constructor(address _implementation, bytes memory _data) public {
        assertSlot(IMPLEMENTATION_SLOT, "eip1967.proxy.implementation");
        assertSlot(ADMIN_SLOT, "eip1967.proxy.admin");
        assertSlot(UPGRADE_TIME_DELAY_SLOT, "network.keep.randombeacon.proxy.upgradeTimeDelay");
        assertSlot(UPGRADE_IMPLEMENTATION_SLOT, "network.keep.randombeacon.proxy.upgradeImplementation");
        assertSlot(UPGRADE_INIT_TIMESTAMP_SLOT, "network.keep.randombeacon.proxy.upgradeInitiatedTimestamp");

        require(
            _implementation != address(0),
            "Implementation address can't be zero."
        );

        if (_data.length > 0) {
            initializeImplementation(_implementation, _data);
        }

        setImplementation(_implementation);

        setUpgradeTimeDelay(1 days);

        setAdmin(msg.sender);
    }

    /// @notice Starts upgrade of the current vendor implementation.
    /// @dev It is the first part of the two-step implementation address update
    /// process. The function emits an event containing the new value and current
    /// block timestamp.
    /// @param _newImplementation Address of the new vendor implementation contract.
    /// @param _data Delegate call data for implementation initialization.
    function upgradeTo(address _newImplementation, bytes memory _data)
        public
        onlyAdmin
    {
        address currentImplementation = _implementation();
        require(
            _newImplementation != address(0),
            "Implementation address can't be zero."
        );
        require(
            _newImplementation != currentImplementation,
            "Implementation address must be different from the current one."
        );

        initializationData[_newImplementation] = _data;

        setNewImplementation(_newImplementation);

        /* solium-disable-next-line security/no-block-members */
        setUpgradeInitiatedTimestamp(block.timestamp);

        /* solium-disable-next-line security/no-block-members */
        emit UpgradeStarted(_newImplementation, block.timestamp);
    }

    /// @notice Finalizes implementation address upgrade.
    /// @dev It is the second part of the two-step implementation address update
    /// process. The function emits an event containing the new implementation
    /// address. It can be called after upgrade time delay period has passed since
    /// upgrade initiation.
    function completeUpgrade() public onlyAdmin {
        require(upgradeInitiatedTimestamp() > 0, "Upgrade not initiated");

        require(
            /* solium-disable-next-line security/no-block-members */
            block.timestamp.sub(upgradeInitiatedTimestamp()) >=
            upgradeTimeDelay(),
            "Timer not elapsed"
        );

        address newImplementation = newImplementation();

        setImplementation(newImplementation);

        bytes memory data = initializationData[newImplementation];
        if (data.length > 0) {
            initializeImplementation(newImplementation, data);
        }

        setUpgradeInitiatedTimestamp(0);

        emit UpgradeCompleted(newImplementation);
    }

    /// @notice Initializes implementation contract.
    /// @dev Delegates a call to the implementation with provided data. It is
    /// expected that data contains details of function to be called.
    /// @param _implementation Address of the new vendor implementation contract.
    /// @param _data Delegate call data for implementation initialization.
    function initializeImplementation(
        address _implementation,
        bytes memory _data
    ) internal {
        (bool success, bytes memory returnData) = _implementation.delegatecall(
            _data
        );

        require(success, string(returnData));
    }

    /// @notice Asserts correct slot for provided key.
    /// @dev To avoid clashing with implementation's fields the proxy contract
    /// defines its' fields on specific slots. Slot is calculated as hash of a
    /// string subtracted by 1 to reduce chances of a possible attack.
    /// For details see EIP-1967.
    function assertSlot(bytes32 slot, bytes memory key) internal pure {
        assert(slot == bytes32(uint256(keccak256(key)) - 1));
    }

    /// @dev Gets the address of the current implementation.
    /// @return address of the current implementation.
    function implementation() public view returns (address) {
        return _implementation();
    }

    /// @notice Returns the current implementation. Implements function from `Proxy`
    /// contract.
    /// @return Address of the current implementation
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        /* solium-disable-next-line */
        assembly {
            impl := sload(slot)
        }
    }

    /// @notice Sets the address of the current implementation.
    /// @param _implementation address representing the new implementation to be set.
    function setImplementation(address _implementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        /* solium-disable-next-line */
        assembly {
            sstore(slot, _implementation)
        }
    }

    function upgradeTimeDelay()
        public
        view
        returns (uint256 _upgradeTimeDelay)
    {
        bytes32 position = UPGRADE_TIME_DELAY_SLOT;
        /* solium-disable-next-line */
        assembly {
            _upgradeTimeDelay := sload(position)
        }
    }

    function setUpgradeTimeDelay(uint256 _upgradeTimeDelay) internal {
        bytes32 position = UPGRADE_TIME_DELAY_SLOT;
        /* solium-disable-next-line */
        assembly {
            sstore(position, _upgradeTimeDelay)
        }
    }

    function newImplementation()
        public
        view
        returns (address _newImplementation)
    {
        bytes32 position = UPGRADE_IMPLEMENTATION_SLOT;
        /* solium-disable-next-line */
        assembly {
            _newImplementation := sload(position)
        }
    }

    function setNewImplementation(address _newImplementation) internal {
        bytes32 position = UPGRADE_IMPLEMENTATION_SLOT;
        /* solium-disable-next-line */
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function upgradeInitiatedTimestamp()
        public
        view
        returns (uint256 _upgradeInitiatedTimestamp)
    {
        bytes32 position = UPGRADE_INIT_TIMESTAMP_SLOT;
        /* solium-disable-next-line */
        assembly {
            _upgradeInitiatedTimestamp := sload(position)
        }
    }

    function setUpgradeInitiatedTimestamp(uint256 _upgradeInitiatedTimestamp)
        internal
    {
        bytes32 position = UPGRADE_INIT_TIMESTAMP_SLOT;
        /* solium-disable-next-line */
        assembly {
            sstore(position, _upgradeInitiatedTimestamp)
        }
    }

    /// @notice The admin slot.
    /// @return The contract owner's address.
    function admin() public view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        /* solium-disable-next-line */
        assembly {
            adm := sload(slot)
        }
    }

    /// @notice Sets the address of the proxy admin.
    /// @dev Function can be called only by the current admin.
    /// @param _newAdmin Address of the new proxy admin.
    function updateAdmin(address _newAdmin) public onlyAdmin {
        setAdmin(_newAdmin);
    }

    /// @notice Sets the address of the proxy admin.
    /// @param _newAdmin Address of the new proxy admin.
    function setAdmin(address _newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        /* solium-disable-next-line */
        assembly {
            sstore(slot, _newAdmin)
        }
    }

    /// @notice Throws if called by any account other than the contract owner.
    modifier onlyAdmin() {
        require(msg.sender == admin(), "Caller is not the admin");
        _;
    }
}
