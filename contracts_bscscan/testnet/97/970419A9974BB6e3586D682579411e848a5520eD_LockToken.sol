/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0;

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
  * solidity ^0.8.0
 */
interface IERC20 {

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 * solidity ^0.8.0
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

/**
 * @dev Collection of functions related to the address type
 * solidity ^0.8.0
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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 * solidity ^0.8.0;
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
 * solidity ^0.8.0;
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract LockToken is Ownable {
    using SafeMath for uint256;
    using Address for address;

    /* Lock Token Item Structure */
    struct LockItem {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool isWithdraw;
    }

    uint256 public lockId;
    uint256[] public allLockIds;
    mapping(address => uint256[]) public locksByWithdrawalAddress;
    mapping(uint256 => LockItem) public lockedToken;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;
    uint256 public fee = 0.05 ether;

    event WithdrawToken(address receiveAddress, address tokenAddress, uint256 receiveAmount, uint256 _id, uint256 unlockTime);

    event LockTokenItem(address tokenAddress, address withdrawAddress, uint256 amount, uint256 unlockTime);

    event TransferLocks(address fromAddress, address toAddress, address tokenAddress, uint256 _id, uint256 amount);

    event ExtendLockDuration(address extendAddress, address tokenAddress, uint256 _id, uint256 oldUnlockTime, uint256 newUnlockTime);

    event SetFee(uint256 oldValue, uint256 newValue);

    /* Lock token */
    function lockToken(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) public payable returns (uint256 _id) {
        require(msg.value == fee, "Please pay the fee");
        require(_amount > 0, "Invalid amount");
        require(_unlockTime < 10000000000 && _unlockTime > block.timestamp, "Invalid unlock time");

        // Update balance in address
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amount);

        _id = ++lockId;

        LockItem memory newLockItem = LockItem({
        tokenAddress : _tokenAddress,
        withdrawalAddress : _withdrawalAddress,
        tokenAmount : _amount,
        unlockTime : _unlockTime,
        isWithdraw : false
        });
        lockedToken[_id] = newLockItem;

        allLockIds.push(_id);
        locksByWithdrawalAddress[_withdrawalAddress].push(_id);

