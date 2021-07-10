/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.4;

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
    constructor () {
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


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.4;

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
    constructor () {
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


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.4;

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

    constructor () {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.4;

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.4;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity ^0.8.4;


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


// File contracts/pawn/PawnContract.sol

pragma solidity ^0.8.4;
contract PawnContract is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    mapping (address => uint256) public whitelistCollateral;
    address public operator; 
    address public feeWallet = address(this);
    uint256 public penaltyRate;
    uint256 public systemFeeRate; 
    uint256 public lateThreshold;
    uint256 public prepaidFeeRate;
    uint256 public ZOOM;  
    bool public initialized = false;
    address public admin;
    enum LoanDurationType {WEEK, MONTH}

    /**
     * @dev initialize function
     * @param _zoom is coefficient used to represent risk params
     */

    function initialize(uint256 _zoom
    ) external notInitialized {
        ZOOM = _zoom;
        initialized = true;
        admin = address(msg.sender);
    }

    function setOperator(address _newOperator) onlyAdmin external {
        operator = _newOperator;
    }

    function setFeeWallet(address _newFeeWallet) onlyAdmin external {
        feeWallet = _newFeeWallet;
    }

    function pause() onlyAdmin external {
        _pause();
    }

    function unPause() onlyAdmin external {
        _unpause();
    }

    /**
    * @dev set fee for each token
    * @param _feeRate is percentage of tokens to pay for the transaction
    */

    function setSystemFeeRate(uint256 _feeRate) external onlyAdmin {
        systemFeeRate = _feeRate;
    }

    /**
    * @dev set fee for each token
    * @param _feeRate is percentage of tokens to pay for the penalty
    */
    function setPenaltyRate(uint256 _feeRate) external onlyAdmin {
        penaltyRate = _feeRate;
    }

    /**
    * @dev set fee for each token
    * @param _threshold is number of time allowed for late repayment
    */
    function setLateThreshold(uint256 _threshold) external onlyAdmin {
        lateThreshold = _threshold;
    }

    function setPrepaidFeeRate(uint256 _feeRate) external onlyAdmin {
        prepaidFeeRate = _feeRate;
    }

    function setWhitelistCollateral(address _token, uint256 _status) external onlyAdmin {
        whitelistCollateral[_token] = _status;
    }

    modifier notInitialized() {
        require(!initialized, "initialized");
        _;
    }

    modifier isInitialized() {
        require(initialized, "not-initialized");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "caller is not the operator");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "caller is not the admin");
        _;
    }

    function emergencyWithdraw(address _token)
    external onlyAdmin
    whenPaused {
        if (_token == address (0)) {
            payable(address(this)).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(admin, IERC20(_token).balanceOf(address(this)));
        }
    }

    /** ========================= COLLATERAL FUNCTIONS & STATES ============================= */
    uint256 public numberCollaterals;
    mapping (uint256 => Collateral) public collaterals;
    enum CollateralStatus {OPEN, DOING, COMPLETED, CANCEL}
    struct Collateral {
        address owner;
        uint256 amount;
        address collateralAddress;
        address loanAsset;
        uint256 expectedDurationQty;
        LoanDurationType expectedDurationType;
        CollateralStatus status;
    }

    event CreateCollateralEvent(
        uint256 collateralId,
        Collateral data
    );

    event WithdrawCollateralEvent(
        uint256 collateralId,
        address collateralOwner
    );

    /**
    * @dev create Collateral function, collateral will be stored in this contract
    * @param _collateralAddress is address of collateral
    * @param _packageId is id of pawn shop package
    * @param _amount is amount of token
    * @param _loanAsset is address of loan token
    * @param _expectedDurationQty is expected duration
    * @param _expectedDurationType is expected duration type
    */
    function createCollateral(
        address _collateralAddress,
        int256 _packageId,
        uint256 _amount,
        address _loanAsset,
        uint256 _expectedDurationQty,
        LoanDurationType _expectedDurationType
    ) external whenNotPaused payable
    returns (uint256 _idx)
    {
        //check whitelist collateral token
        require(whitelistCollateral[_collateralAddress] == 1, 'not-support-collateral');
        //validate: cannot use BNB as loanAsset
        require(_loanAsset != address(0), 'not-use-bnb-as-loan-asset');
        if (_collateralAddress == address(0)) {
            require(_amount == msg.value, 'amount-not-equal-bnb-value');
        }

        //id of collateral
        _idx = numberCollaterals;

        //create new collateral
        Collateral storage newCollateral = collaterals[_idx];
        newCollateral.owner = msg.sender;
        newCollateral.amount = _amount;
        newCollateral.collateralAddress = _collateralAddress;
        newCollateral.loanAsset = _loanAsset;
        newCollateral.status = CollateralStatus.OPEN;
        newCollateral.expectedDurationQty = _expectedDurationQty;
        newCollateral.expectedDurationType = _expectedDurationType;

        ++numberCollaterals;

        emit CreateCollateralEvent(_idx, newCollateral);

        if (_packageId >= 0) {
            //Package must active
            PawnShopPackage storage pawnShopPackage = pawnShopPackages[uint256(_packageId)];
            require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, 'package-not-support');

            _submitCollateralToPackage(_idx, uint256(_packageId));
            emit SubmitPawnShopPackage(uint256(_packageId), _idx, LoanRequestStatus.PENDING);
        }

        // transfer to this contract
        safeTransfer(_collateralAddress, msg.sender, address(this), _amount);
    }

    /**
    * @dev cancel collateral function and return back collateral
    * @param  _collateralId is id of collateral
    */
    function withdrawCollateral(uint256 _collateralId) external {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.owner == msg.sender, 'not-owner-of-this-collateral');
        require(collateral.status == CollateralStatus.OPEN, 'collateral-not-open');

        safeTransfer(collateral.collateralAddress, address(this), collateral.owner, collateral.amount);

        // Remove relation of collateral and offers
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        if (collateralOfferList.isInit == true) {
            for (uint i = 0; i < collateralOfferList.offerIdList.length; i ++) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer storage offer = collateralOfferList.offerMapping[offerId];
                emit CancelOfferEvent(offerId, _collateralId, offer.owner);
            }
            delete collateralOffersMapping[_collateralId];
        }

        delete collaterals[_collateralId];
        emit WithdrawCollateralEvent(_collateralId, msg.sender);
    }

    /** ========================= OFFER FUNCTIONS & STATES ============================= */
    uint256 public numberOffers;
    enum OfferStatus {PENDING, ACCEPTED, COMPLETED, CANCEL}
    struct CollateralOfferList {
        mapping (uint256 => Offer) offerMapping;
        uint256[] offerIdList;
        bool isInit;
    }
    mapping (uint256 => CollateralOfferList) public collateralOffersMapping;
    struct Offer {
        address owner;
        address repaymentAsset;
        uint256 loanAmount;
        uint256 interest;
        uint256 duration;
        OfferStatus status;
        LoanDurationType loanDurationType;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
        bool isInit;
    }

    event CreateOfferEvent(
        uint256 offerId,
        uint256 collateralId,
        Offer data
    );

    event CancelOfferEvent(
        uint256 offerId,
        uint256 collateralId,
        address offerOwner
    );

    /**
    * @dev create Collateral function, collateral will be stored in this contract
    * @param _collateralId is id of collateral
    * @param _repaymentAsset is address of repayment token
    * @param _duration is duration of this offer
    * @param _loanDurationType is type for calculating loan duration
    * @param _repaymentCycleType is type for calculating repayment cycle
    * @param _liquidityThreshold is ratio of assets to be liquidated
    */
    function createOffer(
        uint256 _collateralId,
        address _repaymentAsset,
        uint256 _loanAmount,
        uint256 _duration,
        uint256 _interest,
        uint256 _loanDurationType,
        uint256 _repaymentCycleType,
        uint256 _liquidityThreshold
    )
    external whenNotPaused
    returns (uint256 _idx)
    {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.OPEN, 'collateral-not-open');
        // validate not allow for collateral owner to create offer
        require(collateral.owner != msg.sender, 'collateral-owner-match-sender');
        // Validate ower already approve for this contract to withdraw
        require(IERC20(collateral.loanAsset).allowance(msg.sender, address(this)) >= _loanAmount, 'offer-owner-not-yet-approve-for-withdraw');

        // Get offers of collateral
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        if (!collateralOfferList.isInit) {
            collateralOfferList.isInit = true;
        }
        // Create offer id       
        _idx = numberOffers;

        // Create offer data
        Offer storage _offer = collateralOfferList.offerMapping[_idx];

        _offer.isInit = true;
        _offer.owner = msg.sender;
        _offer.loanAmount = _loanAmount;
        _offer.interest = _interest;
        _offer.duration = _duration;
        _offer.loanDurationType = LoanDurationType(_loanDurationType);
        _offer.repaymentAsset = _repaymentAsset;
        _offer.repaymentCycleType = LoanDurationType(_repaymentCycleType);
        _offer.liquidityThreshold = _liquidityThreshold;
        _offer.status = OfferStatus.PENDING;

        collateralOfferList.offerIdList.push(_idx);

        ++numberOffers;

        emit CreateOfferEvent(_idx, _collateralId, _offer);
    }

    /**
    * @dev cancel offer function, used for cancel offer
    * @param  _offerId is id of offer
    * @param _collateralId is id of collateral associated with offer
    */
    function cancelOffer(uint256 _offerId, uint256 _collateralId) 
    external {
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        require(collateralOfferList.isInit == true, 'collateral-not-have-any-offer');
        Offer storage offer = collateralOfferList.offerMapping[_offerId];
        require(offer.isInit == true, 'offer-not-sent-to-collateral');
        require(offer.owner == msg.sender, 'not-owner-of-offer');
        require(offer.status == OfferStatus.PENDING, 'offer-executed');
        delete collateralOfferList.offerMapping[_offerId];
        for (uint i = 0; i < collateralOfferList.offerIdList.length; i ++) {
            if (collateralOfferList.offerIdList[i] == _offerId) {
                collateralOfferList.offerIdList[i] = collateralOfferList.offerIdList[collateralOfferList.offerIdList.length - 1];
                break;
            }
        }

        delete collateralOfferList.offerIdList[collateralOfferList.offerIdList.length - 1];
        emit CancelOfferEvent(_offerId, _collateralId, msg.sender);
    }

    /** ========================= PAWNSHOP PACKAGE FUNCTIONS & STATES ============================= */
    uint256 public numberPawnShopPackages;
    mapping (uint256 => PawnShopPackage) public pawnShopPackages;

    enum PawnShopPackageStatus {ACTIVE, INACTIVE}
    enum PawnShopPackageType {AUTO, SEMI_AUTO}
    struct Range {
        uint256 lowerBound;
        uint256 upperBound;
    }

    struct PawnShopPackage {
        address owner;
        PawnShopPackageStatus status;
        PawnShopPackageType packageType;
        address loanToken;
        Range loanAmountRange;
        address[] collateralAcceptance;
        uint256 interest;
        uint256 durationType;
        Range durationRange;
        address repaymentAsset;
        LoanDurationType repaymentCycleType;
        uint256 loanToValue;
        uint256 loanToValueLiquidationThreshold;
    }

    event CreatePawnShopPackage(
        uint256 packageId,
        PawnShopPackage data
    );

    event ChangeStatusPawnShopPackage(
        uint256 packageId,
        PawnShopPackageStatus status         
    );

    function createPawnShopPackage(
        PawnShopPackageType _packageType,
        address _loanToken,
        Range calldata _loanAmountRange,
        address[] calldata _collateralAcceptance,
        uint256 _interest,
        uint256 _durationType,
        Range calldata _durationRange,
        address _repaymentAsset,
        LoanDurationType _repaymentCycleType,
        uint256 _loanToValue,
        uint256 _loanToValueLiquidationThreshold
    ) external whenNotPaused
    returns (uint256 _idx)
    {
        _idx = numberPawnShopPackages;

        // Validataion logic: whitelist collateral, ranges must have upper greater than lower, duration type
        for (uint256 i = 0; i < _collateralAcceptance.length; i++) {
            require(whitelistCollateral[_collateralAcceptance[i]] == 1, 'not-support-collateral');
        }

        require(_loanAmountRange.lowerBound < _loanAmountRange.upperBound, 'loan-range-invalid');
        require(_durationRange.lowerBound < _durationRange.upperBound, 'duration-range-invalid');
        require(_durationType == uint256(LoanDurationType.MONTH) || _durationType == uint256(LoanDurationType.WEEK), 'duration-type-invalid');
        
        require(_loanToken != address(0), 'not-use-bnb-as-loan-token');

        //create new collateral
        PawnShopPackage storage newPackage = pawnShopPackages[_idx];
        newPackage.owner = msg.sender;
        newPackage.status = PawnShopPackageStatus.ACTIVE;
        newPackage.packageType = _packageType;
        newPackage.loanToken = _loanToken;
        newPackage.loanAmountRange = _loanAmountRange;
        newPackage.collateralAcceptance = _collateralAcceptance;
        newPackage.interest = _interest;
        newPackage.durationType = _durationType;
        newPackage.durationRange = _durationRange;
        newPackage.repaymentAsset = _repaymentAsset;
        newPackage.repaymentCycleType = _repaymentCycleType;
        newPackage.loanToValue = _loanToValue;
        newPackage.loanToValueLiquidationThreshold = _loanToValueLiquidationThreshold;

        ++numberPawnShopPackages;
        emit CreatePawnShopPackage(
            _idx, 
            newPackage
        );
    }

    function activePawnShopPackage(uint256 _packageId)
    external whenNotPaused
    {
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.owner == msg.sender, 'not-owner-of-this-package');
        require(pawnShopPackage.status == PawnShopPackageStatus.INACTIVE, 'package-not-inactive');

        pawnShopPackage.status = PawnShopPackageStatus.ACTIVE;
        emit ChangeStatusPawnShopPackage(_packageId, PawnShopPackageStatus.ACTIVE);
    }

    function deactivePawnShopPackage(uint256 _packageId)
    external whenNotPaused
    {
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.owner == msg.sender, 'not-owner-of-this-package');
        require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, 'package-not-active');

        pawnShopPackage.status = PawnShopPackageStatus.INACTIVE;
        emit ChangeStatusPawnShopPackage(_packageId, PawnShopPackageStatus.INACTIVE);
    }

    /** ========================= SUBMIT & ACCEPT WORKFLOW OF PAWNSHOP PACKAGE FUNCTIONS & STATES ============================= */
    enum LoanRequestStatus {PENDING, ACCEPTED, REJECTED, CONTRACTED, CANCEL}
    struct LoanRequestStatusStruct {
        bool isInit;
        LoanRequestStatus status;
    }
    struct CollateralAsLoanRequestListStruct {
        mapping (uint256 => LoanRequestStatusStruct) loanRequestToPawnShopPackageMapping; // Mapping from package to status
        uint256[] pawnShopPackageIdList;
        bool isInit;
    }
    mapping (uint256 => CollateralAsLoanRequestListStruct) public collateralAsLoanRequestMapping; // Map from collateral to loan request
    event SubmitPawnShopPackage(
        uint256 packageId,
        uint256 collateralId,
        LoanRequestStatus status
    );

    /**
    * @dev Submit Collateral to Package function, collateral will be submit to pawnshop package
    * @param _collateralId is id of collateral
    * @param _packageId is id of pawn shop package
    */
    function submitCollateralToPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external whenNotPaused
    {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.owner == msg.sender, 'not-owner-of-collateral');
        require(collateral.status == CollateralStatus.OPEN, 'collateral-not-open');
        
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, 'package-not-open');

        // VALIDATE HAVEN'T SUBMIT TO PACKAGE YET
        CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        if (loanRequestListStruct.isInit == true) {
            LoanRequestStatusStruct storage statusStruct = loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];
            require(statusStruct.isInit == false, 'already-submit-to-package');
        }

        // Save
        _submitCollateralToPackage(_collateralId, _packageId);
        emit SubmitPawnShopPackage(_packageId, _collateralId, LoanRequestStatus.PENDING);
        
    }

    function _submitCollateralToPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) internal {
        CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        if (!loanRequestListStruct.isInit) {
            loanRequestListStruct.isInit = true;
        }

        LoanRequestStatusStruct storage statusStruct = loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == false, 'internal-exception:_submitCollateralToPackage - statusStruct.isInit');
        statusStruct.isInit = true;
        statusStruct.status = LoanRequestStatus.PENDING;
        loanRequestListStruct.pawnShopPackageIdList.push(_packageId);
    }

    function withdrawCollateralFromPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external {
        // Collateral must OPEN
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.OPEN, 'collateral-not-open');
        // Sender is collateral owner
        require(collateral.owner == msg.sender, 'sender-not-owner');
        // collateral-package status must pending
        CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        LoanRequestStatusStruct storage loanRequestStatus = loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];
        require(loanRequestStatus.status == LoanRequestStatus.PENDING, 'collateral-package-status-not-pending');

        _removeCollateralFromPackage(_collateralId, _packageId);
        emit SubmitPawnShopPackage(_packageId, _collateralId, LoanRequestStatus.CANCEL);
    }

    function _removeCollateralFromPackage (
        uint256 _collateralId,
        uint256 _packageId
    ) internal {
        CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        require(loanRequestListStruct.isInit == true, 'Internal Exception - loanRequestListStruct');
        require(loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId].isInit == true, 'Internal Exception - statusStruct');
        delete loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];

        for (uint i = 0; i < loanRequestListStruct.pawnShopPackageIdList.length - 1; i++){
            if (loanRequestListStruct.pawnShopPackageIdList[i] == _packageId) {
                loanRequestListStruct.pawnShopPackageIdList[i] = loanRequestListStruct.pawnShopPackageIdList[loanRequestListStruct.pawnShopPackageIdList.length - 1];
                break;
            }
        }
        delete loanRequestListStruct.pawnShopPackageIdList[loanRequestListStruct.pawnShopPackageIdList.length - 1];
    }

    function acceptCollateralOfPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external whenNotPaused
    {
        // Check for owner of packageId
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.owner == msg.sender || msg.sender == operator, 'not-owner-of-this-package-or-not-operator');
        require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, 'package-not-inactive');        
        // Check for collateral status is open
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.OPEN, 'collateral-not-open');
        // Check for collateral-package status is PENDING (waiting for accept)
        CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        require(loanRequestListStruct.isInit == true, 'collateral-havent-had-any-loan-request');
        LoanRequestStatusStruct storage statusStruct = loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == true, 'collateral-havent-had-loan-request-for-this-package');
        require(statusStruct.status == LoanRequestStatus.PENDING, 'collateral-loan-request-for-this-package-not-PENDING');

        // Execute accept => change status of loan request to ACCEPTED, wait for system to generate contract
        // Update status of loan request between _collateralId and _packageId to Accepted
        statusStruct.status = LoanRequestStatus.ACCEPTED;
        collateral.status = CollateralStatus.DOING;

        // Remove status of loan request between _collateralId and other packageId then emit event Cancel
        for (uint i = 0; i < loanRequestListStruct.pawnShopPackageIdList.length - 1; i++) {
            uint256 packageId = loanRequestListStruct.pawnShopPackageIdList[i];
            if (packageId != _packageId) {
                // Remove status
                delete loanRequestListStruct.loanRequestToPawnShopPackageMapping[packageId];
                emit SubmitPawnShopPackage(packageId, _collateralId, LoanRequestStatus.CANCEL);
            }
        }
        delete loanRequestListStruct.pawnShopPackageIdList;
        loanRequestListStruct.pawnShopPackageIdList.push(_packageId);

        // Remove relation of collateral and offers
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        if (collateralOfferList.isInit == true) {
            for (uint i = 0; i < collateralOfferList.offerIdList.length; i ++) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer storage offer = collateralOfferList.offerMapping[offerId];
                emit CancelOfferEvent(offerId, _collateralId, offer.owner);
            }
            delete collateralOffersMapping[_collateralId];
        }        emit SubmitPawnShopPackage(_packageId, _collateralId, LoanRequestStatus.ACCEPTED);
    }

    function rejectCollateralOfPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external whenNotPaused
    {
        // Check for owner of packageId
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.owner == msg.sender, 'not-owner-of-this-package');
        require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, 'package-not-inactive');        
        // Check for collateral status is open
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.OPEN, 'collateral-not-open');
        // Check for collateral-package status is PENDING (waiting for accept)
        CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        require(loanRequestListStruct.isInit == true, 'collateral-havent-had-any-loan-request');
        LoanRequestStatusStruct storage statusStruct = loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == true, 'collateral-havent-had-loan-request-for-this-package');
        require(statusStruct.status == LoanRequestStatus.PENDING, 'collateral-loan-request-for-this-package-not-PENDING');
        
        _removeCollateralFromPackage(_collateralId, _packageId);
        emit SubmitPawnShopPackage(_packageId, _collateralId, LoanRequestStatus.REJECTED);
    }

    /** ========================= CONTRACT RELATED FUNCTIONS & STATES ============================= */
    uint256 public numberContracts;    
    mapping (uint256 => Contract) public contracts;
    enum ContractStatus {ACTIVE, COMPLETED, DEFAULT}
    struct ContractTerms {
        address borrower;
        address lender;
        address collateralAsset;
        uint256 collateralAmount;
        address loanAsset;
        uint256 loanAmount;
        address repaymentAsset;
        uint256 interest;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
        uint256 contractStartDate;
        uint256 contractEndDate;
        uint256 lateThreshold;
        uint256 systemFeeRate;
        uint256 penaltyRate;
        uint256 prepaidFeeRate;
    }
    struct Contract {
        uint256 collateralId;
        int256 offerId;
        int256 pawnShopPackageId;
        ContractTerms terms;
        ContractStatus status;
        uint8 lateCount;
    }

    /** ================================ 1. ACCEPT OFFER (FOR P2P WORKFLOWS) ============================= */
    event LoanContractCreatedEvent(
        address fromAddress,
        uint256 contractId,
        Contract data
    );

    /**
        * @dev accept offer and create contract between collateral and offer
        * @param  _collateralId is id of collateral
        * @param  _offerId is id of offer
        */
    function acceptOffer(uint256 _collateralId, uint256 _offerId) external whenNotPaused {
        Collateral storage collateral = collaterals[_collateralId];
        require(msg.sender == collateral.owner, 'not-collateral-owner');
        require(collateral.status == CollateralStatus.OPEN, 'collateral-not-open');

        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        require(collateralOfferList.isInit == true, 'collateral-not-have-any-offer');
        Offer storage offer = collateralOfferList.offerMapping[_offerId];
        require(offer.isInit == true, 'offer-not-sent-to-collateral');
        require(offer.status == OfferStatus.PENDING, 'offer-unavailable');

        uint256 contractId = createContract(_collateralId, collateral, -1, int256(_offerId), offer.loanAmount, offer.owner, offer.repaymentAsset, offer.interest, offer.loanDurationType, offer.liquidityThreshold);
        Contract storage newContract = contracts[contractId];
        // change status of offer and collateral
        offer.status = OfferStatus.ACCEPTED;
        collateral.status = CollateralStatus.DOING;

        // Cancel other offer sent to this collateral
        for (uint256 i = 0; i < collateralOfferList.offerIdList.length; i++) {
            uint256 thisOfferId = collateralOfferList.offerIdList[i];
            if (thisOfferId != _offerId) {
                Offer storage thisOffer = collateralOfferList.offerMapping[thisOfferId];
                emit CancelOfferEvent(i, _collateralId, thisOffer.owner);

                delete collateralOfferList.offerMapping[thisOfferId];
            }
        }
        delete collateralOfferList.offerIdList;
        collateralOfferList.offerIdList.push(_offerId);

        emit LoanContractCreatedEvent(msg.sender, contractId, newContract);

        // transfer loan asset to collateral owner
        safeTransfer(newContract.terms.loanAsset, newContract.terms.lender, newContract.terms.borrower, newContract.terms.loanAmount);
    }

    function calculateContractDuration(LoanDurationType durationType, uint256 duration)
    internal pure
    returns (uint256 inSeconds)
    {
        if (durationType == LoanDurationType.WEEK) {
            inSeconds = 7 * 24 * 3600 * duration;
        } else {
            inSeconds = 30 * 24 * 3600 * duration;
        }
    }

    /** ================================ 2. ACCEPT COLLATERAL (FOR PAWNSHOP PACKAGE WORKFLOWS) ============================= */
    /**
    * @dev create contract between package and collateral
    * @param  _collateralId is id of collateral
    * @param  _packageId is id of package
    * @param  _loanAmount is number of loan amout for lend
    * @param  _exchangeRate is exchange rate between collateral asset and loan asset, use for validate loan amount again loan to value configuration of package
    */
    function generateContractForCollateralAndPackage(
        uint256 _collateralId,
        uint256 _packageId,
        uint256 _loanAmount,
        uint256 _exchangeRate
    ) external whenNotPaused onlyOperator
    {
        // Package must active
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, 'package-not-inactive');        
        // Check for collateral status is DOING
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.DOING, 'collateral-not-open');
        // Check for collateral-package status is ACCEPTED (waiting for accept)
        CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        require(loanRequestListStruct.isInit == true, 'collateral-havent-had-any-loan-request');
        LoanRequestStatusStruct storage statusStruct = loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == true, 'collateral-havent-had-loan-request-for-this-package');
        require(statusStruct.status == LoanRequestStatus.ACCEPTED, 'collateral-loan-request-for-this-package-not-ACCEPTED');

        // Create Contract
        uint256 contractId = createContract(_collateralId, collateral, int256(_packageId), -1, _loanAmount, pawnShopPackage.owner, pawnShopPackage.repaymentAsset, pawnShopPackage.interest, pawnShopPackage.repaymentCycleType, pawnShopPackage.loanToValueLiquidationThreshold);
        Contract storage newContract = contracts[contractId];
        emit LoanContractCreatedEvent(msg.sender, contractId, newContract);

        // Change status of collateral loan request to package to CONTRACTED
        statusStruct.status == LoanRequestStatus.CONTRACTED;
        emit SubmitPawnShopPackage(_packageId, _collateralId, LoanRequestStatus.CONTRACTED);

        // Transfer loan token from lender to borrower
        safeTransfer(newContract.terms.loanAsset, newContract.terms.lender, newContract.terms.borrower, newContract.terms.loanAmount);
    }

    function createContract (
        uint256 _collateralId,
        Collateral storage _collateral,
        int256 _packageId,
        int256 _offerId,
        uint256 _loanAmount,
        address _lender,
        address _repaymentAsset,
        uint256 _interest,
        LoanDurationType _repaymentCycleType,
        uint256 _liquidityThreshold
    )
    internal
    returns (uint256 _idx)
    {
        _idx = numberContracts;
        Contract storage newContract = contracts[_idx];
        newContract.collateralId = _collateralId;
        newContract.offerId = _offerId;
        newContract.pawnShopPackageId = int256(_packageId);
        newContract.status = ContractStatus.ACTIVE;
        newContract.lateCount = 0;
        newContract.terms.borrower = _collateral.owner;
        newContract.terms.lender = _lender;
        newContract.terms.collateralAsset = _collateral.collateralAddress;
        newContract.terms.collateralAmount = _collateral.amount;
        newContract.terms.loanAsset = _collateral.loanAsset;
        newContract.terms.loanAmount = _loanAmount;
        newContract.terms.repaymentCycleType = _repaymentCycleType;
        newContract.terms.repaymentAsset = _repaymentAsset;
        newContract.terms.interest = _interest;
        newContract.terms.liquidityThreshold = _liquidityThreshold;
        newContract.terms.contractStartDate = block.timestamp;
        newContract.terms.contractEndDate = block.timestamp + calculateContractDuration(_collateral.expectedDurationType, _collateral.expectedDurationQty);
        newContract.terms.lateThreshold = lateThreshold;
        newContract.terms.systemFeeRate = systemFeeRate;
        newContract.terms.penaltyRate = penaltyRate;
        newContract.terms.prepaidFeeRate = prepaidFeeRate;
        ++numberContracts;
    }

    /** ================================ 3. PAYMENT REQUEST & REPAYMENT WORKLOWS ============================= */
    /** ===================================== 3.1. PAYMENT REQUEST ============================= */
    mapping (uint256 => PaymentRequest[]) public contractPaymentRequestMapping;
    enum PaymentRequestStatusEnum {ACTIVE, LATE, COMPLETE, DEFAULT}
    enum PaymentRequestTypeEnum {INTEREST, OVERDUE, LOAN}
    struct PaymentRequest {
        uint256 requestId;
        PaymentRequestTypeEnum paymentRequestType;
        uint256 remainingLoan;
        uint256 penalty;
        uint256 interest;
        uint256 remainingPenalty;
        uint256 remainingInterest;
        uint256 dueDateTimestamp;
        bool chargePrepaidFee;
        PaymentRequestStatusEnum status;
    }

    event PaymentRequestEvent (
        uint256 contractId,
        PaymentRequest data
    );

    /**
        End lend period settlement and generate invoice for next period
        TODO: Need review logic of this function for all case
     */
    event DebugClosePaymentRequest (
        uint256 remainingLoan // TODO: Remove when live
    );
    function closePaymentRequestAndStartNew(
        uint256 _contractId,
        uint256 _remainingLoan,
        uint256 _nextPhrasePenalty,
        uint256 _nextPhraseInterest,
        uint256 _dueDateTimestamp,
        PaymentRequestTypeEnum _paymentRequestType,
        bool _chargePrepaidFee

    ) external whenNotPaused onlyOperator {
        Contract storage currentContract = contractMustActive(_contractId);

        // Check if number of requests is 0 => create new requests, if not then update current request as LATE or COMPLETE and create new requests
        PaymentRequest[] storage requests = contractPaymentRequestMapping[_contractId];
        if (requests.length > 0) {
            // not first phrase, get previous request
            PaymentRequest storage previousRequest = requests[requests.length - 1];
            
            // Validate: time must over due date of current payment
            require(block.timestamp >= previousRequest.dueDateTimestamp, 'time-not-over-due-of-current-payment-request');

            // Validate: remaining loan must valid
            require(previousRequest.remainingLoan == _remainingLoan, 'remaining-loan-not-correct');

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(_dueDateTimestamp <= currentContract.terms.contractEndDate, 'due-date-invalid-contract-end-date');
            emit DebugClosePaymentRequest(previousRequest.requestId); // TODO: Remove when live
            require(_dueDateTimestamp > previousRequest.dueDateTimestamp || _dueDateTimestamp == 0, 'due-date-invalid-less-than-current-request');

            // update previous
            // check for remaining penalty and interest, if greater than zero then is Lated, otherwise is completed
            if (previousRequest.remainingInterest > 0 || previousRequest.remainingPenalty > 0) {
                previousRequest.status = PaymentRequestStatusEnum.LATE;
                // Update late counter of contract
                currentContract.lateCount += 1;

                // Check for late threshold reach
                if (currentContract.terms.lateThreshold <= currentContract.lateCount) {
                    // Execute liquid
                    _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
                    return;
                }
            } else {
                previousRequest.status = PaymentRequestStatusEnum.COMPLETE;
            }

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                if (previousRequest.remainingInterest + previousRequest.remainingPenalty + previousRequest.remainingLoan > 0) {
                    // unpaid => liquid
                    _liquidationExecution(_contractId, ContractLiquidedReasonType.UNPAID);
                    return;
                } else {
                    // paid full => release collateral
                    _returnCollateralToBorrowerAndCloseContract(_contractId);
                    return;
                }
            }

            emit PaymentRequestEvent(_contractId, previousRequest);
        } else {
            // Validate: remaining loan must valid
            require(currentContract.terms.loanAmount == _remainingLoan, 'remaining-loan-not-correct-at-firsttime');

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(_dueDateTimestamp <= currentContract.terms.contractEndDate, 'due-date-invalid-contract-end-date');
            require(_dueDateTimestamp > currentContract.terms.contractStartDate || _dueDateTimestamp == 0, 'due-date-invalid-contract-start-date');
            require(block.timestamp < _dueDateTimestamp || _dueDateTimestamp == 0, 'due-date-already-over');

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                // paid full => release collateral
                _returnCollateralToBorrowerAndCloseContract(_contractId);
                return;
            }
        }

        // Create new payment request and store to contract
        PaymentRequest memory newRequest = PaymentRequest({
            requestId: requests.length,
            paymentRequestType: _paymentRequestType,
            remainingLoan: _remainingLoan,
            penalty: _nextPhrasePenalty,
            interest: _nextPhraseInterest,
            remainingPenalty: _nextPhrasePenalty,
            remainingInterest: _nextPhraseInterest,
            dueDateTimestamp: _dueDateTimestamp,
            status: PaymentRequestStatusEnum.ACTIVE,
            chargePrepaidFee: _chargePrepaidFee
        });
        requests.push(newRequest);
        emit PaymentRequestEvent(_contractId, newRequest);
    }

    /** ===================================== 3.2. REPAYMENT ============================= */
    event RepaymentEvent (
        uint256 contractId,
        uint256 paidPenaltyAmount,
        uint256 paidInterestAmount,
        uint256 paidLoanAmount,
        uint256 paidPenaltyFeeAmount,
        uint256 paidInterestFeeAmount,
        uint256 prepaidAmount,
        uint256 paymentRequestId
    );

    /**
        End lend period settlement and generate invoice for next period
     */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount
    ) external whenNotPaused {
        // Get contract & payment request
        Contract storage _contract = contractMustActive(_contractId);
        PaymentRequest[] storage requests = contractPaymentRequestMapping[_contractId];
        require(requests.length > 0, 'not-have-any-payment-request');
        PaymentRequest storage _paymentRequest = requests[requests.length - 1];
        
        // Validation: current payment request must active and not over due
        require(_paymentRequest.status == PaymentRequestStatusEnum.ACTIVE, 'current-payment-request-not-active');
        require(block.timestamp <= _paymentRequest.dueDateTimestamp, 'current-payment-request-over-due');

        // Validation: Contract must not overdue
        require(block.timestamp <= _contract.terms.contractEndDate, 'contract-over-due');

        // Calculate paid amount / remaining amount, if greater => get paid amount
        if (_paidPenaltyAmount > _paymentRequest.remainingPenalty) {
            _paidPenaltyAmount = _paymentRequest.remainingPenalty;
        }

        if (_paidInterestAmount > _paymentRequest.remainingInterest) {
            _paidInterestAmount = _paymentRequest.remainingInterest;
        }

        if (_paidLoanAmount > _paymentRequest.remainingLoan) {
            _paidLoanAmount = _paymentRequest.remainingLoan;
        }

        // Calculate fee amount based on paid amount
        uint256 _feePenalty = calculateSystemFee(_paidPenaltyAmount, _contract.terms.systemFeeRate);
        uint256 _feeInterest = calculateSystemFee(_paidInterestAmount, _contract.terms.systemFeeRate);

        uint256 _prepaidFee = 0;
        if (_paymentRequest.chargePrepaidFee) {
            _prepaidFee = calculateSystemFee(_paidLoanAmount, _contract.terms.prepaidFeeRate);
        }

        // Update paid amount on payment request
        _paymentRequest.remainingPenalty -= _paidPenaltyAmount;
        _paymentRequest.remainingInterest -= _paidInterestAmount;
        _paymentRequest.remainingLoan -= _paidLoanAmount;

        // emit event repayment
        emit RepaymentEvent(
            _contractId, 
            _paidPenaltyAmount, 
            _paidInterestAmount, 
            _paidLoanAmount, 
            _feePenalty, 
            _feeInterest, 
            _prepaidFee,
            _paymentRequest.requestId
        );

        // If remaining loan = 0 => paidoff => execute release collateral
        if (_paymentRequest.remainingLoan == 0 && _paymentRequest.remainingPenalty == 0 && _paymentRequest.remainingInterest == 0) {
            _returnCollateralToBorrowerAndCloseContract(_contractId);
        }

        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            // Transfer fee to fee wallet
            safeTransfer(_contract.terms.repaymentAsset, msg.sender, feeWallet, _feePenalty + _feeInterest);

            // Transfer penalty and interest to lender except fee amount
            safeTransfer(_contract.terms.repaymentAsset, msg.sender, _contract.terms.lender, _paidPenaltyAmount + _paidInterestAmount - _feePenalty - _feeInterest);   
        }

        if (_paidLoanAmount > 0) {
            // Transfer loan amount and prepaid fee to lender
            safeTransfer(_contract.terms.loanAsset, msg.sender, _contract.terms.lender, _paidLoanAmount + _prepaidFee);
        }

    }

    function safeTransfer(address asset, address from, address to, uint256 amount) internal {
        if (asset == address(0)) {
            // Handle BNB            
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value:amount}('');
                require(success, 'fail-transfer-bnb');
            } else {
                // Send from other address to another address
                require(false, 'not-allow-transfer-bnb-from-address-to-address');
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20(asset).balanceOf(to);
            if (from == address(this)) {
                // transfer direct to to
                IERC20(asset).transfer(to, amount);
            } else {
                IERC20(asset).transferFrom(from, to, amount);
            }
            require(IERC20(asset).balanceOf(to) - amount == prebalance, 'not-transfer-enough');
        }
    }

    function calculateSystemFee(
        uint256 amount, 
        uint256 feeRate
    ) internal view returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (ZOOM * 100);
    }

    /** ===================================== 3.3. LIQUIDITY & DEFAULT ============================= */
    enum ContractLiquidedReasonType { LATE, RISK, UNPAID }
    event ContractLiquidedEvent(
        uint256 contractId,
        uint256 liquidedAmount,
        uint256 feeAmount,
        ContractLiquidedReasonType reasonType
    );
    event LoanContractCompletedEvent(
        uint256 contractId
    );

    // TODO: Remove when live
    event DebugRiskLiquidation (
        uint256 valueRemainingToken,
        uint256 valueRemainingLoan,
        uint256 valueOfCollateralLiquidationThreshold
    );

    function collateralRiskLiquidationExecution(
        uint256 _contractId,
        uint256 _collateralPerRepaymentTokenExchangeRate,
        uint256 _collateralPerLoanAssetExchangeRate
    ) external onlyOperator {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        (uint256 remainingRepayment, uint256 remainingLoan) = calculateRemainingLoanAndRepaymentFromContract(_contractId, _contract);
        uint256 valueOfRemainingRepayment = (_collateralPerRepaymentTokenExchangeRate * remainingRepayment) / ZOOM;
        uint256 valueOfRemainingLoan = (_collateralPerLoanAssetExchangeRate * remainingLoan) / ZOOM;
        uint256 valueOfCollateralLiquidationThreshold = _contract.terms.collateralAmount * _contract.terms.liquidityThreshold / ZOOM;

        // TODO: Remove when live
        emit DebugRiskLiquidation(valueOfRemainingRepayment, valueOfRemainingLoan, valueOfCollateralLiquidationThreshold);

        require(valueOfRemainingLoan + valueOfRemainingRepayment >= valueOfCollateralLiquidationThreshold, 'collateral-not-under-liquidation-threshold');

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.RISK);

    }

    function calculateRemainingLoanAndRepaymentFromContract(uint256 _contractId, Contract storage _contract) internal view returns (uint256 remainingRepayment, uint256 remainingLoan) {
        // Validate: sum of unpaid interest, penalty and remaining loan in value must reach liquidation threshold of collateral value
        PaymentRequest[] storage requests = contractPaymentRequestMapping[_contractId];
        if (requests.length > 0) {
            // Have payment request
            PaymentRequest storage _paymentRequest = requests[requests.length - 1];
            remainingRepayment = remainingRepayment + _paymentRequest.remainingInterest + _paymentRequest.remainingPenalty;
            remainingLoan = _paymentRequest.remainingLoan;
        } else {
            // Haven't had payment request
            remainingLoan = _contract.terms.loanAmount;
        }
    }

    function lateLiquidationExecution(
        uint256 _contractId
    ) external whenNotPaused {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        // validate: contract have lateCount == lateThreshold
        require(_contract.lateCount >= _contract.terms.lateThreshold, 'late-threshold-not-reach');

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
    }

    function contractMustActive(uint256 _contractId) internal view returns (Contract storage _contract) {
        // Validate: Contract must active
        _contract = contracts[_contractId];
        require(_contract.status == ContractStatus.ACTIVE, 'contract-not-active');
    }

    function notPaidFullAtEndContractLiquidation(
        uint256 _contractId
    ) external {
        Contract storage _contract = contractMustActive(_contractId);
        // validate: current is over contract end date
        require(block.timestamp >= _contract.terms.contractEndDate, 'contract-not-over-due');

        // validate: remaining loan, interest, penalty haven't paid in full
        (uint256 remainingRepayment, uint256 remainingLoan) = calculateRemainingLoanAndRepaymentFromContract(_contractId, _contract);
        require(remainingRepayment + remainingLoan > 0, 'contract-paid-full');
        
        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
    }

    function _liquidationExecution(
        uint256 _contractId,
        ContractLiquidedReasonType _reasonType
    ) internal {
        Contract storage _contract = contracts[_contractId];

        // Execute: calculate system fee of collateral and transfer collateral except system fee amount to lender
        uint256 _systemFeeAmount = calculateSystemFee(_contract.terms.collateralAmount, _contract.terms.systemFeeRate);
        uint256 _liquidAmount = _contract.terms.collateralAmount - _systemFeeAmount;

        // Execute: update status of contract to DEFAULT, collateral to COMPLETE
        _contract.status = ContractStatus.DEFAULT;
        PaymentRequest[] storage _paymentRequests = contractPaymentRequestMapping[_contractId];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[_paymentRequests.length - 1];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.DEFAULT;
        Collateral storage _collateral = collaterals[_contract.collateralId];
        _collateral.status = CollateralStatus.COMPLETED;

        // Emit Event ContractLiquidedEvent & PaymentRequest event
        emit ContractLiquidedEvent(
            _contractId,
            _liquidAmount,
            _systemFeeAmount,
            _reasonType
        );

        emit PaymentRequestEvent(_contractId, _lastPaymentRequest);

        // Transfer to lender liquid amount
        safeTransfer(_contract.terms.collateralAsset, address(this), _contract.terms.lender, _liquidAmount);

        // Transfer to system fee wallet fee amount
        safeTransfer(_contract.terms.collateralAsset, address(this), feeWallet, _systemFeeAmount);

    }

    function _returnCollateralToBorrowerAndCloseContract(
        uint256 _contractId
    ) internal {
        Contract storage _contract = contracts[_contractId];

        // Execute: Update status of contract to COMPLETE, collateral to COMPLETE
        _contract.status = ContractStatus.COMPLETED;
        PaymentRequest[] storage _paymentRequests = contractPaymentRequestMapping[_contractId];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[_paymentRequests.length - 1];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.COMPLETE;
        Collateral storage _collateral = collaterals[_contract.collateralId];
        _collateral.status = CollateralStatus.COMPLETED;

        // Emit event ContractCompleted
        emit LoanContractCompletedEvent(_contractId);
        emit PaymentRequestEvent(_contractId, _lastPaymentRequest);

        // Execute: Transfer collateral to borrower
        safeTransfer(_contract.terms.collateralAsset, address(this), _contract.terms.borrower, _contract.terms.collateralAmount);
    }
}