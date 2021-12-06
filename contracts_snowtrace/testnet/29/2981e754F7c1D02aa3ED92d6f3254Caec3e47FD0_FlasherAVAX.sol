/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-05
*/

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


interface IFliquidator {
  function executeFlashClose(
    address _userAddr,
    address _vault,
    uint256 _amount,
    uint256 _flashloanfee
  ) external payable;

  function executeFlashBatchLiquidation(
    address[] calldata _userAddrs,
    uint256[] calldata _usrsBals,
    address _liquidatorAddr,
    address _vault,
    uint256 _amount,
    uint256 _flashloanFee
  ) external payable;
}


interface IFujiMappings {

  // FujiMapping Events

  /**
  * @dev Log a change in address mapping
  */
  event MappingChanged(address keyAddress, address mappedAddress);
  /**
  * @dev Log a change in URI
  */
  event UriChanged(string newUri);

  function addressMapping(address) external view returns (address);
}


interface IWETH {
  function approve(address, uint256) external;

  function deposit() external payable;

  function withdraw(uint256) external;
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


interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}


interface IAaveLendingPool {
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

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


interface ICTokenFlashloan {
  function flashLoan(
    address receiver,
    address initiator,
    uint256 amount,
    bytes calldata params
  ) external;
}


interface ICFlashloanReceiver {
  function onFlashLoan(
    address sender,
    address underlying,
    uint256 amount,
    uint256 fee,
    bytes calldata params
  ) external returns (bytes32);
}


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


library LibUniversalERC20AVAX {
  using SafeERC20 for IERC20;

  IERC20 private constant _AVAX_ADDRESS = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
  IERC20 private constant _ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

  function isAVAX(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _AVAX_ADDRESS);
  }

