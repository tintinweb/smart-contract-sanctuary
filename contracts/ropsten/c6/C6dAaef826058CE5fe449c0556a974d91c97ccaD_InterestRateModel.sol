// SPDX-License-Identifier: MIT

import './interfaces/IInterestRateModel.sol';
import './storage/InterestRateModelStorage.sol';

import './libraries/Math.sol';

pragma solidity ^0.8.4;

/// @title InterestRateModel
/// @notice Interest rates model in ELYFI. ELYFI's interest rates are determined by algorithms.
/// When borrowing demand increases, borrowing interest and pool ROI increase,
/// suppressing excessove borrowing demand and inducing depositors to supply liquidity.
/// Therefore, ELYFI's interest rates are influenced by the Pool `utilizationRatio`.
/// The Pool utilization ratio is a variable representing the current borrowing
/// and deposit status of the Pool. The interest rates of ELYFI exhibits some form of kink.
/// They sharply change at some defined threshold, `optimalUtilazationRate`.
contract InterestRateModel is IInterestRateModel, InterestRateModelStorage {
  using Math for uint256;

  constructor(IProtocolAddressProvider protocolAddressProvider) {
    _protocolAddressProvider = protocolAddressProvider;
  }

  struct calculateRatesLocalVars {
    uint256 totalDebt;
    uint256 utilizationRate;
    uint256 newBorrowAPY;
    uint256 newDepositAPY;
  }

  modifier onlyGovernance() {
    require(
      msg.sender == IProtocolAddressProvider(_protocolAddressProvider).getGovernance(),
      'Only Governance Allowed'
    );
    _;
  }

  /// @inheritdoc IInterestRateModel
  function calculateRates(
    address asset,
    uint256 poolRemainingLiquidityAfterAction,
    uint256 totalDebtTokenSupply,
    uint256 poolFactor
  ) external view override returns (uint256 newBorrowAPY, uint256 newDepositAPY) {
    InterestRateModelParam memory param = _interestRateModel[asset];

    calculateRatesLocalVars memory vars;

    vars.totalDebt = totalDebtTokenSupply;
    vars.utilizationRate = _getUtilizationRate(vars.totalDebt, poolRemainingLiquidityAfterAction);
    vars.newBorrowAPY = 0;

    if (vars.utilizationRate <= param.optimalUtilizationRate) {
      vars.newBorrowAPY =
        param.borrowRateBase +
        (
          (param.borrowRateOptimal - param.borrowRateBase)
            .rayDiv(param.optimalUtilizationRate)
            .rayMul(vars.utilizationRate)
        );
    } else {
      vars.newBorrowAPY =
        param.borrowRateOptimal +
        (
          (param.borrowRateMax - param.borrowRateOptimal)
            .rayDiv(Math.ray() - param.optimalUtilizationRate)
            .rayMul(vars.utilizationRate - param.optimalUtilizationRate)
        );
    }

    vars.newDepositAPY = vars.newBorrowAPY.rayMul(vars.utilizationRate).rayMul(
      Math.RAY - poolFactor
    );

    return (vars.newBorrowAPY, vars.newDepositAPY);
  }

  /// @inheritdoc IInterestRateModel
  /// @custom:check -  Make sure that `msg.sender` is core contract
  /// @custom:check - InterestRateModelParams with `asset` does not already exist
  /// @custom:effect - set `_interestRateModel[asset]` to given params
  /// @custom:interaction - emit `AddNewPoolInterestRateModel` event
  function addNewPoolInterestRateModel(
    address asset,
    uint256 optimalUtilizationRate,
    uint256 borrowRateBase,
    uint256 borrowRateOptimal,
    uint256 borrowRateMax
  ) external override onlyGovernance {
    require(_interestRateModel[asset].borrowRateMax == 0, 'Model already exists');

    _interestRateModel[asset].optimalUtilizationRate = optimalUtilizationRate;
    _interestRateModel[asset].borrowRateBase = borrowRateBase;
    _interestRateModel[asset].borrowRateOptimal = borrowRateOptimal;
    _interestRateModel[asset].borrowRateMax = borrowRateMax;

    emit AddNewPoolInterestRateModel(
      asset,
      optimalUtilizationRate,
      borrowRateBase,
      borrowRateOptimal,
      borrowRateMax
    );
  }

  /// @inheritdoc IInterestRateModel
  /// @custom:check - Make sure that `msg.sender` is core contract
  /// @custom:effect - update `_interestRateModel[asset].optimalUtilizationRate` to `optimalUtilizationRate`
  /// @custom:interaction - emit `UpdateOptimalUtilizationRate` event
  function updateOptimalUtilizationRate(address asset, uint256 optimalUtilizationRate)
    external
    override
    onlyGovernance
  {
    _interestRateModel[asset].optimalUtilizationRate = optimalUtilizationRate;
    emit UpdateOptimalUtilizationRate(optimalUtilizationRate);
  }

  /// @inheritdoc IInterestRateModel
  /// @custom:check - Make sure that `msg.sender` is core contract
  /// @custom:effect - update `_interestRateModel[asset].borrowRateBase` to `borrowRateBase`
  /// @custom:interaction - emit `UpdateBorrowRateBase` event
  function updateBorrowRateBase(address asset, uint256 borrowRateBase)
    external
    override
    onlyGovernance
  {
    _interestRateModel[asset].borrowRateBase = borrowRateBase;
    emit UpdateBorrowRateBase(borrowRateBase);
  }

  /// @inheritdoc IInterestRateModel
  /// @custom:check - Make sure that `msg.sender` is core contract
  /// @custom:effect - update `_interestRateModel[asset].borrowRateOptimal` to `borrowRateOptimal`
  /// @custom:interaction - emit `UpdateBorrowRateOptimal` event
  function updateBorrowRateOptimal(address asset, uint256 borrowRateOptimal)
    external
    override
    onlyGovernance
  {
    _interestRateModel[asset].borrowRateOptimal = borrowRateOptimal;
    emit UpdateBorrowRateOptimal(borrowRateOptimal);
  }

  /// @inheritdoc IInterestRateModel
  /// @custom:check - Make sure that `msg.sender` is core contract
  /// @custom:effect - update `_interestRateModel[asset].borrowRateMax` to `borrowRateMax`
  /// @custom:interaction - emit `UpdateBorrowRateMax` event
  function updateBorrowRateMax(address asset, uint256 borrowRateMax)
    external
    override
    onlyGovernance
  {
    _interestRateModel[asset].borrowRateMax = borrowRateMax;
    emit UpdateBorrowRateMax(borrowRateMax);
  }

  /// @inheritdoc IInterestRateModel
  function getInterestRateModelParam(address asset)
    external
    view
    override
    returns (
      uint256 optimalUtilizationRate,
      uint256 borrowRateBase,
      uint256 borrowRateOptimal,
      uint256 borrowRateMax
    )
  {
    optimalUtilizationRate = _interestRateModel[asset].optimalUtilizationRate;
    borrowRateBase = _interestRateModel[asset].borrowRateBase;
    borrowRateOptimal = _interestRateModel[asset].borrowRateOptimal;
    borrowRateMax = _interestRateModel[asset].borrowRateMax;
  }

  function getUtilizationRate(uint256 totalDebt, uint256 availableLiquidity)
    external
    pure
    override
    returns (uint256 utilizationRate)
  {
    utilizationRate = _getUtilizationRate(totalDebt, availableLiquidity);
  }

  /// @inheritdoc IInterestRateModel
  function getProtocolAddressProvider()
    external
    override
    returns (IProtocolAddressProvider protocolAddressProvider)
  {}

  function _getUtilizationRate(uint256 totalDebt, uint256 availableLiquidity)
    private
    pure
    returns (uint256)
  {
    return totalDebt == 0 ? 0 : totalDebt.rayDiv(availableLiquidity + totalDebt);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../../managers/interfaces/IProtocolAddressProvider.sol';

interface IInterestRateModel {
  /// @param optimalUtilizationRate New optimalUtilizationRate
  event UpdateOptimalUtilizationRate(uint256 optimalUtilizationRate);

  /// @param borrowRateBase New borrowRateBase
  event UpdateBorrowRateBase(uint256 borrowRateBase);

  /// @param borrowRateOptimal New borrowRateOptimal
  event UpdateBorrowRateOptimal(uint256 borrowRateOptimal);

  /// @param borrowRateMax New borrowRateMax
  event UpdateBorrowRateMax(uint256 borrowRateMax);

  /// @param asset Underlying asset address to added
  /// @param optimalUtilizationRate The new optimalUtilizationRate
  /// @param borrowRateBase The new borrowRateBase
  /// @param borrowRateOptimal The new borrowRateOptimal
  /// @param borrowRateMax The new borrowRateMax
  event AddNewPoolInterestRateModel(
    address asset,
    uint256 optimalUtilizationRate,
    uint256 borrowRateBase,
    uint256 borrowRateOptimal,
    uint256 borrowRateMax
  );

  /// @notice Calculates the interest rates based on the token balances.
  /// @dev Calculation Example
  /// - Case1: under optimal U
  ///   - baseRate = 2%, util = 40%, optimalRate = 10%, optimalUtil = 80%
  ///   - result = 2+40*(10-2)/80 = 4%
  /// - Case2: over optimal U
  ///   - optimalRate = 10%, util = 90%, maxRate = 100%, optimalUtil = 80%
  ///   - result = 10+(90-80)*(100-10)/(100-80) = 55%
  /// @param asset Underlying asset address
  /// @param poolRemainingLiquidityAfterAction Pool remaining liquidity after the deposit or borrow
  /// @param totalDebtTokenSupply Total debt token supply
  /// @param poolFactor The pool factor for reserve
  /// @return newBorrowAPY Calculeted borrowAPY
  /// @return newDepositAPY Calculeted depositAPY
  function calculateRates(
    address asset,
    uint256 poolRemainingLiquidityAfterAction,
    uint256 totalDebtTokenSupply,
    uint256 poolFactor
  ) external view returns (uint256 newBorrowAPY, uint256 newDepositAPY);

  /// @notice This function can be called when new pool added to add new interest rate model
  /// Only callable by the core contract
  /// @param asset Underlying asset address to added
  /// @param optimalUtilizationRate The new optimalUtilizationRate
  /// @param borrowRateBase The new borrowRateBase
  /// @param borrowRateOptimal The new borrowRateOptimal
  /// @param borrowRateMax The new borrowRateMax
  function addNewPoolInterestRateModel(
    address asset,
    uint256 optimalUtilizationRate,
    uint256 borrowRateBase,
    uint256 borrowRateOptimal,
    uint256 borrowRateMax
  ) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param optimalUtilizationRate New optimalUtilizationRate to update
  function updateOptimalUtilizationRate(address asset, uint256 optimalUtilizationRate) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param borrowRateBase New optimalUtilizationRate to update
  function updateBorrowRateBase(address asset, uint256 borrowRateBase) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param borrowRateOptimal New optimalUtilizationRate to update
  function updateBorrowRateOptimal(address asset, uint256 borrowRateOptimal) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param borrowRateMax New optimalUtilizationRate to update
  function updateBorrowRateMax(address asset, uint256 borrowRateMax) external;

  /// @notice This function returns interest rate model params for asset
  /// @param asset Underlying asset address
  /// @return optimalUtilizationRate When the pool utilization ratio exceeds this parameter, the kinked rates model adjusts interests.
  /// @return borrowRateBase The interest rate when utilization ratio is zero.
  /// @return borrowRateOptimal The interest rate when the pool utilization ratio is optimal.
  /// @return borrowRateMax The interest rate when the pool utilization ratio is 1.
  function getInterestRateModelParam(address asset)
    external
    view
    returns (
      uint256 optimalUtilizationRate,
      uint256 borrowRateBase,
      uint256 borrowRateOptimal,
      uint256 borrowRateMax
    );

  /// @notice This function returns the current utilization rate of the pool for the asset
  /// TODO
  /// @return utilizationRate The current utilization rate of the pool for the asset.
  function getUtilizationRate(
    uint256 totalDebt,
    uint256 availableLiquidity
  )
    external
    pure
    returns (uint256 utilizationRate);

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The address of protocolAddressProvider contract
  function getProtocolAddressProvider()
    external
    returns (IProtocolAddressProvider protocolAddressProvider);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Math library
/// @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
library Math {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /// @return One ray, 1e27
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /// @return One wad, 1e18

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  ///@return Half ray, 1e27/2
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /// @return Half ray, 1e18/2
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  /// @param a Wad
  /// @param b Wad
  /// @return The result of a*b, in wad
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /// @dev Divides two wad, rounding half up to the nearest wad
  /// @param a Wad
  /// @param b Wad
  /// @return The result of a/b, in wad
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * WAD + halfB) / b;
  }

  /// @dev Multiplies two ray, rounding half up to the nearest ray
  /// @param a Ray
  /// @param b Ray
  /// @return The result of a*b, in ray
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /// @dev Divides two ray, rounding half up to the nearest ray
  /// @param a Ray
  /// @param b Ray
  /// @return The result of a/b, in ray
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * RAY + halfB) / b;
  }

  /// @dev Casts ray down to wad
  /// @param a Ray
  /// @return a casted to wad, rounded half up to the nearest wad
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    return result / WAD_RAY_RATIO;
  }

  /// @dev Converts wad up to ray
  /// @param a Wad
  /// @return a converted in ray
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    return result;
  }
}

