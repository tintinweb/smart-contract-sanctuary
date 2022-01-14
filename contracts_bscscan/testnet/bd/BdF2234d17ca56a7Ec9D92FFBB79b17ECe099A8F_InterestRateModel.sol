// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './libraries/WadRayMath.sol';

import './interfaces/IInterestRateModel.sol';

import './InterestRateModelStorage.sol';

import './interfaces/IConnector.sol';

/**
 * @title ELYFI InterestRateModel
 * @author ELYSIA
 * @notice Interest rates model in ELYFI. ELYFI's interest rates are determined by algorithms.
 * When borrowing demand increases, borrowing interest and MoneyPool ROI increase,
 * suppressing excessove borrowing demand and inducing depositors to supply liquidity.
 * Therefore, ELYFI's interest rates are influenced by the Money Pool `utilizationRatio`.
 * The Money Pool utilization ratio is a variable representing the current borrowing
 * and deposit status of the Money Pool. The interest rates of ELYFI exhibits some form of kink.
 * They sharply change at some defined threshold, `optimalUtilazationRate`.
 */
contract InterestRateModel is IInterestRateModel, InterestRateModelStorage {
  using WadRayMath for uint256;

  /**
   * @param optimalUtilizationRate When the MoneyPool utilization ratio exceeds this parameter, `optimalUtilizationRate`, the kinked rates model adjusts interests.
   * @param borrowRateBase The base interest rate.
   * @param borrowRateOptimal Interest rate when the Money Pool utilization ratio is optimal
   * @param borrowRateMax Interest rate when the Money Pool utilization ratio is 1
   */
  constructor(
    uint256 optimalUtilizationRate,
    uint256 borrowRateBase,
    uint256 borrowRateOptimal,
    uint256 borrowRateMax,
    address connector
  ) {
    _optimalUtilizationRate = optimalUtilizationRate;
    _borrowRateBase = borrowRateBase;
    _borrowRateOptimal = borrowRateOptimal;
    _borrowRateMax = borrowRateMax;
    _connector = connector;
  }

  struct calculateRatesLocalVars {
    uint256 totalDebt;
    uint256 utilizationRate;
    uint256 newBorrowAPY;
    uint256 newDepositAPY;
  }

  /**
   * @notice Calculates the interest rates.
   * @dev Calculation Example
   * Case1: under optimal U
   * baseRate = 2%, util = 40%, optimalRate = 10%, optimalUtil = 80%
   * result = 2+40*(10-2)/80 = 4%
   * Case2: over optimal U
   * optimalRate = 10%, util = 90%, maxRate = 100%, optimalUtil = 80%
   * result = 10+(90-80)*(100-10)/(100-80) = 55%
   * @param lTokenAssetBalance Total deposit amount
   * @param totalDTokenBalance total loan amount
   * @param depositAmount The liquidity added during the operation
   * @param borrowAmount The liquidity taken during the operation
   * @param moneyPoolFactor The moneypool factor. ununsed variable in version 1
   */
  function calculateRates(
    uint256 lTokenAssetBalance,
    uint256 totalDTokenBalance,
    uint256 depositAmount,
    uint256 borrowAmount,
    uint256 moneyPoolFactor
  ) public view override returns (uint256, uint256) {
    calculateRatesLocalVars memory vars;
    moneyPoolFactor;

    vars.totalDebt = totalDTokenBalance;

    uint256 availableLiquidity = lTokenAssetBalance + depositAmount - borrowAmount;

    vars.utilizationRate = vars.totalDebt == 0
      ? 0
      : vars.totalDebt.rayDiv(availableLiquidity + vars.totalDebt);

    vars.newBorrowAPY = 0;

    if (vars.utilizationRate <= _optimalUtilizationRate) {
      vars.newBorrowAPY =
        _borrowRateBase +
        (
          (_borrowRateOptimal - _borrowRateBase).rayDiv(_optimalUtilizationRate).rayMul(
            vars.utilizationRate
          )
        );
    } else {
      vars.newBorrowAPY =
        _borrowRateOptimal +
        (
          (_borrowRateMax - _borrowRateOptimal)
            .rayDiv(WadRayMath.ray() - _optimalUtilizationRate)
            .rayMul(vars.utilizationRate - _borrowRateOptimal)
        );
    }

    vars.newDepositAPY = vars.newBorrowAPY.rayMul(vars.utilizationRate);

    return (vars.newBorrowAPY, vars.newDepositAPY);
  }

  function updateOptimalUtilizationRate(
    uint256 optimalUtilizationRate
  ) onlyMoneyPoolAdmin external override {
    _optimalUtilizationRate = optimalUtilizationRate;
  }

  function updateBorrowRateBase(
    uint256 borrowRateBase
  ) onlyMoneyPoolAdmin external override {
    _borrowRateBase = borrowRateBase;
  }

  function updateBorrowRateOptimal(
    uint256 borrowRateOptimal
  ) onlyMoneyPoolAdmin external override {
    _borrowRateOptimal = borrowRateOptimal;
  }

  function updateBorrowRateMax(
    uint256 borrowRateMax
  ) onlyMoneyPoolAdmin external override {
    _borrowRateMax = borrowRateMax;
  }

  modifier onlyMoneyPoolAdmin() {
    require(IConnector(_connector).isMoneyPoolAdmin(msg.sender), 'OnlyMoneyPoolAdmin');
    _;
  }
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
pragma solidity 0.8.3;

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';

interface IInterestRateModel {
  function calculateRates(
    uint256 lTokenAssetBalance,
    uint256 totalDTokenBalance,
    uint256 depositAmount,
    uint256 borrowAmount,
    uint256 moneyPoolFactor
  ) external view returns (uint256, uint256);

  function updateOptimalUtilizationRate(
    uint256 optimalUtilizationRate
  ) external;

  function updateBorrowRateBase(
    uint256 borrowRateBase
  ) external;

  function updateBorrowRateOptimal(
    uint256 borrowRateOptimal
  ) external;

  function updateBorrowRateMax(
    uint256 borrowRateMax
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title ELYFI InterestRateModel
 * @author ELYSIA
 */

contract InterestRateModelStorage {
  uint256 public _optimalUtilizationRate;

  uint256 public _borrowRateBase;

  uint256 public _borrowRateOptimal;

  uint256 public _borrowRateMax;

  address internal _connector;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';

interface IConnector {
  /**
   * @notice Emitted when an admin adds a council role
   **/
  event NewCouncilAdded(address indexed account);

  /**
   * @notice Emitted when an admin adds a collateral service provider role
   **/
  event NewCollateralServiceProviderAdded(address indexed account);

  /**
   * @notice Emitted when a council role is revoked by admin
   **/
  event CouncilRevoked(address indexed account);

  /**
   * @notice Emitted when a collateral service provider role is revoked by admin
   **/
  event CollateralServiceProviderRevoked(address indexed account);

  function isCollateralServiceProvider(address account) external view returns (bool);

  function isCouncil(address account) external view returns (bool);

  function isMoneyPoolAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

library DataStruct {
  /**
    @notice The main reserve data struct.
   */
  struct ReserveData {
    uint256 moneyPoolFactor;
    uint256 lTokenInterestIndex;
    uint256 borrowAPY;
    uint256 depositAPY;
    uint256 lastUpdateTimestamp;
    address lTokenAddress;
    address dTokenAddress;
    address interestModelAddress;
    address tokenizerAddress;
    uint8 id;
    bool isPaused;
    bool isActivated;
  }

  /**
   * @notice The asset bond data struct.
   * @param ipfsHash The IPFS hash that contains the informations and contracts
   * between Collateral Service Provider and lender.
   * @param maturityTimestamp The amount of time measured in seconds that can elapse
   * before the NPL company liquidate the loan and seize the asset bond collateral.
   * @param borrower The address of the borrower.
   */
  struct AssetBondData {
    AssetBondState state;
    address borrower;
    address signer;
    address collateralServiceProvider;
    uint256 principal;
    uint256 debtCeiling;
    uint256 couponRate;
    uint256 interestRate;
    uint256 delinquencyRate;
    uint256 loanStartTimestamp;
    uint256 collateralizeTimestamp;
    uint256 maturityTimestamp;
    uint256 liquidationTimestamp;
    string ipfsHash; // refactor : gas
    string signerOpinionHash;
  }

  struct AssetBondIdData {
    uint256 nonce;
    uint256 countryCode;
    uint256 collateralServiceProviderIdentificationNumber;
    uint256 collateralLatitude;
    uint256 collateralLatitudeSign;
    uint256 collateralLongitude;
    uint256 collateralLongitudeSign;
    uint256 collateralDetail;
    uint256 collateralCategory;
    uint256 productNumber;
  }

  /**
    @notice The states of asset bond
    * EMPTY: After
    * SETTLED:
    * CONFIRMED:
    * COLLATERALIZED:
    * DELINQUENT:
    * REDEEMED:
    * LIQUIDATED:
   */
  enum AssetBondState {
    EMPTY,
    SETTLED,
    CONFIRMED,
    COLLATERALIZED,
    DELINQUENT,
    REDEEMED,
    LIQUIDATED
  }
}