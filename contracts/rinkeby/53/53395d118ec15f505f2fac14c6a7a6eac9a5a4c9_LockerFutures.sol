/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT
// Platinum Software Dev Team
// Locker  ALFA  version.Testing is in progress.

// With openzeppelin-contracts


pragma solidity ^0.8.2;

abstract contract LockerTypes {

    enum LockType {ERC20, LP}
    
    //Lock storage record
    struct  LockStorageRecord {
        LockType ltype;
        address token;
        uint256 amount;
        VestingRecord[] vestings;
    }

    struct VestingRecord {
        uint256 unlockTime;
        uint256 amountUnlock;
        uint256 nftId;
    }

    struct RegistryShare {
        uint256 lockIndex;
        uint256 sharePercent;
        uint256 claimedAmount;
    }

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


interface  IERC1155mintable is IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function burn(address account, uint256 id, uint256 amount) external;
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



pragma solidity ^0.8.2;

contract Locker is LockerTypes {
    using SafeERC20 for IERC20;

    string  constant name = "Lock & Registry v0.0.1"; 
    uint256 constant MAX_VESTING_RECORDS_PER_LOCK = 250;
    uint256 constant TOTAL_IN_PERCENT = 10000;
    LockStorageRecord[] lockerStorage;

    //map from users(investors)  to locked shares
    mapping(address => RegistryShare[])  public registry;

    //map from lockIndex to beneficiaries list
    mapping(uint256 => address[]) beneficiariesInLock;

    event NewLock(address indexed erc20, address indexed who, uint256 lockedAmount, uint256 lockId);
    event EmitFutures(address indexed erc20, address indexed who, uint256 lockedAmount, uint256 claimDate);

    function lockTokens(
        address _ERC20, 
        uint256 _amount, 
        uint256[] memory _unlockedFrom, 
        uint256[] memory _unlockAmount,
        address[] memory _beneficiaries,
        uint256[] memory _beneficiariesShares

    )
        external 

    {
        require(_amount > 0, "Cant lock 0 amount");
        require(IERC20(_ERC20).allowance(msg.sender, address(this)) >= _amount, "Please approve first");
        require(_getArraySum(_unlockAmount) == _amount, "Sum vesting records must be equal lock amount");
        require(_unlockedFrom.length == _unlockAmount.length, "Length of periods and amounts arrays must be equal");
        require(_beneficiaries.length == _beneficiariesShares.length, "Length of beneficiaries and shares arrays must be equal");
        require(_getArraySum(_beneficiariesShares) == TOTAL_IN_PERCENT, "Sum of shares array must be equal to 100%");
        
        //Lets prepare vestings array
        VestingRecord[] memory v = new VestingRecord[](_unlockedFrom.length);
        for (uint256 i = 0; i < _unlockedFrom.length; i ++ ) {
                v[i].unlockTime = _unlockedFrom[i];
                v[i].amountUnlock = _unlockAmount[i]; 
        }
        
        //Save lock info in storage
        LockStorageRecord storage lock = lockerStorage.push();
        lock.ltype = LockType.ERC20;
        lock.token = _ERC20;
        lock.amount = _amount;


        //Copying of type struct LockerTypes.VestingRecord memory[] memory 
        //to storage not yet supported.
        //so we need this cycle
        for (uint256 i = 0; i < _unlockedFrom.length; i ++ ) {
            lock.vestings.push(v[i]);    
        }

        //Lets save _beneficiaries for this lock
        for (uint256 i = 0; i < _beneficiaries.length; i ++ ) {
            RegistryShare[] storage shares = registry[_beneficiaries[i]];
            shares.push(RegistryShare({
                lockIndex: lockerStorage.length - 1,
                sharePercent: _beneficiariesShares[i],
                claimedAmount: 0
            }));
            //Save beneficaries in one map
            beneficiariesInLock[lockerStorage.length - 1].push(_beneficiaries[i]);
        }

        
        IERC20 token = IERC20(_ERC20);
        token.safeTransferFrom(msg.sender, address(this), _amount);

    }

    function claimTokens(uint256 _lockIndex, uint256 _desiredAmount) external {
        //Lets get our lockRecord by index
        require(_desiredAmount > 0, "Cant claim zero");
        LockStorageRecord memory lock = lockerStorage[_lockIndex];
        (uint256 percentShares, uint256 wasClaimed) = 
            _getUserSharePercentAndClaimedAmount(msg.sender, _lockIndex);
        uint256 availableAmount =
            //TODO check for small values 
            _getAvailableAmountByLockIndex(_lockIndex)
            * percentShares / TOTAL_IN_PERCENT
            - wasClaimed;

        if  (_desiredAmount != 0) {
            require(_desiredAmount <= availableAmount, "Insufficient for now");
            availableAmount = _desiredAmount;
        }

        //update claimed amount
        _decreaseAvailableAmount(msg.sender, _lockIndex, availableAmount);

        //send tokens
        IERC20 token = IERC20(lock.token);
        token.safeTransfer(msg.sender, availableAmount);
    }


    function getMyShares() external view returns (RegistryShare[] memory) {
        return _getUsersShares(msg.sender);
    }


    function getLockRecordByIndex(uint256 _index) external view returns (LockStorageRecord memory){
        return _getLockRecordByIndex(_index);
    }

    function getLockCount() external view returns (uint256) {
        return lockerStorage.length;
    }

    function getArraySum(uint256[] memory _array) external pure returns (uint256) {
        return _getArraySum(_array);
    }

    ////////////////////////////////////////////////////////////
    /////////// Internals           ////////////////////////////
    ////////////////////////////////////////////////////////////
    function _decreaseAvailableAmount(address user, uint256 _lockIndex, uint256 _amount) internal {
        RegistryShare[] storage shares = registry[msg.sender];
        for (uint256 i = 0; i < shares.length; i ++ ) {
            if  (shares[i].lockIndex == _lockIndex) {
                //It does not matter what record will update
                // with same _lockIndex. but only one!!!!
                shares[i].claimedAmount += _amount;
                break;
            }
        }

    }

    function _getArraySum(uint256[] memory _array) internal pure returns (uint256) {
        uint256 res = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            res += _array[i];           
        }
        return res;
    }

    function _getAvailableAmountByLockIndex(uint256 _lockIndex) 
        internal 
        view 
        returns(uint256)
    {
        VestingRecord[] memory v = lockerStorage[_lockIndex].vestings;
        uint256 res = 0;
        for (uint256 i = 0; i < v.length; i ++ ) {
            if  (v[i].unlockTime <= block.timestamp && v[i].nftId == 0) {
                res += v[i].amountUnlock;
            }
        }
        return res;
    }

    function _getUserSharePercentAndClaimedAmount(address _user, uint256 _lockIndex) 
        internal 
        view 
        returns(uint256 percent, uint256 claimed)
    {
        RegistryShare[] memory shares = registry[_user];
        for (uint256 i = 0; i < shares.length; i ++ ) {
            if  (shares[i].lockIndex == _lockIndex) {
                //We do this cycle because one adress can exist
                //more then once in one lock
                percent += shares[i].sharePercent;
                claimed += shares[i].claimedAmount;
            }
        }
        return (percent, claimed);
    }

    function _getUsersShares(address _user) internal view returns (RegistryShare[] memory) {
        return registry[_user];
    }


    function _getVestingsByLockIndex(uint256 _index) internal view returns (VestingRecord[] memory) {
        VestingRecord[] memory v = _getLockRecordByIndex(_index).vestings;
        return v;

    }

    function _getLockRecordByIndex(uint256 _index) internal view returns (LockStorageRecord memory){
        return lockerStorage[_index];
    }

}


