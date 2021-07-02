/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity 0.8.6;



// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeERC20

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


/**
 * @dev Base datstructures for Locker contracts set
 * 
 */
abstract contract LockerTypes {
    //Just enum for good readability
    enum LockType {ERC20, LP}
    
    //Lock storage record
    struct  LockStorageRecord {
        LockType ltype;  //Most time it equal ERC20
        address token;   //Address of project token smart contract to lock
        uint256 amount;  //Lock amount for all investors/lendings
        VestingRecord[] vestings; //Array of vedtings records (see below)
    }

    //One vesting record
    struct VestingRecord {
        uint256 unlockTime;  //only after this moment locked amount will be available
        uint256 amountUnlock;//after unlockTime this amount will be available for all investors according  percentage share
        bool isNFT; //for use with futeres lock
    }

    //Investor's share record
    struct RegistryShare {
        uint256 lockIndex;     //Array index of lock record
        uint256 sharePercent;  //Investors share in this lock
        uint256 claimedAmount; //Already claimed amount
    }

}
// File: Locker.sol

contract Locker is LockerTypes {
    using SafeERC20 for IERC20;

    string  constant name = "Lock & Registry v0.0.2"; 
    uint256 constant MAX_VESTING_RECORDS_PER_LOCK = 250;
    uint256 constant TOTAL_IN_PERCENT = 10000;
    LockStorageRecord[] lockerStorage;

    //map from users(investors)  to locked shares
    mapping(address => RegistryShare[])  public registry;

    //map from lockIndex to beneficiaries list
    mapping(uint256 => address[]) beneficiariesInLock;

    
    event NewLock(address indexed erc20, address indexed who, uint256 lockedAmount, uint256 lockId);
    
    /**
     * @dev Any who have token balance > 0 can lock  it here.
     *
     * Emits a NewLock event.
     *
     * Requirements:
     *
     * - `_ERC20` token contract address for lock.
     * - `_amount` amount of tokens to be locked.
     * - `_unlockedFrom` array of unlock dates in unixtime format.
     * - `_unlockAmount` array of unlock amounts.
     * - `_beneficiaries` array of address for beneficiaries.
     * - `_beneficiariesShares` array of beneficiaries shares, % 
     * - scaled on 100. so 20% = 2000, 0.1% = 10.
     * Caller must approve _ERC20 tokens to this contract address before lock
     */
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
        emit NewLock(_ERC20, msg.sender, _amount, lockerStorage.length - 1);

    }

    /**
     * @dev Any _beneficiaries can claim their tokens after vesting lock time is expired.
     *
     * Requirements:
     *
     * - `_lockIndex` array index, number of lock record in  storage. For one project lock case = 0
     * - `_desiredAmount` amount of tokens to be unlocked. Only after vesting lock time is expired
     * - If now date less then vesting lock time tx will be revert
     */
    function claimTokens(uint256 _lockIndex, uint256 _desiredAmount) external {
        //Lets get our lockRecord by index
        require(_lockIndex < lockerStorage.length, "Lock record not saved yet");
        require(_desiredAmount > 0, "Cant claim zero");
        LockStorageRecord memory lock = lockerStorage[_lockIndex];
        (uint256 percentShares, uint256 wasClaimed) = 
            _getUserSharePercentAndClaimedAmount(msg.sender, _lockIndex);
        uint256 availableAmount =
            _getAvailableAmountByLockIndex(_lockIndex)
            * percentShares / TOTAL_IN_PERCENT
            - wasClaimed;

        require(_desiredAmount <= availableAmount, "Insufficient for now");
        availableAmount = _desiredAmount;

        //update claimed amount
        _decreaseAvailableAmount(msg.sender, _lockIndex, availableAmount);

        //send tokens
        IERC20 token = IERC20(lock.token);
        token.safeTransfer(msg.sender, availableAmount);
    }

    /**
     * @dev Returns array of shares for user (beneficiary).
     * See LockerTypes.RegistryShare description.
     * In case of one project this will only one record
     * 
     * Requirements:
     *
     * - `_user` beneficiary address
     */
    function getUserShares(address _user) external view returns (RegistryShare[] memory) {
        return _getUsersShares(_user);
    }


    /**
     * @dev Returns tuple (totalBalance, available balance).
     * totalBalance - amount of all user shares minus already claimed
     * available - user balance that available for NOW, minus already claimed
     * -
     * Requirements:
     *
     * - `_user` beneficiary address
     * - `_lockIndex` array index, number of lock record in  storage. For one project lock case = 0
     */
    function getUserBalances(address _user, uint256 _lockIndex) external view returns (uint256, uint256) {
        return _getUserBalances(_user, _lockIndex);
    }

    /**
     * @dev Returns LockStorageRecord data struture.See LockerTypes.LockStorageRecord description.
     * -
     * Requirements:
     *
     * - `_index` array index, number of lock record in  storage. For one project lock case = 0
     */
    function getLockRecordByIndex(uint256 _index) external view returns (LockStorageRecord memory){
        return _getLockRecordByIndex(_index);
    }

    
    /**
     * @dev Returns LockStorage Record count, for iteration from app.
     * 
     */
    function getLockCount() external view returns (uint256) {
        return lockerStorage.length;
    }



    /**
     * @dev Just helper for array summ.
     * 
     */
    function getArraySum(uint256[] memory _array) external pure returns (uint256) {
        return _getArraySum(_array);
    }

    ////////////////////////////////////////////////////////////
    /////////// Internals           ////////////////////////////
    ////////////////////////////////////////////////////////////
    function _decreaseAvailableAmount(address user, uint256 _lockIndex, uint256 _amount) internal {
        RegistryShare[] storage shares = registry[user];
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
            if  (v[i].unlockTime <= block.timestamp && !v[i].isNFT) {
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
                //We do this cycle because one address can exist
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

    function _getUserBalances(address _user, uint256 _lockIndex) internal view returns (uint256, uint256) {

        (uint256 percentShares, uint256 wasClaimed) =
            _getUserSharePercentAndClaimedAmount(_user, _lockIndex);

        uint256 totalBalance =
        lockerStorage[_lockIndex].amount
        * percentShares / TOTAL_IN_PERCENT
        - wasClaimed;

        uint256 available =
        _getAvailableAmountByLockIndex(_lockIndex)
        * percentShares / TOTAL_IN_PERCENT
        - wasClaimed;

        return (totalBalance, available);
     }


    function _getVestingsByLockIndex(uint256 _index) internal view returns (VestingRecord[] memory) {
        VestingRecord[] memory v = _getLockRecordByIndex(_index).vestings;
        return v;

    }

    function _getLockRecordByIndex(uint256 _index) internal view returns (LockStorageRecord memory){
        return lockerStorage[_index];
    }

}