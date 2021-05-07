// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.8.0;
pragma experimental ABIEncoderV2;

import { IVault } from "./IVault.sol";
import { VaultBase } from "./VaultBase.sol";
import { IFujiAdmin } from "../IFujiAdmin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFujiERC1155 } from "../FujiERC1155/IFujiERC1155.sol";
import { IProvider } from "../Providers/IProvider.sol";
import { IAlphaWhiteList } from "../IAlphaWhiteList.sol";
import { Errors } from "../Libraries/Errors.sol";

interface IVaultHarvester{
  function collectRewards(uint256 _farmProtocolNum) external returns(address claimedToken);
}

contract VaultETHUSDT is IVault, VaultBase, ReentrancyGuard {

  uint256 internal constant BASE = 1e18;

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Safety factor
  Factor public safetyF;

  // Collateralization factor
  Factor public collatF;

  //State variables
  address[] public providers;
  address public override activeProvider;

  IFujiAdmin private _fujiAdmin;
  address public override fujiERC1155;
  AggregatorV3Interface public oracle;

  modifier isAuthorized() {
    require(
      msg.sender == _fujiAdmin.getController() ||
      msg.sender == owner(),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  modifier onlyFlash() {
    require(
      msg.sender == _fujiAdmin.getFlasher(),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  constructor () public {

    vAssets.collateralAsset = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
    vAssets.borrowAsset = address(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT

    // 1.05
    safetyF.a = 21;
    safetyF.b = 20;

    // 1.269
    collatF.a = 80;
    collatF.b = 63;
  }

  receive() external payable {}

  //Core functions

  /**
  * @dev Deposits collateral and borrows underlying in a single function call from activeProvider
  * @param _collateralAmount: amount to be deposited
  * @param _borrowAmount: amount to be borrowed
  */
  function depositAndBorrow(uint256 _collateralAmount, uint256 _borrowAmount) external payable {
    deposit(_collateralAmount);
    borrow(_borrowAmount);
  }

  /**
  * @dev Paybacks the underlying asset and withdraws collateral in a single function call from activeProvider
  * @param _paybackAmount: amount of underlying asset to be payback, pass -1 to pay full amount
  * @param _collateralAmount: amount of collateral to be withdrawn, pass -1 to withdraw maximum amount
  */
  function paybackAndWithdraw(int256 _paybackAmount, int256 _collateralAmount) external payable {
    payback(_paybackAmount);
    withdraw(_collateralAmount);
  }


  /**
  * @dev Deposit Vault's type collateral to activeProvider
  * call Controller checkrates
  * @param _collateralAmount: to be deposited
  * Emits a {Deposit} event.
  */
  function deposit(uint256 _collateralAmount) public override payable {

    require(msg.value == _collateralAmount && _collateralAmount != 0, Errors.VL_AMOUNT_ERROR);

    // Alpha Whitelist Routine
    require(
      IAlphaWhiteList(_fujiAdmin.getaWhiteList())
        .whiteListRoutine(msg.sender, vAssets.collateralID, _collateralAmount, fujiERC1155),
      Errors.SP_ALPHA_WHITELIST
    );

    // Delegate Call Deposit to current provider
    _deposit(_collateralAmount, address(activeProvider));

    // Collateral Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.collateralID, _collateralAmount, "");

    emit Deposit(msg.sender, vAssets.collateralAsset ,_collateralAmount);
  }

  /**
  * @dev Withdraws Vault's type collateral from activeProvider
  * call Controller checkrates
  * @param _withdrawAmount: amount of collateral to withdraw
  * otherwise pass -1 to withdraw maximum amount possible of collateral (including safety factors)
  * Emits a {Withdraw} event.
  */
  function withdraw(int256 _withdrawAmount) public override nonReentrant {

    // If call from Normal User do typical, otherwise Fliquidator
    if(msg.sender != _fujiAdmin.getFliquidator()) {

      updateF1155Balances();

      // Get User Collateral in this Vault
      uint256 providedCollateral = IFujiERC1155(fujiERC1155)
        .balanceOf(msg.sender, vAssets.collateralID);

      // Check User has collateral
      require(providedCollateral > 0, Errors.VL_INVALID_COLLATERAL);

      // Get Required Collateral with Factors to maintain debt position healthy
      uint256 neededCollateral = getNeededCollateralFor(
        IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID),
        true
      );

      uint256 amountToWithdraw = _withdrawAmount < 0
        ? providedCollateral.sub(neededCollateral)
        : uint256(_withdrawAmount);

        // Check Withdrawal amount, and that it will not fall undercollaterized.
        require(
          amountToWithdraw != 0 &&
          providedCollateral.sub(amountToWithdraw) >= neededCollateral,
          Errors.VL_INVALID_WITHDRAW_AMOUNT
        );

      // Collateral Management before Withdraw Operation
      IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.collateralID, amountToWithdraw);

      // Delegate Call Withdraw to current provider
      _withdraw(amountToWithdraw, address(activeProvider));

      // Transer Assets to User
      IERC20(vAssets.collateralAsset).uniTransfer(msg.sender, amountToWithdraw);

      emit Withdraw(msg.sender, vAssets.collateralAsset, amountToWithdraw);

    } else {

      // Logic used when called by Fliquidator
      _withdraw(uint256(_withdrawAmount), address(activeProvider));
      IERC20(vAssets.collateralAsset).uniTransfer(msg.sender, uint256(_withdrawAmount));
    }
  }

  /**
  * @dev Borrows Vault's type underlying amount from activeProvider
  * @param _borrowAmount: token amount of underlying to borrow
  * Emits a {Borrow} event.
  */
  function borrow(uint256 _borrowAmount) public override nonReentrant {

    updateF1155Balances();

    uint256 providedCollateral = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.collateralID);

    // Get Required Collateral with Factors to maintain debt position healthy
    uint256 neededCollateral = getNeededCollateralFor(
      _borrowAmount.add(IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID)),
      true
    );

    // Check Provided Collateral is not Zero, and greater than needed to maintain healthy position
    require(
      _borrowAmount != 0 &&
      providedCollateral > neededCollateral,
      Errors.VL_INVALID_BORROW_AMOUNT
    );

    // Debt Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.borrowID, _borrowAmount, "");

    // Delegate Call Borrow to current provider
    _borrow(_borrowAmount, address(activeProvider));

    // Transer Assets to User
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, _borrowAmount);

    emit Borrow(msg.sender, vAssets.borrowAsset, _borrowAmount);
  }

  /**
  * @dev Paybacks Vault's type underlying to activeProvider
  * @param _repayAmount: token amount of underlying to repay, or pass -1 to repay full ammount
  * Emits a {Repay} event.
  */
  function payback(int256 _repayAmount) public override payable {

    // If call from Normal User do typical, otherwise Fliquidator
    if (msg.sender != _fujiAdmin.getFliquidator()) {

      updateF1155Balances();

      uint256 userDebtBalance = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID);

      // Check User Debt is greater than Zero and amount is not Zero
      require(
        _repayAmount != 0 &&
        userDebtBalance > 0,
        Errors.VL_NO_DEBT_TO_PAYBACK
      );

      // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

      // If passed argument amount is negative do MAX
      uint256 amountToPayback = _repayAmount < 0
        ? userDebtBalance
        : uint256(_repayAmount);

      // Check User Allowance
      require(
        IERC20(vAssets.borrowAsset).allowance(msg.sender, address(this)) >= amountToPayback,
        Errors.VL_MISSING_ERC20_ALLOWANCE
      );

      // Transfer Asset from User to Vault
      IERC20(vAssets.borrowAsset).transferFrom(msg.sender, address(this), amountToPayback);

      // Delegate Call Payback to current provider
      _payback(amountToPayback, address(activeProvider));

      //TODO: Transfer corresponding Debt Amount to Fuji Treasury

      // Debt Management
      IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.borrowID, amountToPayback);

      emit Payback(msg.sender, vAssets.borrowAsset, userDebtBalance);

    } else {

      // Logic used when called by Fliquidator
      _payback(uint256(_repayAmount), address(activeProvider));

    }
  }

  /**
  * @dev Changes Vault debt and collateral to newProvider, called by Flasher
  * @param _newProvider new provider's address
  * @param _flashLoanAmount amount of flashloan underlying to repay Flashloan
  * Emits a {Switch} event.
  */
  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanAmount,
    uint256 fee
  ) external override onlyFlash whenNotPaused {

    // Compute Ratio of transfer before payback
    uint256 ratio = (_flashLoanAmount).mul(1e18).div(borrowBalance(activeProvider));

    // Payback current provider
    _payback(_flashLoanAmount, activeProvider);

    // Withdraw collateral proportional ratio from current provider
    uint256 collateraltoMove = (depositBalance(activeProvider)).mul(ratio).div(1e18);
    _withdraw(collateraltoMove, activeProvider);

    // Deposit to the new provider
    _deposit(collateraltoMove, _newProvider);

    // Borrow from the new provider, borrowBalance + premium
    _borrow(_flashLoanAmount.add(fee), _newProvider);

    // return borrowed amount to Flasher
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, _flashLoanAmount.add(fee));

    emit Switch(address(this), activeProvider, _newProvider, _flashLoanAmount, collateraltoMove);
  }

  //Setter, change state functions

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public onlyOwner {
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }

  /**
  * @dev Sets a new active provider for the Vault
  * @param _provider: fuji address of the new provider
  * Emits a {SetActiveProvider} event.
  */
  function setActiveProvider(address _provider) external override isAuthorized {
    activeProvider = _provider;

    emit SetActiveProvider(_provider);
  }

  //Administrative functions

  /**
  * @dev Sets a fujiERC1155 Collateral and Debt Asset manager for this vault and initializes it.
  * @param _fujiERC1155: fuji ERC1155 address
  */
  function setFujiERC1155(address _fujiERC1155) external isAuthorized {
    fujiERC1155 = _fujiERC1155;

    vAssets.collateralID = IFujiERC1155(_fujiERC1155)
      .addInitializeAsset(IFujiERC1155.AssetType.collateralToken, address(this));
    vAssets.borrowID = IFujiERC1155(_fujiERC1155)
      .addInitializeAsset(IFujiERC1155.AssetType.debtToken, address(this));
  }

  /**
  * @dev Set Factors "a" and "b" for a Struct Factor
  * For safetyF;  Sets Safety Factor of Vault, should be > 1, a/b
  * For collatF; Sets Collateral Factor of Vault, should be > 1, a/b
  * @param _newFactorA: Nominator
  * @param _newFactorB: Denominator
  * @param _isSafety: safetyF or collatF
  */
  function setFactor(uint64 _newFactorA, uint64 _newFactorB, bool _isSafety) external isAuthorized {
    if(_isSafety) {
      safetyF.a = _newFactorA;
      safetyF.b = _newFactorB;
    } else {
      collatF.a = _newFactorA;
      collatF.b = _newFactorB;
    }
  }

  /**
  * @dev Sets the Oracle address (Must Comply with AggregatorV3Interface)
  * @param _oracle: new Oracle address
  */
  function setOracle(address _oracle) external isAuthorized {
    oracle = AggregatorV3Interface(_oracle);
  }

  /**
  * @dev Set providers to the Vault
  * @param _providers: new providers' addresses
  */
  function setProviders(address[] calldata _providers) external isAuthorized {
    providers = _providers;
  }

  /**
  * @dev External Function to call updateState in F1155
  */
  function updateF1155Balances() public override {
    IFujiERC1155(fujiERC1155).updateState(vAssets.borrowID, allborrowBalance());
    IFujiERC1155(fujiERC1155).updateState(vAssets.collateralID, alldepositBalance());
  }

  //Getter Functions

  /**
  * @dev Returns an array of the Vault's providers
  */
  function getProviders() external view override returns(address[] memory) {
    return providers;
  }

  /**
  * @dev Returns an amount to be paid as bonus for liquidation
  * @param _amount: Vault underlying type intended to be liquidated
  * @param _flash: Flash or classic type of liquidation, bonus differs
  */
  function getLiquidationBonusFor(
    uint256 _amount,
    bool _flash
  ) external view override returns(uint256) {
    if (_flash) {
      // Bonus Factors for Flash Liquidation
      (uint64 a, uint64 b) = _fujiAdmin.getBonusFlashL();
      return _amount.mul(a).div(b);
    }
    else {
      //Bonus Factors for Normal Liquidation
      (uint64 a, uint64 b) = _fujiAdmin.getBonusLiq();
      return _amount.mul(a).div(b);
    }
  }

  /**
  * @dev Returns the amount of collateral needed, including or not safety factors
  * @param _amount: Vault underlying type intended to be borrowed
  * @param _withFactors: Inidicate if computation should include safety_Factors
  */
  function getNeededCollateralFor(uint256 _amount, bool _withFactors) public view override returns(uint256) {
    // Get price of DAI in ETH
    (,int256 latestPrice,,,) = oracle.latestRoundData();
    uint256 minimumReq = (_amount.mul(1e12).mul(uint256(latestPrice))).div(BASE);

    if (_withFactors) {
      return minimumReq.mul(collatF.a).mul(safetyF.a).div(collatF.b).div(safetyF.b);
    } else {
      return minimumReq;
    }
  }

  /**
  * @dev Returns the borrow balance of the Vault's underlying at a particular provider
  * @param _provider: address of a provider
  */
  function borrowBalance(address _provider) public view override returns(uint256) {
    return IProvider(_provider).getBorrowBalance(vAssets.borrowAsset);
  }

  /**
  * @dev Returns the total borrow balance of the Vault's underlying at all providers
  */
  function allborrowBalance() public view returns(uint256 value) {
    for(uint i = 0; i < providers.length; i++){
      value += IProvider(providers[i]).getBorrowBalance(vAssets.borrowAsset);
    }
  }

  /**
  * @dev Returns the deposit balance of the Vault's type collateral at a particular provider
  * @param _provider: address of a provider
  */
  function depositBalance(address _provider) public view override returns(uint256) {
    return IProvider(_provider).getDepositBalance(vAssets.collateralAsset);
  }

  /**
  * @dev Returns the total deposit balance of the Vault's type collateral at all providers
  */
  function alldepositBalance() public view returns(uint256 value) {
    for(uint i = 0; i < providers.length; i++){
      value += IProvider(providers[i]).getDepositBalance(vAssets.collateralAsset);
    }
  }

  /**
  * @dev Harvests the Rewards from baseLayer Protocols
  * @param _farmProtocolNum: number per VaultHarvester Contract for specific farm
  */
  function harvestRewards(uint256 _farmProtocolNum) public onlyOwner {
    address tokenReturned = IVaultHarvester(_fujiAdmin.getVaultHarvester())
      .collectRewards(_farmProtocolNum);
    uint256 tokenBal = IERC20(tokenReturned).balanceOf(address(this));
    require(
      tokenReturned != address(0) &&
      tokenBal > 0,
      Errors.VL_HARVESTING_FAILED
    );
    IERC20(tokenReturned).uniTransfer(payable(_fujiAdmin.getTreasury()), tokenBal);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IVault {
  // Events

  // Log Users Deposit
  event Deposit(address indexed userAddrs, address indexed asset, uint256 amount);
  // Log Users withdraw
  event Withdraw(address indexed userAddrs, address indexed asset, uint256 amount);
  // Log Users borrow
  event Borrow(address indexed userAddrs, address indexed asset, uint256 amount);
  // Log Users debt repay
  event Payback(address indexed userAddrs, address indexed asset, uint256 amount);

  // Log New active provider
  event SetActiveProvider(address providerAddr);
  // Log Switch providers
  event Switch(
    address vault,
    address fromProviderAddrs,
    address toProviderAddr,
    uint256 Debtamount,
    uint256 Collattamount
  );

  // Core Vault Functions

  function deposit(uint256 _collateralAmount) external payable;

  function withdraw(int256 _withdrawAmount) external;

  function borrow(uint256 _borrowAmount) external;

  function payback(int256 _repayAmount) external payable;

  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanDebt,
    uint256 fee
  ) external;

  //Getter Functions

  function activeProvider() external view returns (address);

  function borrowBalance(address _provider) external view returns (uint256);

  function depositBalance(address _provider) external view returns (uint256);

  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    external
    view
    returns (uint256);

  function getLiquidationBonusFor(uint256 _amount, bool _flash) external view returns (uint256);

  function getProviders() external view returns (address[] memory);

  function fujiERC1155() external view returns (address);

  //Setter Functions

  function setActiveProvider(address _provider) external;

  function updateF1155Balances() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";

contract VaultControl is Ownable, Pausable {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  //Asset Struct
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  //Vault Struct for Managed Assets
  VaultAssets public vAssets;

  //Pause Functions

  /**
   * @dev Emergency Call to stop all basic money flow functions.
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @dev Emergency Call to stop all basic money flow functions.
   */
  function unpause() public onlyOwner {
    _pause();
  }
}

contract VaultBase is VaultControl {
  // Internal functions

  /**
   * @dev Executes deposit operation with delegatecall.
   * @param _amount: amount to be deposited
   * @param _provider: address of provider to be used
   */
  function _deposit(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("deposit(address,uint256)", vAssets.collateralAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Executes withdraw operation with delegatecall.
   * @param _amount: amount to be withdrawn
   * @param _provider: address of provider to be used
   */
  function _withdraw(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("withdraw(address,uint256)", vAssets.collateralAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Executes borrow operation with delegatecall.
   * @param _amount: amount to be borrowed
   * @param _provider: address of provider to be used
   */
  function _borrow(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("borrow(address,uint256)", vAssets.borrowAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Executes payback operation with delegatecall.
   * @param _amount: amount to be paid back
   * @param _provider: address of provider to be used
   */
  function _payback(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("payback(address,uint256)", vAssets.borrowAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Returns byte response of delegatcalls
   */
  function _execute(address _target, bytes memory _data)
    internal
    whenNotPaused
    returns (bytes memory response)
  {
    /* solhint-disable */
    assembly {
      let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
      let size := returndatasize()

      response := mload(0x40)
      mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(response, size)
      returndatacopy(add(response, 0x20), 0, size)

      switch iszero(succeeded)
        case 1 {
          // throw if delegatecall failed
          revert(add(response, 0x20), size)
        }
    }
    /* solhint-disable */
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

interface IFujiAdmin {
  function getFlasher() external view returns (address);

  function getFliquidator() external view returns (address);

  function getController() external view returns (address);

  function getTreasury() external view returns (address payable);

  function getaWhiteList() external view returns (address);

  function getVaultHarvester() external view returns (address);

  function getBonusFlashL() external view returns (uint64, uint64);

  function getBonusLiq() external view returns (uint64, uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IFujiERC1155 {
  //Asset Types
  enum AssetType {
    //uint8 = 0
    collateralToken,
    //uint8 = 1
    debtToken
  }

  //General Getter Functions

  function getAssetID(AssetType _type, address _assetAddr) external view returns (uint256);

  function qtyOfManagedAssets() external view returns (uint64);

  function balanceOf(address _account, uint256 _id) external view returns (uint256);

  //function splitBalanceOf(address account,uint256 _AssetID) external view  returns (uint256,uint256);

  //function balanceOfBatchType(address account, AssetType _Type) external view returns (uint256);

  //Permit Controlled  Functions
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) external;

  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function updateState(uint256 _assetID, uint256 _newBalance) external;

  function addInitializeAsset(AssetType _type, address _addr) external returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

interface IProvider {
  //Basic Core Functions

  function deposit(address _collateralAsset, uint256 _collateralAmount) external payable;

  function borrow(address _borrowAsset, uint256 _borrowAmount) external payable;

  function withdraw(address _collateralAsset, uint256 _collateralAmount) external payable;

  function payback(address _borrowAsset, uint256 _borrowAmount) external payable;

  // returns the borrow annualized rate for an asset in ray (1e27)
  //Example 8.5% annual interest = 0.085 x 10^27 = 85000000000000000000000000 or 85*(10**24)
  function getBorrowRateFor(address _asset) external view returns (uint256);

  function getBorrowBalance(address _asset) external view returns (uint256);

  function getDepositBalance(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

interface IAlphaWhiteList {
  function whiteListRoutine(
    address _usrAddrs,
    uint64 _assetId,
    uint256 _amount,
    address _erc1155
  ) external returns(bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity <0.8.0;

/**
 * @title Errors library
 * @author Fuji
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = Validation Logic 100 series
 *  - MATH = Math libraries 200 series
 *  - RF = Refinancing 300 series
 *  - VLT = vault 400 series
 *  - SP = Special 900 series
 */
library Errors {

  //Errors
  string public constant VL_INDEX_OVERFLOW = '100'; // index overflows uint128
  string public constant VL_INVALID_MINT_AMOUNT = '101'; //invalid amount to mint
  string public constant VL_INVALID_BURN_AMOUNT = '102'; //invalid amount to burn
  string public constant VL_AMOUNT_ERROR = '103'; //Input value >0, and for ETH msg.value and amount shall match
  string public constant VL_INVALID_WITHDRAW_AMOUNT = '104'; //Withdraw amount exceeds provided collateral, or falls undercollaterized
  string public constant VL_INVALID_BORROW_AMOUNT = '105'; //Borrow amount does not meet collaterization
  string public constant VL_NO_DEBT_TO_PAYBACK = '106'; //Msg sender has no debt amount to be payback
  string public constant VL_MISSING_ERC20_ALLOWANCE = '107'; //Msg sender has not approved ERC20 full amount to transfer
  string public constant VL_USER_NOT_LIQUIDATABLE = '108'; //User debt position is not liquidatable
  string public constant VL_DEBT_LESS_THAN_AMOUNT = '109'; //User debt is less than amount to partial close
  string public constant VL_PROVIDER_ALREADY_ADDED = '110'; // Provider is already added in Provider Array
  string public constant VL_NOT_AUTHORIZED = '111'; //Not authorized
  string public constant VL_INVALID_COLLATERAL = '112'; //There is no Collateral, or Collateral is not in active in vault
  string public constant VL_NO_ERC20_BALANCE = '113'; //User does not have ERC20 balance
  string public constant VL_INPUT_ERROR = '114'; //Check inputs. For ERC1155 batch functions, array sizes should match.
  string public constant VL_ASSET_EXISTS ='115';  //Asset intended to be added already exists in FujiERC1155
  string public constant VL_ZERO_ADDR_1155 ='116'; //ERC1155: balance/transfer for zero address
  string public constant VL_NOT_A_CONTRACT = '117'; //Address is not a contract.
  string public constant VL_INVALID_ASSETID_1155 = '118'; //ERC1155 Asset ID is invalid.
  string public constant VL_NO_ERC1155_BALANCE ='119';//ERC1155: insufficient balance for transfer.
  string public constant VL_MISSING_ERC1155_APPROVAL = '120'; //ERC1155: transfer caller is not owner nor approved.
  string public constant VL_RECEIVER_REJECT_1155 = '121'; //ERC1155Receiver rejected tokens
  string public constant VL_RECEIVER_CONTRACT_NON_1155 = '122'; //ERC1155: transfer to non ERC1155Receiver implementer
  string public constant VL_OPTIMIZER_FEE_SMALL ='123'; //Fuji OptimizerFee has to be > 1 RAY (1e27)
  string public constant VL_UNDERCOLLATERIZED_ERROR = '124'; // Flashloan-Flashclose cannot be used when User's collateral is worth less than intended debt position to close.
  string public constant VL_MINIMUM_PAYBACK_ERROR = '125'; // Minimum Amount payback should be at least Fuji Optimizerfee accrued interest.
  string public constant VL_HARVESTING_FAILED = '126'; //Harvesting Function failed, check provided _farmProtocolNum or no claimable balance. 

  string public constant MATH_DIVISION_BY_ZERO = '201';
  string public constant MATH_ADDITION_OVERFLOW = '202';
  string public constant MATH_MULTIPLICATION_OVERFLOW = '203';

  string public constant RF_NO_GREENLIGHT = '300'; // Conditions for refinancing are not met, greenLight, deltaAPRThreshold, deltatimestampThreshold
  string public constant RF_INVALID_RATIO_VALUES = '301'; // Ratio Value provided is invalid, _ratioA/_ratioB <= 1, and > 0, or activeProvider borrowBalance = 0
  string public constant RF_CHECK_RATES_FALSE = '302'; //Check Rates routine returned False

  string public constant VLT_CALLER_MUST_BE_VAULT = '401'; // The caller of this function must be a vault

  string public constant SP_ALPHA_WHITELIST = '901'; // One ETH cap value for Alpha Version < 1 ETH



}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library UniERC20 {
  using SafeERC20 for IERC20;

  IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  IERC20 private constant _ZERO_ADDRESS = IERC20(0);

  function isETH(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
  }

  function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
    if (isETH(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
    if (amount > 0) {
      if (isETH(token)) {
        to.transfer(amount);
      } else {
        token.safeTransfer(to, amount);
      }
    }
  }

  function uniApprove(IERC20 token, address to, uint256 amount) internal {
    require(!isETH(token), "Approve called on ETH");

    if (amount == 0) {
      token.safeApprove(to, 0);
    } else {
      uint256 allowance = token.allowance(address(this), to);
      if (allowance < amount) {
        if (allowance > 0) {
          token.safeApprove(to, 0);
        }
        token.safeApprove(to, amount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.4.25 <0.8.0;
pragma experimental ABIEncoderV2;

import { IVault } from "./IVault.sol";
import { VaultBase } from "./VaultBase.sol";
import { IFujiAdmin } from "../IFujiAdmin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFujiERC1155 } from "../FujiERC1155/IFujiERC1155.sol";
import { IProvider } from "../Providers/IProvider.sol";
import { IAlphaWhiteList } from "../IAlphaWhiteList.sol";
import { Errors } from "../Libraries/Errors.sol";

interface IVaultHarvester{
  function collectRewards(uint256 _farmProtocolNum) external returns(address claimedToken);
}

contract VaultETHUSDC is IVault, VaultBase, ReentrancyGuard {

  uint256 internal constant BASE = 1e18;

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Safety factor
  Factor public safetyF;

  // Collateralization factor
  Factor public collatF;

  //State variables
  address[] public providers;
  address public override activeProvider;

  IFujiAdmin private _fujiAdmin;
  address public override fujiERC1155;
  AggregatorV3Interface public oracle;

  modifier isAuthorized() {
    require(
      msg.sender == _fujiAdmin.getController() ||
      msg.sender == owner(),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  modifier onlyFlash() {
    require(
      msg.sender == _fujiAdmin.getFlasher(),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  constructor () public {

    vAssets.collateralAsset = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
    vAssets.borrowAsset = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC

    // 1.05
    safetyF.a = 21;
    safetyF.b = 20;

    // 1.269
    collatF.a = 80;
    collatF.b = 63;
  }

  receive() external payable {}

  //Core functions

  /**
  * @dev Deposits collateral and borrows underlying in a single function call from activeProvider
  * @param _collateralAmount: amount to be deposited
  * @param _borrowAmount: amount to be borrowed
  */
  function depositAndBorrow(uint256 _collateralAmount, uint256 _borrowAmount) external payable {
    deposit(_collateralAmount);
    borrow(_borrowAmount);
  }

  /**
  * @dev Paybacks the underlying asset and withdraws collateral in a single function call from activeProvider
  * @param _paybackAmount: amount of underlying asset to be payback, pass -1 to pay full amount
  * @param _collateralAmount: amount of collateral to be withdrawn, pass -1 to withdraw maximum amount
  */
  function paybackAndWithdraw(int256 _paybackAmount, int256 _collateralAmount) external payable {
    payback(_paybackAmount);
    withdraw(_collateralAmount);
  }


  /**
  * @dev Deposit Vault's type collateral to activeProvider
  * call Controller checkrates
  * @param _collateralAmount: to be deposited
  * Emits a {Deposit} event.
  */
  function deposit(uint256 _collateralAmount) public override payable {

    require(msg.value == _collateralAmount && _collateralAmount != 0, Errors.VL_AMOUNT_ERROR);

    // Alpha Whitelist Routine
    require(
      IAlphaWhiteList(_fujiAdmin.getaWhiteList())
        .whiteListRoutine(msg.sender, vAssets.collateralID, _collateralAmount, fujiERC1155),
      Errors.SP_ALPHA_WHITELIST
    );

    // Delegate Call Deposit to current provider
    _deposit(_collateralAmount, address(activeProvider));

    // Collateral Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.collateralID, _collateralAmount, "");

    emit Deposit(msg.sender, vAssets.collateralAsset ,_collateralAmount);
  }

  /**
  * @dev Withdraws Vault's type collateral from activeProvider
  * call Controller checkrates
  * @param _withdrawAmount: amount of collateral to withdraw
  * otherwise pass -1 to withdraw maximum amount possible of collateral (including safety factors)
  * Emits a {Withdraw} event.
  */
  function withdraw(int256 _withdrawAmount) public override nonReentrant {

    // If call from Normal User do typical, otherwise Fliquidator
    if(msg.sender != _fujiAdmin.getFliquidator()) {

      updateF1155Balances();

      // Get User Collateral in this Vault
      uint256 providedCollateral = IFujiERC1155(fujiERC1155)
        .balanceOf(msg.sender, vAssets.collateralID);

      // Check User has collateral
      require(providedCollateral > 0, Errors.VL_INVALID_COLLATERAL);

      // Get Required Collateral with Factors to maintain debt position healthy
      uint256 neededCollateral = getNeededCollateralFor(
        IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID),
        true
      );

      uint256 amountToWithdraw = _withdrawAmount < 0
        ? providedCollateral.sub(neededCollateral)
        : uint256(_withdrawAmount);

        // Check Withdrawal amount, and that it will not fall undercollaterized.
        require(
          amountToWithdraw != 0 &&
          providedCollateral.sub(amountToWithdraw) >= neededCollateral,
          Errors.VL_INVALID_WITHDRAW_AMOUNT
        );

      // Collateral Management before Withdraw Operation
      IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.collateralID, amountToWithdraw);

      // Delegate Call Withdraw to current provider
      _withdraw(amountToWithdraw, address(activeProvider));

      // Transer Assets to User
      IERC20(vAssets.collateralAsset).uniTransfer(msg.sender, amountToWithdraw);

      emit Withdraw(msg.sender, vAssets.collateralAsset, amountToWithdraw);

    } else {

      // Logic used when called by Fliquidator
      _withdraw(uint256(_withdrawAmount), address(activeProvider));
      IERC20(vAssets.collateralAsset).uniTransfer(msg.sender, uint256(_withdrawAmount));
    }
  }

  /**
  * @dev Borrows Vault's type underlying amount from activeProvider
  * @param _borrowAmount: token amount of underlying to borrow
  * Emits a {Borrow} event.
  */
  function borrow(uint256 _borrowAmount) public override nonReentrant {

    updateF1155Balances();

    uint256 providedCollateral = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.collateralID);

    // Get Required Collateral with Factors to maintain debt position healthy
    uint256 neededCollateral = getNeededCollateralFor(
      _borrowAmount.add(IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID)),
      true
    );

    // Check Provided Collateral is not Zero, and greater than needed to maintain healthy position
    require(
      _borrowAmount != 0 &&
      providedCollateral > neededCollateral,
      Errors.VL_INVALID_BORROW_AMOUNT
    );

    // Debt Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.borrowID, _borrowAmount, "");

    // Delegate Call Borrow to current provider
    _borrow(_borrowAmount, address(activeProvider));

    // Transer Assets to User
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, _borrowAmount);

    emit Borrow(msg.sender, vAssets.borrowAsset, _borrowAmount);
  }

  /**
  * @dev Paybacks Vault's type underlying to activeProvider
  * @param _repayAmount: token amount of underlying to repay, or pass -1 to repay full ammount
  * Emits a {Repay} event.
  */
  function payback(int256 _repayAmount) public override payable {

    // If call from Normal User do typical, otherwise Fliquidator
    if (msg.sender != _fujiAdmin.getFliquidator()) {

      updateF1155Balances();

      uint256 userDebtBalance = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID);

      // Check User Debt is greater than Zero and amount is not Zero
      require(
        _repayAmount != 0 &&
        userDebtBalance > 0,
        Errors.VL_NO_DEBT_TO_PAYBACK
      );

      // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

      // If passed argument amount is negative do MAX
      uint256 amountToPayback = _repayAmount < 0
        ? userDebtBalance
        : uint256(_repayAmount);

      // Check User Allowance
      require(
        IERC20(vAssets.borrowAsset).allowance(msg.sender, address(this)) >= amountToPayback,
        Errors.VL_MISSING_ERC20_ALLOWANCE
      );

      // Transfer Asset from User to Vault
      IERC20(vAssets.borrowAsset).transferFrom(msg.sender, address(this), amountToPayback);

      // Delegate Call Payback to current provider
      _payback(amountToPayback, address(activeProvider));

      //TODO: Transfer corresponding Debt Amount to Fuji Treasury

      // Debt Management
      IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.borrowID, amountToPayback);

      emit Payback(msg.sender, vAssets.borrowAsset, userDebtBalance);

    } else {

      // Logic used when called by Fliquidator
      _payback(uint256(_repayAmount), address(activeProvider));

    }
  }

  /**
  * @dev Changes Vault debt and collateral to newProvider, called by Flasher
  * @param _newProvider new provider's address
  * @param _flashLoanAmount amount of flashloan underlying to repay Flashloan
  * Emits a {Switch} event.
  */
  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanAmount,
    uint256 fee
  ) external override onlyFlash whenNotPaused {

    // Compute Ratio of transfer before payback
    uint256 ratio = (_flashLoanAmount).mul(1e18).div(borrowBalance(activeProvider));

    // Payback current provider
    _payback(_flashLoanAmount, activeProvider);

    // Withdraw collateral proportional ratio from current provider
    uint256 collateraltoMove = (depositBalance(activeProvider)).mul(ratio).div(1e18);
    _withdraw(collateraltoMove, activeProvider);

    // Deposit to the new provider
    _deposit(collateraltoMove, _newProvider);

    // Borrow from the new provider, borrowBalance + premium
    _borrow(_flashLoanAmount.add(fee), _newProvider);

    // return borrowed amount to Flasher
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, _flashLoanAmount.add(fee));

    emit Switch(address(this), activeProvider, _newProvider, _flashLoanAmount, collateraltoMove);
  }

  //Setter, change state functions

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public onlyOwner {
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }

  /**
  * @dev Sets a new active provider for the Vault
  * @param _provider: fuji address of the new provider
  * Emits a {SetActiveProvider} event.
  */
  function setActiveProvider(address _provider) external override isAuthorized {
    activeProvider = _provider;

    emit SetActiveProvider(_provider);
  }

  //Administrative functions

  /**
  * @dev Sets a fujiERC1155 Collateral and Debt Asset manager for this vault and initializes it.
  * @param _fujiERC1155: fuji ERC1155 address
  */
  function setFujiERC1155(address _fujiERC1155) external isAuthorized {
    fujiERC1155 = _fujiERC1155;

    vAssets.collateralID = IFujiERC1155(_fujiERC1155)
      .addInitializeAsset(IFujiERC1155.AssetType.collateralToken, address(this));
    vAssets.borrowID = IFujiERC1155(_fujiERC1155)
      .addInitializeAsset(IFujiERC1155.AssetType.debtToken, address(this));
  }

  /**
  * @dev Set Factors "a" and "b" for a Struct Factor
  * For safetyF;  Sets Safety Factor of Vault, should be > 1, a/b
  * For collatF; Sets Collateral Factor of Vault, should be > 1, a/b
  * @param _newFactorA: Nominator
  * @param _newFactorB: Denominator
  * @param _isSafety: safetyF or collatF
  */
  function setFactor(uint64 _newFactorA, uint64 _newFactorB, bool _isSafety) external isAuthorized {
    if(_isSafety) {
      safetyF.a = _newFactorA;
      safetyF.b = _newFactorB;
    } else {
      collatF.a = _newFactorA;
      collatF.b = _newFactorB;
    }
  }

  /**
  * @dev Sets the Oracle address (Must Comply with AggregatorV3Interface)
  * @param _oracle: new Oracle address
  */
  function setOracle(address _oracle) external isAuthorized {
    oracle = AggregatorV3Interface(_oracle);
  }

  /**
  * @dev Set providers to the Vault
  * @param _providers: new providers' addresses
  */
  function setProviders(address[] calldata _providers) external isAuthorized {
    providers = _providers;
  }

  /**
  * @dev External Function to call updateState in F1155
  */
  function updateF1155Balances() public override {
    IFujiERC1155(fujiERC1155).updateState(vAssets.borrowID, allborrowBalance());
    IFujiERC1155(fujiERC1155).updateState(vAssets.collateralID, alldepositBalance());
  }

  //Getter Functions

  /**
  * @dev Returns an array of the Vault's providers
  */
  function getProviders() external view override returns(address[] memory) {
    return providers;
  }

  /**
  * @dev Returns an amount to be paid as bonus for liquidation
  * @param _amount: Vault underlying type intended to be liquidated
  * @param _flash: Flash or classic type of liquidation, bonus differs
  */
  function getLiquidationBonusFor(
    uint256 _amount,
    bool _flash
  ) external view override returns(uint256) {
    if (_flash) {
      // Bonus Factors for Flash Liquidation
      (uint64 a, uint64 b) = _fujiAdmin.getBonusFlashL();
      return _amount.mul(a).div(b);
    }
    else {
      //Bonus Factors for Normal Liquidation
      (uint64 a, uint64 b) = _fujiAdmin.getBonusLiq();
      return _amount.mul(a).div(b);
    }
  }

  /**
  * @dev Returns the amount of collateral needed, including or not safety factors
  * @param _amount: Vault underlying type intended to be borrowed
  * @param _withFactors: Inidicate if computation should include safety_Factors
  */
  function getNeededCollateralFor(uint256 _amount, bool _withFactors) public view override returns(uint256) {
    // Get price of DAI in ETH
    (,int256 latestPrice,,,) = oracle.latestRoundData();
    uint256 minimumReq = (_amount.mul(1e12).mul(uint256(latestPrice))).div(BASE);

    if (_withFactors) {
      return minimumReq.mul(collatF.a).mul(safetyF.a).div(collatF.b).div(safetyF.b);
    } else {
      return minimumReq;
    }
  }

  /**
  * @dev Returns the borrow balance of the Vault's underlying at a particular provider
  * @param _provider: address of a provider
  */
  function borrowBalance(address _provider) public view override returns(uint256) {
    return IProvider(_provider).getBorrowBalance(vAssets.borrowAsset);
  }

  /**
  * @dev Returns the total borrow balance of the Vault's underlying at all providers
  */
  function allborrowBalance() public view returns(uint256 value) {
    for(uint i = 0; i < providers.length; i++){
      value += IProvider(providers[i]).getBorrowBalance(vAssets.borrowAsset);
    }
  }

  /**
  * @dev Returns the deposit balance of the Vault's type collateral at a particular provider
  * @param _provider: address of a provider
  */
  function depositBalance(address _provider) public view override returns(uint256) {
    return IProvider(_provider).getDepositBalance(vAssets.collateralAsset);
  }

  /**
  * @dev Returns the total deposit balance of the Vault's type collateral at all providers
  */
  function alldepositBalance() public view returns(uint256 value) {
    for(uint i = 0; i < providers.length; i++){
      value += IProvider(providers[i]).getDepositBalance(vAssets.collateralAsset);
    }
  }

  /**
  * @dev Harvests the Rewards from baseLayer Protocols
  * @param _farmProtocolNum: number per VaultHarvester Contract for specific farm
  */
  function harvestRewards(uint256 _farmProtocolNum) public onlyOwner {
    address tokenReturned = IVaultHarvester(_fujiAdmin.getVaultHarvester())
      .collectRewards(_farmProtocolNum);
    uint256 tokenBal = IERC20(tokenReturned).balanceOf(address(this));
    require(
      tokenReturned != address(0) &&
      tokenBal > 0,
      Errors.VL_HARVESTING_FAILED
    );
    IERC20(tokenReturned).uniTransfer(payable(_fujiAdmin.getTreasury()), tokenBal);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import { IVault } from "./IVault.sol";
import { VaultBase } from "./VaultBase.sol";
import { IFujiAdmin } from "../IFujiAdmin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {
  AggregatorV3Interface
} from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFujiERC1155 } from "../FujiERC1155/IFujiERC1155.sol";
import { IProvider } from "../Providers/IProvider.sol";
import { IAlphaWhiteList } from "../IAlphaWhiteList.sol";
import { Errors } from "../Libraries/Errors.sol";

import "hardhat/console.sol"; //test line

interface IVaultHarvester {
  function collectRewards(uint256 _farmProtocolNum) external returns (address claimedToken);
}

contract VaultETHDAI is IVault, VaultBase, ReentrancyGuard {
  uint256 internal constant _BASE = 1e18;

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Safety factor
  Factor public safetyF;

  // Collateralization factor
  Factor public collatF;

  //State variables
  address[] public providers;
  address public override activeProvider;

  IFujiAdmin private _fujiAdmin;
  address public override fujiERC1155;
  AggregatorV3Interface public oracle;

  modifier isAuthorized() {
    require(
      msg.sender == _fujiAdmin.getController() || msg.sender == owner(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  modifier onlyFlash() {
    require(msg.sender == _fujiAdmin.getFlasher(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  constructor() public {
    vAssets.collateralAsset = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
    vAssets.borrowAsset = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI

    // 1.05
    safetyF.a = 21;
    safetyF.b = 20;

    // 1.269
    collatF.a = 80;
    collatF.b = 63;
  }

  receive() external payable {}

  //Core functions

  /**
   * @dev Deposits collateral and borrows underlying in a single function call from activeProvider
   * @param _collateralAmount: amount to be deposited
   * @param _borrowAmount: amount to be borrowed
   */
  function depositAndBorrow(uint256 _collateralAmount, uint256 _borrowAmount) external payable {
    deposit(_collateralAmount);
    borrow(_borrowAmount);
  }

  /**
   * @dev Paybacks the underlying asset and withdraws collateral in a single function call from activeProvider
   * @param _paybackAmount: amount of underlying asset to be payback, pass -1 to pay full amount
   * @param _collateralAmount: amount of collateral to be withdrawn, pass -1 to withdraw maximum amount
   */
  function paybackAndWithdraw(int256 _paybackAmount, int256 _collateralAmount) external payable {
    payback(_paybackAmount);
    withdraw(_collateralAmount);
  }

  /**
   * @dev Deposit Vault's type collateral to activeProvider
   * call Controller checkrates
   * @param _collateralAmount: to be deposited
   * Emits a {Deposit} event.
   */
  function deposit(uint256 _collateralAmount) public payable override {
    require(msg.value == _collateralAmount && _collateralAmount != 0, Errors.VL_AMOUNT_ERROR);

    // Alpha Whitelist Routine
    require(
      IAlphaWhiteList(_fujiAdmin.getaWhiteList()).whiteListRoutine(
        msg.sender,
        vAssets.collateralID,
        _collateralAmount,
        fujiERC1155
      ),
      Errors.SP_ALPHA_WHITELIST
    );

    // Delegate Call Deposit to current provider
    _deposit(_collateralAmount, address(activeProvider));

    // Collateral Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.collateralID, _collateralAmount, "");

    emit Deposit(msg.sender, vAssets.collateralAsset, _collateralAmount);
  }

  /**
   * @dev Withdraws Vault's type collateral from activeProvider
   * call Controller checkrates
   * @param _withdrawAmount: amount of collateral to withdraw
   * otherwise pass -1 to withdraw maximum amount possible of collateral (including safety factors)
   * Emits a {Withdraw} event.
   */
  function withdraw(int256 _withdrawAmount) public override nonReentrant {
    // If call from Normal User do typical, otherwise Fliquidator
    if (msg.sender != _fujiAdmin.getFliquidator()) {
      updateF1155Balances();

      // Get User Collateral in this Vault
      uint256 providedCollateral =
        IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.collateralID);

      // Check User has collateral
      require(providedCollateral > 0, Errors.VL_INVALID_COLLATERAL);

      // Get Required Collateral with Factors to maintain debt position healthy
      uint256 neededCollateral =
        getNeededCollateralFor(
          IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID),
          true
        );

      uint256 amountToWithdraw =
        _withdrawAmount < 0 ? providedCollateral.sub(neededCollateral) : uint256(_withdrawAmount);

      // Check Withdrawal amount, and that it will not fall undercollaterized.
      require(
        amountToWithdraw != 0 && providedCollateral.sub(amountToWithdraw) >= neededCollateral,
        Errors.VL_INVALID_WITHDRAW_AMOUNT
      );

      // Collateral Management before Withdraw Operation
      IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.collateralID, amountToWithdraw);

      // Delegate Call Withdraw to current provider
      _withdraw(amountToWithdraw, address(activeProvider));

      // Transer Assets to User
      IERC20(vAssets.collateralAsset).uniTransfer(msg.sender, amountToWithdraw);

      emit Withdraw(msg.sender, vAssets.collateralAsset, amountToWithdraw);
    } else {
      // Logic used when called by Fliquidator
      _withdraw(uint256(_withdrawAmount), address(activeProvider));
      IERC20(vAssets.collateralAsset).uniTransfer(msg.sender, uint256(_withdrawAmount));
    }
  }

  /**
   * @dev Borrows Vault's type underlying amount from activeProvider
   * @param _borrowAmount: token amount of underlying to borrow
   * Emits a {Borrow} event.
   */
  function borrow(uint256 _borrowAmount) public override nonReentrant {
    updateF1155Balances();

    uint256 providedCollateral =
      IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.collateralID);

    // Get Required Collateral with Factors to maintain debt position healthy
    uint256 neededCollateral =
      getNeededCollateralFor(
        _borrowAmount.add(IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID)),
        true
      );

    // Check Provided Collateral is not Zero, and greater than needed to maintain healthy position
    require(
      _borrowAmount != 0 && providedCollateral > neededCollateral,
      Errors.VL_INVALID_BORROW_AMOUNT
    );

    // Debt Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.borrowID, _borrowAmount, "");

    // Delegate Call Borrow to current provider
    _borrow(_borrowAmount, address(activeProvider));

    // Transer Assets to User
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, _borrowAmount);

    emit Borrow(msg.sender, vAssets.borrowAsset, _borrowAmount);
  }

  /**
   * @dev Paybacks Vault's type underlying to activeProvider
   * @param _repayAmount: token amount of underlying to repay, or pass -1 to repay full ammount
   * Emits a {Repay} event.
   */
  function payback(int256 _repayAmount) public payable override {
    // If call from Normal User do typical, otherwise Fliquidator
    if (msg.sender != _fujiAdmin.getFliquidator()) {
      updateF1155Balances();

      uint256 userDebtBalance = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID);

      // Check User Debt is greater than Zero and amount is not Zero
      require(_repayAmount != 0 && userDebtBalance > 0, Errors.VL_NO_DEBT_TO_PAYBACK);

      // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

      // If passed argument amount is negative do MAX
      uint256 amountToPayback = _repayAmount < 0 ? userDebtBalance : uint256(_repayAmount);

      // Check User Allowance
      require(
        IERC20(vAssets.borrowAsset).allowance(msg.sender, address(this)) >= amountToPayback,
        Errors.VL_MISSING_ERC20_ALLOWANCE
      );

      // Transfer Asset from User to Vault
      IERC20(vAssets.borrowAsset).transferFrom(msg.sender, address(this), amountToPayback);

      // Delegate Call Payback to current provider
      _payback(amountToPayback, address(activeProvider));

      //TODO: Transfer corresponding Debt Amount to Fuji Treasury

      // Debt Management
      IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.borrowID, amountToPayback);

      emit Payback(msg.sender, vAssets.borrowAsset, userDebtBalance);
    } else {
      // Logic used when called by Fliquidator
      _payback(uint256(_repayAmount), address(activeProvider));
    }
  }

  /**
   * @dev Changes Vault debt and collateral to newProvider, called by Flasher
   * @param _newProvider new provider's address
   * @param _flashLoanAmount amount of flashloan underlying to repay Flashloan
   * Emits a {Switch} event.
   */
  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanAmount,
    uint256 _fee
  ) external override onlyFlash whenNotPaused {
    // Compute Ratio of transfer before payback
    uint256 ratio = (_flashLoanAmount).mul(1e18).div(borrowBalance(activeProvider));

    // Payback current provider
    _payback(_flashLoanAmount, activeProvider);

    // Withdraw collateral proportional ratio from current provider
    uint256 collateraltoMove = (depositBalance(activeProvider)).mul(ratio).div(1e18);
    _withdraw(collateraltoMove, activeProvider);

    // Deposit to the new provider
    _deposit(collateraltoMove, _newProvider);

    // Borrow from the new provider, borrowBalance + premium
    _borrow(_flashLoanAmount.add(_fee), _newProvider);

    // return borrowed amount to Flasher
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, _flashLoanAmount.add(_fee));

    emit Switch(address(this), activeProvider, _newProvider, _flashLoanAmount, collateraltoMove);
  }

  //Setter, change state functions

  /**
   * @dev Sets a new active provider for the Vault
   * @param _provider: fuji address of the new provider
   * Emits a {SetActiveProvider} event.
   */
  function setActiveProvider(address _provider) external override isAuthorized {
    activeProvider = _provider;

    emit SetActiveProvider(_provider);
  }

  //Administrative functions

  /**
   * @dev Sets the fujiAdmin Address
   * @param _newFujiAdmin: FujiAdmin Contract Address
   */
  function setFujiAdmin(address _newFujiAdmin) public onlyOwner {
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }

  /**
   * @dev Sets a fujiERC1155 Collateral and Debt Asset manager for this vault and initializes it.
   * @param _fujiERC1155: fuji ERC1155 address
   */
  function setFujiERC1155(address _fujiERC1155) external isAuthorized {
    fujiERC1155 = _fujiERC1155;

    vAssets.collateralID = IFujiERC1155(_fujiERC1155).addInitializeAsset(
      IFujiERC1155.AssetType.collateralToken,
      address(this)
    );
    vAssets.borrowID = IFujiERC1155(_fujiERC1155).addInitializeAsset(
      IFujiERC1155.AssetType.debtToken,
      address(this)
    );
  }

  /**
   * @dev Set Factors "a" and "b" for a Struct Factor
   * For safetyF;  Sets Safety Factor of Vault, should be > 1, a/b
   * For collatF; Sets Collateral Factor of Vault, should be > 1, a/b
   * @param _newFactorA: Nominator
   * @param _newFactorB: Denominator
   * @param _isSafety: safetyF or collatF
   */
  function setFactor(
    uint64 _newFactorA,
    uint64 _newFactorB,
    bool _isSafety
  ) external isAuthorized {
    if (_isSafety) {
      safetyF.a = _newFactorA;
      safetyF.b = _newFactorB;
    } else {
      collatF.a = _newFactorA;
      collatF.b = _newFactorB;
    }
  }

  /**
   * @dev Sets the Oracle address (Must Comply with AggregatorV3Interface)
   * @param _oracle: new Oracle address
   */
  function setOracle(address _oracle) external isAuthorized {
    oracle = AggregatorV3Interface(_oracle);
  }

  /**
   * @dev Set providers to the Vault
   * @param _providers: new providers' addresses
   */
  function setProviders(address[] calldata _providers) external isAuthorized {
    providers = _providers;
  }

  /**
   * @dev External Function to call updateState in F1155
   */
  function updateF1155Balances() public override {
    IFujiERC1155(fujiERC1155).updateState(vAssets.borrowID, allborrowBalance());
    IFujiERC1155(fujiERC1155).updateState(vAssets.collateralID, alldepositBalance());
  }

  //Getter Functions

  /**
   * @dev Returns an array of the Vault's providers
   */
  function getProviders() external view override returns (address[] memory) {
    return providers;
  }

  /**
   * @dev Returns an amount to be paid as bonus for liquidation
   * @param _amount: Vault underlying type intended to be liquidated
   * @param _flash: Flash or classic type of liquidation, bonus differs
   */
  function getLiquidationBonusFor(uint256 _amount, bool _flash)
    external
    view
    override
    returns (uint256)
  {
    if (_flash) {
      // Bonus Factors for Flash Liquidation
      (uint64 a, uint64 b) = _fujiAdmin.getBonusFlashL();
      return _amount.mul(a).div(b);
    } else {
      //Bonus Factors for Normal Liquidation
      (uint64 a, uint64 b) = _fujiAdmin.getBonusLiq();
      return _amount.mul(a).div(b);
    }
  }

  /**
   * @dev Returns the amount of collateral needed, including or not safety factors
   * @param _amount: Vault underlying type intended to be borrowed
   * @param _withFactors: Inidicate if computation should include safety_Factors
   */
  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    public
    view
    override
    returns (uint256)
  {
    // Get price of DAI in ETH
    (, int256 latestPrice, , , ) = oracle.latestRoundData();
    uint256 minimumReq = (_amount.mul(uint256(latestPrice))).div(_BASE);

    if (_withFactors) {
      return minimumReq.mul(collatF.a).mul(safetyF.a).div(collatF.b).div(safetyF.b);
    } else {
      return minimumReq;
    }
  }

  /**
   * @dev Returns the borrow balance of the Vault's underlying at a particular provider
   * @param _provider: address of a provider
   */
  function borrowBalance(address _provider) public view override returns (uint256) {
    return IProvider(_provider).getBorrowBalance(vAssets.borrowAsset);
  }

  /**
   * @dev Returns the total borrow balance of the Vault's underlying at all providers
   */
  function allborrowBalance() public view returns (uint256 value) {
    for (uint256 i = 0; i < providers.length; i++) {
      value += IProvider(providers[i]).getBorrowBalance(vAssets.borrowAsset);
    }
  }

  /**
   * @dev Returns the deposit balance of the Vault's type collateral at a particular provider
   * @param _provider: address of a provider
   */
  function depositBalance(address _provider) public view override returns (uint256) {
    return IProvider(_provider).getDepositBalance(vAssets.collateralAsset);
  }

  /**
   * @dev Returns the total deposit balance of the Vault's type collateral at all providers
   */
  function alldepositBalance() public view returns (uint256 value) {
    for (uint256 i = 0; i < providers.length; i++) {
      value += IProvider(providers[i]).getDepositBalance(vAssets.collateralAsset);
    }
  }

  /**
   * @dev Harvests the Rewards from baseLayer Protocols
   * @param _farmProtocolNum: number per VaultHarvester Contract for specific farm
   */
  function harvestRewards(uint256 _farmProtocolNum) public onlyOwner {
    address tokenReturned =
      IVaultHarvester(_fujiAdmin.getVaultHarvester()).collectRewards(_farmProtocolNum);
    uint256 tokenBal = IERC20(tokenReturned).balanceOf(address(this));
    require(tokenReturned != address(0) && tokenBal > 0, Errors.VL_HARVESTING_FAILED);
    IERC20(tokenReturned).uniTransfer(payable(_fujiAdmin.getTreasury()), tokenBal);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import { IVault} from "./Vaults/IVault.sol";
import { IFujiAdmin } from "./IFujiAdmin.sol";
import { IFujiERC1155} from "./FujiERC1155/IFujiERC1155.sol";
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Flasher } from "./Flashloans/Flasher.sol";
import { FlashLoan } from "./Flashloans/LibFlashLoan.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Errors} from "./Libraries/Errors.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "./Libraries/LibUniERC20.sol";
import { IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ReentrancyGuard } from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import "hardhat/console.sol";

interface IVaultExt is IVault {

  //Asset Struct
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  function vAssets() external view returns(VaultAssets memory);

}

contract Fliquidator is Ownable, ReentrancyGuard {

  using SafeMath for uint256;
  using UniERC20 for IERC20;

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Flash Close Fee Factor
  Factor public flashCloseF;

  IFujiAdmin private _fujiAdmin;
  IUniswapV2Router02 public swapper;

  // Log Liquidation
  event LogLiquidate(address indexed userAddr, address liquidator, address indexed asset, uint256 amount);
  // Log FlashClose
  event LogFlashClose(address indexed userAddr, address indexed asset, uint256 amount);
  // Log Liquidation
  event LogFlashLiquidate(address userAddr, address liquidator, address indexed asset, uint256 amount);

  modifier isAuthorized() {
    require(
      msg.sender == owner() ||
      msg.sender == address(this),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  modifier onlyFlash() {
    require(
      msg.sender == _fujiAdmin.getFlasher(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  constructor() public {

    // 1.013
    flashCloseF.a = 1013;
    flashCloseF.b = 1000;

  }

  receive() external payable {}

  // FLiquidator Core Functions

  /**
  * @dev Liquidate an undercollaterized debt and get bonus (bonusL in Vault)
  * @param _userAddr: Address of user whose position is liquidatable
  * @param _vault: Address of the vault in where liquidation will occur
  */
  function liquidate(address _userAddr, address _vault) external {

    // Update Balances at FujiERC1155
    IVault(_vault).updateF1155Balances();

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // Compute Amount of Minimum Collateral Required including factors
    uint256 neededCollateral = IVault(_vault).getNeededCollateralFor(userDebtBalance, true);

    // Check if User is liquidatable
    require(
      userCollateral < neededCollateral,
      Errors.VL_USER_NOT_LIQUIDATABLE
    );

    // Check Liquidator Allowance
    require(
      IERC20(vAssets.borrowAsset).allowance(msg.sender, address(this)) >= userDebtBalance,
      Errors.VL_MISSING_ERC20_ALLOWANCE
    );

    // Transfer borrowAsset funds from the Liquidator to Here
    IERC20(vAssets.borrowAsset).transferFrom(msg.sender, address(this), userDebtBalance);

    // Transfer Amount to Vault
    IERC20(vAssets.borrowAsset).transfer(_vault, userDebtBalance);

    // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

    // Repay BaseProtocol debt
    IVault(_vault).payback(int256(userDebtBalance));

    //TODO: Transfer corresponding Debt Amount to Fuji Treasury

    // Burn Debt F1155 tokens
    F1155.burn(_userAddr, vAssets.borrowID, userDebtBalance);

    // Compute the Liquidator Bonus bonusL
    uint256 bonus = IVault(_vault).getLiquidationBonusFor(userDebtBalance, false);
    // Compute how much collateral needs to be swapt
    uint256 collateralInPlay = getCollateralInPlay(vAssets.borrowAsset, userDebtBalance.add(bonus));

    // Withdraw collateral
    IVault(_vault).withdraw(int256(collateralInPlay));

    // Swap Collateral
    swap(vAssets.borrowAsset, userDebtBalance.add(bonus), collateralInPlay);

    // Burn Collateral F1155 tokens
    F1155.burn(_userAddr, vAssets.collateralID, collateralInPlay);

    // Transfer to Liquidator the debtBalance + bonus
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, userDebtBalance.add(bonus));

    // Transfer left-over collateral to user
    //IERC20(vAssets.collateralAsset).uniTransfer(payable(_userAddr), remainingCollat);

    emit LogLiquidate(_userAddr, msg.sender, vAssets.borrowAsset, userDebtBalance);
  }

  /**
  * @dev Initiates a flashloan used to repay partially or fully the debt position of msg.sender
  * @param _amount: Pass -1 to fully close debt position, otherwise Amount to be repaid with a flashloan
  * @param _vault: The vault address where the debt position exist.
  * @param _flashnum: integer identifier of flashloan provider
  */
  function flashClose(int256 _amount, address _vault, uint8 _flashnum) external nonReentrant {

    Flasher flasher = Flasher(payable(_fujiAdmin.getFlasher()));

    // Update Balances at FujiERC1155
    IVault(_vault).updateF1155Balances();

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user  Balances
    uint256 userCollateral = F1155.balanceOf(msg.sender, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(msg.sender, vAssets.borrowID);

    // Check Debt is > zero
    require(userDebtBalance > 0, Errors.VL_NO_DEBT_TO_PAYBACK);

    uint256 amount = _amount < 0 ? userDebtBalance : uint256(_amount);

    uint256 neededCollateral = IVault(_vault).getNeededCollateralFor(amount, false);
    require(userCollateral >= neededCollateral, Errors.VL_UNDERCOLLATERIZED_ERROR);

    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Close,
      asset: vAssets.borrowAsset,
      amount: amount,
      vault: _vault,
      newProvider: address(0),
      user: msg.sender,
      userliquidator: address(0),
      fliquidator: address(this)
    });

    flasher.initiateFlashloan(info, _flashnum);
  }

  /**
  * @dev Close user's debt position by using a flashloan
  * @param _userAddr: user addr to be liquidated
  * @param _vault: Vault address
  * @param _amount: amount received by Flashloan
  * @param _flashloanFee: amount extra charged by flashloan provider
  * Emits a {LogFlashClose} event.
  */
  function executeFlashClose(
    address payable _userAddr,
    address _vault,
    uint256 _amount,
    uint256 _flashloanFee
  ) external onlyFlash {
    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // Get user Collateral + Flash Close Fee to close posisition, for _amount passed
    uint256 userCollateralinPlay = IVault(_vault)
      .getNeededCollateralFor(_amount.add(_flashloanFee), false)
      .mul(flashCloseF.a).div(flashCloseF.b);

    // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

    // Repay BaseProtocol debt
    IVault(_vault).payback(int256(_amount));

    //TODO: Transfer corresponding Debt Amount to Fuji Treasury

    // Full close
    if (_amount == userDebtBalance) {
      F1155.burn(_userAddr, vAssets.collateralID, userCollateral);

      // Withdraw Full collateral
      IVault(_vault).withdraw(int256(userCollateral));

      // Send unUsed Collateral to User
      _userAddr.transfer(userCollateral.sub(userCollateralinPlay));
    }
    else {
      F1155.burn(_userAddr, vAssets.collateralID, userCollateralinPlay);

      // Withdraw Collateral in play Only
      IVault(_vault).withdraw(int256(userCollateralinPlay));
    }

    // Swap Collateral for underlying to repay Flashloan
    uint256 remaining = swap(vAssets.borrowAsset, _amount.add(_flashloanFee), userCollateralinPlay);

    // Send FlashClose Fee to FujiTreasury
    IERC20(vAssets.collateralAsset).uniTransfer(_fujiAdmin.getTreasury(), remaining);

    // Send flasher the underlying to repay Flashloan
    IERC20(vAssets.borrowAsset).uniTransfer(payable(_fujiAdmin.getFlasher()), _amount.add(_flashloanFee));

    // Burn Debt F1155 tokens
    F1155.burn(_userAddr, vAssets.borrowID, _amount);

    emit LogFlashClose(_userAddr, vAssets.borrowAsset, userDebtBalance);
  }

  /**
  * @dev Initiates a flashloan to liquidate an undercollaterized debt position,
  * gets bonus (bonusFlashL in Vault)
  * @param _userAddr: Address of user whose position is liquidatable
  * @param _vault: The vault address where the debt position exist.
  * @param _flashnum: integer identifier of flashloan provider
  */
  function flashLiquidate(address _userAddr, address _vault, uint8 _flashnum) external nonReentrant {

    // Update Balances at FujiERC1155
    IVault(_vault).updateF1155Balances();

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // Compute Amount of Minimum Collateral Required including factors
    uint256 neededCollateral = IVault(_vault).getNeededCollateralFor(userDebtBalance, true);

    // Check if User is liquidatable
    require(
      userCollateral < neededCollateral,
      Errors.VL_USER_NOT_LIQUIDATABLE
    );

    Flasher flasher = Flasher(payable(_fujiAdmin.getFlasher()));

    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Liquidate,
      asset: vAssets.borrowAsset,
      amount: userDebtBalance,
      vault: _vault,
      newProvider: address(0),
      user: _userAddr,
      userliquidator: msg.sender,
      fliquidator: address(this)
    });

    flasher.initiateFlashloan(info, _flashnum);
  }

  /**
  * @dev Liquidate a debt position by using a flashloan
  * @param _userAddr: user addr to be liquidated
  * @param _liquidatorAddr: liquidator address
  * @param _vault: Vault address
  * @param _amount: amount of debt to be repaid
  * @param _flashloanFee: amount extra charged by flashloan provider
  * Emits a {LogFlashLiquidate} event.
  */
  function executeFlashLiquidation(
    address _userAddr,
    address _liquidatorAddr,
    address _vault,
    uint256 _amount,
    uint256 _flashloanFee
  ) external onlyFlash {

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

    //TODO: Transfer corresponding Debt Amount to Fuji Treasury

    // Repay BaseProtocol debt to release collateral
    IVault(_vault).payback(int256(_amount));

    // Withdraw collateral
    IVault(_vault).withdraw(int256(userCollateral));

    // Compute the Liquidator Bonus bonusFlashL
    uint256 bonus = IVault(_vault).getLiquidationBonusFor(userDebtBalance, true);
    // Compute how much collateral needs to be swapt
    uint256 collateralInPlay = getCollateralInPlay(vAssets.borrowAsset, userDebtBalance.add(_flashloanFee).add(bonus));

    uint256 remainingCollat = swap(
      vAssets.borrowAsset,
      _amount.add(_flashloanFee).add(bonus),
      collateralInPlay
    );
    console.log(remainingCollat);

    // Send flasher the underlying to repay Flashloan
    IERC20(vAssets.borrowAsset).uniTransfer(payable(_fujiAdmin.getFlasher()), _amount.add(_flashloanFee));

    // Transfer Bonus bonusFlashL to liquidator
    IERC20(vAssets.borrowAsset).uniTransfer(payable(_liquidatorAddr), bonus);

    // Transfer left-over collateral to user
    //IERC20(vAssets.collateralAsset).uniTransfer(payable(_userAddr), remainingCollat);

    // Burn Debt F1155 tokens
    F1155.burn(_userAddr, vAssets.borrowID, userDebtBalance);

    // Burn Collateral F1155 tokens
    F1155.burn(_userAddr, vAssets.collateralID, collateralInPlay);

    emit LogFlashLiquidate(_userAddr, _liquidatorAddr, vAssets.borrowAsset, userDebtBalance);
  }

  /**
  * @dev Swap an amount of underlying
  * @param _borrowAsset: Address of vault borrowAsset
  * @param _amountToReceive: amount of underlying to receive
  * @param _collateralAmount: collateral Amount sent for swap
  */
  function swap(address _borrowAsset, uint256 _amountToReceive, uint256 _collateralAmount) internal returns(uint256) {

    // Swap Collateral Asset to Borrow Asset
    address[] memory path = new address[](2);
    path[0] = swapper.WETH();
    path[1] = _borrowAsset;
    uint[] memory swapperAmounts = swapper.swapETHForExactTokens{ value: _collateralAmount }(
      _amountToReceive,
      path,
      address(this),
      block.timestamp
    );

    return _collateralAmount.sub(swapperAmounts[0]);
  }

  /**
  * @dev Get exact amount of collateral to be swapt
  * @param _borrowAsset: Address of vault borrowAsset
  * @param _amountToReceive: amount of underlying to receive
  */
  function getCollateralInPlay(address _borrowAsset, uint256 _amountToReceive) internal view returns(uint256) {

    address[] memory path = new address[](2);
    path[0] = swapper.WETH();
    path[1] = _borrowAsset;
    uint[] memory amounts = swapper.getAmountsIn(_amountToReceive, path);

    return amounts[0];
  }

  // Administrative functions

  /**
  * @dev Set Factors "a" and "b" for a Struct Factor flashcloseF
  * For flashCloseF;  should be > 1, a/b
  * @param _newFactorA: A number
  * @param _newFactorB: A number
  */
  function setFlashCloseFee(uint64 _newFactorA, uint64 _newFactorB) external isAuthorized {
    flashCloseF.a = _newFactorA;
    flashCloseF.b = _newFactorB;
  }

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public isAuthorized{
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }

  /**
  * @dev Changes the Swapper contract address
  * @param _newSwapper: address of new swapper contract
  */
  function setSwapper(address _newSwapper) external isAuthorized {
    swapper = IUniswapV2Router02(_newSwapper);
  }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFujiAdmin } from "../IFujiAdmin.sol";
import { Errors } from '../Libraries/Errors.sol';

import { ILendingPool, IFlashLoanReceiver } from "./AaveFlashLoans.sol";
import {
  Actions,
  Account,
  DyDxFlashloanBase,
  ICallee,
  ISoloMargin
} from "./DyDxFlashLoans.sol";
import { FlashLoan } from "./LibFlashLoan.sol";
import { IVault } from "../Vaults/IVault.sol";

interface IFliquidator {

  function executeFlashClose(address _userAddr, address vault, uint256 _Amount, uint256 flashloanfee) external;

  function executeFlashLiquidation(address _userAddr,address _liquidatorAddr, address vault, uint256 _debtAmount, uint256 flashloanfee) external;
}

contract Flasher is
  DyDxFlashloanBase,
  IFlashLoanReceiver,
  ICallee,
  Ownable
{

  using SafeMath for uint256;
  using UniERC20 for IERC20;

  IFujiAdmin private _fujiAdmin;

  address public aave_lending_pool;
  address public dydx_solo_margin;

  receive() external payable {}

  constructor() public {

    aave_lending_pool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    dydx_solo_margin = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

  }

  modifier isAuthorized() {
    require(
      msg.sender == _fujiAdmin.getController() ||
      msg.sender == _fujiAdmin.getFliquidator() ||
      msg.sender == owner(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  modifier isAuthorizedExternal() {
    require(
      msg.sender == dydx_solo_margin ||
      msg.sender == aave_lending_pool,
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public onlyOwner {
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }


  /**
  * @dev Routing Function for Flashloan Provider
  * @param info: struct information for flashLoan
  * @param _flashnum: integer identifier of flashloan provider
  */
  function initiateFlashloan(FlashLoan.Info memory info, uint8 _flashnum) public isAuthorized {
    if(_flashnum==0) {
      initiateAaveFlashLoan(info);
    } else if(_flashnum==1) {
      initiateDyDxFlashLoan(info);
    }
  }

  // ===================== DyDx FlashLoan ===================================

  /**
  * @dev Initiates a DyDx flashloan.
  * @param info: data to be passed between functions executing flashloan logic
  */
  function initiateDyDxFlashLoan(
    FlashLoan.Info memory info
  ) internal {

    ISoloMargin solo = ISoloMargin(dydx_solo_margin);

    // Get marketId from token address
    uint256 marketId = _getMarketIdFromTokenAddress(solo, info.asset);

    // 1. Withdraw $
    // 2. Call callFunction(...)
    // 3. Deposit back $
    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, info.amount);
    // Encode FlashLoan.Info for callFunction
    operations[1] = _getCallAction(abi.encode(info));
    // add fee of 2 wei
    operations[2] = _getDepositAction(marketId, info.amount.add(2));

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo(address(this));

    solo.operate(accountInfos, operations);
  }

  /**
  * @dev Executes DyDx Flashloan, this operation is required
  * and called by Solo when sending loaned amount
  * @param sender: Not used
  * @param account: Not used
  */
  function callFunction(
    address sender,
    Account.Info memory account,
    bytes memory data
  ) external override isAuthorizedExternal {
    sender;
    account;

    FlashLoan.Info memory info = abi.decode(data, (FlashLoan.Info));

    //Estimate flashloan payback + premium fee of 2 wei,
    uint amountOwing = info.amount.add(2);

    // Transfer to Vault the flashloan Amount
    IERC20(info.asset).uniTransfer(payable(info.vault), info.amount);

    if (info.callType == FlashLoan.CallType.Switch) {
      IVault(info.vault)
      .executeSwitch(info.newProvider, info.amount, 2);
    }
    else if (info.callType == FlashLoan.CallType.Close) {
      IFliquidator(info.fliquidator)
      .executeFlashClose(info.user, info.vault, info.amount, 2);
    }
    else {
      IFliquidator(info.fliquidator)
      .executeFlashLiquidation(info.user, info.userliquidator, info.vault, info.amount, 2);
    }

    //Approve DYDXSolo to spend to repay flashloan
    IERC20(info.asset).approve(dydx_solo_margin, amountOwing);
  }


  // ===================== Aave FlashLoan ===================================

  /**
  * @dev Initiates an Aave flashloan.
  * @param info: data to be passed between functions executing flashloan logic
  */
  function initiateAaveFlashLoan(
    FlashLoan.Info memory info
  ) internal {

    //Initialize Instance of Aave Lending Pool
    ILendingPool aaveLp = ILendingPool(aave_lending_pool);

    //Passing arguments to construct Aave flashloan -limited to 1 asset type for now.
    address receiverAddress = address(this);
    address[] memory assets = new address[](1);
    assets[0] = address(info.asset);
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = info.amount;

    // 0 = no debt, 1 = stable, 2 = variable
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    address onBehalfOf = address(this);
    bytes memory params = abi.encode(info);
    uint16 referralCode = 0;

    //Aave Flashloan initiated.
    aaveLp.flashLoan(
      receiverAddress,
      assets,
      amounts,
      modes,
      onBehalfOf,
      params,
      referralCode
    );
  }

  /**
  * @dev Executes Aave Flashloan, this operation is required
  * and called by Aaveflashloan when sending loaned amount
  */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override isAuthorizedExternal returns (bool) {
    initiator;

    FlashLoan.Info memory info = abi.decode(params, (FlashLoan.Info));

    //Estimate flashloan payback + premium fee,
    uint amountOwing = amounts[0].add(premiums[0]);

    // Transfer to the vault ERC20
    IERC20(assets[0]).uniTransfer(payable(info.vault), amounts[0]);

    if (info.callType == FlashLoan.CallType.Switch) {
      IVault(info.vault)
      .executeSwitch(info.newProvider, amounts[0], premiums[0]);
    }
    else if (info.callType == FlashLoan.CallType.Close) {
      IFliquidator(info.fliquidator)
      .executeFlashClose(info.user, info.vault, amounts[0], premiums[0]);
    }
    else {
      IFliquidator(info.fliquidator)
      .executeFlashLiquidation(info.user, info.userliquidator, info.vault, amounts[0],premiums[0]);
    }

    //Approve aaveLP to spend to repay flashloan
    IERC20(assets[0]).uniApprove(payable(aave_lending_pool), amountOwing);

    return true;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.5;

library FlashLoan {
  /**
  * @dev Used to determine which vault's function to call post-flashloan:
  * - Switch for executeSwitch(...)
  * - Close for executeFlashClose(...)
  * - Liquidate for executeFlashLiquidation(...)
  */
  enum CallType { Switch, Close, Liquidate }

  /**
  * @dev Struct of params to be passed between functions executing flashloan logic
  * @param asset: Address of asset to be borrowed with flashloan
  * @param amount: Amount of asset to be borrowed with flashloan
  * @param vault: Vault's address on which the flashloan logic to be executed
  * @param newProvider: New provider's address. Used when callType is Switch
  * @param user: User's address. Used when callType is Close or Liquidate
  * @param userliquidator: The user's address who is  performing liquidation. Used when callType is Liquidate
  * @param fliquidator: Fujis Liquidator's address.
  */
  struct Info {
    CallType callType;
    address asset;
    uint256 amount;
    address vault;
    address newProvider;
    address user;
    address userliquidator;
    address fliquidator;
  }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.5;

interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}

interface ILendingPool {
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.5;
pragma experimental ABIEncoderV2;

library Account {
  enum Status {Normal, Liquid, Vapor}
  struct Info {
    address owner; // The address that owns the account
    uint256 number; // A nonce that allows a single address to control many accounts
  }
}

library Actions {
  enum ActionType {
    Deposit, // supply tokens
    Withdraw, // borrow tokens
    Transfer, // transfer balance between accounts
    Buy, // buy an amount of some token (publicly)
    Sell, // sell an amount of some token (publicly)
    Trade, // trade tokens against another account
    Liquidate, // liquidate an undercollateralized or expiring account
    Vaporize, // use excess tokens to zero-out a completely negative account
    Call // send arbitrary data to an address
  }

  struct ActionArgs {
    ActionType actionType;
    uint256 accountId;
    Types.AssetAmount amount;
    uint256 primaryMarketId;
    uint256 secondaryMarketId;
    address otherAddress;
    uint256 otherAccountId;
    bytes data;
  }
}

library Types {
  enum AssetDenomination {
    Wei, // the amount is denominated in wei
    Par // the amount is denominated in par
  }

  enum AssetReference {
    Delta, // the amount is given as a delta from the current value
    Target // the amount is given as an exact number to end up at
  }

  struct AssetAmount {
    bool sign; // true if positive
    AssetDenomination denomination;
    AssetReference ref;
    uint256 value;
  }
}

/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
interface ICallee {
  /**
   * Allows users to send this contract arbitrary data.
   *
   * @param  sender       The msg.sender to Solo
   * @param  accountInfo  The account from which the data is being sent
   * @param  data         Arbitrary data given by the sender
   */
  function callFunction(
    address sender,
    Account.Info memory accountInfo,
    bytes memory data
  ) external;
}

interface ISoloMargin {
  function getNumMarkets() external view returns (uint256);
  function getMarketTokenAddress(uint256 marketId) external view returns (address);
  function operate(
    Account.Info[] memory accounts,
    Actions.ActionArgs[] memory actions
  ) external;
}

contract DyDxFlashloanBase {
  // -- Internal Helper functions -- //

  function _getMarketIdFromTokenAddress(
    ISoloMargin solo,
    address token
  ) internal view returns (uint256) {
    uint256 numMarkets = solo.getNumMarkets();

    address curToken;
    for (uint256 i = 0; i < numMarkets; i++) {
      curToken = solo.getMarketTokenAddress(i);

      if (curToken == token) {
        return i;
      }
    }

    revert("No marketId found for provided token");
  }

  function _getAccountInfo(
    address receiver
  ) internal pure returns (Account.Info memory) {
    return Account.Info({ owner: receiver, number: 1 });
  }

  function _getWithdrawAction(
    uint marketId,
    uint256 amount
  ) internal view returns (Actions.ActionArgs memory) {
    return Actions.ActionArgs({
      actionType: Actions.ActionType.Withdraw,
      accountId: 0,
      amount: Types.AssetAmount({
        sign: false,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: amount
      }),
      primaryMarketId: marketId,
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: ""
    });
  }

  function _getCallAction(
    bytes memory data
  ) internal view returns (Actions.ActionArgs memory) {
    return Actions.ActionArgs({
      actionType: Actions.ActionType.Call,
      accountId: 0,
      amount: Types.AssetAmount({
        sign: false,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: 0
      }),
      primaryMarketId: 0,
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: data
    });
  }

  function _getDepositAction(
    uint marketId,
    uint256 amount
  ) internal view returns (Actions.ActionArgs memory) {
    return Actions.ActionArgs({
      actionType: Actions.ActionType.Deposit,
      accountId: 0,
      amount: Types.AssetAmount({
        sign: true,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: amount
      }),
      primaryMarketId: marketId,
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: ""
    });
  }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.8.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface LQTYInterface {

}

contract LQTYHelpers {

  function initializeTrouve() internal {
    //TODO function
  }

}

contract ProviderLQTY is IProvider, LQTYHelpers {

  using SafeMath for uint256;
  using UniERC20 for IERC20;

  function deposit(address collateralAsset, uint256 collateralAmount) external override payable{
    //TODO
  }

  function borrow(address borrowAsset, uint256 borrowAmount) external override payable {
    //TODO
  }

  function withdraw(address collateralAsset, uint256 collateralAmount) external override payable {
    //TODO
  }

  function payback(address borrowAsset, uint256 borrowAmount) external override payable {
    //TODO
  }

  function getBorrowRateFor(address asset) external view override returns(uint256){
    //TODO
    return 0;

  }
  function getBorrowBalance(address _asset) external view override returns(uint256) {
    //TODO
    return 0;
  }

  function getDepositBalance(address _asset) external view override returns(uint256){
    //TODO
    return 0;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface IWethERC20 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

interface SoloMarginContract {
  struct Info {
    address owner;
    uint256 number;
  }

  struct Price {
    uint256 value;
  }

  struct Value {
    uint256 value;
  }

  struct Rate {
    uint256 value;
  }

  enum ActionType { Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call }

  enum AssetDenomination { Wei, Par }

  enum AssetReference { Delta, Target }

  struct AssetAmount {
    bool sign;
    AssetDenomination denomination;
    AssetReference ref;
    uint256 value;
  }

  struct ActionArgs {
    ActionType actionType;
    uint256 accountId;
    AssetAmount amount;
    uint256 primaryMarketId;
    uint256 secondaryMarketId;
    address otherAddress;
    uint256 otherAccountId;
    bytes data;
  }

  struct Wei {
    bool sign;
    uint256 value;
  }

  function operate(Info[] calldata _accounts, ActionArgs[] calldata _actions) external;

  function getAccountWei(Info calldata _account, uint256 _marketId)
    external
    view
    returns (Wei memory);

  function getNumMarkets() external view returns (uint256);

  function getMarketTokenAddress(uint256 _marketId) external view returns (address);

  function getAccountValues(Info memory _account)
    external
    view
    returns (Value memory, Value memory);

  function getMarketInterestRate(uint256 _marketId) external view returns (Rate memory);
}

contract HelperFunct {
  /**
   * @dev get Dydx Solo Address
   */
  function getDydxAddress() public pure returns (address addr) {
    addr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
  }

  /**
   * @dev get WETH address
   */
  function getWETHAddr() public pure returns (address weth) {
    weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  }

  /**
   * @dev Return ethereum address
   */
  function _getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
  }

  /**
   * @dev Get Dydx Market ID from token Address
   */
  function _getMarketId(SoloMarginContract _solo, address _token)
    internal
    view
    returns (uint256 _marketId)
  {
    uint256 markets = _solo.getNumMarkets();
    address token = _token == _getEthAddr() ? getWETHAddr() : _token;
    bool check = false;
    for (uint256 i = 0; i < markets; i++) {
      if (token == _solo.getMarketTokenAddress(i)) {
        _marketId = i;
        check = true;
        break;
      }
    }
    require(check, "DYDX Market doesnt exist!");
  }

  /**
   * @dev Get Dydx Acccount arg
   */
  function _getAccountArgs() internal view returns (SoloMarginContract.Info[] memory) {
    SoloMarginContract.Info[] memory accounts = new SoloMarginContract.Info[](1);
    accounts[0] = (SoloMarginContract.Info(address(this), 0));
    return accounts;
  }

  /**
   * @dev Get Dydx Actions args.
   */
  function _getActionsArgs(
    uint256 _marketId,
    uint256 _amt,
    bool _sign
  ) internal view returns (SoloMarginContract.ActionArgs[] memory) {
    SoloMarginContract.ActionArgs[] memory actions = new SoloMarginContract.ActionArgs[](1);
    SoloMarginContract.AssetAmount memory amount =
      SoloMarginContract.AssetAmount(
        _sign,
        SoloMarginContract.AssetDenomination.Wei,
        SoloMarginContract.AssetReference.Delta,
        _amt
      );
    bytes memory empty;
    SoloMarginContract.ActionType action =
      _sign ? SoloMarginContract.ActionType.Deposit : SoloMarginContract.ActionType.Withdraw;
    actions[0] = SoloMarginContract.ActionArgs(
      action,
      0,
      amount,
      _marketId,
      0,
      address(this),
      0,
      empty
    );
    return actions;
  }
}

contract ProviderDYDX is IProvider, HelperFunct {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  bool public donothing = true;

  //Provider Core Functions

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset: token address to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());
      tweth.deposit{ value: _amount }();
      tweth.approve(getDydxAddress(), _amount);
    } else {
      IWethERC20 tweth = IWethERC20(_asset);
      tweth.approve(getDydxAddress(), _amount);
    }

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, true));
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset: token address to withdraw. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, false));

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());

      tweth.approve(address(tweth), _amount);

      tweth.withdraw(_amount);
    }
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, false));

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());

      tweth.approve(address(_asset), _amount);

      tweth.withdraw(_amount);
    }
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to payback.
   */
  function payback(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());
      tweth.deposit{ value: _amount }();
      tweth.approve(getDydxAddress(), _amount);
    } else {
      IWethERC20 tweth = IWethERC20(_asset);
      tweth.approve(getDydxAddress(), _amount);
    }

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, true));
  }

  /**
   * @dev Returns the current borrowing rate (APR) of a ETH/ERC20_Token, in ray(1e27).
   * @param _asset: token address to query the current borrowing rate.
   */
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Rate memory _rate = dydxContract.getMarketInterestRate(marketId);
    return (_rate.value).mul(1e9).mul(365 days);
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Info memory account =
      SoloMarginContract.Info({ owner: msg.sender, number: 0 });
    SoloMarginContract.Wei memory structbalance = dydxContract.getAccountWei(account, marketId);
    return structbalance.value;
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getDepositBalance(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Info memory account =
      SoloMarginContract.Info({ owner: msg.sender, number: 0 });
    SoloMarginContract.Wei memory structbalance = dydxContract.getAccountWei(account, marketId);
    return structbalance.value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.5;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface IGenCToken is IERC20 {
  function redeem(uint256) external returns (uint256);

  function redeemUnderlying(uint256) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function totalBorrowsCurrent() external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function borrowBalanceStored(address account) external view returns (uint256);

  function getCash() external view returns (uint256);
}

interface ICErc20 is IGenCToken {
  function mint(uint256) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
}

interface ICEth is IGenCToken {
  function mint() external payable;

  function repayBorrow() external payable;

  function repayBorrowBehalf(address borrower) external payable;
}

interface IComptroller {
  function markets(address) external returns (bool, uint256);

  function enterMarkets(address[] calldata) external returns (uint256[] memory);

  function exitMarket(address cTokenAddress) external returns (uint256);

  function getAccountLiquidity(address)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

interface IFujiMappings {
  function addressMapping(address) external view returns (address);
}

contract HelperFunct {
  function _isETH(address token) internal pure returns (bool) {
    return (token == address(0) || token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
  }

  function _getMappingAddr() internal pure returns (address) {
    return 0x6b09443595BFb8F91eA837c7CB4Fe1255782093b;
  }

  function _getComptrollerAddress() internal pure returns (address) {
    return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
  }

  //Compound functions

  /**
   * @dev Approves vault's assets as collateral for Compound Protocol.
   * @param _cTokenAddress: asset type to be approved as collateral.
   */
  function _enterCollatMarket(address _cTokenAddress) internal {
    // Create a reference to the corresponding network Comptroller
    IComptroller comptroller = IComptroller(_getComptrollerAddress());

    address[] memory cTokenMarkets = new address[](1);
    cTokenMarkets[0] = _cTokenAddress;
    comptroller.enterMarkets(cTokenMarkets);
  }

  /**
   * @dev Removes vault's assets as collateral for Compound Protocol.
   * @param _cTokenAddress: asset type to be removed as collateral.
   */
  function _exitCollatMarket(address _cTokenAddress) internal {
    // Create a reference to the corresponding network Comptroller
    IComptroller comptroller = IComptroller(_getComptrollerAddress());

    comptroller.exitMarket(_cTokenAddress);
  }
}

contract ProviderCompound is IProvider, HelperFunct {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  //Provider Core Functions

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset: token address to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount) external payable override {
    //Get cToken address from mapping
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);

    //Enter and/or ensure collateral market is enacted
    _enterCollatMarket(cTokenAddr);

    if (_isETH(_asset)) {
      // Create a reference to the cToken contract
      ICEth cToken = ICEth(cTokenAddr);

      //Compound protocol Mints cTokens, ETH method
      cToken.mint{ value: _amount }();
    } else {
      // Create reference to the ERC20 contract
      IERC20 erc20token = IERC20(_asset);

      // Create a reference to the cToken contract
      ICErc20 cToken = ICErc20(cTokenAddr);

      //Checks, Vault balance of ERC20 to make deposit
      require(erc20token.balanceOf(address(this)) >= _amount, "Not enough Balance");

      //Approve to move ERC20tokens
      erc20token.approve(cTokenAddr, _amount);

      // Compound Protocol mints cTokens, trhow error if not
      require(cToken.mint(_amount) == 0, "Deposit-failed");
    }
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset: token address to withdraw. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount) external payable override {
    //Get cToken address from mapping
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);

    // Create a reference to the corresponding cToken contract
    IGenCToken cToken = IGenCToken(cTokenAddr);

    //Compound Protocol Redeem Process, throw errow if not.
    require(cToken.redeemUnderlying(_amount) == 0, "Withdraw-failed");
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount) external payable override {
    //Get cToken address from mapping
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);

    // Create a reference to the corresponding cToken contract
    IGenCToken cToken = IGenCToken(cTokenAddr);

    //Enter and/or ensure collateral market is enacted
    //_enterCollatMarket(cTokenAddr);

    //Compound Protocol Borrow Process, throw errow if not.
    require(cToken.borrow(_amount) == 0, "borrow-failed");
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to payback.
   */
  function payback(address _asset, uint256 _amount) external payable override {
    //Get cToken address from mapping
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);

    if (_isETH(_asset)) {
      // Create a reference to the corresponding cToken contract
      ICEth cToken = ICEth(cTokenAddr);

      cToken.repayBorrow{ value: msg.value }();
    } else {
      // Create reference to the ERC20 contract
      IERC20 erc20token = IERC20(_asset);

      // Create a reference to the corresponding cToken contract
      ICErc20 cToken = ICErc20(cTokenAddr);

      // Check there is enough balance to pay
      require(erc20token.balanceOf(address(this)) >= _amount, "Not-enough-token");
      erc20token.approve(cTokenAddr, _amount);
      cToken.repayBorrow(_amount);
    }
  }

  /**
   * @dev Returns the current borrowing rate (APR) of a ETH/ERC20_Token, in ray(1e27).
   * @param _asset: token address to query the current borrowing rate.
   */
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);

    //Block Rate transformed for common mantissa for Fuji in ray (1e27), Note: Compound uses base 1e18
    uint256 bRateperBlock = (IGenCToken(cTokenAddr).borrowRatePerBlock()).mul(10**9);

    // The approximate number of blocks per year that is assumed by the Compound interest rate model
    uint256 blocksperYear = 2102400;
    return bRateperBlock.mul(blocksperYear);
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    return IGenCToken(cTokenAddr).borrowBalanceStored(msg.sender);
  }

  /**
   * @dev Returns the deposit balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getDepositBalance(address _asset) external view override returns (uint256) {
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    uint256 cTokenBal = IGenCToken(cTokenAddr).balanceOf(msg.sender);
    uint256 exRate = IGenCToken(cTokenAddr).exchangeRateStored();
    return exRate.mul(cTokenBal).div(1e18);
  }

  // This function is the accurate way to get Compound Borrow Balance but it costs 84K gas
  // and is not a view function.
  function getBorrowBalanceExact(address _asset, address who) external returns (uint256) {
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    return IGenCToken(cTokenAddr).borrowBalanceCurrent(who);
  }

  // This function is the accurate way to get Compound Deposit Balance but it costs 84K gas
  // and is not a view function.
  function getDepositBalanceExact(address _asset, address who) external returns (uint256) {
    address cTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    return IGenCToken(cTokenAddr).balanceOfUnderlying(who);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface ITokenInterface {
  function approve(address, uint256) external;

  function transfer(address, uint256) external;

  function transferFrom(
    address,
    address,
    uint256
  ) external;

  function deposit() external payable;

  function withdraw(uint256) external;

  function balanceOf(address) external view returns (uint256);

  function decimals() external view returns (uint256);
}

interface IAaveInterface {
  function deposit(
    address _asset,
    uint256 _amount,
    address _onBehalfOf,
    uint16 _referralCode
  ) external;

  function withdraw(
    address _asset,
    uint256 _amount,
    address _to
  ) external;

  function borrow(
    address _asset,
    uint256 _amount,
    uint256 _interestRateMode,
    uint16 _referralCode,
    address _onBehalfOf
  ) external;

  function repay(
    address _asset,
    uint256 _amount,
    uint256 _rateMode,
    address _onBehalfOf
  ) external;

  function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
}

interface AaveLendingPoolProviderInterface {
  function getLendingPool() external view returns (address);
}

interface AaveDataProviderInterface {
  function getReserveTokensAddresses(address _asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  function getUserReserveData(address _asset, address _user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveData(address _asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );
}

interface AaveAddressProviderRegistryInterface {
  function getAddressesProvidersList() external view returns (address[] memory);
}

contract ProviderAave is IProvider {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  function _getAaveProvider() internal pure returns (AaveLendingPoolProviderInterface) {
    return AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); //mainnet
  }

  function _getAaveDataProvider() internal pure returns (AaveDataProviderInterface) {
    return AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); //mainnet
  }

  function _getWethAddr() internal pure returns (address) {
    return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
  }

  function _getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
  }

  function _getIsColl(
    AaveDataProviderInterface _aaveData,
    address _token,
    address _user
  ) internal view returns (bool isCol) {
    (, , , , , , , , isCol) = _aaveData.getUserReserveData(_token, _user);
  }

  function _convertEthToWeth(
    bool _isEth,
    ITokenInterface _token,
    uint256 _amount
  ) internal {
    if (_isEth) _token.deposit{ value: _amount }();
  }

  function _convertWethToEth(
    bool _isEth,
    ITokenInterface _token,
    uint256 _amount
  ) internal {
    if (_isEth) {
      _token.approve(address(_token), _amount);
      _token.withdraw(_amount);
    }
  }

  /**
   * @dev Return the borrowing rate of ETH/ERC20_Token.
   * @param _asset to query the borrowing rate.
   */
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    (, , , , uint256 variableBorrowRate, , , , , ) =
      AaveDataProviderInterface(aaveData).getReserveData(
        _asset == _getEthAddr() ? _getWethAddr() : _asset
      );

    return variableBorrowRate;
  }

  /**
   * @dev Return borrow balance of ETH/ERC20_Token.
   * @param _asset token address to query the balance.
   */
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    (, , uint256 variableDebt, , , , , , ) = aaveData.getUserReserveData(_token, msg.sender);

    return variableDebt;
  }

  /**
   * @dev Return deposit balance of ETH/ERC20_Token.
   * @param _asset token address to query the balance.
   */
  function getDepositBalance(address _asset) external view override returns (uint256) {
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    (uint256 atokenBal, , , , , , , , ) = aaveData.getUserReserveData(_token, msg.sender);

    return atokenBal;
  }

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    ITokenInterface tokenContract = ITokenInterface(_token);

    if (isEth) {
      _amount = _amount == uint256(-1) ? address(this).balance : _amount;
      _convertEthToWeth(isEth, tokenContract, _amount);
    } else {
      _amount = _amount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _amount;
    }

    tokenContract.approve(address(aave), _amount);

    aave.deposit(_token, _amount, address(this), 0);

    if (!_getIsColl(aaveData, _token, address(this))) {
      aave.setUserUseReserveAsCollateral(_token, true);
    }
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    aave.borrow(_token, _amount, 2, 0, address(this));
    _convertWethToEth(isEth, ITokenInterface(_token), _amount);
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    ITokenInterface tokenContract = ITokenInterface(_token);
    uint256 initialBal = tokenContract.balanceOf(address(this));

    aave.withdraw(_token, _amount, address(this));
    uint256 finalBal = tokenContract.balanceOf(address(this));
    _amount = finalBal.sub(initialBal);

    _convertWethToEth(isEth, tokenContract, _amount);
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.
   * @param _amount token amount to payback.
   */

  function payback(address _asset, uint256 _amount) external payable override {
    IAaveInterface aave = IAaveInterface(_getAaveProvider().getLendingPool());
    AaveDataProviderInterface aaveData = _getAaveDataProvider();

    bool isEth = _asset == _getEthAddr();
    address _token = isEth ? _getWethAddr() : _asset;

    ITokenInterface tokenContract = ITokenInterface(_token);

    (, , uint256 variableDebt, , , , , , ) = aaveData.getUserReserveData(_token, address(this));
    _amount = _amount == uint256(-1) ? variableDebt : _amount;

    if (isEth) _convertEthToWeth(isEth, tokenContract, _amount);

    tokenContract.approve(address(aave), _amount);

    aave.repay(_token, _amount, 2, address(this));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   **/

  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    //solium-disable-next-line
    uint256 timeDifference = block.timestamp.sub(uint256(lastUpdateTimestamp));

    return (rate.mul(timeDifference) / SECONDS_PER_YEAR).add(WadRayMath.ray());
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
    uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

    return WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Errors} from './Errors.sol';

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

    require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

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

    require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

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
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import { IFujiERC1155 } from "./IFujiERC1155.sol";
import { FujiBaseERC1155 } from "./FujiBaseERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { WadRayMath } from "../Libraries/WadRayMath.sol";
import { MathUtils } from "../Libraries/MathUtils.sol";
import { Errors } from "../Libraries/Errors.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract F1155Manager is Ownable {
  using Address for address;

  // Controls for Mint-Burn Operations
  mapping(address => bool) public addrPermit;

  modifier onlyPermit() {
    require(addrPermit[_msgSender()] || msg.sender == owner(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  function setPermit(address _address, bool _permit) public onlyOwner {
    require((_address).isContract(), Errors.VL_NOT_A_CONTRACT);
    addrPermit[_address] = _permit;
  }
}

contract FujiERC1155 is IFujiERC1155, FujiBaseERC1155, F1155Manager {
  using WadRayMath for uint256;

  //FujiERC1155 Asset ID Mapping

  //AssetType => asset reference address => ERC1155 Asset ID
  mapping(AssetType => mapping(address => uint256)) public assetIDs;

  //Control mapping that returns the AssetType of an AssetID
  mapping(uint256 => AssetType) public assetIDtype;

  uint64 public override qtyOfManagedAssets;

  //Asset ID  Liquidity Index mapping
  //AssetId => Liquidity index for asset ID
  mapping(uint256 => uint256) public indexes;

  // Optimizer Fee expressed in Ray, where 1 ray = 100% APR
  //uint256 public optimizerFee;
  //uint256 public lastUpdateTimestamp;
  //uint256 public fujiIndex;

  /// @dev Ignoring leap years
  //uint256 internal constant SECONDS_PER_YEAR = 365 days;

  constructor() public {
    //fujiIndex = WadRayMath.ray();
    //optimizerFee = 1e24;
  }

  /**
   * @dev Updates Index of AssetID
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   * @param newBalance: Amount
   **/
  function updateState(uint256 _assetID, uint256 newBalance) external override onlyPermit {
    uint256 total = totalSupply(_assetID);

    if (newBalance > 0 && total > 0 && newBalance > total) {
      uint256 diff = newBalance.sub(total);

      uint256 amountToIndexRatio = (diff.wadToRay()).rayDiv(total.wadToRay());

      uint256 result = amountToIndexRatio.add(WadRayMath.ray());

      result = result.rayMul(indexes[_assetID]);
      require(result <= type(uint128).max, Errors.VL_INDEX_OVERFLOW);

      indexes[_assetID] = uint128(result);

      // TODO: calculate interest rate for a fujiOptimizer Fee.
      /*
      if(lastUpdateTimestamp==0){
        lastUpdateTimestamp = block.timestamp;
      }

      uint256 accrued = _calculateCompoundedInterest(
        optimizerFee,
        lastUpdateTimestamp,
        block.timestamp
      ).rayMul(fujiIndex);

      fujiIndex = accrued;
      lastUpdateTimestamp = block.timestamp;
      */
    }
  }

  /**
   * @dev Returns the total supply of Asset_ID with accrued interest.
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function totalSupply(uint256 _assetID) public view virtual override returns (uint256) {
    // TODO: include interest accrued by Fuji OptimizerFee

    return super.totalSupply(_assetID).rayMul(indexes[_assetID]);
  }

  /**
   * @dev Returns the scaled total supply of the token ID. Represents sum(token ID Principal /index)
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function scaledTotalSupply(uint256 _assetID) public view virtual returns (uint256) {
    return super.totalSupply(_assetID);
  }

  /**
   * @dev Returns the principal + accrued interest balance of the user
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function balanceOf(address _account, uint256 _assetID)
    public
    view
    override(FujiBaseERC1155, IFujiERC1155)
    returns (uint256)
  {
    uint256 scaledBalance = super.balanceOf(_account, _assetID);

    if (scaledBalance == 0) {
      return 0;
    }

    // TODO: include interest accrued by Fuji OptimizerFee
    return scaledBalance.rayMul(indexes[_assetID]);
  }

  /**
   * @dev Returns the balance of User, split into owed amounts to BaseProtocol and FujiProtocol
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  /*
  function splitBalanceOf(
    address _account,
    uint256 _assetID
  ) public view override returns (uint256,uint256) {
    uint256 scaledBalance = super.balanceOf(_account, _assetID);
    if (scaledBalance == 0) {
      return (0,0);
    } else {
    TO DO COMPUTATION
      return (baseprotocol, fuji);
    }
  }
  */

  /**
   * @dev Returns Scaled Balance of the user (e.g. balance/index)
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function scaledBalanceOf(address _account, uint256 _assetID)
    public
    view
    virtual
    returns (uint256)
  {
    return super.balanceOf(_account, _assetID);
  }

  /**
   * @dev Returns the sum of balance of the user for an AssetType.
   * This function is used for when AssetType have units of account of the same value (e.g stablecoins)
   * @param _account: address of the User
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   **/
  /*
  function balanceOfBatchType(address _account, AssetType _type) external view override returns (uint256 total) {

    uint256[] memory IDs = engagedIDsOf(_account, _type);

    for(uint i; i < IDs.length; i++ ){
      total = total.add(balanceOf(_account, IDs[i]));
    }
  }
  */

  /**
   * @dev Mints tokens for Collateral and Debt receipts for the Fuji Protocol
   * Emits a {TransferSingle} event.
   * Requirements:
   * - `_account` cannot be the zero address.
   * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   * - `_amount` should be in WAD
   */
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) external override onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);

    address operator = _msgSender();

    uint256 accountBalance = _balances[_id][_account];
    uint256 assetTotalBalance = _totalSupply[_id];
    uint256 amountScaled = _amount.rayDiv(indexes[_id]);

    require(amountScaled != 0, Errors.VL_INVALID_MINT_AMOUNT);

    _balances[_id][_account] = accountBalance.add(amountScaled);
    _totalSupply[_id] = assetTotalBalance.add(amountScaled);

    emit TransferSingle(operator, address(0), _account, _id, _amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), _account, _id, _amount, _data);
  }

  /**
   * @dev [Batched] version of {mint}.
   * Requirements:
   * - `_ids` and `_amounts` must have the same length.
   * - If `_to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external onlyPermit {
    require(_to != address(0), Errors.VL_ZERO_ADDR_1155);
    require(_ids.length == _amounts.length, Errors.VL_INPUT_ERROR);

    address operator = _msgSender();

    uint256 accountBalance;
    uint256 assetTotalBalance;
    uint256 amountScaled;

    for (uint256 i = 0; i < _ids.length; i++) {
      accountBalance = _balances[_ids[i]][_to];
      assetTotalBalance = _totalSupply[_ids[i]];

      amountScaled = _amounts[i].rayDiv(indexes[_ids[i]]);

      require(amountScaled != 0, Errors.VL_INVALID_MINT_AMOUNT);

      _balances[_ids[i]][_to] = accountBalance.add(amountScaled);
      _totalSupply[_ids[i]] = assetTotalBalance.add(amountScaled);
    }

    emit TransferBatch(operator, address(0), _to, _ids, _amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), _to, _ids, _amounts, _data);
  }

  /**
   * @dev Destroys `_amount` receipt tokens of token type `_id` from `account` for the Fuji Protocol
   * Requirements:
   * - `account` cannot be the zero address.
   * - `account` must have at least `_amount` tokens of token type `_id`.
   * - `_amount` should be in WAD
   */
  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external override onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);

    address operator = _msgSender();

    uint256 accountBalance = _balances[_id][_account];
    uint256 assetTotalBalance = _totalSupply[_id];

    uint256 amountScaled = _amount.rayDiv(indexes[_id]);

    require(amountScaled != 0 && accountBalance >= amountScaled, Errors.VL_INVALID_BURN_AMOUNT);

    _balances[_id][_account] = accountBalance.sub(amountScaled);
    _totalSupply[_id] = assetTotalBalance.sub(amountScaled);

    emit TransferSingle(operator, _account, address(0), _id, _amount);
  }

  /**
   * @dev [Batched] version of {burn}.
   * Requirements:
   * - `_ids` and `_amounts` must have the same length.
   */
  function burnBatch(
    address _account,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);
    require(_ids.length == _amounts.length, Errors.VL_INPUT_ERROR);

    address operator = _msgSender();

    uint256 accountBalance;
    uint256 assetTotalBalance;
    uint256 amountScaled;

    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 amount = _amounts[i];

      accountBalance = _balances[_ids[i]][_account];
      assetTotalBalance = _totalSupply[_ids[i]];

      amountScaled = _amounts[i].rayDiv(indexes[_ids[i]]);

      require(amountScaled != 0 && accountBalance >= amountScaled, Errors.VL_INVALID_BURN_AMOUNT);

      _balances[_ids[i]][_account] = accountBalance.sub(amount);
      _totalSupply[_ids[i]] = assetTotalBalance.sub(amount);
    }

    emit TransferBatch(operator, _account, address(0), _ids, _amounts);
  }

  //Getter Functions

  /**
   * @dev Getter Function for the Asset ID locally managed
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   * @param _addr: Reference Address of the Asset
   */
  function getAssetID(AssetType _type, address _addr) external view override returns (uint256 id) {
    id = assetIDs[_type][_addr];
    require(id <= qtyOfManagedAssets, Errors.VL_INVALID_ASSETID_1155);
  }

  //Setter Functions

  /**
   * @dev Sets the FujiProtocol Fee to be charged
   * @param _fee; Fee in Ray(1e27) to charge users for optimizerFee (1 ray = 100% APR)
   */
  /*
  function setoptimizerFee(uint256 _fee) public onlyOwner {
    require(_fee >= WadRayMath.ray(), Errors.VL_OPTIMIZER_FEE_SMALL);
    optimizerFee = _fee;
  }
  */

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   */
  function setURI(string memory _newUri) public onlyOwner {
    _uri = _newUri;
  }

  /**
   * @dev Adds and initializes liquidity index of a new asset in FujiERC1155
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   * @param _addr: Reference Address of the Asset
   */
  function addInitializeAsset(AssetType _type, address _addr)
    external
    override
    onlyPermit
    returns (uint64)
  {
    require(assetIDs[_type][_addr] == 0, Errors.VL_ASSET_EXISTS);

    assetIDs[_type][_addr] = qtyOfManagedAssets;
    assetIDtype[qtyOfManagedAssets] = _type;

    //Initialize the liquidity Index
    indexes[qtyOfManagedAssets] = WadRayMath.ray();
    qtyOfManagedAssets++;

    return qtyOfManagedAssets - 1;
  }
  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param _rate The interest rate, in ray
   * @param _lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  /*
  function _calculateCompoundedInterest(
    uint256 _rate,
    uint256 _lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp.sub(uint256(_lastUpdateTimestamp));

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = _rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
    uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

    return WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
  }
  */
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1155MetadataURI } from "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import { ERC165 } from "@openzeppelin/contracts/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/introspection/IERC165.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Errors } from "../Libraries/Errors.sol";

