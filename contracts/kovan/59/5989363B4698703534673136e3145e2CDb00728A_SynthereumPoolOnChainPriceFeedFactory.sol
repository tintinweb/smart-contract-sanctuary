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
import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {IRole} from '../../base/interfaces/IRole.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumPoolRegistry} from '../../core/interfaces/IPoolRegistry.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
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
  using SynthereumPoolOnChainPriceFeedLib for IExtendedDerivative;
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
    IExtendedDerivative derivative
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
    IExtendedDerivative _derivative,
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
    IExtendedDerivative derivative
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
    IExtendedDerivative derivative
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
    IExtendedDerivative srcDerivative,
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
    ISynthereumPoolOnChainPriceFeed.SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (
      synthTokenRole == ISynthereumPoolOnChainPriceFeed.SynthTokenRoles.ADMIN
    ) {
      derivative.addSyntheticTokenAdmin(addressToAdd);
    } else {
      require(
        self.syntheticToken ==
          IExtendedDerivative(addressToAdd).tokenCurrency(),
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
    ISynthereumPoolGeneral destPool,
    IExtendedDerivative destDerivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
  function getDerivativeCollateral(IExtendedDerivative derivative)
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
  function getGlobalCollateralizationRatio(IExtendedDerivative derivative)
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
    IExtendedDerivative derivativeToCheck
  ) internal view {
    require(
      poolToCheck.isDerivativeAdmitted(address(derivativeToCheck)),
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
pragma experimental ABIEncoderV2;

import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IExtendedDerivative
} from '../../../derivative/common/interfaces/IExtendedDerivative.sol';
import {ISynthereumDeployer} from '../../../core/interfaces/IDeployer.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  ISynthereumPoolDeployment
} from '../../common/interfaces/IPoolDeployment.sol';
import {ISynthereumPoolGeneral} from '../../common/interfaces/IPoolGeneral.sol';

/**
 * @title Token Issuer Contract Interface
 */
interface ISynthereumPoolOnChainPriceFeed is ISynthereumPoolDeployment {
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
    IExtendedDerivative derivative;
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
    IExtendedDerivative derivative;
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
    IExtendedDerivative derivative;
    // Destination pool
    ISynthereumPoolGeneral destPool;
    // Derivative of destination pool
    IExtendedDerivative destDerivative;
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
  function addDerivative(IExtendedDerivative derivative) external;

  /**
   * @notice Remove a derivative controlled by this pool
   * @param derivative A perpetual derivative
   */
  function removeDerivative(IExtendedDerivative derivative) external;

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
   * @notice Called by a source TIC's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the PoolRegister contract
   * @param srcDerivative Derivative used by the source pool
   * @param derivative The derivative of the destination pool to use for mint
   * @param collateralAmount The amount of collateral to use from the source TIC
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    IExtendedDerivative srcDerivative,
    IExtendedDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

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
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external;

  /**
   * @notice Start a slow withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param derivative Derivative from which collateral withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   */
  function slowWithdrawRequest(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external;

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param derivative Derivative from which collateral withdrawal is requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(IExtendedDerivative derivative)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param derivative Derivative from which fast withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external returns (uint256 amountWithdrawn);

  /**
   * @notice Activate emergency shutdown on a derivative in order to liquidate the token holders in case of emergency
   * @param derivative Derivative on which the emergency shutdown is called
   */
  function emergencyShutdown(IExtendedDerivative derivative) external;

  /**
   * @notice Redeem tokens after contract emergency shutdown
   * @param derivative Derivative for which settlement is requested
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(IExtendedDerivative derivative)
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
    IExtendedDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external;

  /**
   * @notice This pool renounce a role in the derivative
   * @param derivative Derivative in which a role is renounced
   * @param derivativeRole Role to renounce
   */
  function renounceRoleInDerivative(
    IExtendedDerivative derivative,
    DerivativeRoles derivativeRole
  ) external;

  /**
   * @notice Add a role into synthetic token to another contract
   * @param derivative Derivative in which a role is added
   * @param synthTokenRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInSynthToken(
    IExtendedDerivative derivative,
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
  function getAllDerivatives()
    external
    view
    returns (IExtendedDerivative[] memory);

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

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);
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
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumPoolOnChainPriceFeed} from './IPoolOnChainPriceFeed.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
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
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivative} from './IDerivative.sol';
import {
  IExtendedDerivativeDeployment
} from './IExtendedDerivativeDeployment.sol';

interface IExtendedDerivative is IExtendedDerivativeDeployment, IDerivative {}

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
pragma solidity ^0.6.12;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ISynthereumPoolDeployment
} from '../../synthereum-pool/common/interfaces/IPoolDeployment.sol';
import {
  IDerivativeDeployment
} from '../../derivative/common/interfaces/IDerivativeDeployment.sol';
import {
  ISelfMintingDerivativeDeployment
} from '../../derivative/self-minting/common/interfaces/ISelfMintingDerivativeDeployment.sol';
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

  function deployOnlySelfMintingDerivative(
    uint8 selfMintingDerVersion,
    bytes calldata selfMintingDerParamsData
  ) external returns (ISelfMintingDerivativeDeployment selfMintingDerivative);
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
pragma experimental ABIEncoderV2;

import {IDerivativeMain} from './IDerivativeMain.sol';
import {IDerivativeDeployment} from './IDerivativeDeployment.sol';

interface IDerivative is IDerivativeDeployment, IDerivativeMain {}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IDerivativeDeployment} from './IDerivativeDeployment.sol';

interface IExtendedDerivativeDeployment is IDerivativeDeployment {
  /**
   * @notice Add admin to DEFAULT_ADMIN_ROLE
   * @param admin address of the Admin.
   */
  function addAdmin(address admin) external;

  /**
   * @notice Add TokenSponsor to POOL_ROLE
   * @param pool address of the TokenSponsor pool.
   */
  function addPool(address pool) external;

  /**
   * @notice Admin renounce to DEFAULT_ADMIN_ROLE
   */
  function renounceAdmin() external;

  /**
   * @notice TokenSponsor pool renounce to POOL_ROLE
   */
  function renouncePool() external;

  /**
   * @notice Add admin and pool to DEFAULT_ADMIN_ROLE and POOL_ROLE
   * @param adminAndPool address of admin/pool.
   */
  function addAdminAndPool(address adminAndPool) external;

  /**
   * @notice Admin and TokenSponsor pool renounce to DEFAULT_ADMIN_ROLE and POOL_ROLE
   */
  function renounceAdminAndPool() external;

  /**
   * @notice Add derivative as minter of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenMinter(address derivative) external;

  /**
   * @notice Add derivative as burner of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenBurner(address derivative) external;

  /**
   * @notice Add derivative as admin of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenAdmin(address derivative) external;

  /**
   * @notice Add derivative as admin, minter and burner of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenAdminAndMinterAndBurner(address derivative)
    external;

  /**
   * @notice This contract renounce to be minter of synthetic token
   */
  function renounceSyntheticTokenMinter() external;

  /**
   * @notice This contract renounce to be burner of synthetic token
   */
  function renounceSyntheticTokenBurner() external;

  /**
   * @notice This contract renounce to be admin of synthetic token
   */
  function renounceSyntheticTokenAdmin() external;

  /**
   * @notice This contract renounce to be admin, minter and burner of synthetic token
   */
  function renounceSyntheticTokenAdminAndMinterAndBurner() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
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
    ISynthereumFinder synthereumFinder;
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

interface IDerivativeDeployment {
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
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../../core/interfaces/IFinder.sol';

interface ISelfMintingDerivativeDeployment {
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  function collateralCurrency() external view returns (IERC20 collateral);

  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  function syntheticTokenSymbol() external view returns (string memory symbol);

  function version() external view returns (uint8 selfMintingversion);
}

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
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {
  ISynthereumPoolOnChainPriceFeedStorage
} from './interfaces/IPoolOnChainPriceFeedStorage.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumDeployer} from '../../core/interfaces/IDeployer.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
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
    IExtendedDerivative _derivative,
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
  function addDerivative(IExtendedDerivative derivative)
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
  function removeDerivative(IExtendedDerivative derivative)
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
    IExtendedDerivative srcDerivative,
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
  function slowWithdrawRequest(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external override onlyLiquidityProvider nonReentrant {
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
  function slowWithdrawPassedRequest(IExtendedDerivative derivative)
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
  function fastWithdraw(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  )
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
  function emergencyShutdown(IExtendedDerivative derivative)
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
  function settleEmergencyShutdown(IExtendedDerivative derivative)
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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
    returns (IExtendedDerivative[] memory)
  {
    EnumerableSet.AddressSet storage derivativesSet = poolStorage.derivatives;
    uint256 numberOfDerivatives = derivativesSet.length();
    IExtendedDerivative[] memory derivatives =
      new IExtendedDerivative[](numberOfDerivatives);
    for (uint256 j = 0; j < numberOfDerivatives; j++) {
      derivatives[j] = (IExtendedDerivative(derivativesSet.at(j)));
    }
    return derivatives;
  }

  /**
   * @notice Check if a derivative is in the withelist of this pool
   * @param derivative Perpetual derivative
   * @return isAdmitted Return true if in the withelist otherwise false
   */
  function isDerivativeAdmitted(address derivative)
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
import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {SynthereumPoolOnChainPriceFeed} from './PoolOnChainPriceFeed.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
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
    IExtendedDerivative derivative,
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

interface IDeploymentSignature {
  function deploymentSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
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
    IExtendedDerivative derivative,
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumPool} from './interfaces/IPool.sol';
import {SynthereumPool} from './Pool.sol';
import '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolCreator is Lockable {
  function createPool(
    IExtendedDerivative derivative,
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

import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IExtendedDerivative
} from '../../../derivative/common/interfaces/IExtendedDerivative.sol';
import {ISynthereumDeployer} from '../../../core/interfaces/IDeployer.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
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

  function addDerivative(IExtendedDerivative derivative) external;

  function removeDerivative(IExtendedDerivative derivative) external;

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
    IExtendedDerivative srcDerivative,
    IExtendedDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

  function withdrawFromPool(uint256 collateralAmount) external;

  function depositIntoDerivative(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external;

  function slowWithdrawRequest(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external;

  function slowWithdrawPassedRequest(IExtendedDerivative derivative)
    external
    returns (uint256 amountWithdrawn);

  function fastWithdraw(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external returns (uint256 amountWithdrawn);

  function emergencyShutdown(IExtendedDerivative derivative) external;

  function settleEmergencyShutdown(IExtendedDerivative derivative)
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
    IExtendedDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external;

  function renounceRoleInDerivative(
    IExtendedDerivative derivative,
    DerivativeRoles derivativeRole
  ) external;

  function addRoleInSynthToken(
    IExtendedDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external;

  function renounceRoleInSynthToken(
    IExtendedDerivative derivative,
    SynthTokenRoles synthTokenRole
  ) external;

  function setIsContractAllowed(bool isContractAllowed) external;

  function getAllDerivatives()
    external
    view
    returns (IExtendedDerivative[] memory);

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
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {ISynthereumPool} from './interfaces/IPool.sol';
import {ISynthereumPoolStorage} from './interfaces/IPoolStorage.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumDeployer} from '../../core/interfaces/IDeployer.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
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
    IExtendedDerivative _derivative,
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

  function addDerivative(IExtendedDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.addDerivative(derivative);
  }

  function removeDerivative(IExtendedDerivative derivative)
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
    IExtendedDerivative srcDerivative,
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external override onlyLiquidityProvider nonReentrant {
    poolStorage.depositIntoDerivative(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function slowWithdrawRequest(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  ) external override onlyLiquidityProvider nonReentrant {
    poolStorage.slowWithdrawRequest(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function slowWithdrawPassedRequest(IExtendedDerivative derivative)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.slowWithdrawPassedRequest(derivative);
  }

  function fastWithdraw(
    IExtendedDerivative derivative,
    uint256 collateralAmount
  )
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

  function emergencyShutdown(IExtendedDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.emergencyShutdown(derivative);
  }

  function settleEmergencyShutdown(IExtendedDerivative derivative)
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
    IExtendedDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInDerivative(derivative, derivativeRole, addressToAdd);
  }

  function renounceRoleInDerivative(
    IExtendedDerivative derivative,
    DerivativeRoles derivativeRole
  ) external override onlyMaintainer nonReentrant {
    poolStorage.renounceRoleInDerivative(derivative, derivativeRole);
  }

  function addRoleInSynthToken(
    IExtendedDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInSynthToken(derivative, synthTokenRole, addressToAdd);
  }

  function renounceRoleInSynthToken(
    IExtendedDerivative derivative,
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
    returns (IExtendedDerivative[] memory)
  {
    EnumerableSet.AddressSet storage derivativesSet = poolStorage.derivatives;
    uint256 numberOfDerivatives = derivativesSet.length();
    IExtendedDerivative[] memory derivatives =
      new IExtendedDerivative[](numberOfDerivatives);
    for (uint256 j = 0; j < numberOfDerivatives; j++) {
      derivatives[j] = (IExtendedDerivative(derivativesSet.at(j)));
    }
    return derivatives;
  }

  function isDerivativeAdmitted(address derivative)
    external
    view
    override
    returns (bool isAdmitted)
  {
    isAdmitted = poolStorage.derivatives.contains(derivative);
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

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumPool} from './IPool.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
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
import {ISynthereumPoolGeneral} from '../common/interfaces/IPoolGeneral.sol';
import {ISynthereumPoolStorage} from './interfaces/IPoolStorage.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {IRole} from '../../base/interfaces/IRole.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumPoolRegistry} from '../../core/interfaces/IPoolRegistry.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';

library SynthereumPoolLib {
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolLib for ISynthereumPoolStorage.Storage;
  using SynthereumPoolLib for IExtendedDerivative;
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
    IExtendedDerivative derivative
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
    IExtendedDerivative _derivative,
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
    IExtendedDerivative derivative
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
    IExtendedDerivative derivative
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
    IExtendedDerivative derivative =
      IExtendedDerivative(mintMetaTx.derivativeAddr);
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
    IExtendedDerivative derivative =
      IExtendedDerivative(redeemMetaTx.derivativeAddr);

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
    IExtendedDerivative derivative =
      IExtendedDerivative(exchangeMetaTx.derivativeAddr);
    IExtendedDerivative destDerivative =
      IExtendedDerivative(exchangeMetaTx.destDerivativeAddr);

    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(exchangeMetaTx.sender, derivative, numTokens);
    self.checkPool(
      ISynthereumPoolGeneral(exchangeMetaTx.destPoolAddr),
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

    ISynthereumPoolGeneral(exchangeMetaTx.destPoolAddr).exchangeMint(
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
    IExtendedDerivative srcDerivative,
    IExtendedDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external {
    self.checkPool(ISynthereumPoolGeneral(msg.sender), srcDerivative);
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    derivative.requestWithdrawal(collateralAmount);
  }

  function slowWithdrawPassedRequest(
    ISynthereumPoolStorage.Storage storage self,
    IExtendedDerivative derivative
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative
  ) external checkDerivative(self, derivative) {
    derivative.emergencyShutdown();
  }

  function settleEmergencyShutdown(
    ISynthereumPoolStorage.Storage storage self,
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
    ISynthereumPool.DerivativeRoles derivativeRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN) {
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
    ISynthereumPool.SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (synthTokenRole == ISynthereumPool.SynthTokenRoles.ADMIN) {
      derivative.addSyntheticTokenAdmin(addressToAdd);
    } else {
      require(
        self.syntheticToken ==
          IExtendedDerivative(addressToAdd).tokenCurrency(),
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
    IExtendedDerivative derivative,
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
  ) internal checkDerivative(self, IExtendedDerivative(derivativeAddr)) {
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
    IExtendedDerivative derivative,
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
    IExtendedDerivative derivative,
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

  function getDerivativeCollateral(IExtendedDerivative derivative)
    internal
    view
    returns (IERC20 collateral)
  {
    collateral = derivative.collateralCurrency();
  }

  function getGlobalCollateralizationRatio(IExtendedDerivative derivative)
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
    ISynthereumPoolGeneral poolToCheck,
    IExtendedDerivative derivativeToCheck
  ) internal view {
    require(
      poolToCheck.isDerivativeAdmitted(address(derivativeToCheck)),
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
pragma experimental ABIEncoderV2;
import {
  IExtendedDerivative
} from '../../derivative/common/interfaces/IExtendedDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumPool} from './interfaces/IPool.sol';
import {SynthereumPool} from './Pool.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {SynthereumPoolCreator} from './PoolCreator.sol';

contract SynthereumPoolFactory is SynthereumPoolCreator, IDeploymentSignature {
  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  constructor(address _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPool.selector;
  }

  function createPool(
    IExtendedDerivative derivative,
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
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {SynthereumTICInterface} from './interfaces/ITIC.sol';
import {SynthereumTIC} from './TIC.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
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

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
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

  function isDerivativeAdmitted(address TICDerivative)
    external
    view
    override
    returns (bool)
  {
    return TICDerivative == address(ticStorage.derivative);
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
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
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

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

  EnumerableMap.UintToAddressMap private _selfMintingFactory;

  event AddPoolFactory(uint8 indexed version, address indexed poolFactory);

  event SetPoolFactory(uint8 indexed version, address indexed poolFactory);

  event RemovePoolFactory(uint8 indexed version, address indexed poolFactory);

  event AddDerivativeFactory(
    uint8 indexed version,
    address indexed derivativeFactory
  );

  event SetDerivativeFactory(
    uint8 indexed version,
    address indexed derivativeFactory
  );

  event RemoveDerivativeFactory(
    uint8 indexed version,
    address indexed derivativeFactory
  );

  event AddSelfMintingFactory(
    uint8 indexed version,
    address indexed selfMintingFactory
  );

  event SetSelfMintingFactory(
    uint8 indexed version,
    address indexed selfMintingFactory
  );

  event RemoveSelfMintingFactory(
    uint8 indexed version,
    address indexed selfMintingFactory
  );

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
    require(poolFactory != address(0), 'Pool factory cannot be address 0');
    bool isNewVersion = _poolsFactory.set(version, poolFactory);
    if (isNewVersion == true) {
      emit AddPoolFactory(version, poolFactory);
    } else {
      emit SetPoolFactory(version, poolFactory);
    }
  }

  function removePoolFactory(uint8 version) external override onlyMaintainer {
    address poolFactoryToRemove = _poolsFactory.get(version);
    _poolsFactory.remove(version);
    RemovePoolFactory(version, poolFactoryToRemove);
  }

  function setDerivativeFactory(uint8 version, address derivativeFactory)
    external
    override
    onlyMaintainer
  {
    require(
      derivativeFactory != address(0),
      'Derivative factory cannot be address 0'
    );
    bool isNewVersion = _derivativeFactory.set(version, derivativeFactory);
    if (isNewVersion == true) {
      emit AddDerivativeFactory(version, derivativeFactory);
    } else {
      emit SetDerivativeFactory(version, derivativeFactory);
    }
  }

  function removeDerivativeFactory(uint8 version)
    external
    override
    onlyMaintainer
  {
    address derivativeFactoryToRemove = _derivativeFactory.get(version);
    _derivativeFactory.remove(version);
    emit RemoveDerivativeFactory(version, derivativeFactoryToRemove);
  }

  function setSelfMintingFactory(uint8 version, address selfMintingFactory)
    external
    override
    onlyMaintainer
  {
    require(
      selfMintingFactory != address(0),
      'Self-minting factory cannot be address 0'
    );
    bool isNewVersion = _selfMintingFactory.set(version, selfMintingFactory);
    if (isNewVersion == true) {
      emit AddSelfMintingFactory(version, selfMintingFactory);
    } else {
      emit SetSelfMintingFactory(version, selfMintingFactory);
    }
  }

  function removeSelfMintingFactory(uint8 version)
    external
    override
    onlyMaintainer
  {
    address selfMintingFactoryToRemove = _selfMintingFactory.get(version);
    _selfMintingFactory.remove(version);
    emit RemoveSelfMintingFactory(version, selfMintingFactoryToRemove);
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

  function getSelfMintingFactoryVersion(uint8 version)
    external
    view
    override
    returns (address selfMintingFactory)
  {
    selfMintingFactory = _selfMintingFactory.get(version);
  }

  function numberOfVerisonsOfSelfMintingFactory()
    external
    view
    override
    returns (uint256 numberOfVersions)
  {
    numberOfVersions = _selfMintingFactory.length();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface ISynthereumFactoryVersioning {
  function setPoolFactory(uint8 version, address poolFactory) external;

  function removePoolFactory(uint8 version) external;

  function setDerivativeFactory(uint8 version, address derivativeFactory)
    external;

  function removeDerivativeFactory(uint8 version) external;

  function setSelfMintingFactory(uint8 version, address selfMintingFactory)
    external;

  function removeSelfMintingFactory(uint8 version) external;

  function getPoolFactoryVersion(uint8 version)
    external
    view
    returns (address poolFactory);

  function numberOfVerisonsOfPoolFactory()
    external
    view
    returns (uint256 numberOfVersions);

  function getDerivativeFactoryVersion(uint8 version)
    external
    view
    returns (address derivativeFactory);

  function numberOfVerisonsOfDerivativeFactory()
    external
    view
    returns (uint256 numberOfVersions);

  function getSelfMintingFactoryVersion(uint8 version)
    external
    view
    returns (address selfMintingFactory);

  function numberOfVerisonsOfSelfMintingFactory()
    external
    view
    returns (uint256 numberOfVersions);
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
  "libraries": {
    "deploy/contracts/contracts/synthereum-pool/v3/PoolOnChainPriceFeedLib.sol": {
      "SynthereumPoolOnChainPriceFeedLib": "0xa0e59e8552b9c12f4438ce033de855c6ff16136a"
    }
  }
}