// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );
  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import './AggregatorInterface.sol';
import './AggregatorV3Interface.sol';

interface AggregatorV2V3Interface is
  AggregatorInterface,
  AggregatorV3Interface
{}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '../interfaces/AggregatorV2V3Interface.sol';

/**
 * @title MockV3Aggregator
 * @notice Based on the FluxAggregator contract
 * @notice Use this contract when you need to test
 * other contract's ability to read data from an
 * aggregator contract, but how the aggregator got
 * its answer is unimportant
 */
contract MockV3Aggregator is AggregatorV2V3Interface {
  uint256 public constant override version = 0;

  uint8 public override decimals;
  int256 public override latestAnswer;
  uint256 public override latestTimestamp;
  uint256 public override latestRound;

  mapping(uint256 => int256) public override getAnswer;
  mapping(uint256 => uint256) public override getTimestamp;
  mapping(uint256 => uint256) private getStartedAt;

  constructor(uint8 _decimals, int256 _initialAnswer) public {
    decimals = _decimals;
    updateAnswer(_initialAnswer);
  }

  function updateAnswer(int256 _answer) public {
    latestAnswer = _answer;
    latestTimestamp = block.timestamp;
    latestRound++;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = block.timestamp;
    getStartedAt[latestRound] = block.timestamp;
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public {
    latestRound = _roundId;
    latestAnswer = _answer;
    latestTimestamp = _timestamp;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = _timestamp;
    getStartedAt[latestRound] = _startedAt;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      _roundId,
      getAnswer[_roundId],
      getStartedAt[_roundId],
      getTimestamp[_roundId],
      _roundId
    );
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      uint80(latestRound),
      getAnswer[latestRound],
      getStartedAt[latestRound],
      getTimestamp[latestRound],
      uint80(latestRound)
    );
  }

  function description() external view override returns (string memory) {
    return 'v0.6/tests/MockV3Aggregator.sol';
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  MockV3Aggregator
} from '../../@chainlink/contracts/v0.6/tests/MockV3Aggregator.sol';

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {
  AggregatorV3Interface
} from '../../../../@chainlink/contracts/v0.6/interfaces/AggregatorV3Interface.sol';
import {ISynthereumPriceFeed} from '../../common/interfaces/IPriceFeed.sol';

interface ISynthereumChainlinkPriceFeed is ISynthereumPriceFeed {
  struct OracleData {
    uint80 roundId;
    uint256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
    uint8 decimals;
  }

  /**
   * @notice Set the address of aggregator associated to a pricee identifier
   * @param priceIdentifier Price feed identifier
   * @param aggregator Address of chainlink proxy aggregator
   */
  function setAggregator(
    bytes32 priceIdentifier,
    AggregatorV3Interface aggregator
  ) external;

  /**
   * @notice Remove the address of aggregator associated to a price identifier
   * @param priceIdentifier Price feed identifier
   */
  function removeAggregator(bytes32 priceIdentifier) external;

  /**
   * @notice Returns the address of aggregator if exists, otherwise it reverts
   * @param priceIdentifier Price feed identifier
   * @return aggregator Aggregator associated with price identifier
   */
  function getAggregator(bytes32 priceIdentifier)
    external
    view
    returns (AggregatorV3Interface aggregator);

  /**
   * @notice Get last chainlink oracle data for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return oracleData Oracle data
   */
  function getOracleLatestData(bytes32 priceIdentifier)
    external
    view
    returns (OracleData memory oracleData);

  /**
   * @notice Get chainlink oracle price in a given round for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return price Oracle price
   */
  function getRoundPrice(bytes32 priceIdentifier, uint80 _roundId)
    external
    view
    returns (uint256 price);

  /**
   * @notice Get chainlink oracle data in a given round for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return oracleData Oracle data
   */
  function getOracleRoundData(bytes32 priceIdentifier, uint80 _roundId)
    external
    view
    returns (OracleData memory oracleData);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface ISynthereumPriceFeed {
  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 priceIdentifier)
    external
    view
    returns (uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  ISynthereumChainlinkPriceFeed
} from '../oracle/chainlink/interfaces/IChainlinkPriceFeed.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract PriceFeedGetter {
  ISynthereumChainlinkPriceFeed public priceFeed;

  string private symbol;
  IERC20 private token;
  uint8 private poolVersion;

  constructor(
    address _priceFeed,
    string memory _symbol,
    IERC20 _token,
    uint8 _poolVersion
  ) public {
    priceFeed = ISynthereumChainlinkPriceFeed(_priceFeed);
    symbol = _symbol;
    token = _token;
    poolVersion = _poolVersion;
  }

  function getPrice(bytes32 identifier) external view returns (uint256 price) {
    price = priceFeed.getLatestPrice(identifier);
  }

  function syntheticTokenSymbol() external view returns (string memory) {
    return symbol;
  }

  function collateralToken() external view returns (IERC20) {
    return token;
  }

