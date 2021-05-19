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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
    @title Interface for Bridge contract.
    @dev Copied directly from here: https://github.com/ChainSafe/chainbridge-solidity/releases/tag/v1.0.0 except for 
         the addition of `deposit()` so that this contract can be called from Sink and Source Oracle contracts.
    @author ChainSafe Systems.
 */
interface IBridge {
    /**
        @notice Exposing getter for {_chainID} instead of forcing the use of call.
        @return uint8 The {_chainID} that is currently set for the Bridge contract.
     */
    function _chainID() external returns (uint8);

    function deposit(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../oracle/interfaces/FinderInterface.sol";
import "../oracle/implementation/Constants.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBridge.sol";

/**
 * @title Governance relayer contract on L1 that receives messages from the owner (Governor) and sends them to L2.
 */
contract SourceGovernor is Ownable {
    FinderInterface public finder;
    uint8 public currentChainId;
    bytes32 internal currentRequestHash;

    event RelayedGovernanceRequest(
        uint8 indexed destinationChainId,
        address indexed to,
        uint256 value,
        bytes indexed data
    );

    constructor(FinderInterface _finder, uint8 _currentChainId) {
        finder = _finder;
        currentChainId = _currentChainId;
        currentRequestHash = bytes32(0);
    }

    /**
     * @notice This is the first method that should be called in order to relay a governance request to another network
     * marked by `sinkChainID`. Note: this can only be called by the owner (presumably the L1 governor).
     */
    function relayGovernance(
        uint8 destinationChainId,
        address to,
        uint256 value,
        bytes memory data
    ) external onlyOwner {
        require(currentRequestHash == bytes32(0), "Request hash already set");
        currentRequestHash = _computeRequestHash(to, value, data);
        _getBridge().deposit(destinationChainId, getResourceId(), _formatMetadata(to, value, data));
        currentRequestHash = bytes32(0);
        emit RelayedGovernanceRequest(destinationChainId, to, value, data);
    }

    /**
     * @notice This method will ultimately be called after `relayGovernance` calls `Bridge.deposit()`, which will call
     * `GenericHandler.deposit()` and ultimately this method.
     * @dev This method should basically check that the `Bridge.deposit()` was triggered by a valid relay event.
     */
    function verifyRequest(
        address to,
        uint256 value,
        bytes memory data
    ) external view {
        require(currentRequestHash == _computeRequestHash(to, value, data), "Invalid Request");
    }

    /**
     * @notice Gets the resource id to send to the bridge.
     */
    function getResourceId() public view returns (bytes32) {
        return keccak256(abi.encode("Governor", currentChainId));
    }

    function _getBridge() internal view returns (IBridge) {
        return IBridge(finder.getImplementationAddress(OracleInterfaces.Bridge));
    }

    function _formatMetadata(
        address to,
        uint256 value,
        bytes memory data
    ) internal pure returns (bytes memory) {
        bytes memory metadata = abi.encode(to, value, data);
        return abi.encodePacked(metadata.length, metadata);
    }

    function _computeRequestHash(
        address to,
        uint256 value,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(to, value, data));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 199
  },
  "remappings": [],
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