// SPDX-License-Identifier: MIT

import '../../managers/interfaces/IProtocolAddressProvider.sol';
import '../interfaces/IInterestRateModel.sol';

pragma solidity ^0.8.4;

abstract contract InterestRateModelStorage {
  ///@notice InterestRateModel parameters
  struct InterestRateModelParam {
    uint256 optimalUtilizationRate;
    uint256 borrowRateBase;
    uint256 borrowRateOptimal;
    uint256 borrowRateMax;
  }

  mapping(address => InterestRateModelParam) internal _interestRateModel;

  IProtocolAddressProvider internal _protocolAddressProvider;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error OnlyGovernance();
error OnlyGuardian();
error OnlyCouncil();
error OnlyCore();

interface IProtocolAddressProvider {
  /// @notice emitted when liquidationManager address updated
  event UpdateLiquidationManager(address liquidationManager);

  /// @notice emitted when loanManager address updated
  event UpdateLoanManager(address loanManager);

  /// @notice emitted when incentiveManager address updated
  event UpdateIncentiveManager(address incentiveManager);

  /// @notice emitted when governance address updated
  event UpdateGovernance(address governance);

  /// @notice emitted when council address updated
  event UpdateCouncil(address council);

  /// @notice emitted when core address updated
  event UpdateCore(address core);

  /// @notice emitted when treasury address updated
  event UpdateTreasury(address treasury);

  /// @notice emitted when protocol address provider initialized
  event ProtocolAddressProviderInitialized(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treausury
  );

  /// @notice ProtocolAddressProvider should be initialized after deploying protocol contracts finished.
  /// @param guardian guardian
  /// @param liquidationManager liquidationManager
  /// @param loanManager loanManager
  /// @param incentiveManager incentiveManager
  /// @param governance governance
  /// @param council council
  /// @param core core
  /// @param treasury treasury
  function initialize(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treasury
  ) external;

  /// @notice This function returns the address of the guardian
  /// @return guardian The address of the protocol guardian
  function getGuardian() external view returns (address guardian);

  /// @notice This function returns the address of liquidationManager contract
  /// @return liquidationManager The address of liquidationManager contract
  function getLiquidationManager() external view returns (address liquidationManager);

  /// @notice This function returns the address of LoanManager contract
  /// @return loanManager The address of LoanManager contract
  function getLoanManager() external view returns (address loanManager);

  /// @notice This function returns the address of incentiveManager contract
  /// @return incentiveManager The address of incentiveManager contract
  function getIncentiveManager() external view returns (address incentiveManager);

  /// @notice This function returns the address of governance contract
  /// @return governance The address of governance contract
  function getGovernance() external view returns (address governance);

  /// @notice This function returns the address of council contract
  /// @return council The address of council contract
  function getCouncil() external view returns (address council);

  /// @notice This function returns the address of core contract
  /// @return core The address of core contract
  function getCore() external view returns (address core);

  /// @notice This function returns the address of protocolTreasury contract
  /// @return protocolTreasury The address of protocolTreasury contract
  function getProtocolTreasury() external view returns (address protocolTreasury);

  /// @notice This function updates the address of liquidationManager contract
  /// @param liquidationManager The address of liquidationManager contract to update
  function updateLiquidationManager(address liquidationManager) external;

  /// @notice This function updates the address of LoanManager contract
  /// @param loanManager The address of LoanManager contract to update
  function updateLoanManager(address loanManager) external;

  /// @notice This function updates the address of incentiveManager contract
  /// @param incentiveManager The address of incentiveManager contract to update
  function updateIncentiveManager(address incentiveManager) external;

  /// @notice This function updates the address of governance contract
  /// @param governance The address of governance contract to update
  function updateGovernance(address governance) external;

  /// @notice This function updates the address of council contract
  /// @param council The address of council contract to update
  function updateCouncil(address council) external;

  /// @notice This function updates the address of core contract
  /// @param core The address of core contract to update
  function updateCore(address core) external;

  /// @notice This function updates the address of treasury contract
  /// @param treasury The address of treasury contract to update
  function updateTreasury(address treasury) external;
}