// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/IERC20.sol";
import "../interface/IStrategy.sol";
import "../interface/IStrategySplitter.sol";
import "../interface/ISmartVault.sol";
import "../interface/IFeeRewardForwarder.sol";
import "../interface/IBookkeeper.sol";
import "../interface/IUpgradeSource.sol";
import "../interface/IFundKeeper.sol";
import "../interface/ITetuProxy.sol";
import "../interface/IMintHelper.sol";
import "../interface/IAnnouncer.sol";
import "../interface/IBalancingStrategy.sol";
import "./ControllerStorage.sol";
import "./Controllable.sol";

/// @title A central contract for control everything.
///        Governance should be a Multi-Sig Wallet
/// @dev Use with TetuProxy
/// @author belbix
contract Controller is Initializable, Controllable, ControllerStorage {
  using SafeERC20 for IERC20;
  using Address for address;

  // ************ VARIABLES **********************
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.4.0";

  /// @dev Allowed contracts for deposit to vaults
  mapping(address => bool) public override whiteList;
  /// @dev Registered vaults
  mapping(address => bool) public override vaults;
  /// @dev Registered strategies
  mapping(address => bool) public override strategies;
  /// @dev Allowed address for do maintenance work
  mapping(address => bool) public hardWorkers;
  /// @dev Allowed address for reward distributing
  mapping(address => bool) public rewardDistribution;
  /// @dev Allowed address for getting 100% rewards without vesting
  mapping(address => bool) public pureRewardConsumers;

  // ************ EVENTS **********************

  /// @notice HardWorker added
  event HardWorkerAdded(address value);
  /// @notice HardWorker removed
  event HardWorkerRemoved(address value);
  /// @notice Contract whitelist status changed
  event WhiteListStatusChanged(address target, bool status);
  /// @notice Vault and Strategy pair registered
  event VaultAndStrategyAdded(address vault, address strategy);
  /// @notice Tokens moved from Controller contract to Governance
  event ControllerTokenMoved(address indexed recipient, address indexed token, uint256 amount);
  /// @notice Tokens moved from Strategy contract to Governance
  event StrategyTokenMoved(address indexed strategy, address indexed token, uint256 amount);
  /// @notice Tokens moved from Fund contract to Controller
  event FundKeeperTokenMoved(address indexed fund, address indexed token, uint256 amount);
  /// @notice DoHardWork completed and PricePerFullShare changed
  event SharePriceChangeLog(
    address indexed vault,
    address indexed strategy,
    uint256 oldSharePrice,
    uint256 newSharePrice,
    uint256 timestamp
  );
  event VaultStrategyChanged(address vault, address oldStrategy, address newStrategy);
  event ProxyUpgraded(address target, address oldLogic, address newLogic);
  event Minted(
    address mintHelper,
    uint totalAmount,
    address distributor,
    address otherNetworkFund,
    bool mintAllAvailable
  );
  event DistributorChanged(address distributor);

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  ///      Initialize Controllable with sender address
  ///      Setup default values for PS and Fund ratio
  function initialize() external initializer {
    Controllable.initializeControllable(address(this));
    ControllerStorage.initializeControllerStorage(
      msg.sender
    );
    // 100% by default
    setPSNumeratorDenominator(1000, 1000);
    // 10% by default
    setFundNumeratorDenominator(100, 1000);
  }

  // ************* MODIFIERS AND FUNCTIONS FOR STRICT ACCESS ********************

  /// @dev Operations allowed only for Governance address
  function onlyGovernance() view private {
    require(_governance() == msg.sender, "C: Not governance");
  }

  /// @dev Operations allowed for Governance or Dao addresses
  function onlyGovernanceOrDao() view private {
    require(_governance() == msg.sender || _dao() == msg.sender, "C: Not governance or dao");
  }

  /// @dev Operation should be announced (exist in timeLockSchedule map) or new value
  function timeLock(
    bytes32 opHash,
    IAnnouncer.TimeLockOpCodes opCode,
    bool isEmptyValue,
    address target
  ) private {
    // empty values setup without time-lock
    if (!isEmptyValue) {
      require(_announcer() != address(0), "C: Zero announcer");
      require(IAnnouncer(_announcer()).timeLockSchedule(opHash) > 0, "C: Not announced");
      require(IAnnouncer(_announcer()).timeLockSchedule(opHash) < block.timestamp, "C: Too early");
      IAnnouncer(_announcer()).clearAnnounce(opHash, opCode, target);
    }
  }

  // ************ GOVERNANCE ACTIONS **************************


  //  ---------------------- TIME-LOCK ACTIONS --------------------------

  /// @notice Only Governance can do it. Set announced strategies for given vaults
  /// @param _vaults Vault addresses
  /// @param _strategies Strategy addresses
  function setVaultStrategyBatch(address[] calldata _vaults, address[] calldata _strategies) external {
    onlyGovernance();
    require(_vaults.length == _strategies.length, "C: Wrong arrays");
    for (uint256 i = 0; i < _vaults.length; i++) {
      _setVaultStrategy(_vaults[i], _strategies[i]);
    }
  }

  /// @notice Only Governance can do it. Set announced strategy for given vault
  /// @param _target Vault address
  /// @param _strategy Strategy address
  function _setVaultStrategy(address _target, address _strategy) private {
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.StrategyUpgrade, _target, _strategy)),
      IAnnouncer.TimeLockOpCodes.StrategyUpgrade,
      ISmartVault(_target).strategy() == address(0),
      _target
    );
    emit VaultStrategyChanged(_target, ISmartVault(_target).strategy(), _strategy);
    ISmartVault(_target).setStrategy(_strategy);
  }

  function addStrategiesToSplitter(address _splitter, address[] calldata _strategies) external {
    onlyGovernance();
    for (uint256 i = 0; i < _strategies.length; i++) {
      _addStrategyToSplitter(_splitter, _strategies[i]);
    }
  }

  /// @notice Only Governance can do it. Add new strategy to given splitter
  function _addStrategyToSplitter(address _splitter, address _strategy) internal {
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.StrategyUpgrade, _splitter, _strategy)),
      IAnnouncer.TimeLockOpCodes.StrategyUpgrade,
      !IStrategySplitter(_splitter).strategiesInited(),
      _splitter
    );
    IStrategySplitter(_splitter).addStrategy(_strategy);
    rewardDistribution[_strategy] = true;
    if (!strategies[_strategy]) {
      strategies[_strategy] = true;
      IBookkeeper(_bookkeeper()).addStrategy(_strategy);
    }
  }

  /// @notice Only Governance can do it. Upgrade batch announced proxies
  /// @param _contracts Array of Proxy contract addresses for upgrade
  /// @param _implementations Array of New implementation addresses
  function upgradeTetuProxyBatch(
    address[] calldata _contracts,
    address[] calldata _implementations
  ) external {
    onlyGovernance();
    require(_contracts.length == _implementations.length, "wrong arrays");
    for (uint256 i = 0; i < _contracts.length; i++) {
      _upgradeTetuProxy(_contracts[i], _implementations[i]);
    }
  }

  /// @notice Only Governance can do it. Upgrade announced proxy
  /// @param _contract Proxy contract address for upgrade
  /// @param _implementation New implementation address
  function _upgradeTetuProxy(address _contract, address _implementation) private {
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.TetuProxyUpdate, _contract, _implementation)),
      IAnnouncer.TimeLockOpCodes.TetuProxyUpdate,
      false,
      _contract
    );
    emit ProxyUpgraded(_contract, ITetuProxy(_contract).implementation(), _implementation);
    ITetuProxy(_contract).upgrade(_implementation);
  }

  /// @notice Only Governance can do it. Call announced mint
  /// @param totalAmount Total amount to mint.
  ///                    33% will go to current network, 67% to FundKeeper for other networks
  /// @param mintAllAvailable if true instead of amount will be used maxTotalSupplyForCurrentBlock - totalSupply
  function mintAndDistribute(
    uint256 totalAmount,
    bool mintAllAvailable
  ) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.Mint, totalAmount, distributor(), fund(), mintAllAvailable)),
      IAnnouncer.TimeLockOpCodes.Mint,
      false,
      address(0)
    );
    require(distributor() != address(0), "C: Zero distributor");
    require(fund() != address(0), "C: Zero fund");
    IMintHelper(mintHelper()).mintAndDistribute(totalAmount, distributor(), fund(), mintAllAvailable);
    emit Minted(mintHelper(), totalAmount, distributor(), fund(), mintAllAvailable);
  }

  //  ---------------------- TIME-LOCK ADDRESS CHANGE --------------------------

  /// @notice Only Governance can do it. Change governance address.
  /// @param newValue New governance address
  function setGovernance(address newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.Governance, newValue)),
      IAnnouncer.TimeLockOpCodes.Governance,
      _governance() == address(0),
      address(0)
    );
    _setGovernance(newValue);
  }

  /// @notice Only Governance can do it. Change DAO address.
  /// @param newValue New DAO address
  function setDao(address newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.Dao, newValue)),
      IAnnouncer.TimeLockOpCodes.Dao,
      _dao() == address(0),
      address(0)
    );
    _setDao(newValue);
  }

  /// @notice Only Governance can do it. Change FeeRewardForwarder address.
  /// @param _feeRewardForwarder New FeeRewardForwarder address
  function setFeeRewardForwarder(address _feeRewardForwarder) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.FeeRewardForwarder, _feeRewardForwarder)),
      IAnnouncer.TimeLockOpCodes.FeeRewardForwarder,
      feeRewardForwarder() == address(0),
      address(0)
    );
    rewardDistribution[feeRewardForwarder()] = false;
    _setFeeRewardForwarder(_feeRewardForwarder);
    rewardDistribution[feeRewardForwarder()] = true;
  }

  /// @notice Only Governance can do it. Change Bookkeeper address.
  /// @param newValue New Bookkeeper address
  function setBookkeeper(address newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.Bookkeeper, newValue)),
      IAnnouncer.TimeLockOpCodes.Bookkeeper,
      _bookkeeper() == address(0),
      address(0)
    );
    _setBookkeeper(newValue);
  }

  /// @notice Only Governance can do it. Change MintHelper address.
  /// @param _newValue New MintHelper address
  function setMintHelper(address _newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.MintHelper, _newValue)),
      IAnnouncer.TimeLockOpCodes.MintHelper,
      mintHelper() == address(0),
      address(0)
    );
    _setMintHelper(_newValue);
    // for reduce the chance of DoS check new implementation
    require(IMintHelper(mintHelper()).devFundsList(0) != address(0), "C: Wrong");
  }

  /// @notice Only Governance can do it. Change RewardToken(TETU) address.
  /// @param _newValue New RewardToken address
  function setRewardToken(address _newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.RewardToken, _newValue)),
      IAnnouncer.TimeLockOpCodes.RewardToken,
      rewardToken() == address(0),
      address(0)
    );
    _setRewardToken(_newValue);
  }

  /// @notice Only Governance can do it. Change FundToken(USDC by default) address.
  /// @param _newValue New FundToken address
  function setFundToken(address _newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.FundToken, _newValue)),
      IAnnouncer.TimeLockOpCodes.FundToken,
      fundToken() == address(0),
      address(0)
    );
    _setFundToken(_newValue);
  }

  /// @notice Only Governance can do it. Change ProfitSharing vault address.
  /// @param _newValue New ProfitSharing vault address
  function setPsVault(address _newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.PsVault, _newValue)),
      IAnnouncer.TimeLockOpCodes.PsVault,
      psVault() == address(0),
      address(0)
    );
    _setPsVault(_newValue);
  }

  /// @notice Only Governance can do it. Change FundKeeper address.
  /// @param _newValue New FundKeeper address
  function setFund(address _newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.Fund, _newValue)),
      IAnnouncer.TimeLockOpCodes.Fund,
      fund() == address(0),
      address(0)
    );
    _setFund(_newValue);
  }

  /// @notice Only Governance can do it. Change Announcer address.
  ///         Has dedicated time-lock logic for avoiding collisions.
  /// @param _newValue New Announcer address
  function setAnnouncer(address _newValue) external {
    onlyGovernance();
    bytes32 opHash = keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.Announcer, _newValue));
    if (_announcer() != address(0)) {
      require(IAnnouncer(_announcer()).timeLockSchedule(opHash) > 0, "C: Not announced");
      require(IAnnouncer(_announcer()).timeLockSchedule(opHash) < block.timestamp, "C: Too early");
    }

    _setAnnouncer(_newValue);
    // clear announce after update not necessary

    // check new announcer implementation for reducing the chance of DoS
    IAnnouncer.TimeLockInfo memory info = IAnnouncer(_announcer()).timeLockInfo(0);
    require(info.opCode == IAnnouncer.TimeLockOpCodes.ZeroPlaceholder, "C: Wrong");
  }

  /// @notice Only Governance can do it. Change FundKeeper address.
  /// @param _newValue New FundKeeper address
  function setVaultController(address _newValue) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.VaultController, _newValue)),
      IAnnouncer.TimeLockOpCodes.VaultController,
      vaultController() == address(0),
      address(0)
    );
    _setVaultController(_newValue);
  }

  // ------------------ TIME-LOCK RATIO CHANGE -------------------

  /// @notice Only Governance or DAO can do it. Change Profit Sharing fee ratio.
  ///         numerator/denominator = ratio
  /// @param numerator Ratio numerator. Should be less than denominator
  /// @param denominator Ratio denominator. Should be greater than zero
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) public override {
    onlyGovernanceOrDao();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.PsRatio, numerator, denominator)),
      IAnnouncer.TimeLockOpCodes.PsRatio,
      psNumerator() == 0 && psDenominator() == 0,
      address(0)
    );
    _setPsNumerator(numerator);
    _setPsDenominator(denominator);
  }

  /// @notice Only Governance or DAO can do it. Change Fund fee ratio.
  ///         numerator/denominator = ratio
  /// @param numerator Ratio numerator. Should be less than denominator
  /// @param denominator Ratio denominator. Should be greater than zero
  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) public override {
    onlyGovernanceOrDao();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.FundRatio, numerator, denominator)),
      IAnnouncer.TimeLockOpCodes.FundRatio,
      fundNumerator() == 0 && fundDenominator() == 0,
      address(0)
    );
    _setFundNumerator(numerator);
    _setFundDenominator(denominator);
  }

  // ------------------ TIME-LOCK SALVAGE -------------------

  /// @notice Only Governance can do it. Transfer token from this contract to governance address
  /// @param _recipient Recipient address
  /// @param _token Token address
  /// @param _amount Token amount
  function controllerTokenMove(address _recipient, address _token, uint256 _amount) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.ControllerTokenMove, _recipient, _token, _amount)),
      IAnnouncer.TimeLockOpCodes.ControllerTokenMove,
      false,
      address(0)
    );
    IERC20(_token).safeTransfer(_recipient, _amount);
    emit ControllerTokenMoved(_recipient, _token, _amount);
  }

  /// @notice Only Governance can do it. Transfer token from strategy to governance address
  /// @param _strategy Strategy address
  /// @param _token Token address
  /// @param _amount Token amount
  function strategyTokenMove(address _strategy, address _token, uint256 _amount) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.StrategyTokenMove, _strategy, _token, _amount)),
      IAnnouncer.TimeLockOpCodes.StrategyTokenMove,
      false,
      address(0)
    );
    // the strategy is responsible for maintaining the list of
    // salvagable tokens, to make sure that governance cannot come
    // in and take away the coins
    IStrategy(_strategy).salvage(_governance(), _token, _amount);
    emit StrategyTokenMoved(_strategy, _token, _amount);
  }

  /// @notice Only Governance can do it. Transfer token from FundKeeper to controller
  /// @param _fund FundKeeper address
  /// @param _token Token address
  /// @param _amount Token amount
  function fundKeeperTokenMove(address _fund, address _token, uint256 _amount) external {
    onlyGovernance();
    timeLock(
      keccak256(abi.encode(IAnnouncer.TimeLockOpCodes.FundTokenMove, _fund, _token, _amount)),
      IAnnouncer.TimeLockOpCodes.FundTokenMove,
      false,
      address(0)
    );
    IFundKeeper(_fund).withdrawToController(_token, _amount);
    emit FundKeeperTokenMoved(_fund, _token, _amount);
  }

  // ---------------- NO TIME_LOCK --------------------------

  /// @notice Only Governance can do it. Set reward distributor address.
  ///         Distributor is a part of not critical infrastructure contracts and not require time-lock
  /// @param _distributor New distributor address
  function setDistributor(address _distributor) external {
    onlyGovernance();
    require(_distributor != address(0));
    _setDistributor(_distributor);
    emit DistributorChanged(_distributor);
  }

  /// @notice Only Governance can do it. Add/Remove Reward Distributor address
  /// @param _newRewardDistribution Reward Distributor's addresses
  /// @param _flag Reward Distributor's flags - true active, false deactivated
  function setRewardDistribution(address[] calldata _newRewardDistribution, bool _flag) external {
    onlyGovernance();
    for (uint256 i = 0; i < _newRewardDistribution.length; i++) {
      rewardDistribution[_newRewardDistribution[i]] = _flag;
    }
  }

  /// @notice Only Governance can do it. Allow given addresses claim rewards without any penalty
  function setPureRewardConsumers(address[] calldata _targets, bool _flag) external {
    onlyGovernance();
    for (uint256 i = 0; i < _targets.length; i++) {
      pureRewardConsumers[_targets[i]] = _flag;
    }
  }

  /// @notice Only Governance can do it. Add HardWorker address.
  /// @param _worker New HardWorker address
  function addHardWorker(address _worker) external {
    onlyGovernance();
    require(_worker != address(0));
    hardWorkers[_worker] = true;
    emit HardWorkerAdded(_worker);
  }

  /// @notice Only Governance can do it. Remove HardWorker address.
  /// @param _worker Exist HardWorker address
  function removeHardWorker(address _worker) external {
    onlyGovernance();
    require(_worker != address(0));
    hardWorkers[_worker] = false;
    emit HardWorkerRemoved(_worker);
  }

  /// @notice Only Governance or DAO can do it. Add to whitelist an array of addresses
  /// @param _targets An array of contracts
  function changeWhiteListStatus(address[] calldata _targets, bool status) external override {
    onlyGovernanceOrDao();
    for (uint256 i = 0; i < _targets.length; i++) {
      whiteList[_targets[i]] = status;
      emit WhiteListStatusChanged(_targets[i], status);
    }
  }

  /// @notice Only Governance can do it. Register pairs Vault/Strategy
  /// @param _vaults Vault addresses
  /// @param _strategies Strategy addresses
  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external override {
    onlyGovernance();
    require(_vaults.length == _strategies.length, "arrays wrong length");
    for (uint256 i = 0; i < _vaults.length; i++) {
      _addVaultAndStrategy(_vaults[i], _strategies[i]);
    }
  }

  /// @notice Only Governance can do it. Register a pair Vault/Strategy
  /// @param _vault Vault addresses
  /// @param _strategy Strategy addresses
  function _addVaultAndStrategy(address _vault, address _strategy) private {
    require(_vault != address(0), "new vault shouldn't be empty");
    require(!vaults[_vault], "vault already exists");
    require(!strategies[_strategy], "strategy already exists");
    require(_strategy != address(0), "new strategy must not be empty");
    require(IControllable(_vault).isController(address(this)));

    vaults[_vault] = true;
    IBookkeeper(_bookkeeper()).addVault(_vault);

    // adding happens while setting
    _setVaultStrategy(_vault, _strategy);
    emit VaultAndStrategyAdded(_vault, _strategy);
  }

  /// @notice Only Vault can do it. Register Strategy. Vault call it when gov set a strategy
  /// @param _strategy Strategy addresses
  function addStrategy(address _strategy) external override {
    require(vaults[msg.sender], "C: Not vault");
    if (!strategies[_strategy]) {
      strategies[_strategy] = true;
      IBookkeeper(_bookkeeper()).addStrategy(_strategy);
    }
  }

  /// @notice Only Governance or HardWorker can do it. Call doHardWork from given Vault
  /// @param _vault Vault addresses
  function doHardWork(address _vault) external {
    require(hardWorkers[msg.sender] || isGovernance(msg.sender), "C: Not hardworker or governance");
    require(vaults[_vault], "C: Not vault");
    uint256 oldSharePrice = ISmartVault(_vault).getPricePerFullShare();
    ISmartVault(_vault).doHardWork();
    emit SharePriceChangeLog(
      _vault,
      ISmartVault(_vault).strategy(),
      oldSharePrice,
      ISmartVault(_vault).getPricePerFullShare(),
      block.timestamp
    );
  }

  /// @notice Only HardWorker can do it. Call rebalanceAllPipes for given Strategy (AMB Platform)
  /// @param _strategy Vault addresses
  function rebalance(address _strategy) external override {
    require(hardWorkers[msg.sender], "C: Not hardworker");
    require(strategies[_strategy], "C: Not strategy");
    IBalancingStrategy(_strategy).rebalanceAllPipes();
  }

  // ***************** EXTERNAL *******************************

  /// @notice Return true if the given address is DAO
  /// @param _adr Address for check
  /// @return true if it is a DAO address
  function isDao(address _adr) external view override returns (bool) {
    return _dao() == _adr;
  }

  /// @notice Return true if the given address is a HardWorker or Governance
  /// @param _adr Address for check
  /// @return true if it is a HardWorker or Governance
  function isHardWorker(address _adr) external override view returns (bool) {
    return hardWorkers[_adr] || _governance() == _adr;
  }

  /// @notice Return true if the given address is a Reward Distributor or Governance or Strategy
  /// @param _adr Address for check
  /// @return true if it is a Reward Distributor or Governance or Strategy
  function isRewardDistributor(address _adr) external override view returns (bool) {
    return rewardDistribution[_adr] || _governance() == _adr || strategies[_adr];
  }

  /// @notice Return true if the given address is allowed for claim rewards without penalties
  function isPoorRewardConsumer(address _adr) external override view returns (bool) {
    return pureRewardConsumers[_adr];
  }

  /// @notice Return true if the given address:
  ///         - not smart contract
  ///         - added to whitelist
  ///         - governance address
  ///         - hardworker
  ///         - reward distributor
  ///         - registered vault
  ///         - registered strategy
  /// @param _adr Address for check
  /// @return true if the address allowed
  function isAllowedUser(address _adr) external view override returns (bool) {
    return isNotSmartContract(_adr)
    || whiteList[_adr]
    || _governance() == _adr
    || hardWorkers[_adr]
    || rewardDistribution[_adr]
    || pureRewardConsumers[_adr]
    || vaults[_adr]
    || strategies[_adr];
  }

  /// @notice Return true if given address is not smart contract but wallet address
  /// @dev it is not 100% guarantee after EIP-3074 implementation
  ///       use it as an additional check
  /// @param _adr Address for check
  /// @return true if the address is a wallet
  function isNotSmartContract(address _adr) private view returns (bool) {
    return _adr == tx.origin;
  }

  /// @notice Return true if the given address is registered vault
  /// @param _vault Address for check
  /// @return true if it is a registered vault
  function isValidVault(address _vault) external override view returns (bool) {
    return vaults[_vault];
  }

  /// @notice Return true if the given address is registered strategy
  /// @param _strategy Address for check
  /// @return true if it is a registered strategy
  function isValidStrategy(address _strategy) external override view returns (bool) {
    return strategies[_strategy];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
  unchecked {
    uint256 oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint256 newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IStrategy {

  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP, // 12
    SPOOKY, // 13
    AAVE_LEND, //14
    AAVE_MAI_BAL, // 15
    GEIST, //16
    HARVEST, //17
    SCREAM_LEND, //18
    KLIMA, //19
    VESQ, //20
    QIDAO, //21
    SUNFLOWER, //22
    NACHO, //23
    STRATEGY_SPLITTER, //24
    TOMB, //25
    TAROT //26
  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function pauseInvesting() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (Platform);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IStrategySplitter {

  function strategies(uint idx) external view returns (address);

  function strategiesRatios(address strategy) external view returns (uint);

  function withdrawRequestsCalls(address user) external view returns (uint);

  function addStrategy(address _strategy) external;

  function removeStrategy(address _strategy) external;

  function setStrategyRatios(address[] memory _strategies, uint[] memory _ratios) external;

  function strategiesInited() external view returns (bool);

  function needRebalance() external view returns (uint);

  function wantToWithdraw() external view returns (uint);

  function maxCheapWithdraw() external view returns (uint);

  function strategiesLength() external view returns (uint);

  function allStrategies() external view returns (address[] memory);

  function strategyRewardTokens() external view returns (address[] memory);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function changeActivityStatus(bool _active) external;

  function changeProtectionMode(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function setLockPeriod(uint256 _value) external;

  function setLockPenalty(uint256 _value) external;

  function setToInvest(uint256 _value) external;

  function doHardWork() external;

  function rebalance() external;

  function disableLock() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);

  function userLastWithdrawTs(address _user) external view returns (uint256);

  function userLastDepositTs(address _user) external view returns (uint256);

  function userBoostTs(address _user) external view returns (uint256);

  function userLockTs(address _user) external view returns (uint256);

  function addRewardToken(address rt) external;

  function removeRewardToken(address rt) external;

  function stop() external;

  function ppfsDecreaseAllowed() external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function lockPenalty() external view returns (uint256);

  function toInvest() external view returns (uint256);

  function depositFeeNumerator() external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IFeeRewardForwarder {
  function distribute(uint256 _amount, address _token, address _vault) external returns (uint256);

  function notifyPsPool(address _token, uint256 _amount) external returns (uint256);

  function notifyCustomPool(address _token, address _rewardPool, uint256 _maxBuyback) external returns (uint256);

  function liquidate(address tokenIn, address tokenOut, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerFundKeeperEarned(address _token, uint256 _fundTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerVaultTransfer(address from, address to, uint256 amount) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function registerRewardDistribution(address vault, address token, uint256 amount) external;

  function vaults() external view returns (address[] memory);

  function vaultsLength() external view returns (uint256);

  function strategies() external view returns (address[] memory);

  function strategiesLength() external view returns (uint256);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  /// @notice Return total earned TETU tokens for strategy
  /// @dev Should be incremented after strategy rewards distribution
  /// @param strategy Strategy address
  /// @return Earned TETU tokens
  function targetTokenEarned(address strategy) external view returns (uint256);

  /// @notice Return share(xToken) balance of given user
  /// @dev Should be calculated for each xToken transfer
  /// @param vault Vault address
  /// @param user User address
  /// @return User share (xToken) balance
  function vaultUsersBalances(address vault, address user) external view returns (uint256);

  /// @notice Return earned token amount for given token and user
  /// @dev Fills when user claim rewards
  /// @param user User address
  /// @param vault Vault address
  /// @param token Token address
  /// @return User's earned tokens amount
  function userEarned(address user, address vault, address token) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  /// @notice Return users quantity for given Vault
  /// @dev Calculation based in Bookkeeper user balances
  /// @param vault Vault address
  /// @return Users quantity
  function vaultUsersQuantity(address vault) external view returns (uint256);

  function fundKeeperEarned(address vault) external view returns (uint256);

  function vaultRewards(address vault, address token, uint256 idx) external view returns (uint256);

  function vaultRewardsLength(address vault, address token) external view returns (uint256);

  function strategyEarnedSnapshots(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsTime(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsLength(address strategy) external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IUpgradeSource {

  function scheduleUpgrade(address impl) external;

  function finalizeUpgrade() external;

  function shouldUpgrade() external view returns (bool, address);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IFundKeeper {

  function withdrawToController(address _token, uint256 amount) external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ITetuProxy {

  function upgrade(address _newImplementation) external;

  function implementation() external returns (address);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IMintHelper {

  function mintAndDistribute(
    uint256 totalAmount,
    address _distributor,
    address _otherNetworkFund,
    bool mintAllAvailable
  ) external;

  function devFundsList(uint256 idx) external returns (address);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IAnnouncer {

  /// @dev Time lock operation codes
  enum TimeLockOpCodes {
    // TimeLockedAddresses
    Governance, // 0
    Dao, // 1
    FeeRewardForwarder, // 2
    Bookkeeper, // 3
    MintHelper, // 4
    RewardToken, // 5
    FundToken, // 6
    PsVault, // 7
    Fund, // 8
    // TimeLockedRatios
    PsRatio, // 9
    FundRatio, // 10
    // TimeLockedTokenMoves
    ControllerTokenMove, // 11
    StrategyTokenMove, // 12
    FundTokenMove, // 13
    // Other
    TetuProxyUpdate, // 14
    StrategyUpgrade, // 15
    Mint, // 16
    Announcer, // 17
    ZeroPlaceholder, //18
    VaultController, //19
    RewardBoostDuration, //20
    RewardRatioWithoutBoost, //21
    VaultStop //22
  }

  /// @dev Holder for human readable info
  struct TimeLockInfo {
    TimeLockOpCodes opCode;
    bytes32 opHash;
    address target;
    address[] adrValues;
    uint256[] numValues;
  }

  function clearAnnounce(bytes32 opHash, TimeLockOpCodes opCode, address target) external;

  function timeLockSchedule(bytes32 opHash) external returns (uint256);

  function timeLockInfo(uint256 idx) external returns (TimeLockInfo memory);

  // ************ DAO ACTIONS *************
  function announceRatioChange(TimeLockOpCodes opCode, uint256 numerator, uint256 denominator) external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IBalancingStrategy {

  function rebalanceAllPipes() external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";

/// @title Eternal storage + getters and setters pattern
/// @dev If you will change a key value it will require setup it again
/// @author belbix
abstract contract ControllerStorage is Initializable, IController {

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;

  /// @notice Address changed the variable with `name`
  event UpdatedAddressSlot(string indexed name, address oldValue, address newValue);
  /// @notice Value changed the variable with `name`
  event UpdatedUint256Slot(string indexed name, uint256 oldValue, uint256 newValue);

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  /// @param __governance Governance address
  function initializeControllerStorage(
    address __governance
  ) public initializer {
    _setGovernance(__governance);
  }

  // ******************* SETTERS AND GETTERS **********************

  // ----------- ADDRESSES ----------
  function _setGovernance(address _address) internal {
    emit UpdatedAddressSlot("governance", _governance(), _address);
    setAddress("governance", _address);
  }

  /// @notice Return governance address
  /// @return Governance address
  function governance() external override view returns (address) {
    return _governance();
  }

  function _governance() internal view returns (address) {
    return getAddress("governance");
  }

  function _setDao(address _address) internal {
    emit UpdatedAddressSlot("dao", _dao(), _address);
    setAddress("dao", _address);
  }

  /// @notice Return DAO address
  /// @return DAO address
  function dao() external override view returns (address) {
    return _dao();
  }

  function _dao() internal view returns (address) {
    return getAddress("dao");
  }

  function _setFeeRewardForwarder(address _address) internal {
    emit UpdatedAddressSlot("feeRewardForwarder", feeRewardForwarder(), _address);
    setAddress("feeRewardForwarder", _address);
  }

  /// @notice Return FeeRewardForwarder address
  /// @return FeeRewardForwarder address
  function feeRewardForwarder() public override view returns (address) {
    return getAddress("feeRewardForwarder");
  }

  function _setBookkeeper(address _address) internal {
    emit UpdatedAddressSlot("bookkeeper", _bookkeeper(), _address);
    setAddress("bookkeeper", _address);
  }

  /// @notice Return Bookkeeper address
  /// @return Bookkeeper address
  function bookkeeper() external override view returns (address) {
    return _bookkeeper();
  }

  function _bookkeeper() internal view returns (address) {
    return getAddress("bookkeeper");
  }

  function _setMintHelper(address _address) internal {
    emit UpdatedAddressSlot("mintHelper", mintHelper(), _address);
    setAddress("mintHelper", _address);
  }

  /// @notice Return MintHelper address
  /// @return MintHelper address
  function mintHelper() public override view returns (address) {
    return getAddress("mintHelper");
  }

  function _setRewardToken(address _address) internal {
    emit UpdatedAddressSlot("rewardToken", rewardToken(), _address);
    setAddress("rewardToken", _address);
  }

  /// @notice Return TETU address
  /// @return TETU address
  function rewardToken() public override view returns (address) {
    return getAddress("rewardToken");
  }

  function _setFundToken(address _address) internal {
    emit UpdatedAddressSlot("fundToken", fundToken(), _address);
    setAddress("fundToken", _address);
  }

  /// @notice Return a token address used for FundKeeper
  /// @return FundKeeper's main token address
  function fundToken() public override view returns (address) {
    return getAddress("fundToken");
  }

  function _setPsVault(address _address) internal {
    emit UpdatedAddressSlot("psVault", psVault(), _address);
    setAddress("psVault", _address);
  }

  /// @notice Return Profit Sharing pool address
  /// @return Profit Sharing pool address
  function psVault() public override view returns (address) {
    return getAddress("psVault");
  }

  function _setFund(address _address) internal {
    emit UpdatedAddressSlot("fund", fund(), _address);
    setAddress("fund", _address);
  }

  /// @notice Return FundKeeper address
  /// @return FundKeeper address
  function fund() public override view returns (address) {
    return getAddress("fund");
  }

  function _setDistributor(address _address) internal {
    emit UpdatedAddressSlot("distributor", distributor(), _address);
    setAddress("distributor", _address);
  }

  /// @notice Return Reward distributor address
  /// @return Distributor address
  function distributor() public override view returns (address) {
    return getAddress("distributor");
  }

  function _setAnnouncer(address _address) internal {
    emit UpdatedAddressSlot("announcer", _announcer(), _address);
    setAddress("announcer", _address);
  }

  /// @notice Return Announcer address
  /// @return Announcer address
  function announcer() external override view returns (address) {
    return _announcer();
  }

  function _announcer() internal view returns (address) {
    return getAddress("announcer");
  }

  function _setVaultController(address _address) internal {
    emit UpdatedAddressSlot("vaultController", vaultController(), _address);
    setAddress("vaultController", _address);
  }

  /// @notice Return FundKeeper address
  /// @return FundKeeper address
  function vaultController() public override view returns (address) {
    return getAddress("vaultController");
  }

  // ----------- INTEGERS ----------
  function _setPsNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("psNumerator", psNumerator(), _value);
    setUint256("psNumerator", _value);
  }

  /// @notice Return Profit Sharing pool ratio's numerator
  /// @return Profit Sharing pool ratio numerator
  function psNumerator() public view override returns (uint256) {
    return getUint256("psNumerator");
  }

  function _setPsDenominator(uint256 _value) internal {
    emit UpdatedUint256Slot("psDenominator", psDenominator(), _value);
    setUint256("psDenominator", _value);
  }

  /// @notice Return Profit Sharing pool ratio's denominator
  /// @return Profit Sharing pool ratio denominator
  function psDenominator() public view override returns (uint256) {
    return getUint256("psDenominator");
  }

  function _setFundNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("fundNumerator", fundNumerator(), _value);
    setUint256("fundNumerator", _value);
  }

  /// @notice Return FundKeeper ratio's numerator
  /// @return FundKeeper ratio numerator
  function fundNumerator() public view override returns (uint256) {
    return getUint256("fundNumerator");
  }

  function _setFundDenominator(uint256 _value) internal {
    emit UpdatedUint256Slot("fundDenominator", fundDenominator(), _value);
    setUint256("fundDenominator", _value);
  }

  /// @notice Return FundKeeper ratio's denominator
  /// @return FundKeeper ratio denominator
  function fundDenominator() public view override returns (uint256) {
    return getUint256("fundDenominator");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setAddress(string memory key, address _address) private {
    addressStorage[keccak256(abi.encodePacked(key))] = _address;
  }

  function getAddress(string memory key) private view returns (address) {
    return addressStorage[keccak256(abi.encodePacked(key))];
  }

  function setUint256(string memory key, uint256 _value) private {
    uintStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getUint256(string memory key) private view returns (uint256) {
    return uintStorage[keccak256(abi.encodePacked(key))];
  }

  //slither-disable-next-line unused-state
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}