/**
 *
 * @dev Implementation of the Base ERC1155 multi-token standard functions
 * for Fuji Protocol control of User collaterals and borrow debt positions.
 * Originally based on Openzeppelin
 *
 */

contract FujiBaseERC1155 is IERC1155, ERC165, Context {
  using Address for address;

  using SafeMath for uint256;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) internal _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) internal _operatorApprovals;

  // Mapping from token ID to totalSupply
  mapping(uint256 => uint256) internal _totalSupply;

  //Fuji ERC1155 Transfer Control
  bool public transfersActive;

  modifier isTransferActive() {
    require(transfersActive, Errors.VL_NOT_AUTHORIZED);
    _;
  }

  //URI for all token types by relying on ID substitution
  //https://token.fujiDao.org/{id}.json
  string internal _uri;

  /**
   * @return The total supply of a token id
   **/
  function totalSupply(uint256 id) public view virtual returns (uint256) {
    return _totalSupply[id];
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256) public view virtual returns (string memory) {
    return _uri;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   * Requirements:
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0), Errors.VL_ZERO_ADDR_1155);
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   * Requirements:
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    override
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, Errors.VL_INPUT_ERROR);

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_msgSender() != operator, Errors.VL_INPUT_ERROR);

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override isTransferActive {
    require(to != address(0), Errors.VL_ZERO_ADDR_1155);
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      Errors.VL_MISSING_ERC1155_APPROVAL
    );

    address operator = _msgSender();

    _beforeTokenTransfer(
      operator,
      from,
      to,
      _asSingletonArray(id),
      _asSingletonArray(amount),
      data
    );

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, Errors.VL_NO_ERC1155_BALANCE);

    _balances[id][from] = fromBalance.sub(amount);
    _balances[id][to] = uint256(_balances[id][to]).add(amount);

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override isTransferActive {
    require(ids.length == amounts.length, Errors.VL_INPUT_ERROR);
    require(to != address(0), Errors.VL_ZERO_ADDR_1155);
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      Errors.VL_MISSING_ERC1155_APPROVAL
    );

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, Errors.VL_NO_ERC1155_BALANCE);
      _balances[id][from] = fromBalance.sub(amount);
      _balances[id][to] = uint256(_balances[id][to]).add(amount);
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155Receiver(to).onERC1155Received.selector) {
          revert(Errors.VL_RECEIVER_REJECT_1155);
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert(Errors.VL_RECEIVER_CONTRACT_NON_1155);
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
          revert(Errors.VL_RECEIVER_REJECT_1155);
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert(Errors.VL_RECEIVER_CONTRACT_NON_1155);
      }
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVault } from "./Vaults/IVault.sol";
import { IProvider } from "./Providers/IProvider.sol";
import { Flasher } from "./Flashloans/Flasher.sol";
import { FlashLoan } from "./Flashloans/LibFlashLoan.sol";
import { IFujiAdmin } from "./IFujiAdmin.sol";
import { Errors } from "./Libraries/Errors.sol";

