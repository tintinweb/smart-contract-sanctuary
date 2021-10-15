/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

// Part: OpenZeppelin/[email protected]/EnumerableSet

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC731Receiver

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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


interface IGoobers {
	function balanceOf(address _user) external view returns(uint256);
	function ownerOf(uint256 tokenId) external view returns(address);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract GOO is Context, IERC721Receiver, IERC20 {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
	
	uint256 public endBlock = 5000000;  // last block that offers staking, will be startBlock + 5,000,000
	uint256 public startBlock;

    // passive income
	mapping(uint256 => uint256) public lastUpdate;
	uint256 constant public BASE_RATE = 30000; 
	
	// staking
	uint256 constant STAKING_REWARD_PER_BLOCK = 150000;
	uint256 public totalStaked;
	uint256 public rewardCoefficient;
	uint256 public lastStakingUpdateBlock;
	mapping (address => EnumerableSet.UintSet) private stakingDeposits;
	mapping (uint256 => uint256) private rewardCheckpoint;

	IGoobers public goobersContract;

	constructor (address _goobers) {
		goobersContract = IGoobers(_goobers);
		_name = "$GOO";
		_symbol = "$GOO";
		_decimals = 9;
		startBlock = block.number;
		endBlock += startBlock;
	}
	
	// ------------------------
	// ERC20 standard functions
	
    function name() external view returns (string memory){
        return _name;
    }

    function symbol() external view returns (string memory){
        return _symbol;
    }

    function decimals() external view returns (uint256){
        return _decimals;
    }
	
	function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account] + getPassiveClaimable(account) + getStakingClaimable(account);
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    // --------------    
    // view functions
    
    function stakingRewardPerTokenPerBlock() public view returns(uint256){
        return STAKING_REWARD_PER_BLOCK / totalStaked;
    }
    
    function passiveRewardPerTokenPerBlock() public view returns(uint256){
        return BASE_RATE - totalStaked;
    }
    
    function getLastPassiveUpdate(uint256 _idx) public view returns(uint256){
        return lastUpdate[_idx];
    }
    
    function getOwnedGoobersBalance(address _user) public view returns(uint256) {
        return goobersContract.balanceOf(_user);
    }
    
    function getOwnedGoobersIds(address _user) public view returns(uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](goobersContract.balanceOf(_user));
        
        for (uint256 idx; idx < tokenIds.length; idx++){
            tokenIds[idx] = goobersContract.tokenOfOwnerByIndex(_user, idx);
        }
        
