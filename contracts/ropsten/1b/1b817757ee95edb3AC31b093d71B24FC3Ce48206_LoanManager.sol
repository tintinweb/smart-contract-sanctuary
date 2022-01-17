// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './Math.sol';

library Calculation {
  using Math for uint256;

  uint256 internal constant SECONDSPERYEAR = 365 days;

  function calculateLinearInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    uint256 timeDelta = currentTimestamp - uint256(lastUpdateTimestamp);

    return ((rate * timeDelta) / SECONDSPERYEAR) + Math.ray();
  }

  /// @dev Function to calculate the interest using a compounded interest rate formula
  /// To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
  ///  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
  ///
  /// The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
  /// The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
  ///
  /// @param rate The interest rate, in ray
  /// @param lastUpdateTimestamp The timestamp of the last update of the interest
  /// @return The interest rate compounded during the timeDelta, in ray
  function calculateCompoundedInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - lastUpdateTimestamp;

    if (exp == 0) {
      return Math.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    // loss of precision is endurable
    // slither-disable-next-line divide-before-multiply
    uint256 ratePerSecond = rate / SECONDSPERYEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
    uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;

    return Math.ray() + (ratePerSecond * exp) + secondTerm + thirdTerm;
  }

  function calculateRateInIncreasingBalance(
    uint256 averageRate,
    uint256 totalBalance,
    uint256 amountIn,
    uint256 rate
  ) internal pure returns (uint256, uint256) {
    uint256 weightedAverageRate = totalBalance.wadToRay().rayMul(averageRate);
    uint256 weightedAmountRate = amountIn.wadToRay().rayMul(rate);

    uint256 newTotalBalance = totalBalance + amountIn;
    uint256 newAverageRate = (weightedAverageRate + weightedAmountRate).rayDiv(
      newTotalBalance.wadToRay()
    );

    return (newTotalBalance, newAverageRate);
  }
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

import './interfaces/ILoanManager.sol';
import './storage/LoanManagerStorage.sol';
import '../core/libraries/Calculation.sol';

pragma solidity ^0.8.4;

error LoanIdAlreadyExist();
error UnknownLoanId();

