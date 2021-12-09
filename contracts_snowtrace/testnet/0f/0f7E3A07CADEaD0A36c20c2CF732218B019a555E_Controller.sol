/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Abstract contract that implements a modified version of  Openzeppelin {Ownable.sol} contract.
 * It creates a two step process for the transfer of ownership.
 */
abstract contract Claimable is Context {

  address private _owner;

  address public pendingOwner;

  // Claimable Events

  /**
   * @dev Emits when step two in ownership transfer is completed.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev Emits when step one in ownership transfer is initiated.
   */
  event NewPendingOwner(address indexed owner);

  /**
  * @dev Initializes the contract setting the deployer as the initial owner.
  */
  constructor() {
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
    require(_msgSender() == owner(), "Ownable: caller is not the owner");
    _;
  }

  /**
  * @dev Throws if called by any account other than the pendingOwner.
  */
  modifier onlyPendingOwner() {
    require(_msgSender() == pendingOwner);
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
    emit OwnershipTransferred(owner(), address(0));
    _owner = address(0);
  }

  /**
   * @dev Step one of ownership transfer.
   * Initiates transfer of ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   *
   * NOTE:`newOwner` requires to claim ownership in order to be able to call
   * {onlyOwner} modified functions.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(
      newOwner != address(0),
      'Cannot pass zero address!'
    );
    require(pendingOwner == address(0), "There is a pending owner!");
    pendingOwner = newOwner;
    emit NewPendingOwner(newOwner);
  }

  /**
   * @dev Cancels the transfer of ownership of the contract.
   * Can only be called by the current owner.
   */
  function cancelTransferOwnership() public onlyOwner {
    require(pendingOwner != address(0));
    delete pendingOwner;
    emit NewPendingOwner(address(0));
  }

  /**
   * @dev Step two of ownership transfer.
   * 'pendingOwner' claims ownership of the contract.
   * Can only be called by the pending owner.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner(), pendingOwner);
    _owner = pendingOwner;
    delete pendingOwner;
  }
}


library Account {
  enum Status {
    Normal,
    Liquid,
    Vapor
  }
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

library FlashLoan {
  /**
   * @dev Used to determine which vault's function to call post-flashloan:
   * - Switch for executeSwitch(...)
   * - Close for executeFlashClose(...)
   * - Liquidate for executeFlashLiquidation(...)
   * - BatchLiquidate for executeFlashBatchLiquidation(...)
   */
  enum CallType {
    Switch,
    Close,
    BatchLiquidate
  }

  /**
   * @dev Struct of params to be passed between functions executing flashloan logic
   * @param asset: Address of asset to be borrowed with flashloan
   * @param amount: Amount of asset to be borrowed with flashloan
   * @param vault: Vault's address on which the flashloan logic to be executed
   * @param newProvider: New provider's address. Used when callType is Switch
   * @param userAddrs: User's address array Used when callType is BatchLiquidate
   * @param userBals:  Array of user's balances, Used when callType is BatchLiquidate
   * @param userliquidator: The user's address who is  performing liquidation. Used when callType is Liquidate
   * @param fliquidator: Fujis Liquidator's address.
   */
  struct Info {
    CallType callType;
    address asset;
    uint256 amount;
    address vault;
    address newProvider;
    address[] userAddrs;
    uint256[] userBalances;
    address userliquidator;
    address fliquidator;
  }
}


interface IFlasher {

  /**
  * @dev Logs a change in FujiAdmin address.
  */
  event FujiAdminChanged(address newFujiAdmin);
  
  function initiateFlashloan(FlashLoan.Info calldata info, uint8 amount) external;
}


interface IVault {

  // Vault Events

