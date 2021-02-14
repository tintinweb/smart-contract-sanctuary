/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;



// Part: Address

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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// Part: BoostersEnumerableMap

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`] type.
 *
 * Maps have the following properties:
 * - Entries are added, removed, and checked for existence in constant time. (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 * ```
 * contract Example {
 *     using EnumerableMap for EnumerableMap.UintToNFTMap;  // Add the library methods
 *     EnumerableMap.UintToNFTMap private myMap;    // Declare a set state variable
 * }
 * ```
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToNFTMap`) are supported.
 */
library BoostersEnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit in bytes32.

    // boosterInfo contains the owner and the type information of a SIGH Finance's Booster NFT
    struct boosterInfo {
        address owner;
        string _type;
    }

    // key is the tokenID and _NFT_Value is the boosterInfo struct
    struct MapEntry {
        bytes32 _key;
        boosterInfo _NFT_Value;
    }

    struct Map {
        MapEntry[] _NFTs;                       // Storage of NFT's keys and boosterInfos        
        mapping (bytes32 => uint256) _indexes;  // Position of the entry defined by a key (tokenID) in the `_NFTs` array, plus 1 because index 0 means a key is not in the map.
    }

    /**
     * @dev Adds a key-value (tokenID - NFT Info) pair to a map, or updates the value for an existing key. O(1).
     * Returns true if the key was added to the map, that is if it was not already present.
     */
    function _set(Map storage map, bytes32 key, boosterInfo memory _NFTvalue) private returns (bool) {
        uint256 keyIndex = map._indexes[key];   // We read and store the key's index to prevent multiple reads from the same storage slot

        if (keyIndex == 0) { 
            map._NFTs.push( MapEntry({ _key: key, _NFT_Value: _NFTvalue }) );            
            map._indexes[key] = map._NFTs.length;        // The entry is stored at length-1, but we add 1 to all indexes and use 0 as a sentinel value
            return true;
        } 
        else {
            map._NFTs[keyIndex - 1]._NFT_Value = _NFTvalue;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1). Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {        
        uint256 keyIndex = map._indexes[key];   // We read and store the key's index to prevent multiple reads from the same storage slot

        if (keyIndex != 0) { 
            // To delete a key-value pair from the _NFTs array in O(1), we swap the entry to delete with the last one in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._NFTs.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.
            MapEntry storage lastEntry = map._NFTs[lastIndex];
            
            map._NFTs[toDeleteIndex] = lastEntry;            // Move the last entry to the index where the entry to delete is
            map._indexes[lastEntry._key] = toDeleteIndex + 1;   // Update the index for the moved entry. All indexes are 1-based
            
            map._NFTs.pop();                     // Delete the slot where the moved entry was stored            
            delete map._indexes[key];              // Delete the index for the deleted slot

            return true;
        } 
        else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._NFTs.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    * Requirements:
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, address, string memory) {
        require(map._NFTs.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._NFTs[index];
        return (entry._key, entry._NFT_Value.owner, entry._NFT_Value._type );
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     * Requirements:
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (address, string memory) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (address, string memory) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return (map._NFTs[keyIndex - 1]._NFT_Value.owner, map._NFTs[keyIndex - 1]._NFT_Value._type); // All indexes are 1-based
    }

    //##############################
    //######  UintToNFTMap  ########
    //##############################

    struct UintToNFTMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing key. O(1).
     * Returns true if the key was added to the map, that is if it was not already present.
     */
    function set(UintToNFTMap storage map, uint256 key, boosterInfo memory _NFT_value) internal returns (bool) {
        return _set(map._inner, bytes32(key), _NFT_value );
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToNFTMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToNFTMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToNFTMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the array, and it may change when more values are added or removed.
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToNFTMap storage map, uint256 index) internal view returns (uint256, address, string memory) {
        (bytes32 key, address _owner, string memory _type) = _at(map._inner, index);
        return (uint256(key), _owner, _type );
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     * Requirements:
     * - `key` must be in the map.
     */
    function get(UintToNFTMap storage map, uint256 key) internal view returns (address,string memory) {
        return _get(map._inner, bytes32(key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToNFTMap storage map, uint256 key, string memory errorMessage) internal view returns (address,string memory) {
        return _get(map._inner, bytes32(key), errorMessage);
    }
}

// Part: BoostersEnumerableSet

/**
 * @dev Library for managing https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive types.
 * @author modified by _astromartian to meet the requirements of SIGH Finance's Booster NFTs
 * Sets have the following properties:
 * - Elements are added, removed, and checked for existence in constant time (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     
 *     using EnumerableSet for EnumerableSet.AddressSet;        // Add the library methods
 *     EnumerableSet.BoosterSet private mySet;                  // Declare a set state variable
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256` (`UintSet`) are supported.
 */
library BoostersEnumerableSet {
    // The Set implementation uses private functions, and user-facing implementations are just wrappers around the underlying Set.

    // ownedBooster contains boostId and type
    struct ownedBooster {
        uint boostId;
        string _type;
    }

    struct Set {
        ownedBooster[] _NFTs;   // ownedBooster containing boostId and category

        // Position of the value in the `values` array, plus 1 because index 0 means a value is not in the set.
        // Mapping from boostId to index
        mapping (uint256 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns true if the value was added to the set, that is if it was not already present.
     */
    function _add(Set storage set, ownedBooster memory newNFT) private returns (bool) {
        if (!_contains(set, newNFT)) {
            set._NFTs.push(newNFT);             
            set._indexes[newNFT.boostId] = set._NFTs.length;  // The value is stored at length-1, but we add 1 to all indexes and use 0 as a sentinel value
            return true;
        } 
        else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns true if the value was removed from the set, that is if it was present.
     */
    function _remove(Set storage set, ownedBooster memory _NFT) private returns (bool) {
        uint256 valueIndex = set._indexes[_NFT.boostId];  // We read and store the value's index to prevent multiple reads from the same storage slot

        if (valueIndex != 0) {
            // To delete an element from the _NFTs array in O(1), we swap the element to delete with the last one in the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._NFTs.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            ownedBooster memory lastvalue = set._NFTs[lastIndex];
            
            set._NFTs[toDeleteIndex] = lastvalue;                 //   Move the last value to the index where the value to delete is
            set._indexes[lastvalue.boostId] = toDeleteIndex + 1;    //   Update the index for the moved value. All indexes are 1 - based

            set._NFTs.pop();              // Delete the slot where the moved value was stored
            delete set._indexes[_NFT.boostId];     // Delete the index for the deleted slot

            return true;
        } 
        else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1). Checks performed based on the boostId 
     */
    function _contains(Set storage set, ownedBooster memory _NFT) private view returns (bool) {
        return set._indexes[_NFT.boostId] != 0;
    }
    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._NFTs.length;
    }


   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the array, and it may change when more values are added or removed.
    * Requirements:
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (ownedBooster memory) {
        require(set._NFTs.length > index, "EnumerableSet: index out of bounds");
        return set._NFTs[index];
    }


    // ###########################################
    // ######## BoosterSet FUNCTIONS ########
    // ###########################################

    // BoosterSet
    struct BoosterSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(BoosterSet storage set, ownedBooster memory _newNFT) internal returns (bool) {
        return _add(set._inner, _newNFT );
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(BoosterSet storage set, ownedBooster memory _NFT) internal returns (bool) {
        return _remove(set._inner, _NFT );
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(BoosterSet storage set, ownedBooster storage _NFT) internal view returns (bool) {
        return _contains(set._inner, _NFT );
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(BoosterSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the array, and it may change when more values are added or removed.
    *
    * Requirements:
    * - `index` must be strictly less than {length}.
    */
    function at(BoosterSet storage set, uint256 index) internal view returns (ownedBooster memory) {
        return _at(set._inner, index) ;
    }
}

// Part: BoostersStringUtils

library BoostersStringUtils {

    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b)  internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }

    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int) {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}

// Part: Context

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

// Part: IERC165

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

// Part: IERC721Receiver

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// Part: ISIGHBoosters

interface ISIGHBoosters {

    // ########################
    // ######## EVENTS ########
    // ########################

    event baseURIUpdated(string baseURI);
    event newCategoryAdded(string _type, uint256 _platformFeeDiscount_, uint256 _sighPayDiscount_, uint256 _maxBoosters);
    event BoosterMinted(address _owner, string _type,string boosterURI,uint256 newItemId,uint256 totalBoostersOfThisCategory);
    event boosterURIUpdated(uint256 boosterId, string _boosterURI);
    event discountMultiplierUpdated(string _type,uint256 _platformFeeDiscount_,uint256 _sighPayDiscount_ );

    event BoosterWhiteListed(uint256 boosterId);
    event BoosterBlackListed(uint256 boosterId);

    // #################################
    // ######## ADMIN FUNCTIONS ########
    // #################################
    
    function addNewBoosterType(string memory _type, uint256 _platformFeeDiscount_, uint256 _sighPayDiscount_, uint256 _maxBoosters) external returns (bool) ;
    function createNewBoosters(address _owner, string[] memory _type,  string[] memory boosterURI) external returns (uint256);
    function createNewSIGHBooster(address _owner, string memory _type,  string memory boosterURI, bytes memory _data ) external returns (uint256) ;
    function _updateBaseURI(string memory baseURI )  external ;
    function updateBoosterURI(uint256 boosterId, string memory boosterURI )  external returns (bool) ;
    function updateDiscountMultiplier(string memory _type, uint256 _platformFeeDiscount_,uint256 _sighPayDiscount_)  external returns (bool) ;

    function blackListBooster(uint256 boosterId) external;
    function whiteListBooster(uint256 boosterId) external;
    // ###########################################
    // ######## STANDARD ERC721 FUNCTIONS ########
    // ###########################################

    function name() external view  returns (string memory) ;
    function symbol() external view  returns (string memory) ;
    function totalSupply() external view  returns (uint256) ;
    function baseURI() external view returns (string memory) ;

    function tokenByIndex(uint256 index) external view  returns (uint256) ;

    function balanceOf(address _owner) external view returns (uint256 balance) ;    // Returns total number of Boosters owned by the _owner
    function tokenOfOwnerByIndex(address owner, uint256 index) external view  returns (uint256) ; //  See {IERC721Enumerable-tokenOfOwnerByIndex}.

    function ownerOfBooster(uint256 boosterId) external view returns (address owner) ; // Returns current owner of the Booster having the ID = boosterId
    function tokenURI(uint256 boosterId) external view  returns (string memory) ;   // Returns the boostURI for the Booster

    function approve(address to, uint256 boosterId) external ;  // A BOOSTER owner can approve anyone to be able to transfer the underlying booster
    function setApprovalForAll(address operator, bool _approved) external;


    function getApproved(uint256 boosterId) external view  returns (address);   // Returns the Address currently approved for the Booster with ID = boosterId
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 boosterId) external;
    function safeTransferFrom(address from, address to, uint256 boosterId) external;
    function safeTransferFrom(address from, address to, uint256 boosterId, bytes memory data) external;

    // #############################################################
    // ######## FUNCTIONS SPECIFIC TO SIGH FINANCE BOOSTERS ########
    // #############################################################

    function getAllBoosterTypes() external view returns (string[] memory);

    function isCategorySupported(string memory _category) external view returns (bool);
    function getDiscountRatiosForBoosterCategory(string memory _category) external view returns ( uint platformFeeDiscount, uint sighPayDiscount );

    function totalBoostersAvailable(string memory _category) external view returns (uint256);
    function maxBoostersAllowed(string memory _category) external view returns (uint256);

    function totalBoostersOwnedOfType(address owner, string memory _category) external view returns (uint256) ;  // Returns the number of Boosters of a particular category owned by the owner address

    function isValidBooster(uint256 boosterId) external view returns (bool);
    function getBoosterCategory(uint256 boosterId) external view returns ( string memory boosterType );
    function getDiscountRatiosForBooster(uint256 boosterId) external view returns ( uint platformFeeDiscount, uint sighPayDiscount );
    function getBoosterInfo(uint256 boosterId) external view returns (address farmer, string memory boosterType,uint platformFeeDiscount, uint sighPayDiscount, uint _maxBoosters );

    function isBlacklisted(uint boosterId) external view returns(bool) ;
//     function getAllBoosterTypesSupported() external view returns (string[] memory) ;

}

// Part: SafeMath

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Part: Strings

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// Part: Counters

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// Part: ERC165

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

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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

// Part: IERC721

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// Part: Ownable

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// Part: IERC721Enumerable

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// Part: IERC721Metadata

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: SIGHBoosters.sol

contract SIGHBoosters is ISIGHBoosters, ERC165,IERC721Metadata,IERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _boosterIds;

    using SafeMath for uint256;
    using Address for address;
    using BoostersEnumerableSet for BoostersEnumerableSet.BoosterSet;
    using BoostersEnumerableMap for BoostersEnumerableMap.UintToNFTMap;
    using Strings for uint256;
    using BoostersStringUtils for string;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    string private _name;
    string private _symbol;
    mapping (uint256 => string) private _BoostURIs;
    string private _baseURI;

    struct boosterCategory {
        bool isSupported;
        uint256 totalBoosters;
        uint256 _platformFeeDiscount;
        uint256 _sighPayDiscount;
        uint256 maxBoosters;
    }
    
    string[] private boosterTypesList ;
    mapping (string => boosterCategory) private boosterCategories;

    mapping(uint => bool) blacklistedBoosters;                                    // Mapping for blacklisted boosters
    mapping (uint256 => string) private _BoosterCategory;
    mapping (uint256 => address) private _BoosterApprovals;                       // Mapping from BoosterID to approved address
    mapping (address => mapping (address => bool)) private _operatorApprovals;    // Mapping from owner to operator approvals
   
    mapping (address => BoostersEnumerableSet.BoosterSet) private farmersWithBoosts;     // Mapping from holder address to their (enumerable) set of owned tokens & categories
    BoostersEnumerableMap.UintToNFTMap private boostersData;                            // Enumerable mapping from token ids to their owners & categories


    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }


    // #################################
    // ######## ADMIN FUNCTIONS ########
    // #################################

    function addNewBoosterType(string memory _type, uint256 _platformFeeDiscount_, uint256 _sighPayDiscount_, uint256 _maxBoosters) public override onlyOwner returns (bool) {
        require(!boosterCategories[_type].isSupported,"BOOSTERS: Type already exists");
        boosterCategories[_type] =  boosterCategory({isSupported: true, totalBoosters:0, _platformFeeDiscount: _platformFeeDiscount_, _sighPayDiscount: _sighPayDiscount_,maxBoosters: _maxBoosters  });
        boosterTypesList.push(_type);
        emit newCategoryAdded(_type,_platformFeeDiscount_,_sighPayDiscount_,_maxBoosters);
        return true;
    }

    function _updateBaseURI(string memory baseURI )  public override onlyOwner {
        _baseURI = baseURI;
        emit baseURIUpdated(baseURI);
     }

    function updateDiscountMultiplier(string memory _type, uint256 _platformFeeDiscount_,uint256 _sighPayDiscount_)  public override onlyOwner returns (bool) {
        require(boosterCategories[_type].isSupported,"BOOSTERS: Type doesn't exist");
        boosterCategories[_type]._platformFeeDiscount = _platformFeeDiscount_;
        boosterCategories[_type]._sighPayDiscount = _sighPayDiscount_;
        emit discountMultiplierUpdated(_type,_platformFeeDiscount_,_sighPayDiscount_ );
        return true;
     }

    function createNewBoosters(address receiver, string[] memory _type,  string[] memory boosterURI) public override onlyOwner returns (uint256) {
        require( _type.length == boosterURI.length, 'Size not equal');
        bytes memory _data;
        uint i;
        for(; i< _type.length; i++) {
            createNewSIGHBooster(receiver, _type[i], boosterURI[i], _data);
        }
        return i;
    }

    function createNewSIGHBooster(address _owner, string memory _type,  string memory boosterURI, bytes memory _data) public override onlyOwner returns (uint256) {
        require(boosterCategories[_type].isSupported,'Not a valid Type');
        require( boosterCategories[_type].maxBoosters > boosterCategories[_type].totalBoosters ,'Max Boosters limit reached');
        require(_boosterIds.current() < 65535, 'Max Booster limit reached');

        _boosterIds.increment();
        uint256 newItemId = _boosterIds.current();

        _safeMint(_owner, newItemId, _type,_data);
        _setBoosterURI(newItemId,boosterURI);
        _setType(newItemId,_type);

        boosterCategories[_type].totalBoosters = boosterCategories[_type].totalBoosters.add(1);

        emit BoosterMinted(_owner,_type,boosterURI,newItemId,boosterCategories[_type].totalBoosters);
        return newItemId;
    }


    
    function updateBoosterURI(uint256 boosterId, string memory boosterURI )  public override onlyOwner returns (bool) {
        require(_exists(boosterId), "Non-existent Booster");
        _setBoosterURI(boosterId,boosterURI);
        return true;
     }



    function blackListBooster(uint256 boosterId) external override onlyOwner {
        require(_exists(boosterId), "Non-existent Booster");
        blacklistedBoosters[boosterId] = true;
        emit BoosterBlackListed(boosterId);
    }

    function whiteListBooster(uint256 boosterId) external override onlyOwner {
        require(_exists(boosterId), "Non-existent Booster");
        require(blacklistedBoosters[boosterId], "Already whitelisted");
        blacklistedBoosters[boosterId] = false;
        emit BoosterWhiteListed(boosterId);
    }

    // ###########################################
    // ######## STANDARD ERC721 FUNCTIONS ########
    // ###########################################

    function name() public view override(IERC721Metadata,ISIGHBoosters) returns (string memory) {
        return _name;
    }

    function symbol() public view override(IERC721Metadata,ISIGHBoosters) returns (string memory) {
        return _symbol;
    }

    // Returns total number of Boosters owned by the _owner
    function balanceOf(address _owner) external view override(IERC721,ISIGHBoosters) returns (uint256 balance) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return farmersWithBoosts[_owner].length();
    }

    //  See {IERC721Enumerable-tokenOfOwnerByIndex}.
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(IERC721Enumerable,ISIGHBoosters) returns (uint256 id) {
        BoostersEnumerableSet.ownedBooster memory _booster = farmersWithBoosts[owner].at(index);
        return _booster.boostId;
    }

    // Returns current owner of the Booster having the ID = boosterId
    function ownerOf(uint256 boosterId) public view override returns (address owner) {
         owner =  ownerOfBooster(boosterId);
         return owner;
    }

    // Returns current owner of the Booster having the ID = boosterId
    function ownerOfBooster(uint256 boosterId) public view override returns (address owner) {
         ( owner, ) =  boostersData.get(boosterId);
         return owner;
    }

    // Returns the boostURI for the Booster
    function tokenURI(uint256 boosterId) public view override(IERC721Metadata,ISIGHBoosters) returns (string memory) {
        require(_exists(boosterId), "Non-existent Booster");
        string memory _boostURI = _BoostURIs[boosterId];
        
        if (bytes(_baseURI).length == 0 && bytes(_boostURI).length > 0) {                                  // If there is no base URI, return the token URI.
            return _boostURI;
        }

        if (bytes(_baseURI).length > 0 && bytes(_boostURI).length > 0) {                                  // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            return string(abi.encodePacked(_baseURI, _boostURI));
        }
        
        if (bytes(_baseURI).length > 0 && bytes(_boostURI).length == 0) {                                  // If there is a baseURI but no tokenURI, concatenate the boosterId to the baseURI.
            return string(abi.encodePacked(_baseURI, boosterId.toString()));
        }

        return boosterId.toString();
    }

    function baseURI() public view override returns (string memory) {
        return _baseURI;
    }

    function totalSupply() public view override(IERC721Enumerable,ISIGHBoosters) returns (uint256) {
        return boostersData.length();
    }

    function tokenByIndex(uint256 index) public view override(IERC721Enumerable,ISIGHBoosters) returns (uint256) {
        (uint256 _boostId, , ) = boostersData.at(index);
        return _boostId;
    }

    // A BOOSTER owner can approve anyone to be able to transfer the underlying booster
    function approve(address to, uint256 boosterId) override(IERC721,ISIGHBoosters) external {
        address _owner = ownerOfBooster(boosterId);
        require(to != _owner, "BOOSTERS: Owner cannot be approved");
        require(_msgSender() == _owner || isApprovedForAll(_owner, _msgSender()),"BOOSTERS: Neither owner nor approved");
        _approve(to, boosterId);
    }

    // Returns the Address currently approved for the Booster with ID = boosterId
    function getApproved(uint256 boosterId) public view override(IERC721,ISIGHBoosters) returns (address) {
        require(_exists(boosterId), "BOOSTERS: Non-existent Booster");
        return _BoosterApprovals[boosterId];
    }

    function setApprovalForAll(address operator, bool _approved) public virtual override(IERC721,ISIGHBoosters) {
        require(operator != _msgSender(), "BOOSTERS: Caller cannot be Approved");
        _operatorApprovals[_msgSender()][operator] = _approved;
        emit ApprovalForAll(_msgSender(), operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view override(IERC721,ISIGHBoosters) returns (bool) {
       return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 boosterId)  public virtual override(IERC721,ISIGHBoosters) {
        safeTransferFrom(from, to, boosterId, "");
    }

    function safeTransferFrom(address from, address to, uint256 boosterId, bytes memory data) public virtual override(IERC721,ISIGHBoosters) {
        require(!blacklistedBoosters[boosterId], "Booster blacklisted");
        require(_isApprovedOrOwner(_msgSender(), boosterId), "BOOSTERS: Neither owner nor approved");
        _safeTransfer(from, to, boosterId, data);
    }


    function transferFrom(address from, address to, uint256 boosterId) public virtual override(IERC721,ISIGHBoosters) {
        require(!blacklistedBoosters[boosterId], "Booster blacklisted");
        require(_isApprovedOrOwner(_msgSender(), boosterId), "BOOSTERS: Neither owner nor approved");
        _transfer(from, to, boosterId);
    }


    // #############################################################
    // ######## FUNCTIONS SPECIFIC TO SIGH FINANCE BOOSTERS ########
    // #############################################################

    // Returns the number of Boosters of a particular category owned by the owner address
    function totalBoostersOwnedOfType(address owner, string memory _category) external view override returns (uint) {
        require(owner != address(0), "SIGH BOOSTERS: zero address query");
        require(boosterCategories[_category].isSupported, "Not valid Type");

        BoostersEnumerableSet.BoosterSet storage boostersOwned = farmersWithBoosts[owner];

        if (boostersOwned.length() == 0) {
            return 0;
        }

        uint ans;

        for (uint32 i=0; i < boostersOwned.length(); i++ ) {
            BoostersEnumerableSet.ownedBooster memory _booster = boostersOwned.at(i);
            if ( _booster._type.equal(_category) ) {
                ans = ans + 1;
            }
        }

        return ans ;
    }

    // Returns farmer address who owns this Booster and its boosterType 
    function getBoosterInfo(uint256 boosterId) external view override returns (address farmer, string memory boosterType, uint platformFeeDiscount, uint sighPayDiscount, uint _maxBoosters ) {
         ( farmer, boosterType ) =  boostersData.get(boosterId);
         platformFeeDiscount = boosterCategories[boosterType]._platformFeeDiscount;
         sighPayDiscount = boosterCategories[boosterType]._sighPayDiscount ;
        _maxBoosters =  boosterCategories[boosterType].maxBoosters ;
    }

    function isCategorySupported(string memory _category) external view override returns (bool) {
        return boosterCategories[_category].isSupported;
    }

    function totalBoostersAvailable(string memory _category) external view override returns (uint256) {
        return boosterCategories[_category].totalBoosters;
    }

    function maxBoostersAllowed(string memory _category) external view override returns (uint256) {
        return boosterCategories[_category].maxBoosters;
    }

    // get Booster Type
    function getBoosterCategory(uint256 boosterId) public view override returns ( string memory boosterType ) {
         ( , boosterType ) =  boostersData.get(boosterId);
    }

    // get Booster Discount Multiplier for a Booster
    function getDiscountRatiosForBooster(uint256 boosterId) external view override returns ( uint platformFeeDiscount, uint sighPayDiscount ) {
        require(_exists(boosterId), "Non-existent Booster");
        platformFeeDiscount =  boosterCategories[getBoosterCategory(boosterId)]._platformFeeDiscount;
        sighPayDiscount =  boosterCategories[getBoosterCategory(boosterId)]._sighPayDiscount;
    }

    // get Booster Discount Multipliers for Booster Category
    function getDiscountRatiosForBoosterCategory(string memory _category) external view override returns ( uint platformFeeDiscount, uint sighPayDiscount ) {
        require(boosterCategories[_category].isSupported,"BOOSTERS: Type doesn't exist");
        platformFeeDiscount =  boosterCategories[_category]._platformFeeDiscount;
        sighPayDiscount =  boosterCategories[_category]._sighPayDiscount;
    }


    function isValidBooster(uint256 boosterId) external override view returns (bool) {
        return _exists(boosterId);
    }
    
    
    // Returns a list containing all the Booster categories currently supported
    function getAllBoosterTypes() external override view returns (string[] memory) {
        return boosterTypesList;
    }   
    
    
//    // Returns a list of BoosterIDs of the boosters owned by the user
//    function getAllBoostersOwned(address user) external view returns(uint[] memory boosterIds) {
//        BoostersEnumerableSet.BoosterSet storage boostersOwned = farmersWithBoosts[user];
//        for (uint i=1; i < boostersOwned.length() ; i++) {
//            BoostersEnumerableSet.ownedBooster memory _booster = boostersOwned.at(i);
//            boosterIds[i] = _booster.boostId;
//        }
//    }

    // returns true is the Booster has been blacklisted. Else returns false
    function isBlacklisted(uint boosterId) external override view returns(bool) {
        return blacklistedBoosters[boosterId];
    }





    // #####################################
    // ######## INTERNAL FUNCTIONS  ########
    // #####################################

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 boosterId, string memory _typeOfBoost, bytes memory _data) internal {
        _mint(to, boosterId, _typeOfBoost);
        require(_checkOnERC721Received(address(0), to, boosterId, _data), "BOOSTERS: Transfer to non ERC721Receiver implementer");
    }


    /**
     * @dev Mints `boosterId` and transfers it to `to`.
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     */
    function _mint(address to, uint256 boosterId, string memory _typeOfBoost) internal  {
        require(to != address(0), "BOOSTERS: Cannot mint to zero address");
        require(!_exists(boosterId), "BOOSTERS: Already minted");

        BoostersEnumerableSet.ownedBooster memory newBooster = BoostersEnumerableSet.ownedBooster({ boostId: boosterId, _type: _typeOfBoost });
        BoostersEnumerableMap.boosterInfo memory newBoosterInfo = BoostersEnumerableMap.boosterInfo({ owner: to, _type: _typeOfBoost });

        farmersWithBoosts[to].add(newBooster);
        boostersData.set(boosterId, newBoosterInfo);

        emit Transfer(address(0), to, boosterId);
    }

    /**
     * @dev Returns whether `boosterId` exists.
     */
    function _exists(uint256 boosterId) internal view returns (bool) {
        return boostersData.contains(boosterId);
    }


    /**
     * @dev Sets `_boosterURI` as the boosterURI of `boosterId`.
     *
     * Requirements:
     *
     * - `boosterId` must exist.
     */
    function _setBoosterURI(uint256 boosterId, string memory _boosterURI) internal  {
        _BoostURIs[boosterId] = _boosterURI;
         emit boosterURIUpdated(boosterId,_boosterURI);
    }

    function _setType(uint256 boosterId, string memory _type) internal virtual {
        require(_exists(boosterId), "Non-existent Booster");
        _BoosterCategory[boosterId] = _type;
    }


    function _approve(address to, uint256 boosterId) private {
        _BoosterApprovals[boosterId] = to;
        emit Approval(ownerOfBooster(boosterId), to, boosterId);
    }

    // Returns whether `spender` is allowed to manage `tokenId`.
    function _isApprovedOrOwner(address spender, uint256 boosterId) internal view returns (bool) {
        require(_exists(boosterId), "Non-existent Booster");
        address owner = ownerOfBooster(boosterId);
        return (spender == owner || getApproved(boosterId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeTransfer(address from, address to, uint256 boosterId, bytes memory _data) internal virtual {
        _transfer(from, to, boosterId);
        require(_checkOnERC721Received(from, to, boosterId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint256 boosterId) internal virtual {
        require(ownerOfBooster(boosterId) == from, "BOOSTERS: Not owned");
        require(to != address(0), "BOOSTERS: Transfer to the zero address");

//        _beforeTokenTransfer(from, to, boosterId);
        _approve(address(0), boosterId);          // Clear approvals from the previous owner
        
        BoostersEnumerableSet.ownedBooster memory _ownedBooster = BoostersEnumerableSet.ownedBooster({boostId: boosterId, _type: _BoosterCategory[boosterId] });

        farmersWithBoosts[from].remove(_ownedBooster);
        farmersWithBoosts[to].add(_ownedBooster);

        BoostersEnumerableMap.boosterInfo memory _boosterInfo = BoostersEnumerableMap.boosterInfo({owner: to, _type: _BoosterCategory[boosterId] });
        boostersData.set(boosterId, _boosterInfo);

        emit Transfer(from, to, boosterId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param boosterId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 boosterId, bytes memory _data) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector( IERC721Receiver(to).onERC721Received.selector, _msgSender(), from, boosterId, _data ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }


//    /**
//     * @dev Hook that is called before any token transfer.
//    */
//    function _beforeTokenTransfer(address from, address to, uint256 boosterId) internal virtual { }


}