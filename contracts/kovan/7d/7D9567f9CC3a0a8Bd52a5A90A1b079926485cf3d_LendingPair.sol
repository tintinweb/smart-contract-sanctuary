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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
pragma solidity 0.8.1;
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/IBSWrapperToken.sol";
import "./interfaces/IDebtToken.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title DataTypes
/// @author @samparsky
////////////////////////////////////////////////////////////////////////////////////////////

library DataTypes {
    struct BorrowAssetConfig {
        uint256 initialExchangeRateMantissa;
        uint256 reserveFactorMantissa;
        uint256 collateralFactor;
        IBSWrapperToken wrappedBorrowAsset;
        uint256 liquidationFee;
        IDebtToken debtToken;
    }

    function validBorrowAssetConfig(BorrowAssetConfig memory self, address _owner) internal view {
        require(self.initialExchangeRateMantissa > 0, "E");
        require(self.reserveFactorMantissa > 0, "F");
        require(self.collateralFactor > 0, "C");
        require(self.liquidationFee > 0, "L");
        require(address(self.wrappedBorrowAsset) != address(0), "B");
        require(address(self.debtToken) != address(0), "IB");
        require(self.wrappedBorrowAsset.owner() == _owner, "IW");
        require(self.debtToken.owner() == _owner, "IVW");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./math/Exponential.sol";
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/IBSVault.sol";
import "./interfaces/IBSLendingPair.sol";
import "./interfaces/IBSWrapperToken.sol";
import "./interfaces/IDebtToken.sol";
import "./interfaces/IPriceOracleAggregator.sol";
import "./DataTypes.sol";
import "./util/Initializable.sol";
import "./token/IERC20Details.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title LendingPair
/// @author @samparsky
/// @notice
///
////////////////////////////////////////////////////////////////////////////////////////////

contract LendingPair is IBSLendingPair, Exponential, Initializable {
    using SafeERC20 for IERC20;
    using DataTypes for DataTypes.BorrowAssetConfig;

    enum Actions {Deposit, Borrow}

    /// @dev lending pair name
    string public name;

    /// @dev lending pair symbol
    string public symbol;

    /// @dev version
    uint256 public constant VERSION = 0x1;

    /// @notice where the tokens are stored
    IBSVault public immutable vault;

    /// @notice protocol liquidation fee percent in 1e18
    uint256 public immutable protocolLiquidationFeeShare;

    /// @notice The interest rate model for the borrow asset
    IInterestRateModel public interestRate;

    /// @notice The price oracle for the assets
    IPriceOracleAggregator public immutable override oracle;

    /// @notice The address to withdraw fees to
    address public immutable feeWithdrawalAddr;

    /// @dev borrow asset underlying decimal
    uint8 private _borrowAssetUnderlyingDecimal;

    /// @dev collateral asset underlying decimal
    uint8 private _collateralAssetUnderlyingDecimal;

    /// @dev initialExchangeRateMantissa Initial exchange rate used when minting
    uint256 internal initialExchangeRateMantissa;

    /// @dev Fraction of interest currently set aside for reserves
    uint256 private reserveFactorMantissa;

    /// @dev Block number that interest was last accrued at
    uint256 private accrualBlockNumber;

    /// @dev Accumulator of the total earned interest rate since the opening of the market
    uint256 public override borrowIndex;

    /// @notice Total amount of reserves of the underlying held in this market
    uint256 public override totalReserves;

    /// @dev The amount of collateral required for a borrow position in 1e18
    uint256 public collateralFactor;

    /// @notice liquidation fee in 1e18
    uint256 public liquidationFee;

    /// @dev liquidation fee precision
    uint256 private constant PRECISION = 1e18;

    /// @notice the address that can pause borrow & deposits of assets
    address public pauseGuardian;

    /// @notice The pair borrow asset
    IERC20 public override asset;

    /// @notice The pair collateral asset
    IERC20 public override collateralAsset;

    /// @notice The wrapper token for the borrow asset
    IBSWrapperToken public override wrapperBorrowedAsset;

    /// @notice The wrapper token for the collateral asset
    IBSWrapperToken public override wrappedCollateralAsset;

    /// @notice The wrapper token for debt
    IDebtToken public override debtToken;

    /// @notice Mapping of account addresses to their interest interest index
    mapping(address => uint256) public override accountInterestIndex;

    /// @notice Mapping of action to pause status
    mapping(Actions => bool) public pauseStatus;

    modifier whenNotPaused(Actions action) {
        require(pauseStatus[action] == false, "PAUSED");
        _;
    }

    modifier onlyPauseGuardian() {
        require(msg.sender == pauseGuardian, "O_G");
        _;
    }

    constructor(
        IBSVault _vault,
        IPriceOracleAggregator _oracle,
        address _feeWithdrawalAddr,
        uint256 _procotolLiquidationFeeShare
    ) {
        // invalid vault or oracle
        require(address(_vault) != address(0), "IV0");
        // invalid vault or oracle
        require(address(_oracle) != address(0), "IV0");
        // invalid fee withdrawal addr
        require(_feeWithdrawalAddr != address(0), "IVWA");

        vault = _vault;
        oracle = _oracle;
        feeWithdrawalAddr = _feeWithdrawalAddr;
        protocolLiquidationFeeShare = _procotolLiquidationFeeShare;
    }

    /// @notice Initialize function
    /// @param _name for lending pair
    /// @param _symbol for lending pair
    /// @param _asset borrow asset  
    /// @param _collateralAsset pair collateral
    /// @param _wrappedCollateralAsset wrapped token minted when depositing collateral asset
    /// @param _pauseGuardian pause guardian address
    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20 _asset,
        IERC20 _collateralAsset,
        DataTypes.BorrowAssetConfig calldata borrowConfig,
        IBSWrapperToken _wrappedCollateralAsset,
        IInterestRateModel _interestRate,
        address _pauseGuardian
    ) external override initializer {
        // invalid asset or collateral asset
        require(address(_asset) != address(0) && address(_collateralAsset) != address(0), "IAC");
        // invalid pause guardian
        require(_pauseGuardian != address(0), "IVP");
        // validate wrapped collateral asset owner
        require(_wrappedCollateralAsset.owner() == address(this), "IVWC");
        // interest rate model
        require(address(_interestRate) != address(0), "IVIR");
        // en
        require(borrowConfig.liquidationFee > 0, "INLF");
        // validate borrow config
        borrowConfig.validBorrowAssetConfig(address(this));

        name = _name;
        symbol = _symbol;
        pauseGuardian = _pauseGuardian;
        asset = _asset;
        collateralAsset = _collateralAsset;
        interestRate = _interestRate;
        borrowIndex = mantissaOne;

        initialExchangeRateMantissa = borrowConfig.initialExchangeRateMantissa;
        reserveFactorMantissa = borrowConfig.reserveFactorMantissa;
        collateralFactor = borrowConfig.collateralFactor;
        liquidationFee = borrowConfig.liquidationFee;
        wrapperBorrowedAsset = borrowConfig.wrappedBorrowAsset;
        debtToken = borrowConfig.debtToken;

        wrappedCollateralAsset = _wrappedCollateralAsset;

        _borrowAssetUnderlyingDecimal = IERC20Details(address(asset)).decimals();
        _collateralAssetUnderlyingDecimal = IERC20Details(address(collateralAsset)).decimals();

        emit Initialized(address(this), address(_asset), address(_collateralAsset), _pauseGuardian);
    }

    /// @dev pause actions in the lending pair
    function pause(Actions action) external onlyPauseGuardian {
        pauseStatus[action] = true;
        emit ActionPaused(uint8(action), block.timestamp);
    }

    /// @dev unpause actions in lending pair
    function unpause(Actions action) external onlyPauseGuardian {
        pauseStatus[action] = false;
        emit ActionUnPaused(uint8(action), block.timestamp);
    }

    /// @notice deposit allows a user to deposit underlying collateral from vault
    /// @param _tokenRecipient address to credit the wrapped collateral shares
    /// @param _amount is the amount of underlying collateral asset being deposited
    function depositCollateral(address _tokenRecipient, uint256 _amount)
        public
        override
        whenNotPaused(Actions.Deposit)
    {
        uint256 vaultShareAmount = vault.toShare(collateralAsset, _amount, false);

        vault.transfer(collateralAsset, msg.sender, address(this), vaultShareAmount);
        // mint receipient vault share amount
        wrappedCollateralAsset.mint(_tokenRecipient, vaultShareAmount);
        emit Deposit(
            address(this),
            address(collateralAsset),
            _tokenRecipient,
            msg.sender,
            vaultShareAmount
        );
    }

    /// @dev the user should initially have deposited in the vault
    /// transfer appropriate amount of underlying from msg.sender to the LendingPair
    /// @param _tokenReceipeint whom to credit the wrapped tokens
    /// @param _amount is the amount of underlying borrow asset being deposited
    function depositBorrowAsset(address _tokenReceipeint, uint256 _amount)
        public
        override
        whenNotPaused(Actions.Deposit)
    {
        require(_tokenReceipeint != address(0), "IDB");
        uint256 vaultShareAmount = vault.toShare(asset, _amount, false);

        // retrieve exchange rate
        uint256 exchangeRateMantissa = exchangeRateCurrent();
        // We get the current exchange rate and calculate the number of wrapper token to be minted:
        // mintTokens = _amount / exchangeRate
        uint256 mintTokens =
            divScalarByExpTruncate(vaultShareAmount, Exp({mantissa: exchangeRateMantissa}));

        // transfer appropriate amount of DAI from msg.sender to the Vault
        vault.transfer(asset, msg.sender, address(this), vaultShareAmount);

        // mint appropriate wrapped tokens
        wrapperBorrowedAsset.mint(_tokenReceipeint, mintTokens);

        emit Deposit(
            address(this),
            address(asset),
            _tokenReceipeint,
            msg.sender,
            vaultShareAmount
        );
    }

    /// @param _amountToBorrow is the amount of the borrow asset vault shares the user wants to borrow
    /// @param _debtOwner this should be the msg.sender or address that delegates credit to the msg.sender
    /// @dev we use normalized amounts to calculate the
    function borrow(uint256 _amountToBorrow, address _debtOwner) external whenNotPaused(Actions.Borrow) {
        require(_debtOwner != address(0), "INV_DEBT_OWNER");
        // save on sload
        uint8 __borrowAssetUnderlyingDecimal = _borrowAssetUnderlyingDecimal;
        IERC20 __asset = asset;

        uint256 borrowedTotalWithInterest = borrowBalanceCurrent(_debtOwner);
        uint256 currentBorrowAssetPrice = oracle.getPriceInUSD(__asset);
        uint256 borrowedTotalInUSDNormalized =
            normalize(borrowedTotalWithInterest, __borrowAssetUnderlyingDecimal) *
                currentBorrowAssetPrice;
        uint256 borrowLimitInUSDNormalized =
            normalize(getBorrowLimit(_debtOwner), _collateralAssetUnderlyingDecimal) *
                getPriceOfCollateral();
        uint256 borrowAmountAllowedInUSDNormalized =
            borrowLimitInUSDNormalized - borrowedTotalInUSDNormalized;
        // borrow amount in usd normalized
        uint256 borrowAmountInUSDNormalized =
            normalize(_amountToBorrow, __borrowAssetUnderlyingDecimal) * currentBorrowAssetPrice;
        // require the amount being borrowed is less than
        // or equal to the amount they are aloud to borrow
        require(
            borrowAmountAllowedInUSDNormalized >= borrowAmountInUSDNormalized,
            "BORROWING_MORE_THAN_ALLOWED"
        );

        uint256 amountOfSharesToBorrow = vault.toShare(__asset, _amountToBorrow, false);
        // mint debt tokens to _debtOwner account
        debtToken.mint(_debtOwner, msg.sender, _amountToBorrow);
        // set interest index
        accountInterestIndex[_debtOwner] = borrowIndex;
        // transfer borrow asset to borrower
        vault.transfer(__asset, address(this), msg.sender, amountOfSharesToBorrow);

        emit Borrow(msg.sender, _amountToBorrow);
    }

    /// @notice Sender repays their own borrow
    /// @param _repayAmount The amount of borrow asset to repay represented in underlying
    /// @param _beneficiary address to repay loan position
    function repay(uint256 _repayAmount, address _beneficiary) public {
        require(_beneficiary != address(0), "INV_BENEFICIARY");

        // We fetch the amount the borrower owes, with accumulated interest
        uint256 accountBorrows = borrowBalanceCurrent(_beneficiary);

        // require the borrower cant pay more than they owe
        require(_repayAmount <= accountBorrows, "MORE_THAN_OWED");

        uint256 repayAmount = 0;

        if (_repayAmount == 0) {
            repayAmount = accountBorrows;
        } else {
            repayAmount = _repayAmount;
        }

        // convert repayAmount to share and round up
        uint256 repayAmountInShares = vault.toShare(asset, repayAmount, true);

        require(
            vault.balanceOf(asset, msg.sender) >= repayAmountInShares,
            "NOT_ENOUGH_BALANCE"
        );

        // transfer the borrow asset from the borrower to LendingPair
        vault.transfer(asset, msg.sender, address(this), repayAmountInShares);

        accountInterestIndex[_beneficiary] = borrowIndex;

        debtToken.burn(_beneficiary, repayAmount);

        emit Repay(
            address(this),
            address(asset),
            _beneficiary,
            msg.sender,
            repayAmount
        );
    }

    struct RedeemLocalVars {
        uint256 exchangeRateMantissa;
        uint256 burnTokens;
        uint256 currentBSBalance;
        uint256 currentUnderlyingBalance;
        uint256 amount;
    }

    /// @notice Allows a user to redeem their Wrapper Token for the appropriate amount of underlying asset
    /// @param _to Address to send the underlying tokens to
    /// @param _amount of wrapper token to redeem
    function redeem(address _to, uint256 _amount) public override {
        require(_to != address(0), "INV_TO");

        RedeemLocalVars memory vars;

        // fetch the users current wrapped balance
        vars.currentBSBalance = wrapperBorrowedAsset.balanceOf(msg.sender);

        // retreive current exchange rate
        vars.exchangeRateMantissa = exchangeRateCurrent();
        // calculate the current underlying balance
        vars.currentUnderlyingBalance = mulScalarTruncate(
            Exp({mantissa: vars.exchangeRateMantissa}),
            vars.currentBSBalance
        );

        if (_amount == 0) {
            vars.amount = vars.currentUnderlyingBalance;
        } else {
            vars.amount = _amount;
        }

        // we get the current exchange rate and calculate the number of WarpWrapperToken to be burned:
        // burnTokens = _amount / exchangeRate
        vars.burnTokens = divScalarByExpTruncate(
            vars.amount,
            Exp({mantissa: vars.exchangeRateMantissa})
        );

        // ensure the vault pair has enough borrow asset balance
        require(vault.balanceOf(asset, address(this)) >= vars.amount, "NOT_ENOUGH_BALANCE");
        // reverts if the user doesn't have enough balance
        wrapperBorrowedAsset.burn(msg.sender, vars.burnTokens);
        // transfer
        vault.transfer(asset, address(this), _to, vars.amount);

        emit Redeem(address(this), address(asset), msg.sender, _to, vars.amount, vars.burnTokens);
    }
    
    uint8 private constant COLLATERAL_DEPOSIT = 1;
    uint8 private constant BORROW_ASSET_DEPOSIT = 2;
    uint8 private constant REPAY = 3;
    uint8 private constant REDEEM = 4;
    uint8 private constant WITHDRAW_COLLATERAL = 5;
    uint8 private constant VAULT_DEPOSIT = 6;
    uint8 private constant VAULT_WITHDRAW = 7;
    uint8 private constant VAULT_TRANSFER = 8;
    uint8 private constant VAULT_APPROVE_CONTRACT = 9;

    function warp(
        uint8[] calldata actions,
        bytes[] calldata data
    ) external {
        require(actions.length == data.length, "INV");

        for (uint8 i = 0; i < actions.length;  i++) {
            uint8 action = actions[i];
            if (action == BORROW_ASSET_DEPOSIT) {
                (address receipient, uint256 vaultAmount) = abi.decode(data[i], (address, uint256));
                depositBorrowAsset(receipient, vaultAmount);
            } else if (action == COLLATERAL_DEPOSIT) {
                (address receipient, uint256 amount) = abi.decode(data[i], (address, uint256));
                depositCollateral(receipient, amount);
            } else if (action == REPAY) {
                (uint256 amount, address beneficiary) = abi.decode(data[i], (uint256, address));
                repay(amount, beneficiary);
            } else if (action == REDEEM) {
                (address receipient, uint256 amount) = abi.decode(data[i], (address, uint256));
                redeem(receipient, amount);
            } else if (action == WITHDRAW_COLLATERAL) {
                (uint256 amount) = abi.decode(data[i], (uint256));
                withdrawCollateral(amount);
            } else if (action == VAULT_DEPOSIT) {
                (address token, address to, uint256 amount) = abi.decode(data[i], (address, address, uint256));
                vault.deposit(IERC20(token), msg.sender, to, amount);
            } else if (action == VAULT_WITHDRAW) {
                (address token, address to, uint256 amount) = abi.decode(data[i], (address, address, uint256));
                vault.withdraw(IERC20(token), msg.sender, to, amount);
            } else if (action == VAULT_TRANSFER) {
                (address token, address to, uint256 amount) = abi.decode(data[i], (address, address, uint256));
                vault.transfer(IERC20(token), msg.sender, to, amount);
            } else if (action == VAULT_APPROVE_CONTRACT) {
                (
                    address _user,
                    address _contract,
                    bool status,
                    uint8 v,
                    bytes32 r,
                    bytes32 s
                ) = abi.decode(data[i], (address, address, bool, uint8, bytes32, bytes32));
                vault.approveContract(_user, _contract, status, v, r, s);
            }
        }
    }

    /// @notice calculateFee is used to calculate the fee earned
    /// @param _amount is a uint representing the full amount earned as interest
    function calculateLiquidationFee(uint256 _amount) public view returns (uint256 fee) {
        fee = (_amount * liquidationFee) / PRECISION;
    }

    /// @notice Accrue interest then return the up-to-date exchange rate
    /// @return Calculated exchange rate scaled by 1e18
    function exchangeRateCurrent() public returns (uint256) {
        accrueInterest();

        // convert amount to underlying
        uint256 currentTotalSupply = vault.toUnderlying(asset, wrapperBorrowedAsset.totalSupply());

        if (currentTotalSupply == 0) {
            // If there are no tokens minted: exchangeRate = initialExchangeRate
            return initialExchangeRateMantissa;
        } else {
            // Otherwise: exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
            uint256 totalCash = getCashPrior(); // get contract asset balance
            uint256 cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;

            // calculate total value held by contract plus owed to contract
            // uint totalBorrows = totalBorrows();
            cashPlusBorrowsMinusReserves = totalCash + totalBorrows() - totalReserves;

            // calculate exchange rate
            exchangeRate = getExp(cashPlusBorrowsMinusReserves, currentTotalSupply);

            return (exchangeRate.mantissa);
        }
    }

    /// @notice getCashPrior is a view funcion that returns the balance of all held borrow asset
    function getCashPrior() public view returns (uint256) {
        uint256 currentBalance = vault.balanceOf(asset, address(this));
        if (currentBalance > 0 ) {
            return vault.toUnderlying(asset, currentBalance);
        }
        return currentBalance;
    }

    /// @notice Total amount of outstanding borrows of the asset in this market
    function totalBorrows() public view returns (uint256) {
        return debtToken.totalSupply();
    }

    /// @notice Applies accrued interest to total borrows and reserves
    /// @dev This calculates interest accrued from the last checkpointed block
    /// up to the current block and writes new checkpoint to storage.
    function accrueInterest() public {
        // remember the initial block number
        uint256 currentBlockNumber = getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        // short-circuit accumulating 0 interest
        if (accrualBlockNumberPrior == currentBlockNumber) {
            emit InterestShortCircuit(currentBlockNumber);
            return;
        }

        // read the previous values out of storage
        uint256 cashPrior = getCashPrior();
        uint256 borrowsPrior = totalBorrows();
        uint256 reservesPrior = totalReserves;

        uint256 borrowIndexPrior = borrowIndex;

        // calculate the current borrow interest rate
        uint256 borrowRateMantissa =
            interestRate.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);

        // Calculate the number of blocks elapsed since the last accrual
        uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        // Calculate the interest accumulated into borrows and reserves and the new index:
        Exp memory simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 totalReservesNew;
        uint256 borrowIndexNew;

        // simpleInterestFactor = borrowRate * blockDelta
        simpleInterestFactor = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);

        // interestAccumulated = simpleInterestFactor * totalBorrows
        interestAccumulated = mulScalarTruncate(simpleInterestFactor, borrowsPrior);

        // totalReservesNew = interestAccumulated * reserveFactor + totalReserves
        totalReservesNew = mulScalarTruncateAddUInt(
            Exp({mantissa: reserveFactorMantissa}),
            interestAccumulated,
            reservesPrior
        );

        // borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
        borrowIndexNew = mulScalarTruncateAddUInt(
            simpleInterestFactor,
            borrowIndexPrior,
            borrowIndexPrior
        );

        // Write the previously calculated values into storage
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        // increase total borrows
        // totalBorrowsNew = interestAccumulated + totalBorrows
        debtToken.increaseTotalDebt(interestAccumulated);

        totalReserves = totalReservesNew;

        emit InterestAccrued(
            address(this),
            accrualBlockNumber,
            borrowIndex,
            // total borrows
            borrowsPrior + interestAccumulated,
            totalReserves
        );
    }

    /**
    @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance 
            using the updated borrowIndex
    @param _account The address whose balance should be calculated after updating borrowIndex
    @return The calculated balance
    **/
    function borrowBalanceCurrent(address _account) public returns (uint256) {
        accrueInterest();
        return borrowBalancePrior(_account);
    }

    function borrowBalancePrior(address _account) public view override returns (uint256 balance) {
        uint256 principalTimesIndex;
        // Get borrowBalance and borrowIndex
        uint256 principal = debtToken.principal(_account);
        // If borrowBalance = 0 then borrowIndex is likely also 0.
        // Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
        if (principal == 0) {
            return 0;
        }

        uint256 borrowInterestIndex = accountInterestIndex[_account];
        // Calculate new borrow balance using the interest index:
        // recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
        principalTimesIndex = principal * borrowIndex;

        balance = principalTimesIndex / borrowInterestIndex;
    }

    /// @notice withdrawFees to the feeWithdrawalAddr
    /// @param _toWithdraw is the amount of a reservers being withdrawn
    /// @dev this function can be called by anyone
    function withdrawFees(uint256 _toWithdraw) external override {
        require(totalReserves >= _toWithdraw, "NOT_ENOUGH_BALANCE");

        totalReserves = totalReserves - _toWithdraw;
        vault.transfer(asset, address(this), feeWithdrawalAddr, _toWithdraw);

        emit ReserveWithdraw(feeWithdrawalAddr, _toWithdraw);
    }

    ////////////////////////////////
    // Collateral Actions
    ///////////////////////////////

    function withdrawCollateral(uint256 _amount) public {
        uint256 amount;

        uint256 maxAmount = getMaxWithdrawAllowed(msg.sender);

        if (_amount == 0) {
            amount = maxAmount;
        } else {
            amount = _amount;
        }

        // require the availible value of the collateral locked in this contract the user has
        // is greater than or equal to the amount being withdrawn
        require(maxAmount >= amount, "EXCEEDS_ALLOWED");
        // subtract withdrawn amount from amount stored
        // reverts if the user doesn't have enough balance
        wrappedCollateralAsset.burn(msg.sender, amount);
        // transfer them their token
        vault.transfer(collateralAsset, address(this), msg.sender, amount);
        emit WithdrawCollateral(msg.sender, amount);
    }

    /// @notice collateralOfAccount is a view function to retreive an accounts collateral
    /// @param _account is the address of the account being looked up
    function collateralOfAccount(address _account) public view override returns (uint256) {
        return wrappedCollateralAsset.balanceOf(_account);
    }

    /// @notice Figures out how much of a given collateral an account is allowed to withdraw
    /// @param _account is the account being checked
    /// @dev this function runs calculations to accrue interest for an up to date amount
    function getMaxWithdrawAllowed(address _account) public override returns (uint256) {
        // save on sload
        uint8 __collateralAssetUnderlyingDecimal = _collateralAssetUnderlyingDecimal;

        uint256 normalizedBorrowedAmountTotal =
            normalize(borrowBalanceCurrent(_account), _borrowAssetUnderlyingDecimal);

        uint256 currentCollateralValueInUSD = getPriceOfCollateral();

        uint256 borrowedTotalNormalizedAmountInUSD =
            getPriceOfToken(asset, normalizedBorrowedAmountTotal);
        uint256 collateralValueNormalizedInUSD =
            normalize(
                getTotalAvailableCollateralValue(_account),
                __collateralAssetUnderlyingDecimal
            ) * currentCollateralValueInUSD;
        uint256 requiredCollateralNormalizedInUSD =
            calcCollateralRequired(borrowedTotalNormalizedAmountInUSD);

        if (collateralValueNormalizedInUSD < requiredCollateralNormalizedInUSD) {
            return 0;
        }

        // remaining collateral denormalized
        uint256 leftoverCollateral =
            denormalize(
                collateralValueNormalizedInUSD - requiredCollateralNormalizedInUSD,
                __collateralAssetUnderlyingDecimal
            );

        return leftoverCollateral / currentCollateralValueInUSD;
    }

    /// @notice getTotalAvailableCollateralValueInUSD returns the total availible collaeral value for an account in USD
    /// @param _account is the address whos collateral is being retreived
    /// @dev this function runs calculations to accrue interest for an up to date amount
    function getTotalAvailableCollateralValueInUSD(address _account) public returns (uint256) {
        return
            getPriceOfToken(
                collateralAsset,
                // convert the amount of collateral to underlying amount
                vault.toUnderlying(collateralAsset, collateralOfAccount(_account))
            );
    }

    /// @notice getTotalAvailableCollateralValue returns the total availible collaeral value for an account
    /// @param _account is the address whos collateral is being retreived
    /// @dev this function runs calculations to accrue interest for an up to date amount
    function getTotalAvailableCollateralValue(address _account) public view returns (uint256) {
        // convert the amount of collateral to underlying amount
        return vault.toUnderlying(collateralAsset, collateralOfAccount(_account));
    }

    /// @dev returns price of collateral in usd
    function getPriceOfCollateral() public returns (uint256) {
        return oracle.getPriceInUSD(collateralAsset);
    }

    /// @dev returns price of collateral in usd
    function getPriceOfBorrowAsset() external returns (uint256) {
        return oracle.getPriceInUSD(asset);
    }

    /// @notice getPriceOfToken returns price of token in usd
    /// @param _token this is the price of the token
    /// @param _amount this is the amount of tokens
    function getPriceOfToken(IERC20 _token, uint256 _amount) public returns (uint256) {
        return oracle.getPriceInUSD(_token) * _amount;
    }

    /// @notice calcBorrowLimit is used to calculate the borrow limit for an account 
    /// based on the input value of their collateral
    /// @param _collateralValueInUSD is the USD value of the users collateral
    function calcBorrowLimit(uint256 _collateralValueInUSD) public view override returns (uint256) {
        return (_collateralValueInUSD * PRECISION) / collateralFactor;
    }

    /// @notice calcCollateralRequired returns the amount of collateral needed for an input borrow value
    /// @param _borrowAmount is the input borrow amount
    function calcCollateralRequired(uint256 _borrowAmount) public view returns (uint256) {
        return (_borrowAmount * collateralFactor) / PRECISION;
    }

    /// @notice getBorrowLimit returns the borrow limit for an account
    /// @param _account is the input account address
    /// @dev this calculation uses current values for calculations
    function getBorrowLimitInUSD(address _account) public returns (uint256) {
        uint256 availibleCollateralValue = getTotalAvailableCollateralValueInUSD(_account);
        return calcBorrowLimit(availibleCollateralValue);
    }

    /// @notice getBorrowLimit returns the borrow limit for an account
    /// @param _account is the input account address
    /// @dev this calculation uses current values for calculations
    function getBorrowLimit(address _account) public view returns (uint256) {
        uint256 availibleCollateralValue = getTotalAvailableCollateralValue(_account);

        return calcBorrowLimit(availibleCollateralValue);
    }

    function liquidate(address _borrower) external {
        // require the liquidator is not also the borrower
        require(msg.sender != _borrower, "NOT_LIQUIDATE_SELF");

        uint256 currentBorrowAssetPriceInUSD = oracle.getPriceInUSD(asset);
        uint256 priceOfCollateralInUSD = getPriceOfCollateral();

        uint256 borrowedTotalWithInterest = borrowBalanceCurrent(_borrower);
        uint256 borrowedTotalInUSDNormalized = 
            normalize(borrowedTotalWithInterest, _borrowAssetUnderlyingDecimal) *
                currentBorrowAssetPriceInUSD;
        uint256 borrowLimitInUSDNormalized =
            normalize(getBorrowLimit(_borrower), _collateralAssetUnderlyingDecimal) *
                priceOfCollateralInUSD;

        // check if the borrow is less than the borrowed amount
        if (borrowLimitInUSDNormalized <= borrowedTotalInUSDNormalized) {
            // liquidation fee
            uint256 totalLiquidationFee = calculateLiquidationFee(borrowedTotalWithInterest);
            uint256 protocolFeeShareValue =
                (totalLiquidationFee * protocolLiquidationFeeShare) / PRECISION;

            _repayLiquidatingLoan(
                _borrower,
                msg.sender,
                borrowedTotalWithInterest,
                borrowedTotalWithInterest + protocolFeeShareValue
            );

            // Clear the borrowers interest rate index
            accountInterestIndex[_borrower] = 0;
            // add protocol liquidaiton fee amount to reserves
            totalReserves = totalReserves + protocolFeeShareValue;

            // convert borrowedTotal to usd
            uint256 borrowedTotalInUSD =
                currentBorrowAssetPriceInUSD * (borrowedTotalWithInterest + totalLiquidationFee);

            // @TODO ceil!?
            uint256 amountOfCollateralToLiquidate = borrowedTotalInUSD / priceOfCollateralInUSD;
            uint256 amountOfCollateralToLiquidateInVaultShares =
                vault.toShare(collateralAsset, amountOfCollateralToLiquidate, true);
            
            _liquidate(_borrower, msg.sender, amountOfCollateralToLiquidateInVaultShares);
        }
    }

    /// @dev _repayLiquidatingLoan
    /// @param _borrower is the address of the borrower who took out the loan
    /// @param _liquidator is the address of the account who is liquidating the loan
    /// @param _borrowedAmount is the amount of StableCoin being repayed + fee
    /// @dev
    function _repayLiquidatingLoan(
        address _borrower,
        address _liquidator,
        uint256 _borrowedAmount,
        uint256 _borrowedAmountPlusFee
    ) internal {
        // borrowed amount + liquidation fee
        uint256 amountInShares = vault.toShare(asset, _borrowedAmountPlusFee, true);
        // repay the liquidated position
        vault.transfer(asset, _liquidator, address(this), amountInShares);
        // burn borrower debt
        debtToken.burn(_borrower, _borrowedAmount);
    }

    /// @dev _liquidate is a function to liquidate a user
    /// @param _account is the address of the account being liquidated
    /// @param _liquidator is the address of the account doing the liquidating who receives the collateral
    function _liquidate(
        address _account,
        address _liquidator,
        uint256 amountOfCollateralToLiquidateInVaultShares
    ) internal {
        uint accountCollateralBalance = wrappedCollateralAsset.balanceOf(_account);
        // incase the value of the collateral drops
        // faster than liquidate
        if (amountOfCollateralToLiquidateInVaultShares > accountCollateralBalance) {
            amountOfCollateralToLiquidateInVaultShares = accountCollateralBalance;
        }
        
        // reset the borrowers collateral tracker
        wrappedCollateralAsset.burn(_account, amountOfCollateralToLiquidateInVaultShares);

        // transfer the collateral tokens to the liquidator
        vault.transfer(
            collateralAsset,
            address(this),
            _liquidator,
            amountOfCollateralToLiquidateInVaultShares
        );

        emit Liquidate(
            address(this),
            address(collateralAsset),
            address(_account),
            amountOfCollateralToLiquidateInVaultShares,
            _liquidator
        );
    }

    /// @notice getBlockNumber allows for easy retrieval of block number
    /// @return block number
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /// @dev scales the input to from _underlyingDecimal to 18 decimal places
    function normalize(uint256 _amount, uint8 _underlyingDecimal) internal pure returns (uint256) {
        if (_underlyingDecimal >= 18) {
            return _amount / 10**(_underlyingDecimal - 18);
        } else {
            return _amount * (10**(18 - _underlyingDecimal));
        }
    }

    /// @dev scales the input to from 18 decinal to underlying decimal places
    function denormalize(uint256 _amount, uint8 _underlyingDecimal)
        internal
        pure
        returns (uint256)
    {
        if (_underlyingDecimal >= 18) {
            return _amount * 10**(_underlyingDecimal - 18);
        } else {
            return _amount / (10**(18 - _underlyingDecimal));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPriceOracleAggregator.sol";
import "./IBSWrapperToken.sol";
import "./IDebtToken.sol";
import "./IBSVault.sol";
import "../DataTypes.sol";

interface IBSLendingPair {
    event Initialized(
        address indexed pair,
        address indexed asset,
        address indexed collateralAsset,
        address pauseGuardian
    );

    /**
     * Emitted on deposit
     *
     * @param pair The pair being interacted with
     * @param asset The asset deposited in the pair
     * @param tokenReceipeint The user the receives the bsTokens
     * @param user The user that made the deposit
     * @param amount The amount deposited
     **/
    event Deposit(
        address indexed pair,
        address indexed asset,
        address indexed tokenReceipeint,
        address user,
        uint256 amount
    );

    event Borrow(address indexed borrower, uint256 amount);

    /**
     * Emitted on Redeem
     *
     * @param pair The pair being interacted with
     * @param asset The asset withdraw in the pair
     * @param user The user that's making the withdrawal
     * @param to The user the receives the withdrawn tokens
     * @param amount The amount being withdrawn
     **/
    event Redeem(
        address indexed pair,
        address indexed asset,
        address indexed user,
        address to,
        uint256 amount,
        uint256 amountofWrappedBurned
    );

    event WithdrawCollateral(address account, uint256 amount);

    event ReserveWithdraw(address user, uint256 shares);

    /**
     * Emitted on repay
     *
     * @param pair The pair being interacted with
     * @param asset The asset repaid in the pair
     * @param beneficiary The user that's getting their debt reduced
     * @param repayer The user that's providing the funds
     * @param amount The amount being repaid
     **/
    event Repay(
        address indexed pair,
        address indexed asset,
        address indexed beneficiary,
        address repayer,
        uint256 amount
    );

    /**
     * Emitted on liquidation
     *
     * @param pair The pair being interacted with
     * @param asset The asset that getting liquidated
     * @param user The user that's getting liquidated
     * @param liquidatedCollateralAmount The of collateral transferred to the liquidator
     * @param liquidator The liquidator
     **/
    event Liquidate(
        address indexed pair,
        address indexed asset,
        address indexed user,
        uint256 liquidatedCollateralAmount,
        address liquidator
    );

    /**
     * @dev Emitted on flashLoan
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    /**
     * @dev Emitted on interest accrued
     * @param accrualBlockNumber block number
     * @param borrowIndex borrow index
     * @param totalBorrows total borrows
     * @param totalReserves total reserves
     **/
    event InterestAccrued(
        address indexed pair,
        uint256 accrualBlockNumber,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves
    );

    event InterestShortCircuit(uint256 blockNumber);

    event ActionPaused(uint8 action, uint256 timestamp);
    event ActionUnPaused(uint8 action, uint256 timestamp);

    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20 _asset,
        IERC20 _collateralAsset,
        DataTypes.BorrowAssetConfig calldata borrowConfig,
        IBSWrapperToken _wrappedCollateralAsset,
        IInterestRateModel _interestRate,
        address _pauseGuardian
    ) external;

    function asset() external view returns (IERC20);

    function depositBorrowAsset(address _tokenReceipeint, uint256 _amount) external;

    function depositCollateral(address _tokenReceipeint, uint256 _vaultShareAmount) external;

    function redeem(address _to, uint256 _amount) external;

    function collateralOfAccount(address _account) external view returns (uint256);

    function getMaxWithdrawAllowed(address account) external returns (uint256);

    function oracle() external view returns (IPriceOracleAggregator);

    function collateralAsset() external view returns (IERC20);

    function calcBorrowLimit(uint256 amount) external view returns (uint256);

    function accountInterestIndex(address) external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function debtToken() external view returns (IDebtToken);

    function borrowBalancePrior(address _account) external view returns (uint256);

    function wrapperBorrowedAsset() external view returns (IBSWrapperToken);

    function wrappedCollateralAsset() external view returns (IBSWrapperToken);

    function totalReserves() external view returns (uint256);

    function withdrawFees(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IBSVault is IERC3156FlashLender {
    // ************** //
    // *** EVENTS *** //
    // ************** //

    /// @notice Emitted on deposit
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being deposited
    /// @param amount being deposited
    /// @param shares the represent the amount deposited in the vault
    event Deposit(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 shares
    );

    /// @notice Emitted on withdraw
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being withdrawn
    /// @param amount Amount of underlying being withdrawn
    /// @param shares the represent the amount withdraw from the vault
    event Withdraw(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 shares,
        uint256 amount
    );

    event Transfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    event FlashLoan(
        address indexed borrower,
        IERC20 indexed token,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );

    event TransferControl(address _newTeam, uint256 timestamp);

    event UpdateFlashLoanRate(uint256 newRate);

    event Approval(address indexed user, address indexed allowed, bool status);

    event OwnershipAccepted(address newOwner, uint256 timestamp);

    // ************** //
    // *** FUNCTIONS *** //
    // ************** //

    function initialize(uint256 _flashLoanRate, address _owner) external;

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(IERC20, address) external view returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewardDistributorManager.sol";

interface IBSWrapperTokenBase is IERC20 {
    function initialize(
        address _owner,
        address _underlying,
        string memory _tokenName,
        string memory _tokenSymbol,
        IRewardDistributorManager _manager
    ) external;

    function burn(address _from, uint256 _amount) external;

    function owner() external view returns (address);
}

interface IBSWrapperToken is IBSWrapperTokenBase {
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import {IBSWrapperTokenBase} from "./IBSWrapperToken.sol";

interface IDebtToken is IBSWrapperTokenBase {
    event DelegateBorrow(address from, address to, uint256 amount, uint256 timestamp);

    function increaseTotalDebt(uint256 _amount) external;

    function principal(address _account) external view returns (uint256);

    function mint(
        address _to,
        address _owner,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    function getPriceInUSD() external returns (uint256);

    function viewPriceInUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(IERC20 token, IOracle oracle);

    function getPriceInUSD(IERC20 _token) external returns (uint256);

    function updateOracleForAsset(IERC20 _asset, IOracle _oracle) external;

    function viewPriceInUSD(IERC20 _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardDistributor {
    event Initialized(
        IERC20 indexed _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian,
        uint256 timestamp
    );

    function accumulateReward(address _tokenAddr, address _user) external;

    function endTimestamp() external returns (uint256);

    function initialize(
        string calldata _name,
        IERC20 _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IRewardDistributor.sol";

interface IRewardDistributorManager {
    /// @dev Emitted on Initialization
    event Initialized(address owner, uint256 timestamp);

    event ApprovedDistributor(IRewardDistributor distributor, uint256 timestamp);
    event AddReward(address tokenAddr, IRewardDistributor distributor, uint256 timestamp);
    event RemoveReward(address tokenAddr, IRewardDistributor distributor, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);
    event OwnershipAccepted(address newOwner, uint256 timestamp);

    function activateReward(address _tokenAddr) external;

    function removeReward(address _tokenAddr, IRewardDistributor _distributor) external;

    function accumulateRewards(address _from, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */

contract Exponential {
    uint256 constant expScale = 1e18;
    // uint constant doubleScale = 1e36;
    // uint constant halfExpScale = expScale/2;
    uint256 constant mantissaOne = expScale;

    struct Exp {
        uint256 mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint256 num, uint256 denom) internal pure returns (Exp memory) {
        uint256 scaledNumerator = num * expScale;
        uint256 rational = scaledNumerator / denom;
        return Exp({mantissa: rational});
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint256 scalar) internal pure returns (Exp memory) {
        uint256 scaledMantissa = a.mantissa * scalar;
        return Exp({mantissa: scaledMantissa});
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
        Exp memory product = mulScalar(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        Exp memory product = mulScalar(a, scalar);
        return truncate(product) + addend;
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint256 scalar) internal pure returns (Exp memory) {
        uint256 descaledMantissa = a.mantissa / scalar;
        return Exp({mantissa: descaledMantissa});
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        uint256 numerator = expScale * scalar;
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor)
        internal
        pure
        returns (uint256)
    {
        Exp memory fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20Details {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