  function version() external view returns (uint8) {
    return poolVersion;
  }
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

import {ISynthereumPoolRegistry} from './interfaces/IPoolRegistry.sol';
import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SynthereumInterfaces} from './Constants.sol';
import {
  EnumerableSet
} from '../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  Lockable
} from '../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolRegistry is ISynthereumPoolRegistry, Lockable {
  using EnumerableSet for EnumerableSet.AddressSet;

  ISynthereumFinder public synthereumFinder;

  mapping(string => mapping(IERC20 => mapping(uint8 => EnumerableSet.AddressSet)))
    private symbolToPools;

  EnumerableSet.AddressSet private collaterals;

  constructor(ISynthereumFinder _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
  }

  function registerPool(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 poolVersion,
    address pool
  ) external override nonReentrant {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    symbolToPools[syntheticTokenSymbol][collateralToken][poolVersion].add(pool);
    collaterals.add(address(collateralToken));
  }

  function isPoolDeployed(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion,
    address pool
  ) external view override nonReentrantView returns (bool isDeployed) {
    isDeployed = symbolToPools[poolSymbol][collateral][poolVersion].contains(
      pool
    );
  }

  function getPools(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion
  ) external view override nonReentrantView returns (address[] memory) {
    EnumerableSet.AddressSet storage poolSet =
      symbolToPools[poolSymbol][collateral][poolVersion];
    uint256 numberOfPools = poolSet.length();
    address[] memory pools = new address[](numberOfPools);
    for (uint256 j = 0; j < numberOfPools; j++) {
      pools[j] = poolSet.at(j);
    }
    return pools;
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

interface ISynthereumPoolRegistry {
  function registerPool(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 poolVersion,
    address pool
  ) external;

  function isPoolDeployed(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion,
    address pool
  ) external view returns (bool isDeployed);

  function getPools(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {ISynthereumDeployer} from './interfaces/IDeployer.sol';
import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {ISynthereumPoolRegistry} from './interfaces/IPoolRegistry.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IDeploymentSignature} from './interfaces/IDeploymentSignature.sol';
import {
  ISynthereumPoolDeployment
} from '../synthereum-pool/common/interfaces/IPoolDeployment.sol';
import {
  IDerivativeDeployment
} from '../derivative/common/interfaces/IDerivativeDeployment.sol';
import {SynthereumInterfaces} from './Constants.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {
  EnumerableSet
} from '../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  Lockable
} from '../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';
import {
  AccessControl
} from '../../@openzeppelin/contracts/access/AccessControl.sol';

contract SynthereumDeployer is ISynthereumDeployer, AccessControl, Lockable {
  using Address for address;
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  struct Roles {
    address admin;
    address maintainer;
  }

  ISynthereumFinder public synthereumFinder;

  event PoolDeployed(
    uint8 indexed poolVersion,
    address indexed derivative,
    address newPool
  );
  event DerivativeDeployed(
    uint8 indexed derivativeVersion,
    address indexed pool,
    address newDerivative
  );

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) public {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  function deployPoolAndDerivative(
    uint8 derivativeVersion,
    uint8 poolVersion,
    bytes calldata derivativeParamsData,
    bytes calldata poolParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (IDerivativeDeployment derivative, ISynthereumPoolDeployment pool)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    derivative = deployDerivative(
      factoryVersioning,
      derivativeVersion,
      derivativeParamsData
    );
    checkDerivativeRoles(derivative);
    pool = deployPool(
      factoryVersioning,
      poolVersion,
      derivative,
      poolParamsData
    );
    checkPoolDeployment(pool, poolVersion);
    checkPoolAndDerivativeMatching(pool, derivative);
    setDerivativeRoles(derivative, pool);
    ISynthereumPoolRegistry poolRegister = getPoolRegister();
    poolRegister.registerPool(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      poolVersion,
      address(pool)
    );
    emit PoolDeployed(poolVersion, address(derivative), address(pool));
    emit DerivativeDeployed(
      derivativeVersion,
      address(pool),
      address(derivative)
    );
  }

  function deployOnlyPool(
    uint8 poolVersion,
    bytes calldata poolParamsData,
    IDerivativeDeployment derivative
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumPoolDeployment pool)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    pool = deployPool(
      factoryVersioning,
      poolVersion,
      derivative,
      poolParamsData
    );
    checkPoolDeployment(pool, poolVersion);
    checkPoolAndDerivativeMatching(pool, derivative);
    ISynthereumPoolRegistry poolRegister = getPoolRegister();
    poolRegister.registerPool(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      poolVersion,
      address(pool)
    );
    emit PoolDeployed(poolVersion, address(derivative), address(pool));
  }

  function deployOnlyDerivative(
    uint8 derivativeVersion,
    bytes calldata derivativeParamsData,
    ISynthereumPoolDeployment pool
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (IDerivativeDeployment derivative)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    derivative = deployDerivative(
      factoryVersioning,
      derivativeVersion,
      derivativeParamsData
    );
    checkDerivativeRoles(derivative);
    checkPoolAndDerivativeMatching(pool, derivative);
    setDerivativeRoles(derivative, pool);
    emit DerivativeDeployed(
      derivativeVersion,
      address(pool),
      address(derivative)
    );
  }

  function deployDerivative(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 derivativeVersion,
    bytes memory derivativeParamsData
  ) internal returns (IDerivativeDeployment derivative) {
    address derivativeFactory =
      factoryVersioning.getDerivativeFactoryVersion(derivativeVersion);
    bytes memory derivativeDeploymentResult =
      derivativeFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(derivativeFactory),
          derivativeParamsData
        ),
        'Wrong derivative deployment'
      );
    derivative = IDerivativeDeployment(
      abi.decode(derivativeDeploymentResult, (address))
    );
  }

  function deployPool(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 poolVersion,
    IDerivativeDeployment derivative,
    bytes memory poolParamsData
  ) internal returns (ISynthereumPoolDeployment pool) {
    address poolFactory = factoryVersioning.getPoolFactoryVersion(poolVersion);
    bytes memory poolDeploymentResult =
      poolFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(poolFactory),
          bytes32(uint256(address(derivative))),
          poolParamsData
        ),
        'Wrong pool deployment'
      );
    pool = ISynthereumPoolDeployment(
      abi.decode(poolDeploymentResult, (address))
    );
  }

  function setDerivativeRoles(
    IDerivativeDeployment derivative,
    ISynthereumPoolDeployment pool
  ) internal {
    address poolAddr = address(pool);
    derivative.addAdminAndPool(poolAddr);
    derivative.renounceAdmin();
  }

  function getFactoryVersioning()
    internal
    view
    returns (ISynthereumFactoryVersioning factoryVersioning)
  {
    factoryVersioning = ISynthereumFactoryVersioning(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.FactoryVersioning
      )
    );
  }

  function getPoolRegister()
    internal
    view
    returns (ISynthereumPoolRegistry poolRegister)
  {
    poolRegister = ISynthereumPoolRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.PoolRegistry
      )
    );
  }

  function getDeploymentSignature(address deploymentContract)
    internal
    view
    returns (bytes4 signature)
  {
    signature = IDeploymentSignature(deploymentContract).deploymentSignature();
  }

  function checkDerivativeRoles(IDerivativeDeployment derivative)
    internal
    view
  {
    address[] memory derivativeAdmins = derivative.getAdminMembers();
    require(derivativeAdmins.length == 1, 'The derivative must have one admin');
    require(
      derivativeAdmins[0] == address(this),
      'The derivative admin must be the deployer'
    );
    address[] memory derivativePools = derivative.getPoolMembers();
    require(derivativePools.length == 0, 'The derivative must have no pools');
  }

  function checkPoolDeployment(ISynthereumPoolDeployment pool, uint8 version)
    internal
    view
  {
    require(
      pool.synthereumFinder() == synthereumFinder,
      'Wrong finder in pool deployment'
    );
    require(pool.version() == version, 'Wrong version in pool deployment');
  }

  function checkPoolAndDerivativeMatching(
    ISynthereumPoolDeployment pool,
    IDerivativeDeployment derivative
  ) internal view {
    require(
      pool.collateralToken() == derivative.collateralCurrency(),
      'Wrong collateral matching'
    );
    require(
      pool.syntheticToken() == derivative.tokenCurrency(),
      'Wrong synthetic token matching'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ISynthereumPoolDeployment
} from '../../synthereum-pool/common/interfaces/IPoolDeployment.sol';
import {
  IDerivativeDeployment
} from '../../derivative/common/interfaces/IDerivativeDeployment.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';

interface ISynthereumDeployer {
  function deployPoolAndDerivative(
    uint8 derivativeVersion,
    uint8 poolVersion,
    bytes calldata derivativeParamsData,
    bytes calldata poolParamsData
  )
    external
    returns (IDerivativeDeployment derivative, ISynthereumPoolDeployment pool);

  function deployOnlyPool(
    uint8 poolVersion,
    bytes calldata poolParamsData,
    IDerivativeDeployment derivative
  ) external returns (ISynthereumPoolDeployment pool);

  function deployOnlyDerivative(
    uint8 derivativeVersion,
    bytes calldata derivativeParamsData,
    ISynthereumPoolDeployment pool
  ) external returns (IDerivativeDeployment derivative);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface ISynthereumFactoryVersioning {
  function setPoolFactory(uint8 version, address poolFactory) external;

  function removePoolFactory(uint8 version) external;

  function setDerivativeFactory(uint8 version, address derivativeFactory)
    external;

  function removeDerivativeFactory(uint8 version) external;

  function getPoolFactoryVersion(uint8 version) external view returns (address);

  function numberOfVerisonsOfPoolFactory() external view returns (uint256);

  function getDerivativeFactoryVersion(uint8 version)
    external
    view
    returns (address);

  function numberOfVerisonsOfDerivativeFactory()
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface IDeploymentSignature {
  function deploymentSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../versioning/interfaces/IFinder.sol';

interface ISynthereumPoolDeployment {
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  function version() external view returns (uint8 poolVersion);

  function collateralToken() external view returns (IERC20 collateralCurrency);

  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDerivativeDeployment {
  function addAdminAndPool(address adminAndPool) external;

  function renounceAdmin() external;

  function collateralCurrency() external view returns (IERC20 collateral);

  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  function getAdminMembers() external view returns (address[] memory);

  function getPoolMembers() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;

    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(
      success,
      'Address: unable to send value, recipient may have reverted'
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, 'Address: low-level call failed');
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        'Address: low-level call with value failed'
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      'Address: insufficient balance for call'
    );
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../utils/EnumerableSet.sol';
import '../utils/Address.sol';
import '../GSN/Context.sol';

abstract contract AccessControl is Context {
  using EnumerableSet for EnumerableSet.AddressSet;
  using Address for address;

  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  function hasRole(bytes32 role, address account) public view returns (bool) {
    return _roles[role].members.contains(account);
  }

  function getRoleMemberCount(bytes32 role) public view returns (uint256) {
    return _roles[role].members.length();
  }

  function getRoleMember(bytes32 role, uint256 index)
    public
    view
    returns (address)
  {
    return _roles[role].members.at(index);
  }

  function getRoleAdmin(bytes32 role) public view returns (bytes32) {
    return _roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) public virtual {
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to grant'
    );

    _grantRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual {
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to revoke'
    );

    _revokeRole(role, account);
  }

  function renounceRole(bytes32 role, address account) public virtual {
    require(
      account == _msgSender(),
      'AccessControl: can only renounce roles for self'
    );

    _revokeRole(role, account);
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {
  AccessControl
} from '../../@openzeppelin/contracts/access/AccessControl.sol';

contract SynthereumFinder is ISynthereumFinder, AccessControl {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  struct Roles {
    address admin;
    address maintainer;
  }

  mapping(bytes32 => address) public interfacesImplemented;

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  constructor(Roles memory _roles) public {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {SynthereumPoolOnChainPriceFeed} from './PoolOnChainPriceFeed.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  IDeploymentSignature
} from '../../versioning/interfaces/IDeploymentSignature.sol';
import {
  SynthereumPoolOnChainPriceFeedCreator
} from './PoolOnChainPriceFeedCreator.sol';

contract SynthereumPoolOnChainPriceFeedFactory is
  SynthereumPoolOnChainPriceFeedCreator,
  IDeploymentSignature
{
  //----------------------------------------
  // State variables
  //----------------------------------------

  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Set synthereum finder
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(address _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @notice Only Synthereum deployer can deploy a pool
   * @param derivative The perpetual derivative
   * @param finder The Synthereum finder
   * @param version Synthereum version
   * @param roles The addresses of admin, maintainer, liquidity provider and validator
   * @param isContractAllowed Enable or disable the option to accept meta-tx only by an EOA for security reason
   * @param startingCollateralization Collateralization ratio to use before a global one is set
   * @param fee The fee structure
   * @return poolDeployed Pool contract deployed
   */
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPoolOnChainPriceFeed.Roles memory roles,
    bool isContractAllowed,
    uint256 startingCollateralization,
    ISynthereumPoolOnChainPriceFeed.Fee memory fee
  ) public override returns (SynthereumPoolOnChainPriceFeed poolDeployed) {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    poolDeployed = super.createPool(
      derivative,
      finder,
      version,
      roles,
      isContractAllowed,
      startingCollateralization,
      fee
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IDerivativeDeployment} from './IDerivativeDeployment.sol';
import {
  FinderInterface
} from '../../../../@jarvis-network/uma-core/contracts/oracle/interfaces/FinderInterface.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';

interface IDerivative is IDerivativeDeployment {
  struct FeePayerData {
    IERC20 collateralCurrency;
    FinderInterface finder;
    uint256 lastPaymentTime;
    FixedPoint.Unsigned cumulativeFeeMultiplier;
  }

  struct PositionManagerData {
    IERC20 tokenCurrency;
    bytes32 priceIdentifier;
    uint256 withdrawalLiveness;
    FixedPoint.Unsigned minSponsorTokens;
    FixedPoint.Unsigned emergencyShutdownPrice;
    uint256 emergencyShutdownTimestamp;
    address excessTokenBeneficiary;
  }

  struct GlobalPositionData {
    FixedPoint.Unsigned totalTokensOutstanding;
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  function feePayerData() external view returns (FeePayerData memory data);

  function positionManagerData()
    external
    view
    returns (PositionManagerData memory data);

  function globalPositionData()
    external
    view
    returns (GlobalPositionData memory data);

  function depositTo(
    address sponsor,
    FixedPoint.Unsigned memory collateralAmount
  ) external;

  function deposit(FixedPoint.Unsigned memory collateralAmount) external;

  function withdraw(FixedPoint.Unsigned memory collateralAmount)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
    external;

  function withdrawPassedRequest()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function cancelWithdrawal() external;

  function create(
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external;

  function redeem(FixedPoint.Unsigned memory numTokens)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function repay(FixedPoint.Unsigned memory numTokens) external;

  function settleEmergencyShutdown()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function emergencyShutdown() external;

  function remargin() external;

  function trimExcess(IERC20 token)
    external
    returns (FixedPoint.Unsigned memory amount);

  function addPool(address pool) external;

  function addAdmin(address admin) external;

  function renouncePool() external;

  function renounceAdminAndPool() external;

  function addSyntheticTokenMinter(address derivative) external;

  function addSyntheticTokenBurner(address derivative) external;

  function addSyntheticTokenAdmin(address derivative) external;

  function addSyntheticTokenAdminAndMinterAndBurner(address derivative)
    external;

  function renounceSyntheticTokenMinter() external;

  function renounceSyntheticTokenBurner() external;

  function renounceSyntheticTokenAdmin() external;

  function renounceSyntheticTokenAdminAndMinterAndBurner() external;

  function getCollateral(address sponsor)
    external
    view
    returns (FixedPoint.Unsigned memory collateralAmount);

  function totalPositionCollateral()
    external
    view
    returns (FixedPoint.Unsigned memory totalCollateral);

  function emergencyShutdownPrice()
    external
    view
    returns (FixedPoint.Unsigned memory emergencyPrice);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';
import {
  ISynthereumDeployer
} from '../../../versioning/interfaces/IDeployer.sol';
import {ISynthereumFinder} from '../../../versioning/interfaces/IFinder.sol';
import {ISynthereumPoolGeneral} from '../../common/interfaces/IPoolGeneral.sol';

/**
 * @title Token Issuer Contract Interface
 */
interface ISynthereumPoolOnChainPriceFeed is ISynthereumPoolGeneral {
  // Describe fee structure
  struct Fee {
    // Fees charged when a user mints, redeem and exchanges tokens
    FixedPoint.Unsigned feePercentage;
    address[] feeRecipients;
    uint32[] feeProportions;
  }

  // Describe role structure
  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
  }

  struct MintParams {
    // Derivative to use
    IDerivative derivative;
    // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
    uint256 minNumTokens;
    // Amount of collateral that a user wants to spend for minting
    uint256 collateralAmount;
    // Maximum amount of fees in percentage that user is willing to pay
    uint256 feePercentage;
    // Expiration time of the transaction
    uint256 expiration;
  }

  struct RedeemParams {
    // Derivative to use
    IDerivative derivative;
    // Amount of synthetic tokens that user wants to use for redeeming
    uint256 numTokens;
    // Minimium amount of collateral that user wants to redeem (anti-slippage)
    uint256 minCollateral;
    // Maximum amount of fees in percentage that user is willing to pay
    uint256 feePercentage;
    // Expiration time of the transaction
    uint256 expiration;
  }

  struct ExchangeParams {
    // Derivative of source pool
    IDerivative derivative;
    // Destination pool
    ISynthereumPoolOnChainPriceFeed destPool;
    // Derivative of destination pool
    IDerivative destDerivative;
    // Amount of source synthetic tokens that user wants to use for exchanging
    uint256 numTokens;
    // Minimum Amount of destination synthetic tokens that user wants to receive (anti-slippage)
    uint256 minDestNumTokens;
    // Maximum amount of fees in percentage that user is willing to pay
    uint256 feePercentage;
    // Expiration time of the transaction
    uint256 expiration;
  }

  enum DerivativeRoles {ADMIN, POOL, ADMIN_AND_POOL}

  enum SynthTokenRoles {ADMIN, MINTER, BURNER, ADMIN_AND_MINTER_AND_BURNER}

  /**
   * @notice Add a derivate to be controlled by this pool
   * @param derivative A perpetual derivative
   */
  function addDerivative(IDerivative derivative) external;

  /**
   * @notice Remove a derivative controlled by this pool
   * @param derivative A perpetual derivative
   */
  function removeDerivative(IDerivative derivative) external;

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the minter as fee
   */
  function mint(MintParams memory mintParams)
    external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams memory redeemParams)
    external
    returns (uint256 collateralRedeemed, uint256 feePaid);

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams memory exchangeParams)
    external
    returns (uint256 destNumTokensMinted, uint256 feePaid);

  /**
   * @notice Liquidity provider withdraw margin from the pool
   * @param collateralAmount The amount of margin to withdraw
   */
  function withdrawFromPool(uint256 collateralAmount) external;

  /**
   * @notice Move collateral from Pool to its derivative in order to increase GCR
   * @param derivative Derivative on which to deposit collateral
   * @param collateralAmount The amount of collateral to move into derivative
   */
  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external;

  /**
   * @notice Start a slow withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param derivative Derivative from which collateral withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   */
  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external;

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param derivative Derivative from which collateral withdrawal is requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param derivative Derivative from which fast withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Activate emergency shutdown on a derivative in order to liquidate the token holders in case of emergency
   * @param derivative Derivative on which the emergency shutdown is called
   */
  function emergencyShutdown(IDerivative derivative) external;

  /**
   * @notice Redeem tokens after contract emergency shutdown
   * @param derivative Derivative for which settlement is requested
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(IDerivative derivative)
    external
    returns (uint256 amountSettled);

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @param _fee Fee struct containing percentage, recipients and proportions
   */
  function setFee(Fee memory _fee) external;

  /**
   * @notice Update the fee percentage
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage) external;

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) external;

  /**
   * @notice Reset the starting collateral ratio - for example when you add a new derivative without collateral
   * @param startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function setStartingCollateralization(uint256 startingCollateralRatio)
    external;

  /**
   * @notice Add a role into derivative to another contract
   * @param derivative Derivative in which a role is added
   * @param derivativeRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external;

  /**
   * @notice This pool renounce a role in the derivative
   * @param derivative Derivative in which a role is renounced
   * @param derivativeRole Role to renounce
   */
  function renounceRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole
  ) external;

  /**
   * @notice Add a role into synthetic token to another contract
   * @param derivative Derivative in which a role is added
   * @param synthTokenRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external;

  /**
   * @notice Set the possibility to accept only EOA meta-tx
   * @param isContractAllowed Flag that represent options to receive tx by a contract or only EOA
   */
  function setIsContractAllowed(bool isContractAllowed) external;

  /**
   * @notice Get all the derivatives associated to this pool
   * @return Return list of all derivatives
   */
  function getAllDerivatives() external view returns (IDerivative[] memory);

  /**
   * @notice Get the starting collateral ratio of the pool
   * @return startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function getStartingCollateralization()
    external
    view
    returns (uint256 startingCollateralRatio);

  /**
   * @notice Returns if pool can accept only EOA meta-tx or also contract meta-tx
   * @return isAllowed True if accept also contract, false if only EOA
   */
  function isContractAllowed() external view returns (bool isAllowed);

  /**
   * @notice Returns infos about fee set
   * @return fee Percentage and recipients of fee
   */
  function getFeeInfo() external view returns (Fee memory fee);

  /**
   * @notice Calculate the fees a user will have to pay to mint tokens with their collateral
   * @param collateralAmount Amount of collateral on which fees are calculated
   * @return fee Amount of fee that must be paid by the user
   */
  function calculateFee(uint256 collateralAmount)
    external
    view
    returns (uint256 fee);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {
  ISynthereumPoolOnChainPriceFeedStorage
} from './interfaces/IPoolOnChainPriceFeedStorage.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {ISynthereumDeployer} from '../../versioning/interfaces/IDeployer.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {Strings} from '../../../@openzeppelin/contracts/utils/Strings.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {SynthereumPoolOnChainPriceFeedLib} from './PoolOnChainPriceFeedLib.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';
import {
  AccessControl
} from '../../../@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title Token Issuer Contract
 * @notice Collects collateral and issues synthetic assets
 */
contract SynthereumPoolOnChainPriceFeed is
  AccessControl,
  ISynthereumPoolOnChainPriceFeedStorage,
  ISynthereumPoolOnChainPriceFeed,
  Lockable
{
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolOnChainPriceFeedLib for Storage;

  //----------------------------------------
  // Constants
  //----------------------------------------

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  //----------------------------------------
  // State variables
  //----------------------------------------

  Storage private poolStorage;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);
  // We may omit the pool from event since we can recover it from the address of smart contract emitting event, but for query convenience we include it in the event
  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyLiquidityProvider() {
    require(
      hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender),
      'Sender must be the liquidity provider'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `_startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param _derivative The perpetual derivative
   * @param _finder The Synthereum finder
   * @param _version Synthereum version
   * @param _roles The addresses of admin, maintainer, liquidity provider and validator
   * @param _isContractAllowed Enable or disable the option to accept meta-tx only by an EOA for security reason
   * @param _startingCollateralization Collateralization ratio to use before a global one is set
   * @param _fee The fee structure
   */
  constructor(
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    Roles memory _roles,
    bool _isContractAllowed,
    uint256 _startingCollateralization,
    Fee memory _fee
  ) public nonReentrant {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
    _setupRole(LIQUIDITY_PROVIDER_ROLE, _roles.liquidityProvider);
    poolStorage.initialize(
      _version,
      _finder,
      _derivative,
      FixedPoint.Unsigned(_startingCollateralization),
      _isContractAllowed
    );
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------
  /**
   * @notice Add a derivate to be controlled by this pool
   * @param derivative A perpetual derivative
   */
  function addDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.addDerivative(derivative);
  }

  /**
   * @notice Remove a derivative controlled by this pool
   * @param derivative A perpetual derivative
   */
  function removeDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.removeDerivative(derivative);
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the minter as fee
   */
  function mint(MintParams memory mintParams)
    external
    override
    nonReentrant
    returns (uint256 syntheticTokensMinted, uint256 feePaid)
  {
    (syntheticTokensMinted, feePaid) = poolStorage.mint(mintParams);
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams memory redeemParams)
    external
    override
    nonReentrant
    returns (uint256 collateralRedeemed, uint256 feePaid)
  {
    (collateralRedeemed, feePaid) = poolStorage.redeem(redeemParams);
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams memory exchangeParams)
    external
    override
    nonReentrant
    returns (uint256 destNumTokensMinted, uint256 feePaid)
  {
    (destNumTokensMinted, feePaid) = poolStorage.exchange(exchangeParams);
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the PoolRegister contract
   * @param srcDerivative Derivative used by the source pool
   * @param derivative The derivative of the destination pool to use for mint
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external override nonReentrant {
    poolStorage.exchangeMint(
      srcDerivative,
      derivative,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens)
    );
  }

  /**
   * @notice Liquidity provider withdraw collateral from the pool
   * @param collateralAmount The amount of collateral to withdraw
   */
  function withdrawFromPool(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.withdrawFromPool(FixedPoint.Unsigned(collateralAmount));
  }

  /**
   * @notice Move collateral from Pool to its derivative in order to increase GCR
   * @param derivative Derivative on which to deposit collateral
   * @param collateralAmount The amount of collateral to move into derivative
   */
  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external override onlyLiquidityProvider nonReentrant {
    poolStorage.depositIntoDerivative(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  /**
   * @notice Start a slow withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param derivative Derivative from which the collateral withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   */
  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.slowWithdrawRequest(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param derivative Derivative from which collateral withdrawal was requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.slowWithdrawPassedRequest(derivative);
  }

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param derivative Derivative from which fast withdrawal was requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.fastWithdraw(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  /**
   * @notice Activate emergency shutdown on a derivative in order to liquidate the token holders in case of emergency
   * @param derivative Derivative on which emergency shutdown is called
   */
  function emergencyShutdown(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.emergencyShutdown(derivative);
  }

  /**
   * @notice Redeem tokens after derivative emergency shutdown
   * @param derivative Derivative for which settlement is requested
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(IDerivative derivative)
    external
    override
    nonReentrant
    returns (uint256 amountSettled)
  {
    amountSettled = poolStorage.settleEmergencyShutdown(
      derivative,
      LIQUIDITY_PROVIDER_ROLE
    );
  }

  /**
   * @notice Update the fee percentage
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external override onlyMaintainer nonReentrant {
    poolStorage.setFeeRecipients(_feeRecipients, _feeProportions);
  }

  /**
   * @notice Reset the starting collateral ratio - for example when you add a new derivative without collateral
   * @param startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function setStartingCollateralization(uint256 startingCollateralRatio)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setStartingCollateralization(
      FixedPoint.Unsigned(startingCollateralRatio)
    );
  }

  /**
   * @notice Add a role into derivative to another contract
   * @param derivative Derivative in which a role is being added
   * @param derivativeRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInDerivative(derivative, derivativeRole, addressToAdd);
  }

  /**
   * @notice Removing a role from a derivative contract
   * @param derivative Derivative in which to remove a role
   * @param derivativeRole Role to remove
   */
  function renounceRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole
  ) external override onlyMaintainer nonReentrant {
    poolStorage.renounceRoleInDerivative(derivative, derivativeRole);
  }

  /**
   * @notice Add a role into synthetic token to another contract
   * @param derivative Derivative in which adding role
   * @param synthTokenRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInSynthToken(derivative, synthTokenRole, addressToAdd);
  }

  /**
   * @notice Set the possibility to accept only EOA meta-tx
   * @param isContractAllowed Flag that represent options to receive tx by a contract or only EOA
   */
  function setIsContractAllowed(bool isContractAllowed)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setIsContractAllowed(isContractAllowed);
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /**
   * @notice Get Synthereum finder of the pool
   * @return finder Returns finder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = poolStorage.finder;
  }

  /**
   * @notice Get Synthereum version
   * @return poolVersion Returns the version of the Synthereum pool
   */
  function version() external view override returns (uint8 poolVersion) {
    poolVersion = poolStorage.version;
  }

  /**
   * @notice Get the collateral token
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken()
    external
    view
    override
    returns (IERC20 collateralCurrency)
  {
    collateralCurrency = poolStorage.collateralToken;
  }

  /**
   * @notice Get the synthetic token associated to this pool
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken()
    external
    view
    override
    returns (IERC20 syntheticCurrency)
  {
    syntheticCurrency = poolStorage.syntheticToken;
  }

  /**
   * @notice Get all the derivatives associated to this pool
   * @return Return list of all derivatives
   */
  function getAllDerivatives()
    external
    view
    override
    returns (IDerivative[] memory)
  {
    EnumerableSet.AddressSet storage derivativesSet = poolStorage.derivatives;
    uint256 numberOfDerivatives = derivativesSet.length();
    IDerivative[] memory derivatives = new IDerivative[](numberOfDerivatives);
    for (uint256 j = 0; j < numberOfDerivatives; j++) {
      derivatives[j] = (IDerivative(derivativesSet.at(j)));
    }
    return derivatives;
  }

  /**
   * @notice Check if a derivative is in the withelist of this pool
   * @param derivative Perpetual derivative
   * @return isAdmitted Return true if in the withelist otherwise false
   */
  function isDerivativeAdmitted(IDerivative derivative)
    external
    view
    override
    returns (bool isAdmitted)
  {
    isAdmitted = poolStorage.derivatives.contains(address(derivative));
  }

  /**
   * @notice Get the starting collateral ratio of the pool
   * @return startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function getStartingCollateralization()
    external
    view
    override
    returns (uint256 startingCollateralRatio)
  {
    startingCollateralRatio = poolStorage.startingCollateralization.rawValue;
  }

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(poolStorage.syntheticToken)).symbol();
  }

  /**
   * @notice Returns if pool can accept only EOA meta-tx or also contract meta-tx
   * @return isAllowed True if accept also contract, false if only EOA
   */
  function isContractAllowed() external view override returns (bool isAllowed) {
    isAllowed = poolStorage.isContractAllowed;
  }

  /**
   * @notice Returns infos about fee set
   * @return fee Percentage and recipients of fee
   */
  function getFeeInfo() external view override returns (Fee memory fee) {
    fee = poolStorage.fee;
  }

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = poolStorage.priceIdentifier;
  }

  /**
   * @notice Calculate the fees a user will have to pay to mint tokens with their collateral
   * @param collateralAmount Amount of collateral on which fee is calculated
   * @return fee Amount of fee that must be paid
   */
  function calculateFee(uint256 collateralAmount)
    external
    view
    override
    returns (uint256 fee)
  {
    fee = FixedPoint
      .Unsigned(collateralAmount)
      .mul(poolStorage.fee.feePercentage)
      .rawValue;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @param _fee Fee struct containing percentage, recipients and proportions
   */
  function setFee(Fee memory _fee) public override onlyMaintainer nonReentrant {
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {SynthereumPoolOnChainPriceFeed} from './PoolOnChainPriceFeed.sol';
import '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolOnChainPriceFeedCreator is Lockable {
  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param derivative The perpetual derivative
   * @param finder The Synthereum finder
   * @param version Synthereum version
   * @param roles The addresses of admin, maintainer, liquidity provider and validator
   * @param isContractAllowed Enable or disable the option to accept meta-tx only by an EOA for security reason
   * @param startingCollateralization Collateralization ratio to use before a global one is set
   * @param fee The fee structure
   * @return poolDeployed Pool contract deployed
   */
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPoolOnChainPriceFeed.Roles memory roles,
    bool isContractAllowed,
    uint256 startingCollateralization,
    ISynthereumPoolOnChainPriceFeed.Fee memory fee
  )
    public
    virtual
    nonReentrant
    returns (SynthereumPoolOnChainPriceFeed poolDeployed)
  {
    poolDeployed = new SynthereumPoolOnChainPriceFeed(
      derivative,
      finder,
      version,
      roles,
      isContractAllowed,
      startingCollateralization,
      fee
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

interface FinderInterface {
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/math/SignedSafeMath.sol';

library FixedPoint {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  uint256 private constant FP_SCALING_FACTOR = 10**18;

  struct Unsigned {
    uint256 rawValue;
  }

  function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
    return Unsigned(a.mul(FP_SCALING_FACTOR));
  }

  function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledUint(b).rawValue;
  }

  function isEqual(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue == b.rawValue;
  }

  function isGreaterThan(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > b.rawValue;
  }

  function isGreaterThan(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > fromUnscaledUint(b).rawValue;
  }

  function isGreaterThan(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue > b.rawValue;
  }

  function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= b.rawValue;
  }

  function isGreaterThanOrEqual(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= fromUnscaledUint(b).rawValue;
  }

  function isGreaterThanOrEqual(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue >= b.rawValue;
  }

  function isLessThan(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue < b.rawValue;
  }

  function isLessThan(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue < fromUnscaledUint(b).rawValue;
  }

  function isLessThan(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue < b.rawValue;
  }

  function isLessThanOrEqual(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= b.rawValue;
  }

  function isLessThanOrEqual(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= fromUnscaledUint(b).rawValue;
  }

  function isLessThanOrEqual(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue <= b.rawValue;
  }

  function min(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return a.rawValue < b.rawValue ? a : b;
  }

  function max(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return a.rawValue > b.rawValue ? a : b;
  }

  function add(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.add(b.rawValue));
  }

  function add(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return add(a, fromUnscaledUint(b));
  }

  function sub(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.sub(b.rawValue));
  }

  function sub(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return sub(a, fromUnscaledUint(b));
  }

  function sub(uint256 a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return sub(fromUnscaledUint(a), b);
  }

  function mul(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
  }

  function mul(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(b));
  }

  function mulCeil(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    uint256 mulRaw = a.rawValue.mul(b.rawValue);
    uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
    uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
    if (mod != 0) {
      return Unsigned(mulFloor.add(1));
    } else {
      return Unsigned(mulFloor);
    }
  }

  function mulCeil(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(b));
  }

  function div(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
  }

  function div(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.div(b));
  }

  function div(uint256 a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return div(fromUnscaledUint(a), b);
  }

  function divCeil(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
    uint256 divFloor = aScaled.div(b.rawValue);
    uint256 mod = aScaled.mod(b.rawValue);
    if (mod != 0) {
      return Unsigned(divFloor.add(1));
    } else {
      return Unsigned(divFloor);
    }
  }

  function divCeil(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return divCeil(a, fromUnscaledUint(b));
  }

  function pow(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory output)
  {
    output = fromUnscaledUint(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }

  int256 private constant SFP_SCALING_FACTOR = 10**18;

  struct Signed {
    int256 rawValue;
  }

  function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
    require(a.rawValue >= 0, 'Negative value provided');
    return Unsigned(uint256(a.rawValue));
  }

  function fromUnsigned(Unsigned memory a)
    internal
    pure
    returns (Signed memory)
  {
    require(a.rawValue <= uint256(type(int256).max), 'Unsigned too large');
    return Signed(int256(a.rawValue));
  }

  function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
    return Signed(a.mul(SFP_SCALING_FACTOR));
  }

  function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledInt(b).rawValue;
  }

  function isEqual(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue == b.rawValue;
  }

  function isGreaterThan(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > b.rawValue;
  }

  function isGreaterThan(Signed memory a, int256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > fromUnscaledInt(b).rawValue;
  }

  function isGreaterThan(int256 a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledInt(a).rawValue > b.rawValue;
  }

  function isGreaterThanOrEqual(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= b.rawValue;
  }

  function isGreaterThanOrEqual(Signed memory a, int256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= fromUnscaledInt(b).rawValue;
  }

  function isGreaterThanOrEqual(int256 a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledInt(a).rawValue >= b.rawValue;
  }

  function isLessThan(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue < b.rawValue;
  }

  function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue < fromUnscaledInt(b).rawValue;
  }

  function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue < b.rawValue;
  }

  function isLessThanOrEqual(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= b.rawValue;
  }

  function isLessThanOrEqual(Signed memory a, int256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= fromUnscaledInt(b).rawValue;
  }

  function isLessThanOrEqual(int256 a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledInt(a).rawValue <= b.rawValue;
  }

  function min(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return a.rawValue < b.rawValue ? a : b;
  }

  function max(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return a.rawValue > b.rawValue ? a : b;
  }

  function add(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.add(b.rawValue));
  }

  function add(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return add(a, fromUnscaledInt(b));
  }

  function sub(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.sub(b.rawValue));
  }

  function sub(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return sub(a, fromUnscaledInt(b));
  }

  function sub(int256 a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return sub(fromUnscaledInt(a), b);
  }

  function mul(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
  }

  function mul(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(b));
  }

  function mulAwayFromZero(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    int256 mulRaw = a.rawValue.mul(b.rawValue);
    int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;

    int256 mod = mulRaw % SFP_SCALING_FACTOR;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(mulTowardsZero.add(valueToAdd));
    } else {
      return Signed(mulTowardsZero);
    }
  }

  function mulAwayFromZero(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(b));
  }

  function div(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
  }

  function div(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.div(b));
  }

  function div(int256 a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return div(fromUnscaledInt(a), b);
  }

  function divAwayFromZero(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
    int256 divTowardsZero = aScaled.div(b.rawValue);

    int256 mod = aScaled % b.rawValue;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(divTowardsZero.add(valueToAdd));
    } else {
      return Signed(divTowardsZero);
    }
  }

  function divAwayFromZero(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return divAwayFromZero(a, fromUnscaledInt(b));
  }

  function pow(Signed memory a, uint256 b)
    internal
    pure
    returns (Signed memory output)
  {
    output = fromUnscaledInt(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SignedSafeMath {
  int256 private constant _INT256_MIN = -2**255;

  function mul(int256 a, int256 b) internal pure returns (int256) {
    if (a == 0) {
      return 0;
    }

    require(
      !(a == -1 && b == _INT256_MIN),
      'SignedSafeMath: multiplication overflow'
    );

    int256 c = a * b;
    require(c / a == b, 'SignedSafeMath: multiplication overflow');

    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, 'SignedSafeMath: division by zero');
    require(
      !(b == -1 && a == _INT256_MIN),
      'SignedSafeMath: division overflow'
    );

    int256 c = a / b;

    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require(
      (b >= 0 && c <= a) || (b < 0 && c > a),
      'SignedSafeMath: subtraction overflow'
    );

    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require(
      (b >= 0 && c >= a) || (b < 0 && c < a),
      'SignedSafeMath: addition overflow'
    );

    return c;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {ISynthereumPoolInteraction} from './IPoolInteraction.sol';
import {ISynthereumPoolDeployment} from './IPoolDeployment.sol';

interface ISynthereumPoolGeneral is
  ISynthereumPoolDeployment,
  ISynthereumPoolInteraction
{}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';

interface ISynthereumPoolInteraction {
  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the PoolRegister contract
   * @param srcDerivative Derivative used by the source pool
   * @param derivative The derivative of the destination pool to use for mint
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

  /**
   * @notice Check if a derivative is in the whitelist of this pool
   * @param derivative Perpetual derivative
   * @return isAdmitted Return true if in the whitelist, otherwise false
   */
  function isDerivativeAdmitted(IDerivative derivative)
    external
    view
    returns (bool isAdmitted);

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumPoolOnChainPriceFeed} from './IPoolOnChainPriceFeed.sol';
import {ISynthereumFinder} from '../../../versioning/interfaces/IFinder.sol';
import {
  EnumerableSet
} from '../../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';

interface ISynthereumPoolOnChainPriceFeedStorage {
  struct Storage {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum version
    uint8 version;
    // Collateral token
    IERC20 collateralToken;
    // Synthetic token
    IERC20 syntheticToken;
    // Restrict access to only EOA account
    bool isContractAllowed;
    // Derivatives supported
    EnumerableSet.AddressSet derivatives;
    // Starting collateralization ratio
    FixedPoint.Unsigned startingCollateralization;
    // Fees
    ISynthereumPoolOnChainPriceFeed.Fee fee;
    // Used with individual proportions to scale values
    uint256 totalFeeProportions;
    // Price identifier
    bytes32 priceIdentifier;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library Strings {
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    uint256 index = digits - 1;
    temp = value;
    while (temp != 0) {
      buffer[index--] = bytes1(uint8(48 + (temp % 10)));
      temp /= 10;
    }
    return string(buffer);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {ISynthereumPoolGeneral} from '../common/interfaces/IPoolGeneral.sol';
import {
  ISynthereumPoolOnChainPriceFeedStorage
} from './interfaces/IPoolOnChainPriceFeedStorage.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {IRole} from './interfaces/IRole.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumPoolRegistry
} from '../../versioning/interfaces/IPoolRegistry.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';

/**
 * @notice Pool implementation is stored here to reduce deployment costs
 */

library SynthereumPoolOnChainPriceFeedLib {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolOnChainPriceFeedLib for ISynthereumPoolOnChainPriceFeedStorage.Storage;
  using SynthereumPoolOnChainPriceFeedLib for IDerivative;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  struct ExecuteMintParams {
    // Amount of synth tokens to mint
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) needed for mint
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral minted + fees
    FixedPoint.Unsigned totCollateralAmount;
  }

  struct ExecuteRedeemParams {
    //Amount of synth tokens needed for redeem
    FixedPoint.Unsigned numTokens;
    // Amount of collateral that user will receive
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redeemed + fees
    FixedPoint.Unsigned totCollateralAmount;
  }

  struct ExecuteExchangeParams {
    // Amount of tokens to send
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) equivalent to synthetic token (exluding fees) to send
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redemeed + fees
    FixedPoint.Unsigned totCollateralAmount;
    // Amount of synthetic token to receive
    FixedPoint.Unsigned destNumTokens;
  }

  //----------------------------------------
  // Events
  //----------------------------------------
  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);
  // We may omit the pool from event since we can recover it from the address of smart contract emitting event, but for query convenience we include it in the event
  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  // Check that derivative must be whitelisted in this pool
  modifier checkDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) {
    require(self.derivatives.contains(address(derivative)), 'Wrong derivative');
    _;
  }

  // Check that the sender must be an EOA if the flag isContractAllowed is false
  modifier checkIsSenderContract(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self
  ) {
    if (!self.isContractAllowed) {
      require(tx.origin == msg.sender, 'Account must be an EOA');
    }
    _;
  }

  //----------------------------------------
  // External function
  //----------------------------------------

  /**
   * @notice Initializes a fresh on chain pool
   * @notice The derivative's collateral currency must be a Collateral Token
   * @notice `_startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param self Data type the library is attached to
   * @param _version Synthereum version of the pool
   * @param _finder Synthereum finder
   * @param _derivative The perpetual derivative
   * @param _startingCollateralization Collateralization ratio to use before a global one is set
   * @param _isContractAllowed Enable or disable the option to accept meta-tx only by an EOA for security reason
   */
  function initialize(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    uint8 _version,
    ISynthereumFinder _finder,
    IDerivative _derivative,
    FixedPoint.Unsigned memory _startingCollateralization,
    bool _isContractAllowed
  ) external {
    self.version = _version;
    self.finder = _finder;
    self.startingCollateralization = _startingCollateralization;
    self.isContractAllowed = _isContractAllowed;
    self.collateralToken = getDerivativeCollateral(_derivative);
    self.syntheticToken = _derivative.tokenCurrency();
    self.priceIdentifier = _derivative.positionManagerData().priceIdentifier;
    self.derivatives.add(address(_derivative));
    emit AddDerivative(address(this), address(_derivative));
  }

  /**
   * @notice Add a derivate to be linked to this pool
   * @param self Data type the library is attached to
   * @param derivative A perpetual derivative
   */
  function addDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.collateralToken == getDerivativeCollateral(derivative),
      'Wrong collateral of the new derivative'
    );
    require(
      self.syntheticToken == derivative.tokenCurrency(),
      'Wrong synthetic token'
    );
    require(
      self.derivatives.add(address(derivative)),
      'Derivative has already been included'
    );
    emit AddDerivative(address(this), address(derivative));
  }

  /**
   * @notice Remove a derivate linked to this pool
   * @param self Data type the library is attached to
   * @param derivative A perpetual derivative
   */
  function removeDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.derivatives.remove(address(derivative)),
      'Derivative not included'
    );
    emit RemoveDerivative(address(this), address(derivative));
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param self Data type the library is attached to
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the minter as fee
   */
  function mint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams
  )
    external
    checkIsSenderContract(self)
    returns (uint256 syntheticTokensMinted, uint256 feePaid)
  {
    FixedPoint.Unsigned memory totCollateralAmount =
      FixedPoint.Unsigned(mintParams.collateralAmount);
    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);
    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);
    FixedPoint.Unsigned memory numTokens =
      calculateNumberOfTokens(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        collateralAmount
      );
    require(
      numTokens.rawValue >= mintParams.minNumTokens,
      'Number of tokens less than minimum limit'
    );
    checkParams(
      self,
      mintParams.derivative,
      mintParams.feePercentage,
      mintParams.expiration
    );
    self.executeMint(
      mintParams.derivative,
      ExecuteMintParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount
      )
    );
    syntheticTokensMinted = numTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param self Data type the library is attached to
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams
  )
    external
    checkIsSenderContract(self)
    returns (uint256 collateralRedeemed, uint256 feePaid)
  {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(redeemParams.numTokens);
    FixedPoint.Unsigned memory totCollateralAmount =
      calculateCollateralAmount(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        numTokens
      );
    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);
    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);
    require(
      collateralAmount.rawValue >= redeemParams.minCollateral,
      'Collateral amount less than minimum limit'
    );
    checkParams(
      self,
      redeemParams.derivative,
      redeemParams.feePercentage,
      redeemParams.expiration
    );
    self.executeRedeem(
      redeemParams.derivative,
      ExecuteRedeemParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount
      )
    );
    feePaid = feeAmount.rawValue;
    collateralRedeemed = collateralAmount.rawValue;
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.ExchangeParams memory exchangeParams
  )
    external
    checkIsSenderContract(self)
    returns (uint256 destNumTokensMinted, uint256 feePaid)
  {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(exchangeParams.numTokens);

    FixedPoint.Unsigned memory totCollateralAmount =
      calculateCollateralAmount(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        numTokens
      );

    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);

    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);

    FixedPoint.Unsigned memory destNumTokens =
      calculateNumberOfTokens(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        exchangeParams.destPool.getPriceFeedIdentifier(),
        collateralAmount
      );

    require(
      destNumTokens.rawValue >= exchangeParams.minDestNumTokens,
      'Number of destination tokens less than minimum limit'
    );
    checkParams(
      self,
      exchangeParams.derivative,
      exchangeParams.feePercentage,
      exchangeParams.expiration
    );

    self.executeExchange(
      exchangeParams.derivative,
      exchangeParams.destPool,
      exchangeParams.destDerivative,
      ExecuteExchangeParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount,
        destNumTokens
      )
    );

    destNumTokensMinted = destNumTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the deployer
   * @param self Data type the library is attached to
   * @param srcDerivative Derivative used by the source pool
   * @param derivative Derivative that this pool will use
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative srcDerivative,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external {
    self.checkPool(ISynthereumPoolGeneral(msg.sender), srcDerivative);
    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    // Target the starting collateralization ratio if there is no global ratio
    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    // Check that LP collateral can support the tokens to be minted
    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        collateralAmount,
        numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    // Pull Collateral Tokens from calling Pool contract
    self.pullCollateral(msg.sender, collateralAmount);

    // Mint new tokens with the collateral
    self.mintSynTokens(
      derivative,
      numTokens.mulCeil(targetCollateralization),
      numTokens
    );

    // Transfer new tokens back to the calling Pool where they will be sent to the user
    self.transferSynTokens(msg.sender, numTokens);
  }

  /**
   * @notice Liquidity provider withdraw collateral from the pool
   * @param self Data type the library is attached to
   * @param collateralAmount The amount of collateral to withdraw
   */
  function withdrawFromPool(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) external {
    // Transfer the collateral from this pool to the LP sender
    self.collateralToken.safeTransfer(msg.sender, collateralAmount.rawValue);
  }

  /**
   * @notice Move collateral from Pool to its derivative in order to increase GCR
   * @param self Data type the library is attached to
   * @param derivative Derivative on which to deposit collateral
   * @param collateralAmount The amount of collateral to move into derivative
   */
  function depositIntoDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.deposit(collateralAmount);
  }

  /**
   * @notice Start a withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param self Data type the library is attached to
   * @param derivative Derivative from which request collateral withdrawal
   * @param collateralAmount The amount of short margin to withdraw
   */
  function slowWithdrawRequest(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    derivative.requestWithdrawal(collateralAmount);
  }

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param self Data type the library is attached to
   * @param derivative Derivative from which collateral withdrawal was requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdrawPassedRequest();
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param self Data type the library is attached to
   * @param derivative Derivative from which fast withdrawal was requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdraw(collateralAmount);
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  /**
   * @notice Actiavte emergency shutdown on a derivative in order to liquidate the token holders in case of emergency
   * @param self Data type the library is attached to
   * @param derivative Derivative on which emergency shutdown is called
   */
  function emergencyShutdown(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external checkDerivative(self, derivative) {
    derivative.emergencyShutdown();
  }

  /**
   * @notice Redeem tokens after derivative emergency shutdown
   * @param self Data type the library is attached to
   * @param derivative Derivative for which settlement is requested
   * @param liquidity_provider_role Lp role
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    bytes32 liquidity_provider_role
  ) external returns (uint256 amountSettled) {
    IERC20 tokenCurrency = self.syntheticToken;

    IERC20 collateralToken = self.collateralToken;

    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));

    //Check if sender is a LP
    bool isLiquidityProvider =
      IRole(address(this)).hasRole(liquidity_provider_role, msg.sender);

    // Make sure there is something for the user to settle
    require(
      numTokens.isGreaterThan(0) || isLiquidityProvider,
      'Account has nothing to settle'
    );

    if (numTokens.isGreaterThan(0)) {
      // Move synthetic tokens from the user to the pool
      // - This is because derivative expects the tokens to come from the sponsor address
      tokenCurrency.safeTransferFrom(
        msg.sender,
        address(this),
        numTokens.rawValue
      );

      // Allow the derivative to transfer tokens from the pool
      tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);
    }

    // Redeem the synthetic tokens for collateral
    derivative.settleEmergencyShutdown();

    // Amount of collateral that will be redeemed and sent to the user
    FixedPoint.Unsigned memory totalToRedeem;

    // If the user is the LP, send redeemed token collateral plus excess collateral
    if (isLiquidityProvider) {
      // Redeem LP collateral held in pool
      // Includes excess collateral withdrawn by a user previously calling `settleEmergencyShutdown`
      totalToRedeem = FixedPoint.Unsigned(
        collateralToken.balanceOf(address(this))
      );
    } else {
      // Otherwise, separate excess collateral from redeemed token value
      // Must be called after `emergencyShutdown` to make sure expiryPrice is set
      FixedPoint.Unsigned memory dueCollateral =
        numTokens.mul(derivative.emergencyShutdownPrice());

      totalToRedeem = FixedPoint.min(
        dueCollateral,
        FixedPoint.Unsigned(collateralToken.balanceOf(address(this)))
      );
    }
    amountSettled = totalToRedeem.rawValue;
    // Redeem the collateral for the underlying asset and transfer to the user
    collateralToken.safeTransfer(msg.sender, amountSettled);

    emit Settlement(
      msg.sender,
      address(this),
      numTokens.rawValue,
      amountSettled
    );
  }

  /**
   * @notice Update the fee percentage
   * @param self Data type the library is attached to
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory _feePercentage
  ) external {
    require(
      _feePercentage.rawValue < 10**(18),
      'Fee Percentage must be less than 100%'
    );
    self.fee.feePercentage = _feePercentage;
    emit SetFeePercentage(_feePercentage.rawValue);
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param self Data type the library is attached to
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external {
    require(
      _feeRecipients.length == _feeProportions.length,
      'Fee recipients and fee proportions do not match'
    );
    uint256 totalActualFeeProportions;
    // Store the sum of all proportions
    for (uint256 i = 0; i < _feeProportions.length; i++) {
      totalActualFeeProportions += _feeProportions[i];
    }
    self.fee.feeRecipients = _feeRecipients;
    self.fee.feeProportions = _feeProportions;
    self.totalFeeProportions = totalActualFeeProportions;
    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }

  /**
   * @notice Reset the starting collateral ratio - for example when you add a new derivative without collateral
   * @param startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function setStartingCollateralization(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory startingCollateralRatio
  ) external {
    self.startingCollateralization = startingCollateralRatio;
  }

  /**
   * @notice Add a role into derivative to another contract
   * @param self Data type the library is attached to
   * @param derivative Derivative in which a role is being added
   * @param derivativeRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolOnChainPriceFeed.DerivativeRoles derivativeRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (
      derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN
    ) {
      derivative.addAdmin(addressToAdd);
    } else {
      ISynthereumPoolGeneral pool = ISynthereumPoolGeneral(addressToAdd);
      IERC20 collateralToken = self.collateralToken;
      require(
        collateralToken == pool.collateralToken(),
        'Collateral tokens do not match'
      );
      require(
        self.syntheticToken == pool.syntheticToken(),
        'Synthetic tokens do not match'
      );
      ISynthereumFinder finder = self.finder;
      require(finder == pool.synthereumFinder(), 'Finders do not match');
      ISynthereumPoolRegistry poolRegister =
        ISynthereumPoolRegistry(
          finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
        );
      poolRegister.isPoolDeployed(
        pool.syntheticTokenSymbol(),
        collateralToken,
        pool.version(),
        address(pool)
      );
      if (
        derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.POOL
      ) {
        derivative.addPool(addressToAdd);
      } else if (
        derivativeRole ==
        ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN_AND_POOL
      ) {
        derivative.addAdminAndPool(addressToAdd);
      }
    }
  }

  /**
   * @notice Removing a role from a derivative contract
   * @param self Data type the library is attached to
   * @param derivative Derivative in which to remove a role
   * @param derivativeRole Role to remove
   */
  function renounceRoleInDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolOnChainPriceFeed.DerivativeRoles derivativeRole
  ) external checkDerivative(self, derivative) {
    if (
      derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN
    ) {
      derivative.renounceAdmin();
    } else if (
      derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.POOL
    ) {
      derivative.renouncePool();
    } else if (
      derivativeRole ==
      ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN_AND_POOL
    ) {
      derivative.renounceAdminAndPool();
    }
  }

  /**
   * @notice Add a role into synthetic token to another contract
   * @param self Data type the library is attached to
   * @param derivative Derivative in which adding role
   * @param synthTokenRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInSynthToken(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolOnChainPriceFeed.SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (
      synthTokenRole == ISynthereumPoolOnChainPriceFeed.SynthTokenRoles.ADMIN
    ) {
      derivative.addSyntheticTokenAdmin(addressToAdd);
    } else {
      require(
        self.syntheticToken == IDerivative(addressToAdd).tokenCurrency(),
        'Synthetic tokens do not match'
      );
      if (
        synthTokenRole == ISynthereumPoolOnChainPriceFeed.SynthTokenRoles.MINTER
      ) {
        derivative.addSyntheticTokenMinter(addressToAdd);
      } else if (
        synthTokenRole == ISynthereumPoolOnChainPriceFeed.SynthTokenRoles.BURNER
      ) {
        derivative.addSyntheticTokenBurner(addressToAdd);
      } else if (
        synthTokenRole ==
        ISynthereumPoolOnChainPriceFeed
          .SynthTokenRoles
          .ADMIN_AND_MINTER_AND_BURNER
      ) {
        derivative.addSyntheticTokenAdminAndMinterAndBurner(addressToAdd);
      }
    }
  }

  /**
   * @notice Set the possibility to accept only EOA meta-tx
   * @param self Data type the library is attached to
   * @param isContractAllowed Flag that represent options to receive tx by a contract or only EOA
   */
  function setIsContractAllowed(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    bool isContractAllowed
  ) external {
    require(
      self.isContractAllowed != isContractAllowed,
      'Contract flag already set'
    );
    self.isContractAllowed = isContractAllowed;
  }

  //----------------------------------------
  //  Internal functions
  //----------------------------------------

  /**
   * @notice Execute mint of synthetic tokens
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param executeMintParams Params for execution of mint (see ExecuteMintParams struct)
   */
  function executeMint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ExecuteMintParams memory executeMintParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeMintParams.collateralAmount.isGreaterThan(0),
      'Sending amount is equal to 0'
    );

    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    // Target the starting collateralization ratio if there is no global ratio
    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    // Check that LP collateral can support the tokens to be minted
    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        executeMintParams.collateralAmount,
        executeMintParams.numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    // Pull user's collateral and mint fee into the pool
    self.pullCollateral(msg.sender, executeMintParams.totCollateralAmount);

    // Mint synthetic asset with collateral from user and liquidity provider
    self.mintSynTokens(
      derivative,
      executeMintParams.numTokens.mulCeil(targetCollateralization),
      executeMintParams.numTokens
    );

    // Transfer synthetic assets to the user
    self.transferSynTokens(msg.sender, executeMintParams.numTokens);

    // Send fees
    self.sendFee(executeMintParams.feeAmount);

    emit Mint(
      msg.sender,
      address(this),
      executeMintParams.totCollateralAmount.rawValue,
      executeMintParams.numTokens.rawValue,
      executeMintParams.feeAmount.rawValue
    );
  }

  /**
   * @notice Execute redeem of collateral
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param executeRedeemParams Params for execution of redeem (see ExecuteRedeemParams struct)
   */
  function executeRedeem(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ExecuteRedeemParams memory executeRedeemParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeRedeemParams.numTokens.isGreaterThan(0),
      'Sending amount is equal to 0'
    );
    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(
        msg.sender,
        derivative,
        executeRedeemParams.numTokens
      );
    require(
      amountWithdrawn.isGreaterThan(executeRedeemParams.totCollateralAmount),
      'Collateral from derivative less than collateral amount'
    );

    //Send net amount of collateral to the user that submited the redeem request
    self.collateralToken.safeTransfer(
      msg.sender,
      executeRedeemParams.collateralAmount.rawValue
    );
    // Send fees collected
    self.sendFee(executeRedeemParams.feeAmount);

    emit Redeem(
      msg.sender,
      address(this),
      executeRedeemParams.numTokens.rawValue,
      executeRedeemParams.collateralAmount.rawValue,
      executeRedeemParams.feeAmount.rawValue
    );
  }

  /**
   * @notice Execute exchange between synthetic tokens
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param destPool Pool of synthetic token to receive
   * @param destDerivative Derivative of the pool of synthetic token to receive
   * @param executeExchangeParams Params for execution of exchange (see ExecuteExchangeParams struct)
   */
  function executeExchange(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolGeneral destPool,
    IDerivative destDerivative,
    ExecuteExchangeParams memory executeExchangeParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeExchangeParams.numTokens.isGreaterThan(0),
      'Sending amount is equal to 0'
    );
    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(
        msg.sender,
        derivative,
        executeExchangeParams.numTokens
      );

    require(
      amountWithdrawn.isGreaterThan(executeExchangeParams.totCollateralAmount),
      'Collateral from derivative less than collateral amount'
    );
    self.checkPool(destPool, destDerivative);

    self.sendFee(executeExchangeParams.feeAmount);

    self.collateralToken.safeApprove(
      address(destPool),
      executeExchangeParams.collateralAmount.rawValue
    );
    // Mint the destination tokens with the withdrawn collateral
    destPool.exchangeMint(
      derivative,
      destDerivative,
      executeExchangeParams.collateralAmount.rawValue,
      executeExchangeParams.destNumTokens.rawValue
    );

    // Transfer the new tokens to the user
    destDerivative.tokenCurrency().safeTransfer(
      msg.sender,
      executeExchangeParams.destNumTokens.rawValue
    );

    emit Exchange(
      msg.sender,
      address(this),
      address(destPool),
      executeExchangeParams.numTokens.rawValue,
      executeExchangeParams.destNumTokens.rawValue,
      executeExchangeParams.feeAmount.rawValue
    );
  }

  /**
   * @notice Pulls collateral tokens from the sender to store in the Pool
   * @param self Data type the library is attached to
   * @param numTokens The number of tokens to pull
   */
  function pullCollateral(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeTransferFrom(
      from,
      address(this),
      numTokens.rawValue
    );
  }

  /**
   * @notice Mints synthetic tokens with the available collateral
   * @param self Data type the library is attached to
   * @param collateralAmount The amount of collateral to send
   * @param numTokens The number of tokens to mint
   */
  function mintSynTokens(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.create(collateralAmount, numTokens);
  }

  /**
   * @notice Transfer synthetic tokens from the derivative to an address
   * @dev Refactored from `mint` to guard against reentrancy
   * @param self Data type the library is attached to
   * @param recipient The address to send the tokens
   * @param numTokens The number of tokens to send
   */
  function transferSynTokens(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address recipient,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.syntheticToken.safeTransfer(recipient, numTokens.rawValue);
  }

  /**
   * @notice Redeem synthetic tokens for collateral from the derivative
   * @param tokenHolder Address of the user that redeems
   * @param derivative Derivative from which collateral is redeemed
   * @param numTokens The number of tokens to redeem
   * @return amountWithdrawn Collateral amount withdrawn by redeem execution
   */
  function redeemForCollateral(
    address tokenHolder,
    IDerivative derivative,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (FixedPoint.Unsigned memory amountWithdrawn) {
    IERC20 tokenCurrency = derivative.positionManagerData().tokenCurrency;
    require(
      tokenCurrency.balanceOf(tokenHolder) >= numTokens.rawValue,
      'Token balance less than token to redeem'
    );

    // Move synthetic tokens from the user to the Pool
    // - This is because derivative expects the tokens to come from the sponsor address
    tokenCurrency.safeTransferFrom(
      tokenHolder,
      address(this),
      numTokens.rawValue
    );

    // Allow the derivative to transfer tokens from the Pool
    tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);

    // Redeem the synthetic tokens for Collateral tokens
    amountWithdrawn = derivative.redeem(numTokens);
  }

  /**
   * @notice Send collateral withdrawn by the derivative to the LP
   * @param self Data type the library is attached to
   * @param collateralAmount Amount of collateral to send to the LP
   * @param recipient Address of a LP
   * @return amountWithdrawn Collateral amount withdrawn
   */
  function liquidateWithdrawal(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    address recipient
  ) internal returns (uint256 amountWithdrawn) {
    amountWithdrawn = collateralAmount.rawValue;
    self.collateralToken.safeTransfer(recipient, amountWithdrawn);
  }

  /**
   * @notice Set the Pool fee structure parameters
   * @param self Data type the library is attached tfo
   * @param _feeAmount Amount of fee to send
   */
  function sendFee(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory _feeAmount
  ) internal {
    // Distribute fees
    // TODO Consider using the withdrawal pattern for fees
    for (uint256 i = 0; i < self.fee.feeRecipients.length; i++) {
      self.collateralToken.safeTransfer(
        self.fee.feeRecipients[i],
        // This order is important because it mixes FixedPoint with unscaled uint
        _feeAmount
          .mul(self.fee.feeProportions[i])
          .div(self.totalFeeProportions)
          .rawValue
      );
    }
  }

  //----------------------------------------
  //  Internal views functions
  //----------------------------------------

  /**
   * @notice Check fee percentage and expiration of mint, redeem and exchange transaction
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param feePercentage Maximum percentage of fee that a user want to pay
   * @param expiration Expiration time of the transaction
   */
  function checkParams(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    uint256 feePercentage,
    uint256 expiration
  ) internal view checkDerivative(self, derivative) {
    require(now <= expiration, 'Transaction expired');
    require(
      self.fee.feePercentage.rawValue <= feePercentage,
      'User fee percentage less than actual one'
    );
  }

  /**
   * @notice Get the address of collateral of a perpetual derivative
   * @param derivative Address of the perpetual derivative
   * @return collateral Address of the collateral of perpetual derivative
   */
  function getDerivativeCollateral(IDerivative derivative)
    internal
    view
    returns (IERC20 collateral)
  {
    collateral = derivative.collateralCurrency();
  }

  /**
   * @notice Get the global collateralization ratio of the derivative
   * @param derivative Perpetual derivative contract
   * @return The global collateralization ratio
   */
  function getGlobalCollateralizationRatio(IDerivative derivative)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    FixedPoint.Unsigned memory totalTokensOutstanding =
      derivative.globalPositionData().totalTokensOutstanding;
    if (totalTokensOutstanding.isGreaterThan(0)) {
      return derivative.totalPositionCollateral().div(totalTokensOutstanding);
    } else {
      return FixedPoint.fromUnscaledUint(0);
    }
  }

  /**
   * @notice Check if a call to `mint` with the supplied parameters will succeed
   * @dev Compares the new collateral from `collateralAmount` combined with LP collateral
   *      against the collateralization ratio of the derivative.
   * @param self Data type the library is attached to
   * @param globalCollateralization The global collateralization ratio of the derivative
   * @param collateralAmount The amount of additional collateral supplied
   * @param numTokens The number of tokens to mint
   * @return `true` if there is sufficient collateral
   */
  function checkCollateralizationRatio(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory globalCollateralization,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (bool) {
    // Collateral ratio possible for new tokens accounting for LP collateral
    FixedPoint.Unsigned memory newCollateralization =
      collateralAmount
        .add(FixedPoint.Unsigned(self.collateralToken.balanceOf(address(this))))
        .div(numTokens);

    // Check that LP collateral can support the tokens to be minted
    return newCollateralization.isGreaterThanOrEqual(globalCollateralization);
  }

  /**
   * @notice Check if sender or receiver pool is a correct registered pool
   * @param self Data type the library is attached to
   * @param poolToCheck Pool that should be compared with this pool
   * @param derivativeToCheck Derivative of poolToCheck
   */
  function checkPool(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolGeneral poolToCheck,
    IDerivative derivativeToCheck
  ) internal view {
    require(
      poolToCheck.isDerivativeAdmitted(derivativeToCheck),
      'Wrong derivative'
    );
    IERC20 collateralToken = self.collateralToken;
    require(
      collateralToken == poolToCheck.collateralToken(),
      'Collateral tokens do not match'
    );
    ISynthereumFinder finder = self.finder;
    require(finder == poolToCheck.synthereumFinder(), 'Finders do not match');
    ISynthereumPoolRegistry poolRegister =
      ISynthereumPoolRegistry(
        finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
      );
    require(
      poolRegister.isPoolDeployed(
        poolToCheck.syntheticTokenSymbol(),
        collateralToken,
        poolToCheck.version(),
        address(poolToCheck)
      ),
      'Destination pool not registred'
    );
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token, using on-chain oracle
   * @param finder Synthereum finder
   * @param collateralToken Collateral token contract
   * @param priceIdentifier Identifier of price pair
   * @param numTokens Amount of synthetic tokens from which you want to calculate collateral amount
   * @return collateralAmount Amount of collateral after on-chain oracle conversion
   */
  function calculateCollateralAmount(
    ISynthereumFinder finder,
    IStandardERC20 collateralToken,
    bytes32 priceIdentifier,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (FixedPoint.Unsigned memory collateralAmount) {
    FixedPoint.Unsigned memory priceRate =
      getPriceFeedRate(finder, priceIdentifier);
    uint256 decimalsOfCollateral = getCollateralDecimals(collateralToken);
    collateralAmount = numTokens.mul(priceRate).div(
      10**((uint256(18)).sub(decimalsOfCollateral))
    );
  }

  /**
   * @notice Calculate synthetic token amount starting from an amount of collateral, using on-chain oracle
   * @param finder Synthereum finder
   * @param collateralToken Collateral token contract
   * @param priceIdentifier Identifier of price pair
   * @param numTokens Amount of collateral from which you want to calculate synthetic token amount
   * @return numTokens Amount of tokens after on-chain oracle conversion
   */
  function calculateNumberOfTokens(
    ISynthereumFinder finder,
    IStandardERC20 collateralToken,
    bytes32 priceIdentifier,
    FixedPoint.Unsigned memory collateralAmount
  ) internal view returns (FixedPoint.Unsigned memory numTokens) {
    FixedPoint.Unsigned memory priceRate =
      getPriceFeedRate(finder, priceIdentifier);
    uint256 decimalsOfCollateral = getCollateralDecimals(collateralToken);
    numTokens = collateralAmount
      .mul(10**((uint256(18)).sub(decimalsOfCollateral)))
      .div(priceRate);
  }

  /**
   * @notice Retrun the on-chain oracle price for a pair
   * @param finder Synthereum finder
   * @param priceIdentifier Identifier of price pair
   * @return priceRate Latest rate of the pair
   */
  function getPriceFeedRate(ISynthereumFinder finder, bytes32 priceIdentifier)
    internal
    view
    returns (FixedPoint.Unsigned memory priceRate)
  {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );
    priceRate = FixedPoint.Unsigned(priceFeed.getLatestPrice(priceIdentifier));
  }

  /**
   * @notice Retrun the number of decimals of collateral token
   * @param collateralToken Collateral token contract
   * @return decimals number of decimals
   */
  function getCollateralDecimals(IStandardERC20 collateralToken)
    internal
    view
    returns (uint256 decimals)
  {
    decimals = collateralToken.decimals();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Access role interface
 */
interface IRole {
  // Check if an address has a role
  function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './IERC20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance =
      token.allowance(address(this), spender).sub(
        value,
        'SafeERC20: decreased allowance below zero'
      );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata =
      address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      require(
        abi.decode(returndata, (bool)),
        'SafeERC20: ERC20 operation did not succeed'
      );
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  ISynthereumPoolOnChainPriceFeed
} from '../synthereum-pool/v3/interfaces/IPoolOnChainPriceFeed.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ContractAllowedOnChanPriceFeed {
  ISynthereumPoolOnChainPriceFeed public pool;
  IERC20 public collateral;

  constructor(address _pool, address _collateral) public {
    pool = ISynthereumPoolOnChainPriceFeed(_pool);
    collateral = IERC20(_collateral);
  }

  function mintInPool(
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams,
    uint256 approveAmount
  ) external {
    collateral.approve(address(pool), approveAmount);
    pool.mint(mintParams);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumPool} from './interfaces/IPool.sol';
import {ISynthereumPoolStorage} from './interfaces/IPoolStorage.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {ISynthereumDeployer} from '../../versioning/interfaces/IDeployer.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {Strings} from '../../../@openzeppelin/contracts/utils/Strings.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {SynthereumPoolLib} from './PoolLib.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';
import {
  AccessControl
} from '../../../@openzeppelin/contracts/access/AccessControl.sol';

contract SynthereumPool is
  AccessControl,
  ISynthereumPoolStorage,
  ISynthereumPool,
  Lockable
{
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolLib for Storage;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  bytes32 public constant VALIDATOR_ROLE = keccak256('Validator');

  bytes32 public immutable MINT_TYPEHASH;

  bytes32 public immutable REDEEM_TYPEHASH;

  bytes32 public immutable EXCHANGE_TYPEHASH;

  bytes32 public DOMAIN_SEPARATOR;

  Storage private poolStorage;

  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyLiquidityProvider() {
    require(
      hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender),
      'Sender must be the liquidity provider'
    );
    _;
  }

  constructor(
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    Roles memory _roles,
    bool _isContractAllowed,
    uint256 _startingCollateralization,
    Fee memory _fee
  ) public nonReentrant {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(VALIDATOR_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
    _setupRole(LIQUIDITY_PROVIDER_ROLE, _roles.liquidityProvider);
    _setupRole(VALIDATOR_ROLE, _roles.validator);
    poolStorage.initialize(
      _version,
      _finder,
      _derivative,
      FixedPoint.Unsigned(_startingCollateralization),
      _isContractAllowed
    );
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        ),
        keccak256(bytes('Synthereum Pool')),
        keccak256(bytes(Strings.toString(_version))),
        getChainID(),
        address(this)
      )
    );
    MINT_TYPEHASH = keccak256(
      'MintParameters(address sender,address derivativeAddr,uint256 collateralAmount,uint256 numTokens,uint256 feePercentage,uint256 nonce,uint256 expiration)'
    );
    REDEEM_TYPEHASH = keccak256(
      'RedeemParameters(address sender,address derivativeAddr,uint256 collateralAmount,uint256 numTokens,uint256 feePercentage,uint256 nonce,uint256 expiration)'
    );
    EXCHANGE_TYPEHASH = keccak256(
      'ExchangeParameters(address sender,address derivativeAddr,address destPoolAddr,address destDerivativeAddr,uint256 numTokens,uint256 collateralAmount,uint256 destNumTokens,uint256 feePercentage,uint256 nonce,uint256 expiration)'
    );
  }

  function addDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.addDerivative(derivative);
  }

  function removeDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.removeDerivative(derivative);
  }

  function mint(MintParameters memory mintMetaTx, Signature memory signature)
    external
    override
    nonReentrant
    returns (uint256 feePaid)
  {
    feePaid = poolStorage.mint(
      mintMetaTx,
      SignatureVerificationParams(
        DOMAIN_SEPARATOR,
        MINT_TYPEHASH,
        signature,
        VALIDATOR_ROLE
      )
    );
  }

  function redeem(
    RedeemParameters memory redeemMetaTx,
    Signature memory signature
  ) external override nonReentrant returns (uint256 feePaid) {
    feePaid = poolStorage.redeem(
      redeemMetaTx,
      SignatureVerificationParams(
        DOMAIN_SEPARATOR,
        REDEEM_TYPEHASH,
        signature,
        VALIDATOR_ROLE
      )
    );
  }

  function exchange(
    ExchangeParameters memory exchangeMetaTx,
    Signature memory signature
  ) external override nonReentrant returns (uint256 feePaid) {
    feePaid = poolStorage.exchange(
      exchangeMetaTx,
      SignatureVerificationParams(
        DOMAIN_SEPARATOR,
        EXCHANGE_TYPEHASH,
        signature,
        VALIDATOR_ROLE
      )
    );
  }

  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external override nonReentrant {
    poolStorage.exchangeMint(
      srcDerivative,
      derivative,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens)
    );
  }

  function withdrawFromPool(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.withdrawFromPool(FixedPoint.Unsigned(collateralAmount));
  }

  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external override onlyLiquidityProvider nonReentrant {
    poolStorage.depositIntoDerivative(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.slowWithdrawRequest(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.slowWithdrawPassedRequest(derivative);
  }

  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.fastWithdraw(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function emergencyShutdown(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.emergencyShutdown(derivative);
  }

  function settleEmergencyShutdown(IDerivative derivative)
    external
    override
    nonReentrant
    returns (uint256 amountSettled)
  {
    amountSettled = poolStorage.settleEmergencyShutdown(
      derivative,
      LIQUIDITY_PROVIDER_ROLE
    );
  }

  function setFeePercentage(uint256 _feePercentage)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
  }

  function setFeeRecipients(
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external override onlyMaintainer nonReentrant {
    poolStorage.setFeeRecipients(_feeRecipients, _feeProportions);
  }

  function setStartingCollateralization(uint256 startingCollateralRatio)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setStartingCollateralization(
      FixedPoint.Unsigned(startingCollateralRatio)
    );
  }

  function addRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInDerivative(derivative, derivativeRole, addressToAdd);
  }

  function renounceRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole
  ) external override onlyMaintainer nonReentrant {
    poolStorage.renounceRoleInDerivative(derivative, derivativeRole);
  }

  function addRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInSynthToken(derivative, synthTokenRole, addressToAdd);
  }

  function renounceRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole
  ) external override onlyMaintainer nonReentrant {
    poolStorage.renounceRoleInSynthToken(derivative, synthTokenRole);
  }

  function setIsContractAllowed(bool isContractAllowed)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setIsContractAllowed(isContractAllowed);
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = poolStorage.finder;
  }

  function version() external view override returns (uint8 poolVersion) {
    poolVersion = poolStorage.version;
  }

  function collateralToken()
    external
    view
    override
    returns (IERC20 collateralCurrency)
  {
    collateralCurrency = poolStorage.collateralToken;
  }

  function syntheticToken()
    external
    view
    override
    returns (IERC20 syntheticCurrency)
  {
    syntheticCurrency = poolStorage.syntheticToken;
  }

  function getAllDerivatives()
    external
    view
    override
    returns (IDerivative[] memory)
  {
    EnumerableSet.AddressSet storage derivativesSet = poolStorage.derivatives;
    uint256 numberOfDerivatives = derivativesSet.length();
    IDerivative[] memory derivatives = new IDerivative[](numberOfDerivatives);
    for (uint256 j = 0; j < numberOfDerivatives; j++) {
      derivatives[j] = (IDerivative(derivativesSet.at(j)));
    }
    return derivatives;
  }

  function isDerivativeAdmitted(IDerivative derivative)
    external
    view
    override
    returns (bool isAdmitted)
  {
    isAdmitted = poolStorage.derivatives.contains(address(derivative));
  }

  function getStartingCollateralization()
    external
    view
    override
    returns (uint256 startingCollateralRatio)
  {
    startingCollateralRatio = poolStorage.startingCollateralization.rawValue;
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(poolStorage.syntheticToken)).symbol();
  }

  function isContractAllowed() external view override returns (bool isAllowed) {
    isAllowed = poolStorage.isContractAllowed;
  }

  function getFeeInfo() external view override returns (Fee memory fee) {
    fee = poolStorage.fee;
  }

  function getUserNonce(address user)
    external
    view
    override
    returns (uint256 nonce)
  {
    nonce = poolStorage.nonces[user];
  }

  function calculateFee(uint256 collateralAmount)
    external
    view
    override
    returns (uint256 fee)
  {
    fee = FixedPoint
      .Unsigned(collateralAmount)
      .mul(poolStorage.fee.feePercentage)
      .rawValue;
  }

  function setFee(Fee memory _fee) public override onlyMaintainer nonReentrant {
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  function getChainID() private pure returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';
import {
  ISynthereumDeployer
} from '../../../versioning/interfaces/IDeployer.sol';
import {ISynthereumFinder} from '../../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumPoolDeployment
} from '../../common/interfaces/IPoolDeployment.sol';