/// @title LoanManager
/// @notice LoanManager manages loan data in the protocol. Core contract can produce or
/// change state of the loan data in loan manager contract. LoanManager also provides redeem
/// or liquidation amount of the loan.
contract LoanManager is ILoanManager, LoanManagerStorage {
  using Math for uint256;

  constructor(
    IProtocolAddressProvider protocolAddressProvider,
    IAssetTokenStateProvider assetTokenStateProvider
  ) {
    _protocolAddressProvider = protocolAddressProvider;
    _assetTokenStateProvider = assetTokenStateProvider;
  }

  /// ************** Modifiers ************* ///

  modifier onlyCore() {
    if (msg.sender != address(_protocolAddressProvider.getCore())) revert OnlyCore();
    _;
  }

  /// ************** User Interactions ************* ///

  /// @inheritdoc ILoanManager
  /// @custom:check - check that loan id that build from `hashLoan` already exists
  /// @custom:check - check that `msg.sender` is the `core`
  /// @custom:effect - sets `_loans[loanId] = loan`
  ///   - loan struct is `principalAmount, block.timestamp, dueTimestamp, interestRate, LoanState.VALID'
  ///   - loanId can be build from `hashLoan(borrower, asset, collateral, core, tokenId, descriptionHash`
  function beginLoan(
    address borrower,
    address asset,
    address collateral,
    uint256 tokenId,
    uint256 principalAmount,
    uint256 duration,
    uint256 interestRate,
    bytes32 descriptionHash
  ) external override onlyCore returns (uint256 loanId) {
    loanId = hashLoan(borrower, asset, collateral, msg.sender, tokenId, descriptionHash);

    if (_loan[loanId].startTimestamp != 0) revert LoanIdAlreadyExist();

    Loan storage loan = _loan[loanId];

    loan.principalAmount = principalAmount;
    loan.interestRate = interestRate;
    loan.startTimestamp = uint64(block.timestamp);
    loan.dueTimestamp = uint64(block.timestamp + duration);

    emit LoanBegin(
      borrower,
      asset,
      collateral,
      loanId,
      tokenId,
      principalAmount,
      duration,
      interestRate,
      descriptionHash
    );
  }

  /// @inheritdoc ILoanManager
  /// @custom:check - check that loanState should be `ACTIVE`
  /// @custom:effect - sets `loanState` to `END`
  /// @custom:interaction - emits `LoanRepaid` event
  function repayLoan(
    address borrower,
    address asset,
    address collateral,
    uint256 tokenId,
    bytes32 descriptionHash
  )
    external
    override
    onlyCore
    returns (
      uint256 loanState,
      uint256 repayAmount,
      uint256 loanInterestRate
    )
  {
    uint256 loanId = hashLoan(borrower, asset, collateral, msg.sender, tokenId, descriptionHash);

    Loan storage loan = _loan[loanId];

    loanState = getLoanState(collateral, loanId, tokenId);

    repayAmount = getRepaymentAmount(loanId);

    loanInterestRate = loan.interestRate;

    loan.loanState = LoanState.END;

    emit LoanRepaid(
      asset,
      collateral,
      borrower,
      loanId,
      tokenId,
      loan.principalAmount,
      repayAmount,
      block.timestamp
    );
  }

  /// ************** View Functions ************* ///

  /// @inheritdoc ILoanManager
  function hashLoan(
    address borrower,
    address asset,
    address collateral,
    address core,
    uint256 tokenId,
    bytes32 descriptionHash
  ) public pure override returns (uint256 loanId) {
    loanId = uint256(
      keccak256(abi.encode(borrower, asset, collateral, core, tokenId, descriptionHash))
    );
  }

  /// @inheritdoc ILoanManager
  function getLoan(uint256 loanId)
    external
    view
    override
    returns (
      uint256 principalAmount,
      uint256 startTimestamp,
      uint256 dueTimestamp,
      uint256 interestRate,
      uint256 loanState
    )
  {
    Loan storage loan = _loan[loanId];

    principalAmount = loan.principalAmount;
    startTimestamp = uint256(loan.startTimestamp);
    dueTimestamp = uint256(loan.dueTimestamp);
    interestRate = loan.interestRate;
    loanState = uint256(loan.loanState);
  }

  /// @inheritdoc ILoanManager
  function getLoanState(
    address assetToken,
    uint256 loanId,
    uint256 tokenId
  ) public view override returns (uint256 loanState) {
    Loan storage loan = _loan[loanId];

    if (loan.startTimestamp == 0) revert UnknownLoanId();

    if (loan.loanState == LoanState.END) {
      loanState = uint256(LoanState.END);
    } else if (_assetTokenStateProvider.getAssetTokenState(assetToken, tokenId) == false) {
      loanState = uint256(LoanState.DEFAULTED);
    } else if (block.timestamp > loan.dueTimestamp) {
      loanState = uint256(LoanState.DEFAULTED);
    } else {
      loanState = uint256(LoanState.VALID);
    }
  }

  /// @inheritdoc ILoanManager
  function getRepaymentAmount(uint256 loanId) public view override returns (uint256 amountToRepay) {
    Loan storage loan = _loan[loanId];

    amountToRepay = Calculation
      .calculateCompoundedInterest(loan.interestRate, uint256(loan.startTimestamp), block.timestamp)
      .rayMul(loan.principalAmount);
  }

  /// @inheritdoc ILoanManager
  function getAssetTokenStateProvider()
    external
    view
    override
    returns (address assetTokenStateProvider)
  {
    assetTokenStateProvider = address(_assetTokenStateProvider);
  }

  /// @inheritdoc ILoanManager
  function getProtocolAddressProvider()
    external
    view
    override
    returns (address protocolAddressProvider)
  {
    protocolAddressProvider = address(_protocolAddressProvider);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILoanManager {
  event LoanBegin(
    address indexed borrower,
    address asset,
    address collateral,
    uint256 loanId,
    uint256 tokenId,
    uint256 principalAmount,
    uint256 duration,
    uint256 interestRate,
    bytes32 descriptionHash
  );

  event LoanRepaid(
    address asset,
    address collateral,
    address borrower,
    uint256 loanId,
    uint256 tokenId,
    uint256 principalAmount,
    uint256 repayAmount,
    uint256 repayTimestamp
  );

  /// @notice This function can be called when new loan begins. The loan detail hashed.
  /// Only callable by core contract
  /// @param borrower The borrower address
  /// @param asset The address of the ERC20 contract of the currency being used as principal/interest for this loan.
  /// @param collateral The address of the ERC721 contract of the asset token being collateralized for this loan.
  /// @param tokenId The id of the token which is used as collateral of this loan
  /// @param principalAmount The original sum of money transferred from lender to borrower at the beginning of the loan
  /// @param duration The amount of time (measured in seconds) that can elapse before the lender can liquidate the loan
  // and seize the underlying collateral NFT
  /// @param interestRate The interest rate for the loan
  /// @param descriptionHash The description hash of loan
  /// @return loanId The id of loan initialized which is build from hashing the loan struct
  function beginLoan(
    address borrower,
    address asset,
    address collateral,
    uint256 tokenId,
    uint256 principalAmount,
    uint256 duration,
    uint256 interestRate,
    bytes32 descriptionHash
  ) external returns (uint256 loanId);

  /// @notice This function can be called when loan redeemed
  /// @param borrower The borrower address
  /// @param asset The address of the ERC20 contract of the currency being used as principal/interest for this loan.
  /// @param collateral The address of the ERC721 contract of the asset token being collateralized for this loan.
  /// @param tokenId The id of the token which is collateralized for the loan
  /// @param descriptionHash bytes32 which itself is the keccak256 hash of the description string
  /// @return loanState returns the loan state prior to the action
  function repayLoan(
    address borrower,
    address asset,
    address collateral,
    uint256 tokenId,
    bytes32 descriptionHash
  )
    external
    returns (
      uint256 loanState,
      uint256 repayAmount,
      uint256 loanInterestRate
    );

  /// @notice Hashing function used to build the loan id from the loan detail
  /// - borrower: the address of the borrower who begins the loan and will receive collateral after redemption of the loan
  /// - asset: underlying asset address for the loan principal
  /// - collateral: asset token address for the loan collateral
  /// - core: the address of the core contract executing the borrow which can be passed as `msg.sender`
  /// - tokenId: the id of the token for the loan collateral
  /// - descriptionHash: the description for the loan which is posted in the protocol forum
  /// @param borrower The address of the borrower
  /// @param asset description
  /// @param collateral description
  /// @param core The address of the core contract
  /// @param tokenId The id of the token which is collateralized for the loan
  /// @param descriptionHash bytes32 which itself is the keccak256 hash of the description string
  /// @return loanId The loan id produced by hashing the loan data
  function hashLoan(
    address borrower,
    address asset,
    address collateral,
    address core,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external pure returns (uint256 loanId);

  /// @notice This function return the data of the loan
  /// @param loanId The loan id
  /// @return principalAmount The principal amount of the loan
  /// @return startTimestamp Loan start timestamp
  /// @return dueTimestamp Loan due timestamp
  /// @return interestRate The interest rate of the loan
  /// @return loanState The state of the loan
  function getLoan(uint256 loanId)
    external
    view
    returns (
      uint256 principalAmount,
      uint256 startTimestamp,
      uint256 dueTimestamp,
      uint256 interestRate,
      uint256 loanState
    );

  /// @notice This function returns the state of the loan
  /// @dev It checks the state of the asset token first. If the current asset token state from the assetTokenStateOracle is invalid, the loan state is `DEFAULTED`
  /// After then, it compares the current block timestamp and loan timestamps
  /// @param assetToken The address of the assetToken
  /// @param loanId The loan id
  /// @param tokenId The id of the token collateralized
  /// @return loanState The loan state
  function getLoanState(
    address assetToken,
    uint256 loanId,
    uint256 tokenId
  ) external view returns (uint256 loanState);

  /// @notice This function compute and return the amount for redepmtion of the loan based on the loan data
  /// @param loanId The loan id
  /// @return amountToRepay Amount to repay
  function getRepaymentAmount(uint256 loanId) external view returns (uint256 amountToRepay);

  /// @notice ElysiaProvider address to validate and check the state of asset token.
  /// @return assetTokenStateProvider The address of AssetTokenStateProvider contract
  function getAssetTokenStateProvider() external view returns (address assetTokenStateProvider);

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The address of protocolAddressProvider contract
  function getProtocolAddressProvider() external view returns (address protocolAddressProvider);
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

// SPDX-License-Identifier: MIT

import '../interfaces/IProtocolAddressProvider.sol';
import {IAssetTokenStateProvider} from '../../test/AssetTokenStateProvider.sol';

pragma solidity ^0.8.4;

abstract contract LoanManagerStorage {
  enum LoanState {
    VALID,
    DEFAULTED,
    END
  }

  struct Loan {
    uint256 principalAmount;
    uint256 interestRate;
    uint64 startTimestamp;
    uint64 dueTimestamp;
    LoanState loanState;
  }

  mapping(uint256 => Loan) internal _loan;

  IProtocolAddressProvider internal _protocolAddressProvider;

  IAssetTokenStateProvider internal _assetTokenStateProvider;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAssetTokenStateProvider {
  function getAssetTokenState(address asset, uint256 tokenId) external view returns (bool);

  function setAssetTokenState(
    address asset,
    uint256 tokenId,
    bool state
  ) external;
}

/// @title AssetTokenStateProvider
/// @notice This AssetTokenStateProvider is only for the test
contract AssetTokenStateProvider is IAssetTokenStateProvider {
  constructor() {}

  enum State {
    VALID,
    INVAILD
  }

  mapping(uint256 => State) public tokenState;

  /// @notice This function always returns false
  function getAssetTokenState(address asset, uint256 tokenId)
    external
    view
    override
    returns (bool)
  {
    asset;
    if (tokenState[tokenId] == State.INVAILD) {
      return false;
    } else {
      return true;
    }
  }

  /// @notice This function always returns false
  function setAssetTokenState(
    address asset,
    uint256 tokenId,
    bool state
  ) external override {
    asset;
    if (state == true) {
      tokenState[tokenId] = State.VALID;
    } else {
      tokenState[tokenId] = State.INVAILD;
    }
  }
}