  function univBalanceOf(IERC20 token, address account) internal view returns (uint256) {
    if (isAVAX(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function univTransfer(
    IERC20 token,
    address payable to,
    uint256 amount
  ) internal {
    if (amount > 0) {
      if (isAVAX(token)) {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send AVAX");
      } else {
        token.safeTransfer(to, amount);
      }
    }
  }

  function univApprove(
    IERC20 token,
    address to,
    uint256 amount
  ) internal {
    require(!isAVAX(token), "Approve called on AVAX");

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


/**
 * @dev Contract that handles Fuji protocol flash loan logic and
 * the specific logic of all active flash loan providers used by Fuji protocol.
 */
contract FlasherAVAX is IFlasher, Claimable, IFlashLoanReceiver, ICFlashloanReceiver {
  using LibUniversalERC20AVAX for IERC20;

  IFujiAdmin private _fujiAdmin;

  address private constant _AVAX = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  address private constant _WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
  address private constant _cAVAX = 0x219990FA1f91751539c65aE3f50040C6701cF219;

  address private immutable _aavxLendingPool = 0x76cc67FF2CC77821A70ED14321111Ce381C2594D;
  IFujiMappings private immutable _crMappings = IFujiMappings(0x1eEdE44b91750933C96d2125b6757C4F89e63E20);

  // need to be payable because of the conversion ETH <> WETH
  receive() external payable {}

  /**
  * @dev Throws if caller is not 'owner'.
  */
  modifier isAuthorized() {
    require(
      msg.sender == _fujiAdmin.getController() ||
        msg.sender == _fujiAdmin.getFliquidator() ||
        msg.sender == owner(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  /**
   * @dev Sets the fujiAdmin Address
   * @param _newFujiAdmin: FujiAdmin Contract Address
   * Emits a {FujiAdminChanged} event.
   */
  function setFujiAdmin(address _newFujiAdmin) public onlyOwner {
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
    emit FujiAdminChanged(_newFujiAdmin);
  }

  /**
   * @dev Routing Function for Flashloan Provider
   * @param info: struct information for flashLoan
   * @param _flashnum: integer identifier of flashloan provider
   */
  function initiateFlashloan(FlashLoan.Info calldata info, uint8 _flashnum) external isAuthorized override {
    if (_flashnum == 0) {
      _initiateGeistFlashLoan(info);
    } else if (_flashnum == 2) {
      _initiateCreamFlashLoan(info);
    } else {
      revert(Errors.VL_INVALID_FLASH_NUMBER);
    }
  }

  /**
   * @dev Initiates an Geist flashloan.
   * @param info: data to be passed between functions executing flashloan logic
   */
  function _initiateGeistFlashLoan(FlashLoan.Info calldata info) internal {
    //Initialize Instance of Geist Lending Pool
    IAaveLendingPool geistLp = IAaveLendingPool(_aavxLendingPool);

    //Passing arguments to construct Geist flashloan -limited to 1 asset type for now.
    address receiverAddress = address(this);
    address[] memory assets = new address[](1);
    assets[0] = address(info.asset == _AVAX ? _WAVAX : info.asset);
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = info.amount;

    // 0 = no debt, 1 = stable, 2 = variable
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    //address onBehalfOf = address(this);
    //bytes memory params = abi.encode(info);
    //uint16 referralCode = 0;

    //Geist Flashloan initiated.
    geistLp.flashLoan(receiverAddress, assets, amounts, modes, address(this), abi.encode(info), 0);
  }

  /**
   * @dev Executes Geist Flashloan, this operation is required
   * and called by Geistflashloan when sending loaned amount
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    require(msg.sender == _aavxLendingPool && initiator == address(this), Errors.VL_NOT_AUTHORIZED);

    FlashLoan.Info memory info = abi.decode(params, (FlashLoan.Info));

    uint256 _value;
    if (info.asset == _AVAX) {
      // Convert WAVAX to AVAX and assign amount to be set as msg.value
      _convertWavaxToAvax(amounts[0]);
      _value = info.amount;
    } else {
      // Transfer to Vault the flashloan Amount
      // _value is 0
      IERC20(assets[0]).univTransfer(payable(info.vault), amounts[0]);
    }

    _executeAction(info, amounts[0], premiums[0], _value);

    //Approve geistLP to spend to repay flashloan
    _approveBeforeRepay(info.asset == _AVAX, assets[0], amounts[0] + premiums[0], _aavxLendingPool);

    return true;
  }

  // ===================== CreamFinance FlashLoan ===================================

  /**
   * @dev Initiates an CreamFinance flashloan.
   * @param info: data to be passed between functions executing flashloan logic
   */
  function _initiateCreamFlashLoan(FlashLoan.Info calldata info) internal {
    address crToken = info.asset == _AVAX
      ? _cAVAX
      : _crMappings.addressMapping(info.asset);

    // Prepara data for flashloan execution
    bytes memory params = abi.encode(info);

    // Initialize Instance of Cream crLendingContract
    ICTokenFlashloan(crToken).flashLoan(address(this), address(this), info.amount, params);
  }
  /**
   * @dev Executes CreamFinance Flashloan, this operation is required
   * and called by CreamFinanceflashloan when sending loaned amount
   */
  function onFlashLoan(
    address sender,
    address underlying,
    uint256 amount,
    uint256 fee,
    bytes calldata params
  ) external override returns (bytes32) {
    // Check Msg. Sender is crToken Lending Contract
    // from IronBank because ETH on Cream cannot perform a flashloan
    address crToken = underlying == _WAVAX
      ? _cAVAX
      : _crMappings.addressMapping(underlying);
    require(msg.sender == crToken && address(this) == sender, Errors.VL_NOT_AUTHORIZED);
    require(IERC20(underlying).balanceOf(address(this)) >= amount, Errors.VL_FLASHLOAN_FAILED);
    FlashLoan.Info memory info = abi.decode(params, (FlashLoan.Info));
    uint256 _value;
    if (info.asset == _AVAX) {
      // Convert WAVAX to AVAX and assign amount to be set as msg.value
      _convertWavaxToAvax(amount);
      _value = amount;
    } else {
      // Transfer to Vault the flashloan Amount
      // _value is 0
      IERC20(underlying).univTransfer(payable(info.vault), amount);
    }
    // Do task according to CallType
    _executeAction(info, amount, fee, _value);

    if (info.asset == _AVAX) _convertAvaxToWavax(amount + fee);
    // Transfer flashloan + fee back to crToken Lending Contract
    IERC20(underlying).univApprove(payable(crToken), amount + fee);

    return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
  }

  // ========================================================
  //
  // flash loans come here....
  //
  // ========================================================

  function _executeAction(
    FlashLoan.Info memory _info,
    uint256 _amount,
    uint256 _fee,
    uint256 _value
  ) internal {
    if (_info.callType == FlashLoan.CallType.Switch) {
      IVault(_info.vault).executeSwitch{ value: _value }(_info.newProvider, _amount, _fee);
    } else if (_info.callType == FlashLoan.CallType.Close) {
      IFliquidator(_info.fliquidator).executeFlashClose{ value: _value }(
        _info.userAddrs[0],
        _info.vault,
        _amount,
        _fee
      );
    } else {
      IFliquidator(_info.fliquidator).executeFlashBatchLiquidation{ value: _value }(
        _info.userAddrs,
        _info.userBalances,
        _info.userliquidator,
        _info.vault,
        _amount,
        _fee
      );
    }
  }

  function _approveBeforeRepay(
    bool _isAVAX,
    address _asset,
    uint256 _amount,
    address _spender
  ) internal {
    if (_isAVAX) {
      _convertAvaxToWavax(_amount);
      IERC20(_WAVAX).univApprove(payable(_spender), _amount);
    } else {
      IERC20(_asset).univApprove(payable(_spender), _amount);
    }
  }

  function _convertAvaxToWavax(uint256 _amount) internal {
    IWETH(_WAVAX).deposit{ value: _amount }();
  }

  function _convertWavaxToAvax(uint256 _amount) internal {
    IWETH token = IWETH(_WAVAX);
    token.withdraw(_amount);
  }
}