/**
 *Submitted for verification at snowtrace.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context {
    using SafeERC20 for IERC20;

    struct Collateral {
        bool defined;
        uint256 raised;
    }

    uint256 public constant PRECISION = 10**6;

    // Price of a token
    uint256 private _price;

    // The token being sold
    address private _token;

    // Tokens used as a payment
    mapping(address => Collateral) private _collaterals;

    // Address where funds are collected
    address private _wallet;

    /**
     * Event for token purchase logging.
     * @param purchaser  who paid for the tokens.
     * @param value  collateral tokens paid for purchase.
     * @param amount  amount of tokens purchased.
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed collateral,
        uint256 value,
        uint256 amount
    );

    /**
     * @param price_ price of a token.
     * @param wallet_  address where collected funds will be forwarded to.
     * @param token_  address of the token being sold.
     * @param collaterals_  addresses of the payment tokens.
     */
    constructor(
        uint256 price_,
        address wallet_,
        address token_,
        address[] memory collaterals_
    ) {
        require(price_ > 0, "Crowdsale: price value is 0");
        require(wallet_ != address(0), "Crowdsale: wallet address is zero");
        require(
            address(token_) != address(0),
            "Crowdsale: token address is zero"
        );

        for (uint256 i = 0; i < collaterals_.length; i++) {
            require(
                collaterals_[i] != address(0),
                "Crowdsale: collateral address is zero"
            );
            _collaterals[collaterals_[i]] = Collateral({
                defined: true,
                raised: 0
            });
        }

        _price = price_;
        _wallet = wallet_;
        _token = token_;
    }

    /**
     * @return the token being sold.
     */
    function getToken() public view returns (address) {
        return _token;
    }

    /**
     * @param collateral_  collateral token.
     * @return the token being used as a payment.
     */
    function isCollateral(address collateral_) public view returns (bool) {
        return _collaterals[collateral_].defined;
    }

    /**
     * @return the address where funds are collected.
     */
    function getWallet() public view returns (address) {
        return _wallet;
    }

    /**
     * @return price per token unit.
     */
    function getPrice() public view virtual returns (uint256) {
        return _price;
    }

    /**
     * @return the amount of collateral tokens raised.
     */
    function collateralRaised(address collateral_)
        external
        view
        returns (uint256)
    {
        return _collaterals[collateral_].raised;
    }

    /**
     * @dev Low level token purchase ***DO NOT OVERRIDE***
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     */
    function buyTokens(address collateral_, uint256 amount_) external {
        _preValidatePurchase(_msgSender(), collateral_, amount_);

        // transfer collateral tokens
        IERC20(collateral_).safeTransferFrom(
            _msgSender(),
            address(this),
            amount_
        );

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(collateral_, amount_);

        // update collaterals state
        _collaterals[collateral_].raised =
            _collaterals[collateral_].raised +
            amount_;

        _processPurchase(_msgSender(), tokens);
        emit TokensPurchased(_msgSender(), collateral_, amount_, tokens);

        _updatePurchasingState(_msgSender(), collateral_, amount_);

        _forwardFunds(collateral_, amount_);
        _postValidatePurchase(_msgSender(), collateral_, amount_);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, collateralAmount);
     *     require(collateralRaised().add(collateralAmount) <= cap);
     * @param beneficiary_  address performing the token purchase.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     */
    function _preValidatePurchase(
        address beneficiary_,
        address collateral_,
        uint256 amount_
    ) internal view virtual {
        require(
            _collaterals[collateral_].defined,
            "Crowdsale::_preValidatePurchase: collateral token not defined"
        );
        require(
            beneficiary_ != address(0),
            "Crowdsale::_preValidatePurchase: beneficiary address is zero"
        );
        require(
            amount_ != 0,
            "Crowdsale::_preValidatePurchase: collateralAmount is 0"
        );

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary_  address performing the token purchase.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     */
    function _postValidatePurchase(
        address beneficiary_,
        address collateral_,
        uint256 amount_
    ) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary_  address performing the token purchase.
     * @param tokenAmount_  number of tokens to be emitted.
     */
    function _deliverTokens(address beneficiary_, uint256 tokenAmount_)
        internal
        virtual
    {
        IERC20(_token).safeTransfer(beneficiary_, tokenAmount_);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary_  address receiving the tokens
     * @param tokenAmount_  number of tokens to be purchased
     */
    function _processPurchase(address beneficiary_, uint256 tokenAmount_)
        internal
        virtual
    {
        _deliverTokens(beneficiary_, tokenAmount_);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions etc.)
     * @param beneficiary_  address receiving the tokens.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     */
    function _updatePurchasingState(
        address beneficiary_,
        address collateral_,
        uint256 amount_
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     * @return number of tokens that can be purchased with the specified collateralAmount.
     */
    function _getTokenAmount(address collateral_, uint256 amount_)
        internal
        view
        virtual
        returns (uint256)
    {
        uint8 tokenDecimals = IERC20Metadata(address(_token)).decimals();
        uint8 collateralDecimals = IERC20Metadata(collateral_).decimals();
        if (tokenDecimals >= collateralDecimals) {
            return
                (amount_ *
                    PRECISION *
                    (10**(tokenDecimals - collateralDecimals))) / getPrice();
        }
        return
            (amount_ * PRECISION) /
            (10**(collateralDecimals - tokenDecimals)) /
            getPrice();
    }

    /**
     * @dev Determines how collateral tokens are stored/forwarded on purchases.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens to be stored/forwarded on purchases.
     */
    function _forwardFunds(address collateral_, uint256 amount_)
        internal
        virtual
    {
        IERC20(collateral_).safeTransfer(_wallet, amount_);
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role_, address account_) internal {
        require(!has(role_, account_), "Roles::add: account already has role");
        role_.bearer[account_] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role_, address account_) internal {
        require(
            has(role_, account_),
            "Roles::remove: account does not have role"
        );
        role_.bearer[account_] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role_, address account_)
        internal
        view
        returns (bool)
    {
        require(account_ != address(0), "Roles::has: account address is zero");
        return role_.bearer[account_];
    }
}

/**
 * @title AdminRole
 * @dev Admins are responsible for assigning and removing whitelisted/capped accounts.
 */
contract AdminRole is Context {
    using Roles for Roles.Role;

    Roles.Role private _admins;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    constructor() {
        _addAdmin(_msgSender());
    }

    modifier onlyAdmin() {
        require(
            isAdmin(_msgSender()),
            "AdminRole: caller does not have the admin role"
        );
        _;
    }

    /**
     * @dev Checks if an account is admin.
     * @param account_  account to check.
     */
    function isAdmin(address account_) public view returns (bool) {
        return _admins.has(account_);
    }

    /**
     * @dev Grants admin role to account.
     * @param account_  account to add role to.
     */
    function addAdmin(address account_) external onlyAdmin {
        _addAdmin(account_);
    }

    /**
     * @dev Renounces admin role.
     */
    function renounceAdmin() external {
        _removeAdmin(_msgSender());
    }

    function _addAdmin(address account_) internal {
        _admins.add(account_);
        emit AdminAdded(account_);
    }

    function _removeAdmin(address account_) internal {
        _admins.remove(account_);
        emit AdminRemoved(account_);
    }
}

/**
 * @title KycRole
 * @dev Kyc accounts have been approved by the admin to perform certain actions (e.g. participate in a crowdsale).
 * This role is special in that the only accounts that can add it are admins (who can also remove it).
 */
contract KycRole is Context, AdminRole {
    using Roles for Roles.Role;

    enum KycLevel {
        low,
        medium,
        high
    }
    mapping(address => KycLevel) private _kycAccounts;

    event KycLevelSet(address indexed account, KycLevel levels);

    /**
     * @dev Returns account's KYC level.
     * @param account_  account to check.
     */
    function kycLevelOf(address account_) public view returns (KycLevel) {
        return _kycAccounts[account_];
    }

    /**
     * @dev Sets account's KYC level.
     * @param account_  account to set level for.
     * @param level_  KYC level.
     */
    function setKyc(address account_, KycLevel level_) public onlyAdmin {
        _kycAccounts[account_] = level_;

        emit KycLevelSet(account_, level_);
    }

    /**
     * @dev Sets KYC levels to accounts in batches.
     * @param accounts_  accounts array to set level for.
     * @param levels_  KYC levels.
     */
    function setKycBatches(
        address[] calldata accounts_,
        KycLevel[] calldata levels_
    ) external onlyAdmin {
        require(
            accounts_.length == levels_.length,
            "KycRole::setKycBatches: mismatch in accounts and levels length"
        );

        uint256 length = accounts_.length;
        for (uint256 index = 0; index < length; index++) {
            _kycAccounts[accounts_[index]] = levels_[index];

            emit KycLevelSet(accounts_[index], levels_[index]);
        }
    }
}

/**
 * @title CappedCrowdsale
 * @dev Crowdsale where users can contribute within cap validation.
 */
abstract contract CappedCrowdsale is Crowdsale, KycRole {
    uint256 private _minInvestment;
    mapping(KycLevel => uint256) private _cap;
    mapping(address => uint256) internal _investments;

    event MinInvestmentSet(uint256 minInvestment);
    event CapSet(KycLevel indexed level, uint256 cap);

    /**
     * @dev Returns min investment amount.
     */
    function getMinInvestment() public view returns (uint256) {
        return _minInvestment;
    }

    /**
     * @dev Sets min investment amount.
     * @param minInvestment_  min investment amount.
     */
    function setMinInvestment(uint256 minInvestment_) external onlyAdmin {
        _minInvestment = minInvestment_;

        emit MinInvestmentSet(_minInvestment);
    }

    /**
     * @dev Returns cap according to KYC level.
     * @param beneficiary_  address performing the token purchase.
     */
    function capOf(address beneficiary_) public view returns (uint256) {
        uint256 investments = _investments[beneficiary_];
        if (investments > _cap[kycLevelOf(beneficiary_)]) {
            return 0;
        }
        return _cap[kycLevelOf(beneficiary_)] - investments;
    }

    /**
     * @dev Returns KYC level cap.
     * @param level_  KYC level.
     */
    function getCap(KycLevel level_) public view returns (uint256) {
        return _cap[level_];
    }

    /**
     * @dev Sets cap per KYC level.
     * @param level_  KYC level.
     * @param cap_  new cap value.
     */
    function setCap(KycLevel level_, uint256 cap_) external onlyAdmin {
        if (level_ == KycLevel.low) {
            require(
                _cap[KycLevel.medium] >= cap_,
                "CappedCrowdsale::setCap: cap higher than medium cap"
            );
        }
        if (level_ == KycLevel.medium) {
            require(
                _cap[KycLevel.high] >= cap_,
                "CappedCrowdsale::setCap: cap higher than high cap"
            );
        }
        _cap[level_] = cap_;

        emit CapSet(level_, cap_);
    }

    /**
     * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
     * restriction is imposed on the account sending the transaction.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     */
    function _preValidatePurchase(
        address beneficiary_,
        address collateral_,
        uint256 amount_
    ) internal view virtual override {
        uint256 decimals = IERC20Metadata(collateral_).decimals();
        uint256 normalizedAmount = (amount_ * PRECISION) / (10**decimals);

        require(
            _minInvestment <= normalizedAmount,
            "CappedCrowdsale::_preValidatePurchase: investment amount too low"
        );
        require(
            capOf(beneficiary_) >= normalizedAmount,
            "CappedCrowdsale::_preValidatePurchase: exceeded cap"
        );

        super._preValidatePurchase(beneficiary_, collateral_, amount_);
    }

    /**
     * @dev Updating investment balance to check for limits.
     * @param beneficiary_  address receiving the tokens.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     */
    function _updatePurchasingState(
        address beneficiary_,
        address collateral_,
        uint256 amount_
    ) internal virtual override {
        uint256 decimals = IERC20Metadata(collateral_).decimals();
        uint256 normalizedAmount = (amount_ * PRECISION) / (10**decimals);
        _investments[beneficiary_] =
            _investments[beneficiary_] +
            normalizedAmount;

        super._updatePurchasingState(beneficiary_, collateral_, amount_);
    }
}

/**
 * @dev Interface of the DefiYieldTokenVesting
 */
interface IDefiYieldTokenVesting {
    function addBeneficiary(
        uint8 pid_,
        address beneficiary_,
        uint256 lockedAmount_
    ) external;

    function addBeneficiaryBatches(
        uint8 pid_,
        address[] calldata beneficiaries_,
        uint256[] calldata lockedAmounts_
    ) external;
}

contract DefiYieldCrowdsale is CappedCrowdsale {
    using SafeERC20 for IERC20;

    enum State {
        None,
        Open,
        Closed
    }

    struct Round {
        bool defined;
        State state;
        uint256 price;
        uint256 investment;
        uint256 totalSupply;
        uint8 pool;
    }

    State private _state;
    Round[] private _rounds;
    uint256 private _activeRound;
    uint256 private _tokensSold;
    uint256 private _tokensWithdrawn;
    uint256 private _directWithdrawPercentage;

    IDefiYieldTokenVesting private _vesting;
    mapping(address => mapping(uint256 => uint256)) private _balances;

    event SaleStateUpdated(State state);
    event RoundOpened(uint256 indexed index);
    event RoundClosed(uint256 indexed index);
    event RoundAdded(uint256 price, uint256 totalSupply);
    event RoundUpdated(
        uint256 indexed index,
        uint256 price,
        uint256 totalSupply
    );

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen() {
        require(isOpen(), "DefiYieldCrowdsale: not open");
        _;
    }

    constructor(
        address wallet_,
        address token_,
        address[] memory collaterals_,
        IDefiYieldTokenVesting vesting_
    ) Crowdsale(1, wallet_, token_, collaterals_) {
        _vesting = vesting_;
        IERC20(token_).safeApprove(address(_vesting), 2**256 - 1);
    }

    /**
     * @dev Returns vesting contract address.
     */
    function getVestingAddress()
        external
        view
        returns (IDefiYieldTokenVesting)
    {
        return _vesting;
    }

    /**
     * @dev Returns total tokens sold.
     */
    function getTokensSold() external view returns (uint256) {
        return _tokensSold;
    }

    /**
     * @dev Returns total tokens withdrawn.
     */
    function getTokensWithdrawn() external view returns (uint256) {
        return _tokensWithdrawn;
    }

    /**
     * @dev Returns active round.
     */
    function getActiveRound() external view returns (uint256) {
        return _activeRound;
    }

    /**
     * @dev Returns round by index.
     * @param index_  round index.
     */
    function getRound(uint256 index_) external view returns (Round memory) {
        return _rounds[index_];
    }

    /**
     * @dev Returns vesting pool.
     */
    function getVestingPool(uint256 index_) external view returns (uint8) {
        return _rounds[index_].pool;
    }

    /**
     * @dev Returns sale token balance.
     */
    function tokenBalance() public view returns (uint256) {
        return IERC20(getToken()).balanceOf(address(this));
    }

    /**
     * @dev Returns direct withdraw percentage.
     */
    function directWithdrawPercentage() external view returns (uint256) {
        return _directWithdrawPercentage;
    }

    /**
     * @dev Sets direct withdraw percentage.
     * @param percentage_  percentage of tokens available to withdraw after sale is closed.
     */
    function setDirectWithdrawPercentage(uint256 percentage_)
        external
        onlyAdmin
    {
        require(
            !isClosed(),
            "DefiYieldCrowdsale::setDirectWithdrawPercentage: sales is already closed"
        );
        require(
            percentage_ >= 0 && percentage_ <= 100,
            "DefiYieldCrowdsale::setDirectWithdrawPercentage: withdraw percentage should be >= 0 and <= 100"
        );

        _directWithdrawPercentage = percentage_;
    }

    /**
     * @return True if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return _state == State.Open;
    }

    /**
     * @dev True if the crowdsale is closed, false otherwise.
     */
    function isClosed() public view returns (bool) {
        return _state == State.Closed;
    }

    /**
     * @dev Opens the sale.
     */
    function openSale() external onlyAdmin {
        require(
            _state == State.None,
            "DefiYieldCrowdsale::openSale: sales is already open or closed"
        );
        _state = State.Open;

        emit SaleStateUpdated(_state);
    }

    /**
     * @dev Closes the sale.
     */
    function closeSale() external onlyAdmin {
        require(
            isOpen(),
            "DefiYieldCrowdsale::closeSale: sales is already closed or not open"
        );
        _state = State.Closed;

        emit SaleStateUpdated(_state);
    }

    /**
     * @dev Adds new round.
     * @param price_  price per token unit.
     * @param totalSupply_  max amount of tokens available in round.
     * @param pool_  vesting pool.
     */
    function addRound(
        uint256 price_,
        uint256 totalSupply_,
        uint8 pool_
    ) external onlyAdmin {
        require(
            !isClosed(),
            "DefiYieldCrowdsale::addRound: sales is already closed"
        );

        _rounds.push(
            Round({
                defined: true,
                state: State.None,
                price: price_,
                investment: 0,
                totalSupply: totalSupply_,
                pool: pool_
            })
        );
        emit RoundAdded(price_, totalSupply_);
    }

    /**
     * @dev Updates round parameters.
     * @param index_  round index.
     * @param price_  price per token unit.
     * @param totalSupply_  max amount of tokens available in round.
     * @param pool_  vesting pool.
     */
    function updateRound(
        uint256 index_,
        uint256 price_,
        uint256 totalSupply_,
        uint8 pool_
    ) external onlyAdmin {
        require(
            _rounds[index_].defined,
            "DefiYieldCrowdsale::updateRound: no round with provided index"
        );
        require(
            _rounds[index_].state != State.Closed,
            "DefiYieldCrowdsale::updateRound: round is already closed"
        );
        require(
            !isClosed(),
            "DefiYieldCrowdsale::updateRound: sales is already closed"
        );

        _rounds[index_].price = price_;
        _rounds[index_].totalSupply = totalSupply_;
        _rounds[index_].pool = pool_;

        emit RoundUpdated(index_, price_, totalSupply_);
    }

    /**
     * @dev Opens round for investment.
     * @param index_  round index.
     */
    function openRound(uint256 index_) external onlyAdmin {
        require(
            isOpen(),
            "DefiYieldCrowdsale::openRound: sales is not open yet"
        );
        require(
            _rounds[index_].defined,
            "DefiYieldCrowdsale::openRound: no round with provided index"
        );
        require(
            _rounds[index_].state == State.None,
            "DefiYieldCrowdsale::openRound: round is already open or closed"
        );

        if (_rounds[_activeRound].state == State.Open) {
            _rounds[_activeRound].state = State.Closed;
        }
        _rounds[index_].state = State.Open;
        _activeRound = index_;

        emit RoundOpened(index_);
    }

    /**
     * @dev Closes round for investment.
     * @param index_  round index.
     */
    function closeRound(uint256 index_) external onlyAdmin {
        require(
            isOpen(),
            "DefiYieldCrowdsale::closeRound: sales is not open yet"
        );
        require(
            _rounds[index_].defined,
            "DefiYieldCrowdsale::closeRound: no round with provided index"
        );
        require(
            _rounds[index_].state == State.Open,
            "DefiYieldCrowdsale::closeRound: round is not open"
        );

        _rounds[index_].state = State.Closed;

        emit RoundClosed(index_);
    }

    /**
     * @return the price value and decimals.
     */
    function getPrice() public view virtual override returns (uint256) {
        if (_rounds[_activeRound].state == State.Open) {
            return _rounds[_activeRound].price;
        }
        return 0;
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     */
    function withdrawTokens() external {
        require(
            isClosed(),
            "DefiYieldCrowdsale::withdrawTokens: sales is not closed yet"
        );
        uint256 roundsLength = _rounds.length;
        for (uint256 i; i < roundsLength; i++) {
            uint256 amount = _balances[_msgSender()][i];

            if (amount == 0) {
                continue;
            }

            _balances[_msgSender()][i] = 0;
            _tokensWithdrawn = _tokensWithdrawn + amount;
            uint256 directWithdrawAmount = (amount *
                _directWithdrawPercentage) / 100;
            uint256 vestingAmount = amount - directWithdrawAmount;

            if (directWithdrawAmount > 0) {
                IERC20(getToken()).safeTransfer(
                    _msgSender(),
                    directWithdrawAmount
                );
            }

            if (vestingAmount > 0) {
                _vesting.addBeneficiary(
                    _rounds[i].pool,
                    _msgSender(),
                    vestingAmount
                );
            }
        }
    }

    /**
     * @return the balance of a beneficiary.
     * @param round_  round of sale.
     * @param beneficiary_  address performing the token purchase.
     */
    function balanceOf(uint256 round_, address beneficiary_)
        public
        view
        returns (uint256)
    {
        return _balances[beneficiary_][round_];
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary_  token purchaser.
     * @param collateral_  collateral token.
     * @param amount_  amount of collateral tokens involved in the purchase.
     */
    function _preValidatePurchase(
        address beneficiary_,
        address collateral_,
        uint256 amount_
    ) internal view override onlyWhileOpen {
        require(
            _state == State.Open,
            "DefiYieldCrowdsale::_preValidatePurchase: sales is not open yet"
        );
        require(
            _rounds[_activeRound].state == State.Open,
            "DefiYieldCrowdsale::_preValidatePurchase: sales round is not open yet"
        );
        require(
            _rounds[_activeRound].totalSupply >=
                _rounds[_activeRound].investment +
                    _getTokenAmount(collateral_, amount_),
            "DefiYieldCrowdsale::_preValidatePurchase: exceeded round total supply"
        );

        super._preValidatePurchase(beneficiary_, collateral_, amount_);
    }

    /**
     * @dev Overrides parent by updating round investment.
     * @param beneficiary_  token purchaser.
     * @param tokenAmount_  amount of tokens purchased.
     */
    function _processPurchase(address beneficiary_, uint256 tokenAmount_)
        internal
        virtual
        override
    {
        require(
            tokenBalance() >= (_tokensSold + tokenAmount_) - _tokensWithdrawn,
            "DefiYieldCrowdsale::_processPurchase: not enough tokens to buy"
        );

        _rounds[_activeRound].investment =
            _rounds[_activeRound].investment +
            tokenAmount_;
        _balances[beneficiary_][_activeRound] =
            _balances[beneficiary_][_activeRound] +
            tokenAmount_;
        _tokensSold = _tokensSold + tokenAmount_;

        super._processPurchase(beneficiary_, tokenAmount_);
    }

    /**
     * @dev Source of tokens. Overridden so tokens are not transferred.
     * @param beneficiary_  address performing the token purchase.
     * @param tokenAmount_  number of tokens to be emitted.
     */
    function _deliverTokens(address beneficiary_, uint256 tokenAmount_)
        internal
        virtual
        override
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Allows to recover ERC20 from contract.
     * @param token_  ERC20 token address.
     * @param amount_  ERC20 token amount.
     */
    function recoverERC20(address token_, uint256 amount_) external onlyAdmin {
        if (address(getToken()) == token_) {
            // We don't allow to withdraw tokens already sold to investors
            uint256 tokensLocked = _tokensSold - _tokensWithdrawn;
            uint256 tokensAfterAdminWithdrawal = tokenBalance() - amount_;
            require(
                tokensAfterAdminWithdrawal >= tokensLocked,
                "DefiYieldCrowdsale::recoverERC20: cannot withdraw already sold tokens"
            );
        }

        IERC20(token_).safeTransfer(getWallet(), amount_);
    }
}