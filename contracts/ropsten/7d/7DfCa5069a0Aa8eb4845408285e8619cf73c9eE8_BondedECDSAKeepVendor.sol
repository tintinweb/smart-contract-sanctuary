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

/// @title Proxy contract for Bonded ECDSA Keep vendor.
contract BondedECDSAKeepVendor is Proxy {
    using SafeMath for uint256;

    /// @dev Storage slot with the admin of the contract.
    /// This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
    /// validated in the constructor.
    bytes32 internal constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @dev Storage slot with the address of the current implementation.
    /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
    /// validated in the constructor.
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Storage slot with the upgrade time delay. Upgrade time delay defines a
    /// period for implementation upgrade.
    /// This is the keccak-256 hash of "network.keep.bondedecdsavendor.proxy.upgradeTimeDelay"
    /// subtracted by 1, and is validated in the constructor.
    bytes32 internal constant UPGRADE_TIME_DELAY_SLOT =
        0x3ca583dafde9ce8bdb41fe825f85984a83b08ecf90ffaccbc4b049e8d8703563;

    /// @dev Storage slot with the new implementation address.
    /// This is the keccak-256 hash of "network.keep.bondedecdsavendor.proxy.upgradeImplementation"
    /// subtracted by 1, and is validated in the constructor.
    bytes32 internal constant UPGRADE_IMPLEMENTATION_SLOT =
        0x4e06287250f0fdd90b4a096f346c06d4e706d470a14747ab56a0156d48a6883f;

    /// @dev Storage slot with the implementation address upgrade initiation.
    /// This is the keccak-256 hash of "network.keep.bondedecdsavendor.proxy.upgradeInitiatedTimestamp"
    /// subtracted by 1, and is validated in the constructor.
    bytes32 internal constant UPGRADE_INIT_TIMESTAMP_SLOT =
        0x0816e8d9eeb2554df0d0b7edc58e2d957e6ce18adf92c138b50dd78a420bebaf;

    /// @notice Details of initialization data to be called on the second step
    /// of upgrade.
    /// @dev Mapping is stored at position calculated with keccak256 of the entry
    /// details, hence it should be protected from clashing with implementation's
    /// fields.
    mapping(address => bytes) public initializationData;

    event UpgradeStarted(address implementation, uint256 timestamp);
    event UpgradeCompleted(address implementation);

    constructor(address _implementationAddress, bytes memory _data) public {
        assertSlot(IMPLEMENTATION_SLOT, "eip1967.proxy.implementation");
        assertSlot(ADMIN_SLOT, "eip1967.proxy.admin");
        assertSlot(
            UPGRADE_TIME_DELAY_SLOT,
            "network.keep.bondedecdsavendor.proxy.upgradeTimeDelay"
        );
        assertSlot(
            UPGRADE_IMPLEMENTATION_SLOT,
            "network.keep.bondedecdsavendor.proxy.upgradeImplementation"
        );
        assertSlot(
            UPGRADE_INIT_TIMESTAMP_SLOT,
            "network.keep.bondedecdsavendor.proxy.upgradeInitiatedTimestamp"
        );

        require(
            _implementationAddress != address(0),
            "Implementation address can't be zero."
        );

        if (_data.length > 0) {
            initializeImplementation(_implementationAddress, _data);
        }

        setImplementation(_implementationAddress);

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

        setUpgradeInitiatedTimestamp(block.timestamp);

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
            block.timestamp.sub(upgradeInitiatedTimestamp()) >=
                upgradeTimeDelay(),
            "Timer not elapsed"
        );

        address _newImplementation = newImplementation();

        setImplementation(_newImplementation);

        bytes memory data = initializationData[_newImplementation];
        if (data.length > 0) {
            initializeImplementation(_newImplementation, data);
        }

        setUpgradeInitiatedTimestamp(0);

        emit UpgradeCompleted(_newImplementation);
    }

    /// @notice Gets the address of the current vendor implementation.
    /// @return Address of the current implementation.
    function implementation() public view returns (address) {
        return _implementation();
    }

    /// @notice Initializes implementation contract.
    /// @dev Delegates a call to the implementation with provided data. It is
    /// expected that data contains details of function to be called.
    /// This function uses delegatecall to a input-controlled function id and
    /// contract address. This is safe because both _implementation and _data
    /// an be set only by the admin of this contract in upgradeTo and constructor.
    /// @param _implementationAddress Address of the new vendor implementation
    /// contract.
    /// @param _data Delegate call data for implementation initialization.
    function initializeImplementation(
        address _implementationAddress,
        bytes memory _data
    ) internal {
        /* solium-disable-next-line security/no-low-level-calls */
        (bool success, bytes memory returnData) =
            _implementationAddress.delegatecall(_data);

        require(success, string(returnData));
    }

    /// @notice Asserts correct slot for provided key.
    /// @dev To avoid clashing with implementation's fields the proxy contract
    /// defines its' fields on specific slots. Slot is calculated as hash of a string
    /// subtracted by 1 to reduce chances of a possible attack. For details see
    /// EIP-1967.
    function assertSlot(bytes32 slot, bytes memory key) internal pure {
        assert(slot == bytes32(uint256(keccak256(key)) - 1));
    }

    /* solium-disable function-order */

    /// @dev Returns the current implementation. Implements function from `Proxy`
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
    /// @param _implementationAddress Address representing the new
    /// implementation to be set.
    function setImplementation(address _implementationAddress) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        /* solium-disable-next-line */
        assembly {
            sstore(slot, _implementationAddress)
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

    /// @dev Sets the address of the proxy admin.
    /// @param _newAdmin Address of the new proxy admin.
    function setAdmin(address _newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        /* solium-disable-next-line */
        assembly {
            sstore(slot, _newAdmin)
        }
    }

    /// @dev Throws if called by any account other than the contract owner.
    modifier onlyAdmin() {
        require(msg.sender == admin(), "Caller is not the admin");
        _;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}