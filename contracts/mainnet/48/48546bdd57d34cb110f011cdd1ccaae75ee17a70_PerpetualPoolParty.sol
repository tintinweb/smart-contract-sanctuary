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
pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';

interface AdministrateeInterface {
  function emergencyShutdown() external;

  function remargin() external;

  function pfc() external view returns (FixedPoint.Unsigned memory);
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