//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

import "./PoolLogic.sol";
import "./upgradability/ProxyFactory.sol";
import "./interfaces/IAssetHandler.sol";
import "./interfaces/IHasDaoInfo.sol";
import "./interfaces/IHasFeeInfo.sol";
import "./interfaces/IHasAssetInfo.sol";
import "./interfaces/IPoolLogic.sol";
import "./interfaces/IHasGuardInfo.sol";
import "./interfaces/IHasPausable.sol";
import "./interfaces/IHasSupportedAsset.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IManaged.sol";

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title Pool Factory
/// @dev A Factory to spawn pools
contract PoolFactory is
  PausableUpgradeable,
  ProxyFactory,
  IHasDaoInfo,
  IHasFeeInfo,
  IHasAssetInfo,
  IHasGuardInfo,
  IHasPausable
{
  using SafeMathUpgradeable for uint256;

  event FundCreated(
    address fundAddress,
    bool isPoolPrivate,
    string fundName,
    string managerName,
    address manager,
    uint256 time,
    uint256 managerFeeNumerator,
    uint256 managerFeeDenominator
  );

  event DAOAddressSet(address daoAddress);

  event GovernanceAddressSet(address governanceAddress);

  event DaoFeeSet(uint256 numerator, uint256 denominator);

  event ExitFeeSet(uint256 numerator, uint256 denominator);

  event ExitCooldownSet(uint256 cooldown);

  event MaximumSupportedAssetCountSet(uint256 count);

  event LogUpgrade(address indexed manager, address indexed pool);

  event SetPoolManagerFee(uint256 numerator, uint256 denominator);

  event SetMaximumManagerFee(uint256 numerator, uint256 denominator);

  event SetMaximumManagerFeeNumeratorChange(uint256 amount);

  event SetAssetHandler(address assetHandler);

  event SetPoolStorageVersion(uint256 poolStorageVersion);

  event SetManagerFeeNumeratorChangeDelay(uint256 delay);

  address[] public deployedFunds;

  address public override daoAddress;
  address public governanceAddress;

  address internal _assetHandler;
  uint256 internal _daoFeeNumerator;
  uint256 internal _daoFeeDenominator;

  mapping(address => bool) public isPool;

  uint256 private _MAXIMUM_MANAGER_FEE_NUMERATOR;
  uint256 private _MANAGER_FEE_DENOMINATOR;

  uint256 internal _exitCooldown;

  uint256 internal _maximumSupportedAssetCount;

  mapping(address => uint256) public poolVersion;
  uint256 public poolStorageVersion;

  uint256 public override maximumManagerFeeNumeratorChange;
  uint256 public override managerFeeNumeratorChangeDelay;

  function initialize(
    address _poolLogic,
    address _managerLogic,
    address assetHandler,
    address _daoAddress,
    address _governanceAddress
  ) external initializer {
    __ProxyFactory_init(_poolLogic, _managerLogic);
    __Pausable_init();

    _setAssetHandler(assetHandler);

    _setDAOAddress(_daoAddress);

    _setGovernanceAddress(_governanceAddress);

    _setMaximumManagerFee(5000, 10000);

    _setDaoFee(10, 100); // 10%
    _setExitCooldown(1 days);
    setManagerFeeNumeratorChangeDelay(4 weeks);
    setMaximumManagerFeeNumeratorChange(1000);

    _setMaximumSupportedAssetCount(10);

    _setPoolStorageVersion(230); // V2.3.0;
  }

  function createFund(
    bool _privatePool,
    address _manager,
    string memory _managerName,
    string memory _fundName,
    string memory _fundSymbol,
    uint256 _managerFeeNumerator,
    IHasSupportedAsset.Asset[] memory _supportedAssets
  ) external returns (address) {
    require(!paused(), "contracts paused");
    require(_supportedAssets.length <= _maximumSupportedAssetCount, "maximum assets reached");
    require(_managerFeeNumerator <= _MAXIMUM_MANAGER_FEE_NUMERATOR, "invalid manager fee");

    bytes memory poolLogicData =
      abi.encodeWithSignature(
        "initialize(address,bool,string,string)",
        address(this),
        _privatePool,
        _fundName,
        _fundSymbol
      );

    address fund = deploy(poolLogicData, 2);

    bytes memory managerLogicData =
      abi.encodeWithSignature(
        "initialize(address,address,string,address,uint256,(address,bool)[])",
        address(this),
        _manager,
        _managerName,
        fund,
        _managerFeeNumerator,
        _supportedAssets
      );

    address managerLogic = deploy(managerLogicData, 1);
    // Ignore return value as want it to continue regardless
    IPoolLogic(fund).setPoolManagerLogic(managerLogic);

    deployedFunds.push(fund);
    isPool[fund] = true;

    poolVersion[fund] = poolStorageVersion;

    emit FundCreated(
      fund,
      _privatePool,
      _fundName,
      _managerName,
      _manager,
      block.timestamp,
      _managerFeeNumerator,
      _MANAGER_FEE_DENOMINATOR
    );

    return fund;
  }

  // DAO info (Uber Pool)

  function setDAOAddress(address _daoAddress) external onlyOwner {
    _setDAOAddress(_daoAddress);
  }

  function _setDAOAddress(address _daoAddress) internal {
    require(_daoAddress != address(0), "Invalid daoAddress");

    daoAddress = _daoAddress;

    emit DAOAddressSet(_daoAddress);
  }

  // Governance info

  function setGovernanceAddress(address _governanceAddress) external onlyOwner {
    _setGovernanceAddress(_governanceAddress);
  }

  function _setGovernanceAddress(address _governanceAddress) internal {
    require(_governanceAddress != address(0), "Invalid governanceAddress");

    governanceAddress = _governanceAddress;

    emit GovernanceAddressSet(_governanceAddress);
  }

  function setDaoFee(uint256 numerator, uint256 denominator) external onlyOwner {
    _setDaoFee(numerator, denominator);
  }

  function _setDaoFee(uint256 numerator, uint256 denominator) internal {
    require(numerator <= denominator, "invalid fraction");

    _daoFeeNumerator = numerator;
    _daoFeeDenominator = denominator;

    emit DaoFeeSet(numerator, denominator);
  }

  function getDaoFee() external view override returns (uint256, uint256) {
    return (_daoFeeNumerator, _daoFeeDenominator);
  }

  // Manager fees

  function getMaximumManagerFee() external view override returns (uint256, uint256) {
    return (_MAXIMUM_MANAGER_FEE_NUMERATOR, _MANAGER_FEE_DENOMINATOR);
  }

  function setMaximumManagerFee(uint256 numerator) external onlyOwner {
    _setMaximumManagerFee(numerator, _MANAGER_FEE_DENOMINATOR);
  }

  function _setMaximumManagerFee(uint256 numerator, uint256 denominator) internal {
    require(numerator <= denominator, "invalid fraction");

    _MAXIMUM_MANAGER_FEE_NUMERATOR = numerator;
    _MANAGER_FEE_DENOMINATOR = denominator;

    emit SetMaximumManagerFee(numerator, denominator);
  }

  function setMaximumManagerFeeNumeratorChange(uint256 amount) public onlyOwner {
    maximumManagerFeeNumeratorChange = amount;

    emit SetMaximumManagerFeeNumeratorChange(amount);
  }

  function setManagerFeeNumeratorChangeDelay(uint256 delay) public onlyOwner {
    managerFeeNumeratorChangeDelay = delay;

    emit SetManagerFeeNumeratorChangeDelay(delay);
  }

  function setExitCooldown(uint256 cooldown) external onlyOwner {
    _setExitCooldown(cooldown);
  }

  function _setExitCooldown(uint256 cooldown) internal {
    _exitCooldown = cooldown;

    emit ExitCooldownSet(cooldown);
  }

  function getExitCooldown() external view override returns (uint256) {
    return _exitCooldown;
  }

  // Asset Info

  function setMaximumSupportedAssetCount(uint256 count) external onlyOwner {
    _setMaximumSupportedAssetCount(count);
  }

  function _setMaximumSupportedAssetCount(uint256 count) internal {
    _maximumSupportedAssetCount = count;

    emit MaximumSupportedAssetCountSet(count);
  }

  function getMaximumSupportedAssetCount() external view virtual override returns (uint256) {
    return _maximumSupportedAssetCount;
  }

  function isValidAsset(address asset) public view override returns (bool) {
    return IAssetHandler(_assetHandler).priceAggregators(asset) != address(0);
  }

  /**
   * Returns the latest price of a given asset
   */
  function getAssetPrice(address asset) external view override returns (uint256) {
    return IAssetHandler(_assetHandler).getUSDPrice(asset);
  }

  function getAssetType(address asset) external view override returns (uint16) {
    return IAssetHandler(_assetHandler).assetTypes(asset);
  }

  function getAssetHandler() external view returns (address) {
    return _assetHandler;
  }

  function setAssetHandler(address assetHandler) external onlyOwner {
    _setAssetHandler(assetHandler);
  }

  function _setAssetHandler(address assetHandler) internal {
    require(assetHandler != address(0), "Invalid assetHandler");

    _assetHandler = assetHandler;

    emit SetAssetHandler(assetHandler);
  }

  // Upgrade

  function setPoolStorageVersion(uint256 _poolStorageVersion) external onlyOwner {
    _setPoolStorageVersion(_poolStorageVersion);
  }

  function _setPoolStorageVersion(uint256 _poolStorageVersion) internal {
    require(_poolStorageVersion > poolStorageVersion, "version needs to be higher");

    poolStorageVersion = _poolStorageVersion;

    emit SetPoolStorageVersion(_poolStorageVersion);
  }

  /**
   * @dev Backdoor function
   * @param pool Address of the target.
   * @param data Calldata for the target address.
   * @param targetVersion set target version after call
   */
  function _upgradePool(
    address pool,
    bytes calldata data,
    uint256 targetVersion
  ) internal {
    require(pool != address(0), "target-invalid");
    require(data.length > 0, "data-invalid");
    bytes memory _data = data;
    assembly {
      let succeeded := delegatecall(gas(), pool, add(_data, 0x20), mload(_data), 0, 0)
      switch iszero(succeeded)
        case 1 {
          // throw if delegatecall failed
          let size := returndatasize()
          returndatacopy(0x00, 0x00, size)
          revert(0x00, size)
        }
    }
    emit LogUpgrade(msg.sender, pool);

    poolVersion[pool] = targetVersion;
  }

  function upgradePoolBatch(
    uint256 startIndex,
    uint256 endIndex,
    uint256 sourceVersion,
    uint256 targetVersion,
    bytes calldata data
  ) external onlyOwner {
    require(startIndex <= endIndex && endIndex < deployedFunds.length, "invalid bounds");

    for (uint256 i = startIndex; i <= endIndex; i++) {
      address pool = deployedFunds[i];

      if (poolVersion[pool] != sourceVersion) continue;

      _upgradePool(pool, data, targetVersion);
    }
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function isPaused() external view override returns (bool) {
    return paused();
  }

  // Transaction Guards

  function getGuard(address extContract) external view override returns (address guard) {
    guard = IGovernance(governanceAddress).contractGuards(extContract);
    if (guard == address(0)) {
      guard = getAssetGuard(extContract);
    }
  }

  function getAssetGuard(address extContract) public view override returns (address guard) {
    if (isValidAsset(extContract)) {
      uint16 assetType = IAssetHandler(_assetHandler).assetTypes(extContract);
      guard = IGovernance(governanceAddress).assetGuards(assetType);
    }
  }

  function getAddress(bytes32 name) external view override returns (address destination) {
    destination = IGovernance(governanceAddress).nameToDestination(name);
    require(destination != address(0), "governance: invalid name");
  }

  /// @notice Return full array of deployed funds
  /// @return full array of deployed funds
  function getDeployedFunds() external view returns (address[] memory) {
    return deployedFunds;
  }

  /**
   * @notice Returns all invested pools by a given user
   * @param user the user address
   */
  function getInvestedPools(address user) external view returns (address[] memory) {
    uint256 length = deployedFunds.length;
    address[] memory investedPools = new address[](length);
    uint256 index = 0;
    for (uint256 i = 0; i < length; i++) {
      if (IERC20Upgradeable(deployedFunds[i]).balanceOf(user) > 0) {
        investedPools[index] = deployedFunds[i];
        index++;
      }
    }

    uint256 reduceLength = length.sub(index);
    assembly {
      mstore(investedPools, sub(mload(investedPools), reduceLength))
    }
    return investedPools;
  }

  /**
   * @notice Returns all managed pools by a given manager
   * @param manager the manager address
   */
  function getManagedPools(address manager) external view returns (address[] memory) {
    uint256 length = deployedFunds.length;
    address[] memory managedPools = new address[](length);
    uint256 index = 0;
    for (uint256 i = 0; i < length; i++) {
      address poolManagerLogic = IPoolLogic(deployedFunds[i]).poolManagerLogic();
      if (IManaged(poolManagerLogic).manager() == manager) {
        managedPools[index] = deployedFunds[i];
        index++;
      }
    }

    uint256 reduceLength = length.sub(index);
    assembly {
      mstore(managedPools, sub(mload(managedPools), reduceLength))
    }
    return managedPools;
  }

  uint256[50] private __gap;
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// Transaction Types in execTransaction()
// 1. Approve: Approving a token for spending by different address/contract
// 2. Exchange: Exchange/trade of tokens eg. Uniswap, Synthetix
// 3. AddLiquidity: Add liquidity of Uniswap, Sushiswap
// 4. RemoveLiquidity: Remove liquidity of Uniswap, Sushiswap
// 5. Stake: Stake tokens into a third party contract (eg. Sushi yield farming)
// 6. Unstake: Unstake tokens from a third party contract (eg. Sushi yield farming)
// 7. Claim: Claim rewards tokens from a third party contract (eg. SUSHI & MATIC rewards)
// 8. UnstakeAndClaim: Unstake tokens and claim rewards from a third party contract
// 9. Deposit: Aave deposit tokens -> get Aave Interest Bearing Token
// 10. Withdraw: Withdraw tokens from Aave Interest Bearing Token
// 11. SetUserUseReserveAsCollateral: Aave set reserve asset to be used as collateral
// 12. Borrow: Aave borrow tokens
// 13. Repay: Aave repay tokens
// 14. SwapBorrowRateMode: Aave change borrow rate mode (stable/variable)
// 15. RebalanceStableBorrowRate: Aave rebalance stable borrow rate

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IHasDaoInfo.sol";
import "./interfaces/IHasFeeInfo.sol";
import "./interfaces/IHasGuardInfo.sol";
import "./interfaces/IHasAssetInfo.sol";
import "./interfaces/IHasPausable.sol";
import "./interfaces/IPoolManagerLogic.sol";
import "./interfaces/IHasSupportedAsset.sol";
import "./interfaces/IHasOwnable.sol";
import "./interfaces/IManaged.sol";
import "./interfaces/guards/IGuard.sol";
import "./interfaces/guards/IAssetGuard.sol";
import "./interfaces/guards/IAaveLendingPoolAssetGuard.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PoolLogic is ERC20Upgradeable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;

  event Deposit(
    address fundAddress,
    address investor,
    address assetDeposited,
    uint256 amountDeposited,
    uint256 valueDeposited,
    uint256 fundTokensReceived,
    uint256 totalInvestorFundTokens,
    uint256 fundValue,
    uint256 totalSupply,
    uint256 time
  );

  struct WithdrawnAsset {
    address asset;
    uint256 amount;
    bool withdrawProcessed;
  }

  event Withdrawal(
    address fundAddress,
    address investor,
    uint256 valueWithdrawn,
    uint256 fundTokensWithdrawn,
    uint256 totalInvestorFundTokens,
    uint256 fundValue,
    uint256 totalSupply,
    WithdrawnAsset[] withdrawnAssets,
    uint256 time
  );

  event TransactionExecuted(address pool, address manager, uint16 transactionType, uint256 time);

  event PoolPrivacyUpdated(bool isPoolPrivate);

  event ManagerFeeMinted(
    address pool,
    address manager,
    uint256 available,
    uint256 daoFee,
    uint256 managerFee,
    uint256 tokenPriceAtLastFeeMint
  );

  event PoolManagerLogicSet(address poolManagerLogic, address from);

  bool public privatePool;
  address public creator;

  uint256 public creationTime;

  address public factory;

  // Manager fees
  uint256 public tokenPriceAtLastFeeMint;

  mapping(address => uint256) public lastDeposit;

  address public poolManagerLogic;

  modifier onlyPrivate() {
    require(msg.sender == manager() || !privatePool || isMemberAllowed(msg.sender), "only members allowed");
    _;
  }

  modifier onlyManager() {
    require(msg.sender == manager(), "only manager");
    _;
  }

  modifier onlyManagerOrTrader() {
    require(msg.sender == manager() || msg.sender == trader(), "only manager or trader");
    _;
  }

  modifier whenNotPaused() {
    require(!IHasPausable(factory).isPaused(), "contracts paused");
    _;
  }

  function initialize(
    address _factory,
    bool _privatePool,
    string memory _fundName,
    string memory _fundSymbol
  ) external initializer {
    require(_factory != address(0), "Invalid factory");
    __ERC20_init(_fundName, _fundSymbol);
    __ReentrancyGuard_init();

    factory = _factory;
    _setPoolPrivacy(_privatePool);
    creator = msg.sender;
    creationTime = block.timestamp;

    tokenPriceAtLastFeeMint = 10**18;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(getExitRemainingCooldown(from) == 0, "cooldown active");
  }

  function setPoolPrivate(bool _privatePool) external onlyManager {
    require(privatePool != _privatePool, "flag must be different");

    _setPoolPrivacy(_privatePool);
  }

  function _setPoolPrivacy(bool _privacy) internal {
    privatePool = _privacy;

    emit PoolPrivacyUpdated(_privacy);
  }

  function deposit(address _asset, uint256 _amount) external onlyPrivate whenNotPaused returns (uint256) {
    require(IPoolManagerLogic(poolManagerLogic).isDepositAsset(_asset), "invalid deposit asset");

    lastDeposit[msg.sender] = block.timestamp;

    uint256 fundValue = _mintManagerFee();

    uint256 totalSupplyBefore = totalSupply();

    require(IERC20Upgradeable(_asset).transferFrom(msg.sender, address(this), _amount), "token transfer failed");

    uint256 usdAmount = IPoolManagerLogic(poolManagerLogic).assetValue(_asset, _amount);

    uint256 liquidityMinted;
    if (totalSupplyBefore > 0) {
      //total balance converted to susd that this contract holds
      //need to calculate total value of synths in this contract
      liquidityMinted = usdAmount.mul(totalSupplyBefore).div(fundValue);
    } else {
      liquidityMinted = usdAmount;
    }

    _mint(msg.sender, liquidityMinted);

    emit Deposit(
      address(this),
      msg.sender,
      _asset,
      _amount,
      usdAmount,
      liquidityMinted,
      balanceOf(msg.sender),
      fundValue.add(usdAmount),
      totalSupplyBefore.add(liquidityMinted),
      block.timestamp
    );

    return liquidityMinted;
  }

  /// @notice Withdraw assets based on the fund token amount
  /// @param _fundTokenAmount the fund token amount
  function withdraw(uint256 _fundTokenAmount) external virtual nonReentrant whenNotPaused {
    require(balanceOf(msg.sender) >= _fundTokenAmount, "insufficient balance");

    require(getExitRemainingCooldown(msg.sender) == 0, "cooldown active");

    uint256 fundValue = _mintManagerFee();

    //calculate the proportion
    uint256 portion = _fundTokenAmount.mul(10**18).div(totalSupply());

    //first return funded tokens
    _burn(msg.sender, _fundTokenAmount);

    // TODO: Combining into one line to fix stack too deep,
    //       need to refactor some variables into struct in order to have more variables
    IHasSupportedAsset.Asset[] memory _supportedAssets = IHasSupportedAsset(poolManagerLogic).getSupportedAssets();
    uint256 assetCount = _supportedAssets.length;
    WithdrawnAsset[] memory withdrawnAssets = new WithdrawnAsset[](assetCount);
    uint16 index = 0;

    for (uint256 i = 0; i < assetCount; i++) {
      (address asset, uint256 portionOfAssetBalance, bool withdrawProcessed) =
        _withdrawProcessing(_supportedAssets[i].asset, msg.sender, portion);

      if (portionOfAssetBalance > 0) {
        // Ignoring return value for transfer as want to transfer no matter what happened
        IERC20Upgradeable(asset).transfer(msg.sender, portionOfAssetBalance);

        withdrawnAssets[index] = WithdrawnAsset({
          asset: asset,
          amount: portionOfAssetBalance,
          withdrawProcessed: withdrawProcessed
        });
        index++;
      }
    }

    // Reduce length for withdrawnAssets to remove the empty items
    uint256 reduceLength = assetCount.sub(index);
    assembly {
      mstore(withdrawnAssets, sub(mload(withdrawnAssets), reduceLength))
    }

    uint256 valueWithdrawn = portion.mul(fundValue).div(10**18);

    emit Withdrawal(
      address(this),
      msg.sender,
      valueWithdrawn,
      _fundTokenAmount,
      balanceOf(msg.sender),
      fundValue.sub(valueWithdrawn),
      totalSupply(),
      withdrawnAssets,
      block.timestamp
    );
  }

  /// @notice Perform any additional processing on withdrawal of asset
  /// @dev Checks for staked tokens and withdraws them to the investor account
  /// @param asset Asset for withdrawal processing
  /// @param to Investor account to send withdrawed tokens to
  /// @param portion Portion of investor withdrawal of the total dHedge pool
  /// @return withdrawAsset Asset to be withdrawed
  /// @return withdrawBalance Asset balance amount to be withdrawed
  /// @return success A boolean for success or fail transaction
  function _withdrawProcessing(
    address asset,
    address to,
    uint256 portion
  )
    internal
    returns (
      address, // withdrawAsset
      uint256, // withdrawBalance
      bool success
    )
  {
    // Withdraw any external tokens (eg. staked tokens in other contracts)
    address guard = IHasGuardInfo(factory).getAssetGuard(asset);
    require(guard != address(0), "invalid guard");

    (address withdrawAsset, uint256 withdrawBalance, IAssetGuard.MultiTransaction[] memory transactions) =
      IAssetGuard(guard).withdrawProcessing(address(this), asset, portion, to);

    uint256 txCount = transactions.length;
    if (txCount > 0) {
      uint256 assetBalanceBefore;
      if (withdrawAsset != address(0)) {
        assetBalanceBefore = IERC20Upgradeable(withdrawAsset).balanceOf(address(this));
      }

      for (uint256 i = 0; i < txCount; i++) {
        (success, ) = transactions[i].to.call(transactions[i].txData);
        require(success, "failed to withdraw tokens");
      }

      if (withdrawAsset != address(0)) {
        // calculated the balance change after withdraw process.
        withdrawBalance = withdrawBalance.add(IERC20Upgradeable(withdrawAsset).balanceOf(address(this))).sub(
          assetBalanceBefore
        );
      }
    }

    return (withdrawAsset, withdrawBalance, success);
  }

  /// @notice Function to let pool talk to other protocol
  /// @dev execute transaction for the pool
  /// @param to The destination address for pool to talk to
  /// @param data The data that going to send in the transaction
  /// @return success A boolean for success or fail transaction
  function execTransaction(address to, bytes memory data)
    external
    onlyManagerOrTrader
    nonReentrant
    whenNotPaused
    returns (bool success)
  {
    require(to != address(0), "non-zero address is required");

    address guard = IHasGuardInfo(factory).getGuard(to);

    require(guard != address(0), "invalid destination");

    if (IHasAssetInfo(factory).isValidAsset(to)) {
      require(IHasSupportedAsset(poolManagerLogic).isSupportedAsset(to), "asset not enabled in pool");
    }

    // to pass the guard, the data must return a transaction type. refer to header for transaction types
    uint16 txType = IGuard(guard).txGuard(poolManagerLogic, to, data);
    require(txType > 0, "invalid transaction");

    (success, ) = to.call(data);
    require(success, "failed to execute the call");

    emit TransactionExecuted(address(this), manager(), txType, block.timestamp);
  }

  function getFundSummary()
    external
    view
    returns (
      string memory,
      uint256,
      uint256,
      address,
      string memory,
      uint256,
      bool,
      uint256,
      uint256
    )
  {
    uint256 managerFeeNumerator;
    uint256 managerFeeDenominator;
    (managerFeeNumerator, managerFeeDenominator) = IPoolManagerLogic(poolManagerLogic).getManagerFee();

    return (
      name(),
      totalSupply(),
      IPoolManagerLogic(poolManagerLogic).totalFundValue(),
      manager(),
      managerName(),
      creationTime,
      privatePool,
      managerFeeNumerator,
      managerFeeDenominator
    );
  }

  function tokenPrice() external view returns (uint256) {
    uint256 fundValue = IPoolManagerLogic(poolManagerLogic).totalFundValue();
    uint256 tokenSupply = totalSupply();

    return _tokenPrice(fundValue, tokenSupply);
  }

  function _tokenPrice(uint256 _fundValue, uint256 _tokenSupply) internal pure returns (uint256) {
    if (_tokenSupply == 0 || _fundValue == 0) return 0;

    return _fundValue.mul(10**18).div(_tokenSupply);
  }

  function availableManagerFee() external view returns (uint256) {
    uint256 fundValue = IPoolManagerLogic(poolManagerLogic).totalFundValue();
    uint256 tokenSupply = totalSupply();

    uint256 managerFeeNumerator;
    uint256 managerFeeDenominator;
    (managerFeeNumerator, managerFeeDenominator) = IPoolManagerLogic(poolManagerLogic).getManagerFee();

    return
      _availableManagerFee(fundValue, tokenSupply, tokenPriceAtLastFeeMint, managerFeeNumerator, managerFeeDenominator);
  }

  function _availableManagerFee(
    uint256 _fundValue,
    uint256 _tokenSupply,
    uint256 _lastFeeMintPrice,
    uint256 _feeNumerator,
    uint256 _feeDenominator
  ) internal pure returns (uint256) {
    if (_tokenSupply == 0 || _fundValue == 0) return 0;

    uint256 currentTokenPrice = _fundValue.mul(10**18).div(_tokenSupply);

    if (currentTokenPrice <= _lastFeeMintPrice) return 0;

    uint256 available =
      currentTokenPrice.sub(_lastFeeMintPrice).mul(_tokenSupply).mul(_feeNumerator).div(_feeDenominator).div(
        currentTokenPrice
      );

    return available;
  }

  function mintManagerFee() external whenNotPaused {
    _mintManagerFee();
  }

  function _mintManagerFee() internal returns (uint256 fundValue) {
    fundValue = IPoolManagerLogic(poolManagerLogic).totalFundValue();
    uint256 tokenSupply = totalSupply();

    uint256 managerFeeNumerator;
    uint256 managerFeeDenominator;
    (managerFeeNumerator, managerFeeDenominator) = IPoolManagerLogic(poolManagerLogic).getManagerFee();

    uint256 available =
      _availableManagerFee(fundValue, tokenSupply, tokenPriceAtLastFeeMint, managerFeeNumerator, managerFeeDenominator);

    // Ignore dust when minting performance fees
    if (available < 10000) return fundValue;

    address daoAddress = IHasOwnable(factory).owner();
    uint256 daoFeeNumerator;
    uint256 daoFeeDenominator;

    (daoFeeNumerator, daoFeeDenominator) = IHasDaoInfo(factory).getDaoFee();

    uint256 daoFee = available.mul(daoFeeNumerator).div(daoFeeDenominator);
    uint256 managerFee = available.sub(daoFee);

    if (daoFee > 0) _mint(daoAddress, daoFee);

    if (managerFee > 0) _mint(manager(), managerFee);

    tokenPriceAtLastFeeMint = _tokenPrice(fundValue, tokenSupply);

    emit ManagerFeeMinted(address(this), manager(), available, daoFee, managerFee, tokenPriceAtLastFeeMint);
  }

  function getExitCooldown() public view returns (uint256) {
    return IHasFeeInfo(factory).getExitCooldown();
  }

  function getExitRemainingCooldown(address sender) public view returns (uint256) {
    uint256 cooldown = getExitCooldown();
    uint256 cooldownFinished = lastDeposit[sender].add(cooldown);

    if (cooldownFinished < block.timestamp) return 0;

    return cooldownFinished.sub(block.timestamp);
  }

  function setPoolManagerLogic(address _poolManagerLogic) external returns (bool) {
    require(_poolManagerLogic != address(0), "Invalid poolManagerLogic address");
    require(
      msg.sender == address(factory) || msg.sender == IHasOwnable(factory).owner(),
      "only DAO or factory allowed"
    );

    poolManagerLogic = _poolManagerLogic;
    emit PoolManagerLogicSet(_poolManagerLogic, msg.sender);
    return true;
  }

  function manager() internal view returns (address) {
    return IManaged(poolManagerLogic).manager();
  }

  function trader() internal view returns (address) {
    return IManaged(poolManagerLogic).trader();
  }

  function managerName() public view returns (string memory) {
    return IManaged(poolManagerLogic).managerName();
  }

  function isMemberAllowed(address member) public view returns (bool) {
    return IManaged(poolManagerLogic).isMemberAllowed(member);
  }

  /// @notice execute function of aave flash loan
  /// @dev This function is called after your contract has received the flash loaned amount
  /// @param assets the loaned assets
  /// @param amounts the loaned amounts per each asset
  /// @param premiums the additional owed amount per each asset
  /// @param originator the origin caller address of the flash loan
  /// @param params Variadic packed params to pass to the receiver as extra information
  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address originator,
    bytes memory params
  ) external returns (bool success) {
    require(originator == address(this), "only pool flash loan origin");

    address aaveLendingPoolAssetGuard = IHasGuardInfo(factory).getAssetGuard(msg.sender);
    require(
      aaveLendingPoolAssetGuard != address(0) &&
        msg.sender == IAaveLendingPoolAssetGuard(aaveLendingPoolAssetGuard).aaveLendingPool(),
      "invalid lending pool"
    );

    (uint256[] memory interestRateModes, uint256 portion) = abi.decode(params, (uint256[], uint256));

    IAssetGuard.MultiTransaction[] memory transactions =
      IAaveLendingPoolAssetGuard(aaveLendingPoolAssetGuard).flashloanProcessing(
        address(this),
        portion,
        assets,
        amounts,
        premiums,
        interestRateModes
      );

    for (uint256 i = 0; i < transactions.length; i++) {
      (success, ) = transactions[i].to.call(transactions[i].txData);
      require(success, "failed to process flashloan");
    }
  }

  uint256[50] private __gap;
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./InitializableUpgradeabilityProxy.sol";
import "./HasLogic.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ProxyFactory is OwnableUpgradeable, HasLogic {
  event ProxyCreated(address proxy);

  address private poolLogic;

  address private poolManagerLogic;

  function __ProxyFactory_init(address _poolLogic, address _poolManagerLogic) internal {
    __Ownable_init();

    require(_poolLogic != address(0), "Invalid poolLogic");
    require(_poolManagerLogic != address(0), "Invalid poolManagerLogic");

    poolLogic = _poolLogic;
    poolManagerLogic = _poolManagerLogic;
  }

  function setLogic(address _poolLogic, address _poolManagerLogic) public onlyOwner {
    require(_poolLogic != address(0), "Invalid poolLogic");
    require(_poolManagerLogic != address(0), "Invalid poolManagerLogic");

    poolLogic = _poolLogic;
    poolManagerLogic = _poolManagerLogic;
  }

  function getLogic(uint8 _proxyType) public view override returns (address) {
    if (_proxyType == 1) {
      return poolManagerLogic;
    } else {
      return poolLogic;
    }
  }

  function deploy(bytes memory _data, uint8 _proxyType) public returns (address) {
    return _deployProxy(_data, _proxyType);
  }

  function _deployProxy(bytes memory _data, uint8 _proxyType) internal returns (address) {
    InitializableUpgradeabilityProxy proxy = _createProxy();
    emit ProxyCreated(address(proxy));
    proxy.initialize(address(this), _data, _proxyType);
    return address(proxy);
  }

  function _createProxy() internal returns (InitializableUpgradeabilityProxy) {
    address payable addr;
    bytes memory code = type(InitializableUpgradeabilityProxy).creationCode;

    assembly {
      addr := create(0, add(code, 0x20), mload(code))
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    return InitializableUpgradeabilityProxy(addr);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

interface IAssetHandler {
  event AddedAsset(address asset, uint16 assetType, address aggregator);
  event RemovedAsset(address asset);

  struct Asset {
    address asset;
    uint16 assetType;
    address aggregator;
  }

  function addAsset(
    address asset,
    uint16 assetType,
    address aggregator
  ) external;

  function addAssets(Asset[] memory assets) external;

  function removeAsset(address asset) external;

  function priceAggregators(address asset) external view returns (address);

  function assetTypes(address asset) external view returns (uint16);

  function getUSDPrice(address asset) external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasDaoInfo {
  function getDaoFee() external view returns (uint256, uint256);

  function daoAddress() external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasFeeInfo {
  // Manager fee
  function getMaximumManagerFee() external view returns (uint256, uint256);

  function maximumManagerFeeNumeratorChange() external view returns (uint256);

  function managerFeeNumeratorChangeDelay() external view returns (uint256);

  // Exit fee
  // function getExitFee() external view returns (uint256, uint256);
  function getExitCooldown() external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasAssetInfo {
  function isValidAsset(address asset) external view returns (bool);

  function getAssetPrice(address asset) external view returns (uint256);

  function getAssetType(address asset) external view returns (uint16);

  function getMaximumSupportedAssetCount() external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolLogic {
  function factory() external view returns (address);

  function poolManagerLogic() external view returns (address);

  function setPoolManagerLogic(address _poolManagerLogic) external returns (bool);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasGuardInfo {
  // Get guard
  function getGuard(address extContract) external view returns (address);

  // Get asset guard
  function getAssetGuard(address extContract) external view returns (address);

  // Get mapped addresses from Governance
  function getAddress(bytes32 name) external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasPausable {
  function isPaused() external view returns (bool);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

interface IHasSupportedAsset {
  struct Asset {
    address asset;
    bool isDeposit;
  }

  function getSupportedAssets() external view returns (Asset[] memory);

  function isSupportedAsset(address asset) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGovernance {
  function contractGuards(address target) external view returns (address guard);

  function assetGuards(uint16 assetType) external view returns (address guard);

  function nameToDestination(bytes32 name) external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IManaged {
  function manager() external view returns (address);

  function trader() external view returns (address);

  function managerName() external view returns (string memory);

  function isMemberAllowed(address member) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolManagerLogic {
  function poolLogic() external view returns (address);

  function isDepositAsset(address asset) external view returns (bool);

  function validateAsset(address asset) external view returns (bool);

  function assetValue(address asset) external view returns (uint256);

  function assetValue(address asset, uint256 amount) external view returns (uint256);

  function factory() external view returns (address);

  function setPoolLogic(address fundAddress) external returns (bool);

  function totalFundValue() external view returns (uint256);

  function getManagerFee() external view returns (uint256, uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasOwnable {
  function owner() external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGuard {
  event Exchange(address fundAddress, address sourceAsset, uint256 sourceAmount, address dstAsset, uint256 time);

  function txGuard(
    address poolManagerLogic,
    address to,
    bytes calldata data
  ) external returns (uint16 txType);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IAssetGuard {
  struct MultiTransaction {
    address to;
    bytes txData;
  }

  function withdrawProcessing(
    address pool,
    address asset,
    uint256 withdrawPortion,
    address to
  )
    external
    view
    returns (
      address,
      uint256,
      MultiTransaction[] memory transactions
    );

  function getBalance(address pool, address asset) external view returns (uint256 balance);

  function getDecimals(address asset) external view returns (uint256 decimals);

  function removeAssetCheck(address poolLogic, address asset) external view;
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IAssetGuard.sol";

interface IAaveLendingPoolAssetGuard {
  function flashloanProcessing(
    address pool,
    uint256 portion,
    address[] memory repayAssets,
    uint256[] memory repayAmounts,
    uint256[] memory premiums,
    uint256[] memory interestRateModes
  ) external view returns (IAssetGuard.MultiTransaction[] memory transactions);

  function aaveLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity 0.7.6;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _factory Address of the factory containing the implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(
    address _factory,
    bytes memory _data,
    uint8 _proxyType
  ) public payable {
    require(_implementation() == address(0), "Impl not zero");
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    _setImplementation(_factory);
    _setProxyType(_proxyType);
    if (_data.length > 0) {
      (bool success, ) = _implementation().delegatecall(_data);
      require(success, "Implementation init failed");
    }
  }
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface HasLogic {
  function getLogic(uint8 _proxyType) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Proxy.sol";
import "./Address.sol";
import "./HasLogic.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Storing type of the proxy, 1 for managerLogic, 2 for pool.
   */
  bytes32 internal constant PROXY_TYPE = 0x1000000000000000000000000000000000000000000000000000000000000000;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address) {
    address factory;
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      factory := sload(slot)
    }

    // Begin custom modification
    if (factory == address(0x0)) return address(0x0); // If factory not initialized return empty

    return HasLogic(factory).getLogic(_proxyType());
  }

  function _proxyType() internal view returns (uint8) {
    uint8 proxyType;
    bytes32 slot = PROXY_TYPE;
    assembly {
      proxyType := sload(slot)
    }
    return proxyType;
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set implementation to EOA");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }

  /**
   * @dev Sets type of the proxy.
   * @param proxyType type of the proxy.
   */
  function _setProxyType(uint8 proxyType) internal {
    bytes32 slot = PROXY_TYPE;

    assembly {
      sstore(slot, proxyType)
    }
  }
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      // Warning: OVM: Using RETURNDATASIZE or RETURNDATACOPY in user asm isn't guaranteed to work
      returndatacopy(0, 0, returndatasize())

      switch result
        // delegatecall returns 0 on error.
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}