        // Transfer token into contract
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), "Cannot transfer token");
        emit LockTokenItem(_tokenAddress, _withdrawalAddress, _amount, _unlockTime);
    }

    /* Multiple lock token */
    function multipleLockToken(address _tokenAddress, address _withdrawalAddress, uint256[] memory _amounts, uint256[] memory _unlockTimes) public payable returns (uint256 _id) {
        require(_amounts.length > 0);
        require(_amounts.length == _unlockTimes.length);
        uint256 requestNumber = _amounts.length;
        uint256 feeRequired = fee * requestNumber;
        if (requestNumber > 1) {
            uint256 discount = feeRequired.div(10);
            feeRequired = feeRequired.sub(discount);
        }
        require(msg.value == feeRequired, "Please pay the fee");

        for (uint256 i = 0; i < requestNumber; i++) {
            require(_amounts[i] > 0, "Invalid amount");
            require(_unlockTimes[i] < 10000000000 && _unlockTimes[i] > block.timestamp, "Invalid unlock time");

            // Update balance in address
            walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amounts[i]);

            _id = ++lockId;

            LockItem memory newLockItem = LockItem({
            tokenAddress : _tokenAddress,
            withdrawalAddress : _withdrawalAddress,
            tokenAmount : _amounts[i],
            unlockTime : _unlockTimes[i],
            isWithdraw : false
            });
            lockedToken[_id] = newLockItem;

            allLockIds.push(_id);
            locksByWithdrawalAddress[_withdrawalAddress].push(_id);

            // Transfer token into contract
            require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amounts[i]));
            emit LockTokenItem(_tokenAddress, _withdrawalAddress, _amounts[i], _unlockTimes[i]);
        }
    }

    /* Extend lock Duration */
    function extendLockDuration(uint256 _id, uint256 _unlockTime) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(_unlockTime < 10000000000);
        require(_unlockTime > lockedTokenItem.unlockTime);
        require(!lockedTokenItem.isWithdraw);
        require(msg.sender == lockedTokenItem.withdrawalAddress);
        uint256 oldUnlockTime = lockedTokenItem.unlockTime;
        // Update new unlock time
        lockedTokenItem.unlockTime = _unlockTime;
        emit ExtendLockDuration(msg.sender, lockedTokenItem.tokenAddress, _id, oldUnlockTime, _unlockTime);
    }

    /* Transfer locked token */
    function transferLocks(uint256 _id, address _receiverAddress) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(!lockedTokenItem.isWithdraw);
        require(msg.sender == lockedTokenItem.withdrawalAddress);
        // Decrease sender's token balance
        walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender] = walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender].sub(lockedTokenItem.tokenAmount);

        // Increase receiver's token balance
        walletTokenBalance[lockedTokenItem.tokenAddress][_receiverAddress] = walletTokenBalance[lockedTokenItem.tokenAddress][_receiverAddress].add(lockedTokenItem.tokenAmount);

        // Remove this id from this address
        uint256 lockLength = locksByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
        for (uint256 i = 0; i < lockLength; i++) {
            if (locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i] == _id) {
                delete locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i];
                break;
            }
        }

        // Assign this id to receiver address
        lockedTokenItem.withdrawalAddress = _receiverAddress;
        locksByWithdrawalAddress[_receiverAddress].push(_id);
        emit TransferLocks(msg.sender, _receiverAddress, lockedTokenItem.tokenAddress, _id, lockedTokenItem.tokenAmount);
    }

    /* Withdraw token */
    function withdrawToken(uint256 _id) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(block.timestamp >= lockedTokenItem.unlockTime);
        require(msg.sender == lockedTokenItem.withdrawalAddress);
        require(!lockedTokenItem.isWithdraw);
        lockedTokenItem.isWithdraw = true;

        // Update balance in address
        walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender] = walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender].sub(lockedTokenItem.tokenAmount);

        // Remove this id from this address
        uint256 lockLength = locksByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
        for (uint256 i = 0; i < lockLength; i++) {
            if (locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i] == _id) {
                delete locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i];
                break;
            }
        }

        // Transfer token to wallet address
        require(IERC20(lockedTokenItem.tokenAddress).transfer(msg.sender, lockedTokenItem.tokenAmount));
        emit WithdrawToken(msg.sender, lockedTokenItem.tokenAddress, lockedTokenItem.tokenAmount, _id, lockedTokenItem.unlockTime);
    }

    /* Get Total Token Balance By Contract */
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    /* Get Token Balance By Address */
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256) {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    /* Get All Lock Ids */
    function getAllLockIds() view public returns (uint256[] memory) {
        return allLockIds;
    }

    /* Get Lock Detail By Id */
    function getLockDetails(uint256 _id) view public returns (address _tokenAddress, address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _isWithdraw) {
        return (lockedToken[_id].tokenAddress, lockedToken[_id].withdrawalAddress, lockedToken[_id].tokenAmount, lockedToken[_id].unlockTime, lockedToken[_id].isWithdraw);
    }

    /* Get Lock By Withdrawal Address */
    function getLocksByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory) {
        return locksByWithdrawalAddress[_withdrawalAddress];
    }

    /* Get Lock Token Item By Id */
    function getLockTokenItem(uint256 _id) view private returns (LockItem storage) {
        return lockedToken[_id];
    }

    fallback() payable external {}

    receive() payable external {}

    /* Retrieve main balance */
    function retrieveMainBalance() public onlyOwner() {
        uint256 mainBalance = address(this).balance;
        require(mainBalance > 0, "Nothing to retrieve");
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    /* Set Fee */
    function setFee(uint256 _fee) public onlyOwner() {
        uint256 oldValue = fee;
        fee = _fee;
        emit SetFee(oldValue, fee);
    }

}