// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.6;

import "./OwnableUpgradeSafe.sol";
import "./ERC20UpgradeSafe.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ReentrancyGuardUpgradeSafe.sol";
import "./Initializable.sol";

import "./IDebtToken.sol";
import "./IVaultConfig.sol";
import "./IWorker.sol";
import "./IVault.sol";
import "./IFairLaunch.sol";
import "./SafeToken.sol";
import "./IWETH.sol";
import "./IWNativeRelayer.sol";

contract Vault is IVault, ERC20UpgradeSafe, ReentrancyGuardUpgradeSafe, OwnableUpgradeSafe {
  /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint256;

  /// @notice Events
  event AddDebt(uint256 indexed id, uint256 debtShare);
  event RemoveDebt(uint256 indexed id, uint256 debtShare);
  event Work(uint256 indexed id, uint256 loan);
  event Kill(
    uint256 indexed id,
    address indexed killer,
    address owner,
    uint256 posVal,
    uint256 debt,
    uint256 prize,
    uint256 left
  );
  event AddCollateral(uint256 indexed id, uint256 amount, uint256 healthBefore, uint256 healthAfter);

  /// @dev Flags for manage execution scope
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private constant _NO_ID = uint256(-1);
  address private constant _NO_ADDRESS = address(1);

  /// @dev Temporay variables to manage execution scope
  uint256 public _IN_EXEC_LOCK;
  uint256 public POSITION_ID;
  address public STRATEGY;

  /// @dev Attributes for Vault
  /// token - address of the token to be deposited in this pool
  /// name - name of the ibERC20
  /// symbol - symbol of ibERC20
  /// decimals - decimals of ibERC20, this depends on the decimal of the token
  /// debtToken - just a simple ERC20 token for staking with FairLaunch
  address public override token;
  address public debtToken;

  struct Position {
    address worker;
    address owner;
    uint256 debtShare;
  }

  IVaultConfig public config;
  mapping(uint256 => Position) public positions;
  uint256 public nextPositionID;
  uint256 public fairLaunchPoolId;

  uint256 public vaultDebtShare;
  uint256 public vaultDebtVal;
  uint256 public lastAccrueTime;
  uint256 public reservePool;

  /// @dev Require that the caller must be an EOA account if not whitelisted.
  modifier onlyEOAorWhitelisted() {
    if (!config.whitelistedCallers(msg.sender)) {
      require(msg.sender == tx.origin, "not eoa");
    }
    _;
  }

  /// @dev Get token from msg.sender
  modifier transferTokenToVault(uint256 value) {
    if (msg.value != 0) {
      require(token == config.getWrappedNativeAddr(), "baseToken is not wNative");
      require(value == msg.value, "value != msg.value");
      IWETH(config.getWrappedNativeAddr()).deposit{ value: msg.value }();
    } else {
      SafeToken.safeTransferFrom(token, msg.sender, address(this), value);
    }
    _;
  }

  /// @dev Ensure that the function is called with the execution scope
  modifier inExec() {
    require(POSITION_ID != _NO_ID, "not within execution scope");
    require(STRATEGY == msg.sender, "not from the strategy");
    require(_IN_EXEC_LOCK == _NOT_ENTERED, "in exec lock");
    _IN_EXEC_LOCK = _ENTERED;
    _;
    _IN_EXEC_LOCK = _NOT_ENTERED;
  }

  /// @dev Add more debt to the bank debt pool.
  modifier accrue(uint256 value) {
    if (now > lastAccrueTime) {
      uint256 interest = pendingInterest(value);
      uint256 toReserve = interest.mul(config.getReservePoolBps()).div(10000);
      reservePool = reservePool.add(toReserve);
      vaultDebtVal = vaultDebtVal.add(interest);
      lastAccrueTime = now;
    }
    _;
  }

  function initialize(
    IVaultConfig _config,
    address _token,
    string calldata _name,
    string calldata _symbol,
    uint8 _decimals,
    address _debtToken
  ) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    ERC20UpgradeSafe.__ERC20_init(_name, _symbol);
    _setupDecimals(_decimals);

    nextPositionID = 1;
    config = _config;
    lastAccrueTime = now;
    token = _token;

    fairLaunchPoolId = uint256(-1);

    debtToken = _debtToken;

    SafeToken.safeApprove(debtToken, config.getFairLaunchAddr(), uint256(-1));

    // free-up execution scope
    _IN_EXEC_LOCK = _NOT_ENTERED;
    POSITION_ID = _NO_ID;
    STRATEGY = _NO_ADDRESS;
  }

  /// @dev Return the pending interest that will be accrued in the next call.
  /// @param value Balance value to subtract off address(this).balance when called from payable functions.
  function pendingInterest(uint256 value) public view returns (uint256) {
    if (now > lastAccrueTime) {
      uint256 timePast = now.sub(lastAccrueTime);
      uint256 balance = SafeToken.myBalance(token).sub(value);
      uint256 ratePerSec = config.getInterestRate(vaultDebtVal, balance);
      return ratePerSec.mul(vaultDebtVal).mul(timePast).div(1e18);
    } else {
      return 0;
    }
  }

  /// @dev Return the Token debt value given the debt share. Be careful of unaccrued interests.
  /// @param debtShare The debt share to be converted.
  function debtShareToVal(uint256 debtShare) public view returns (uint256) {
    if (vaultDebtShare == 0) return debtShare; // When there's no share, 1 share = 1 val.
    return debtShare.mul(vaultDebtVal).div(vaultDebtShare);
  }

  /// @dev Return the debt share for the given debt value. Be careful of unaccrued interests.
  /// @param debtVal The debt value to be converted.
  function debtValToShare(uint256 debtVal) public view returns (uint256) {
    if (vaultDebtShare == 0) return debtVal; // When there's no share, 1 share = 1 val.
    return debtVal.mul(vaultDebtShare).div(vaultDebtVal);
  }

  /// @dev Return Token value and debt of the given position. Be careful of unaccrued interests.
  /// @param id The position ID to query.
  function positionInfo(uint256 id) external view returns (uint256, uint256) {
    Position storage pos = positions[id];
    return (IWorker(pos.worker).health(id), debtShareToVal(pos.debtShare));
  }

  /// @dev Return the total token entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() public view override returns (uint256) {
    return SafeToken.myBalance(token).add(vaultDebtVal).sub(reservePool);
  }

  /// @dev Add more token to the lending pool. Hope to get some good returns.
  function deposit(uint256 amountToken)
    external
    payable
    override
    transferTokenToVault(amountToken)
    accrue(amountToken)
    nonReentrant
  {
    _deposit(amountToken);
  }

  function _deposit(uint256 amountToken) internal {
    uint256 total = totalToken().sub(amountToken);
    uint256 share = total == 0 ? amountToken : amountToken.mul(totalSupply()).div(total);
    _mint(msg.sender, share);
    require(totalSupply() > 1e17, "no tiny shares");
  }

  /// @dev Withdraw token from the lending and burning ibToken.
  function withdraw(uint256 share) external override accrue(0) nonReentrant {
    uint256 amount = share.mul(totalToken()).div(totalSupply());
    _burn(msg.sender, share);
    _safeUnwrap(msg.sender, amount);
    require(totalSupply() > 1e17, "no tiny shares");
  }

  /// @dev Request Funds from user through Vault
  function requestFunds(address targetedToken, uint256 amount) external override inExec {
    SafeToken.safeTransferFrom(targetedToken, positions[POSITION_ID].owner, msg.sender, amount);
  }

  /// @dev Mint & deposit debtToken on behalf of farmers
  /// @param id The ID of the position
  /// @param amount The amount of debt that the position holds
  function _fairLaunchDeposit(uint256 id, uint256 amount) internal {
    if (amount > 0) {
      IDebtToken(debtToken).mint(address(this), amount);
      IFairLaunch(config.getFairLaunchAddr()).deposit(positions[id].owner, fairLaunchPoolId, amount);
    }
  }

  /// @dev Withdraw & burn debtToken on behalf of farmers
  /// @param id The ID of the position
  function _fairLaunchWithdraw(uint256 id) internal {
    if (positions[id].debtShare > 0) {
      // Note: Do this way because we don't want to fail open, close, or kill position
      // if cannot withdraw from FairLaunch somehow. 0xb5c5f672 is a signature of withdraw(address,uint256,uint256)
      (bool success, ) =
        config.getFairLaunchAddr().call(
          abi.encodeWithSelector(0xb5c5f672, positions[id].owner, fairLaunchPoolId, positions[id].debtShare)
        );
      if (success) IDebtToken(debtToken).burn(address(this), positions[id].debtShare);
    }
  }

  /// @dev Transfer to "to". Automatically unwrap if BTOKEN is WBNB
  /// @param to The address of the receiver
  /// @param amount The amount to be withdrawn
  function _safeUnwrap(address to, uint256 amount) internal {
    if (token == config.getWrappedNativeAddr()) {
      SafeToken.safeTransfer(token, config.getWNativeRelayer(), amount);
      IWNativeRelayer(uint160(config.getWNativeRelayer())).withdraw(amount);
      SafeToken.safeTransferETH(to, amount);
    } else {
      SafeToken.safeTransfer(token, to, amount);
    }
  }

  /// @dev addCollateral to the given position.
  /// @param id The ID of the position to add collaterals.
  /// @param amount The amount of BTOKEN to be added to the position
  /// @param goRogue If on skip worker stability check, else only check reserve consistency.
  /// @param data The calldata to pass along to the worker for more working context.
  function addCollateral(
    uint256 id,
    uint256 amount,
    bool goRogue,
    bytes calldata data
  ) external payable onlyEOAorWhitelisted transferTokenToVault(amount) accrue(amount) nonReentrant {
    require(fairLaunchPoolId != uint256(-1), "poolId not set");
    require(id != 0, "no id 0");

    // 1. Load position from state & sanity check
    Position storage pos = positions[id];
    address worker = pos.worker;
    uint256 healthBefore = IWorker(worker).health(id);
    require(id < nextPositionID, "bad position id");
    require(pos.owner == msg.sender, "!position owner");
    require(healthBefore != 0, "!active position");
    // 2. Book execution scope variables. Check if the given strategy is known add strat.
    POSITION_ID = id;
    (STRATEGY, ) = abi.decode(data, (address, bytes));
    require(config.approvedAddStrategies(STRATEGY), "!approved strat");
    // 3. If not goRouge then check worker stability, else only check reserve consistency.
    if (!goRogue) require(config.isWorkerStable(worker), "worker !stable");
    else require(config.isWorkerReserveConsistent(worker), "reserve !consistent");
    // 4. Getting required info.
    uint256 debt = debtShareToVal(pos.debtShare);
    // 5. Perform add collateral according to the strategy.
    uint256 beforeBEP20 = SafeToken.myBalance(token).sub(amount);
    SafeToken.safeTransfer(token, worker, amount);
    IWorker(worker).work(id, msg.sender, debt, data);
    uint256 healthAfter = IWorker(worker).health(id);
    uint256 back = SafeToken.myBalance(token).sub(beforeBEP20);
    // 6. Sanity check states after perform add collaterals
    // - if not goRouge then check worker stability else only check reserve consistency.
    // - back must be 0 as it is adding collateral only. No BTOKEN needed to be returned.
    // - healthAfter must more than before.
    if (!goRogue) require(config.isWorkerStable(worker), "worker !stable");
    else require(config.isWorkerReserveConsistent(worker), "reserve !consistent");
    require(back == 0, "back !0");
    require(healthAfter > healthBefore, "health !increase");
    // 7. Release execution scope
    POSITION_ID = _NO_ID;
    STRATEGY = _NO_ADDRESS;
    // 8. Emit event
    emit AddCollateral(id, amount, healthBefore, healthAfter);
  }

  /// @dev Create a new farming position to unlock your yield farming potential.
  /// @param id The ID of the position to unlock the earning. Use ZERO for new position.
  /// @param worker The address of the authorized worker to work for this position.
  /// @param principalAmount The anout of Token to supply by user.
  /// @param borrowAmount The amount of Token to borrow from the pool.
  /// @param maxReturn The max amount of Token to return to the pool.
  /// @param data The calldata to pass along to the worker for more working context.
  function work(
    uint256 id,
    address worker,
    uint256 principalAmount,
    uint256 borrowAmount,
    uint256 maxReturn,
    bytes calldata data
  ) external payable onlyEOAorWhitelisted transferTokenToVault(principalAmount) accrue(principalAmount) nonReentrant {
    require(fairLaunchPoolId != uint256(-1), "poolId not set");
    // 1. Sanity check the input position, or add a new position of ID is 0.
    Position storage pos;
    if (id == 0) {
      id = nextPositionID++;
      pos = positions[id];
      pos.worker = worker;
      pos.owner = msg.sender;
    } else {
      pos = positions[id];
      require(id < nextPositionID, "bad position id");
      require(pos.worker == worker, "bad position worker");
      require(pos.owner == msg.sender, "not position owner");
      _fairLaunchWithdraw(id);
    }
    emit Work(id, borrowAmount);
    // Update execution scope variables
    POSITION_ID = id;
    (STRATEGY, ) = abi.decode(data, (address, bytes));
    // 2. Make sure the worker can accept more debt and remove the existing debt.
    require(config.isWorker(worker), "not a worker");
    require(borrowAmount == 0 || config.acceptDebt(worker), "worker not accept more debt");
    uint256 debt = _removeDebt(id).add(borrowAmount);
    // 3. Perform the actual work, using a new scope to avoid stack-too-deep errors.
    uint256 back;
    {
      uint256 sendBEP20 = principalAmount.add(borrowAmount);
      require(sendBEP20 <= SafeToken.myBalance(token), "insufficient funds in the vault");
      uint256 beforeBEP20 = SafeToken.myBalance(token).sub(sendBEP20);
      SafeToken.safeTransfer(token, worker, sendBEP20);
      IWorker(worker).work(id, msg.sender, debt, data);
      back = SafeToken.myBalance(token).sub(beforeBEP20);
    }
    // 4. Check and update position debt.
    uint256 lessDebt = Math.min(debt, Math.min(back, maxReturn));
    debt = debt.sub(lessDebt);
    if (debt > 0) {
      require(debt >= config.minDebtSize(), "too small debt size");
      uint256 health = IWorker(worker).health(id);
      uint256 workFactor = config.workFactor(worker, debt);
      require(health.mul(workFactor) >= debt.mul(10000), "bad work factor");
      _addDebt(id, debt);
      _fairLaunchDeposit(id, pos.debtShare);
    }
    // 5. Release execution scope
    POSITION_ID = _NO_ID;
    STRATEGY = _NO_ADDRESS;
    // 6. Return excess token back.
    if (back > lessDebt) {
      _safeUnwrap(msg.sender, back.sub(lessDebt));
    }
  }

  /// @dev Kill the given to the position. Liquidate it immediately if killFactor condition is met.
  /// @param id The position ID to be killed.
  function kill(uint256 id) external onlyEOAorWhitelisted accrue(0) nonReentrant {
    require(fairLaunchPoolId != uint256(-1), "poolId not set");
    // 1. Verify that the position is eligible for liquidation.
    Position storage pos = positions[id];
    require(pos.debtShare > 0, "no debt");
    // 2. Distribute ALPACAs in FairLaunch to owner
    _fairLaunchWithdraw(id);
    uint256 debt = _removeDebt(id);
    uint256 health = IWorker(pos.worker).health(id);
    uint256 killFactor = config.killFactor(pos.worker, debt);
    require(health.mul(killFactor) < debt.mul(10000), "can't liquidate");
    // 3. Perform liquidation and compute the amount of token received.
    uint256 beforeToken = SafeToken.myBalance(token);
    IWorker(pos.worker).liquidate(id);
    uint256 back = SafeToken.myBalance(token).sub(beforeToken);

    uint256 liquidatorPrize = back.mul(config.getKillBps()).div(10000);
    uint256 tresauryFees = back.mul(config.getKillTreasuryBps()).div(10000);
    uint256 prize = liquidatorPrize.add(tresauryFees);
    uint256 rest = back.sub(prize);
    // 4. Clear position debt and return funds to liquidator and position owner.
    if (liquidatorPrize > 0) {
      _safeUnwrap(msg.sender, liquidatorPrize);
    }

    if (tresauryFees > 0) {
      _safeUnwrap(config.getTreasuryAddr(), tresauryFees);
    }

    uint256 left = rest > debt ? rest - debt : 0;
    if (left > 0) {
      _safeUnwrap(pos.owner, left);
    }

    emit Kill(id, msg.sender, pos.owner, health, debt, prize, left);
  }

  /// @dev Internal function to add the given debt value to the given position.
  function _addDebt(uint256 id, uint256 debtVal) internal {
    Position storage pos = positions[id];
    uint256 debtShare = debtValToShare(debtVal);
    pos.debtShare = pos.debtShare.add(debtShare);
    vaultDebtShare = vaultDebtShare.add(debtShare);
    vaultDebtVal = vaultDebtVal.add(debtVal);
    emit AddDebt(id, debtShare);
  }

  /// @dev Internal function to clear the debt of the given position. Return the debt value.
  function _removeDebt(uint256 id) internal returns (uint256) {
    Position storage pos = positions[id];
    uint256 debtShare = pos.debtShare;
    if (debtShare > 0) {
      uint256 debtVal = debtShareToVal(debtShare);
      pos.debtShare = 0;
      vaultDebtShare = vaultDebtShare.sub(debtShare);
      vaultDebtVal = vaultDebtVal.sub(debtVal);
      emit RemoveDebt(id, debtShare);
      return debtVal;
    } else {
      return 0;
    }
  }

  /// @dev Update bank configuration to a new address. Must only be called by owner.
  /// @param _config The new configurator address.
  function updateConfig(IVaultConfig _config) external onlyOwner {
    config = _config;
  }

  function setFairLaunchPoolId(uint256 _poolId) external onlyOwner {
    SafeToken.safeApprove(debtToken, config.getFairLaunchAddr(), uint256(-1));
    fairLaunchPoolId = _poolId;
  }

  /// @dev Withdraw BaseToken reserve for underwater positions to the given address.
  /// @param to The address to transfer BaseToken to.
  /// @param value The number of BaseToken tokens to withdraw. Must not exceed `reservePool`.
  function withdrawReserve(address to, uint256 value) external onlyOwner nonReentrant {
    reservePool = reservePool.sub(value);
    SafeToken.safeTransfer(token, to, value);
  }

  /// @dev Reduce BaseToken reserve, effectively giving them to the depositors.
  /// @param value The number of BaseToken reserve to reduce.
  function reduceReserve(uint256 value) external onlyOwner {
    reservePool = reservePool.sub(value);
  }

  /// @dev Fallback function to accept BNB.
  receive() external payable {}
}