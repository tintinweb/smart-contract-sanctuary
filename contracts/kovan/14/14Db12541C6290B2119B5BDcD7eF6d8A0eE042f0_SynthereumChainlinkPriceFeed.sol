// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumPoolRegistry} from '../../core/interfaces/IPoolRegistry.sol';
import {
  ISynthereumPoolDeployment
} from '../../synthereum-pool/common/interfaces/IPoolDeployment.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
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

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {IRole} from '../../../base/interfaces/IRole.sol';
import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';

interface ISynthereumPoolDeployment {
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  function version() external view returns (uint8 poolVersion);

  function collateralToken() external view returns (IERC20 collateralCurrency);

  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  function syntheticTokenSymbol() external view returns (string memory symbol);

  function isDerivativeAdmitted(address derivative)
    external
    view
    returns (bool isAdmitted);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant SelfMintingController = 'SelfMintingController';
}

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

/**
 * @title Access role interface
 */
interface IRole {
  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   */
  function getRoleMember(bytes32 role, uint256 index)
    external
    view
    returns (address);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
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
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivativeMain} from './IDerivativeMain.sol';
import {IDerivativeDeployment} from './IDerivativeDeployment.sol';

interface IDerivative is IDerivativeDeployment, IDerivativeMain {}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  FinderInterface
} from '../../../../@jarvis-network/uma-core/contracts/oracle/interfaces/FinderInterface.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';

interface IDerivativeMain {
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

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IRole} from '../../../base/interfaces/IRole.sol';

interface IDerivativeDeployment is IRole {
  function collateralCurrency() external view returns (IERC20 collateral);

  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  function getAdminMembers() external view returns (address[] memory);

  function getPoolMembers() external view returns (address[] memory);
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

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
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