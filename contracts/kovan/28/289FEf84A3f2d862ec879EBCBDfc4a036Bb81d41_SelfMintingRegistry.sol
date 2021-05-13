// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {ISelfMintingRegistry} from './interfaces/ISelfMintingRegistry.sol';
import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SynthereumInterfaces} from './Constants.sol';
import {
  EnumerableSet
} from '../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  Lockable
} from '../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SelfMintingRegistry is ISelfMintingRegistry, Lockable {
  using EnumerableSet for EnumerableSet.AddressSet;

  ISynthereumFinder public synthereumFinder;

  mapping(string => mapping(IERC20 => mapping(uint8 => EnumerableSet.AddressSet)))
    private symbolToSelfMintingDerivatives;

  EnumerableSet.AddressSet private collaterals;

  constructor(ISynthereumFinder _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
  }

  function registerSelfMintingDerivative(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 selfMintingVersion,
    address selfMintingDerivative
  ) external override nonReentrant {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    symbolToSelfMintingDerivatives[syntheticTokenSymbol][collateralToken][
      selfMintingVersion
    ]
      .add(selfMintingDerivative);
    collaterals.add(address(collateralToken));
  }

  function isSelfMintingDerivativeDeployed(
    string calldata selfMintingDerivativeSymbol,
    IERC20 collateral,
    uint8 selfMintingVersion,
    address selfMintingDerivative
  ) external view override nonReentrantView returns (bool isDeployed) {
    isDeployed = symbolToSelfMintingDerivatives[selfMintingDerivativeSymbol][
      collateral
    ][selfMintingVersion]
      .contains(selfMintingDerivative);
  }

  function getSelfMintingDerivatives(
    string calldata selfMintingDerivativeSymbol,
    IERC20 collateral,
    uint8 selfMintingVersion
  ) external view override nonReentrantView returns (address[] memory) {
    EnumerableSet.AddressSet storage selfMintingSet =
      symbolToSelfMintingDerivatives[selfMintingDerivativeSymbol][collateral][
        selfMintingVersion
      ];
    uint256 numberOfDerivatives = selfMintingSet.length();
    address[] memory selfMintingDerivatives =
      new address[](numberOfDerivatives);
    for (uint256 j = 0; j < numberOfDerivatives; j++) {
      selfMintingDerivatives[j] = selfMintingSet.at(j);
    }
    return selfMintingDerivatives;
  }

  function getCollaterals()
    external
    view
    override
    nonReentrantView
    returns (address[] memory)
  {
    uint256 numberOfCollaterals = collaterals.length();
    address[] memory collateralAddresses = new address[](numberOfCollaterals);
    for (uint256 j = 0; j < numberOfCollaterals; j++) {
      collateralAddresses[j] = collaterals.at(j);
    }
    return collateralAddresses;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISelfMintingRegistry {
  function registerSelfMintingDerivative(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 selfMintingVersion,
    address selfMintingDerivative
  ) external;

  function isSelfMintingDerivativeDeployed(
    string calldata selfMintingDerivativeSymbol,
    IERC20 collateral,
    uint8 selfMintingVersion,
    address selfMintingDerivative
  ) external view returns (bool isDeployed);

  function getSelfMintingDerivatives(
    string calldata selfMintingDerivativeSymbol,
    IERC20 collateral,
    uint8 selfMintingVersion
  ) external view returns (address[] memory);

  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface ISynthereumFinder {
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant SelfMintingController = 'SelfMintingController';
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);

      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      bytes32 lastvalue = set._values[lastIndex];

      set._values[toDeleteIndex] = lastvalue;

      set._indexes[lastvalue] = toDeleteIndex + 1;

      set._values.pop();

      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
    return set._values[index];
  }

  struct Bytes32Set {
    Set _inner;
  }

  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, value);
  }

  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
    return _at(set._inner, index);
  }

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(value)));
  }

  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(value)));
  }

  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(uint256(value)));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
    return address(uint256(_at(set._inner, index)));
  }

  struct UintSet {
    Set _inner;
  }

  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(value));
  }

  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

contract Lockable {
  bool private _notEntered;

  constructor() internal {
    _notEntered = true;
  }

  modifier nonReentrant() {
    _preEntranceCheck();
    _preEntranceSet();
    _;
    _postEntranceReset();
  }

  modifier nonReentrantView() {
    _preEntranceCheck();
    _;
  }

  function _preEntranceCheck() internal view {
    require(_notEntered, 'ReentrancyGuard: reentrant call');
  }

  function _preEntranceSet() internal {
    _notEntered = false;
  }

  function _postEntranceReset() internal {
    _notEntered = true;
  }
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