        return tokenIds;
    }
    
    function getStakedGoobersBalance(address _user) public view returns(uint256) {
        EnumerableSet.UintSet storage depositSet = stakingDeposits[_user];
        return depositSet.length();
    }
    
    function getStakedGoobersIds(address _user) public view returns(uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = stakingDeposits[_user];
        uint256[] memory tokenIds = new uint256[](depositSet.length());
        
        for (uint256 idx; idx < depositSet.length(); idx++) {
            tokenIds[idx] = depositSet.at(idx);
        }

        return tokenIds;
    }
    
    function confirmOwnership(address _user, uint256 _idx) public view returns(bool) {
        address owner = goobersContract.ownerOf(_idx);
        if (owner == _user || (owner == address(this) && stakingDeposits[_user].contains(_idx))){
            return true;
        }
        return false;
    }
    
    function getPassiveClaimable(address _user) public view returns(uint256) {
		uint256 time = min(block.number, endBlock);
		uint256 goobersCount = goobersContract.balanceOf(_user);
		uint256 pending = 0;
		for (uint256 idx = 0; idx < goobersCount; idx++){
		    pending +=  time - (lastUpdate[goobersContract.tokenOfOwnerByIndex(_user, idx)] != 0 ? lastUpdate[goobersContract.tokenOfOwnerByIndex(_user, idx)] : startBlock);
		}
		uint256[] memory stakedGoobers = getStakedGoobersIds(_user);
		for (uint256 idx = 0; idx < stakedGoobers.length; idx++){
		    pending +=  time - (lastUpdate[stakedGoobers[idx]] != 0 ? lastUpdate[stakedGoobers[idx]] : startBlock);
		}
		return pending * BASE_RATE;
	}
	
	function getStakingClaimable(address _user) public view returns(uint256) {
	    if (totalStaked == 0) return 0;
	    uint256 dBlocks;
	    unchecked{
	        dBlocks = block.number - lastStakingUpdateBlock;
	    }
	    
	    uint256 pending = 0;
	    unchecked{
	        pending = rewardCoefficient + (dBlocks * STAKING_REWARD_PER_BLOCK) / totalStaked;
	    }
	    EnumerableSet.UintSet storage depositSet = stakingDeposits[_user];
	    unchecked{
	        pending *= depositSet.length();
	    }
	    for (uint256 idx; idx < depositSet.length(); idx++) {
	        pending -= rewardCheckpoint[depositSet.at(idx)];
        }
	    
	    return pending;
	}
	
	function getTotalClaimable(address _user) public view returns(uint256) {
	    return getPassiveClaimable(_user) + getStakingClaimable(_user);
	}
	
	function getLastStakingUpdateBlock() public view returns(uint256){
	    return lastStakingUpdateBlock;
	}
	
	function getCurrentBlock() public view returns(uint256){
	    return block.number;
	}
	
	// ----------------
	// public functions
	
	function claimPassiveRewards() external {
	    uint256 passiveClaim = getPassiveClaimable(_msgSender());
	    require(passiveClaim > 0, "No passive reward to claim");
        _claimPassiveReward(passiveClaim);
	}
	
	function claimStakingRewards() public {
	    uint256 goobersStaked = getStakedGoobersBalance(_msgSender());
	    require(goobersStaked > 0, "Nothing staked");
	    _updateStakingClaims();
	    _claimStakingReward();
	}
	
	function claimAllRewards() public {
	    uint256 passiveClaim = getPassiveClaimable(_msgSender());
	    uint256 goobersStaked = getStakedGoobersBalance(_msgSender());
	    require (passiveClaim > 0 || goobersStaked > 0, "No rewards to claim");
	    if (passiveClaim > 0){
	        _claimPassiveReward(passiveClaim);
	    }
        if (goobersStaked > 0){
            _updateStakingClaims();
            _claimStakingReward();
        }
	}
    
    function stake(uint256[] memory _ids) external {
        _updateStakingClaims();
        
        for (uint256 idx = 0; idx < _ids.length; idx++){
            goobersContract.safeTransferFrom(_msgSender(), address(this), _ids[idx], '');
            stakingDeposits[_msgSender()].add(_ids[idx]);
            rewardCheckpoint[_ids[idx]] = rewardCoefficient;
        }
        unchecked{
            totalStaked += _ids.length;
        }
    }
    
    function unstake(uint256[] memory _ids) external {
        _updateStakingClaims();
        _claimStakingReward();
        
        for (uint256 idx = 0; idx < _ids.length; idx++){
            require(stakingDeposits[_msgSender()].contains(_ids[idx]), "Token does not belong to you or not deposited");
            goobersContract.safeTransferFrom(address(this), _msgSender(), _ids[idx], '');
            stakingDeposits[_msgSender()].remove(_ids[idx]);
        }
        unchecked{
            totalStaked -= _ids.length;
        }
    }
    
    function unstakeAll() external {
        uint256[] memory stakedGoobers = getStakedGoobersIds(_msgSender());
        require(stakedGoobers.length > 0, "Nothing staked");
        
        _updateStakingClaims();
        
        uint256 pending = 0;
        unchecked{
            totalStaked -= stakedGoobers.length;
	        pending = rewardCoefficient * stakedGoobers.length;
	    }
        for (uint256 idx = 0; idx < stakedGoobers.length; idx++){
            pending -= rewardCheckpoint[stakedGoobers[idx]];
            rewardCheckpoint[stakedGoobers[idx]] = rewardCoefficient;
            goobersContract.safeTransferFrom(address(this), _msgSender(), stakedGoobers[idx], '');
            stakingDeposits[_msgSender()].remove(stakedGoobers[idx]);
        }
        _mint(_msgSender(), pending);
    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    // ------------------
    // internal functions

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function _updatePassiveClaims() internal {
	    uint256 time = min(block.number, endBlock);
		uint256 goobersCount = goobersContract.balanceOf(_msgSender());
		for (uint256 idx = 0; idx < goobersCount; idx++){
		    if (lastUpdate[goobersContract.tokenOfOwnerByIndex(_msgSender(), idx)] < time ){
		        lastUpdate[goobersContract.tokenOfOwnerByIndex(_msgSender(), idx)] = time;
		    }
		}
		uint256[] memory stakedGoobers = getStakedGoobersIds(_msgSender());
		for (uint256 idx = 0; idx < stakedGoobers.length; idx++){
		    if (lastUpdate[stakedGoobers[idx]] < time ){
		        lastUpdate[stakedGoobers[idx]] = time;
		    }
		}
	}
	
	function _claimPassiveReward(uint256 _claimAmount) internal {
	    _updatePassiveClaims();
        _mint(_msgSender(), _claimAmount);
	}
	
	function _claimStakingReward() internal {
	    uint256 pending = 0;
	   
	    EnumerableSet.UintSet storage depositSet = stakingDeposits[_msgSender()];
	    unchecked{
	        pending = rewardCoefficient * depositSet.length();
	    }
	    
	    for (uint256 idx; idx < depositSet.length(); idx++) {
	        pending -= rewardCheckpoint[depositSet.at(idx)];
	        rewardCheckpoint[depositSet.at(idx)] = rewardCoefficient;
        }
        _mint(_msgSender(), pending);
	}
	
	function _updateStakingClaims() internal {
	    uint256 dBlocks;
	    unchecked{
	        dBlocks = block.number - lastStakingUpdateBlock;
	    }
	    if (dBlocks == 0){
	        return;
	    }
	    if (totalStaked == 0){
	        lastStakingUpdateBlock = block.number;
	        return;
	    }
	    unchecked {
	        rewardCoefficient += (dBlocks * STAKING_REWARD_PER_BLOCK) / totalStaked;
	    }
	    lastStakingUpdateBlock = block.number;
	}
	
	function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (amount > balances[sender]){
            uint256 passiveClaim = getPassiveClaimable(sender);
            if (passiveClaim > 0) {
                _claimPassiveReward(passiveClaim);
            }
            if (amount > balances[sender]) {
                _updateStakingClaims();
                _claimStakingReward();
                require(balances[sender] >= amount,"ERC20: transfer amount exceeds balance");
            }
        }
        
        
        unchecked {
            balances[sender] -= amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
	
	function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
	
}