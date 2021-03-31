// https://tornado.cash
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./interfaces/ITornadoTreesV1.sol";
import "./interfaces/IBatchTreeUpdateVerifier.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";

/// @dev This contract holds a merkle tree of all tornado cash deposit and withdrawal events
contract TornadoTrees is Initializable {
  address public immutable governance;
  bytes32 public depositRoot;
  bytes32 public previousDepositRoot;
  bytes32 public withdrawalRoot;
  bytes32 public previousWithdrawalRoot;
  address public tornadoProxy;
  IBatchTreeUpdateVerifier public treeUpdateVerifier;
  ITornadoTreesV1 public immutable tornadoTreesV1;

  uint256 public constant CHUNK_TREE_HEIGHT = 8;
  uint256 public constant CHUNK_SIZE = 2**CHUNK_TREE_HEIGHT;
  uint256 public constant ITEM_SIZE = 32 + 20 + 4;
  uint256 public constant BYTES_SIZE = 32 + 32 + 4 + CHUNK_SIZE * ITEM_SIZE;
  uint256 public constant SNARK_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  mapping(uint256 => bytes32) public deposits;
  uint256 public depositsLength;
  uint256 public lastProcessedDepositLeaf;
  uint256 public immutable depositsV1Length;

  mapping(uint256 => bytes32) public withdrawals;
  uint256 public withdrawalsLength;
  uint256 public lastProcessedWithdrawalLeaf;
  uint256 public immutable withdrawalsV1Length;

  event DepositData(address instance, bytes32 indexed hash, uint256 block, uint256 index);
  event WithdrawalData(address instance, bytes32 indexed hash, uint256 block, uint256 index);
  event VerifierUpdated(address newVerifier);
  event ProxyUpdated(address newProxy);

  struct TreeLeaf {
    bytes32 hash;
    address instance;
    uint32 block;
  }

  modifier onlyTornadoProxy {
    require(msg.sender == tornadoProxy, "Not authorized");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance, "Only governance can perform this action");
    _;
  }

  struct SearchParams {
    uint256 depositsFrom;
    uint256 depositsStep;
    uint256 withdrawalsFrom;
    uint256 withdrawalsStep;
  }

  constructor(
    address _governance,
    ITornadoTreesV1 _tornadoTreesV1,
    SearchParams memory _searchParams
  ) public {
    governance = _governance;
    tornadoTreesV1 = _tornadoTreesV1;

    depositsV1Length = findArrayLength(
      _tornadoTreesV1,
      "deposits(uint256)",
      _searchParams.depositsFrom,
      _searchParams.depositsStep
    );

    withdrawalsV1Length = findArrayLength(
      _tornadoTreesV1,
      "withdrawals(uint256)",
      _searchParams.withdrawalsFrom,
      _searchParams.withdrawalsStep
    );
  }

  function initialize(address _tornadoProxy, IBatchTreeUpdateVerifier _treeUpdateVerifier) public initializer onlyGovernance {
    tornadoProxy = _tornadoProxy;
    treeUpdateVerifier = _treeUpdateVerifier;

    depositRoot = tornadoTreesV1.depositRoot();
    uint256 lastDepositLeaf = tornadoTreesV1.lastProcessedDepositLeaf();
    require(lastDepositLeaf % CHUNK_SIZE == 0, "Incorrect TornadoTrees state");
    lastProcessedDepositLeaf = lastDepositLeaf;
    depositsLength = depositsV1Length;

    withdrawalRoot = tornadoTreesV1.withdrawalRoot();
    uint256 lastWithdrawalLeaf = tornadoTreesV1.lastProcessedWithdrawalLeaf();
    require(lastWithdrawalLeaf % CHUNK_SIZE == 0, "Incorrect TornadoTrees state");
    lastProcessedWithdrawalLeaf = lastWithdrawalLeaf;
    withdrawalsLength = withdrawalsV1Length;
  }

  /// @dev Queue a new deposit data to be inserted into a merkle tree
  function registerDeposit(address _instance, bytes32 _commitment) public onlyTornadoProxy {
    uint256 _depositsLength = depositsLength;
    deposits[_depositsLength] = keccak256(abi.encode(_instance, _commitment, blockNumber()));
    emit DepositData(_instance, _commitment, blockNumber(), _depositsLength);
    depositsLength = _depositsLength + 1;
  }

  /// @dev Queue a new withdrawal data to be inserted into a merkle tree
  function registerWithdrawal(address _instance, bytes32 _nullifierHash) public onlyTornadoProxy {
    uint256 _withdrawalsLength = withdrawalsLength;
    withdrawals[_withdrawalsLength] = keccak256(abi.encode(_instance, _nullifierHash, blockNumber()));
    emit WithdrawalData(_instance, _nullifierHash, blockNumber(), _withdrawalsLength);
    withdrawalsLength = _withdrawalsLength + 1;
  }

  /// @dev Insert a full batch of queued deposits into a merkle tree
  /// @param _proof A snark proof that elements were inserted correctly
  /// @param _argsHash A hash of snark inputs
  /// @param _argsHash Current merkle tree root
  /// @param _newRoot Updated merkle tree root
  /// @param _pathIndices Merkle path to inserted batch
  /// @param _events A batch of inserted events (leaves)
  function updateDepositTree(
    bytes calldata _proof,
    bytes32 _argsHash,
    bytes32 _currentRoot,
    bytes32 _newRoot,
    uint32 _pathIndices,
    TreeLeaf[CHUNK_SIZE] calldata _events
  ) public {
    uint256 offset = lastProcessedDepositLeaf;
    require(_currentRoot == depositRoot, "Proposed deposit root is invalid");
    require(_pathIndices == offset >> CHUNK_TREE_HEIGHT, "Incorrect deposit insert index");

    bytes memory data = new bytes(BYTES_SIZE);
    assembly {
      mstore(add(data, 0x44), _pathIndices)
      mstore(add(data, 0x40), _newRoot)
      mstore(add(data, 0x20), _currentRoot)
    }
    for (uint256 i = 0; i < CHUNK_SIZE; i++) {
      (bytes32 hash, address instance, uint32 blockNumber) = (_events[i].hash, _events[i].instance, _events[i].block);
      bytes32 leafHash = keccak256(abi.encode(instance, hash, blockNumber));
      bytes32 deposit = offset + i >= depositsV1Length ? deposits[offset + i] : tornadoTreesV1.deposits(offset + i);
      require(leafHash == deposit, "Incorrect deposit");
      assembly {
        let itemOffset := add(data, mul(ITEM_SIZE, i))
        mstore(add(itemOffset, 0x7c), blockNumber)
        mstore(add(itemOffset, 0x78), instance)
        mstore(add(itemOffset, 0x64), hash)
      }
      if (offset + i >= depositsV1Length) {
        delete deposits[offset + i];
      } else {
        emit DepositData(instance, hash, blockNumber, offset + i);
      }
    }

    uint256 argsHash = uint256(sha256(data)) % SNARK_FIELD;
    require(argsHash == uint256(_argsHash), "Invalid args hash");
    require(treeUpdateVerifier.verifyProof(_proof, [argsHash]), "Invalid deposit tree update proof");

    previousDepositRoot = _currentRoot;
    depositRoot = _newRoot;
    lastProcessedDepositLeaf = offset + CHUNK_SIZE;
  }

  /// @dev Insert a full batch of queued withdrawals into a merkle tree
  /// @param _proof A snark proof that elements were inserted correctly
  /// @param _argsHash A hash of snark inputs
  /// @param _argsHash Current merkle tree root
  /// @param _newRoot Updated merkle tree root
  /// @param _pathIndices Merkle path to inserted batch
  /// @param _events A batch of inserted events (leaves)
  function updateWithdrawalTree(
    bytes calldata _proof,
    bytes32 _argsHash,
    bytes32 _currentRoot,
    bytes32 _newRoot,
    uint32 _pathIndices,
    TreeLeaf[CHUNK_SIZE] calldata _events
  ) public {
    uint256 offset = lastProcessedWithdrawalLeaf;
    require(_currentRoot == withdrawalRoot, "Proposed withdrawal root is invalid");
    require(_pathIndices == offset >> CHUNK_TREE_HEIGHT, "Incorrect withdrawal insert index");

    bytes memory data = new bytes(BYTES_SIZE);
    assembly {
      mstore(add(data, 0x44), _pathIndices)
      mstore(add(data, 0x40), _newRoot)
      mstore(add(data, 0x20), _currentRoot)
    }
    for (uint256 i = 0; i < CHUNK_SIZE; i++) {
      (bytes32 hash, address instance, uint32 blockNumber) = (_events[i].hash, _events[i].instance, _events[i].block);
      bytes32 leafHash = keccak256(abi.encode(instance, hash, blockNumber));
      bytes32 withdrawal = offset + i >= withdrawalsV1Length ? withdrawals[offset + i] : tornadoTreesV1.withdrawals(offset + i);
      require(leafHash == withdrawal, "Incorrect withdrawal");
      assembly {
        let itemOffset := add(data, mul(ITEM_SIZE, i))
        mstore(add(itemOffset, 0x7c), blockNumber)
        mstore(add(itemOffset, 0x78), instance)
        mstore(add(itemOffset, 0x64), hash)
      }
      if (offset + i >= withdrawalsV1Length) {
        delete withdrawals[offset + i];
      } else {
        emit WithdrawalData(instance, hash, blockNumber, offset + i);
      }
    }

    uint256 argsHash = uint256(sha256(data)) % SNARK_FIELD;
    require(argsHash == uint256(_argsHash), "Invalid args hash");
    require(treeUpdateVerifier.verifyProof(_proof, [argsHash]), "Invalid withdrawal tree update proof");

    previousWithdrawalRoot = _currentRoot;
    withdrawalRoot = _newRoot;
    lastProcessedWithdrawalLeaf = offset + CHUNK_SIZE;
  }

  function validateRoots(bytes32 _depositRoot, bytes32 _withdrawalRoot) public view {
    require(_depositRoot == depositRoot || _depositRoot == previousDepositRoot, "Incorrect deposit tree root");
    require(_withdrawalRoot == withdrawalRoot || _withdrawalRoot == previousWithdrawalRoot, "Incorrect withdrawal tree root");
  }

  /// @dev There is no array length getter for deposit and withdrawal arrays
  /// in the previous contract, so we have to find them length manually.
  /// Used only during deployment
  function findArrayLength(
    ITornadoTreesV1 _tornadoTreesV1,
    string memory _type,
    uint256 _from, // most likely array length after the proposal has passed
    uint256 _step // optimal step size to find first match, approximately equals dispersion
  ) internal view virtual returns (uint256) {
    // Find the segment with correct array length
    bool direction = elementExists(_tornadoTreesV1, _type, _from);
    do {
      _from = direction ? _from + _step : _from - _step;
    } while (direction == elementExists(_tornadoTreesV1, _type, _from));
    uint256 high = direction ? _from : _from + _step;
    uint256 low = direction ? _from - _step : _from;
    uint256 mid = (high + low) / 2;

    // Perform a binary search in this segment
    while (low < mid) {
      if (elementExists(_tornadoTreesV1, _type, mid)) {
        low = mid;
      } else {
        high = mid;
      }
      mid = (low + high) / 2;
    }
    return mid + 1;
  }

  function elementExists(
    ITornadoTreesV1 _tornadoTreesV1,
    string memory _type,
    uint256 index
  ) public view returns (bool success) {
    // Try to get the element. If it succeeds the array length is higher, it it reverts the length is equal or lower
    (success, ) = address(_tornadoTreesV1).staticcall{ gas: 2500 }(abi.encodeWithSignature(_type, index));
  }

  function setTornadoProxyContract(address _tornadoProxy) external onlyGovernance {
    tornadoProxy = _tornadoProxy;
    emit ProxyUpdated(_tornadoProxy);
  }

  function setVerifierContract(IBatchTreeUpdateVerifier _treeUpdateVerifier) external onlyGovernance {
    treeUpdateVerifier = _treeUpdateVerifier;
    emit VerifierUpdated(address(_treeUpdateVerifier));
  }

  function blockNumber() public view virtual returns (uint256) {
    return block.number;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ITornadoTreesV1 {
  function lastProcessedDepositLeaf() external view returns (uint256);

  function lastProcessedWithdrawalLeaf() external view returns (uint256);

  function depositRoot() external view returns (bytes32);

  function withdrawalRoot() external view returns (bytes32);

  function deposits(uint256 i) external view returns (bytes32);

  function withdrawals(uint256 i) external view returns (bytes32);

  function registerDeposit(address instance, bytes32 commitment) external;

  function registerWithdrawal(address instance, bytes32 nullifier) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IBatchTreeUpdateVerifier {
  function verifyProof(bytes calldata proof, uint256[1] calldata input) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
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