interface ISynthereumPool is ISynthereumPoolDeployment {
  struct Fee {
    FixedPoint.Unsigned feePercentage;
    address[] feeRecipients;
    uint32[] feeProportions;
  }

  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
    address validator;
  }

  struct MintParameters {
    address sender;
    address derivativeAddr;
    uint256 collateralAmount;
    uint256 numTokens;
    uint256 feePercentage;
    uint256 nonce;
    uint256 expiration;
  }

  struct RedeemParameters {
    address sender;
    address derivativeAddr;
    uint256 collateralAmount;
    uint256 numTokens;
    uint256 feePercentage;
    uint256 nonce;
    uint256 expiration;
  }

  struct ExchangeParameters {
    address sender;
    address derivativeAddr;
    address destPoolAddr;
    address destDerivativeAddr;
    uint256 numTokens;
    uint256 collateralAmount;
    uint256 destNumTokens;
    uint256 feePercentage;
    uint256 nonce;
    uint256 expiration;
  }

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct SignatureVerificationParams {
    bytes32 domain_separator;
    bytes32 typeHash;
    ISynthereumPool.Signature signature;
    bytes32 validator_role;
  }

  enum DerivativeRoles {ADMIN, POOL, ADMIN_AND_POOL}

  enum SynthTokenRoles {ADMIN, MINTER, BURNER, ADMIN_AND_MINTER_AND_BURNER}

  function addDerivative(IDerivative derivative) external;

  function removeDerivative(IDerivative derivative) external;

  function mint(MintParameters memory mintMetaTx, Signature memory signature)
    external
    returns (uint256 feePaid);

  function redeem(
    RedeemParameters memory redeemMetaTx,
    Signature memory signature
  ) external returns (uint256 feePaid);

  function exchange(
    ExchangeParameters memory exchangeMetaTx,
    Signature memory signature
  ) external returns (uint256 feePaid);

  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

  function withdrawFromPool(uint256 collateralAmount) external;

  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external;

  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external;

  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    returns (uint256 amountWithdrawn);

  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    returns (uint256 amountWithdrawn);

  function emergencyShutdown(IDerivative derivative) external;

  function settleEmergencyShutdown(IDerivative derivative)
    external
    returns (uint256 amountSettled);

  function setFee(Fee memory _fee) external;

  function setFeePercentage(uint256 _feePercentage) external;

  function setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) external;

  function setStartingCollateralization(uint256 startingCollateralRatio)
    external;

  function addRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external;

  function renounceRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole
  ) external;

  function addRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external;

  function renounceRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole
  ) external;

  function setIsContractAllowed(bool isContractAllowed) external;

  function getAllDerivatives() external view returns (IDerivative[] memory);

  function isDerivativeAdmitted(IDerivative derivative)
    external
    view
    returns (bool isAdmitted);

  function getStartingCollateralization()
    external
    view
    returns (uint256 startingCollateralRatio);

  function isContractAllowed() external view returns (bool isAllowed);

  function getFeeInfo() external view returns (Fee memory fee);

  function getUserNonce(address user) external view returns (uint256 nonce);

  function calculateFee(uint256 collateralAmount)
    external
    view
    returns (uint256 fee);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumPool} from './IPool.sol';
import {ISynthereumFinder} from '../../../versioning/interfaces/IFinder.sol';
import {
  EnumerableSet
} from '../../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';

interface ISynthereumPoolStorage {
  struct Storage {
    ISynthereumFinder finder;
    uint8 version;
    IERC20 collateralToken;
    IERC20 syntheticToken;
    bool isContractAllowed;
    EnumerableSet.AddressSet derivatives;
    FixedPoint.Unsigned startingCollateralization;
    ISynthereumPool.Fee fee;
    uint256 totalFeeProportions;
    mapping(address => uint256) nonces;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumPool} from './interfaces/IPool.sol';
import {ISynthereumPoolStorage} from './interfaces/IPoolStorage.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {IRole} from './interfaces/IRole.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumPoolRegistry
} from '../../versioning/interfaces/IPoolRegistry.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';

