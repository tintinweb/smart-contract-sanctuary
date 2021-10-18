/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface BurningMoon is IBEP20{
    function Compound() external;
    function getDividents(address addr) external view returns (uint256);
    function ClaimAnyToken(address token) external payable;
    function ClaimBNB() external;
    function TransferSacrifice(address target, uint256 amount) external;
}
interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}




interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

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
interface IERC721Enumerable
{

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract BurningMoonDividentNFT is ERC165, IERC721, IERC721Metadata ,IERC721Enumerable,Ownable {
    using Address for address;
    // Token name
    string private _name="PocketDoge x BurningMoon";
    // Token symbol
    string private _symbol="PDogeXBM";
    
    string public _baseURI="https://gateway.pinata.cloud/ipfs/";
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;


    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    //Mapping of the tokenIDs of an owner
    mapping(address => uint256[]) private _tokenOfOwner;
    
    //Mapping of the shares of each account based on the rarity of the NFTs they hold
    mapping(address => uint256) public shares;
    mapping(address => uint256) private paidOutShares;


    //The rarity determines the amount of BM you get as reflection 
    //and the worth of the NFT    
    enum Rarity{Common ,Uncommon, Rare, UltraRare, Epic,Legendary,LegendaryShiny}
    struct NFTData{
        string Name;
        string URI;
        Rarity rarity;
    }
    address[] NFTHolders;
    uint256[] ownerID;
    uint256[] NFTValue;
    uint256[] public NFTs;

    NFTData[] NFTPrototypes;

    uint256 public currentValue=3*10**16; //0.03 BNB for first NFT
    
    function OwnerSetValue(uint256 value) external onlyOwner{
        currentValue=value;
    }
    uint8 Taxes=50;//5%

    uint256 constant dividentMagnifier=10**32;
    uint256 profitPerShare;
    uint256 public totalShares;

    function getDividents(address account) public view returns (uint256){
        uint256 fullPayout = profitPerShare * shares[account];
        if(fullPayout<=paidOutShares[account]) return 0;
        return ((fullPayout - paidOutShares[account]) / dividentMagnifier);
    }
    //Set of the token that are curently for sale
    EnumerableSet.UintSet TokenForSale;
    
    BurningMoon private BM;
    IPancakeRouter02 private BMPCS;
    IPancakeRouter02 private TokenPCS;
    IBEP20 private Token;
    function OwnerSetTokenRouter(address Router) external onlyOwner{
        TokenPCS=IPancakeRouter02(Router);
    }
    function OwnerSetBMRouter(address Router) external onlyOwner{
        BMPCS=IPancakeRouter02(Router);
    }
    function OwnerSetToken(address tokenAddress) external onlyOwner{
        Token=IBEP20(tokenAddress);
    }
    function OwnerSetBM(address BMAddress) external onlyOwner{
        BM=BurningMoon(BMAddress);
    }
    //Mainnet
    //address constant BMaddress=0x97c6825e6911578A515B11e25B552Ecd5fE58dbA;
    //address constant PCSaddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //address constant TokenAddress=0xEb6892bB78dE0d5D72EEBf9dF49AFaD78C920dA5;//PocketDoge
    //TestNet
    address constant BMaddress=0x1Fd93329706579516e18ef2B51890F7a146B5b14;
    address constant PCSaddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address constant TokenAddress=0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    constructor() {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
        NFTPrototypes.push(NFTData("Common", "QmP5MbeM2YgdLYDufxBUM13hJfkh6vy29Cu2wCKRLHDgVv", Rarity.Common));
        NFTPrototypes.push(NFTData("Uncommon", "QmS6HAzBVnNVhGH6QSACYM4e17gAHD5ZWG4wpAYRsKxLa2", Rarity.Uncommon));
        NFTPrototypes.push(NFTData("Rare", "QmUAknLMCfmzXRhtHnK8qTGkMg56LXwBxKbYdwSXsb8ask", Rarity.Rare));
        NFTPrototypes.push(NFTData("UltraRare", "Qmbq9whJo8FxMY2GZpzYL2zSEv672m663y16AbuN9k5e1x", Rarity.UltraRare));
        NFTPrototypes.push(NFTData("Epic", "Qmb33oHUEHjSFxukTvWRXMqJHW8jxfmQppUbbfgihqh7tp", Rarity.Epic));
        NFTPrototypes.push(NFTData("Legendary", "QmbpqQDPrSPMcxRisv1LHjEnEm4FkhsHDoEmzaHu1dEhPS", Rarity.Legendary));
        NFTPrototypes.push(NFTData("LegendaryShiny", "QmSX3DfGi8SHngaQyhKBKUPpoPMNSMyWVZPZ6bTmM5Jwej", Rarity.LegendaryShiny));
        BM=BurningMoon(BMaddress);
        
        BMPCS=IPancakeRouter02(PCSaddress);
        TokenPCS=IPancakeRouter02(PCSaddress);
        Token=IBEP20(TokenAddress); 
    }

    bool _isInFunction;
    modifier isInFunction{
        require(!_isInFunction);
        _isInFunction=true;
        _;
        _isInFunction=false;
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //BM Dividents////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    bool isPaying;
    uint256 CurrentAirdropID;

    
    function Airdrop(uint256 count) public{
        _distributeToken();
        uint256 holderLength=holders.length();
        if(count>holderLength)count=holderLength;
        if(CurrentAirdropID>=holderLength) CurrentAirdropID=0;
        for(uint i=0;i<count;i++)
        {
           try this.Payout(holders.at(CurrentAirdropID)){}
           catch{}
            CurrentAirdropID++;
            if(CurrentAirdropID>=holderLength)
                CurrentAirdropID=0;  
        }
    }
    uint8 airdropsPerClaim=10;
    function OwnerSetAirdropsPerClaim(uint8 airdrops) public onlyOwner{
        require(airdrops<=10);
        airdropsPerClaim=airdrops;
    }
    function AccountClaimDividents() external{
        _distributeToken();
        uint256 amount=getDividents(msg.sender);
        require(amount>0,"No payout");
        _payout(msg.sender);
        try this.Airdrop(airdropsPerClaim){}
        catch{}
    }
    function Payout(address account) external isInFunction{
        _payout(account);
    }
    function _payout(address account) private{
        uint256 amount=getDividents(account);
        if(amount==0)return;
        paidOutShares[account]=shares[account]*profitPerShare;
        Token.transfer(account, amount);
    }
    function _distributeBNB(uint amount) private{
        if(amount>address(this).balance)amount=address(this).balance;
        if(amount<=0) return;
            uint256 BMAmount=amount*80/100;
            uint256 TokenAmount=amount*15/100;
            //Sends the sender 15% of the BNB Amount in token
            SwapForToken(TokenAmount,Token,TokenPCS,msg.sender);
            _buyAndSacrificeBM(BMAmount);
    }
    function _buyAndSacrificeBM(uint256 amount)private{
        if(amount==0) return;
        //Buy BM
        address[] memory path = new address[](2);
        path[1] = address(BM);
        path[0] = BMPCS.WETH();
        uint SwapBM=SwapForToken(amount,BM,BMPCS,address(this));
        uint TokenForSender=SwapBM*18/100;
        if(SwapBM==0) return;
        try BM.transfer(msg.sender,TokenForSender){
            SwapBM-=TokenForSender;}catch{}

        try BM.transfer(address(0xdead),SwapBM){}catch{}
    }
    function SwapForToken(uint BNBAmount,IBEP20 token, IPancakeRouter02 router,address Target) private returns(uint256){
        address[] memory path = new address[](2);
        path[1] = address(token);
        path[0] = router.WETH();
        uint256 initialBalance=token.balanceOf(Target);

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:BNBAmount}(
            0,
            path,
            Target,
            block.timestamp
        ){}
        catch{
            (bool sent,)=Target.call{value:BNBAmount}("");
            sent=true;
            return 0;
        }
        return token.balanceOf(Target)-initialBalance;
    }
    
    function _distributeToken() private{
        //If total shares is 0, ignore compound
        if(totalShares==0) return;
        uint256 newDividents=BM.getDividents(address(this));
        if(newDividents<=0) return;

        uint256 InitialBNB=address(this).balance;
        BM.ClaimBNB();
        uint256 newBNB=address(this).balance-InitialBNB;

        uint newBalance=SwapForToken(newBNB,Token,TokenPCS,address(this));
        profitPerShare += ((newBalance * dividentMagnifier) / totalShares);

    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Owner Settings//////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    
    //Changes the BaseURI 
    function OwnerSetBaseURI(string memory newBaseURI) external onlyOwner{
        _baseURI=newBaseURI;
    }

    function OwnerBatchSetURI(string[] memory newURI, uint StartID) external onlyOwner{
        for(uint i=0;i<newURI.length;i++){
        uint ID=i+StartID;
        NFTData memory data=NFTPrototypes[ID];
        data.URI=newURI[i];
        NFTPrototypes[ID]=data;
        }

    }


    function OwnerSetURI(string memory newURI, uint ID) external onlyOwner{
        NFTData memory data=NFTPrototypes[ID];
        data.URI=newURI;
        NFTPrototypes[ID]=data;
    }
    function OwnerSetTaxes(uint8 taxes) external onlyOwner{
        Taxes=taxes;
    }
    function OwnerTransferSacrifice(address target,uint256  amount) external onlyOwner{
        BM.TransferSacrifice(target, amount);
    }
    function OwnerClaimBNB() external isInFunction{
        uint256 amount=address(this).balance;        
        (bool sent,)=owner().call{value:amount}("");
        sent=true;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //NFTTrading//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    

    function Sell(uint256 ID, uint256 value, bool isForSale)external{
        require(_isApprovedOrOwner(msg.sender,ID));
        NFTValue[ID]=value;
        if(isForSale) TokenForSale.add(ID);
        else TokenForSale.remove(ID);
    }
    function SellNextNFT(uint256 value)external{
        for(uint SellID=0;SellID<balanceOf(msg.sender);SellID++)
        {
        uint TokenID=tokenOfOwnerByIndex(msg.sender,SellID);
          if(!isNFTForSale(TokenID)){
              NFTValue[SellID]=value;
              TokenForSale.add(TokenID);
              return;
          }
        }
        revert("No token left to sell");
    }
    function SellRemoveNextNFT()external{
        for(uint SellID=0;SellID<balanceOf(msg.sender);SellID++)
        {
        uint TokenID=tokenOfOwnerByIndex(msg.sender,SellID);
          if(isNFTForSale(TokenID)){
              TokenForSale.remove(TokenID);
              return;
          }
        }
        revert("No token to remove from sale");
    }
    
    //Iterates over all NFTs to find the cheapest NFT in the given Rarity
    function BuyNFTWithRarity(uint8 rarity) external payable{
        uint buyID;
        uint cheapestValue = type(uint).max;
        
        for(uint i=0;i<TokenForSale.length();i++){
            uint NFTID=TokenForSale.at(i);    
            if(NFTs[NFTID]==uint8(rarity)){         
                uint newValue=getValue(NFTID);
                if(newValue<cheapestValue){
                    cheapestValue=newValue;
                    buyID=NFTID;
                }
            }
        }
        require(cheapestValue<type(uint).max,"no NFT for sale in this rarity found");
        BuyNFT(buyID);
    }
    //Iterates over all NFTs to find the cheapest NFT with the given name
    function BuyNFTWIthName(string memory NFTName) external payable{
        uint buyID;
        uint cheapestValue = type(uint).max;
        bytes32 nameHash = keccak256(abi.encodePacked(NFTName));
        for(uint i=0;i<TokenForSale.length();i++){
            uint NFTID=TokenForSale.at(i);    
            if(keccak256(abi.encodePacked(NFTPrototypes[NFTs[NFTID]].Name))==nameHash){         
                uint newValue=getValue(NFTID);
                if(newValue<cheapestValue){
                    cheapestValue=newValue;
                    buyID=NFTID;
                }
            }
        }
        require(cheapestValue<type(uint).max,"no NFT for sale found");
        BuyNFT(buyID);
    }  
        //Iterates over all NFTs to find the cheapest NFT with the given name
    function BuyCheapestNFT() external payable{
        uint buyID;
        uint cheapestValue = type(uint).max;
        for(uint i=0;i<TokenForSale.length();i++){
            uint NFTID=TokenForSale.at(i);    
                uint newValue=getValue(NFTID);
                if(newValue<cheapestValue){
                    cheapestValue=newValue;
                    buyID=NFTID;
            }
        }
        require(cheapestValue<type(uint).max,"no NFT for sale in this rarity found");
        BuyNFT(buyID);
    }  
 
    function BuyMostExpensiveNFT() external payable{
        uint buyID;
        uint mostExpensiveValue = 0;
        for(uint i=0;i<TokenForSale.length();i++){
            uint NFTID=TokenForSale.at(i);    
                uint newValue=getValue(NFTID);
                if(newValue>mostExpensiveValue){
                    mostExpensiveValue=newValue;
                    buyID=NFTID;
            }
        }
        require(mostExpensiveValue>0,"no NFT for sale found");
        BuyNFT(buyID);
    }  
    
    function BuyNFT(uint256 ID) public payable isInFunction{
        //Locked NFTs can't be traded
        require(isNFTForSale(ID),"NFT is Locked");
        uint256 Value=getValue(ID);
        uint256 TaxedValue=Value*(1000-Taxes)/1000;
        require(msg.value>=Value,"not enough BNB to buy NFT");

        address oldOwner=ownerOf(ID);
        bool sent;
        (sent,)=oldOwner.call{value:TaxedValue}("");
        require(sent);
        _transfer(oldOwner,msg.sender,ID);
        
        if(msg.value>Value){
            //transfer back excess funds
            (sent,)=msg.sender.call{value: msg.value-Value}("");
            require(sent);
        }

        _distributeBNB(Value);
    }

    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //NFTPresale//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    bool public SaleOpen;  
    function OwnerSetSale(bool Open) external onlyOwner{
        SaleOpen=Open;
    }
    function OwnerIncreaseNFTMintCount(uint NewCount) external onlyOwner{
        MaxNFTCount=NewCount;
    }
    uint256 public MaxNFTCount=4000;

    event BatchMint(uint Count, uint StartIndex, uint[] PrototypeIDs, address to);
    function PresalePurchase() public payable isInFunction{
        require(!msg.sender.isContract(),"no Contracts allowed");
        require(SaleOpen,"Sale not yet open");
        uint256 presalePurchases=msg.value/currentValue;
        require(presalePurchases>0,"Not enough BNB sent");
        require(NFTHolders.length+presalePurchases<=MaxNFTCount);
        uint[] memory MintedIDs=new uint[](presalePurchases);
        for(uint i=0;i<presalePurchases;i++){
            MintedIDs[i]=_mintRandom(msg.sender,i);
        }
        uint256 remainder=msg.value%presalePurchases;
        if(remainder>0){
            (bool sent,)=msg.sender.call{value:remainder}("");
            require(sent,"send failed");
        }
        _distributeBNB(msg.value-remainder);
        if(presalePurchases>1)
            emit BatchMint(presalePurchases,NFTs.length-presalePurchases,MintedIDs,msg.sender);
    }
    
    function TransferNFTsFrom(address payable oldContract, uint256 count) public onlyOwner{
        BurningMoonDividentNFT oldNFT =BurningMoonDividentNFT(oldContract);
        
        
        for(uint256 i=0;i<count;i++)
        {
            uint currentID=NFTs.length;
            if(currentID<oldNFT.totalSupply())
            {
                address owner=oldNFT.ownerOf(currentID);
                _mint(owner,uint8(oldNFT.NFTs(currentID)));
            }
            else return;
            
        }
    }




    receive() external payable {
        if(msg.sender==address(BMPCS)||msg.sender==address(BM)) 
            return;
        PresalePurchase();
    }

    function _prng(uint256 modulo,uint256 seed) private view returns(uint256) {

        uint256 WBNBBalance = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balance;
        
        //generates a PseudoRandomNumber
        uint256 randomResult = uint256(keccak256(abi.encodePacked(
            WBNBBalance + 
            seed +
            block.timestamp + 
            block.difficulty +
            block.gaslimit
            ))) % modulo;
            
        return randomResult;    
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Public View//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     
    function getSharesOfNFT(uint256 ID) public view returns(uint256){
        require(_exists(ID));
        return 2**(NFTs[ID]);
    }
    function getValue(uint256 ID) public view returns (uint256){
        require(_exists(ID));
        if(NFTValue[ID]==0)   
           return currentValue*getSharesOfNFT(ID);
        
        return NFTValue[ID];
    }
    function getNFTInfo(uint256 ID) public view returns(string memory name_, string memory uri_, address holder_, Rarity rarity){
        NFTData memory data=NFTPrototypes[NFTs[ID]];
        return(data.Name, data.URI, NFTHolders[ID], data.rarity);
    }
    function getNFTForSaleAt(uint256 ID) public view returns(uint){
        return TokenForSale.at(ID);
    }  
    function isNFTForSale(uint256 NFTID) public view returns (bool){
        require(_exists(NFTID),"NFT doesn't exist");
        return TokenForSale.contains(NFTID);
    }   
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //ERC721//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function transferFrom(address from, address to, uint256 tokenId) external override{
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override{
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override{
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    

    function getUniqueCountOfRarity(uint8 rarity, address account) public view returns(uint){
        uint[] memory counts=NFTHold[account];
        uint count;
        for(uint i=0;i<counts.length;i++){
            if(uint8(NFTPrototypes[NFTs[i]].rarity)==rarity){
                if(counts[i]>0)
                count++;
            }
        }
        return count; 
    }
    function getTotalCountOfRarity(uint8 rarity, address account) public view returns(uint){
        uint[] memory counts=NFTHold[account];
        uint count;
        for(uint i=0;i<counts.length;i++){
            if(uint8(NFTPrototypes[NFTs[i]].rarity)==rarity)
            count+=counts[i];
        }
        return count; 
    }
    function getUniqueCount(address account) public view returns(uint){
        uint[] memory counts=NFTHold[account];
        uint count;
        for(uint i=0;i<counts.length;i++){
            if(counts[i]>0)count++;
        }
        return count; 
    }

    event Mint(address to, uint ID, uint PrototypeID);
    uint public MintedCommon;
    uint public MintedUncommon;
    uint public MintedRare;
    uint public MintedUltraRare;
    uint public MintedEpic;
    uint public MintedLegendary;
    uint public MintedLegendaryShiny;
    
    mapping (address=>uint[]) NFTHold;
    function _setNFTHold(address account, uint ID, bool Add) private{
        uint[] memory AccountNFTs=NFTHold[account];
        if(AccountNFTs.length==0) AccountNFTs=new uint[](NFTPrototypes.length);

        if(Add) AccountNFTs[ID]++;
        else AccountNFTs[ID]--;

        NFTHold[account]=AccountNFTs;
    }


    function _mintRandom(address to, uint seed) private returns (uint){
        uint value=_prng(2000, seed);
        Rarity rarity;
        if(value<5){
            rarity=Rarity.Legendary;
            MintedLegendaryShiny++;
        } 
        else if(value<25){    
           rarity=Rarity.Legendary; 
           MintedLegendary++;
        }
        else if(value<100){   
             rarity=Rarity.Epic;
             MintedEpic++; 
        }
        else if(value<250){    
           rarity=Rarity.UltraRare; 
           MintedUltraRare++;
        }
        else if(value<500){   
           rarity=Rarity.Rare; 
           MintedRare++;
        }else if(value<1000){    
            rarity=Rarity.Uncommon;
            MintedUncommon++;
        }else{                  
            rarity=Rarity.Common;
            MintedCommon++;
        }
        return _mint(to,uint8(rarity));

    }
    function _mint(address to, uint8 rarity) private returns(uint){
        
        uint256 ID=NFTHolders.length;
        NFTs.push(rarity);
        ownerID.push(0);
        NFTHolders.push(to);
        _AddNFT(to,ID);
        NFTValue.push(0);
        
        emit Transfer(address(0),to,ID);
        emit Mint(to, ID, uint8(rarity));
        return uint8(rarity);
    }
    
    
    
    
    
    
    function _transfer(address from, address to, uint256 tokenId) private {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _RemoveNFT(from, tokenId);
        _AddNFT(to,tokenId);
        TokenForSale.remove(tokenId);
        NFTValue[tokenId]=0;
        emit Transfer(from, to, tokenId);
    }
    EnumerableSet.AddressSet holders;
        //Adds NFT during transfer
    function _AddNFT(address account, uint256 ID) private{
        //the holderID of the NFT will be the last index of the ownerIDs
        ownerID[ID]=balanceOf(account);
        //the new NFT will be added as the last NFT of the holder
        _tokenOfOwner[account].push(ID);
        if(_tokenOfOwner[account].length==1)
            holders.add(account);
        NFTHolders[ID]=account;
        //pays out dividents and sets new shares
        if(getDividents(account)>0) _payout(account);
        _setNFTHold(account,NFTs[ID],true);
        uint NFTShares=getSharesOfNFT(ID);
        shares[account]+= NFTShares;
        totalShares+=NFTShares;
        
        paidOutShares[account]=shares[account]*profitPerShare;

    }
    //Removes NFT during transfer
    function _RemoveNFT(address account, uint256 ID) private{
        //the token the holder holds
        uint256[] memory IDs=_tokenOfOwner[account];
        //the Index of the token to be removed
        uint256 TokenIndex=ownerID[ID];
        //If token isn't the last token, reorder token
        if(TokenIndex<IDs.length-1){
            uint256 lastID=IDs[IDs.length-1];
            _tokenOfOwner[account][TokenIndex]=lastID;
        }
        //Remove_ the Last token ID
        _tokenOfOwner[account].pop();
        if(_tokenOfOwner[account].length==0)
            holders.remove(account);
        //pays out dividents and sets new shares
        if(getDividents(account)>0) _payout(account);
        _setNFTHold(account,NFTs[ID],false);
        uint NFTShares=getSharesOfNFT(ID);
        
        shares[account]-=NFTShares;
        totalShares-=NFTShares;
    
        paidOutShares[account]=shares[account]*profitPerShare;
        //doesn't remove token, token gets transfered by Add token and therefore removed
    }
    
    
    //the total Supply is the same as the Length of holders
    function totalSupply() external override view returns (uint256){
        return NFTHolders.length;
    }
    //Index is always = token ID
    function tokenByIndex(uint256 _index) external override view returns (uint256){
        require(_exists(_index));
        return _index;
    }
    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = NFTHolders[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    //returns the NFT ID of the owner at position
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public override view returns (uint256){
        return _tokenOfOwner[_owner][_index];
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return NFTHolders.length>tokenId;
    }
    
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    } 
    
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _tokenOfOwner[owner].length;
    }


    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
  //  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
  //      string memory currentURI=NFTs[tokenId].URI;
  //      if(keccak256(abi.encodePacked((currentURI))) == keccak256(abi.encodePacked(("")))) return baseURI;
  //      return NFTs[tokenId].URI;
  //  }

    function tokenURIOfPrototype(uint8 rarity) public view returns (string memory){
        string memory _tokenURI = NFTPrototypes[rarity].URI;
        string memory base = baseURI();
        return string(abi.encodePacked(base, _tokenURI));
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = NFTPrototypes[NFTs[tokenId]].URI;
        string memory base = baseURI();
        return string(abi.encodePacked(base, _tokenURI));

    }




    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
}