contract LockerFutures is Locker, Ownable {
    using SafeERC20 for IERC20;

    uint256 constant DELAY_FOR_FUTURES_ISSUANCE = 1 days;
    uint256 constant LOCK_ID_SCALE = 1e18; 

    address public futuresERC1155;

   function emitFutures(uint256 _lockIndex, uint256 _vestingIndex) 
        external 
        returns (uint256)
    {
        VestingRecord storage vr = lockerStorage[_lockIndex].vestings[_vestingIndex];
        require(vr.unlockTime > block.timestamp + DELAY_FOR_FUTURES_ISSUANCE, 
             "To late for this vesting"
        );
        require(vr.nftId == 0, "This futures already issued");
        
        //Check that tx.sender have none zero share in this lock
        //to be authorize for mint NFT 
        
        uint256 percent;
        uint256 claimed;
        (percent, claimed) = _getUserSharePercentAndClaimedAmount(msg.sender, _lockIndex);
        require(percent > 0, "Sender has no balance in this lock");
        require(claimed == 0, "Distribution was started");

        //TODO  may be need more checks

        //lets mint nft
        address[] memory bnfc = beneficiariesInLock[_lockIndex];
        uint256 amountMint; 
        for (uint256 i = 0; i < bnfc.length; i ++) {
            (percent, ) = _getUserSharePercentAndClaimedAmount(bnfc[i], _lockIndex);
            amountMint = vr.amountUnlock * percent / TOTAL_IN_PERCENT;
            IERC1155mintable(futuresERC1155).mint(
                bnfc[i],
                _getNFTtokenID(_lockIndex, _vestingIndex),
                amountMint, 
                bytes('0')
            );
        }
        //Save nftid in vesting record for exclude amount of this vesting
        //record from available for ordinar claim.
        //from this moment this amount can be claimed only for NFT owner
        vr.nftId =  _getNFTtokenID(_lockIndex, _vestingIndex);
    }

    function claimWithNFT(uint256 _tokenId) external {
        require(
            IERC1155mintable(futuresERC1155).balanceOf(msg.sender, _tokenId) > 0,
            "Your futures balance is zero"
        );
        //Lets get ERC20 address of lock of this futures
        IERC20 token20;
        token20 = IERC20(_getLockRecordByIndex(_tokenId / LOCK_ID_SCALE).token);

        //send tokens
        IERC20 token = IERC20(token20);
        token.safeTransfer(
            msg.sender,  
            IERC1155mintable(futuresERC1155).balanceOf(msg.sender, _tokenId)
        );
    }
    ///////////////////////////////////////////////////////////
    /////   Admin functions                                 ///
    ///////////////////////////////////////////////////////////
    function setFuturesERC1155(address _erc1155) external onlyOwner {
        require(_erc1155 != address(0), "Cant set zero address");
        futuresERC1155 = _erc1155;
    }

    ////////////////////////////////////////////////////////////
    /////////// Internals           ////////////////////////////
    ////////////////////////////////////////////////////////////
    function _getNFTtokenID(uint256 _lockIndex, uint256 _vestingIndex) 
        internal 
        returns (uint256)
    {
        return _lockIndex * LOCK_ID_SCALE +_vestingIndex;
    }
}