library SynthereumPoolLib {
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolLib for ISynthereumPoolStorage.Storage;
  using SynthereumPoolLib for IDerivative;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

  modifier checkDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) {
    require(self.derivatives.contains(address(derivative)), 'Wrong derivative');
    _;
  }

  modifier checkIsSenderContract(ISynthereumPoolStorage.Storage storage self) {
    if (!self.isContractAllowed) {
      require(tx.origin == msg.sender, 'Account must be an EOA');
    }
    _;
  }

  function initialize(
    ISynthereumPoolStorage.Storage storage self,
    uint8 _version,
    ISynthereumFinder _finder,
    IDerivative _derivative,
    FixedPoint.Unsigned memory _startingCollateralization,
    bool _isContractAllowed
  ) external {
    self.derivatives.add(address(_derivative));
    emit AddDerivative(address(this), address(_derivative));
    self.version = _version;
    self.finder = _finder;
    self.startingCollateralization = _startingCollateralization;
    self.isContractAllowed = _isContractAllowed;
    self.collateralToken = getDerivativeCollateral(_derivative);
    self.syntheticToken = _derivative.tokenCurrency();
  }

  function addDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.collateralToken == getDerivativeCollateral(derivative),
      'Wrong collateral of the new derivative'
    );
    require(
      self.syntheticToken == derivative.tokenCurrency(),
      'Wrong synthetic token'
    );
    require(
      self.derivatives.add(address(derivative)),
      'Derivative has already been included'
    );
    emit AddDerivative(address(this), address(derivative));
  }

  function removeDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.derivatives.remove(address(derivative)),
      'Derivative not included'
    );
    emit RemoveDerivative(address(this), address(derivative));
  }

  function mint(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool.MintParameters memory mintMetaTx,
    ISynthereumPool.SignatureVerificationParams
      memory signatureVerificationParams
  ) external checkIsSenderContract(self) returns (uint256 feePaid) {
    bytes32 digest =
      generateMintDigest(
        mintMetaTx,
        signatureVerificationParams.domain_separator,
        signatureVerificationParams.typeHash
      );
    checkSignature(
      signatureVerificationParams.validator_role,
      digest,
      signatureVerificationParams.signature
    );
    self.checkMetaTxParams(
      mintMetaTx.sender,
      mintMetaTx.derivativeAddr,
      mintMetaTx.feePercentage,
      mintMetaTx.nonce,
      mintMetaTx.expiration
    );

    FixedPoint.Unsigned memory collateralAmount =
      FixedPoint.Unsigned(mintMetaTx.collateralAmount);
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(mintMetaTx.numTokens);
    IDerivative derivative = IDerivative(mintMetaTx.derivativeAddr);
    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        collateralAmount,
        numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    FixedPoint.Unsigned memory feeTotal =
      collateralAmount.mul(self.fee.feePercentage);

    self.pullCollateral(mintMetaTx.sender, collateralAmount.add(feeTotal));

    self.mintSynTokens(
      derivative,
      numTokens.mulCeil(targetCollateralization),
      numTokens
    );

    self.transferSynTokens(mintMetaTx.sender, numTokens);

    self.sendFee(feeTotal);

    feePaid = feeTotal.rawValue;

    emit Mint(
      mintMetaTx.sender,
      address(this),
      collateralAmount.add(feeTotal).rawValue,
      numTokens.rawValue,
      feePaid
    );
  }

  function redeem(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool.RedeemParameters memory redeemMetaTx,
    ISynthereumPool.SignatureVerificationParams
      memory signatureVerificationParams
  ) external checkIsSenderContract(self) returns (uint256 feePaid) {
    bytes32 digest =
      generateRedeemDigest(
        redeemMetaTx,
        signatureVerificationParams.domain_separator,
        signatureVerificationParams.typeHash
      );
    checkSignature(
      signatureVerificationParams.validator_role,
      digest,
      signatureVerificationParams.signature
    );
    self.checkMetaTxParams(
      redeemMetaTx.sender,
      redeemMetaTx.derivativeAddr,
      redeemMetaTx.feePercentage,
      redeemMetaTx.nonce,
      redeemMetaTx.expiration
    );
    FixedPoint.Unsigned memory collateralAmount =
      FixedPoint.Unsigned(redeemMetaTx.collateralAmount);
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(redeemMetaTx.numTokens);
    IDerivative derivative = IDerivative(redeemMetaTx.derivativeAddr);

    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(redeemMetaTx.sender, derivative, numTokens);
    require(
      amountWithdrawn.isGreaterThan(collateralAmount),
      'Collateral amount bigger than collateral in the derivative'
    );

    FixedPoint.Unsigned memory feeTotal =
      collateralAmount.mul(self.fee.feePercentage);

    uint256 netReceivedCollateral = (collateralAmount.sub(feeTotal)).rawValue;

    self.collateralToken.safeTransfer(
      redeemMetaTx.sender,
      netReceivedCollateral
    );

    self.sendFee(feeTotal);

    feePaid = feeTotal.rawValue;

    emit Redeem(
      redeemMetaTx.sender,
      address(this),
      numTokens.rawValue,
      netReceivedCollateral,
      feePaid
    );
  }

  function exchange(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool.ExchangeParameters memory exchangeMetaTx,
    ISynthereumPool.SignatureVerificationParams
      memory signatureVerificationParams
  ) external checkIsSenderContract(self) returns (uint256 feePaid) {
    {
      bytes32 digest =
        generateExchangeDigest(
          exchangeMetaTx,
          signatureVerificationParams.domain_separator,
          signatureVerificationParams.typeHash
        );
      checkSignature(
        signatureVerificationParams.validator_role,
        digest,
        signatureVerificationParams.signature
      );
    }
    self.checkMetaTxParams(
      exchangeMetaTx.sender,
      exchangeMetaTx.derivativeAddr,
      exchangeMetaTx.feePercentage,
      exchangeMetaTx.nonce,
      exchangeMetaTx.expiration
    );
    FixedPoint.Unsigned memory collateralAmount =
      FixedPoint.Unsigned(exchangeMetaTx.collateralAmount);
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(exchangeMetaTx.numTokens);
    IDerivative derivative = IDerivative(exchangeMetaTx.derivativeAddr);
    IDerivative destDerivative = IDerivative(exchangeMetaTx.destDerivativeAddr);

    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(exchangeMetaTx.sender, derivative, numTokens);
    self.checkPool(
      ISynthereumPool(exchangeMetaTx.destPoolAddr),
      destDerivative
    );
    require(
      amountWithdrawn.isGreaterThan(collateralAmount),
      'Collateral amount bigger than collateral in the derivative'
    );

    FixedPoint.Unsigned memory feeTotal =
      collateralAmount.mul(self.fee.feePercentage);

    self.sendFee(feeTotal);

    FixedPoint.Unsigned memory destinationCollateral =
      amountWithdrawn.sub(feeTotal);

    self.collateralToken.safeApprove(
      exchangeMetaTx.destPoolAddr,
      destinationCollateral.rawValue
    );

    ISynthereumPool(exchangeMetaTx.destPoolAddr).exchangeMint(
      derivative,
      destDerivative,
      destinationCollateral.rawValue,
      exchangeMetaTx.destNumTokens
    );

    destDerivative.tokenCurrency().safeTransfer(
      exchangeMetaTx.sender,
      exchangeMetaTx.destNumTokens
    );

    feePaid = feeTotal.rawValue;

    emit Exchange(
      exchangeMetaTx.sender,
      address(this),
      exchangeMetaTx.destPoolAddr,
      numTokens.rawValue,
      exchangeMetaTx.destNumTokens,
      feePaid
    );
  }

  function exchangeMint(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative srcDerivative,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external {
    self.checkPool(ISynthereumPool(msg.sender), srcDerivative);
    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        collateralAmount,
        numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    self.pullCollateral(msg.sender, collateralAmount);

    self.mintSynTokens(
      derivative,
      numTokens.mulCeil(targetCollateralization),
      numTokens
    );

    self.transferSynTokens(msg.sender, numTokens);
  }

  function withdrawFromPool(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) external {
    self.collateralToken.safeTransfer(msg.sender, collateralAmount.rawValue);
  }

  function depositIntoDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.deposit(collateralAmount);
  }

  function slowWithdrawRequest(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    derivative.requestWithdrawal(collateralAmount);
  }

  function slowWithdrawPassedRequest(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdrawPassedRequest();
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  function fastWithdraw(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdraw(collateralAmount);
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  function emergencyShutdown(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) external checkDerivative(self, derivative) {
    derivative.emergencyShutdown();
  }

  function settleEmergencyShutdown(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    bytes32 liquidity_provider_role
  ) external returns (uint256 amountSettled) {
    IERC20 tokenCurrency = self.syntheticToken;

    IERC20 collateralToken = self.collateralToken;

    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));

    bool isLiquidityProvider =
      IRole(address(this)).hasRole(liquidity_provider_role, msg.sender);

    require(
      numTokens.isGreaterThan(0) || isLiquidityProvider,
      'Account has nothing to settle'
    );

    if (numTokens.isGreaterThan(0)) {
      tokenCurrency.safeTransferFrom(
        msg.sender,
        address(this),
        numTokens.rawValue
      );

      tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);
    }

    derivative.settleEmergencyShutdown();

    FixedPoint.Unsigned memory totalToRedeem;

    if (isLiquidityProvider) {
      totalToRedeem = FixedPoint.Unsigned(
        collateralToken.balanceOf(address(this))
      );
    } else {
      FixedPoint.Unsigned memory dueCollateral =
        numTokens.mul(derivative.emergencyShutdownPrice());

      totalToRedeem = FixedPoint.min(
        dueCollateral,
        FixedPoint.Unsigned(collateralToken.balanceOf(address(this)))
      );
    }
    amountSettled = totalToRedeem.rawValue;

    collateralToken.safeTransfer(msg.sender, amountSettled);

    emit Settlement(
      msg.sender,
      address(this),
      numTokens.rawValue,
      amountSettled
    );
  }

  function setFeePercentage(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory _feePercentage
  ) external {
    require(
      _feePercentage.rawValue < 10**(18),
      'Fee Percentage must be less than 100%'
    );
    self.fee.feePercentage = _feePercentage;
    emit SetFeePercentage(_feePercentage.rawValue);
  }

  function setFeeRecipients(
    ISynthereumPoolStorage.Storage storage self,
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external {
    require(
      _feeRecipients.length == _feeProportions.length,
      'Fee recipients and fee proportions do not match'
    );
    uint256 totalActualFeeProportions;

    for (uint256 i = 0; i < _feeProportions.length; i++) {
      totalActualFeeProportions += _feeProportions[i];
    }
    self.fee.feeRecipients = _feeRecipients;
    self.fee.feeProportions = _feeProportions;
    self.totalFeeProportions = totalActualFeeProportions;
    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }

  function setStartingCollateralization(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory startingCollateralRatio
  ) external {
    self.startingCollateralization = startingCollateralRatio;
  }

  function addRoleInDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.DerivativeRoles derivativeRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN) {
      derivative.addAdmin(addressToAdd);
    } else {
      ISynthereumPool pool = ISynthereumPool(addressToAdd);
      IERC20 collateralToken = self.collateralToken;
      require(
        collateralToken == pool.collateralToken(),
        'Collateral tokens do not match'
      );
      require(
        self.syntheticToken == pool.syntheticToken(),
        'Synthetic tokens do not match'
      );
      ISynthereumFinder finder = self.finder;
      require(finder == pool.synthereumFinder(), 'Finders do not match');
      ISynthereumPoolRegistry poolRegister =
        ISynthereumPoolRegistry(
          finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
        );
      poolRegister.isPoolDeployed(
        pool.syntheticTokenSymbol(),
        collateralToken,
        pool.version(),
        address(pool)
      );
      if (derivativeRole == ISynthereumPool.DerivativeRoles.POOL) {
        derivative.addPool(addressToAdd);
      } else if (
        derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN_AND_POOL
      ) {
        derivative.addAdminAndPool(addressToAdd);
      }
    }
  }

  function renounceRoleInDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.DerivativeRoles derivativeRole
  ) external checkDerivative(self, derivative) {
    if (derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN) {
      derivative.renounceAdmin();
    } else if (derivativeRole == ISynthereumPool.DerivativeRoles.POOL) {
      derivative.renouncePool();
    } else if (
      derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN_AND_POOL
    ) {
      derivative.renounceAdminAndPool();
    }
  }

  function addRoleInSynthToken(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (synthTokenRole == ISynthereumPool.SynthTokenRoles.ADMIN) {
      derivative.addSyntheticTokenAdmin(addressToAdd);
    } else {
      require(
        self.syntheticToken == IDerivative(addressToAdd).tokenCurrency(),
        'Synthetic tokens do not match'
      );
      if (synthTokenRole == ISynthereumPool.SynthTokenRoles.MINTER) {
        derivative.addSyntheticTokenMinter(addressToAdd);
      } else if (synthTokenRole == ISynthereumPool.SynthTokenRoles.BURNER) {
        derivative.addSyntheticTokenBurner(addressToAdd);
      } else if (
        synthTokenRole ==
        ISynthereumPool.SynthTokenRoles.ADMIN_AND_MINTER_AND_BURNER
      ) {
        derivative.addSyntheticTokenAdminAndMinterAndBurner(addressToAdd);
      }
    }
  }

  function renounceRoleInSynthToken(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.SynthTokenRoles synthTokenRole
  ) external checkDerivative(self, derivative) {
    if (synthTokenRole == ISynthereumPool.SynthTokenRoles.ADMIN) {
      derivative.renounceSyntheticTokenAdmin();
    } else if (synthTokenRole == ISynthereumPool.SynthTokenRoles.MINTER) {
      derivative.renounceSyntheticTokenMinter();
    } else if (synthTokenRole == ISynthereumPool.SynthTokenRoles.BURNER) {
      derivative.renounceSyntheticTokenBurner();
    } else if (
      synthTokenRole ==
      ISynthereumPool.SynthTokenRoles.ADMIN_AND_MINTER_AND_BURNER
    ) {
      derivative.renounceSyntheticTokenAdminAndMinterAndBurner();
    }
  }

  function setIsContractAllowed(
    ISynthereumPoolStorage.Storage storage self,
    bool isContractAllowed
  ) external {
    require(
      self.isContractAllowed != isContractAllowed,
      'Contract flag already set'
    );
    self.isContractAllowed = isContractAllowed;
  }

  function checkMetaTxParams(
    ISynthereumPoolStorage.Storage storage self,
    address sender,
    address derivativeAddr,
    uint256 feePercentage,
    uint256 nonce,
    uint256 expiration
  ) internal checkDerivative(self, IDerivative(derivativeAddr)) {
    require(sender == msg.sender, 'Wrong user account');
    require(now <= expiration, 'Meta-signature expired');
    require(
      feePercentage == self.fee.feePercentage.rawValue,
      'Wrong fee percentage'
    );
    require(nonce == self.nonces[sender]++, 'Invalid nonce');
  }

  function pullCollateral(
    ISynthereumPoolStorage.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeTransferFrom(
      from,
      address(this),
      numTokens.rawValue
    );
  }

  function mintSynTokens(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.create(collateralAmount, numTokens);
  }

  function transferSynTokens(
    ISynthereumPoolStorage.Storage storage self,
    address recipient,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.syntheticToken.safeTransfer(recipient, numTokens.rawValue);
  }

  function redeemForCollateral(
    address tokenHolder,
    IDerivative derivative,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(numTokens.isGreaterThan(0), 'Number of tokens to redeem is 0');

    IERC20 tokenCurrency = derivative.positionManagerData().tokenCurrency;
    require(
      tokenCurrency.balanceOf(tokenHolder) >= numTokens.rawValue,
      'Token balance less than token to redeem'
    );

    tokenCurrency.safeTransferFrom(
      tokenHolder,
      address(this),
      numTokens.rawValue
    );

    tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);

    amountWithdrawn = derivative.redeem(numTokens);
  }

  function liquidateWithdrawal(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    address recipient
  ) internal returns (uint256 amountWithdrawn) {
    amountWithdrawn = collateralAmount.rawValue;
    self.collateralToken.safeTransfer(recipient, amountWithdrawn);
  }

  function sendFee(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory _feeAmount
  ) internal {
    for (uint256 i = 0; i < self.fee.feeRecipients.length; i++) {
      self.collateralToken.safeTransfer(
        self.fee.feeRecipients[i],
        _feeAmount
          .mul(self.fee.feeProportions[i])
          .div(self.totalFeeProportions)
          .rawValue
      );
    }
  }

  function getDerivativeCollateral(IDerivative derivative)
    internal
    view
    returns (IERC20 collateral)
  {
    collateral = derivative.collateralCurrency();
  }

  function getGlobalCollateralizationRatio(IDerivative derivative)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    FixedPoint.Unsigned memory totalTokensOutstanding =
      derivative.globalPositionData().totalTokensOutstanding;
    if (totalTokensOutstanding.isGreaterThan(0)) {
      return derivative.totalPositionCollateral().div(totalTokensOutstanding);
    } else {
      return FixedPoint.fromUnscaledUint(0);
    }
  }

  function checkCollateralizationRatio(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory globalCollateralization,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (bool) {
    FixedPoint.Unsigned memory newCollateralization =
      collateralAmount
        .add(FixedPoint.Unsigned(self.collateralToken.balanceOf(address(this))))
        .div(numTokens);

    return newCollateralization.isGreaterThanOrEqual(globalCollateralization);
  }

  function checkPool(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool poolToCheck,
    IDerivative derivativeToCheck
  ) internal view {
    require(
      poolToCheck.isDerivativeAdmitted(derivativeToCheck),
      'Wrong derivative'
    );

    IERC20 collateralToken = self.collateralToken;
    require(
      collateralToken == poolToCheck.collateralToken(),
      'Collateral tokens do not match'
    );
    ISynthereumFinder finder = self.finder;
    require(finder == poolToCheck.synthereumFinder(), 'Finders do not match');
    ISynthereumPoolRegistry poolRegister =
      ISynthereumPoolRegistry(
        finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
      );
    require(
      poolRegister.isPoolDeployed(
        poolToCheck.syntheticTokenSymbol(),
        collateralToken,
        poolToCheck.version(),
        address(poolToCheck)
      ),
      'Destination pool not registred'
    );
  }

  function generateMintDigest(
    ISynthereumPool.MintParameters memory mintMetaTx,
    bytes32 domain_separator,
    bytes32 typeHash
  ) internal pure returns (bytes32 digest) {
    digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        domain_separator,
        keccak256(
          abi.encode(
            typeHash,
            mintMetaTx.sender,
            mintMetaTx.derivativeAddr,
            mintMetaTx.collateralAmount,
            mintMetaTx.numTokens,
            mintMetaTx.feePercentage,
            mintMetaTx.nonce,
            mintMetaTx.expiration
          )
        )
      )
    );
  }

  function generateRedeemDigest(
    ISynthereumPool.RedeemParameters memory redeemMetaTx,
    bytes32 domain_separator,
    bytes32 typeHash
  ) internal pure returns (bytes32 digest) {
    digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        domain_separator,
        keccak256(
          abi.encode(
            typeHash,
            redeemMetaTx.sender,
            redeemMetaTx.derivativeAddr,
            redeemMetaTx.collateralAmount,
            redeemMetaTx.numTokens,
            redeemMetaTx.feePercentage,
            redeemMetaTx.nonce,
            redeemMetaTx.expiration
          )
        )
      )
    );
  }

  function generateExchangeDigest(
    ISynthereumPool.ExchangeParameters memory exchangeMetaTx,
    bytes32 domain_separator,
    bytes32 typeHash
  ) internal pure returns (bytes32 digest) {
    digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        domain_separator,
        keccak256(
          abi.encode(
            typeHash,
            exchangeMetaTx.sender,
            exchangeMetaTx.derivativeAddr,
            exchangeMetaTx.destPoolAddr,
            exchangeMetaTx.destDerivativeAddr,
            exchangeMetaTx.numTokens,
            exchangeMetaTx.collateralAmount,
            exchangeMetaTx.destNumTokens,
            exchangeMetaTx.feePercentage,
            exchangeMetaTx.nonce,
            exchangeMetaTx.expiration
          )
        )
      )
    );
  }

  function checkSignature(
    bytes32 validator_role,
    bytes32 digest,
    ISynthereumPool.Signature memory signature
  ) internal view {
    address signatureAddr =
      ecrecover(digest, signature.v, signature.r, signature.s);
    require(
      IRole(address(this)).hasRole(validator_role, signatureAddr),
      'Invalid meta-signature'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface IRole {
  function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {ISynthereumPool} from './interfaces/IPool.sol';
import {SynthereumPool} from './Pool.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  IDeploymentSignature
} from '../../versioning/interfaces/IDeploymentSignature.sol';
import {SynthereumPoolCreator} from './PoolCreator.sol';

contract SynthereumPoolFactory is SynthereumPoolCreator, IDeploymentSignature {
  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  constructor(address _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPool.selector;
  }

  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPool.Roles memory roles,
    bool isContractAllowed,
    uint256 startingCollateralization,
    ISynthereumPool.Fee memory fee
  ) public override returns (SynthereumPool poolDeployed) {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    poolDeployed = super.createPool(
      derivative,
      finder,
      version,
      roles,
      isContractAllowed,
      startingCollateralization,
      fee
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {ISynthereumPool} from './interfaces/IPool.sol';
import {SynthereumPool} from './Pool.sol';
import '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolCreator is Lockable {
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPool.Roles memory roles,
    bool isContractAllowed,
    uint256 startingCollateralization,
    ISynthereumPool.Fee memory fee
  ) public virtual nonReentrant returns (SynthereumPool poolDeployed) {
    poolDeployed = new SynthereumPool(
      derivative,
      finder,
      version,
      roles,
      isContractAllowed,
      startingCollateralization,
      fee
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumPool} from '../synthereum-pool/v1/interfaces/IPool.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ContractAllowed {
  ISynthereumPool public pool;
  IERC20 public collateral;

  constructor(address _pool, address _collateral) public {
    pool = ISynthereumPool(_pool);
    collateral = IERC20(_collateral);
  }

  function mintInPool(
    ISynthereumPool.MintParameters memory mintParams,
    ISynthereumPool.Signature memory signature,
    uint256 approveAmount
  ) external {
    collateral.approve(address(pool), approveAmount);
    pool.mint(mintParams, signature);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../../common/implementation/FixedPoint.sol';
import '../../common/implementation/MultiRole.sol';
import '../../common/implementation/Withdrawable.sol';
import '../../common/implementation/Testable.sol';
import '../interfaces/StoreInterface.sol';

contract Store is StoreInterface, Withdrawable, Testable {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for uint256;
  using SafeERC20 for IERC20;

  enum Roles {Owner, Withdrawer}

  FixedPoint.Unsigned public fixedOracleFeePerSecondPerPfc;
  FixedPoint.Unsigned public weeklyDelayFeePerSecondPerPfc;

  mapping(address => FixedPoint.Unsigned) public finalFees;
  uint256 public constant SECONDS_PER_WEEK = 604800;

  event NewFixedOracleFeePerSecondPerPfc(FixedPoint.Unsigned newOracleFee);
  event NewWeeklyDelayFeePerSecondPerPfc(
    FixedPoint.Unsigned newWeeklyDelayFeePerSecondPerPfc
  );
  event NewFinalFee(FixedPoint.Unsigned newFinalFee);

  constructor(
    FixedPoint.Unsigned memory _fixedOracleFeePerSecondPerPfc,
    FixedPoint.Unsigned memory _weeklyDelayFeePerSecondPerPfc,
    address _timerAddress
  ) public Testable(_timerAddress) {
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );
    _createWithdrawRole(
      uint256(Roles.Withdrawer),
      uint256(Roles.Owner),
      msg.sender
    );
    setFixedOracleFeePerSecondPerPfc(_fixedOracleFeePerSecondPerPfc);
    setWeeklyDelayFeePerSecondPerPfc(_weeklyDelayFeePerSecondPerPfc);
  }

  function payOracleFees() external payable override {
    require(msg.value > 0, "Value sent can't be zero");
  }

  function payOracleFeesErc20(
    address erc20Address,
    FixedPoint.Unsigned calldata amount
  ) external override {
    IERC20 erc20 = IERC20(erc20Address);
    require(amount.isGreaterThan(0), "Amount sent can't be zero");
    erc20.safeTransferFrom(msg.sender, address(this), amount.rawValue);
  }

  function computeRegularFee(
    uint256 startTime,
    uint256 endTime,
    FixedPoint.Unsigned calldata pfc
  )
    external
    view
    override
    returns (
      FixedPoint.Unsigned memory regularFee,
      FixedPoint.Unsigned memory latePenalty
    )
  {
    uint256 timeDiff = endTime.sub(startTime);

    regularFee = pfc.mul(timeDiff).mul(fixedOracleFeePerSecondPerPfc);

    uint256 paymentDelay = getCurrentTime().sub(startTime);

    FixedPoint.Unsigned memory penaltyPercentagePerSecond =
      weeklyDelayFeePerSecondPerPfc.mul(paymentDelay.div(SECONDS_PER_WEEK));

    latePenalty = pfc.mul(timeDiff).mul(penaltyPercentagePerSecond);
  }

  function computeFinalFee(address currency)
    external
    view
    override
    returns (FixedPoint.Unsigned memory)
  {
    return finalFees[currency];
  }

  function setFixedOracleFeePerSecondPerPfc(
    FixedPoint.Unsigned memory newFixedOracleFeePerSecondPerPfc
  ) public onlyRoleHolder(uint256(Roles.Owner)) {
    require(
      newFixedOracleFeePerSecondPerPfc.isLessThan(1),
      'Fee must be < 100% per second.'
    );
    fixedOracleFeePerSecondPerPfc = newFixedOracleFeePerSecondPerPfc;
    emit NewFixedOracleFeePerSecondPerPfc(newFixedOracleFeePerSecondPerPfc);
  }

  function setWeeklyDelayFeePerSecondPerPfc(
    FixedPoint.Unsigned memory newWeeklyDelayFeePerSecondPerPfc
  ) public onlyRoleHolder(uint256(Roles.Owner)) {
    require(
      newWeeklyDelayFeePerSecondPerPfc.isLessThan(1),
      'weekly delay fee must be < 100%'
    );
    weeklyDelayFeePerSecondPerPfc = newWeeklyDelayFeePerSecondPerPfc;
    emit NewWeeklyDelayFeePerSecondPerPfc(newWeeklyDelayFeePerSecondPerPfc);
  }

  function setFinalFee(address currency, FixedPoint.Unsigned memory newFinalFee)
    public
    onlyRoleHolder(uint256(Roles.Owner))
  {
    finalFees[currency] = newFinalFee;
    emit NewFinalFee(newFinalFee);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library Exclusive {
  struct RoleMembership {
    address member;
  }

  function isMember(
    RoleMembership storage roleMembership,
    address memberToCheck
  ) internal view returns (bool) {
    return roleMembership.member == memberToCheck;
  }

  function resetMember(RoleMembership storage roleMembership, address newMember)
    internal
  {
    require(newMember != address(0x0), 'Cannot set an exclusive role to 0x0');
    roleMembership.member = newMember;
  }

  function getMember(RoleMembership storage roleMembership)
    internal
    view
    returns (address)
  {
    return roleMembership.member;
  }

  function init(RoleMembership storage roleMembership, address initialMember)
    internal
  {
    resetMember(roleMembership, initialMember);
  }
}

library Shared {
  struct RoleMembership {
    mapping(address => bool) members;
  }

  function isMember(
    RoleMembership storage roleMembership,
    address memberToCheck
  ) internal view returns (bool) {
    return roleMembership.members[memberToCheck];
  }

  function addMember(RoleMembership storage roleMembership, address memberToAdd)
    internal
  {
    require(memberToAdd != address(0x0), 'Cannot add 0x0 to a shared role');
    roleMembership.members[memberToAdd] = true;
  }

  function removeMember(
    RoleMembership storage roleMembership,
    address memberToRemove
  ) internal {
    roleMembership.members[memberToRemove] = false;
  }

  function init(
    RoleMembership storage roleMembership,
    address[] memory initialMembers
  ) internal {
    for (uint256 i = 0; i < initialMembers.length; i++) {
      addMember(roleMembership, initialMembers[i]);
    }
  }
}

abstract contract MultiRole {
  using Exclusive for Exclusive.RoleMembership;
  using Shared for Shared.RoleMembership;

  enum RoleType {Invalid, Exclusive, Shared}

  struct Role {
    uint256 managingRole;
    RoleType roleType;
    Exclusive.RoleMembership exclusiveRoleMembership;
    Shared.RoleMembership sharedRoleMembership;
  }

  mapping(uint256 => Role) private roles;

  event ResetExclusiveMember(
    uint256 indexed roleId,
    address indexed newMember,
    address indexed manager
  );
  event AddedSharedMember(
    uint256 indexed roleId,
    address indexed newMember,
    address indexed manager
  );
  event RemovedSharedMember(
    uint256 indexed roleId,
    address indexed oldMember,
    address indexed manager
  );

  modifier onlyRoleHolder(uint256 roleId) {
    require(
      holdsRole(roleId, msg.sender),
      'Sender does not hold required role'
    );
    _;
  }

  modifier onlyRoleManager(uint256 roleId) {
    require(
      holdsRole(roles[roleId].managingRole, msg.sender),
      'Can only be called by a role manager'
    );
    _;
  }

  modifier onlyExclusive(uint256 roleId) {
    require(
      roles[roleId].roleType == RoleType.Exclusive,
      'Must be called on an initialized Exclusive role'
    );
    _;
  }

  modifier onlyShared(uint256 roleId) {
    require(
      roles[roleId].roleType == RoleType.Shared,
      'Must be called on an initialized Shared role'
    );
    _;
  }

  function holdsRole(uint256 roleId, address memberToCheck)
    public
    view
    returns (bool)
  {
    Role storage role = roles[roleId];
    if (role.roleType == RoleType.Exclusive) {
      return role.exclusiveRoleMembership.isMember(memberToCheck);
    } else if (role.roleType == RoleType.Shared) {
      return role.sharedRoleMembership.isMember(memberToCheck);
    }
    revert('Invalid roleId');
  }

  function resetMember(uint256 roleId, address newMember)
    public
    onlyExclusive(roleId)
    onlyRoleManager(roleId)
  {
    roles[roleId].exclusiveRoleMembership.resetMember(newMember);
    emit ResetExclusiveMember(roleId, newMember, msg.sender);
  }

  function getMember(uint256 roleId)
    public
    view
    onlyExclusive(roleId)
    returns (address)
  {
    return roles[roleId].exclusiveRoleMembership.getMember();
  }

  function addMember(uint256 roleId, address newMember)
    public
    onlyShared(roleId)
    onlyRoleManager(roleId)
  {
    roles[roleId].sharedRoleMembership.addMember(newMember);
    emit AddedSharedMember(roleId, newMember, msg.sender);
  }

  function removeMember(uint256 roleId, address memberToRemove)
    public
    onlyShared(roleId)
    onlyRoleManager(roleId)
  {
    roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
    emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
  }

  function renounceMembership(uint256 roleId)
    public
    onlyShared(roleId)
    onlyRoleHolder(roleId)
  {
    roles[roleId].sharedRoleMembership.removeMember(msg.sender);
    emit RemovedSharedMember(roleId, msg.sender, msg.sender);
  }

  modifier onlyValidRole(uint256 roleId) {
    require(
      roles[roleId].roleType != RoleType.Invalid,
      'Attempted to use an invalid roleId'
    );
    _;
  }

  modifier onlyInvalidRole(uint256 roleId) {
    require(
      roles[roleId].roleType == RoleType.Invalid,
      'Cannot use a pre-existing role'
    );
    _;
  }

  function _createSharedRole(
    uint256 roleId,
    uint256 managingRoleId,
    address[] memory initialMembers
  ) internal onlyInvalidRole(roleId) {
    Role storage role = roles[roleId];
    role.roleType = RoleType.Shared;
    role.managingRole = managingRoleId;
    role.sharedRoleMembership.init(initialMembers);
    require(
      roles[managingRoleId].roleType != RoleType.Invalid,
      'Attempted to use an invalid role to manage a shared role'
    );
  }

  function _createExclusiveRole(
    uint256 roleId,
    uint256 managingRoleId,
    address initialMember
  ) internal onlyInvalidRole(roleId) {
    Role storage role = roles[roleId];
    role.roleType = RoleType.Exclusive;
    role.managingRole = managingRoleId;
    role.exclusiveRoleMembership.init(initialMember);
    require(
      roles[managingRoleId].roleType != RoleType.Invalid,
      'Attempted to use an invalid role to manage an exclusive role'
    );
  }
}

pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/utils/Address.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './MultiRole.sol';

abstract contract Withdrawable is MultiRole {
  using SafeERC20 for IERC20;

  uint256 private roleId;

  function withdraw(uint256 amount) external onlyRoleHolder(roleId) {
    Address.sendValue(msg.sender, amount);
  }

  function withdrawErc20(address erc20Address, uint256 amount)
    external
    onlyRoleHolder(roleId)
  {
    IERC20 erc20 = IERC20(erc20Address);
    erc20.safeTransfer(msg.sender, amount);
  }

  function _createWithdrawRole(
    uint256 newRoleId,
    uint256 managingRoleId,
    address withdrawerAddress
  ) internal {
    roleId = newRoleId;
    _createExclusiveRole(newRoleId, managingRoleId, withdrawerAddress);
  }

  function _setWithdrawRole(uint256 setRoleId)
    internal
    onlyValidRole(setRoleId)
  {
    roleId = setRoleId;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import './Timer.sol';

abstract contract Testable {
  address public timerAddress;

  constructor(address _timerAddress) internal {
    timerAddress = _timerAddress;
  }

  modifier onlyIfTest {
    require(timerAddress != address(0x0));
    _;
  }

  function setCurrentTime(uint256 time) external onlyIfTest {
    Timer(timerAddress).setCurrentTime(time);
  }

  function getCurrentTime() public view returns (uint256) {
    if (timerAddress != address(0x0)) {
      return Timer(timerAddress).getCurrentTime();
    } else {
      return now;
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../common/implementation/FixedPoint.sol';

interface StoreInterface {
  function payOracleFees() external payable;

  function payOracleFeesErc20(
    address erc20Address,
    FixedPoint.Unsigned calldata amount
  ) external;

  function computeRegularFee(
    uint256 startTime,
    uint256 endTime,
    FixedPoint.Unsigned calldata pfc
  )
    external
    view
    returns (
      FixedPoint.Unsigned memory regularFee,
      FixedPoint.Unsigned memory latePenalty
    );

  function computeFinalFee(address currency)
    external
    view
    returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

contract Timer {
  uint256 private currentTime;

  constructor() public {
    currentTime = now;
  }

  function setCurrentTime(uint256 time) external {
    currentTime = time;
  }

  function getCurrentTime() public view returns (uint256) {
    return currentTime;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  Finder
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/Finder.sol';
import {
  Timer
} from '../../@jarvis-network/uma-core/contracts/common/implementation/Timer.sol';
import {
  VotingToken
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/VotingToken.sol';
import {
  TokenMigrator
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/TokenMigrator.sol';
import {
  Voting
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/Voting.sol';
import {
  IdentifierWhitelist
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/IdentifierWhitelist.sol';
import {
  Registry
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/Registry.sol';
import {
  FinancialContractsAdmin
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/FinancialContractsAdmin.sol';
import {
  Store
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/Store.sol';
import {
  Governor
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/Governor.sol';
import {
  DesignatedVotingFactory
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/DesignatedVotingFactory.sol';
import {
  TestnetERC20
} from '../../@jarvis-network/uma-core/contracts/common/implementation/TestnetERC20.sol';
import {
  OptimisticOracle
} from '../../@jarvis-network/uma-core/contracts/oracle/implementation/OptimisticOracle.sol';
import {
  MockOracle
} from '../../@jarvis-network/uma-core/contracts/oracle/test/MockOracle.sol';

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/FinderInterface.sol';

contract Finder is FinderInterface, Ownable {
  mapping(bytes32 => address) public interfacesImplemented;

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyOwner {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../common/implementation/ExpandedERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol';

contract VotingToken is ExpandedERC20, ERC20Snapshot {
  constructor() public ExpandedERC20('UMA Voting Token v1', 'UMA', 18) {}

  function snapshot() external returns (uint256) {
    return _snapshot();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Snapshot) {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';
import '../../common/interfaces/ExpandedIERC20.sol';
import './VotingToken.sol';

contract TokenMigrator {
  using FixedPoint for FixedPoint.Unsigned;

  VotingToken public oldToken;
  ExpandedIERC20 public newToken;

  uint256 public snapshotId;
  FixedPoint.Unsigned public rate;

  mapping(address => bool) public hasMigrated;

  constructor(
    FixedPoint.Unsigned memory _rate,
    address _oldToken,
    address _newToken
  ) public {
    require(_rate.isGreaterThan(0), "Rate can't be 0");
    rate = _rate;
    newToken = ExpandedIERC20(_newToken);
    oldToken = VotingToken(_oldToken);
    snapshotId = oldToken.snapshot();
  }

  function migrateTokens(address tokenHolder) external {
    require(!hasMigrated[tokenHolder], 'Already migrated tokens');
    hasMigrated[tokenHolder] = true;

    FixedPoint.Unsigned memory oldBalance =
      FixedPoint.Unsigned(oldToken.balanceOfAt(tokenHolder, snapshotId));

    if (!oldBalance.isGreaterThan(0)) {
      return;
    }

    FixedPoint.Unsigned memory newBalance = oldBalance.div(rate);
    require(newToken.mint(tokenHolder, newBalance.rawValue), 'Mint failed');
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';
import '../../common/implementation/Testable.sol';
import '../interfaces/FinderInterface.sol';
import '../interfaces/OracleInterface.sol';
import '../interfaces/OracleAncillaryInterface.sol';
import '../interfaces/VotingInterface.sol';
import '../interfaces/VotingAncillaryInterface.sol';
import '../interfaces/IdentifierWhitelistInterface.sol';
import './Registry.sol';
import './ResultComputation.sol';
import './VoteTiming.sol';
import './VotingToken.sol';
import './Constants.sol';

import '../../../../../@openzeppelin/contracts/access/Ownable.sol';
import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/cryptography/ECDSA.sol';

contract Voting is
  Testable,
  Ownable,
  OracleInterface,
  OracleAncillaryInterface,
  VotingInterface,
  VotingAncillaryInterface
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeMath for uint256;
  using VoteTiming for VoteTiming.Data;
  using ResultComputation for ResultComputation.Data;

  struct PriceRequest {
    bytes32 identifier;
    uint256 time;
    mapping(uint256 => VoteInstance) voteInstances;
    uint256 lastVotingRound;
    uint256 index;
    bytes ancillaryData;
  }

  struct VoteInstance {
    mapping(address => VoteSubmission) voteSubmissions;
    ResultComputation.Data resultComputation;
  }

  struct VoteSubmission {
    bytes32 commit;
    bytes32 revealHash;
  }

  struct Round {
    uint256 snapshotId;
    FixedPoint.Unsigned inflationRate;
    FixedPoint.Unsigned gatPercentage;
    uint256 rewardsExpirationTime;
  }

  enum RequestStatus {NotRequested, Active, Resolved, Future}

  struct RequestState {
    RequestStatus status;
    uint256 lastVotingRound;
  }

  mapping(uint256 => Round) public rounds;

  mapping(bytes32 => PriceRequest) private priceRequests;

  bytes32[] internal pendingPriceRequests;

  VoteTiming.Data public voteTiming;

  FixedPoint.Unsigned public gatPercentage;

  FixedPoint.Unsigned public inflationRate;

  uint256 public rewardsExpirationTimeout;

  VotingToken public votingToken;

  FinderInterface private finder;

  address public migratedAddress;

  uint256 private constant UINT_MAX = ~uint256(0);

  uint256 public constant ancillaryBytesLimit = 8192;

  bytes32 public snapshotMessageHash =
    ECDSA.toEthSignedMessageHash(keccak256(bytes('Sign For Snapshot')));

  event VoteCommitted(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    bytes ancillaryData
  );

  event EncryptedVote(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    bytes ancillaryData,
    bytes encryptedVote
  );

  event VoteRevealed(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    int256 price,
    bytes ancillaryData,
    uint256 numTokens
  );

  event RewardsRetrieved(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    bytes ancillaryData,
    uint256 numTokens
  );

  event PriceRequestAdded(
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time
  );

  event PriceResolved(
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    int256 price,
    bytes ancillaryData
  );

  constructor(
    uint256 _phaseLength,
    FixedPoint.Unsigned memory _gatPercentage,
    FixedPoint.Unsigned memory _inflationRate,
    uint256 _rewardsExpirationTimeout,
    address _votingToken,
    address _finder,
    address _timerAddress
  ) public Testable(_timerAddress) {
    voteTiming.init(_phaseLength);
    require(
      _gatPercentage.isLessThanOrEqual(1),
      'GAT percentage must be <= 100%'
    );
    gatPercentage = _gatPercentage;
    inflationRate = _inflationRate;
    votingToken = VotingToken(_votingToken);
    finder = FinderInterface(_finder);
    rewardsExpirationTimeout = _rewardsExpirationTimeout;
  }

  modifier onlyRegisteredContract() {
    if (migratedAddress != address(0)) {
      require(msg.sender == migratedAddress, 'Caller must be migrated address');
    } else {
      Registry registry =
        Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
      require(
        registry.isContractRegistered(msg.sender),
        'Called must be registered'
      );
    }
    _;
  }

  modifier onlyIfNotMigrated() {
    require(migratedAddress == address(0), 'Only call this if not migrated');
    _;
  }

  function requestPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public override onlyRegisteredContract() {
    uint256 blockTime = getCurrentTime();
    require(time <= blockTime, 'Can only request in past');
    require(
      _getIdentifierWhitelist().isIdentifierSupported(identifier),
      'Unsupported identifier request'
    );
    require(
      ancillaryData.length <= ancillaryBytesLimit,
      'Invalid ancillary data'
    );

    bytes32 priceRequestId =
      _encodePriceRequest(identifier, time, ancillaryData);
    PriceRequest storage priceRequest = priceRequests[priceRequestId];
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

    RequestStatus requestStatus =
      _getRequestStatus(priceRequest, currentRoundId);

    if (requestStatus == RequestStatus.NotRequested) {
      uint256 nextRoundId = currentRoundId.add(1);

      priceRequests[priceRequestId] = PriceRequest({
        identifier: identifier,
        time: time,
        lastVotingRound: nextRoundId,
        index: pendingPriceRequests.length,
        ancillaryData: ancillaryData
      });
      pendingPriceRequests.push(priceRequestId);
      emit PriceRequestAdded(nextRoundId, identifier, time);
    }
  }

  function requestPrice(bytes32 identifier, uint256 time) public override {
    requestPrice(identifier, time, '');
  }

  /**
   * @notice Whether the price for `identifier` and `time` is available.
   * @dev Time must be in the past and the identifier must be supported.
   * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
   * @param time unix timestamp of for the price request.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @return _hasPrice bool if the DVM has resolved to a price for the given identifier and timestamp.
   */
  function hasPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view override onlyRegisteredContract() returns (bool) {
    (bool _hasPrice, , ) = _getPriceOrError(identifier, time, ancillaryData);
    return _hasPrice;
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function hasPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (bool)
  {
    return hasPrice(identifier, time, '');
  }

  /**
   * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
   * @dev If the price is not available, the method reverts.
   * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
   * @param time unix timestamp of for the price request.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @return int256 representing the resolved price for the given identifier and timestamp.
   */
  function getPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view override onlyRegisteredContract() returns (int256) {
    (bool _hasPrice, int256 price, string memory message) =
      _getPriceOrError(identifier, time, ancillaryData);

    // If the price wasn't available, revert with the provided message.
    require(_hasPrice, message);
    return price;
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function getPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (int256)
  {
    return getPrice(identifier, time, '');
  }

  /**
   * @notice Gets the status of a list of price requests, identified by their identifier and time.
   * @dev If the status for a particular request is NotRequested, the lastVotingRound will always be 0.
   * @param requests array of type PendingRequest which includes an identifier and timestamp for each request.
   * @return requestStates a list, in the same order as the input list, giving the status of each of the specified price requests.
   */
  function getPriceRequestStatuses(PendingRequestAncillary[] memory requests)
    public
    view
    returns (RequestState[] memory)
  {
    RequestState[] memory requestStates = new RequestState[](requests.length);
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());
    for (uint256 i = 0; i < requests.length; i++) {
      PriceRequest storage priceRequest =
        _getPriceRequest(
          requests[i].identifier,
          requests[i].time,
          requests[i].ancillaryData
        );

      RequestStatus status = _getRequestStatus(priceRequest, currentRoundId);

      // If it's an active request, its true lastVotingRound is the current one, even if it hasn't been updated.
      if (status == RequestStatus.Active) {
        requestStates[i].lastVotingRound = currentRoundId;
      } else {
        requestStates[i].lastVotingRound = priceRequest.lastVotingRound;
      }
      requestStates[i].status = status;
    }
    return requestStates;
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function getPriceRequestStatuses(PendingRequest[] memory requests)
    public
    view
    returns (RequestState[] memory)
  {
    PendingRequestAncillary[] memory requestsAncillary =
      new PendingRequestAncillary[](requests.length);

    for (uint256 i = 0; i < requests.length; i++) {
      requestsAncillary[i].identifier = requests[i].identifier;
      requestsAncillary[i].time = requests[i].time;
      requestsAncillary[i].ancillaryData = '';
    }
    return getPriceRequestStatuses(requestsAncillary);
  }

  /****************************************
   *            VOTING FUNCTIONS          *
   ****************************************/

  /**
   * @notice Commit a vote for a price request for `identifier` at `time`.
   * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
   * Commits can be changed.
   * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
   * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
   * they can determine the vote pre-reveal.
   * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
   * @param time unix timestamp of the price being voted on.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
   */
  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash
  ) public override onlyIfNotMigrated() {
    require(hash != bytes32(0), 'Invalid provided hash');

    uint256 blockTime = getCurrentTime();
    require(
      voteTiming.computeCurrentPhase(blockTime) ==
        VotingAncillaryInterface.Phase.Commit,
      'Cannot commit in reveal phase'
    );

    uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

    PriceRequest storage priceRequest =
      _getPriceRequest(identifier, time, ancillaryData);
    require(
      _getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active,
      'Cannot commit inactive request'
    );

    priceRequest.lastVotingRound = currentRoundId;
    VoteInstance storage voteInstance =
      priceRequest.voteInstances[currentRoundId];
    voteInstance.voteSubmissions[msg.sender].commit = hash;

    emit VoteCommitted(
      msg.sender,
      currentRoundId,
      identifier,
      time,
      ancillaryData
    );
  }

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash
  ) public override onlyIfNotMigrated() {
    commitVote(identifier, time, '', hash);
  }

  /**
   * @notice Snapshot the current round's token balances and lock in the inflation rate and GAT.
   * @dev This function can be called multiple times, but only the first call per round into this function or `revealVote`
   * will create the round snapshot. Any later calls will be a no-op. Will revert unless called during reveal period.
   * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
   * snapshot.
   */
  function snapshotCurrentRound(bytes calldata signature)
    external
    override(VotingInterface, VotingAncillaryInterface)
    onlyIfNotMigrated()
  {
    uint256 blockTime = getCurrentTime();
    require(
      voteTiming.computeCurrentPhase(blockTime) == Phase.Reveal,
      'Only snapshot in reveal phase'
    );

    require(
      ECDSA.recover(snapshotMessageHash, signature) == msg.sender,
      'Signature must match sender'
    );
    uint256 roundId = voteTiming.computeCurrentRoundId(blockTime);
    _freezeRoundVariables(roundId);
  }

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    bytes memory ancillaryData,
    int256 salt
  ) public override onlyIfNotMigrated() {
    require(
      voteTiming.computeCurrentPhase(getCurrentTime()) == Phase.Reveal,
      'Cannot reveal in commit phase'
    );

    uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());

    PriceRequest storage priceRequest =
      _getPriceRequest(identifier, time, ancillaryData);
    VoteInstance storage voteInstance = priceRequest.voteInstances[roundId];
    VoteSubmission storage voteSubmission =
      voteInstance.voteSubmissions[msg.sender];

    {
      require(voteSubmission.commit != bytes32(0), 'Invalid hash reveal');
      require(
        keccak256(
          abi.encodePacked(
            price,
            salt,
            msg.sender,
            time,
            ancillaryData,
            roundId,
            identifier
          )
        ) == voteSubmission.commit,
        'Revealed data != commit hash'
      );

      require(rounds[roundId].snapshotId != 0, 'Round has no snapshot');
    }

    uint256 snapshotId = rounds[roundId].snapshotId;

    delete voteSubmission.commit;

    FixedPoint.Unsigned memory balance =
      FixedPoint.Unsigned(votingToken.balanceOfAt(msg.sender, snapshotId));

    voteSubmission.revealHash = keccak256(abi.encode(price));

    voteInstance.resultComputation.addVote(price, balance);

    emit VoteRevealed(
      msg.sender,
      roundId,
      identifier,
      time,
      price,
      ancillaryData,
      balance.rawValue
    );
  }

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    int256 salt
  ) public override {
    revealVote(identifier, time, price, '', salt);
  }

  /**
   * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
   * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
   * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
   * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
   * @param time unix timestamp of for the price request.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
   * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
   */
  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash,
    bytes memory encryptedVote
  ) public override {
    commitVote(identifier, time, ancillaryData, hash);

    uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());
    emit EncryptedVote(
      msg.sender,
      roundId,
      identifier,
      time,
      ancillaryData,
      encryptedVote
    );
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash,
    bytes memory encryptedVote
  ) public override {
    commitVote(identifier, time, '', hash);

    commitAndEmitEncryptedVote(identifier, time, '', hash, encryptedVote);
  }

  /**
   * @notice Submit a batch of commits in a single transaction.
   * @dev Using `encryptedVote` is optional. If included then commitment is emitted in an event.
   * Look at `project-root/common/Constants.js` for the tested maximum number of
   * commitments that can fit in one transaction.
   * @param commits struct to encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
   */
  function batchCommit(CommitmentAncillary[] memory commits) public override {
    for (uint256 i = 0; i < commits.length; i++) {
      if (commits[i].encryptedVote.length == 0) {
        commitVote(
          commits[i].identifier,
          commits[i].time,
          commits[i].ancillaryData,
          commits[i].hash
        );
      } else {
        commitAndEmitEncryptedVote(
          commits[i].identifier,
          commits[i].time,
          commits[i].ancillaryData,
          commits[i].hash,
          commits[i].encryptedVote
        );
      }
    }
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function batchCommit(Commitment[] memory commits) public override {
    CommitmentAncillary[] memory commitsAncillary =
      new CommitmentAncillary[](commits.length);

    for (uint256 i = 0; i < commits.length; i++) {
      commitsAncillary[i].identifier = commits[i].identifier;
      commitsAncillary[i].time = commits[i].time;
      commitsAncillary[i].ancillaryData = '';
      commitsAncillary[i].hash = commits[i].hash;
      commitsAncillary[i].encryptedVote = commits[i].encryptedVote;
    }
    batchCommit(commitsAncillary);
  }

  /**
   * @notice Reveal multiple votes in a single transaction.
   * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
   * that can fit in one transaction.
   * @dev For more info on reveals, review the comment for `revealVote`.
   * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
   */
  function batchReveal(RevealAncillary[] memory reveals) public override {
    for (uint256 i = 0; i < reveals.length; i++) {
      revealVote(
        reveals[i].identifier,
        reveals[i].time,
        reveals[i].price,
        reveals[i].ancillaryData,
        reveals[i].salt
      );
    }
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function batchReveal(Reveal[] memory reveals) public override {
    RevealAncillary[] memory revealsAncillary =
      new RevealAncillary[](reveals.length);

    for (uint256 i = 0; i < reveals.length; i++) {
      revealsAncillary[i].identifier = reveals[i].identifier;
      revealsAncillary[i].time = reveals[i].time;
      revealsAncillary[i].price = reveals[i].price;
      revealsAncillary[i].ancillaryData = '';
      revealsAncillary[i].salt = reveals[i].salt;
    }
    batchReveal(revealsAncillary);
  }

  /**
   * @notice Retrieves rewards owed for a set of resolved price requests.
   * @dev Can only retrieve rewards if calling for a valid round and if the call is done within the timeout threshold
   * (not expired). Note that a named return value is used here to avoid a stack to deep error.
   * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
   * @param roundId the round from which voting rewards will be retrieved from.
   * @param toRetrieve array of PendingRequests which rewards are retrieved from.
   * @return totalRewardToIssue total amount of rewards returned to the voter.
   */
  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequestAncillary[] memory toRetrieve
  ) public override returns (FixedPoint.Unsigned memory totalRewardToIssue) {
    if (migratedAddress != address(0)) {
      require(msg.sender == migratedAddress, 'Can only call from migrated');
    }
    require(
      roundId < voteTiming.computeCurrentRoundId(getCurrentTime()),
      'Invalid roundId'
    );

    Round storage round = rounds[roundId];
    bool isExpired = getCurrentTime() > round.rewardsExpirationTime;
    FixedPoint.Unsigned memory snapshotBalance =
      FixedPoint.Unsigned(
        votingToken.balanceOfAt(voterAddress, round.snapshotId)
      );

    FixedPoint.Unsigned memory snapshotTotalSupply =
      FixedPoint.Unsigned(votingToken.totalSupplyAt(round.snapshotId));
    FixedPoint.Unsigned memory totalRewardPerVote =
      round.inflationRate.mul(snapshotTotalSupply);

    totalRewardToIssue = FixedPoint.Unsigned(0);

    for (uint256 i = 0; i < toRetrieve.length; i++) {
      PriceRequest storage priceRequest =
        _getPriceRequest(
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData
        );
      VoteInstance storage voteInstance =
        priceRequest.voteInstances[priceRequest.lastVotingRound];

      require(
        priceRequest.lastVotingRound == roundId,
        'Retrieve for votes same round'
      );

      _resolvePriceRequest(priceRequest, voteInstance);

      if (voteInstance.voteSubmissions[voterAddress].revealHash == 0) {
        continue;
      } else if (isExpired) {
        emit RewardsRetrieved(
          voterAddress,
          roundId,
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData,
          0
        );
      } else if (
        voteInstance.resultComputation.wasVoteCorrect(
          voteInstance.voteSubmissions[voterAddress].revealHash
        )
      ) {
        FixedPoint.Unsigned memory reward =
          snapshotBalance.mul(totalRewardPerVote).div(
            voteInstance.resultComputation.getTotalCorrectlyVotedTokens()
          );
        totalRewardToIssue = totalRewardToIssue.add(reward);

        emit RewardsRetrieved(
          voterAddress,
          roundId,
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData,
          reward.rawValue
        );
      } else {
        emit RewardsRetrieved(
          voterAddress,
          roundId,
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData,
          0
        );
      }

      delete voteInstance.voteSubmissions[voterAddress].revealHash;
    }

    if (totalRewardToIssue.isGreaterThan(0)) {
      require(
        votingToken.mint(voterAddress, totalRewardToIssue.rawValue),
        'Voting token issuance failed'
      );
    }
  }

  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequest[] memory toRetrieve
  ) public override returns (FixedPoint.Unsigned memory) {
    PendingRequestAncillary[] memory toRetrieveAncillary =
      new PendingRequestAncillary[](toRetrieve.length);

    for (uint256 i = 0; i < toRetrieve.length; i++) {
      toRetrieveAncillary[i].identifier = toRetrieve[i].identifier;
      toRetrieveAncillary[i].time = toRetrieve[i].time;
      toRetrieveAncillary[i].ancillaryData = '';
    }

    return retrieveRewards(voterAddress, roundId, toRetrieveAncillary);
  }

  /****************************************
   *        VOTING GETTER FUNCTIONS       *
   ****************************************/

  /**
   * @notice Gets the queries that are being voted on this round.
   * @return pendingRequests array containing identifiers of type `PendingRequest`.
   * and timestamps for all pending requests.
   */
  function getPendingRequests()
    external
    view
    override(VotingInterface, VotingAncillaryInterface)
    returns (PendingRequestAncillary[] memory)
  {
    uint256 blockTime = getCurrentTime();
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

    // Solidity memory arrays aren't resizable (and reading storage is expensive). Hence this hackery to filter
    // `pendingPriceRequests` only to those requests that have an Active RequestStatus.
    PendingRequestAncillary[] memory unresolved =
      new PendingRequestAncillary[](pendingPriceRequests.length);
    uint256 numUnresolved = 0;

    for (uint256 i = 0; i < pendingPriceRequests.length; i++) {
      PriceRequest storage priceRequest =
        priceRequests[pendingPriceRequests[i]];
      if (
        _getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active
      ) {
        unresolved[numUnresolved] = PendingRequestAncillary({
          identifier: priceRequest.identifier,
          time: priceRequest.time,
          ancillaryData: priceRequest.ancillaryData
        });
        numUnresolved++;
      }
    }

    PendingRequestAncillary[] memory pendingRequests =
      new PendingRequestAncillary[](numUnresolved);
    for (uint256 i = 0; i < numUnresolved; i++) {
      pendingRequests[i] = unresolved[i];
    }
    return pendingRequests;
  }

  /**
   * @notice Returns the current voting phase, as a function of the current time.
   * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
   */
  function getVotePhase()
    external
    view
    override(VotingInterface, VotingAncillaryInterface)
    returns (Phase)
  {
    return voteTiming.computeCurrentPhase(getCurrentTime());
  }

  /**
   * @notice Returns the current round ID, as a function of the current time.
   * @return uint256 representing the unique round ID.
   */
  function getCurrentRoundId()
    external
    view
    override(VotingInterface, VotingAncillaryInterface)
    returns (uint256)
  {
    return voteTiming.computeCurrentRoundId(getCurrentTime());
  }

  /****************************************
   *        OWNER ADMIN FUNCTIONS         *
   ****************************************/

  /**
   * @notice Disables this Voting contract in favor of the migrated one.
   * @dev Can only be called by the contract owner.
   * @param newVotingAddress the newly migrated contract address.
   */
  function setMigrated(address newVotingAddress)
    external
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    migratedAddress = newVotingAddress;
  }

  /**
   * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
   * @dev This method is public because calldata structs are not currently supported by solidity.
   * @param newInflationRate sets the next round's inflation rate.
   */
  function setInflationRate(FixedPoint.Unsigned memory newInflationRate)
    public
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    inflationRate = newInflationRate;
  }

  /**
   * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
   * @dev This method is public because calldata structs are not currently supported by solidity.
   * @param newGatPercentage sets the next round's Gat percentage.
   */
  function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage)
    public
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    require(newGatPercentage.isLessThan(1), 'GAT percentage must be < 100%');
    gatPercentage = newGatPercentage;
  }

  /**
   * @notice Resets the rewards expiration timeout.
   * @dev This change only applies to rounds that have not yet begun.
   * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
   */
  function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout)
    public
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    rewardsExpirationTimeout = NewRewardsExpirationTimeout;
  }

  /****************************************
   *    PRIVATE AND INTERNAL FUNCTIONS    *
   ****************************************/

  // Returns the price for a given identifer. Three params are returns: bool if there was an error, int to represent
  // the resolved price and a string which is filled with an error message, if there was an error or "".
  function _getPriceOrError(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  )
    private
    view
    returns (
      bool,
      int256,
      string memory
    )
  {
    PriceRequest storage priceRequest =
      _getPriceRequest(identifier, time, ancillaryData);
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());

    RequestStatus requestStatus =
      _getRequestStatus(priceRequest, currentRoundId);
    if (requestStatus == RequestStatus.Active) {
      return (false, 0, 'Current voting round not ended');
    } else if (requestStatus == RequestStatus.Resolved) {
      VoteInstance storage voteInstance =
        priceRequest.voteInstances[priceRequest.lastVotingRound];
      (, int256 resolvedPrice) =
        voteInstance.resultComputation.getResolvedPrice(
          _computeGat(priceRequest.lastVotingRound)
        );
      return (true, resolvedPrice, '');
    } else if (requestStatus == RequestStatus.Future) {
      return (false, 0, 'Price is still to be voted on');
    } else {
      return (false, 0, 'Price was never requested');
    }
  }

  function _getPriceRequest(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) private view returns (PriceRequest storage) {
    return priceRequests[_encodePriceRequest(identifier, time, ancillaryData)];
  }

  function _encodePriceRequest(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(identifier, time, ancillaryData));
  }

  function _freezeRoundVariables(uint256 roundId) private {
    Round storage round = rounds[roundId];

    if (round.snapshotId == 0) {
      round.snapshotId = votingToken.snapshot();

      rounds[roundId].inflationRate = inflationRate;

      rounds[roundId].gatPercentage = gatPercentage;

      rounds[roundId].rewardsExpirationTime = voteTiming
        .computeRoundEndTime(roundId)
        .add(rewardsExpirationTimeout);
    }
  }

  function _resolvePriceRequest(
    PriceRequest storage priceRequest,
    VoteInstance storage voteInstance
  ) private {
    if (priceRequest.index == UINT_MAX) {
      return;
    }
    (bool isResolved, int256 resolvedPrice) =
      voteInstance.resultComputation.getResolvedPrice(
        _computeGat(priceRequest.lastVotingRound)
      );
    require(isResolved, "Can't resolve unresolved request");

    uint256 lastIndex = pendingPriceRequests.length - 1;
    PriceRequest storage lastPriceRequest =
      priceRequests[pendingPriceRequests[lastIndex]];
    lastPriceRequest.index = priceRequest.index;
    pendingPriceRequests[priceRequest.index] = pendingPriceRequests[lastIndex];
    pendingPriceRequests.pop();

    priceRequest.index = UINT_MAX;
    emit PriceResolved(
      priceRequest.lastVotingRound,
      priceRequest.identifier,
      priceRequest.time,
      resolvedPrice,
      priceRequest.ancillaryData
    );
  }

  function _computeGat(uint256 roundId)
    private
    view
    returns (FixedPoint.Unsigned memory)
  {
    uint256 snapshotId = rounds[roundId].snapshotId;
    if (snapshotId == 0) {
      return FixedPoint.Unsigned(UINT_MAX);
    }

    FixedPoint.Unsigned memory snapshottedSupply =
      FixedPoint.Unsigned(votingToken.totalSupplyAt(snapshotId));

    return snapshottedSupply.mul(rounds[roundId].gatPercentage);
  }

  function _getRequestStatus(
    PriceRequest storage priceRequest,
    uint256 currentRoundId
  ) private view returns (RequestStatus) {
    if (priceRequest.lastVotingRound == 0) {
      return RequestStatus.NotRequested;
    } else if (priceRequest.lastVotingRound < currentRoundId) {
      VoteInstance storage voteInstance =
        priceRequest.voteInstances[priceRequest.lastVotingRound];
      (bool isResolved, ) =
        voteInstance.resultComputation.getResolvedPrice(
          _computeGat(priceRequest.lastVotingRound)
        );
      return isResolved ? RequestStatus.Resolved : RequestStatus.Active;
    } else if (priceRequest.lastVotingRound == currentRoundId) {
      return RequestStatus.Active;
    } else {
      return RequestStatus.Future;
    }
  }

  function _getIdentifierWhitelist()
    private
    view
    returns (IdentifierWhitelistInterface supportedIdentifiers)
  {
    return
      IdentifierWhitelistInterface(
        finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../interfaces/IdentifierWhitelistInterface.sol';
import '../../../../../@openzeppelin/contracts/access/Ownable.sol';

contract IdentifierWhitelist is IdentifierWhitelistInterface, Ownable {
  mapping(bytes32 => bool) private supportedIdentifiers;

  event SupportedIdentifierAdded(bytes32 indexed identifier);
  event SupportedIdentifierRemoved(bytes32 indexed identifier);

  function addSupportedIdentifier(bytes32 identifier)
    external
    override
    onlyOwner
  {
    if (!supportedIdentifiers[identifier]) {
      supportedIdentifiers[identifier] = true;
      emit SupportedIdentifierAdded(identifier);
    }
  }

  function removeSupportedIdentifier(bytes32 identifier)
    external
    override
    onlyOwner
  {
    if (supportedIdentifiers[identifier]) {
      supportedIdentifiers[identifier] = false;
      emit SupportedIdentifierRemoved(identifier);
    }
  }

  function isIdentifierSupported(bytes32 identifier)
    external
    view
    override
    returns (bool)
  {
    return supportedIdentifiers[identifier];
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/MultiRole.sol';
import '../interfaces/RegistryInterface.sol';

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';

contract Registry is RegistryInterface, MultiRole {
  using SafeMath for uint256;

  enum Roles {Owner, ContractCreator}

  enum Validity {Invalid, Valid}

  struct FinancialContract {
    Validity valid;
    uint128 index;
  }

  struct Party {
    address[] contracts;
    mapping(address => uint256) contractIndex;
  }

  address[] public registeredContracts;

  mapping(address => FinancialContract) public contractMap;

  mapping(address => Party) private partyMap;

  event NewContractRegistered(
    address indexed contractAddress,
    address indexed creator,
    address[] parties
  );
  event PartyAdded(address indexed contractAddress, address indexed party);
  event PartyRemoved(address indexed contractAddress, address indexed party);

  constructor() public {
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );

    _createSharedRole(
      uint256(Roles.ContractCreator),
      uint256(Roles.Owner),
      new address[](0)
    );
  }

  function registerContract(address[] calldata parties, address contractAddress)
    external
    override
    onlyRoleHolder(uint256(Roles.ContractCreator))
  {
    FinancialContract storage financialContract = contractMap[contractAddress];
    require(
      contractMap[contractAddress].valid == Validity.Invalid,
      'Can only register once'
    );

    registeredContracts.push(contractAddress);

    financialContract.index = uint128(registeredContracts.length.sub(1));

    financialContract.valid = Validity.Valid;
    for (uint256 i = 0; i < parties.length; i = i.add(1)) {
      _addPartyToContract(parties[i], contractAddress);
    }

    emit NewContractRegistered(contractAddress, msg.sender, parties);
  }

  function addPartyToContract(address party) external override {
    address contractAddress = msg.sender;
    require(
      contractMap[contractAddress].valid == Validity.Valid,
      'Can only add to valid contract'
    );

    _addPartyToContract(party, contractAddress);
  }

  function removePartyFromContract(address partyAddress) external override {
    address contractAddress = msg.sender;
    Party storage party = partyMap[partyAddress];
    uint256 numberOfContracts = party.contracts.length;

    require(numberOfContracts != 0, 'Party has no contracts');
    require(
      contractMap[contractAddress].valid == Validity.Valid,
      'Remove only from valid contract'
    );
    require(
      isPartyMemberOfContract(partyAddress, contractAddress),
      'Can only remove existing party'
    );

    uint256 deleteIndex = party.contractIndex[contractAddress];

    address lastContractAddress = party.contracts[numberOfContracts - 1];

    party.contracts[deleteIndex] = lastContractAddress;

    party.contractIndex[lastContractAddress] = deleteIndex;

    party.contracts.pop();
    delete party.contractIndex[contractAddress];

    emit PartyRemoved(contractAddress, partyAddress);
  }

  function isContractRegistered(address contractAddress)
    external
    view
    override
    returns (bool)
  {
    return contractMap[contractAddress].valid == Validity.Valid;
  }

  function getRegisteredContracts(address party)
    external
    view
    override
    returns (address[] memory)
  {
    return partyMap[party].contracts;
  }

  function getAllRegisteredContracts()
    external
    view
    override
    returns (address[] memory)
  {
    return registeredContracts;
  }

  function isPartyMemberOfContract(address party, address contractAddress)
    public
    view
    override
    returns (bool)
  {
    uint256 index = partyMap[party].contractIndex[contractAddress];
    return
      partyMap[party].contracts.length > index &&
      partyMap[party].contracts[index] == contractAddress;
  }

  function _addPartyToContract(address party, address contractAddress)
    internal
  {
    require(
      !isPartyMemberOfContract(party, contractAddress),
      'Can only register a party once'
    );
    uint256 contractIndex = partyMap[party].contracts.length;
    partyMap[party].contracts.push(contractAddress);
    partyMap[party].contractIndex[contractAddress] = contractIndex;

    emit PartyAdded(contractAddress, party);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../interfaces/AdministrateeInterface.sol';
import '../../../../../@openzeppelin/contracts/access/Ownable.sol';

contract FinancialContractsAdmin is Ownable {
  function callEmergencyShutdown(address financialContract) external onlyOwner {
    AdministrateeInterface administratee =
      AdministrateeInterface(financialContract);
    administratee.emergencyShutdown();
  }

  function callRemargin(address financialContract) external onlyOwner {
    AdministrateeInterface administratee =
      AdministrateeInterface(financialContract);
    administratee.remargin();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/MultiRole.sol';
import '../../common/implementation/FixedPoint.sol';
import '../../common/implementation/Testable.sol';
import '../interfaces/FinderInterface.sol';
import '../interfaces/IdentifierWhitelistInterface.sol';
import '../interfaces/OracleInterface.sol';
import './Constants.sol';

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/utils/Address.sol';

contract Governor is MultiRole, Testable {
  using SafeMath for uint256;
  using Address for address;

  enum Roles {Owner, Proposer}

  struct Transaction {
    address to;
    uint256 value;
    bytes data;
  }

  struct Proposal {
    Transaction[] transactions;
    uint256 requestTime;
  }

  FinderInterface private finder;
  Proposal[] public proposals;

  event NewProposal(uint256 indexed id, Transaction[] transactions);

  event ProposalExecuted(uint256 indexed id, uint256 transactionIndex);

  constructor(
    address _finderAddress,
    uint256 _startingId,
    address _timerAddress
  ) public Testable(_timerAddress) {
    finder = FinderInterface(_finderAddress);
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );
    _createExclusiveRole(
      uint256(Roles.Proposer),
      uint256(Roles.Owner),
      msg.sender
    );

    uint256 maxStartingId = 10**18;
    require(
      _startingId <= maxStartingId,
      'Cannot set startingId larger than 10^18'
    );

    assembly {
      sstore(proposals_slot, _startingId)
    }
  }

  function propose(Transaction[] memory transactions)
    public
    onlyRoleHolder(uint256(Roles.Proposer))
  {
    uint256 id = proposals.length;
    uint256 time = getCurrentTime();

    proposals.push();

    Proposal storage proposal = proposals[id];
    proposal.requestTime = time;

    for (uint256 i = 0; i < transactions.length; i++) {
      require(
        transactions[i].to != address(0),
        'The `to` address cannot be 0x0'
      );

      if (transactions[i].data.length > 0) {
        require(
          transactions[i].to.isContract(),
          "EOA can't accept tx with data"
        );
      }
      proposal.transactions.push(transactions[i]);
    }

    bytes32 identifier = _constructIdentifier(id);

    OracleInterface oracle = _getOracle();
    IdentifierWhitelistInterface supportedIdentifiers =
      _getIdentifierWhitelist();
    supportedIdentifiers.addSupportedIdentifier(identifier);

    oracle.requestPrice(identifier, time);
    supportedIdentifiers.removeSupportedIdentifier(identifier);

    emit NewProposal(id, transactions);
  }

  function executeProposal(uint256 id, uint256 transactionIndex)
    external
    payable
  {
    Proposal storage proposal = proposals[id];
    int256 price =
      _getOracle().getPrice(_constructIdentifier(id), proposal.requestTime);

    Transaction memory transaction = proposal.transactions[transactionIndex];

    require(
      transactionIndex == 0 ||
        proposal.transactions[transactionIndex.sub(1)].to == address(0),
      'Previous tx not yet executed'
    );
    require(transaction.to != address(0), 'Tx already executed');
    require(price != 0, 'Proposal was rejected');
    require(msg.value == transaction.value, 'Must send exact amount of ETH');

    delete proposal.transactions[transactionIndex];

    require(
      _executeCall(transaction.to, transaction.value, transaction.data),
      'Tx execution failed'
    );

    emit ProposalExecuted(id, transactionIndex);
  }

  function numProposals() external view returns (uint256) {
    return proposals.length;
  }

  function getProposal(uint256 id) external view returns (Proposal memory) {
    return proposals[id];
  }

  function _executeCall(
    address to,
    uint256 value,
    bytes memory data
  ) private returns (bool) {
    bool success;
    assembly {
      let inputData := add(data, 0x20)
      let inputDataSize := mload(data)
      success := call(gas(), to, value, inputData, inputDataSize, 0, 0)
    }
    return success;
  }

  function _getOracle() private view returns (OracleInterface) {
    return
      OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
  }

  function _getIdentifierWhitelist()
    private
    view
    returns (IdentifierWhitelistInterface supportedIdentifiers)
  {
    return
      IdentifierWhitelistInterface(
        finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
      );
  }

  function _constructIdentifier(uint256 id) internal pure returns (bytes32) {
    bytes32 bytesId = _uintToUtf8(id);
    return _addPrefix(bytesId, 'Admin ', 6);
  }

  function _uintToUtf8(uint256 v) internal pure returns (bytes32) {
    bytes32 ret;
    if (v == 0) {
      ret = '0';
    } else {
      uint256 bitsPerByte = 8;
      uint256 base = 10;
      uint256 utf8NumberOffset = 48;
      while (v > 0) {
        ret = ret >> bitsPerByte;

        uint256 leastSignificantDigit = v % base;

        bytes32 utf8Digit = bytes32(leastSignificantDigit + utf8NumberOffset);

        ret |= utf8Digit << (31 * bitsPerByte);

        v /= base;
      }
    }
    return ret;
  }

  function _addPrefix(
    bytes32 input,
    bytes32 prefix,
    uint256 prefixLength
  ) internal pure returns (bytes32) {
    bytes32 shiftedInput = input >> (prefixLength * 8);
    return shiftedInput | prefix;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/Withdrawable.sol';
import './DesignatedVoting.sol';

contract DesignatedVotingFactory is Withdrawable {
  enum Roles {Withdrawer}

  address private finder;
  mapping(address => DesignatedVoting) public designatedVotingContracts;

  constructor(address finderAddress) public {
    finder = finderAddress;

    _createWithdrawRole(
      uint256(Roles.Withdrawer),
      uint256(Roles.Withdrawer),
      msg.sender
    );
  }

  function newDesignatedVoting(address ownerAddress)
    external
    returns (DesignatedVoting)
  {
    require(
      address(designatedVotingContracts[msg.sender]) == address(0),
      'Duplicate hot key not permitted'
    );

    DesignatedVoting designatedVoting =
      new DesignatedVoting(finder, ownerAddress, msg.sender);
    designatedVotingContracts[msg.sender] = designatedVoting;
    return designatedVoting;
  }

  function setDesignatedVoting(address designatedVotingAddress) external {
    require(
      address(designatedVotingContracts[msg.sender]) == address(0),
      'Duplicate hot key not permitted'
    );
    designatedVotingContracts[msg.sender] = DesignatedVoting(
      designatedVotingAddress
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TestnetERC20 is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public ERC20(_name, _symbol) {
    _setupDecimals(_decimals);
  }

  function allocateTo(address ownerAddress, uint256 value) external {
    _mint(ownerAddress, value);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/utils/Address.sol';

import '../interfaces/StoreInterface.sol';
import '../interfaces/OracleAncillaryInterface.sol';
import '../interfaces/FinderInterface.sol';
import '../interfaces/IdentifierWhitelistInterface.sol';
import '../interfaces/OptimisticOracleInterface.sol';
import './Constants.sol';

import '../../common/implementation/Testable.sol';
import '../../common/implementation/Lockable.sol';
import '../../common/implementation/FixedPoint.sol';
import '../../common/implementation/AddressWhitelist.sol';

interface OptimisticRequester {
  function priceProposed(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external;

  function priceDisputed(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 refund
  ) external;

  function priceSettled(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 price
  ) external;
}

contract OptimisticOracle is OptimisticOracleInterface, Testable, Lockable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address;

  event RequestPrice(
    address indexed requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData,
    address currency,
    uint256 reward,
    uint256 finalFee
  );
  event ProposePrice(
    address indexed requester,
    address indexed proposer,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData,
    int256 proposedPrice
  );
  event DisputePrice(
    address indexed requester,
    address indexed proposer,
    address indexed disputer,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData
  );
  event Settle(
    address indexed requester,
    address indexed proposer,
    address indexed disputer,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData,
    int256 price,
    uint256 payout
  );

  mapping(bytes32 => Request) public requests;

  FinderInterface public finder;

  uint256 public defaultLiveness;

  constructor(
    uint256 _liveness,
    address _finderAddress,
    address _timerAddress
  ) public Testable(_timerAddress) {
    finder = FinderInterface(_finderAddress);
    _validateLiveness(_liveness);
    defaultLiveness = _liveness;
  }

  function requestPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward
  ) external override nonReentrant() returns (uint256 totalBond) {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Invalid,
      'requestPrice: Invalid'
    );
    require(
      _getIdentifierWhitelist().isIdentifierSupported(identifier),
      'Unsupported identifier'
    );
    require(
      _getCollateralWhitelist().isOnWhitelist(address(currency)),
      'Unsupported currency'
    );
    require(timestamp <= getCurrentTime(), 'Timestamp in future');
    require(
      ancillaryData.length <= ancillaryBytesLimit,
      'Invalid ancillary data'
    );
    uint256 finalFee = _getStore().computeFinalFee(address(currency)).rawValue;
    requests[
      _getId(msg.sender, identifier, timestamp, ancillaryData)
    ] = Request({
      proposer: address(0),
      disputer: address(0),
      currency: currency,
      settled: false,
      refundOnDispute: false,
      proposedPrice: 0,
      resolvedPrice: 0,
      expirationTime: 0,
      reward: reward,
      finalFee: finalFee,
      bond: finalFee,
      customLiveness: 0
    });

    if (reward > 0) {
      currency.safeTransferFrom(msg.sender, address(this), reward);
    }

    emit RequestPrice(
      msg.sender,
      identifier,
      timestamp,
      ancillaryData,
      address(currency),
      reward,
      finalFee
    );

    return finalFee.mul(2);
  }

  function setBond(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 bond
  ) external override nonReentrant() returns (uint256 totalBond) {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'setBond: Requested'
    );
    Request storage request =
      _getRequest(msg.sender, identifier, timestamp, ancillaryData);
    request.bond = bond;

    return bond.add(request.finalFee);
  }

  function setRefundOnDispute(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override nonReentrant() {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'setRefundOnDispute: Requested'
    );
    _getRequest(msg.sender, identifier, timestamp, ancillaryData)
      .refundOnDispute = true;
  }

  function setCustomLiveness(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 customLiveness
  ) external override nonReentrant() {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'setCustomLiveness: Requested'
    );
    _validateLiveness(customLiveness);
    _getRequest(msg.sender, identifier, timestamp, ancillaryData)
      .customLiveness = customLiveness;
  }

  function proposePriceFor(
    address proposer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) public override nonReentrant() returns (uint256 totalBond) {
    require(proposer != address(0), 'proposer address must be non 0');
    require(
      getState(requester, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'proposePriceFor: Requested'
    );
    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);
    request.proposer = proposer;
    request.proposedPrice = proposedPrice;

    request.expirationTime = getCurrentTime().add(
      request.customLiveness != 0 ? request.customLiveness : defaultLiveness
    );

    totalBond = request.bond.add(request.finalFee);
    if (totalBond > 0) {
      request.currency.safeTransferFrom(msg.sender, address(this), totalBond);
    }

    emit ProposePrice(
      requester,
      proposer,
      identifier,
      timestamp,
      ancillaryData,
      proposedPrice
    );

    if (address(requester).isContract())
      try
        OptimisticRequester(requester).priceProposed(
          identifier,
          timestamp,
          ancillaryData
        )
      {} catch {}
  }

  function proposePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) external override returns (uint256 totalBond) {
    return
      proposePriceFor(
        msg.sender,
        requester,
        identifier,
        timestamp,
        ancillaryData,
        proposedPrice
      );
  }

  function disputePriceFor(
    address disputer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public override nonReentrant() returns (uint256 totalBond) {
    require(disputer != address(0), 'disputer address must be non 0');
    require(
      getState(requester, identifier, timestamp, ancillaryData) ==
        State.Proposed,
      'disputePriceFor: Proposed'
    );
    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);
    request.disputer = disputer;

    uint256 finalFee = request.finalFee;
    uint256 bond = request.bond;
    totalBond = bond.add(finalFee);
    if (totalBond > 0) {
      request.currency.safeTransferFrom(msg.sender, address(this), totalBond);
    }

    StoreInterface store = _getStore();
    if (finalFee > 0) {
      uint256 burnedBond = _computeBurnedBond(request);

      uint256 totalFee = finalFee.add(burnedBond);
      request.currency.safeIncreaseAllowance(address(store), totalFee);
      _getStore().payOracleFeesErc20(
        address(request.currency),
        FixedPoint.Unsigned(totalFee)
      );
    }

    _getOracle().requestPrice(
      identifier,
      timestamp,
      _stampAncillaryData(ancillaryData, requester)
    );

    uint256 refund = 0;
    if (request.reward > 0 && request.refundOnDispute) {
      refund = request.reward;
      request.reward = 0;
      request.currency.safeTransfer(requester, refund);
    }

    emit DisputePrice(
      requester,
      request.proposer,
      disputer,
      identifier,
      timestamp,
      ancillaryData
    );

    if (address(requester).isContract())
      try
        OptimisticRequester(requester).priceDisputed(
          identifier,
          timestamp,
          ancillaryData,
          refund
        )
      {} catch {}
  }

  function disputePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override returns (uint256 totalBond) {
    return
      disputePriceFor(
        msg.sender,
        requester,
        identifier,
        timestamp,
        ancillaryData
      );
  }

  function settleAndGetPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override nonReentrant() returns (int256) {
    if (
      getState(msg.sender, identifier, timestamp, ancillaryData) !=
      State.Settled
    ) {
      _settle(msg.sender, identifier, timestamp, ancillaryData);
    }

    return
      _getRequest(msg.sender, identifier, timestamp, ancillaryData)
        .resolvedPrice;
  }

  function settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override nonReentrant() returns (uint256 payout) {
    return _settle(requester, identifier, timestamp, ancillaryData);
  }

  function getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view override returns (Request memory) {
    return _getRequest(requester, identifier, timestamp, ancillaryData);
  }

  function getState(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view override returns (State) {
    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);

    if (address(request.currency) == address(0)) {
      return State.Invalid;
    }

    if (request.proposer == address(0)) {
      return State.Requested;
    }

    if (request.settled) {
      return State.Settled;
    }

    if (request.disputer == address(0)) {
      return
        request.expirationTime <= getCurrentTime()
          ? State.Expired
          : State.Proposed;
    }

    return
      _getOracle().hasPrice(
        identifier,
        timestamp,
        _stampAncillaryData(ancillaryData, requester)
      )
        ? State.Resolved
        : State.Disputed;
  }

  function hasPrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view override returns (bool) {
    State state = getState(requester, identifier, timestamp, ancillaryData);
    return
      state == State.Settled ||
      state == State.Resolved ||
      state == State.Expired;
  }

  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    pure
    returns (bytes memory)
  {
    return _stampAncillaryData(ancillaryData, requester);
  }

  function _getId(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) private pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(requester, identifier, timestamp, ancillaryData)
      );
  }

  function _settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) private returns (uint256 payout) {
    State state = getState(requester, identifier, timestamp, ancillaryData);

    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);
    request.settled = true;

    if (state == State.Expired) {
      request.resolvedPrice = request.proposedPrice;
      payout = request.bond.add(request.finalFee).add(request.reward);
      request.currency.safeTransfer(request.proposer, payout);
    } else if (state == State.Resolved) {
      request.resolvedPrice = _getOracle().getPrice(
        identifier,
        timestamp,
        _stampAncillaryData(ancillaryData, requester)
      );
      bool disputeSuccess = request.resolvedPrice != request.proposedPrice;
      uint256 bond = request.bond;

      uint256 unburnedBond = bond.sub(_computeBurnedBond(request));

      payout = bond.add(unburnedBond).add(request.finalFee).add(request.reward);
      request.currency.safeTransfer(
        disputeSuccess ? request.disputer : request.proposer,
        payout
      );
    } else {
      revert('_settle: not settleable');
    }

    emit Settle(
      requester,
      request.proposer,
      request.disputer,
      identifier,
      timestamp,
      ancillaryData,
      request.resolvedPrice,
      payout
    );

    if (address(requester).isContract())
      try
        OptimisticRequester(requester).priceSettled(
          identifier,
          timestamp,
          ancillaryData,
          request.resolvedPrice
        )
      {} catch {}
  }

  function _getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) private view returns (Request storage) {
    return requests[_getId(requester, identifier, timestamp, ancillaryData)];
  }

  function _computeBurnedBond(Request storage request)
    private
    view
    returns (uint256)
  {
    return request.bond.div(2);
  }

  function _validateLiveness(uint256 _liveness) private pure {
    require(_liveness < 5200 weeks, 'Liveness too large');
    require(_liveness > 0, 'Liveness cannot be 0');
  }

  function _getOracle() internal view returns (OracleAncillaryInterface) {
    return
      OracleAncillaryInterface(
        finder.getImplementationAddress(OracleInterfaces.Oracle)
      );
  }

  function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
    return
      AddressWhitelist(
        finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist)
      );
  }

  function _getStore() internal view returns (StoreInterface) {
    return
      StoreInterface(finder.getImplementationAddress(OracleInterfaces.Store));
  }

  function _getIdentifierWhitelist()
    internal
    view
    returns (IdentifierWhitelistInterface)
  {
    return
      IdentifierWhitelistInterface(
        finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
      );
  }

  function _stampAncillaryData(bytes memory ancillaryData, address requester)
    internal
    pure
    returns (bytes memory)
  {
    return abi.encodePacked(ancillaryData, 'OptimisticOracle', requester);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import '../../common/implementation/Testable.sol';
import '../interfaces/OracleInterface.sol';
import '../interfaces/IdentifierWhitelistInterface.sol';
import '../interfaces/FinderInterface.sol';
import '../implementation/Constants.sol';

contract MockOracle is OracleInterface, Testable {
  struct Price {
    bool isAvailable;
    int256 price;
    uint256 verifiedTime;
  }

  struct QueryIndex {
    bool isValid;
    uint256 index;
  }

  struct QueryPoint {
    bytes32 identifier;
    uint256 time;
  }

  FinderInterface private finder;

  mapping(bytes32 => mapping(uint256 => Price)) private verifiedPrices;

  mapping(bytes32 => mapping(uint256 => QueryIndex)) private queryIndices;
  QueryPoint[] private requestedPrices;

  constructor(address _finderAddress, address _timerAddress)
    public
    Testable(_timerAddress)
  {
    finder = FinderInterface(_finderAddress);
  }

  function requestPrice(bytes32 identifier, uint256 time) public override {
    require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
    Price storage lookup = verifiedPrices[identifier][time];
    if (!lookup.isAvailable && !queryIndices[identifier][time].isValid) {
      queryIndices[identifier][time] = QueryIndex(true, requestedPrices.length);
      requestedPrices.push(QueryPoint(identifier, time));
    }
  }

  function pushPrice(
    bytes32 identifier,
    uint256 time,
    int256 price
  ) external {
    verifiedPrices[identifier][time] = Price(true, price, getCurrentTime());

    QueryIndex storage queryIndex = queryIndices[identifier][time];
    require(
      queryIndex.isValid,
      "Can't push prices that haven't been requested"
    );

    uint256 indexToReplace = queryIndex.index;
    delete queryIndices[identifier][time];
    uint256 lastIndex = requestedPrices.length - 1;
    if (lastIndex != indexToReplace) {
      QueryPoint storage queryToCopy = requestedPrices[lastIndex];
      queryIndices[queryToCopy.identifier][queryToCopy.time]
        .index = indexToReplace;
      requestedPrices[indexToReplace] = queryToCopy;
    }
  }

  function hasPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (bool)
  {
    require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
    Price storage lookup = verifiedPrices[identifier][time];
    return lookup.isAvailable;
  }

  function getPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (int256)
  {
    require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
    Price storage lookup = verifiedPrices[identifier][time];
    require(lookup.isAvailable);
    return lookup.price;
  }

  function getPendingQueries() external view returns (QueryPoint[] memory) {
    return requestedPrices;
  }

  function _getIdentifierWhitelist()
    private
    view
    returns (IdentifierWhitelistInterface supportedIdentifiers)
  {
    return
      IdentifierWhitelistInterface(
        finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../GSN/Context.sol';

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './MultiRole.sol';
import '../interfaces/ExpandedIERC20.sol';

contract ExpandedERC20 is ExpandedIERC20, ERC20, MultiRole {
  enum Roles {Owner, Minter, Burner}

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  ) public ERC20(_tokenName, _tokenSymbol) {
    _setupDecimals(_tokenDecimals);
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );
    _createSharedRole(
      uint256(Roles.Minter),
      uint256(Roles.Owner),
      new address[](0)
    );
    _createSharedRole(
      uint256(Roles.Burner),
      uint256(Roles.Owner),
      new address[](0)
    );
  }

  function mint(address recipient, uint256 value)
    external
    override
    onlyRoleHolder(uint256(Roles.Minter))
    returns (bool)
  {
    _mint(recipient, value);
    return true;
  }

  function burn(uint256 value)
    external
    override
    onlyRoleHolder(uint256(Roles.Burner))
  {
    _burn(msg.sender, value);
  }

  function addMinter(address account) external virtual override {
    addMember(uint256(Roles.Minter), account);
  }

  function addBurner(address account) external virtual override {
    addMember(uint256(Roles.Burner), account);
  }

  function resetOwner(address account) external virtual override {
    resetMember(uint256(Roles.Owner), account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../../math/SafeMath.sol';
import '../../utils/Arrays.sol';
import '../../utils/Counters.sol';
import './ERC20.sol';

abstract contract ERC20Snapshot is ERC20 {
  using SafeMath for uint256;
  using Arrays for uint256[];
  using Counters for Counters.Counter;

  struct Snapshots {
    uint256[] ids;
    uint256[] values;
  }

  mapping(address => Snapshots) private _accountBalanceSnapshots;
  Snapshots private _totalSupplySnapshots;

  Counters.Counter private _currentSnapshotId;

  event Snapshot(uint256 id);

  function _snapshot() internal virtual returns (uint256) {
    _currentSnapshotId.increment();

    uint256 currentId = _currentSnapshotId.current();
    emit Snapshot(currentId);
    return currentId;
  }

  function balanceOfAt(address account, uint256 snapshotId)
    public
    view
    returns (uint256)
  {
    (bool snapshotted, uint256 value) =
      _valueAt(snapshotId, _accountBalanceSnapshots[account]);

    return snapshotted ? value : balanceOf(account);
  }

  function totalSupplyAt(uint256 snapshotId) public view returns (uint256) {
    (bool snapshotted, uint256 value) =
      _valueAt(snapshotId, _totalSupplySnapshots);

    return snapshotted ? value : totalSupply();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (from == address(0)) {
      _updateAccountSnapshot(to);
      _updateTotalSupplySnapshot();
    } else if (to == address(0)) {
      _updateAccountSnapshot(from);
      _updateTotalSupplySnapshot();
    } else {
      _updateAccountSnapshot(from);
      _updateAccountSnapshot(to);
    }
  }

  function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
    private
    view
    returns (bool, uint256)
  {
    require(snapshotId > 0, 'ERC20Snapshot: id is 0');

    require(
      snapshotId <= _currentSnapshotId.current(),
      'ERC20Snapshot: nonexistent id'
    );

    uint256 index = snapshots.ids.findUpperBound(snapshotId);

    if (index == snapshots.ids.length) {
      return (false, 0);
    } else {
      return (true, snapshots.values[index]);
    }
  }

  function _updateAccountSnapshot(address account) private {
    _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
  }

  function _updateTotalSupplySnapshot() private {
    _updateSnapshot(_totalSupplySnapshots, totalSupply());
  }

  function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue)
    private
  {
    uint256 currentId = _currentSnapshotId.current();
    if (_lastSnapshotId(snapshots.ids) < currentId) {
      snapshots.ids.push(currentId);
      snapshots.values.push(currentValue);
    }
  }

  function _lastSnapshotId(uint256[] storage ids)
    private
    view
    returns (uint256)
  {
    if (ids.length == 0) {
      return 0;
    } else {
      return ids[ids.length - 1];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../../GSN/Context.sol';
import './IERC20.sol';
import '../../math/SafeMath.sol';

contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name_, string memory symbol_) public {
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        'ERC20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(
      amount,
      'ERC20: transfer amount exceeds balance'
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      'ERC20: burn amount exceeds balance'
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract ExpandedIERC20 is IERC20 {
  function burn(uint256 value) external virtual;

  function mint(address to, uint256 value) external virtual returns (bool);

  function addMinter(address account) external virtual;

  function addBurner(address account) external virtual;

  function resetOwner(address account) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../math/Math.sol';

library Arrays {
  function findUpperBound(uint256[] storage array, uint256 element)
    internal
    view
    returns (uint256)
  {
    if (array.length == 0) {
      return 0;
    }

    uint256 low = 0;
    uint256 high = array.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      if (array[mid] > element) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    if (low > 0 && array[low - 1] == element) {
      return low - 1;
    } else {
      return low;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../math/SafeMath.sol';

library Counters {
  using SafeMath for uint256;

  struct Counter {
    uint256 _value;
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

abstract contract OracleInterface {
  function requestPrice(bytes32 identifier, uint256 time) public virtual;

  function hasPrice(bytes32 identifier, uint256 time)
    public
    view
    virtual
    returns (bool);

  function getPrice(bytes32 identifier, uint256 time)
    public
    view
    virtual
    returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

abstract contract OracleAncillaryInterface {
  function requestPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public virtual;

  function hasPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view virtual returns (bool);

  function getPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';
import './VotingAncillaryInterface.sol';

abstract contract VotingInterface {
  struct PendingRequest {
    bytes32 identifier;
    uint256 time;
  }

  struct Commitment {
    bytes32 identifier;
    uint256 time;
    bytes32 hash;
    bytes encryptedVote;
  }

  struct Reveal {
    bytes32 identifier;
    uint256 time;
    int256 price;
    int256 salt;
  }

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash
  ) external virtual;

  function batchCommit(Commitment[] memory commits) public virtual;

  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash,
    bytes memory encryptedVote
  ) public virtual;

  function snapshotCurrentRound(bytes calldata signature) external virtual;

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    int256 salt
  ) public virtual;

  function batchReveal(Reveal[] memory reveals) public virtual;

  function getPendingRequests()
    external
    view
    virtual
    returns (VotingAncillaryInterface.PendingRequestAncillary[] memory);

  function getVotePhase()
    external
    view
    virtual
    returns (VotingAncillaryInterface.Phase);

  function getCurrentRoundId() external view virtual returns (uint256);

  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequest[] memory toRetrieve
  ) public virtual returns (FixedPoint.Unsigned memory);

  function setMigrated(address newVotingAddress) external virtual;

  function setInflationRate(FixedPoint.Unsigned memory newInflationRate)
    public
    virtual;

  function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage)
    public
    virtual;

  function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout)
    public
    virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';

abstract contract VotingAncillaryInterface {
  struct PendingRequestAncillary {
    bytes32 identifier;
    uint256 time;
    bytes ancillaryData;
  }

  struct CommitmentAncillary {
    bytes32 identifier;
    uint256 time;
    bytes ancillaryData;
    bytes32 hash;
    bytes encryptedVote;
  }

  struct RevealAncillary {
    bytes32 identifier;
    uint256 time;
    int256 price;
    bytes ancillaryData;
    int256 salt;
  }

  enum Phase {Commit, Reveal, NUM_PHASES_PLACEHOLDER}

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash
  ) public virtual;

  function batchCommit(CommitmentAncillary[] memory commits) public virtual;

  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash,
    bytes memory encryptedVote
  ) public virtual;

  function snapshotCurrentRound(bytes calldata signature) external virtual;

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    bytes memory ancillaryData,
    int256 salt
  ) public virtual;

  function batchReveal(RevealAncillary[] memory reveals) public virtual;

  function getPendingRequests()
    external
    view
    virtual
    returns (PendingRequestAncillary[] memory);

  function getVotePhase() external view virtual returns (Phase);

  function getCurrentRoundId() external view virtual returns (uint256);

  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequestAncillary[] memory toRetrieve
  ) public virtual returns (FixedPoint.Unsigned memory);

  function setMigrated(address newVotingAddress) external virtual;

  function setInflationRate(FixedPoint.Unsigned memory newInflationRate)
    public
    virtual;

  function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage)
    public
    virtual;

  function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout)
    public
    virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

interface IdentifierWhitelistInterface {
  function addSupportedIdentifier(bytes32 identifier) external;

  function removeSupportedIdentifier(bytes32 identifier) external;

  function isIdentifierSupported(bytes32 identifier)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../common/implementation/FixedPoint.sol';

library ResultComputation {
  using FixedPoint for FixedPoint.Unsigned;

  struct Data {
    mapping(int256 => FixedPoint.Unsigned) voteFrequency;
    FixedPoint.Unsigned totalVotes;
    int256 currentMode;
  }

  function addVote(
    Data storage data,
    int256 votePrice,
    FixedPoint.Unsigned memory numberTokens
  ) internal {
    data.totalVotes = data.totalVotes.add(numberTokens);
    data.voteFrequency[votePrice] = data.voteFrequency[votePrice].add(
      numberTokens
    );
    if (
      votePrice != data.currentMode &&
      data.voteFrequency[votePrice].isGreaterThan(
        data.voteFrequency[data.currentMode]
      )
    ) {
      data.currentMode = votePrice;
    }
  }

  function getResolvedPrice(
    Data storage data,
    FixedPoint.Unsigned memory minVoteThreshold
  ) internal view returns (bool isResolved, int256 price) {
    FixedPoint.Unsigned memory modeThreshold =
      FixedPoint.fromUnscaledUint(50).div(100);

    if (
      data.totalVotes.isGreaterThan(minVoteThreshold) &&
      data.voteFrequency[data.currentMode].div(data.totalVotes).isGreaterThan(
        modeThreshold
      )
    ) {
      isResolved = true;
      price = data.currentMode;
    } else {
      isResolved = false;
    }
  }

  function wasVoteCorrect(Data storage data, bytes32 voteHash)
    internal
    view
    returns (bool)
  {
    return voteHash == keccak256(abi.encode(data.currentMode));
  }

  function getTotalCorrectlyVotedTokens(Data storage data)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    return data.voteFrequency[data.currentMode];
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/VotingInterface.sol';

library VoteTiming {
  using SafeMath for uint256;

  struct Data {
    uint256 phaseLength;
  }

  function init(Data storage data, uint256 phaseLength) internal {
    require(phaseLength > 0);
    data.phaseLength = phaseLength;
  }

  function computeCurrentRoundId(Data storage data, uint256 currentTime)
    internal
    view
    returns (uint256)
  {
    uint256 roundLength =
      data.phaseLength.mul(
        uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER)
      );
    return currentTime.div(roundLength);
  }

  function computeRoundEndTime(Data storage data, uint256 roundId)
    internal
    view
    returns (uint256)
  {
    uint256 roundLength =
      data.phaseLength.mul(
        uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER)
      );
    return roundLength.mul(roundId.add(1));
  }

  function computeCurrentPhase(Data storage data, uint256 currentTime)
    internal
    view
    returns (VotingAncillaryInterface.Phase)
  {
    return
      VotingAncillaryInterface.Phase(
        currentTime.div(data.phaseLength).mod(
          uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER)
        )
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library OracleInterfaces {
  bytes32 public constant Oracle = 'Oracle';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant Store = 'Store';
  bytes32 public constant FinancialContractsAdmin = 'FinancialContractsAdmin';
  bytes32 public constant Registry = 'Registry';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant OptimisticOracle = 'OptimisticOracle';
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library ECDSA {
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    if (signature.length != 65) {
      revert('ECDSA: invalid signature length');
    }

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    require(
      uint256(s) <=
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      "ECDSA: invalid signature 's' value"
    );
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), 'ECDSA: invalid signature');

    return signer;
  }

  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

interface RegistryInterface {
  function registerContract(address[] calldata parties, address contractAddress)
    external;

  function isContractRegistered(address contractAddress)
    external
    view
    returns (bool);

  function getRegisteredContracts(address party)
    external
    view
    returns (address[] memory);

  function getAllRegisteredContracts() external view returns (address[] memory);

  function addPartyToContract(address party) external;

  function removePartyFromContract(address party) external;

  function isPartyMemberOfContract(address party, address contractAddress)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';

interface AdministrateeInterface {
  function emergencyShutdown() external;

  function remargin() external;

  function pfc() external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/MultiRole.sol';
import '../../common/implementation/Withdrawable.sol';
import '../interfaces/VotingAncillaryInterface.sol';
import '../interfaces/FinderInterface.sol';
import './Constants.sol';

contract DesignatedVoting is Withdrawable {
  enum Roles {Owner, Voter}

  FinderInterface private finder;

  constructor(
    address finderAddress,
    address ownerAddress,
    address voterAddress
  ) public {
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      ownerAddress
    );
    _createExclusiveRole(
      uint256(Roles.Voter),
      uint256(Roles.Owner),
      voterAddress
    );
    _setWithdrawRole(uint256(Roles.Owner));

    finder = FinderInterface(finderAddress);
  }

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().commitVote(identifier, time, ancillaryData, hash);
  }

  function batchCommit(
    VotingAncillaryInterface.CommitmentAncillary[] calldata commits
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().batchCommit(commits);
  }

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    bytes memory ancillaryData,
    int256 salt
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().revealVote(
      identifier,
      time,
      price,
      ancillaryData,
      salt
    );
  }

  function batchReveal(
    VotingAncillaryInterface.RevealAncillary[] calldata reveals
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().batchReveal(reveals);
  }

  function retrieveRewards(
    uint256 roundId,
    VotingAncillaryInterface.PendingRequestAncillary[] memory toRetrieve
  )
    public
    onlyRoleHolder(uint256(Roles.Voter))
    returns (FixedPoint.Unsigned memory)
  {
    return
      _getVotingAddress().retrieveRewards(address(this), roundId, toRetrieve);
  }

  function _getVotingAddress() private view returns (VotingAncillaryInterface) {
    return
      VotingAncillaryInterface(
        finder.getImplementationAddress(OracleInterfaces.Oracle)
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract OptimisticOracleInterface {
  enum State {
    Invalid,
    Requested,
    Proposed,
    Expired,
    Disputed,
    Resolved,
    Settled
  }

  struct Request {
    address proposer;
    address disputer;
    IERC20 currency;
    bool settled;
    bool refundOnDispute;
    int256 proposedPrice;
    int256 resolvedPrice;
    uint256 expirationTime;
    uint256 reward;
    uint256 finalFee;
    uint256 bond;
    uint256 customLiveness;
  }

  uint256 public constant ancillaryBytesLimit = 8192;

  function requestPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward
  ) external virtual returns (uint256 totalBond);

  function setBond(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 bond
  ) external virtual returns (uint256 totalBond);

  function setRefundOnDispute(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual;

  function setCustomLiveness(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 customLiveness
  ) external virtual;

  function proposePriceFor(
    address proposer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  function proposePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  function disputePriceFor(
    address disputer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public virtual returns (uint256 totalBond);

  function disputePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 totalBond);

  function settleAndGetPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (int256);

  function settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 payout);

  function getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (Request memory);

  function getState(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (State);

  function hasPrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/access/Ownable.sol';
import './Lockable.sol';

contract AddressWhitelist is Ownable, Lockable {
  enum Status {None, In, Out}
  mapping(address => Status) public whitelist;

  address[] public whitelistIndices;

  event AddedToWhitelist(address indexed addedAddress);
  event RemovedFromWhitelist(address indexed removedAddress);

  function addToWhitelist(address newElement)
    external
    nonReentrant()
    onlyOwner
  {
    if (whitelist[newElement] == Status.In) {
      return;
    }

    if (whitelist[newElement] == Status.None) {
      whitelistIndices.push(newElement);
    }

    whitelist[newElement] = Status.In;

    emit AddedToWhitelist(newElement);
  }

  function removeFromWhitelist(address elementToRemove)
    external
    nonReentrant()
    onlyOwner
  {
    if (whitelist[elementToRemove] != Status.Out) {
      whitelist[elementToRemove] = Status.Out;
      emit RemovedFromWhitelist(elementToRemove);
    }
  }

  function isOnWhitelist(address elementToCheck)
    external
    view
    nonReentrantView()
    returns (bool)
  {
    return whitelist[elementToCheck] == Status.In;
  }

  function getWhitelist()
    external
    view
    nonReentrantView()
    returns (address[] memory activeWhitelist)
  {
    uint256 activeCount = 0;
    for (uint256 i = 0; i < whitelistIndices.length; i++) {
      if (whitelist[whitelistIndices[i]] == Status.In) {
        activeCount++;
      }
    }

    activeWhitelist = new address[](activeCount);
    activeCount = 0;
    for (uint256 i = 0; i < whitelistIndices.length; i++) {
      address addr = whitelistIndices[i];
      if (whitelist[addr] == Status.In) {
        activeWhitelist[activeCount] = addr;
        activeCount++;
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {SynthereumTIC} from './TIC.sol';
import {SynthereumTICInterface} from './interfaces/ITIC.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {HitchensUnorderedKeySetLib} from './HitchensUnorderedKeySet.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';

library SynthereumTICHelper {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
  using SynthereumTICHelper for SynthereumTIC.Storage;

  function initialize(
    SynthereumTIC.Storage storage self,
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    address _liquidityProvider,
    address _validator,
    FixedPoint.Unsigned memory _startingCollateralization
  ) public {
    self.derivative = _derivative;
    self.finder = _finder;
    self.version = _version;
    self.liquidityProvider = _liquidityProvider;
    self.validator = _validator;
    self.startingCollateralization = _startingCollateralization;
    self.collateralToken = IERC20(
      address(self.derivative.collateralCurrency())
    );
  }

  function mintRequest(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) public returns (bytes32) {
    bytes32 mintID =
      keccak256(
        abi.encodePacked(
          msg.sender,
          collateralAmount.rawValue,
          numTokens.rawValue,
          now
        )
      );

    SynthereumTICInterface.MintRequest memory mint =
      SynthereumTICInterface.MintRequest(
        mintID,
        now,
        msg.sender,
        collateralAmount,
        numTokens
      );

    self.mintRequestSet.insert(mintID);
    self.mintRequests[mintID] = mint;

    return mintID;
  }

  function approveMint(SynthereumTIC.Storage storage self, bytes32 mintID)
    public
  {
    FixedPoint.Unsigned memory globalCollateralization =
      self.getGlobalCollateralizationRatio();

    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    require(self.mintRequestSet.exists(mintID), 'Mint request does not exist');
    SynthereumTICInterface.MintRequest memory mint = self.mintRequests[mintID];

    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        mint.collateralAmount,
        mint.numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    self.mintRequestSet.remove(mintID);
    delete self.mintRequests[mintID];

    FixedPoint.Unsigned memory feeTotal =
      mint.collateralAmount.mul(self.fee.feePercentage);

    self.pullCollateral(mint.sender, mint.collateralAmount.add(feeTotal));

    self.mintSynTokens(
      mint.numTokens.mulCeil(targetCollateralization),
      mint.numTokens
    );

    self.transferSynTokens(mint.sender, mint.numTokens);

    self.sendFee(feeTotal);
  }

  function rejectMint(SynthereumTIC.Storage storage self, bytes32 mintID)
    public
  {
    require(self.mintRequestSet.exists(mintID), 'Mint request does not exist');
    self.mintRequestSet.remove(mintID);
    delete self.mintRequests[mintID];
  }

  function deposit(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    self.pullCollateral(msg.sender, collateralAmount);
  }

  function withdraw(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    require(
      self.collateralToken.transfer(msg.sender, collateralAmount.rawValue)
    );
  }

  function exchangeMint(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) public {
    FixedPoint.Unsigned memory globalCollateralization =
      self.getGlobalCollateralizationRatio();

    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        collateralAmount,
        numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    require(self.pullCollateral(msg.sender, collateralAmount));

    self.mintSynTokens(numTokens.mulCeil(targetCollateralization), numTokens);

    self.transferSynTokens(msg.sender, numTokens);
  }

  function depositIntoDerivative(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    IDerivative derivative = self.derivative;
    self.collateralToken.approve(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.deposit(collateralAmount);
  }

  function withdrawRequest(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    self.derivative.requestWithdrawal(collateralAmount);
  }

  function withdrawPassedRequest(SynthereumTIC.Storage storage self) public {
    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.derivative.withdrawPassedRequest();

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );
    require(amountWithdrawn.isGreaterThan(0), 'No tokens were redeemed');
    require(
      self.collateralToken.transfer(msg.sender, amountWithdrawn.rawValue)
    );
  }

  function redeemRequest(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) public returns (bytes32) {
    bytes32 redeemID =
      keccak256(
        abi.encodePacked(
          msg.sender,
          collateralAmount.rawValue,
          numTokens.rawValue,
          now
        )
      );

    SynthereumTICInterface.RedeemRequest memory redeem =
      SynthereumTICInterface.RedeemRequest(
        redeemID,
        now,
        msg.sender,
        collateralAmount,
        numTokens
      );

    self.redeemRequestSet.insert(redeemID);
    self.redeemRequests[redeemID] = redeem;

    return redeemID;
  }

  function approveRedeem(SynthereumTIC.Storage storage self, bytes32 redeemID)
    public
  {
    require(
      self.redeemRequestSet.exists(redeemID),
      'Redeem request does not exist'
    );
    SynthereumTICInterface.RedeemRequest memory redeem =
      self.redeemRequests[redeemID];

    require(redeem.numTokens.isGreaterThan(0));

    IERC20 tokenCurrency = self.derivative.tokenCurrency();
    require(
      tokenCurrency.balanceOf(redeem.sender) >= redeem.numTokens.rawValue
    );

    self.redeemRequestSet.remove(redeemID);
    delete self.redeemRequests[redeemID];

    require(
      tokenCurrency.transferFrom(
        redeem.sender,
        address(this),
        redeem.numTokens.rawValue
      ),
      'Token transfer failed'
    );

    require(
      tokenCurrency.approve(
        address(self.derivative),
        redeem.numTokens.rawValue
      ),
      'Token approve failed'
    );

    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.derivative.redeem(redeem.numTokens);

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );

    require(amountWithdrawn.isGreaterThan(redeem.collateralAmount));

    FixedPoint.Unsigned memory feeTotal =
      redeem.collateralAmount.mul(self.fee.feePercentage);

    self.collateralToken.transfer(
      redeem.sender,
      redeem.collateralAmount.sub(feeTotal).rawValue
    );

    self.sendFee(feeTotal);
  }

  function rejectRedeem(SynthereumTIC.Storage storage self, bytes32 redeemID)
    public
  {
    require(
      self.redeemRequestSet.exists(redeemID),
      'Mint request does not exist'
    );
    self.redeemRequestSet.remove(redeemID);
    delete self.redeemRequests[redeemID];
  }

  function emergencyShutdown(SynthereumTIC.Storage storage self) external {
    self.derivative.emergencyShutdown();
  }

  function settleEmergencyShutdown(SynthereumTIC.Storage storage self) public {
    IERC20 tokenCurrency = self.derivative.tokenCurrency();

    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));

    require(
      numTokens.isGreaterThan(0) || msg.sender == self.liquidityProvider,
      'Account has nothing to settle'
    );

    if (numTokens.isGreaterThan(0)) {
      require(
        tokenCurrency.transferFrom(
          msg.sender,
          address(this),
          numTokens.rawValue
        ),
        'Token transfer failed'
      );

      require(
        tokenCurrency.approve(address(self.derivative), numTokens.rawValue),
        'Token approve failed'
      );
    }

    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.derivative.settleEmergencyShutdown();

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );

    require(amountWithdrawn.isGreaterThan(0), 'No collateral was withdrawn');

    FixedPoint.Unsigned memory totalToRedeem;

    if (msg.sender == self.liquidityProvider) {
      totalToRedeem = FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this))
      );
    } else {
      totalToRedeem = numTokens.mul(self.derivative.emergencyShutdownPrice());
      require(
        amountWithdrawn.isGreaterThanOrEqual(totalToRedeem),
        'Insufficient collateral withdrawn to redeem tokens'
      );
    }

    require(self.collateralToken.transfer(msg.sender, totalToRedeem.rawValue));
  }

  function exchangeRequest(
    SynthereumTIC.Storage storage self,
    SynthereumTICInterface destTIC,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory destNumTokens
  ) public returns (bytes32) {
    bytes32 exchangeID =
      keccak256(
        abi.encodePacked(
          msg.sender,
          address(destTIC),
          numTokens.rawValue,
          destNumTokens.rawValue,
          now
        )
      );

    SynthereumTICInterface.ExchangeRequest memory exchange =
      SynthereumTICInterface.ExchangeRequest(
        exchangeID,
        now,
        msg.sender,
        destTIC,
        numTokens,
        collateralAmount,
        destNumTokens
      );

    self.exchangeRequestSet.insert(exchangeID);
    self.exchangeRequests[exchangeID] = exchange;

    return exchangeID;
  }

  function approveExchange(
    SynthereumTIC.Storage storage self,
    bytes32 exchangeID
  ) public {
    require(
      self.exchangeRequestSet.exists(exchangeID),
      'Exchange request does not exist'
    );
    SynthereumTICInterface.ExchangeRequest memory exchange =
      self.exchangeRequests[exchangeID];

    self.exchangeRequestSet.remove(exchangeID);
    delete self.exchangeRequests[exchangeID];

    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.redeemForCollateral(exchange.sender, exchange.numTokens);

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );

    require(
      amountWithdrawn.isGreaterThan(exchange.collateralAmount),
      'No tokens were redeemed'
    );

    FixedPoint.Unsigned memory feeTotal =
      exchange.collateralAmount.mul(self.fee.feePercentage);

    self.sendFee(feeTotal);

    FixedPoint.Unsigned memory destinationCollateral =
      amountWithdrawn.sub(feeTotal);

    require(
      self.collateralToken.approve(
        address(exchange.destTIC),
        destinationCollateral.rawValue
      )
    );

    exchange.destTIC.exchangeMint(
      destinationCollateral.rawValue,
      exchange.destNumTokens.rawValue
    );

    require(
      exchange.destTIC.derivative().tokenCurrency().transfer(
        exchange.sender,
        exchange.destNumTokens.rawValue
      )
    );
  }

  function rejectExchange(
    SynthereumTIC.Storage storage self,
    bytes32 exchangeID
  ) public {
    require(
      self.exchangeRequestSet.exists(exchangeID),
      'Exchange request does not exist'
    );
    self.exchangeRequestSet.remove(exchangeID);
    delete self.exchangeRequests[exchangeID];
  }

  function setFeePercentage(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory _feePercentage
  ) public {
    self.fee.feePercentage = _feePercentage;
  }

  function setFeeRecipients(
    SynthereumTIC.Storage storage self,
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) public {
    require(
      _feeRecipients.length == _feeProportions.length,
      'Fee recipients and fee proportions do not match'
    );

    uint256 totalActualFeeProportions;

    for (uint256 i = 0; i < _feeProportions.length; i++) {
      totalActualFeeProportions += _feeProportions[i];
    }

    self.fee.feeRecipients = _feeRecipients;
    self.fee.feeProportions = _feeProportions;
    self.totalFeeProportions = totalActualFeeProportions;
  }

  function getMintRequests(SynthereumTIC.Storage storage self)
    public
    view
    returns (SynthereumTICInterface.MintRequest[] memory)
  {
    SynthereumTICInterface.MintRequest[] memory mintRequests =
      new SynthereumTICInterface.MintRequest[](self.mintRequestSet.count());

    for (uint256 i = 0; i < self.mintRequestSet.count(); i++) {
      mintRequests[i] = self.mintRequests[self.mintRequestSet.keyAtIndex(i)];
    }

    return mintRequests;
  }

  function getRedeemRequests(SynthereumTIC.Storage storage self)
    public
    view
    returns (SynthereumTICInterface.RedeemRequest[] memory)
  {
    SynthereumTICInterface.RedeemRequest[] memory redeemRequests =
      new SynthereumTICInterface.RedeemRequest[](self.redeemRequestSet.count());

    for (uint256 i = 0; i < self.redeemRequestSet.count(); i++) {
      redeemRequests[i] = self.redeemRequests[
        self.redeemRequestSet.keyAtIndex(i)
      ];
    }

    return redeemRequests;
  }

  function getExchangeRequests(SynthereumTIC.Storage storage self)
    public
    view
    returns (SynthereumTICInterface.ExchangeRequest[] memory)
  {
    SynthereumTICInterface.ExchangeRequest[] memory exchangeRequests =
      new SynthereumTICInterface.ExchangeRequest[](
        self.exchangeRequestSet.count()
      );

    for (uint256 i = 0; i < self.exchangeRequestSet.count(); i++) {
      exchangeRequests[i] = self.exchangeRequests[
        self.exchangeRequestSet.keyAtIndex(i)
      ];
    }

    return exchangeRequests;
  }

  function pullCollateral(
    SynthereumTIC.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (bool) {
    return
      self.collateralToken.transferFrom(
        from,
        address(this),
        numTokens.rawValue
      );
  }

  function mintSynTokens(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    require(
      self.collateralToken.approve(
        address(self.derivative),
        collateralAmount.rawValue
      )
    );
    self.derivative.create(collateralAmount, numTokens);
  }

  function transferSynTokens(
    SynthereumTIC.Storage storage self,
    address recipient,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    require(
      self.derivative.tokenCurrency().transfer(recipient, numTokens.rawValue)
    );
  }

  function sendFee(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory _feeAmount
  ) internal {
    for (uint256 i = 0; i < self.fee.feeRecipients.length; i++) {
      require(
        self.collateralToken.transfer(
          self.fee.feeRecipients[i],
          _feeAmount
            .mul(self.fee.feeProportions[i])
            .div(self.totalFeeProportions)
            .rawValue
        )
      );
    }
  }

  function redeemForCollateral(
    SynthereumTIC.Storage storage self,
    address tokenHolder,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    require(numTokens.isGreaterThan(0));

    IERC20 tokenCurrency = self.derivative.tokenCurrency();
    require(tokenCurrency.balanceOf(tokenHolder) >= numTokens.rawValue);

    require(
      tokenCurrency.transferFrom(
        tokenHolder,
        address(this),
        numTokens.rawValue
      ),
      'Token transfer failed'
    );

    require(
      tokenCurrency.approve(address(self.derivative), numTokens.rawValue),
      'Token approve failed'
    );

    self.derivative.redeem(numTokens);
  }

  function getGlobalCollateralizationRatio(SynthereumTIC.Storage storage self)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    FixedPoint.Unsigned memory totalTokensOutstanding =
      self.derivative.globalPositionData().totalTokensOutstanding;

    if (totalTokensOutstanding.isGreaterThan(0)) {
      return
        self.derivative.totalPositionCollateral().div(totalTokensOutstanding);
    } else {
      return FixedPoint.fromUnscaledUint(0);
    }
  }

  function checkCollateralizationRatio(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory globalCollateralization,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (bool) {
    FixedPoint.Unsigned memory newCollateralization =
      collateralAmount
        .add(FixedPoint.Unsigned(self.collateralToken.balanceOf(address(this))))
        .div(numTokens);

    return newCollateralization.isGreaterThanOrEqual(globalCollateralization);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  AccessControl
} from '../../../@openzeppelin/contracts/access/AccessControl.sol';
import {SynthereumTICInterface} from './interfaces/ITIC.sol';
import '../../../@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {HitchensUnorderedKeySetLib} from './HitchensUnorderedKeySet.sol';
import {SynthereumTICHelper} from './TICHelper.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';

import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';

contract SynthereumTIC is
  AccessControl,
  SynthereumTICInterface,
  ReentrancyGuard
{
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  bytes32 public constant VALIDATOR_ROLE = keccak256('Validator');

  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
  using SynthereumTICHelper for Storage;

  struct Storage {
    ISynthereumFinder finder;
    uint8 version;
    IDerivative derivative;
    FixedPoint.Unsigned startingCollateralization;
    address liquidityProvider;
    address validator;
    IERC20 collateralToken;
    Fee fee;
    uint256 totalFeeProportions;
    mapping(bytes32 => MintRequest) mintRequests;
    HitchensUnorderedKeySetLib.Set mintRequestSet;
    mapping(bytes32 => ExchangeRequest) exchangeRequests;
    HitchensUnorderedKeySetLib.Set exchangeRequestSet;
    mapping(bytes32 => RedeemRequest) redeemRequests;
    HitchensUnorderedKeySetLib.Set redeemRequestSet;
  }

  event MintRequested(
    bytes32 mintID,
    uint256 timestamp,
    address indexed sender,
    uint256 collateralAmount,
    uint256 numTokens
  );
  event MintApproved(bytes32 mintID, address indexed sender);
  event MintRejected(bytes32 mintID, address indexed sender);

  event ExchangeRequested(
    bytes32 exchangeID,
    uint256 timestamp,
    address indexed sender,
    address destTIC,
    uint256 numTokens,
    uint256 destNumTokens
  );
  event ExchangeApproved(bytes32 exchangeID, address indexed sender);
  event ExchangeRejected(bytes32 exchangeID, address indexed sender);

  event RedeemRequested(
    bytes32 redeemID,
    uint256 timestamp,
    address indexed sender,
    uint256 collateralAmount,
    uint256 numTokens
  );
  event RedeemApproved(bytes32 redeemID, address indexed sender);
  event RedeemRejected(bytes32 redeemID, address indexed sender);
  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  Storage private ticStorage;

  constructor(
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    Roles memory _roles,
    uint256 _startingCollateralization,
    Fee memory _fee
  ) public nonReentrant {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(VALIDATOR_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
    _setupRole(LIQUIDITY_PROVIDER_ROLE, _roles.liquidityProvider);
    _setupRole(VALIDATOR_ROLE, _roles.validator);
    ticStorage.initialize(
      _derivative,
      _finder,
      _version,
      _roles.liquidityProvider,
      _roles.validator,
      FixedPoint.Unsigned(_startingCollateralization)
    );
    _setFeePercentage(_fee.feePercentage.rawValue);
    _setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyLiquidityProvider() {
    require(
      hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender),
      'Sender must be the liquidity provider'
    );
    _;
  }

  modifier onlyValidator() {
    require(
      hasRole(VALIDATOR_ROLE, msg.sender),
      'Sender must be the validator'
    );
    _;
  }

  function mintRequest(uint256 collateralAmount, uint256 numTokens)
    external
    override
    nonReentrant
  {
    bytes32 mintID =
      ticStorage.mintRequest(
        FixedPoint.Unsigned(collateralAmount),
        FixedPoint.Unsigned(numTokens)
      );

    emit MintRequested(mintID, now, msg.sender, collateralAmount, numTokens);
  }

  function approveMint(bytes32 mintID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.mintRequests[mintID].sender;

    ticStorage.approveMint(mintID);

    emit MintApproved(mintID, sender);
  }

  function rejectMint(bytes32 mintID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.mintRequests[mintID].sender;

    ticStorage.rejectMint(mintID);

    emit MintRejected(mintID, sender);
  }

  function deposit(uint256 collateralAmount)
    external
    override
    nonReentrant
    onlyLiquidityProvider
  {
    ticStorage.deposit(FixedPoint.Unsigned(collateralAmount));
  }

  function withdraw(uint256 collateralAmount)
    external
    override
    nonReentrant
    onlyLiquidityProvider
  {
    ticStorage.withdraw(FixedPoint.Unsigned(collateralAmount));
  }

  function exchangeMint(uint256 collateralAmount, uint256 numTokens)
    external
    override
    nonReentrant
  {
    ticStorage.exchangeMint(
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens)
    );
  }

  function depositIntoDerivative(uint256 collateralAmount)
    external
    override
    nonReentrant
    onlyLiquidityProvider
  {
    ticStorage.depositIntoDerivative(FixedPoint.Unsigned(collateralAmount));
  }

  function withdrawRequest(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    ticStorage.withdrawRequest(FixedPoint.Unsigned(collateralAmount));
  }

  function withdrawPassedRequest()
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    ticStorage.withdrawPassedRequest();
  }

  function redeemRequest(uint256 collateralAmount, uint256 numTokens)
    external
    override
    nonReentrant
  {
    bytes32 redeemID =
      ticStorage.redeemRequest(
        FixedPoint.Unsigned(collateralAmount),
        FixedPoint.Unsigned(numTokens)
      );

    emit RedeemRequested(
      redeemID,
      now,
      msg.sender,
      collateralAmount,
      numTokens
    );
  }

  function approveRedeem(bytes32 redeemID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.redeemRequests[redeemID].sender;

    ticStorage.approveRedeem(redeemID);

    emit RedeemApproved(redeemID, sender);
  }

  function rejectRedeem(bytes32 redeemID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.redeemRequests[redeemID].sender;

    ticStorage.rejectRedeem(redeemID);

    emit RedeemRejected(redeemID, sender);
  }

  function emergencyShutdown() external override onlyMaintainer nonReentrant {
    ticStorage.emergencyShutdown();
  }

  function settleEmergencyShutdown() external override nonReentrant {
    ticStorage.settleEmergencyShutdown();
  }

  function exchangeRequest(
    SynthereumTICInterface destTIC,
    uint256 numTokens,
    uint256 collateralAmount,
    uint256 destNumTokens
  ) external override nonReentrant {
    bytes32 exchangeID =
      ticStorage.exchangeRequest(
        destTIC,
        FixedPoint.Unsigned(numTokens),
        FixedPoint.Unsigned(collateralAmount),
        FixedPoint.Unsigned(destNumTokens)
      );

    emit ExchangeRequested(
      exchangeID,
      now,
      msg.sender,
      address(destTIC),
      numTokens,
      destNumTokens
    );
  }

  function approveExchange(bytes32 exchangeID)
    external
    override
    onlyValidator
    nonReentrant
  {
    address sender = ticStorage.exchangeRequests[exchangeID].sender;

    ticStorage.approveExchange(exchangeID);

    emit ExchangeApproved(exchangeID, sender);
  }

  function rejectExchange(bytes32 exchangeID)
    external
    override
    onlyValidator
    nonReentrant
  {
    address sender = ticStorage.exchangeRequests[exchangeID].sender;

    ticStorage.rejectExchange(exchangeID);

    emit ExchangeRejected(exchangeID, sender);
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = ticStorage.finder;
  }

  function version() external view override returns (uint8 poolVersion) {
    poolVersion = ticStorage.version;
  }

  function derivative() external view override returns (IDerivative) {
    return ticStorage.derivative;
  }

  function collateralToken() external view override returns (IERC20) {
    return ticStorage.collateralToken;
  }

  function syntheticToken() external view override returns (IERC20) {
    return ticStorage.derivative.tokenCurrency();
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(ticStorage.derivative.tokenCurrency()))
      .symbol();
  }

  function calculateFee(uint256 collateralAmount)
    external
    view
    override
    returns (uint256)
  {
    return
      FixedPoint
        .Unsigned(collateralAmount)
        .mul(ticStorage.fee.feePercentage)
        .rawValue;
  }

  function getMintRequests()
    external
    view
    override
    returns (MintRequest[] memory)
  {
    return ticStorage.getMintRequests();
  }

  function getRedeemRequests()
    external
    view
    override
    returns (RedeemRequest[] memory)
  {
    return ticStorage.getRedeemRequests();
  }

  function getExchangeRequests()
    external
    view
    override
    returns (ExchangeRequest[] memory)
  {
    return ticStorage.getExchangeRequests();
  }

  function setFee(Fee memory _fee)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    _setFeePercentage(_fee.feePercentage.rawValue);
    _setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  function setFeePercentage(uint256 _feePercentage)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    _setFeePercentage(_feePercentage);
  }

  function setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) external override nonReentrant onlyMaintainer {
    _setFeeRecipients(_feeRecipients, _feeProportions);
  }

  function _setFeePercentage(uint256 _feePercentage) private {
    ticStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
    emit SetFeePercentage(_feePercentage);
  }

  function _setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) private {
    ticStorage.setFeeRecipients(_feeRecipients, _feeProportions);
    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';
import {
  ISynthereumPoolDeployment
} from '../../common/interfaces/IPoolDeployment.sol';

interface SynthereumTICInterface is ISynthereumPoolDeployment {
  struct Fee {
    FixedPoint.Unsigned feePercentage;
    address[] feeRecipients;
    uint32[] feeProportions;
  }

  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
    address validator;
  }

  struct MintRequest {
    bytes32 mintID;
    uint256 timestamp;
    address sender;
    FixedPoint.Unsigned collateralAmount;
    FixedPoint.Unsigned numTokens;
  }

  struct ExchangeRequest {
    bytes32 exchangeID;
    uint256 timestamp;
    address sender;
    SynthereumTICInterface destTIC;
    FixedPoint.Unsigned numTokens;
    FixedPoint.Unsigned collateralAmount;
    FixedPoint.Unsigned destNumTokens;
  }

  struct RedeemRequest {
    bytes32 redeemID;
    uint256 timestamp;
    address sender;
    FixedPoint.Unsigned collateralAmount;
    FixedPoint.Unsigned numTokens;
  }

  function mintRequest(uint256 collateralAmount, uint256 numTokens) external;

  function approveMint(bytes32 mintID) external;

  function rejectMint(bytes32 mintID) external;

  function deposit(uint256 collateralAmount) external;

  function withdraw(uint256 collateralAmount) external;

  function exchangeMint(uint256 collateralAmount, uint256 numTokens) external;

  function depositIntoDerivative(uint256 collateralAmount) external;

  function withdrawRequest(uint256 collateralAmount) external;

  function withdrawPassedRequest() external;

  function redeemRequest(uint256 collateralAmount, uint256 numTokens) external;

  function approveRedeem(bytes32 redeemID) external;

  function rejectRedeem(bytes32 redeemID) external;

  function emergencyShutdown() external;

  function settleEmergencyShutdown() external;

  function exchangeRequest(
    SynthereumTICInterface destTIC,
    uint256 numTokens,
    uint256 collateralAmount,
    uint256 destNumTokens
  ) external;

  function approveExchange(bytes32 exchangeID) external;

  function rejectExchange(bytes32 exchangeID) external;

  function setFee(Fee calldata _fee) external;

  function setFeePercentage(uint256 _feePercentage) external;

  function setFeeRecipients(
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external;

  function derivative() external view returns (IDerivative);

  function calculateFee(uint256 collateralAmount)
    external
    view
    returns (uint256);

  function getMintRequests() external view returns (MintRequest[] memory);

  function getRedeemRequests() external view returns (RedeemRequest[] memory);

  function getExchangeRequests()
    external
    view
    returns (ExchangeRequest[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library HitchensUnorderedKeySetLib {
  struct Set {
    mapping(bytes32 => uint256) keyPointers;
    bytes32[] keyList;
  }

  function insert(Set storage self, bytes32 key) internal {
    require(key != 0x0, 'UnorderedKeySet(100) - Key cannot be 0x0');
    require(
      !exists(self, key),
      'UnorderedKeySet(101) - Key already exists in the set.'
    );
    self.keyList.push(key);
    self.keyPointers[key] = self.keyList.length - 1;
  }

  function remove(Set storage self, bytes32 key) internal {
    require(
      exists(self, key),
      'UnorderedKeySet(102) - Key does not exist in the set.'
    );
    bytes32 keyToMove = self.keyList[count(self) - 1];
    uint256 rowToReplace = self.keyPointers[key];
    self.keyPointers[keyToMove] = rowToReplace;
    self.keyList[rowToReplace] = keyToMove;
    delete self.keyPointers[key];
    self.keyList.pop();
  }

  function count(Set storage self) internal view returns (uint256) {
    return (self.keyList.length);
  }

  function exists(Set storage self, bytes32 key) internal view returns (bool) {
    if (self.keyList.length == 0) return false;
    return self.keyList[self.keyPointers[key]] == key;
  }

  function keyAtIndex(Set storage self, uint256 index)
    internal
    view
    returns (bytes32)
  {
    return self.keyList[index];
  }

  function nukeSet(Set storage self) public {
    delete self.keyList;
  }
}

contract HitchensUnorderedKeySet {
  using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
  HitchensUnorderedKeySetLib.Set set;

  event LogUpdate(address sender, string action, bytes32 key);

  function exists(bytes32 key) public view returns (bool) {
    return set.exists(key);
  }

  function insert(bytes32 key) public {
    set.insert(key);
    emit LogUpdate(msg.sender, 'insert', key);
  }

  function remove(bytes32 key) public {
    set.remove(key);
    emit LogUpdate(msg.sender, 'remove', key);
  }

  function count() public view returns (uint256) {
    return set.count();
  }

  function keyAtIndex(uint256 index) public view returns (bytes32) {
    return set.keyAtIndex(index);
  }

  function nukeSet() public {
    set.nukeSet();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() internal {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

    _status = _ENTERED;

    _;

    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {SynthereumTICInterface} from './interfaces/ITIC.sol';
import {SynthereumTIC} from './TIC.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  IDeploymentSignature
} from '../../versioning/interfaces/IDeploymentSignature.sol';
import {TICCreator} from './TICCreator.sol';

contract SynthereumTICFactory is TICCreator, IDeploymentSignature {
  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  constructor(address _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createTIC.selector;
  }

  function createTIC(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    SynthereumTICInterface.Roles memory roles,
    uint256 startingCollateralization,
    SynthereumTICInterface.Fee memory fee
  ) public override returns (SynthereumTIC poolDeployed) {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    poolDeployed = super.createTIC(
      derivative,
      finder,
      version,
      roles,
      startingCollateralization,
      fee
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {SynthereumTICInterface} from './interfaces/ITIC.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';
import {SynthereumTIC} from './TIC.sol';

contract TICCreator is Lockable {
  function createTIC(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    SynthereumTICInterface.Roles memory roles,
    uint256 startingCollateralization,
    SynthereumTICInterface.Fee memory fee
  ) public virtual nonReentrant returns (SynthereumTIC poolDeployed) {
    poolDeployed = new SynthereumTIC(
      derivative,
      finder,
      version,
      roles,
      startingCollateralization,
      fee
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {
  IDeploymentSignature
} from '../../versioning/interfaces/IDeploymentSignature.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  PerpetualPoolPartyCreator
} from '../../../@jarvis-network/uma-core/contracts/financial-templates/perpetual-poolParty/PerpetutalPoolPartyCreator.sol';

contract SynthereumDerivativeFactory is
  PerpetualPoolPartyCreator,
  IDeploymentSignature
{
  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  constructor(
    address _synthereumFinder,
    address _umaFinder,
    address _tokenFactoryAddress,
    address _timerAddress
  )
    public
    PerpetualPoolPartyCreator(_umaFinder, _tokenFactoryAddress, _timerAddress)
  {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPerpetual.selector;
  }

  function createPerpetual(Params memory params)
    public
    override
    returns (address derivative)
  {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    derivative = super.createPerpetual(params);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/interfaces/MintableBurnableIERC20.sol';
import '../../oracle/implementation/ContractCreator.sol';
import '../../common/implementation/Testable.sol';
import '../../common/implementation/AddressWhitelist.sol';
import '../../common/implementation/Lockable.sol';
import '../common/MintableBurnableTokenFactory.sol';
import './PerpetualPoolPartyLib.sol';

contract PerpetualPoolPartyCreator is ContractCreator, Testable, Lockable {
  using FixedPoint for FixedPoint.Unsigned;

  struct Params {
    address collateralAddress;
    bytes32 priceFeedIdentifier;
    string syntheticName;
    string syntheticSymbol;
    address syntheticToken;
    FixedPoint.Unsigned collateralRequirement;
    FixedPoint.Unsigned disputeBondPct;
    FixedPoint.Unsigned sponsorDisputeRewardPct;
    FixedPoint.Unsigned disputerDisputeRewardPct;
    FixedPoint.Unsigned minSponsorTokens;
    uint256 withdrawalLiveness;
    uint256 liquidationLiveness;
    address excessTokenBeneficiary;
    address[] admins;
    address[] pools;
  }

  address public tokenFactoryAddress;

  event CreatedPerpetual(
    address indexed perpetualAddress,
    address indexed deployerAddress
  );

  constructor(
    address _finderAddress,
    address _tokenFactoryAddress,
    address _timerAddress
  )
    public
    ContractCreator(_finderAddress)
    Testable(_timerAddress)
    nonReentrant()
  {
    tokenFactoryAddress = _tokenFactoryAddress;
  }

  function createPerpetual(Params memory params)
    public
    virtual
    nonReentrant()
    returns (address)
  {
    require(bytes(params.syntheticName).length != 0, 'Missing synthetic name');
    require(
      bytes(params.syntheticSymbol).length != 0,
      'Missing synthetic symbol'
    );
    MintableBurnableTokenFactory tf =
      MintableBurnableTokenFactory(tokenFactoryAddress);
    address derivative;
    if (params.syntheticToken == address(0)) {
      MintableBurnableIERC20 tokenCurrency =
        tf.createToken(params.syntheticName, params.syntheticSymbol, 18);
      derivative = PerpetualPoolPartyLib.deploy(
        _convertParams(params, tokenCurrency)
      );

      tokenCurrency.addAdminAndMinterAndBurner(derivative);
      tokenCurrency.renounceAdmin();
    } else {
      MintableBurnableIERC20 tokenCurrency =
        MintableBurnableIERC20(params.syntheticToken);
      require(
        keccak256(abi.encodePacked(tokenCurrency.name())) ==
          keccak256(abi.encodePacked(params.syntheticName)),
        'Wrong synthetic token name'
      );
      require(
        keccak256(abi.encodePacked(tokenCurrency.symbol())) ==
          keccak256(abi.encodePacked(params.syntheticSymbol)),
        'Wrong synthetic token symbol'
      );
      require(
        tokenCurrency.decimals() == uint8(18),
        'Decimals of synthetic token must be 18'
      );
      derivative = PerpetualPoolPartyLib.deploy(
        _convertParams(params, tokenCurrency)
      );
    }

    _registerContract(new address[](0), address(derivative));

    emit CreatedPerpetual(address(derivative), msg.sender);

    return address(derivative);
  }

  function _convertParams(
    Params memory params,
    MintableBurnableIERC20 newTokenCurrency
  )
    private
    view
    returns (PerpetualPoolParty.ConstructorParams memory constructorParams)
  {
    constructorParams.positionManagerParams.finderAddress = finderAddress;
    constructorParams.positionManagerParams.timerAddress = timerAddress;

    require(params.withdrawalLiveness != 0, 'Withdrawal liveness cannot be 0');
    require(
      params.liquidationLiveness != 0,
      'Liquidation liveness cannot be 0'
    );
    require(
      params.excessTokenBeneficiary != address(0),
      'Token Beneficiary cannot be 0x0'
    );
    require(params.admins.length > 0, 'No admin addresses set');
    _requireWhitelistedCollateral(params.collateralAddress);

    require(
      params.withdrawalLiveness < 5200 weeks,
      'Withdrawal liveness too large'
    );
    require(
      params.liquidationLiveness < 5200 weeks,
      'Liquidation liveness too large'
    );

    constructorParams.positionManagerParams.tokenAddress = address(
      newTokenCurrency
    );
    constructorParams.positionManagerParams.collateralAddress = params
      .collateralAddress;
    constructorParams.positionManagerParams.priceFeedIdentifier = params
      .priceFeedIdentifier;
    constructorParams.liquidatableParams.collateralRequirement = params
      .collateralRequirement;
    constructorParams.liquidatableParams.disputeBondPct = params.disputeBondPct;
    constructorParams.liquidatableParams.sponsorDisputeRewardPct = params
      .sponsorDisputeRewardPct;
    constructorParams.liquidatableParams.disputerDisputeRewardPct = params
      .disputerDisputeRewardPct;
    constructorParams.positionManagerParams.minSponsorTokens = params
      .minSponsorTokens;
    constructorParams.positionManagerParams.withdrawalLiveness = params
      .withdrawalLiveness;
    constructorParams.liquidatableParams.liquidationLiveness = params
      .liquidationLiveness;
    constructorParams.positionManagerParams.excessTokenBeneficiary = params
      .excessTokenBeneficiary;
    constructorParams.roles.admins = params.admins;
    constructorParams.roles.pools = params.pools;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/ERC20.sol';

abstract contract MintableBurnableIERC20 is ERC20 {
  function burn(uint256 value) external virtual;

  function mint(address to, uint256 value) external virtual returns (bool);

  function addMinter(address account) external virtual;

  function addBurner(address account) external virtual;

  function addAdmin(address account) external virtual;

  function addAdminAndMinterAndBurner(address account) external virtual;

  function renounceMinter() external virtual;

  function renounceBurner() external virtual;

  function renounceAdmin() external virtual;

  function renounceAdminAndMinterAndBurner() external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../interfaces/FinderInterface.sol';
import '../../common/implementation/AddressWhitelist.sol';
import './Registry.sol';
import './Constants.sol';

abstract contract ContractCreator {
  address internal finderAddress;

  constructor(address _finderAddress) public {
    finderAddress = _finderAddress;
  }

  function _requireWhitelistedCollateral(address collateralAddress)
    internal
    view
  {
    FinderInterface finder = FinderInterface(finderAddress);
    AddressWhitelist collateralWhitelist =
      AddressWhitelist(
        finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist)
      );
    require(
      collateralWhitelist.isOnWhitelist(collateralAddress),
      'Collateral not whitelisted'
    );
  }

  function _registerContract(
    address[] memory parties,
    address contractToRegister
  ) internal {
    FinderInterface finder = FinderInterface(finderAddress);
    Registry registry =
      Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
    registry.registerContract(parties, contractToRegister);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import './MintableBurnableSyntheticToken.sol';
import '../../common/interfaces/MintableBurnableIERC20.sol';
import '../../common/implementation/Lockable.sol';

contract MintableBurnableTokenFactory is Lockable {
  function createToken(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) public virtual nonReentrant() returns (MintableBurnableIERC20 newToken) {
    MintableBurnableSyntheticToken mintableToken =
      new MintableBurnableSyntheticToken(tokenName, tokenSymbol, tokenDecimals);
    mintableToken.addAdmin(msg.sender);
    mintableToken.renounceAdmin();
    newToken = MintableBurnableIERC20(address(mintableToken));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './PerpetualPoolParty.sol';

library PerpetualPoolPartyLib {
  function deploy(PerpetualPoolParty.ConstructorParams memory params)
    public
    returns (address)
  {
    PerpetualPoolParty derivative = new PerpetualPoolParty(params);
    return address(derivative);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
import '../../common/implementation/MintableBurnableERC20.sol';
import '../../common/implementation/Lockable.sol';

contract MintableBurnableSyntheticToken is MintableBurnableERC20, Lockable {
  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  )
    public
    MintableBurnableERC20(tokenName, tokenSymbol, tokenDecimals)
    nonReentrant()
  {}

  function addMinter(address account) public override nonReentrant() {
    super.addMinter(account);
  }

  function addBurner(address account) public override nonReentrant() {
    super.addBurner(account);
  }

  function addAdmin(address account) public override nonReentrant() {
    super.addAdmin(account);
  }

  function addAdminAndMinterAndBurner(address account)
    public
    override
    nonReentrant()
  {
    super.addAdminAndMinterAndBurner(account);
  }

  function renounceMinter() public override nonReentrant() {
    super.renounceMinter();
  }

  function renounceBurner() public override nonReentrant() {
    super.renounceBurner();
  }

  function renounceAdmin() public override nonReentrant() {
    super.renounceAdmin();
  }

  function renounceAdminAndMinterAndBurner() public override nonReentrant() {
    super.renounceAdminAndMinterAndBurner();
  }

  function isMinter(address account)
    public
    view
    nonReentrantView()
    returns (bool)
  {
    return hasRole(MINTER_ROLE, account);
  }

  function isBurner(address account)
    public
    view
    nonReentrantView()
    returns (bool)
  {
    return hasRole(BURNER_ROLE, account);
  }

  function isAdmin(address account)
    public
    view
    nonReentrantView()
    returns (bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  function getAdminMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(DEFAULT_ADMIN_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function getMinterMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(MINTER_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(MINTER_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function getBurnerMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(BURNER_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(BURNER_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../../../../../@openzeppelin/contracts/access/AccessControl.sol';
import '../interfaces/MintableBurnableIERC20.sol';

contract MintableBurnableERC20 is ERC20, MintableBurnableIERC20, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256('Minter');

  bytes32 public constant BURNER_ROLE = keccak256('Burner');

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), 'Sender must be the minter');
    _;
  }

  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, msg.sender), 'Sender must be the burner');
    _;
  }

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  ) public ERC20(_tokenName, _tokenSymbol) {
    _setupDecimals(_tokenDecimals);
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(BURNER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function mint(address recipient, uint256 value)
    external
    override
    onlyMinter()
    returns (bool)
  {
    _mint(recipient, value);
    return true;
  }

  function burn(uint256 value) external override onlyBurner() {
    _burn(msg.sender, value);
  }

  function addMinter(address account) public virtual override {
    grantRole(MINTER_ROLE, account);
  }

  function addBurner(address account) public virtual override {
    grantRole(BURNER_ROLE, account);
  }

  function addAdmin(address account) public virtual override {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  function addAdminAndMinterAndBurner(address account) public virtual override {
    grantRole(DEFAULT_ADMIN_ROLE, account);
    grantRole(MINTER_ROLE, account);
    grantRole(BURNER_ROLE, account);
  }

  function renounceMinter() public virtual override {
    renounceRole(MINTER_ROLE, msg.sender);
  }

  function renounceBurner() public virtual override {
    renounceRole(BURNER_ROLE, msg.sender);
  }

  function renounceAdmin() public virtual override {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function renounceAdminAndMinterAndBurner() public virtual override {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    renounceRole(MINTER_ROLE, msg.sender);
    renounceRole(BURNER_ROLE, msg.sender);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './PerpetualLiquidatablePoolParty.sol';

contract PerpetualPoolParty is PerpetualLiquidatablePoolParty {
  constructor(ConstructorParams memory params)
    public
    PerpetualLiquidatablePoolParty(params)
  {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './PerpetualPositionManagerPoolParty.sol';

import '../../common/implementation/FixedPoint.sol';
import './PerpetualPositionManagerPoolPartyLib.sol';
import './PerpetualLiquidatablePoolPartyLib.sol';

contract PerpetualLiquidatablePoolParty is PerpetualPositionManagerPoolParty {
  using FixedPoint for FixedPoint.Unsigned;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using FeePayerPoolPartyLib for FixedPoint.Unsigned;
  using PerpetualLiquidatablePoolPartyLib for PerpetualPositionManagerPoolParty.PositionData;
  using PerpetualLiquidatablePoolPartyLib for LiquidationData;

  enum Status {
    Uninitialized,
    PreDispute,
    PendingDispute,
    DisputeSucceeded,
    DisputeFailed
  }

  struct LiquidatableParams {
    uint256 liquidationLiveness;
    FixedPoint.Unsigned collateralRequirement;
    FixedPoint.Unsigned disputeBondPct;
    FixedPoint.Unsigned sponsorDisputeRewardPct;
    FixedPoint.Unsigned disputerDisputeRewardPct;
  }

  struct LiquidationData {
    address sponsor;
    address liquidator;
    Status state;
    uint256 liquidationTime;
    FixedPoint.Unsigned tokensOutstanding;
    FixedPoint.Unsigned lockedCollateral;
    FixedPoint.Unsigned liquidatedCollateral;
    FixedPoint.Unsigned rawUnitCollateral;
    address disputer;
    FixedPoint.Unsigned settlementPrice;
    FixedPoint.Unsigned finalFee;
  }

  struct ConstructorParams {
    PerpetualPositionManagerPoolParty.PositionManagerParams positionManagerParams;
    PerpetualPositionManagerPoolParty.Roles roles;
    LiquidatableParams liquidatableParams;
  }

  struct LiquidatableData {
    FixedPoint.Unsigned rawLiquidationCollateral;
    uint256 liquidationLiveness;
    FixedPoint.Unsigned collateralRequirement;
    FixedPoint.Unsigned disputeBondPct;
    FixedPoint.Unsigned sponsorDisputeRewardPct;
    FixedPoint.Unsigned disputerDisputeRewardPct;
  }

  struct RewardsData {
    FixedPoint.Unsigned payToSponsor;
    FixedPoint.Unsigned payToLiquidator;
    FixedPoint.Unsigned payToDisputer;
    FixedPoint.Unsigned paidToSponsor;
    FixedPoint.Unsigned paidToLiquidator;
    FixedPoint.Unsigned paidToDisputer;
  }

  mapping(address => LiquidationData[]) public liquidations;

  LiquidatableData public liquidatableData;

  event LiquidationCreated(
    address indexed sponsor,
    address indexed liquidator,
    uint256 indexed liquidationId,
    uint256 tokensOutstanding,
    uint256 lockedCollateral,
    uint256 liquidatedCollateral,
    uint256 liquidationTime
  );
  event LiquidationDisputed(
    address indexed sponsor,
    address indexed liquidator,
    address indexed disputer,
    uint256 liquidationId,
    uint256 disputeBondAmount
  );
  event DisputeSettled(
    address indexed caller,
    address indexed sponsor,
    address indexed liquidator,
    address disputer,
    uint256 liquidationId,
    bool disputeSucceeded
  );
  event LiquidationWithdrawn(
    address indexed caller,
    uint256 paidToLiquidator,
    uint256 paidToDisputer,
    uint256 paidToSponsor,
    Status indexed liquidationStatus,
    uint256 settlementPrice
  );

  modifier disputable(uint256 liquidationId, address sponsor) {
    _disputable(liquidationId, sponsor);
    _;
  }

  modifier withdrawable(uint256 liquidationId, address sponsor) {
    _withdrawable(liquidationId, sponsor);
    _;
  }

  constructor(ConstructorParams memory params)
    public
    PerpetualPositionManagerPoolParty(
      params.positionManagerParams,
      params.roles
    )
  {
    require(
      params.liquidatableParams.collateralRequirement.isGreaterThan(1),
      'CR is more than 100%'
    );
    require(
      params
        .liquidatableParams
        .sponsorDisputeRewardPct
        .add(params.liquidatableParams.disputerDisputeRewardPct)
        .isLessThan(1),
      'Rewards are more than 100%'
    );

    liquidatableData.liquidationLiveness = params
      .liquidatableParams
      .liquidationLiveness;
    liquidatableData.collateralRequirement = params
      .liquidatableParams
      .collateralRequirement;
    liquidatableData.disputeBondPct = params.liquidatableParams.disputeBondPct;
    liquidatableData.sponsorDisputeRewardPct = params
      .liquidatableParams
      .sponsorDisputeRewardPct;
    liquidatableData.disputerDisputeRewardPct = params
      .liquidatableParams
      .disputerDisputeRewardPct;
  }

  function createLiquidation(
    address sponsor,
    FixedPoint.Unsigned calldata minCollateralPerToken,
    FixedPoint.Unsigned calldata maxCollateralPerToken,
    FixedPoint.Unsigned calldata maxTokensToLiquidate,
    uint256 deadline
  )
    external
    fees()
    notEmergencyShutdown()
    nonReentrant()
    returns (
      uint256 liquidationId,
      FixedPoint.Unsigned memory tokensLiquidated,
      FixedPoint.Unsigned memory finalFeeBond
    )
  {
    PositionData storage positionToLiquidate = _getPositionData(sponsor);

    LiquidationData[] storage TokenSponsorLiquidations = liquidations[sponsor];

    FixedPoint.Unsigned memory finalFee = _computeFinalFees();

    uint256 actualTime = getCurrentTime();

    PerpetualLiquidatablePoolPartyLib.CreateLiquidationParams memory params =
      PerpetualLiquidatablePoolPartyLib.CreateLiquidationParams(
        minCollateralPerToken,
        maxCollateralPerToken,
        maxTokensToLiquidate,
        actualTime,
        deadline,
        finalFee,
        sponsor
      );


      PerpetualLiquidatablePoolPartyLib.CreateLiquidationReturnParams
        memory returnValues
    ;

    returnValues = positionToLiquidate.createLiquidation(
      globalPositionData,
      positionManagerData,
      liquidatableData,
      TokenSponsorLiquidations,
      params,
      feePayerData
    );

    return (
      returnValues.liquidationId,
      returnValues.tokensLiquidated,
      returnValues.finalFeeBond
    );
  }

  function dispute(uint256 liquidationId, address sponsor)
    external
    disputable(liquidationId, sponsor)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory totalPaid)
  {
    LiquidationData storage disputedLiquidation =
      _getLiquidationData(sponsor, liquidationId);

    totalPaid = disputedLiquidation.dispute(
      liquidatableData,
      positionManagerData,
      feePayerData,
      liquidationId,
      sponsor
    );
  }

  function withdrawLiquidation(uint256 liquidationId, address sponsor)
    public
    withdrawable(liquidationId, sponsor)
    fees()
    nonReentrant()
    returns (RewardsData memory)
  {
    LiquidationData storage liquidation =
      _getLiquidationData(sponsor, liquidationId);

    RewardsData memory rewardsData =
      liquidation.withdrawLiquidation(
        liquidatableData,
        positionManagerData,
        feePayerData,
        liquidationId,
        sponsor
      );

    return rewardsData;
  }

  function deleteLiquidation(uint256 liquidationId, address sponsor)
    external
    onlyThisContract
  {
    delete liquidations[sponsor][liquidationId];
  }

  function _pfc() internal view override returns (FixedPoint.Unsigned memory) {
    return
      super._pfc().add(
        liquidatableData.rawLiquidationCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );
  }

  function _getLiquidationData(address sponsor, uint256 liquidationId)
    internal
    view
    returns (LiquidationData storage liquidation)
  {
    LiquidationData[] storage liquidationArray = liquidations[sponsor];

    require(
      liquidationId < liquidationArray.length &&
        liquidationArray[liquidationId].state != Status.Uninitialized,
      'Invalid liquidation ID'
    );
    return liquidationArray[liquidationId];
  }

  function _getLiquidationExpiry(LiquidationData storage liquidation)
    internal
    view
    returns (uint256)
  {
    return
      liquidation.liquidationTime.add(liquidatableData.liquidationLiveness);
  }

  function _disputable(uint256 liquidationId, address sponsor) internal view {
    LiquidationData storage liquidation =
      _getLiquidationData(sponsor, liquidationId);
    require(
      (getCurrentTime() < _getLiquidationExpiry(liquidation)) &&
        (liquidation.state == Status.PreDispute),
      'Liquidation not disputable'
    );
  }

  function _withdrawable(uint256 liquidationId, address sponsor) internal view {
    LiquidationData storage liquidation =
      _getLiquidationData(sponsor, liquidationId);
    Status state = liquidation.state;

    require(
      (state > Status.PreDispute) ||
        ((_getLiquidationExpiry(liquidation) <= getCurrentTime()) &&
          (state == Status.PreDispute)),
      'Liquidation not withdrawable'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../common/implementation/FixedPoint.sol';
import '../../common/interfaces/MintableBurnableIERC20.sol';
import './PerpetualPositionManagerPoolPartyLib.sol';

import '../../oracle/interfaces/OracleInterface.sol';
import '../../oracle/interfaces/IdentifierWhitelistInterface.sol';
import '../../oracle/interfaces/AdministrateeInterface.sol';
import '../../oracle/implementation/Constants.sol';

import '../common/FeePayerPoolParty.sol';
import '../../../../../@openzeppelin/contracts/access/AccessControl.sol';

contract PerpetualPositionManagerPoolParty is AccessControl, FeePayerPoolParty {
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using PerpetualPositionManagerPoolPartyLib for PositionData;
  using PerpetualPositionManagerPoolPartyLib for PositionManagerData;

  bytes32 public constant POOL_ROLE = keccak256('Pool');

  struct Roles {
    address[] admins;
    address[] pools;
  }

  struct PositionManagerParams {
    uint256 withdrawalLiveness;
    address collateralAddress;
    address tokenAddress;
    address finderAddress;
    bytes32 priceFeedIdentifier;
    FixedPoint.Unsigned minSponsorTokens;
    address timerAddress;
    address excessTokenBeneficiary;
  }

  struct PositionData {
    FixedPoint.Unsigned tokensOutstanding;
    uint256 withdrawalRequestPassTimestamp;
    FixedPoint.Unsigned withdrawalRequestAmount;
    FixedPoint.Unsigned rawCollateral;
  }

  struct GlobalPositionData {
    FixedPoint.Unsigned totalTokensOutstanding;
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  struct PositionManagerData {
    MintableBurnableIERC20 tokenCurrency;
    bytes32 priceIdentifier;
    uint256 withdrawalLiveness;
    FixedPoint.Unsigned minSponsorTokens;
    FixedPoint.Unsigned emergencyShutdownPrice;
    uint256 emergencyShutdownTimestamp;
    address excessTokenBeneficiary;
  }

  mapping(address => PositionData) public positions;

  GlobalPositionData public globalPositionData;

  PositionManagerData public positionManagerData;

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event RequestWithdrawal(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalExecuted(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalCanceled(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  modifier onlyPool() {
    require(hasRole(POOL_ROLE, msg.sender), 'Sender must be a pool');
    _;
  }

  modifier onlyCollateralizedPosition(address sponsor) {
    _onlyCollateralizedPosition(sponsor);
    _;
  }

  modifier notEmergencyShutdown() {
    _notEmergencyShutdown();
    _;
  }

  modifier isEmergencyShutdown() {
    _isEmergencyShutdown();
    _;
  }

  modifier noPendingWithdrawal(address sponsor) {
    _positionHasNoPendingWithdrawal(sponsor);
    _;
  }

  constructor(
    PositionManagerParams memory _positionManagerData,
    Roles memory _roles
  )
    public
    FeePayerPoolParty(
      _positionManagerData.collateralAddress,
      _positionManagerData.finderAddress,
      _positionManagerData.timerAddress
    )
    nonReentrant()
  {
    require(
      _getIdentifierWhitelist().isIdentifierSupported(
        _positionManagerData.priceFeedIdentifier
      ),
      'Unsupported price identifier'
    );
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(POOL_ROLE, DEFAULT_ADMIN_ROLE);
    for (uint256 j = 0; j < _roles.admins.length; j++) {
      _setupRole(DEFAULT_ADMIN_ROLE, _roles.admins[j]);
    }
    for (uint256 j = 0; j < _roles.pools.length; j++) {
      _setupRole(POOL_ROLE, _roles.pools[j]);
    }
    positionManagerData.withdrawalLiveness = _positionManagerData
      .withdrawalLiveness;
    positionManagerData.tokenCurrency = MintableBurnableIERC20(
      _positionManagerData.tokenAddress
    );
    positionManagerData.minSponsorTokens = _positionManagerData
      .minSponsorTokens;
    positionManagerData.priceIdentifier = _positionManagerData
      .priceFeedIdentifier;
    positionManagerData.excessTokenBeneficiary = _positionManagerData
      .excessTokenBeneficiary;
  }

  function depositTo(
    address sponsor,
    FixedPoint.Unsigned memory collateralAmount
  )
    public
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(sponsor)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      collateralAmount,
      feePayerData,
      sponsor
    );
  }

  function deposit(FixedPoint.Unsigned memory collateralAmount) public {
    depositTo(msg.sender, collateralAmount);
  }

  function withdraw(FixedPoint.Unsigned memory collateralAmount)
    public
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData.withdraw(
      globalPositionData,
      collateralAmount,
      feePayerData
    );
  }

  function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
    public
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    nonReentrant()
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.requestWithdrawal(
      positionManagerData,
      collateralAmount,
      actualTime,
      feePayerData
    );
  }

  function withdrawPassedRequest()
    external
    onlyPool()
    notEmergencyShutdown()
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    amountWithdrawn = positionData.withdrawPassedRequest(
      globalPositionData,
      actualTime,
      feePayerData
    );
  }

  function cancelWithdrawal()
    external
    onlyPool()
    notEmergencyShutdown()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.cancelWithdrawal();
  }

  function create(
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) public onlyPool() notEmergencyShutdown() fees() nonReentrant() {
    PositionData storage positionData = positions[msg.sender];

    positionData.create(
      globalPositionData,
      positionManagerData,
      collateralAmount,
      numTokens,
      feePayerData
    );
  }

  function redeem(FixedPoint.Unsigned memory numTokens)
    public
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData.redeeem(
      globalPositionData,
      positionManagerData,
      numTokens,
      feePayerData,
      msg.sender
    );
  }

  function repay(FixedPoint.Unsigned memory numTokens)
    public
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.repay(globalPositionData, positionManagerData, numTokens);
  }

  function settleEmergencyShutdown()
    external
    onlyPool()
    isEmergencyShutdown()
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = positions[msg.sender];
    amountWithdrawn = positionData.settleEmergencyShutdown(
      globalPositionData,
      positionManagerData,
      feePayerData
    );
  }

  function emergencyShutdown()
    external
    override
    notEmergencyShutdown()
    nonReentrant()
  {
    require(
      hasRole(POOL_ROLE, msg.sender) ||
        msg.sender == _getFinancialContractsAdminAddress(),
      'Caller must be a pool or the UMA governor'
    );
    positionManagerData.emergencyShutdownTimestamp = getCurrentTime();
    positionManagerData.requestOraclePrice(
      positionManagerData.emergencyShutdownTimestamp,
      feePayerData
    );
    emit EmergencyShutdown(
      msg.sender,
      positionManagerData.emergencyShutdownTimestamp
    );
  }

  function remargin() external override {
    return;
  }

  function trimExcess(IERC20 token)
    external
    nonReentrant()
    returns (FixedPoint.Unsigned memory amount)
  {
    FixedPoint.Unsigned memory pfcAmount = _pfc();
    amount = positionManagerData.trimExcess(token, pfcAmount, feePayerData);
  }

  function deleteSponsorPosition(address sponsor) external onlyThisContract {
    delete positions[sponsor];
  }

  function addPool(address pool) external {
    grantRole(POOL_ROLE, pool);
  }

  function addAdmin(address admin) external {
    grantRole(DEFAULT_ADMIN_ROLE, admin);
  }

  function addAdminAndPool(address adminAndPool) external {
    grantRole(DEFAULT_ADMIN_ROLE, adminAndPool);
    grantRole(POOL_ROLE, adminAndPool);
  }

  function renouncePool() external {
    renounceRole(POOL_ROLE, msg.sender);
  }

  function renounceAdmin() external {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function renounceAdminAndPool() external {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    renounceRole(POOL_ROLE, msg.sender);
  }

  function addSyntheticTokenMinter(address derivative) external onlyPool() {
    positionManagerData.tokenCurrency.addMinter(derivative);
  }

  function addSyntheticTokenBurner(address derivative) external onlyPool() {
    positionManagerData.tokenCurrency.addBurner(derivative);
  }

  function addSyntheticTokenAdmin(address derivative) external onlyPool() {
    positionManagerData.tokenCurrency.addAdmin(derivative);
  }

  function addSyntheticTokenAdminAndMinterAndBurner(address derivative)
    external
    onlyPool()
  {
    positionManagerData.tokenCurrency.addAdminAndMinterAndBurner(derivative);
  }

  function renounceSyntheticTokenMinter() external onlyPool() {
    positionManagerData.tokenCurrency.renounceMinter();
  }

  function renounceSyntheticTokenBurner() external onlyPool() {
    positionManagerData.tokenCurrency.renounceBurner();
  }

  function renounceSyntheticTokenAdmin() external onlyPool() {
    positionManagerData.tokenCurrency.renounceAdmin();
  }

  function renounceSyntheticTokenAdminAndMinterAndBurner() external onlyPool() {
    positionManagerData.tokenCurrency.renounceAdminAndMinterAndBurner();
  }

  function getCollateral(address sponsor)
    external
    view
    nonReentrantView()
    returns (FixedPoint.Unsigned memory collateralAmount)
  {
    return
      positions[sponsor].rawCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function tokenCurrency() external view nonReentrantView() returns (IERC20) {
    return positionManagerData.tokenCurrency;
  }

  function totalPositionCollateral()
    external
    view
    nonReentrantView()
    returns (FixedPoint.Unsigned memory totalCollateral)
  {
    return
      globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function emergencyShutdownPrice()
    external
    view
    isEmergencyShutdown()
    nonReentrantView()
    returns (FixedPoint.Unsigned memory)
  {
    return positionManagerData.emergencyShutdownPrice;
  }

  function getAdminMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(DEFAULT_ADMIN_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function getPoolMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(POOL_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(POOL_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function _pfc()
    internal
    view
    virtual
    override
    returns (FixedPoint.Unsigned memory)
  {
    return
      globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _getPositionData(address sponsor)
    internal
    view
    onlyCollateralizedPosition(sponsor)
    returns (PositionData storage)
  {
    return positions[sponsor];
  }

  function _getIdentifierWhitelist()
    internal
    view
    returns (IdentifierWhitelistInterface)
  {
    return
      IdentifierWhitelistInterface(
        feePayerData.finder.getImplementationAddress(
          OracleInterfaces.IdentifierWhitelist
        )
      );
  }

  function _onlyCollateralizedPosition(address sponsor) internal view {
    require(
      positions[sponsor]
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isGreaterThan(0),
      'Position has no collateral'
    );
  }

  function _notEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp == 0,
      'Contract emergency shutdown'
    );
  }

  function _isEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp != 0,
      'Contract not emergency shutdown'
    );
  }

  function _positionHasNoPendingWithdrawal(address sponsor) internal view {
    require(
      _getPositionData(sponsor).withdrawalRequestPassTimestamp == 0,
      'Pending withdrawal'
    );
  }

  function _getFinancialContractsAdminAddress()
    internal
    view
    returns (address)
  {
    return
      feePayerData.finder.getImplementationAddress(
        OracleInterfaces.FinancialContractsAdmin
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../../common/interfaces/IERC20Standard.sol';
import '../../common/implementation/FixedPoint.sol';
import '../../common/interfaces/MintableBurnableIERC20.sol';
import '../../oracle/interfaces/OracleInterface.sol';
import '../../oracle/implementation/Constants.sol';
import './PerpetualPositionManagerPoolParty.sol';
import '../common/FeePayerPoolPartyLib.sol';

library PerpetualPositionManagerPoolPartyLib {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using PerpetualPositionManagerPoolPartyLib for PerpetualPositionManagerPoolParty.PositionData;
  using PerpetualPositionManagerPoolPartyLib for PerpetualPositionManagerPoolParty.PositionManagerData;
  using PerpetualPositionManagerPoolPartyLib for FeePayerPoolParty.FeePayerData;
  using PerpetualPositionManagerPoolPartyLib for FixedPoint.Unsigned;
  using FeePayerPoolPartyLib for FixedPoint.Unsigned;

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event RequestWithdrawal(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalExecuted(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalCanceled(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  function depositTo(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    address sponsor
  ) external {
    require(collateralAmount.isGreaterThan(0), 'Invalid collateral amount');

    positionData._incrementCollateralBalances(
      globalPositionData,
      collateralAmount,
      feePayerData
    );

    emit Deposit(sponsor, collateralAmount.rawValue);

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      collateralAmount.rawValue
    );
  }

  function withdraw(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(collateralAmount.isGreaterThan(0), 'Invalid collateral amount');

    amountWithdrawn = _decrementCollateralBalancesCheckGCR(
      positionData,
      globalPositionData,
      collateralAmount,
      feePayerData
    );

    emit Withdrawal(msg.sender, amountWithdrawn.rawValue);

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );
  }

  function requestWithdrawal(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    uint256 actualTime,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external {
    require(
      collateralAmount.isGreaterThan(0) &&
        collateralAmount.isLessThanOrEqual(
          positionData.rawCollateral.getFeeAdjustedCollateral(
            feePayerData.cumulativeFeeMultiplier
          )
        ),
      'Invalid collateral amount'
    );

    positionData.withdrawalRequestPassTimestamp = actualTime.add(
      positionManagerData.withdrawalLiveness
    );
    positionData.withdrawalRequestAmount = collateralAmount;

    emit RequestWithdrawal(msg.sender, collateralAmount.rawValue);
  }

  function withdrawPassedRequest(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    uint256 actualTime,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(
      positionData.withdrawalRequestPassTimestamp != 0 &&
        positionData.withdrawalRequestPassTimestamp <= actualTime,
      'Invalid withdraw request'
    );

    FixedPoint.Unsigned memory amountToWithdraw =
      positionData.withdrawalRequestAmount;
    if (
      positionData.withdrawalRequestAmount.isGreaterThan(
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      )
    ) {
      amountToWithdraw = positionData.rawCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
    }

    amountWithdrawn = positionData._decrementCollateralBalances(
      globalPositionData,
      amountToWithdraw,
      feePayerData
    );

    positionData._resetWithdrawalRequest();

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );

    emit RequestWithdrawalExecuted(msg.sender, amountWithdrawn.rawValue);
  }

  function cancelWithdrawal(
    PerpetualPositionManagerPoolParty.PositionData storage positionData
  ) external {
    require(
      positionData.withdrawalRequestPassTimestamp != 0,
      'No pending withdrawal'
    );

    emit RequestWithdrawalCanceled(
      msg.sender,
      positionData.withdrawalRequestAmount.rawValue
    );

    _resetWithdrawalRequest(positionData);
  }

  function create(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external {
    require(
      (_checkCollateralization(
        globalPositionData,
        positionData
          .rawCollateral
          .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
          .add(collateralAmount),
        positionData.tokensOutstanding.add(numTokens),
        feePayerData
      ) ||
        _checkCollateralization(
          globalPositionData,
          collateralAmount,
          numTokens,
          feePayerData
        )),
      'Insufficient collateral'
    );

    require(
      positionData.withdrawalRequestPassTimestamp == 0,
      'Pending withdrawal'
    );
    if (positionData.tokensOutstanding.isEqual(0)) {
      require(
        numTokens.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
        'Below minimum sponsor position'
      );
      emit NewSponsor(msg.sender);
    }

    _incrementCollateralBalances(
      positionData,
      globalPositionData,
      collateralAmount,
      feePayerData
    );

    positionData.tokensOutstanding = positionData.tokensOutstanding.add(
      numTokens
    );

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .add(numTokens);

    emit PositionCreated(
      msg.sender,
      collateralAmount.rawValue,
      numTokens.rawValue
    );

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      collateralAmount.rawValue
    );
    require(
      positionManagerData.tokenCurrency.mint(msg.sender, numTokens.rawValue),
      'Minting synthetic tokens failed'
    );
  }

  function redeeem(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    address sponsor
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    FixedPoint.Unsigned memory fractionRedeemed =
      numTokens.div(positionData.tokensOutstanding);
    FixedPoint.Unsigned memory collateralRedeemed =
      fractionRedeemed.mul(
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );

    if (positionData.tokensOutstanding.isEqual(numTokens)) {
      amountWithdrawn = positionData._deleteSponsorPosition(
        globalPositionData,
        feePayerData,
        sponsor
      );
    } else {
      amountWithdrawn = positionData._decrementCollateralBalances(
        globalPositionData,
        collateralRedeemed,
        feePayerData
      );

      FixedPoint.Unsigned memory newTokenCount =
        positionData.tokensOutstanding.sub(numTokens);
      require(
        newTokenCount.isGreaterThanOrEqual(
          positionManagerData.minSponsorTokens
        ),
        'Below minimum sponsor position'
      );
      positionData.tokensOutstanding = newTokenCount;

      globalPositionData.totalTokensOutstanding = globalPositionData
        .totalTokensOutstanding
        .sub(numTokens);
    }

    emit Redeem(msg.sender, amountWithdrawn.rawValue, numTokens.rawValue);

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );
    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      numTokens.rawValue
    );
    positionManagerData.tokenCurrency.burn(numTokens.rawValue);
  }

  function repay(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory numTokens
  ) external {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    FixedPoint.Unsigned memory newTokenCount =
      positionData.tokensOutstanding.sub(numTokens);
    require(
      newTokenCount.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
      'Below minimum sponsor position'
    );
    positionData.tokensOutstanding = newTokenCount;

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(numTokens);

    emit Repay(msg.sender, numTokens.rawValue, newTokenCount.rawValue);

    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      numTokens.rawValue
    );
    positionManagerData.tokenCurrency.burn(numTokens.rawValue);
  }

  function settleEmergencyShutdown(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    if (
      positionManagerData.emergencyShutdownPrice.isEqual(
        FixedPoint.fromUnscaledUint(0)
      )
    ) {
      FixedPoint.Unsigned memory oraclePrice =
        positionManagerData._getOracleEmergencyShutdownPrice(feePayerData);
      positionManagerData.emergencyShutdownPrice = oraclePrice
        ._decimalsScalingFactor(feePayerData);
    }

    FixedPoint.Unsigned memory tokensToRedeem =
      FixedPoint.Unsigned(
        positionManagerData.tokenCurrency.balanceOf(msg.sender)
      );

    FixedPoint.Unsigned memory totalRedeemableCollateral =
      tokensToRedeem.mul(positionManagerData.emergencyShutdownPrice);

    if (
      positionData
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isGreaterThan(0)
    ) {
      FixedPoint.Unsigned memory tokenDebtValueInCollateral =
        positionData.tokensOutstanding.mul(
          positionManagerData.emergencyShutdownPrice
        );
      FixedPoint.Unsigned memory positionCollateral =
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        );

      FixedPoint.Unsigned memory positionRedeemableCollateral =
        tokenDebtValueInCollateral.isLessThan(positionCollateral)
          ? positionCollateral.sub(tokenDebtValueInCollateral)
          : FixedPoint.Unsigned(0);

      totalRedeemableCollateral = totalRedeemableCollateral.add(
        positionRedeemableCollateral
      );

      PerpetualPositionManagerPoolParty(address(this)).deleteSponsorPosition(
        msg.sender
      );
      emit EndedSponsorPosition(msg.sender);
    }

    FixedPoint.Unsigned memory payout =
      FixedPoint.min(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        totalRedeemableCollateral
      );

    amountWithdrawn = globalPositionData
      .rawTotalPositionCollateral
      .removeCollateral(payout, feePayerData.cumulativeFeeMultiplier);
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToRedeem);

    emit SettleEmergencyShutdown(
      msg.sender,
      amountWithdrawn.rawValue,
      tokensToRedeem.rawValue
    );

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );
    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      tokensToRedeem.rawValue
    );
    positionManagerData.tokenCurrency.burn(tokensToRedeem.rawValue);
  }

  function trimExcess(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    IERC20 token,
    FixedPoint.Unsigned memory pfcAmount,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amount) {
    FixedPoint.Unsigned memory balance =
      FixedPoint.Unsigned(token.balanceOf(address(this)));
    if (address(token) == address(feePayerData.collateralCurrency)) {
      amount = balance.sub(pfcAmount);
    } else {
      amount = balance;
    }
    token.safeTransfer(
      positionManagerData.excessTokenBeneficiary,
      amount.rawValue
    );
  }

  function requestOraclePrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    uint256 requestedTime,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external {
    feePayerData._getOracle().requestPrice(
      positionManagerData.priceIdentifier,
      requestedTime
    );
  }

  function reduceSponsorPosition(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory tokensToRemove,
    FixedPoint.Unsigned memory collateralToRemove,
    FixedPoint.Unsigned memory withdrawalAmountToRemove,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    address sponsor
  ) external {
    if (
      tokensToRemove.isEqual(positionData.tokensOutstanding) &&
      positionData
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isEqual(collateralToRemove)
    ) {
      positionData._deleteSponsorPosition(
        globalPositionData,
        feePayerData,
        sponsor
      );
      return;
    }

    positionData._decrementCollateralBalances(
      globalPositionData,
      collateralToRemove,
      feePayerData
    );

    positionData.tokensOutstanding = positionData.tokensOutstanding.sub(
      tokensToRemove
    );
    require(
      positionData.tokensOutstanding.isGreaterThanOrEqual(
        positionManagerData.minSponsorTokens
      ),
      'Below minimum sponsor position'
    );

    positionData.withdrawalRequestAmount = positionData
      .withdrawalRequestAmount
      .sub(withdrawalAmountToRemove);

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToRemove);
  }

  function getOraclePrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    uint256 requestedTime,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external view returns (FixedPoint.Unsigned memory price) {
    return _getOraclePrice(positionManagerData, requestedTime, feePayerData);
  }

  function decimalsScalingFactor(
    FixedPoint.Unsigned memory oraclePrice,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external view returns (FixedPoint.Unsigned memory scaledPrice) {
    return _decimalsScalingFactor(oraclePrice, feePayerData);
  }

  function _incrementCollateralBalances(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerPoolParty.FeePayerData memory feePayerData
  ) internal returns (FixedPoint.Unsigned memory) {
    positionData.rawCollateral.addCollateral(
      collateralAmount,
      feePayerData.cumulativeFeeMultiplier
    );
    return
      globalPositionData.rawTotalPositionCollateral.addCollateral(
        collateralAmount,
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _decrementCollateralBalances(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) internal returns (FixedPoint.Unsigned memory) {
    positionData.rawCollateral.removeCollateral(
      collateralAmount,
      feePayerData.cumulativeFeeMultiplier
    );
    return
      globalPositionData.rawTotalPositionCollateral.removeCollateral(
        collateralAmount,
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _decrementCollateralBalancesCheckGCR(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) internal returns (FixedPoint.Unsigned memory) {
    positionData.rawCollateral.removeCollateral(
      collateralAmount,
      feePayerData.cumulativeFeeMultiplier
    );
    require(
      _checkPositionCollateralization(
        positionData,
        globalPositionData,
        feePayerData
      ),
      'CR below GCR'
    );
    return
      globalPositionData.rawTotalPositionCollateral.removeCollateral(
        collateralAmount,
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _checkPositionCollateralization(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) internal view returns (bool) {
    return
      _checkCollateralization(
        globalPositionData,
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        positionData.tokensOutstanding,
        feePayerData
      );
  }

  function _checkCollateralization(
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory numTokens,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) internal view returns (bool) {
    FixedPoint.Unsigned memory global =
      _getCollateralizationRatio(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        globalPositionData.totalTokensOutstanding
      );
    FixedPoint.Unsigned memory thisChange =
      _getCollateralizationRatio(collateral, numTokens);
    return !global.isGreaterThan(thisChange);
  }

  function _getCollateralizationRatio(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory numTokens
  ) internal pure returns (FixedPoint.Unsigned memory ratio) {
    return
      numTokens.isLessThanOrEqual(0)
        ? FixedPoint.fromUnscaledUint(0)
        : collateral.div(numTokens);
  }

  function _resetWithdrawalRequest(
    PerpetualPositionManagerPoolParty.PositionData storage positionData
  ) internal {
    positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
    positionData.withdrawalRequestPassTimestamp = 0;
  }

  function _deleteSponsorPosition(
    PerpetualPositionManagerPoolParty.PositionData storage positionToLiquidate,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    address sponsor
  ) internal returns (FixedPoint.Unsigned memory) {
    FixedPoint.Unsigned memory startingGlobalCollateral =
      globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );

    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(positionToLiquidate.rawCollateral);
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(positionToLiquidate.tokensOutstanding);

    PerpetualPositionManagerPoolParty(address(this)).deleteSponsorPosition(
      sponsor
    );

    emit EndedSponsorPosition(sponsor);

    return
      startingGlobalCollateral.sub(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );
  }

  function _getOracleEmergencyShutdownPrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory) {
    return
      positionManagerData._getOraclePrice(
        positionManagerData.emergencyShutdownTimestamp,
        feePayerData
      );
  }

  function _getOraclePrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    uint256 requestedTime,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory price) {
    OracleInterface oracle = feePayerData._getOracle();
    require(
      oracle.hasPrice(positionManagerData.priceIdentifier, requestedTime),
      'Unresolved oracle price'
    );
    int256 oraclePrice =
      oracle.getPrice(positionManagerData.priceIdentifier, requestedTime);

    if (oraclePrice < 0) {
      oraclePrice = 0;
    }
    return FixedPoint.Unsigned(uint256(oraclePrice));
  }

  function _getOracle(FeePayerPoolParty.FeePayerData storage feePayerData)
    internal
    view
    returns (OracleInterface)
  {
    return
      OracleInterface(
        feePayerData.finder.getImplementationAddress(OracleInterfaces.Oracle)
      );
  }

  function _decimalsScalingFactor(
    FixedPoint.Unsigned memory oraclePrice,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory scaledPrice) {
    uint8 collateralDecimalsNumber =
      IERC20Standard(address(feePayerData.collateralCurrency)).decimals();
    scaledPrice = oraclePrice.div(
      (10**(uint256(18)).sub(collateralDecimalsNumber))
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';
import './PerpetualPositionManagerPoolPartyLib.sol';
import './PerpetualLiquidatablePoolParty.sol';
import '../common/FeePayerPoolPartyLib.sol';
import '../../common/interfaces/MintableBurnableIERC20.sol';

library PerpetualLiquidatablePoolPartyLib {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using FixedPoint for FixedPoint.Unsigned;
  using PerpetualPositionManagerPoolPartyLib for PerpetualPositionManagerPoolParty.PositionData;
  using FeePayerPoolPartyLib for FixedPoint.Unsigned;
  using PerpetualPositionManagerPoolPartyLib for PerpetualPositionManagerPoolParty.PositionManagerData;
  using PerpetualLiquidatablePoolPartyLib for PerpetualLiquidatablePoolParty.LiquidationData;
  using PerpetualPositionManagerPoolPartyLib for FixedPoint.Unsigned;

  struct CreateLiquidationParams {
    FixedPoint.Unsigned minCollateralPerToken;
    FixedPoint.Unsigned maxCollateralPerToken;
    FixedPoint.Unsigned maxTokensToLiquidate;
    uint256 actualTime;
    uint256 deadline;
    FixedPoint.Unsigned finalFee;
    address sponsor;
  }

  struct CreateLiquidationCollateral {
    FixedPoint.Unsigned startCollateral;
    FixedPoint.Unsigned startCollateralNetOfWithdrawal;
    FixedPoint.Unsigned tokensLiquidated;
    FixedPoint.Unsigned finalFeeBond;
    address sponsor;
  }

  struct CreateLiquidationReturnParams {
    uint256 liquidationId;
    FixedPoint.Unsigned lockedCollateral;
    FixedPoint.Unsigned liquidatedCollateral;
    FixedPoint.Unsigned tokensLiquidated;
    FixedPoint.Unsigned finalFeeBond;
  }

  struct SettleParams {
    FixedPoint.Unsigned feeAttenuation;
    FixedPoint.Unsigned settlementPrice;
    FixedPoint.Unsigned tokenRedemptionValue;
    FixedPoint.Unsigned collateral;
    FixedPoint.Unsigned disputerDisputeReward;
    FixedPoint.Unsigned sponsorDisputeReward;
    FixedPoint.Unsigned disputeBondAmount;
    FixedPoint.Unsigned finalFee;
    FixedPoint.Unsigned withdrawalAmount;
  }

  event LiquidationCreated(
    address indexed sponsor,
    address indexed liquidator,
    uint256 indexed liquidationId,
    uint256 tokensOutstanding,
    uint256 lockedCollateral,
    uint256 liquidatedCollateral,
    uint256 liquidationTime
  );
  event LiquidationDisputed(
    address indexed sponsor,
    address indexed liquidator,
    address indexed disputer,
    uint256 liquidationId,
    uint256 disputeBondAmount
  );

  event DisputeSettled(
    address indexed caller,
    address indexed sponsor,
    address indexed liquidator,
    address disputer,
    uint256 liquidationId,
    bool disputeSucceeded
  );

  event LiquidationWithdrawn(
    address indexed caller,
    uint256 paidToLiquidator,
    uint256 paidToDisputer,
    uint256 paidToSponsor,
    PerpetualLiquidatablePoolParty.Status indexed liquidationStatus,
    uint256 settlementPrice
  );

  function createLiquidation(
    PerpetualPositionManagerPoolParty.PositionData storage positionToLiquidate,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    PerpetualLiquidatablePoolParty.LiquidatableData storage liquidatableData,
    PerpetualLiquidatablePoolParty.LiquidationData[] storage liquidations,
    CreateLiquidationParams memory params,
    FeePayerPoolParty.FeePayerData storage feePayerData
  ) external returns (CreateLiquidationReturnParams memory returnValues) {
    FixedPoint.Unsigned memory startCollateral;
    FixedPoint.Unsigned memory startCollateralNetOfWithdrawal;

    (
      startCollateral,
      startCollateralNetOfWithdrawal,
      returnValues.tokensLiquidated
    ) = calculateNetLiquidation(positionToLiquidate, params, feePayerData);

    {
      FixedPoint.Unsigned memory startTokens =
        positionToLiquidate.tokensOutstanding;

      require(
        params.maxCollateralPerToken.mul(startTokens).isGreaterThanOrEqual(
          startCollateralNetOfWithdrawal
        ),
        'CR is more than max liq. price'
      );

      require(
        params.minCollateralPerToken.mul(startTokens).isLessThanOrEqual(
          startCollateralNetOfWithdrawal
        ),
        'CR is less than min liq. price'
      );
    }
    {
      returnValues.finalFeeBond = params.finalFee;

      CreateLiquidationCollateral memory liquidationCollateral =
        CreateLiquidationCollateral(
          startCollateral,
          startCollateralNetOfWithdrawal,
          returnValues.tokensLiquidated,
          returnValues.finalFeeBond,
          params.sponsor
        );

      (
        returnValues.lockedCollateral,
        returnValues.liquidatedCollateral
      ) = liquidateCollateral(
        positionToLiquidate,
        globalPositionData,
        positionManagerData,
        liquidatableData,
        feePayerData,
        liquidationCollateral
      );

      returnValues.liquidationId = liquidations.length;
      liquidations.push(
        PerpetualLiquidatablePoolParty.LiquidationData({
          sponsor: params.sponsor,
          liquidator: msg.sender,
          state: PerpetualLiquidatablePoolParty.Status.PreDispute,
          liquidationTime: params.actualTime,
          tokensOutstanding: returnValues.tokensLiquidated,
          lockedCollateral: returnValues.lockedCollateral,
          liquidatedCollateral: returnValues.liquidatedCollateral,
          rawUnitCollateral: FixedPoint
            .fromUnscaledUint(1)
            .convertToRawCollateral(feePayerData.cumulativeFeeMultiplier),
          disputer: address(0),
          settlementPrice: FixedPoint.fromUnscaledUint(0),
          finalFee: returnValues.finalFeeBond
        })
      );
    }

    {
      FixedPoint.Unsigned memory griefingThreshold =
        positionManagerData.minSponsorTokens;
      if (
        positionToLiquidate.withdrawalRequestPassTimestamp > 0 &&
        positionToLiquidate.withdrawalRequestPassTimestamp >
        params.actualTime &&
        returnValues.tokensLiquidated.isGreaterThanOrEqual(griefingThreshold)
      ) {
        positionToLiquidate.withdrawalRequestPassTimestamp = params
          .actualTime
          .add(positionManagerData.withdrawalLiveness);
      }
    }
    emit LiquidationCreated(
      params.sponsor,
      msg.sender,
      returnValues.liquidationId,
      returnValues.tokensLiquidated.rawValue,
      returnValues.lockedCollateral.rawValue,
      returnValues.liquidatedCollateral.rawValue,
      params.actualTime
    );

    burnAndLiquidateFee(
      positionManagerData,
      feePayerData,
      returnValues.tokensLiquidated,
      returnValues.finalFeeBond
    );
  }

  function dispute(
    PerpetualLiquidatablePoolParty.LiquidationData storage disputedLiquidation,
    PerpetualLiquidatablePoolParty.LiquidatableData storage liquidatableData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    uint256 liquidationId,
    address sponsor
  ) external returns (FixedPoint.Unsigned memory totalPaid) {
    FixedPoint.Unsigned memory disputeBondAmount =
      disputedLiquidation
        .lockedCollateral
        .mul(liquidatableData.disputeBondPct)
        .mul(
        disputedLiquidation.rawUnitCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );
    liquidatableData.rawLiquidationCollateral.addCollateral(
      disputeBondAmount,
      feePayerData.cumulativeFeeMultiplier
    );

    disputedLiquidation.state = PerpetualLiquidatablePoolParty
      .Status
      .PendingDispute;
    disputedLiquidation.disputer = msg.sender;

    positionManagerData.requestOraclePrice(
      disputedLiquidation.liquidationTime,
      feePayerData
    );

    emit LiquidationDisputed(
      sponsor,
      disputedLiquidation.liquidator,
      msg.sender,
      liquidationId,
      disputeBondAmount.rawValue
    );

    totalPaid = disputeBondAmount.add(disputedLiquidation.finalFee);

    FeePayerPoolParty(address(this)).payFinalFees(
      msg.sender,
      disputedLiquidation.finalFee
    );

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      disputeBondAmount.rawValue
    );
  }

  function withdrawLiquidation(
    PerpetualLiquidatablePoolParty.LiquidationData storage liquidation,
    PerpetualLiquidatablePoolParty.LiquidatableData storage liquidatableData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    uint256 liquidationId,
    address sponsor
  )
    external
    returns (PerpetualLiquidatablePoolParty.RewardsData memory rewards)
  {
    liquidation._settle(
      positionManagerData,
      liquidatableData,
      feePayerData,
      liquidationId,
      sponsor
    );

    SettleParams memory settleParams;

    settleParams.feeAttenuation = liquidation
      .rawUnitCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
    settleParams.settlementPrice = liquidation.settlementPrice;
    settleParams.tokenRedemptionValue = liquidation
      .tokensOutstanding
      .mul(settleParams.settlementPrice)
      .mul(settleParams.feeAttenuation);
    settleParams.collateral = liquidation.lockedCollateral.mul(
      settleParams.feeAttenuation
    );
    settleParams.disputerDisputeReward = liquidatableData
      .disputerDisputeRewardPct
      .mul(settleParams.tokenRedemptionValue);
    settleParams.sponsorDisputeReward = liquidatableData
      .sponsorDisputeRewardPct
      .mul(settleParams.tokenRedemptionValue);
    settleParams.disputeBondAmount = settleParams.collateral.mul(
      liquidatableData.disputeBondPct
    );
    settleParams.finalFee = liquidation.finalFee.mul(
      settleParams.feeAttenuation
    );

    if (
      liquidation.state ==
      PerpetualLiquidatablePoolParty.Status.DisputeSucceeded
    ) {
      rewards.payToDisputer = settleParams
        .disputerDisputeReward
        .add(settleParams.disputeBondAmount)
        .add(settleParams.finalFee);

      rewards.payToSponsor = settleParams.sponsorDisputeReward.add(
        settleParams.collateral.sub(settleParams.tokenRedemptionValue)
      );

      rewards.payToLiquidator = settleParams
        .tokenRedemptionValue
        .sub(settleParams.sponsorDisputeReward)
        .sub(settleParams.disputerDisputeReward);

      rewards.paidToLiquidator = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToLiquidator,
        feePayerData.cumulativeFeeMultiplier
      );
      rewards.paidToSponsor = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToSponsor,
        feePayerData.cumulativeFeeMultiplier
      );
      rewards.paidToDisputer = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToDisputer,
        feePayerData.cumulativeFeeMultiplier
      );

      feePayerData.collateralCurrency.safeTransfer(
        liquidation.disputer,
        rewards.paidToDisputer.rawValue
      );
      feePayerData.collateralCurrency.safeTransfer(
        liquidation.liquidator,
        rewards.paidToLiquidator.rawValue
      );
      feePayerData.collateralCurrency.safeTransfer(
        liquidation.sponsor,
        rewards.paidToSponsor.rawValue
      );
    } else if (
      liquidation.state == PerpetualLiquidatablePoolParty.Status.DisputeFailed
    ) {
      rewards.payToLiquidator = settleParams
        .collateral
        .add(settleParams.disputeBondAmount)
        .add(settleParams.finalFee);

      rewards.paidToLiquidator = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToLiquidator,
        feePayerData.cumulativeFeeMultiplier
      );

      feePayerData.collateralCurrency.safeTransfer(
        liquidation.liquidator,
        rewards.paidToLiquidator.rawValue
      );
    } else if (
      liquidation.state == PerpetualLiquidatablePoolParty.Status.PreDispute
    ) {
      rewards.payToLiquidator = settleParams.collateral.add(
        settleParams.finalFee
      );

      rewards.paidToLiquidator = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToLiquidator,
        feePayerData.cumulativeFeeMultiplier
      );

      feePayerData.collateralCurrency.safeTransfer(
        liquidation.liquidator,
        rewards.paidToLiquidator.rawValue
      );
    }

    emit LiquidationWithdrawn(
      msg.sender,
      rewards.paidToLiquidator.rawValue,
      rewards.paidToDisputer.rawValue,
      rewards.paidToSponsor.rawValue,
      liquidation.state,
      settleParams.settlementPrice.rawValue
    );

    PerpetualLiquidatablePoolParty(address(this)).deleteLiquidation(
      liquidationId,
      sponsor
    );

    return rewards;
  }

  function calculateNetLiquidation(
    PerpetualPositionManagerPoolParty.PositionData storage positionToLiquidate,
    CreateLiquidationParams memory params,
    FeePayerPoolParty.FeePayerData storage feePayerData
  )
    internal
    view
    returns (
      FixedPoint.Unsigned memory startCollateral,
      FixedPoint.Unsigned memory startCollateralNetOfWithdrawal,
      FixedPoint.Unsigned memory tokensLiquidated
    )
  {
    tokensLiquidated = FixedPoint.min(
      params.maxTokensToLiquidate,
      positionToLiquidate.tokensOutstanding
    );
    require(tokensLiquidated.isGreaterThan(0), 'Liquidating 0 tokens');

    require(params.actualTime <= params.deadline, 'Mined after deadline');

    startCollateral = positionToLiquidate
      .rawCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
    startCollateralNetOfWithdrawal = FixedPoint.fromUnscaledUint(0);

    if (
      positionToLiquidate.withdrawalRequestAmount.isLessThanOrEqual(
        startCollateral
      )
    ) {
      startCollateralNetOfWithdrawal = startCollateral.sub(
        positionToLiquidate.withdrawalRequestAmount
      );
    }
  }

  function liquidateCollateral(
    PerpetualPositionManagerPoolParty.PositionData storage positionToLiquidate,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    PerpetualLiquidatablePoolParty.LiquidatableData storage liquidatableData,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    CreateLiquidationCollateral memory liquidationCollateralParams
  )
    internal
    returns (
      FixedPoint.Unsigned memory lockedCollateral,
      FixedPoint.Unsigned memory liquidatedCollateral
    )
  {
    {
      FixedPoint.Unsigned memory ratio =
        liquidationCollateralParams.tokensLiquidated.div(
          positionToLiquidate.tokensOutstanding
        );

      lockedCollateral = liquidationCollateralParams.startCollateral.mul(ratio);

      liquidatedCollateral = liquidationCollateralParams
        .startCollateralNetOfWithdrawal
        .mul(ratio);

      FixedPoint.Unsigned memory withdrawalAmountToRemove =
        positionToLiquidate.withdrawalRequestAmount.mul(ratio);

      positionToLiquidate.reduceSponsorPosition(
        globalPositionData,
        positionManagerData,
        liquidationCollateralParams.tokensLiquidated,
        lockedCollateral,
        withdrawalAmountToRemove,
        feePayerData,
        liquidationCollateralParams.sponsor
      );
    }

    liquidatableData.rawLiquidationCollateral.addCollateral(
      lockedCollateral.add(liquidationCollateralParams.finalFeeBond),
      feePayerData.cumulativeFeeMultiplier
    );
  }

  function burnAndLiquidateFee(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    FixedPoint.Unsigned memory tokensLiquidated,
    FixedPoint.Unsigned memory finalFeeBond
  ) internal {
    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      tokensLiquidated.rawValue
    );
    positionManagerData.tokenCurrency.burn(tokensLiquidated.rawValue);

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      finalFeeBond.rawValue
    );
  }

  function _settle(
    PerpetualLiquidatablePoolParty.LiquidationData storage liquidation,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    PerpetualLiquidatablePoolParty.LiquidatableData storage liquidatableData,
    FeePayerPoolParty.FeePayerData storage feePayerData,
    uint256 liquidationId,
    address sponsor
  ) internal {
    if (
      liquidation.state != PerpetualLiquidatablePoolParty.Status.PendingDispute
    ) {
      return;
    }

    FixedPoint.Unsigned memory oraclePrice =
      positionManagerData.getOraclePrice(
        liquidation.liquidationTime,
        feePayerData
      );

    liquidation.settlementPrice = oraclePrice.decimalsScalingFactor(
      feePayerData
    );

    FixedPoint.Unsigned memory tokenRedemptionValue =
      liquidation.tokensOutstanding.mul(liquidation.settlementPrice);

    FixedPoint.Unsigned memory requiredCollateral =
      tokenRedemptionValue.mul(liquidatableData.collateralRequirement);

    bool disputeSucceeded =
      liquidation.liquidatedCollateral.isGreaterThanOrEqual(requiredCollateral);
    liquidation.state = disputeSucceeded
      ? PerpetualLiquidatablePoolParty.Status.DisputeSucceeded
      : PerpetualLiquidatablePoolParty.Status.DisputeFailed;

    emit DisputeSettled(
      msg.sender,
      sponsor,
      liquidation.liquidator,
      liquidation.disputer,
      liquidationId,
      disputeSucceeded
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../common/implementation/Lockable.sol';
import '../../common/implementation/FixedPoint.sol';
import './FeePayerPoolPartyLib.sol';
import '../../common/implementation/Testable.sol';

import '../../oracle/interfaces/StoreInterface.sol';
import '../../oracle/interfaces/FinderInterface.sol';
import '../../oracle/interfaces/AdministrateeInterface.sol';
import '../../oracle/implementation/Constants.sol';

abstract contract FeePayerPoolParty is
  AdministrateeInterface,
  Testable,
  Lockable
{
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPoolPartyLib for FixedPoint.Unsigned;
  using FeePayerPoolPartyLib for FeePayerData;
  using SafeERC20 for IERC20;

  struct FeePayerData {
    IERC20 collateralCurrency;
    FinderInterface finder;
    uint256 lastPaymentTime;
    FixedPoint.Unsigned cumulativeFeeMultiplier;
  }

  FeePayerData public feePayerData;

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  modifier fees {
    payRegularFees();
    _;
  }
  modifier onlyThisContract {
    require(msg.sender == address(this), 'Caller is not this contract');
    _;
  }

  constructor(
    address _collateralAddress,
    address _finderAddress,
    address _timerAddress
  ) public Testable(_timerAddress) {
    feePayerData.collateralCurrency = IERC20(_collateralAddress);
    feePayerData.finder = FinderInterface(_finderAddress);
    feePayerData.lastPaymentTime = getCurrentTime();
    feePayerData.cumulativeFeeMultiplier = FixedPoint.fromUnscaledUint(1);
  }

  function payRegularFees()
    public
    nonReentrant()
    returns (FixedPoint.Unsigned memory totalPaid)
  {
    StoreInterface store = _getStore();
    uint256 time = getCurrentTime();
    FixedPoint.Unsigned memory collateralPool = _pfc();
    totalPaid = feePayerData.payRegularFees(store, time, collateralPool);
    return totalPaid;
  }

  function payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    external
    onlyThisContract
  {
    _payFinalFees(payer, amount);
  }

  function pfc()
    public
    view
    override
    nonReentrantView()
    returns (FixedPoint.Unsigned memory)
  {
    return _pfc();
  }

  function collateralCurrency()
    public
    view
    nonReentrantView()
    returns (IERC20)
  {
    return feePayerData.collateralCurrency;
  }

  function _payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    internal
  {
    StoreInterface store = _getStore();
    feePayerData.payFinalFees(store, payer, amount);
  }

  function _pfc() internal view virtual returns (FixedPoint.Unsigned memory);

  function _getStore() internal view returns (StoreInterface) {
    return
      StoreInterface(
        feePayerData.finder.getImplementationAddress(OracleInterfaces.Store)
      );
  }

  function _computeFinalFees()
    internal
    view
    returns (FixedPoint.Unsigned memory finalFees)
  {
    StoreInterface store = _getStore();
    return store.computeFinalFee(address(feePayerData.collateralCurrency));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Standard is IERC20 {
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';
import './FeePayerPoolParty.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../../oracle/interfaces/StoreInterface.sol';

library FeePayerPoolPartyLib {
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPoolPartyLib for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  function payRegularFees(
    FeePayerPoolParty.FeePayerData storage feePayerData,
    StoreInterface store,
    uint256 time,
    FixedPoint.Unsigned memory collateralPool
  ) external returns (FixedPoint.Unsigned memory totalPaid) {
    if (collateralPool.isEqual(0)) {
      feePayerData.lastPaymentTime = time;
      return totalPaid;
    }

    if (feePayerData.lastPaymentTime == time) {
      return totalPaid;
    }

    FixedPoint.Unsigned memory regularFee;
    FixedPoint.Unsigned memory latePenalty;

    (regularFee, latePenalty) = store.computeRegularFee(
      feePayerData.lastPaymentTime,
      time,
      collateralPool
    );
    feePayerData.lastPaymentTime = time;

    totalPaid = regularFee.add(latePenalty);
    if (totalPaid.isEqual(0)) {
      return totalPaid;
    }

    if (totalPaid.isGreaterThan(collateralPool)) {
      FixedPoint.Unsigned memory deficit = totalPaid.sub(collateralPool);
      FixedPoint.Unsigned memory latePenaltyReduction =
        FixedPoint.min(latePenalty, deficit);
      latePenalty = latePenalty.sub(latePenaltyReduction);
      deficit = deficit.sub(latePenaltyReduction);
      regularFee = regularFee.sub(FixedPoint.min(regularFee, deficit));
      totalPaid = collateralPool;
    }

    emit RegularFeesPaid(regularFee.rawValue, latePenalty.rawValue);

    feePayerData.cumulativeFeeMultiplier._adjustCumulativeFeeMultiplier(
      totalPaid,
      collateralPool
    );

    if (regularFee.isGreaterThan(0)) {
      feePayerData.collateralCurrency.safeIncreaseAllowance(
        address(store),
        regularFee.rawValue
      );
      store.payOracleFeesErc20(
        address(feePayerData.collateralCurrency),
        regularFee
      );
    }

    if (latePenalty.isGreaterThan(0)) {
      feePayerData.collateralCurrency.safeTransfer(
        msg.sender,
        latePenalty.rawValue
      );
    }
    return totalPaid;
  }

  function payFinalFees(
    FeePayerPoolParty.FeePayerData storage feePayerData,
    StoreInterface store,
    address payer,
    FixedPoint.Unsigned memory amount
  ) external {
    if (amount.isEqual(0)) {
      return;
    }

    feePayerData.collateralCurrency.safeTransferFrom(
      payer,
      address(this),
      amount.rawValue
    );

    emit FinalFeesPaid(amount.rawValue);

    feePayerData.collateralCurrency.safeIncreaseAllowance(
      address(store),
      amount.rawValue
    );
    store.payOracleFeesErc20(address(feePayerData.collateralCurrency), amount);
  }

  function getFeeAdjustedCollateral(
    FixedPoint.Unsigned memory rawCollateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external pure returns (FixedPoint.Unsigned memory collateral) {
    return rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
  }

  function convertToRawCollateral(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external pure returns (FixedPoint.Unsigned memory rawCollateral) {
    return collateral._convertToRawCollateral(cumulativeFeeMultiplier);
  }

  function removeCollateral(
    FixedPoint.Unsigned storage rawCollateral,
    FixedPoint.Unsigned memory collateralToRemove,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external returns (FixedPoint.Unsigned memory removedCollateral) {
    FixedPoint.Unsigned memory initialBalance =
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
    FixedPoint.Unsigned memory adjustedCollateral =
      collateralToRemove._convertToRawCollateral(cumulativeFeeMultiplier);
    rawCollateral.rawValue = rawCollateral.sub(adjustedCollateral).rawValue;
    removedCollateral = initialBalance.sub(
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier)
    );
  }

  function addCollateral(
    FixedPoint.Unsigned storage rawCollateral,
    FixedPoint.Unsigned memory collateralToAdd,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external returns (FixedPoint.Unsigned memory addedCollateral) {
    FixedPoint.Unsigned memory initialBalance =
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
    FixedPoint.Unsigned memory adjustedCollateral =
      collateralToAdd._convertToRawCollateral(cumulativeFeeMultiplier);
    rawCollateral.rawValue = rawCollateral.add(adjustedCollateral).rawValue;
    addedCollateral = rawCollateral
      ._getFeeAdjustedCollateral(cumulativeFeeMultiplier)
      .sub(initialBalance);
  }

  function _adjustCumulativeFeeMultiplier(
    FixedPoint.Unsigned storage cumulativeFeeMultiplier,
    FixedPoint.Unsigned memory amount,
    FixedPoint.Unsigned memory currentPfc
  ) internal {
    FixedPoint.Unsigned memory effectiveFee = amount.divCeil(currentPfc);
    cumulativeFeeMultiplier.rawValue = cumulativeFeeMultiplier
      .mul(FixedPoint.fromUnscaledUint(1).sub(effectiveFee))
      .rawValue;
  }

  function _getFeeAdjustedCollateral(
    FixedPoint.Unsigned memory rawCollateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) internal pure returns (FixedPoint.Unsigned memory collateral) {
    return rawCollateral.mul(cumulativeFeeMultiplier);
  }

  function _convertToRawCollateral(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) internal pure returns (FixedPoint.Unsigned memory rawCollateral) {
    return collateral.div(cumulativeFeeMultiplier);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumFactoryVersioning
} from '../../versioning/interfaces/IFactoryVersioning.sol';
import {
  MintableBurnableIERC20
} from '../../../@jarvis-network/uma-core/contracts/common/interfaces/MintableBurnableIERC20.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  MintableBurnableTokenFactory
} from '../../../@jarvis-network/uma-core/contracts/financial-templates/common/MintableBurnableTokenFactory.sol';

contract SynthereumSyntheticTokenFactory is MintableBurnableTokenFactory {
  address public synthereumFinder;

  uint8 public derivativeVersion;

  constructor(address _synthereumFinder, uint8 _derivativeVersion) public {
    synthereumFinder = _synthereumFinder;
    derivativeVersion = _derivativeVersion;
  }

  function createToken(
    string calldata tokenName,
    string calldata tokenSymbol,
    uint8 tokenDecimals
  ) public override returns (MintableBurnableIERC20 newToken) {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        ISynthereumFinder(synthereumFinder).getImplementationAddress(
          SynthereumInterfaces.FactoryVersioning
        )
      );
    require(
      msg.sender ==
        factoryVersioning.getDerivativeFactoryVersion(derivativeVersion),
      'Sender must be a Derivative Factory'
    );
    newToken = super.createToken(tokenName, tokenSymbol, tokenDecimals);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumPoolRegistry
} from '../../versioning/interfaces/IPoolRegistry.sol';
import {
  ISynthereumPoolDeployment
} from '../../synthereum-pool/common/interfaces/IPoolDeployment.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  ISynthereumChainlinkPriceFeed
} from './interfaces/IChainlinkPriceFeed.sol';
import {
  AggregatorV3Interface
} from '../../../@chainlink/contracts/v0.6/interfaces/AggregatorV3Interface.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  AccessControl
} from '../../../@openzeppelin/contracts/access/AccessControl.sol';

contract SynthereumChainlinkPriceFeed is
  ISynthereumChainlinkPriceFeed,
  AccessControl
{
  using SafeMath for uint256;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // State variables
  //----------------------------------------

  ISynthereumFinder public synthereumFinder;
  mapping(bytes32 => AggregatorV3Interface) private aggregators;

  //----------------------------------------
  // Events
  //----------------------------------------

  event SetAggregator(bytes32 indexed priceIdentifier, address aggregator);

  event RemoveAggregator(bytes32 indexed priceIdentifier);

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumChainlinkPriceFeed contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) public {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyPools() {
    if (msg.sender != tx.origin) {
      ISynthereumPoolRegistry poolRegister =
        ISynthereumPoolRegistry(
          synthereumFinder.getImplementationAddress(
            SynthereumInterfaces.PoolRegistry
          )
        );
      ISynthereumPoolDeployment pool = ISynthereumPoolDeployment(msg.sender);
      require(
        poolRegister.isPoolDeployed(
          pool.syntheticTokenSymbol(),
          pool.collateralToken(),
          pool.version(),
          msg.sender
        ),
        'Pool not registred'
      );
    }
    _;
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Set the address of aggregator associated to a pricee identifier
   * @param priceIdentifier Price feed identifier
   * @param aggregator Address of chainlink proxy aggregator
   */
  function setAggregator(
    bytes32 priceIdentifier,
    AggregatorV3Interface aggregator
  ) external override onlyMaintainer {
    require(
      address(aggregators[priceIdentifier]) != address(aggregator),
      'Aggregator address is the same'
    );
    aggregators[priceIdentifier] = aggregator;
    emit SetAggregator(priceIdentifier, address(aggregator));
  }

  /**
   * @notice Remove the address of aggregator associated to a price identifier
   * @param priceIdentifier Price feed identifier
   */
  function removeAggregator(bytes32 priceIdentifier)
    external
    override
    onlyMaintainer
  {
    require(
      address(aggregators[priceIdentifier]) != address(0),
      'Price identifier does not exist'
    );
    delete aggregators[priceIdentifier];
    emit RemoveAggregator(priceIdentifier);
  }

  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 priceIdentifier)
    external
    view
    override
    onlyPools()
    returns (uint256 price)
  {
    OracleData memory oracleData = _getOracleLatestRoundData(priceIdentifier);
    price = getScaledValue(oracleData.answer, oracleData.decimals);
  }

  /**
   * @notice Get last chainlink oracle data for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return oracleData Oracle data
   */
  function getOracleLatestData(bytes32 priceIdentifier)
    external
    view
    override
    onlyPools()
    returns (OracleData memory oracleData)
  {
    oracleData = _getOracleLatestRoundData(priceIdentifier);
  }

  /**
   * @notice Get chainlink oracle price in a given round for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return price Oracle price
   */
  function getRoundPrice(bytes32 priceIdentifier, uint80 _roundId)
    external
    view
    override
    onlyPools()
    returns (uint256 price)
  {
    OracleData memory oracleData =
      _getOracleRoundData(priceIdentifier, _roundId);
    price = getScaledValue(oracleData.answer, oracleData.decimals);
  }

  /**
   * @notice Get chainlink oracle data in a given round for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return oracleData Oracle data
   */
  function getOracleRoundData(bytes32 priceIdentifier, uint80 _roundId)
    external
    view
    override
    onlyPools()
    returns (OracleData memory oracleData)
  {
    oracleData = _getOracleRoundData(priceIdentifier, _roundId);
  }

  //----------------------------------------
  // Public view functions
  //----------------------------------------

  /**
   * @notice Returns the address of aggregator if exists, otherwise it reverts
   * @param priceIdentifier Price feed identifier
   * @return aggregator Aggregator associated with price identifier
   */
  function getAggregator(bytes32 priceIdentifier)
    public
    view
    override
    returns (AggregatorV3Interface aggregator)
  {
    aggregator = aggregators[priceIdentifier];
    require(
      address(aggregator) != address(0),
      'Price identifier does not exist'
    );
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------

  /**
   * @notice Get last chainlink oracle data for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return oracleData Oracle data
   */
  function _getOracleLatestRoundData(bytes32 priceIdentifier)
    internal
    view
    returns (OracleData memory oracleData)
  {
    AggregatorV3Interface aggregator = getAggregator(priceIdentifier);
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    oracleData = OracleData(
      roundId,
      convertPrice(answer),
      startedAt,
      updatedAt,
      answeredInRound,
      decimals
    );
  }

  /**
   * @notice Get chainlink oracle data in a given round for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return oracleData Oracle data
   */
  function _getOracleRoundData(bytes32 priceIdentifier, uint80 _roundId)
    internal
    view
    returns (OracleData memory oracleData)
  {
    AggregatorV3Interface aggregator = getAggregator(priceIdentifier);
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = aggregator.getRoundData(_roundId);
    uint8 decimals = aggregator.decimals();
    oracleData = OracleData(
      roundId,
      convertPrice(answer),
      startedAt,
      updatedAt,
      answeredInRound,
      decimals
    );
  }

  //----------------------------------------
  // Internal pure functions
  //----------------------------------------

  /**
   * @notice Covert the price from int to uint and it reverts if negative
   * @param uncovertedPrice Price before conversion
   * @return price Price after conversion
   */

  function convertPrice(int256 uncovertedPrice)
    internal
    pure
    returns (uint256 price)
  {
    require(uncovertedPrice > 0, 'Negative value');
    price = uint256(uncovertedPrice);
  }

  /**
   * @notice Covert the price to a integer with 18 decimals
   * @param unscaledPrice Price before conversion
   * @param decimals Number of decimals of unconverted price
   * @return price Price after conversion
   */

  function getScaledValue(uint256 unscaledPrice, uint8 decimals)
    internal
    pure
    returns (uint256 price)
  {
    price = unscaledPrice.mul(10**(uint256(18).sub(uint256(decimals))));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {
  EnumerableMap
} from '../../@openzeppelin/contracts/utils/EnumerableMap.sol';
import {
  AccessControl
} from '../../@openzeppelin/contracts/access/AccessControl.sol';

contract SynthereumFactoryVersioning is
  ISynthereumFactoryVersioning,
  AccessControl
{
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  struct Roles {
    address admin;
    address maintainer;
  }

  EnumerableMap.UintToAddressMap private _poolsFactory;

  EnumerableMap.UintToAddressMap private _derivativeFactory;

  event AddPoolFactory(uint8 indexed version, address poolFactory);

  event RemovePoolFactory(uint8 indexed version);

  event AddDerivativeFactory(uint8 indexed version, address derivativeFactory);

  event RemoveDerivativeFactory(uint8 indexed version);

  constructor(Roles memory _roles) public {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  function setPoolFactory(uint8 version, address poolFactory)
    external
    override
    onlyMaintainer
  {
    _poolsFactory.set(version, poolFactory);
    emit AddPoolFactory(version, poolFactory);
  }

  function removePoolFactory(uint8 version) external override onlyMaintainer {
    require(
      _poolsFactory.remove(version),
      'Version of the pool factory does not exist'
    );
    emit RemovePoolFactory(version);
  }

  function setDerivativeFactory(uint8 version, address derivativeFactory)
    external
    override
    onlyMaintainer
  {
    _derivativeFactory.set(version, derivativeFactory);
    emit AddDerivativeFactory(version, derivativeFactory);
  }

  function removeDerivativeFactory(uint8 version)
    external
    override
    onlyMaintainer
  {
    require(
      _derivativeFactory.remove(version),
      'Version of the pool factory does not exist'
    );
    emit RemoveDerivativeFactory(version);
  }

  function getPoolFactoryVersion(uint8 version)
    external
    view
    override
    returns (address poolFactory)
  {
    poolFactory = _poolsFactory.get(version);
  }

  function numberOfVerisonsOfPoolFactory()
    external
    view
    override
    returns (uint256 numberOfVersions)
  {
    numberOfVersions = _poolsFactory.length();
  }

  function getDerivativeFactoryVersion(uint8 version)
    external
    view
    override
    returns (address derivativeFactory)
  {
    derivativeFactory = _derivativeFactory.get(version);
  }

  function numberOfVerisonsOfDerivativeFactory()
    external
    view
    override
    returns (uint256 numberOfVersions)
  {
    numberOfVersions = _derivativeFactory.length();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library EnumerableMap {
  struct MapEntry {
    bytes32 _key;
    bytes32 _value;
  }

  struct Map {
    MapEntry[] _entries;
    mapping(bytes32 => uint256) _indexes;
  }

  function _set(
    Map storage map,
    bytes32 key,
    bytes32 value
  ) private returns (bool) {
    uint256 keyIndex = map._indexes[key];

    if (keyIndex == 0) {
      map._entries.push(MapEntry({_key: key, _value: value}));

      map._indexes[key] = map._entries.length;
      return true;
    } else {
      map._entries[keyIndex - 1]._value = value;
      return false;
    }
  }

  function _remove(Map storage map, bytes32 key) private returns (bool) {
    uint256 keyIndex = map._indexes[key];

    if (keyIndex != 0) {
      uint256 toDeleteIndex = keyIndex - 1;
      uint256 lastIndex = map._entries.length - 1;

      MapEntry storage lastEntry = map._entries[lastIndex];

      map._entries[toDeleteIndex] = lastEntry;

      map._indexes[lastEntry._key] = toDeleteIndex + 1;

      map._entries.pop();

      delete map._indexes[key];

      return true;
    } else {
      return false;
    }
  }

  function _contains(Map storage map, bytes32 key) private view returns (bool) {
    return map._indexes[key] != 0;
  }

  function _length(Map storage map) private view returns (uint256) {
    return map._entries.length;
  }

  function _at(Map storage map, uint256 index)
    private
    view
    returns (bytes32, bytes32)
  {
    require(map._entries.length > index, 'EnumerableMap: index out of bounds');

    MapEntry storage entry = map._entries[index];
    return (entry._key, entry._value);
  }

  function _get(Map storage map, bytes32 key) private view returns (bytes32) {
    return _get(map, key, 'EnumerableMap: nonexistent key');
  }

  function _get(
    Map storage map,
    bytes32 key,
    string memory errorMessage
  ) private view returns (bytes32) {
    uint256 keyIndex = map._indexes[key];
    require(keyIndex != 0, errorMessage);
    return map._entries[keyIndex - 1]._value;
  }

  struct UintToAddressMap {
    Map _inner;
  }

  function set(
    UintToAddressMap storage map,
    uint256 key,
    address value
  ) internal returns (bool) {
    return _set(map._inner, bytes32(key), bytes32(uint256(value)));
  }

  function remove(UintToAddressMap storage map, uint256 key)
    internal
    returns (bool)
  {
    return _remove(map._inner, bytes32(key));
  }

  function contains(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (bool)
  {
    return _contains(map._inner, bytes32(key));
  }

  function length(UintToAddressMap storage map)
    internal
    view
    returns (uint256)
  {
    return _length(map._inner);
  }

  function at(UintToAddressMap storage map, uint256 index)
    internal
    view
    returns (uint256, address)
  {
    (bytes32 key, bytes32 value) = _at(map._inner, index);
    return (uint256(key), address(uint256(value)));
  }

  function get(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (address)
  {
    return address(uint256(_get(map._inner, bytes32(key))));
  }

  function get(
    UintToAddressMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (address) {
    return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
  }
}