//import "hardhat/console.sol"; //test line

interface IVaultExt is IVault {

  //Asset Struct
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  function vAssets() external view returns(VaultAssets memory);

}

interface IProviderExt is IProvider {
  // Temp
  function getBorrowBalanceExact(address _asset, address who) external returns(uint256);
}


contract Controller is Ownable {

  using SafeMath for uint256;

  IFujiAdmin private _fujiAdmin;

  //Refinancing Variables
  bool public greenLight;
  //uint256 public lastRefinancetimestamp;

  //deltaAPRThreshold: Expressed in ray (1e27), where 1ray = 100% APR
  uint256 public deltaAPRThreshold;

  //Modifiers
  modifier isAuthorized() {
    require(
      msg.sender == owner() ||
      msg.sender == address(this),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  constructor() public {

    deltaAPRThreshold = 1e25;
    greenLight = false;

  }

  //Administrative functions

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public isAuthorized{
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }

  /**
  * @dev Changes the conditional Threshold for a provider switch
  * @param _newThreshold: percent decimal in ray (example 25% =.25 x10^27)
  */
  function setDeltaAPRThreshold(uint256 _newThreshold) external isAuthorized {
    deltaAPRThreshold = _newThreshold;
  }

  /**
  * @dev Sets the Green light to proceed with a Refinancing opportunity
  * @param _lightstate: True or False
  */
  function setLight(bool _lightstate) public isAuthorized {
    greenLight = _lightstate;
  }

  /**
  * @dev Sets a new provider to called Vault, returns true on success
  * @param _vaultAddr: fuji Vault address to which active provider will change
  * @param _newProviderAddr: fuji address of new Provider
  */
  function _setProvider(address _vaultAddr,address _newProviderAddr) internal {
    //Create vault instance and call setActiveProvider method in that vault.
    IVault(_vaultAddr).setActiveProvider(_newProviderAddr);
  }

  /**
  * @dev Sets current timestamp after a refinancing cycle
  */
  /*
  function _setRefinanceTimestamp() internal {
    lastRefinancetimestamp = block.timestamp;
  }
  */

  //Controller Core functions

  /**
  * @dev Performs refinancing routine, performs checks for verification
  * @param _vaultAddr: fuji Vault address
  * @param _ratioA: ratio to determine how much of debtposition to move
  * @param _ratioB: _ratioA/_ratioB <= 1, and > 0
  * @param _flashnum: integer identifier of flashloan provider
  * @param isCompoundActiveProvider: indicate if activeProvider is Compound
  */
  function doRefinancing(
    address _vaultAddr,
    uint256 _ratioA,
    uint256 _ratioB,
    uint8 _flashnum,
    bool isCompoundActiveProvider
  ) external {

    // Check Protocol have allowed to refinance
    require(
      greenLight,
      Errors.RF_NO_GREENLIGHT
    );

    IVault vault = IVault(_vaultAddr);
    vault.updateF1155Balances();
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vaultAddr).vAssets();

    // Check if there is an opportunity to Change provider with a lower borrowing Rate
    (bool opportunityTochange, address newProvider) = checkRates(_vaultAddr);

    require(opportunityTochange,Errors.RF_CHECK_RATES_FALSE);

    // Check Vault borrowbalance and apply ratio (consider compound or not)
    uint256 debtPosition = isCompoundActiveProvider ?
    IProviderExt(
      vault.activeProvider()).getBorrowBalanceExact(vAssets.borrowAsset,_vaultAddr) :
      vault.borrowBalance(vault.activeProvider());
    uint256 applyRatiodebtPosition = debtPosition.mul(_ratioA).div(_ratioB);

    // Check Ratio Input and Vault Balance at ActiveProvider
    require(
      debtPosition >= applyRatiodebtPosition &&
      applyRatiodebtPosition > 0,
      Errors.RF_INVALID_RATIO_VALUES
    );

    greenLight = false;

    //Initiate Flash Loan Struct
    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Switch,
      asset: vAssets.borrowAsset,
      amount: applyRatiodebtPosition,
      vault: _vaultAddr,
      newProvider: newProvider,
      user: address(0),
      userliquidator: address(0),
      fliquidator: address(0)
    });

    Flasher(payable(_fujiAdmin.getFlasher())).initiateFlashloan(info, _flashnum);

    //Set the new provider in the Vault
    _setProvider(_vaultAddr, newProvider);
  }

  /**
  * @dev Performs a forced refinancing routine
  * @param _vaultAddr: fuji Vault address
  * @param _newProvider: new provider address
  * @param _ratioA: ratio to determine how much of debtposition to move
  * @param _ratioB: _ratioA/_ratioB <= 1, and > 0
  * @param _flashnum: integer identifier of flashloan provider
  * @param isCompoundActiveProvider: indicate if activeProvider is Compound
  */
  function forcedRefinancing(
    address _vaultAddr,
    address _newProvider,
    uint256 _ratioA,
    uint256 _ratioB,
    uint8 _flashnum,
    bool isCompoundActiveProvider
  ) external isAuthorized {

    IVault vault = IVault(_vaultAddr);
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vaultAddr).vAssets();
    vault.updateF1155Balances();

    // Check Vault borrowbalance and apply ratio (consider compound or not)
    uint256 debtPosition = isCompoundActiveProvider ?
    IProviderExt(
      vault.activeProvider()).getBorrowBalanceExact(vAssets.borrowAsset,_vaultAddr) :
      vault.borrowBalance(vault.activeProvider());
    uint256 applyRatiodebtPosition = debtPosition.mul(_ratioA).div(_ratioB);

    // Check Ratio Input and Vault Balance at ActiveProvider
    require(
      debtPosition >= applyRatiodebtPosition &&
      applyRatiodebtPosition > 0,
      Errors.RF_INVALID_RATIO_VALUES
    );

    //Initiate Flash Loan Struct
    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Switch,
      asset: vAssets.borrowAsset,
      amount: applyRatiodebtPosition,
      vault: _vaultAddr,
      newProvider: _newProvider,
      user: address(0),
      userliquidator: address(0),
      fliquidator: address(0)
    });

    Flasher(payable(_fujiAdmin.getFlasher())).initiateFlashloan(info, _flashnum);

  }

  /**
  * @dev Compares borrowing rates from providers of a vault
  * @param _vaultAddr: Fuji vault address
  */
  function checkRates(address _vaultAddr) public view returns(bool opportunityTochange, address newProvider) {
    //Get the array of Providers from _vaultAddr
    address[] memory arrayOfProviders = IVault(_vaultAddr).getProviders();
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vaultAddr).vAssets();

    //Call and check borrow rates for all Providers in array for _vaultAddr
    uint256 currentRate = IProvider(IVault(_vaultAddr).activeProvider()).getBorrowRateFor(vAssets.borrowAsset);
    uint256 newRate = currentRate;

    for (uint i=0; i < arrayOfProviders.length; i++) {
      if(
        newRate > IProvider(arrayOfProviders[i]).getBorrowRateFor(vAssets.borrowAsset)
      ){
        newProvider = arrayOfProviders[i];
        newRate = IProvider(arrayOfProviders[i]).getBorrowRateFor(vAssets.borrowAsset);
      }
    }
    if( currentRate.sub(newRate) >= deltaAPRThreshold) {
      opportunityTochange = true;
    }
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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