  /**
  * @dev Log a deposit transaction done by a user
  */
  event Deposit(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a withdraw transaction done by a user
  */
  event Withdraw(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a borrow transaction done by a user
  */
  event Borrow(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a payback transaction done by a user
  */
  event Payback(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a switch from provider to new provider in vault
  */
  event Switch(
    address fromProviderAddrs,
    address toProviderAddr,
    uint256 debtamount,
    uint256 collattamount
  );
  /**
  * @dev Log a change in active provider
  */
  event SetActiveProvider(address newActiveProviderAddress);
  /**
  * @dev Log a change in the array of provider addresses
  */
  event ProvidersChanged(address[] newProviderArray);
  /**
  * @dev Log a change in F1155 address
  */
  event F1155Changed(address newF1155Address);
  /**
  * @dev Log a change in fuji admin address
  */
  event FujiAdminChanged(address newFujiAdmin);
  /**
  * @dev Log a change in the factor values
  */
  event FactorChanged(
    FactorType factorType,
    uint64 newFactorA,
    uint64 newFactorB
  );
  /**
  * @dev Log a change in the oracle address
  */
  event OracleChanged(address newOracle);

  enum FactorType {
    Safety,
    Collateralization,
    ProtocolFee,
    BonusLiquidation
  }

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Core Vault Functions

  function deposit(uint256 _collateralAmount) external payable;

  function withdraw(int256 _withdrawAmount) external;

  function withdrawLiq(int256 _withdrawAmount) external;

  function borrow(uint256 _borrowAmount) external;

  function payback(int256 _repayAmount) external payable;

  function paybackLiq(address[] memory _users, uint256 _repayAmount) external payable;

  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanDebt,
    uint256 _fee
  ) external payable;

  //Getter Functions

  function activeProvider() external view returns (address);

  function borrowBalance(address _provider) external view returns (uint256);

  function depositBalance(address _provider) external view returns (uint256);

  function userDebtBalance(address _user) external view returns (uint256);

  function userProtocolFee(address _user) external view returns (uint256);

  function userDepositBalance(address _user) external view returns (uint256);

  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    external
    view
    returns (uint256);

  function getLiquidationBonusFor(uint256 _amount) external view returns (uint256);

  function getProviders() external view returns (address[] memory);

  function fujiERC1155() external view returns (address);

  //Setter Functions

  function setActiveProvider(address _provider) external;

  function updateF1155Balances() external;

  function protocolFee() external view returns (uint64, uint64);
}


interface IVaultControl {
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  function vAssets() external view returns (VaultAssets memory);
}


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

  function getBorrowBalanceOf(address _asset, address _who) external returns (uint256);
}


interface IFujiAdmin {

  // FujiAdmin Events

  /**
  * @dev Log change of flasher address
  */
  event FlasherChanged(address newFlasher);
  /**
  * @dev Log change of fliquidator address
  */
  event FliquidatorChanged(address newFliquidator);
  /**
  * @dev Log change of treasury address
  */
  event TreasuryChanged(address newTreasury);
  /**
  * @dev Log change of controller address
  */
  event ControllerChanged(address newController);
  /**
  * @dev Log change of vault harvester address
  */
  event VaultHarvesterChanged(address newHarvester);
  /**
  * @dev Log change of swapper address
  */
  event SwapperChanged(address newSwapper);
  /**
  * @dev Log change of vault address permission
  */
  event VaultPermitChanged(address vaultAddress, bool newPermit);


  function validVault(address _vaultAddr) external view returns (bool);

  function getFlasher() external view returns (address);

  function getFliquidator() external view returns (address);

  function getController() external view returns (address);

  function getTreasury() external view returns (address payable);

  function getVaultHarvester() external view returns (address);

  function getSwapper() external view returns (address);
}


/**
 * @title Errors library
 * @author Fuji
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = Validation Logic 100 series
 *  - MATH = Math libraries 200 series
 *  - RF = Refinancing 300 series
 *  - VLT = vault 400 series
 *  - SP = Special 900 series
 */
library Errors {
  //Errors
  string public constant VL_INDEX_OVERFLOW = "100"; // index overflows uint128
  string public constant VL_INVALID_MINT_AMOUNT = "101"; //invalid amount to mint
  string public constant VL_INVALID_BURN_AMOUNT = "102"; //invalid amount to burn
  string public constant VL_AMOUNT_ERROR = "103"; //Input value >0, and for ETH msg.value and amount shall match
  string public constant VL_INVALID_WITHDRAW_AMOUNT = "104"; //Withdraw amount exceeds provided collateral, or falls undercollaterized
  string public constant VL_INVALID_BORROW_AMOUNT = "105"; //Borrow amount does not meet collaterization
  string public constant VL_NO_DEBT_TO_PAYBACK = "106"; //Msg sender has no debt amount to be payback
  string public constant VL_MISSING_ERC20_ALLOWANCE = "107"; //Msg sender has not approved ERC20 full amount to transfer
  string public constant VL_USER_NOT_LIQUIDATABLE = "108"; //User debt position is not liquidatable
  string public constant VL_DEBT_LESS_THAN_AMOUNT = "109"; //User debt is less than amount to partial close
  string public constant VL_PROVIDER_ALREADY_ADDED = "110"; // Provider is already added in Provider Array
  string public constant VL_NOT_AUTHORIZED = "111"; //Not authorized
  string public constant VL_INVALID_COLLATERAL = "112"; //There is no Collateral, or Collateral is not in active in vault
  string public constant VL_NO_ERC20_BALANCE = "113"; //User does not have ERC20 balance
  string public constant VL_INPUT_ERROR = "114"; //Check inputs. For ERC1155 batch functions, array sizes should match.
  string public constant VL_ASSET_EXISTS = "115"; //Asset intended to be added already exists in FujiERC1155
  string public constant VL_ZERO_ADDR_1155 = "116"; //ERC1155: balance/transfer for zero address
  string public constant VL_NOT_A_CONTRACT = "117"; //Address is not a contract.
  string public constant VL_INVALID_ASSETID_1155 = "118"; //ERC1155 Asset ID is invalid.
  string public constant VL_NO_ERC1155_BALANCE = "119"; //ERC1155: insufficient balance for transfer.
  string public constant VL_MISSING_ERC1155_APPROVAL = "120"; //ERC1155: transfer caller is not owner nor approved.
  string public constant VL_RECEIVER_REJECT_1155 = "121"; //ERC1155Receiver rejected tokens
  string public constant VL_RECEIVER_CONTRACT_NON_1155 = "122"; //ERC1155: transfer to non ERC1155Receiver implementer
  string public constant VL_OPTIMIZER_FEE_SMALL = "123"; //Fuji OptimizerFee has to be > 1 RAY (1e27)
  string public constant VL_UNDERCOLLATERIZED_ERROR = "124"; // Flashloan-Flashclose cannot be used when User's collateral is worth less than intended debt position to close.
  string public constant VL_MINIMUM_PAYBACK_ERROR = "125"; // Minimum Amount payback should be at least Fuji Optimizerfee accrued interest.
  string public constant VL_HARVESTING_FAILED = "126"; // Harvesting Function failed, check provided _farmProtocolNum or no claimable balance.
  string public constant VL_FLASHLOAN_FAILED = "127"; // Flashloan failed
  string public constant VL_ERC1155_NOT_TRANSFERABLE = "128"; // ERC1155: Not Transferable
  string public constant VL_SWAP_SLIPPAGE_LIMIT_EXCEED = "129"; // ERC1155: Not Transferable
  string public constant VL_ZERO_ADDR = "130"; // Zero Address
  string public constant VL_INVALID_FLASH_NUMBER = "131"; // invalid flashloan number
  string public constant VL_INVALID_HARVEST_PROTOCOL_NUMBER = "132"; // invalid flashloan number
  string public constant VL_INVALID_HARVEST_TYPE = "133"; // invalid flashloan number
  string public constant VL_INVALID_FACTOR = "134"; // invalid factor
  string public constant VL_INVALID_NEW_PROVIDER ="135"; // invalid newProvider in executeSwitch

  string public constant MATH_DIVISION_BY_ZERO = "201";
  string public constant MATH_ADDITION_OVERFLOW = "202";
  string public constant MATH_MULTIPLICATION_OVERFLOW = "203";

  string public constant RF_INVALID_RATIO_VALUES = "301"; // Ratio Value provided is invalid, _ratioA/_ratioB <= 1, and > 0, or activeProvider borrowBalance = 0
  string public constant RF_INVALID_NEW_ACTIVEPROVIDER = "302"; //Input '_newProvider' and vault's 'activeProvider' must be different

  string public constant VLT_CALLER_MUST_BE_VAULT = "401"; // The caller of this function must be a vault

  string public constant ORACLE_INVALID_LENGTH = "501"; // The assets length and price feeds length doesn't match
  string public constant ORACLE_NONE_PRICE_FEED = "502"; // The price feed is not found
}


/**
 * @dev Contract that controls rebalances and refinancing of the positions
 * held by the Fuji Vaults.
 *
 */
contract Controller is Claimable {

  // Controller Events

  /**
  * @dev Log a change in fuji admin address
  */
  event FujiAdminChanged(address newFujiAdmin);
  /**
  * @dev Log a change in executor permission
  */
  event ExecutorPermitChanged(address executorAddress, bool newPermit);


  IFujiAdmin private _fujiAdmin;

  mapping(address => bool) public isExecutor;

  /**
  * @dev Throws if address passed is not a recognized vault.
  */
  modifier isValidVault(address _vaultAddr) {
    require(_fujiAdmin.validVault(_vaultAddr), "Invalid vault!");
    _;
  }

  /**
  * @dev Throws if caller passed is not owner or approved executor.
  */
  modifier onlyOwnerOrExecutor() {
    require(msg.sender == owner() || isExecutor[msg.sender], "Not executor!");
    _;
  }

  /**
   * @dev Sets the fujiAdmin Address
   * @param _newFujiAdmin: FujiAdmin Contract Address
   */
  function setFujiAdmin(address _newFujiAdmin) external onlyOwner {
    require(_newFujiAdmin != address(0), Errors.VL_ZERO_ADDR);
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
    emit FujiAdminChanged(_newFujiAdmin);
  }

  /**
   * @dev Performs a forced refinancing routine
   * @param _vaultAddr: fuji Vault address
   * @param _newProvider: new provider address
   * @param _flashNum: integer identifier of flashloan provider
   * Requirements:
   * - '_vaultAddr' should be a valid vault.
   * - '_newProvider' should not be the same as activeProvider in vault.
   */
  function doRefinancing(
    address _vaultAddr,
    address _newProvider,
    uint8 _flashNum
  ) external isValidVault(_vaultAddr) onlyOwnerOrExecutor {

    IVault vault = IVault(_vaultAddr);

    // Validate _newProvider is not equal to vault's activeProvider
    require(
      vault.activeProvider() != _newProvider,
      Errors.RF_INVALID_NEW_ACTIVEPROVIDER
    );

    IVaultControl.VaultAssets memory vAssets = IVaultControl(_vaultAddr).vAssets();
    vault.updateF1155Balances();

    // Check Vault borrowbalance and apply ratio (consider compound or not)
    uint256 debtPosition = IProvider(vault.activeProvider()).getBorrowBalanceOf(
      vAssets.borrowAsset,
      _vaultAddr
    );

    //Initiate Flash Loan Struct
    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Switch,
      asset: vAssets.borrowAsset,
      amount: debtPosition,
      vault: _vaultAddr,
      newProvider: _newProvider,
      userAddrs: new address[](0),
      userBalances: new uint256[](0),
      userliquidator: address(0),
      fliquidator: address(0)
    });

    IFlasher(payable(_fujiAdmin.getFlasher())).initiateFlashloan(info, _flashNum);

    IVault(_vaultAddr).setActiveProvider(_newProvider);
  }

  /**
   * @dev Sets approved executors for 'doRefinancing' function
   * Can only be called by the contract owner.
   * Emits a {ExecutorPermitChanged} event.
   */
  function setExecutors(address[] calldata _executors, bool _isExecutor) external onlyOwner {
    for (uint256 i = 0; i < _executors.length; i++) {
      require(_executors[i] != address(0), Errors.VL_ZERO_ADDR);
      isExecutor[_executors[i]] = _isExecutor;
      emit ExecutorPermitChanged(_executors[i], _isExecutor);
    }
  }
}