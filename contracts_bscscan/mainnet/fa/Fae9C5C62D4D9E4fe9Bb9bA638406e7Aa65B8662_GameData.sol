/**
 *Submitted for verification at BscScan.com on 2022-01-24
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
     //查询用户某个id的资产拥有的总量
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
     //多个地址多个id资产返回多个用户多个资产的数值
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
    //from发出地址 to接收地址 id资产类别 amount要转出的数量 data可以默认为空
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
     //批量转账 from发出地址 to接收地址 ids资产类别数组 amounts不同类别资产转出的不同数量 data转账时附带的数据
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    function mintNftForTrading(address receiver,uint256 assetId,uint256 amount) external;
    function burnNftForTrading(address from,uint256 assetId,uint256 amount) external;
}

interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

interface IGetInfo{
    function bossTaxRate(uint256 bosId) external view returns(uint256);
    function workerBasePower(uint256 worId) external view returns(uint256);
    function landBasePower(uint256 lanId) external view returns(uint256);
    function pickBasePower(uint256 picId) external view returns(uint256);
    function erc20ForBossPercent(uint256 amo) external view returns(uint256);
    function erc20ForLandAddPower(uint256 amo) external view returns(uint256);
    function erc20ForWorkerAddPower(uint256 amo) external view returns(uint256);
    function upgradeId(uint256 oId) external view returns(uint256);
    function destoryAddress() external view returns(address);
    
}


interface ITools{
    struct Boss{
        uint256 id;
        address holder;
        //质押土地数量
        uint256 stakingLand;
        //质押mpc数量
        uint256 erc20ForBoss;
        //质押mpc时间
        uint256 stakingERC20Time;
        //税率
        uint256 taxRate;
        //算力加成
        uint256 addPercentagePower;
    }
    
    struct Land{
        uint256 id;
        uint256 bossId;
        address holder;
        //质押的worker数量
        uint256 stakingWorker;
        //质押的mpc数量
        uint256 erc20ForLand;
        //质押mpc的时间
        uint256 stakingERC20Time;
        //计算收益时的负债
        uint256 nftDebt;
        //算力加成
        uint256 addPower;
        //提取开始时间点
        uint256 withTime;
    }

    struct Worker{
        uint256 id;
        uint256 bossId;
        uint256 landId;
        address holder;
        //质押的mpc数量
        uint256 erc20ForWorker;
        //质押mpc的时间
        uint256 stakingERC20Time;
        //
        uint256 nftDebt;
        //
        uint256 totalPower;
        //提取开始时间点
        uint256 withTime;
    }

    struct Pick{
        uint256 id;
        uint256 workerId;
        address holder;
    }

    struct User{
        uint256[] stakingBossForUserIds;
        uint256[] stakingLandForUserIds;
        uint256[] stakingWorkerForUserIds;
        uint256[] stakingPickForUserIds;
        uint256   rewardDebt;
        uint256   sync;
        uint256   boss;
    }
}

interface IGameData{

    function stakingBoss(uint256 bosId) external view returns(uint256 id,address hol,uint256 lan,uint256 erc20,uint256 erc20Time,
        uint256 rate,uint256 percent);
    function stakingLand(uint256 lanId) external view returns(uint256 id,uint256 bosId,address hol,uint256 wor,uint256 erc20,
        uint256 erc20Time,uint256 debt,uint256 addPow,uint256 withtime);
    function stakingWorker(uint256 worId) external view returns(uint256 id,uint256 bosId,uint256 lanId,address hol,uint256 erc20,
        uint256 erc20Time,uint256 debt,uint256 toPow,uint256 withtime);
    function stakingPick(uint256 picId) external view returns(uint256 id,uint256 worId,address holder);

    function getAllBossIds() external view returns(uint256[] memory bossIds);
    function getUserInfo(address customer) external view returns(uint256[] memory bos,uint256[] memory lan,uint256[] memory
        wor,uint256 debt,uint256 syn,uint256 bosAmount);
    function getBossSubordinateLand(uint256 bosId)external view returns(uint256[] memory sLand,uint256[] memory sWorker);
    function getLandSubordinateWorker(uint256 lanId) external  view returns(uint256[] memory);
    function getWorkerSubordinatePick(uint256 worId) external  view returns(uint256[] memory);
    function getWorkerIncome(uint256 worId) external view returns(uint256 worIn,uint256 bosIn);
    function getLandIncome(uint256 lanId) external view returns(uint256);
    function getBossIncome(uint256 bosId) external view returns(uint256);

    function updateWorkerIncome(uint256 worId)external;
    function updateLandIncome(uint256 lanId)external;
    function updateBossIncome(uint256 bosId)external;

    function createBoss(address customer,uint256 assetId,uint256 rate) external  returns(uint256 bosId);
    function createLand(address customer,uint256 assetId,uint256 bosId,uint256 apo) external  returns(uint256 lanId);
    function createWorker(address customer,uint256 assetId,uint256 lanId,uint256 toPow) external  returns(uint256 worId);
    function createPick(address customer,uint256 worId,uint256 assetId) external  returns(uint256 picId);

    function deleteBoss(uint256 bosId) external;
    function deleteLand(uint256 lanId) external;
    function deleteWorker(uint256 worId) external;
    function deletePick(uint256 picId) external;

    function updatePower(uint256 id,uint256 worId,uint256 power) external;
    function updateErc20Info(uint256 id,uint256 stId,uint256 amount,uint256 power) external;
    // function updateToolsForWorker(uint256 worId,uint256 str) external;
    function updateUserDebt(uint256 id,address customer,uint256 with) external;
    function addRecommend(address customer) external;
    function withdrawErc20ForUser(uint256 id,address customer,uint256 amount) external;
    function updateBossIdForLandAndWorker(uint256 lanId,uint256 worId)external;
}

contract GameData is IGameData,ITools,ERC1155Holder{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minerList;
    mapping(address=>User) userInfo;
    Boss[] public override stakingBoss;
    uint256[] allBossIds;
    Land[] public override stakingLand;
    Worker[] public override stakingWorker;
    Pick[] public override stakingPick;

    mapping(uint256=>uint256[])  bossSubordinateLand;
    mapping(uint256=>uint256[])  bossSubordinateWorker;
    mapping(uint256=>uint256[])  landSubordinateWorker;
    mapping(uint256=>uint256[])  workerSubordinatePick;

    mapping(uint256=>uint256) allBossIdIndex;
    mapping(uint256=>uint256) bossSubordinateLandIndex;
    mapping(uint256=>uint256) bossSubordinateWorkerIndex;
    mapping(uint256=>uint256) landSubordinateWorkerIndex;
    mapping(uint256=>uint256) workerSubordinatePickIndex;

    mapping(uint256=>uint256) bossIdOfUserIndex;
    mapping(uint256=>uint256) landIdOfUserIndex;
    mapping(uint256=>uint256) workerIdOfUserIndex;
    mapping(uint256=>uint256) pickIdOfUserIndex;

    uint256 public perBlockMint;//每个区块释放多少
    uint256 public startBlock;//开始挖矿的区块
    uint256 public lastUpdateBlock;//最新更新每份算力的时间
    uint256 public accPerReward;//每份算力截止目前的收益
    uint256 public accPerRewardForLand;
    uint256 public lastUpdateBlockForLand;

    uint256 public  wholenetPower;
    uint256 public  totalStakingErc20;
    uint256 public  totalWorker;
    address token1155;
    address token20;
    address destoryAddress;
    address manager;

    constructor(){
        manager = msg.sender;
        addMinerList(msg.sender);
        createBoss(address(0),0,0);
        createLand(address(0),0,0,0);
        createWorker(address(0),0,0,0);
        createPick(address(0),0,0);
    }

    modifier onlyManager(){
        require(manager == msg.sender,"GameData:No permit");
        _;
    }

    function changeManager(address manage) public onlyManager{
        manager = manage;
    }

    modifier onlyUpdate(){
        require(isMinerList(msg.sender)==true,"GameData:No permit");
        _;
    }

    function addMinerList(address pool) public onlyManager returns(bool){
        require(pool != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_minerList, pool);
    }

    function isMinerList(address miner) internal view returns (bool) {
        return EnumerableSet.contains(_minerList, miner);
    }

    function getAllBossIds() public override view returns(uint256[] memory bossIds){
        bossIds = allBossIds;
    }

    function setTokenAddress(address token15,address token2,address destory) public onlyManager{
        token1155 = token15;
        token20 = token2;
        destoryAddress = destory;
    }

    function setMintInfo(uint256 start,uint256 blockMint) public onlyManager{
        startBlock = start;
        perBlockMint = blockMint;
    }

    function getBlockNumber() public view returns(uint256){
        return block.number;
    }

    function getBossSubordinateLand(uint256 bosId) public override view returns(uint256[] memory sLand,uint256[] memory sWorker){
        sLand = bossSubordinateLand[bosId];
        sWorker = bossSubordinateWorker[bosId];
    }
    
    function getLandSubordinateWorker(uint256 lanId) public override view returns(uint256[] memory){
        return landSubordinateWorker[lanId];
    }
    
    function getWorkerSubordinatePick(uint256 worId) public override view returns(uint256[] memory){
        return workerSubordinatePick[worId];
    }

    function getUserInfo(address customer) public override view returns(uint256[] memory bos,uint256[] memory lan,uint256[] memory
        wor,uint256 debt,uint256 syn,uint256 bosAmount){
            User storage user = userInfo[customer];
            bos = user.stakingBossForUserIds;
            lan = user.stakingLandForUserIds;
            wor = user.stakingWorkerForUserIds;
            syn = user.sync;
            debt = user.rewardDebt;
            bosAmount = user.boss;
    }

    function getCurrentAccPerReward() public view returns(uint256){
        uint256 num = block.number.sub(lastUpdateBlock);
        if(num>0 && wholenetPower > 0){
            uint256 current = num.mul(perBlockMint).div(wholenetPower).mul(82).div(100);
            return accPerReward.add(current);
        }else{
            return accPerReward;
        }
    }

    function getCurrentAccForland() public view returns(uint256){
        uint256 num = block.number.sub(lastUpdateBlockForLand);
        if(num>0 && totalWorker > 1){
            uint256 current = num.mul(perBlockMint).div(totalWorker).mul(18).div(100);
            return accPerRewardForLand.add(current);
        }else{
            return accPerRewardForLand;
        }
    }

    function getWorkerIncome(uint256 worId) public override view returns(uint256 worIn,uint256 bosIn){
        Worker storage wor = stakingWorker[worId];
        uint256 currentPerReward = getCurrentAccPerReward();
        uint256 totalIncome = wor.totalPower.mul(currentPerReward).sub(wor.nftDebt);
        if(wor.bossId>0){
            Boss storage bos = stakingBoss[wor.bossId]; 
            uint256 surRate = 100 - bos.taxRate;
            worIn = totalIncome.mul(surRate).div(100);
            bosIn = totalIncome.mul(bos.taxRate).div(100);
        }else{
            worIn = totalIncome;
            bosIn = 0;
        }
    }

    function getLandIncome(uint256 lanId) public override view returns(uint256){
        Land storage lan = stakingLand[lanId];
        uint256 current = getCurrentAccForland();
        if(lan.stakingWorker>0){
            uint256 total = lan.stakingWorker.mul(current);
            return total.sub(lan.nftDebt);
        }else{
            return 0;
        }
    }

    function getBossIncome(uint256 bosId) public override view returns(uint256){
        uint256[] memory wor = bossSubordinateWorker[bosId];
        uint256 reward = 0;
        for (uint i = 0; i < wor.length; i++) {
            if(wor[i]>0){
                (,uint256 bosIn) = getWorkerIncome(wor[i]);
                reward = reward.add(bosIn);
            }
        }
        return reward;
    }

    function updateWorkerIncome(uint256 worId) public override onlyUpdate{
        updateFarm();
        Worker storage wor = stakingWorker[worId]; 
        User storage userWor = userInfo[wor.holder];
        (uint256 worIn,uint256 bosIn) = getWorkerIncome(worId);
        if(wor.bossId>0){
            Boss storage bos = stakingBoss[wor.bossId];
            User storage userBos = userInfo[bos.holder];
            userBos.sync = userBos.sync.add(bosIn);
        }
        userWor.sync = userWor.sync.add(worIn);
    }

    function updateLandIncome(uint256 lanId) public override onlyUpdate{
        updateFarmForLand();
        Land storage lan = stakingLand[lanId];
        User storage user = userInfo[lan.holder];
        uint256 income = getLandIncome(lanId);
        user.sync = user.sync.add(income);
    }

    function updateBossIncome(uint256 bosId) public override onlyUpdate{
        Boss storage bos = stakingBoss[bosId];
        User storage user = userInfo[bos.holder];
        uint256[] memory wor = bossSubordinateWorker[bosId];
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                (,uint256 bosIn) = getWorkerIncome(wor[i]);
                user.sync = user.sync.add(bosIn);
                Worker storage work = stakingWorker[wor[i]];
                work.nftDebt = work.nftDebt.add(bosIn);
            }
        }
    }

    function updateFarm() public {
        if(block.number<startBlock){
            return ;
        }
        if(block.number < lastUpdateBlock){
          return ;
        }
        if(wholenetPower == 0){
          lastUpdateBlock = block.number;
          return;
        }
        uint256 totalReward = perBlockMint.mul(block.number.sub(lastUpdateBlock)).mul(82).div(100);
        if(totalReward>0){
            uint256 transition = totalReward.div(wholenetPower);
            accPerReward = accPerReward.add(transition);
            lastUpdateBlock = block.number;
        }
    }
    
    function updateFarmForLand() public {
        if(block.number<startBlock){
            return ;
        }
        if(block.number < lastUpdateBlockForLand){
          return ;
        }
        if(wholenetPower == 0){
          lastUpdateBlockForLand = block.number;
          return;
        }
        uint256 totalReward = perBlockMint.mul(block.number.sub(lastUpdateBlockForLand)).mul(18).div(100);
        if(totalReward>0){
            uint256 transition = totalReward.div(totalWorker);
            accPerRewardForLand = accPerRewardForLand.add(transition);
            lastUpdateBlockForLand = block.number;
        }
    }

    function createBoss(address customer,uint256 assetId,uint256 rate) public override onlyUpdate returns(uint256 bosId){
        User storage user = userInfo[customer];
        bosId = stakingBoss.length;
        Boss memory bos = Boss({id:assetId,holder:customer,stakingLand:0,erc20ForBoss:0,stakingERC20Time:0,taxRate:rate,
            addPercentagePower:0});
        stakingBoss.push(bos);
        allBossIdIndex[bosId] = allBossIds.length;
        allBossIds.push(bosId);
        bossIdOfUserIndex[bosId] = user.stakingBossForUserIds.length;
        user.stakingBossForUserIds.push(bosId);
        user.boss = 1;
    }

    function createLand(address customer,uint256 assetId,uint256 bosId,uint256 apo) public override onlyUpdate returns(uint256 lanId){
        updateFarmForLand();
        User storage user = userInfo[customer];
        lanId = stakingLand.length;
        Land memory lan = Land({id:assetId,bossId:bosId,holder:customer,stakingWorker:0,erc20ForLand:0,stakingERC20Time:0,
                nftDebt:accPerRewardForLand,addPower:apo,withTime:block.timestamp});
        stakingLand.push(lan);
        landIdOfUserIndex[lanId] = user.stakingLandForUserIds.length;
        user.stakingLandForUserIds.push(lanId);
        if(bosId > 0){
            Boss storage bos = stakingBoss[bosId];
            bos.stakingLand = bos.stakingLand + 1;
            bossSubordinateLandIndex[lanId] = bossSubordinateLand[bosId].length;
            bossSubordinateLand[bosId].push(lanId);
        }
    }

    function createWorker(address customer,uint256 assetId,uint256 lanId,uint256 toPow) public override onlyUpdate returns(uint256 worId){
        updateFarm();
        updateLandIncome(lanId);
        Land storage lan = stakingLand[lanId];
        User storage user = userInfo[customer];
        worId = stakingWorker.length;
        Worker memory work = Worker({id:assetId,bossId:lan.bossId,landId:lanId,holder:customer,erc20ForWorker:0,stakingERC20Time:0,
            nftDebt:toPow.mul(accPerReward),totalPower:toPow,withTime:block.timestamp});
        stakingWorker.push(work); 
        if(lan.bossId > 0){
            bossSubordinateWorkerIndex[worId] = bossSubordinateWorker[lan.bossId].length;
            bossSubordinateWorker[lan.bossId].push(worId);
        }
        landSubordinateWorkerIndex[worId] = landSubordinateWorker[lanId].length;
        landSubordinateWorker[lanId].push(worId);
        workerIdOfUserIndex[worId] = user.stakingWorkerForUserIds.length;
        user.stakingWorkerForUserIds.push(worId);
        wholenetPower = wholenetPower.add(toPow);
        totalWorker = totalWorker.add(1);
        lan.stakingWorker = lan.stakingWorker+1;
        lan.nftDebt = lan.stakingWorker.mul(accPerRewardForLand);
    }

    function createPick(address customer,uint256 worId,uint256 assetId) public override onlyUpdate  returns(uint256 picId){
        picId = stakingPick.length;
        Pick memory pic = Pick({id:assetId,workerId:worId,holder:customer});
        stakingPick.push(pic);
        workerSubordinatePickIndex[picId] = workerSubordinatePick[worId].length;
        workerSubordinatePick[worId].push(picId);
        User storage user =userInfo[customer];
        pickIdOfUserIndex[picId] = user.stakingPickForUserIds.length;
        user.stakingPickForUserIds.push(picId);
    }

    function deleteBoss(uint256 bosId) public override onlyUpdate{
        Boss storage bos = stakingBoss[bosId];
        User storage user = userInfo[bos.holder];
        user.sync = user.sync.add(getBossIncome(bosId));
        uint256[] memory sland = bossSubordinateLand[bosId];
        for(uint i=0; i<sland.length; i++){
            if(sland[i]>0){
                Land storage lan = stakingLand[sland[i]];
                lan.bossId = 0;
            }
        }
        uint256[] memory sWorker = bossSubordinateWorker[bosId];
        for(uint i=0; i<sWorker.length; i++){
            if(sWorker[i]>0){
                //updateWorkerAndComRate(worId);
                Worker storage work = stakingWorker[sWorker[i]];
                work.bossId = 0;
            }
        }
        user.boss = 0;    
        IERC1155(token1155).safeTransferFrom(address(this),bos.holder,bos.id,1,"");
        delete stakingBoss[bosId];
        delete bossSubordinateLand[bosId];
        delete bossSubordinateWorker[bosId];
        delete allBossIds[allBossIdIndex[bosId]];
        delete user.stakingBossForUserIds[bossIdOfUserIndex[bosId]];
    }

    function deleteLand(uint256 lanId) public override onlyUpdate{
        updateLandIncome(lanId);
        Land storage lan = stakingLand[lanId];
        User storage user = userInfo[lan.holder];
        IERC1155(token1155).safeTransferFrom(address(this), lan.holder, lan.id, 1, "");
        uint256[] memory middle = landSubordinateWorker[lanId];
        for(uint i=0; i<middle.length; i++){
            if(middle[i]>0){
                deleteWorker(middle[i]);
            }
        }
        if(lan.bossId > 0){
            Boss storage bos = stakingBoss[lan.bossId];
            bos.stakingLand = bos.stakingLand.sub(1);
            uint256 bosId = lan.bossId;
            uint256 bosIndex = bossSubordinateLandIndex[lanId];
            delete bossSubordinateLand[bosId][bosIndex];
        }
        delete stakingLand[lanId];
        delete landSubordinateWorker[lanId];
        delete user.stakingLandForUserIds[landIdOfUserIndex[lanId]];
    }

    function deleteWorker(uint256 worId) public override onlyUpdate{
        Worker storage work = stakingWorker[worId];
        updateLandIncome(work.landId);
        User storage user =userInfo[work.holder];
        IERC1155(token1155).safeTransferFrom(address(this), work.holder, work.id, 1, "");
        Land storage lan = stakingLand[work.landId];
        lan.stakingWorker = lan.stakingWorker.sub(1);
        lan.nftDebt = lan.stakingWorker.mul(accPerRewardForLand);
        totalWorker = totalWorker.sub(1);
        uint256[] memory middle = workerSubordinatePick[worId];
        for(uint i=0; i<middle.length; i++){
            if(middle[i]>0){
                deletePick(middle[i]);
            }
        }
        uint256 lanId = work.landId;
        uint256 bosId = work.bossId;
        uint256 lanIndex = landSubordinateWorkerIndex[worId];
        uint256 bosIndex = bossSubordinateWorkerIndex[worId];
        uint256 userIndex = workerIdOfUserIndex[worId];
        delete landSubordinateWorker[lanId][lanIndex];
        delete workerSubordinatePick[worId];
        if(bosId>0){
            delete bossSubordinateWorker[bosId][bosIndex];
        }      
        delete user.stakingWorkerForUserIds[userIndex];
        delete stakingWorker[worId];
    }

    function deletePick(uint256 picId) public override onlyUpdate {
        Pick storage pic = stakingPick[picId];
        User storage user =userInfo[pic.holder];
        uint256 worId = pic.workerId;
        uint256 index = workerSubordinatePickIndex[picId];
        IERC1155(token1155).safeTransferFrom(address(this), pic.holder, pic.id, 1, "");
        delete stakingPick[picId];
        delete workerSubordinatePick[worId][index];
        delete user.stakingPickForUserIds[pickIdOfUserIndex[picId]];
    }

    function updatePower(uint256 id,uint256 worId,uint256 power) public override onlyUpdate{
        Worker storage work = stakingWorker[worId];
        if (id==0) {
            work.totalPower = work.totalPower.add(power);
            wholenetPower = wholenetPower.add(power);
            work.nftDebt = work.totalPower.mul(accPerReward);
        } else {
            work.totalPower = work.totalPower.sub(power);
            wholenetPower = wholenetPower.sub(power);
            work.nftDebt = work.totalPower.mul(accPerReward);
        }
    }

    function updateErc20Info(uint256 id,uint256 stId,uint256 amount,uint256 power) public override onlyUpdate{
        if(id==0){
            Boss storage bos = stakingBoss[stId];
            totalStakingErc20 = totalStakingErc20.sub(bos.erc20ForBoss).add(amount);
            bos.erc20ForBoss = amount;
            bos.addPercentagePower = power;  
            bos.stakingERC20Time = block.timestamp;
        }else if(id==1){
            Land storage lan = stakingLand[stId];
            totalStakingErc20 = totalStakingErc20.sub(lan.erc20ForLand).add(amount);
            lan.erc20ForLand = amount;
            lan.addPower = power;
            lan.stakingERC20Time = block.timestamp;
        }else{
            Worker storage work = stakingWorker[stId];
            totalStakingErc20 = totalStakingErc20.sub(work.erc20ForWorker).add(amount);
            work.erc20ForWorker = amount;
            work.stakingERC20Time = block.timestamp;
        }
    }

    function updateBossIdForLandAndWorker(uint256 lanId,uint256 worId) public override onlyUpdate{
        if(lanId>0){
            Land storage lan = stakingLand[lanId];
            Boss storage bos = stakingBoss[lan.bossId];
            bos.stakingLand = bos.stakingLand.sub(1);
            uint256 bosIndex = bossSubordinateLandIndex[lanId];
            delete bossSubordinateLand[lan.bossId][bosIndex];
            lan.bossId = 0;
        }
        if(worId>0){
            Worker storage wor = stakingWorker[worId];
            uint256 bosIndex = bossSubordinateWorkerIndex[worId];
            delete bossSubordinateWorker[wor.bossId][bosIndex];
            wor.bossId = 0;
        }
    }

    function addRecommend(address customer) public override onlyUpdate {
        User storage user = userInfo[customer];
        user.sync = user.sync.add(2e18);
    }

    function updateUserDebt(uint256 id,address customer,uint256 with) public override onlyUpdate{
        User storage user = userInfo[customer];
        if(id==0){
            user.rewardDebt = user.rewardDebt.add(with);
        }else{
            user.rewardDebt = 0;
        }
    }

    function withdrawErc20ForUser(uint256 id,address customer,uint256 amount) public override onlyUpdate{
        if (id==0) {
            require(IERC20(token20).transfer(customer, amount),"GameData:Transfer failed");
        } else {
            uint256 withAmount = 0;
            withAmount = amount.mul(90).div(100);
            require(IERC20(token20).transfer(customer, withAmount),"GameData:Transfer failed");
            require(IERC20(token20).transfer(destoryAddress, amount.mul(10).div(100)),"GameData:Transfer failed");
        }
    }

}

contract GetInfo is IGetInfo{
    using SafeMath for uint256;
    mapping(uint256=>uint256) public override bossTaxRate;
    mapping(uint256=>uint256) public override workerBasePower;
    mapping(uint256=>uint256) public override pickBasePower;
    mapping(uint256=>uint256) public override landBasePower;

    mapping(uint256=>uint256) public override erc20ForBossPercent;
    mapping(uint256=>uint256) public override erc20ForLandAddPower;
    mapping(uint256=>uint256) public override erc20ForWorkerAddPower;
    mapping(uint256=>uint256) public override upgradeId;
    uint256 nftWithTime = 432000;
    uint256 erc20WithTime = 604800;
    address gameData;
    address token20;
    address public override destoryAddress;
    address manager;

    constructor(){
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(manager == msg.sender,"Staking:No permit");
        _;
    }

    function changeManager(address manage) public onlyManager{
        manager = manage;
    }

    function setTokenAddress(address game,address token,address destory) public onlyManager{
        gameData = game;
        token20 = token;
        destoryAddress = destory;
    }

    function setTime(uint256 erc20Time,uint256 nftTime) public onlyManager{
        erc20WithTime = erc20Time;
        nftWithTime = nftTime;
    }

    function setLandBasePower(uint256[] memory ids,uint256[] memory pows) public onlyManager{
        require(ids.length == pows.length, "GetInfo:Wrong length");
        for(uint i=0; i<ids.length; i++){
            landBasePower[ids[i]] = pows[i];
        }
    }

    function setWorkerPower(uint256[] memory ids,uint256[] memory pows) public onlyManager{
        require(ids.length == pows.length, "GetInfo:Wrong length");
        for(uint i=0; i<ids.length; i++){
            workerBasePower[ids[i]] = pows[i];
        }

    }

    function setBossTaxRate(uint256[] memory ids,uint256[] memory rates) public onlyManager{
        require(ids.length == rates.length, "GetInfo:Wrong length");
        for(uint i=0; i<ids.length; i++){
            bossTaxRate[ids[i]] = rates[i];
        }
    }

    function setPickBasePower(uint256[] memory ids,uint256[] memory pows) public onlyManager{
        require(ids.length == pows.length, "GetInfo:Wrong length");
        for(uint i=0; i<ids.length; i++){
            pickBasePower[ids[i]] = pows[i];
        }
    }

    function setErc20ForBoss(uint256[] memory amounts,uint256[] memory percents) public onlyManager{
        require(amounts.length == percents.length, "GetInfo:Wrong length");
        for(uint i=0; i<amounts.length; i++){
            erc20ForBossPercent[amounts[i]] = percents[i];
        }
    }

    function setErc20ForLand(uint256[] memory amounts,uint256[] memory pows) public onlyManager{
        require(amounts.length == pows.length, "GetInfo:Wrong length");
        for(uint i=0; i<amounts.length; i++){
            erc20ForLandAddPower[amounts[i]] = pows[i];
        }
    }

    function setErc20ForWorker(uint256[] memory amounts,uint256[] memory pows) public onlyManager{
        require(amounts.length == pows.length, "GetInfo:Wrong length");
        for(uint i=0; i<amounts.length; i++){
            erc20ForWorkerAddPower[amounts[i]] = pows[i];
        }
    }

    function setUpgradeId(uint256[] memory oIds,uint256[] memory nIds) public onlyManager{
        require(oIds.length == nIds.length, "GetInfo:Wrong length");
        for(uint i=0; i<oIds.length; i++){
            upgradeId[oIds[i]] = nIds[i];
        }
    }

    function getBossSubordinateWorkerAmount(uint256 bosId) public view returns(uint256){
        uint256 amount = 0;
        (,uint256[] memory middle) = IGameData(gameData).getBossSubordinateLand(bosId);
        for (uint256 i = 0; i < middle.length; i++) {
            if(middle[i]>0){
                amount = amount + 1;
            }
        }
        return amount;
    }

    function getBossErc20Info(uint256 bosId) public view returns(uint256 rece,uint256 stakingTime){
        (,,,uint256 erc20,uint256 erc20Time,,) = IGameData(gameData).stakingBoss(bosId);
        stakingTime = erc20Time;
        if (block.timestamp.sub(erc20Time)>=erc20WithTime) {
            rece = erc20;
        } else {
            rece = erc20.mul(90).div(100);
        }
    }

    function getLandErc20Info(uint256 lanId) public view returns(uint256 rece,uint256 stakingTime){
        (,,,,uint256 erc20,uint256 erc20Time,,,) = IGameData(gameData).stakingLand(lanId);
        stakingTime = erc20Time;
        if (block.timestamp.sub(erc20Time)>=erc20WithTime) {
            rece = erc20;
        } else {
            rece = erc20.mul(90).div(100);
        }
    }

    function getWorkerErc20Info(uint256 worId) public view returns(uint256 rece,uint256 stakingTime){
        (,,,,uint256 erc20,uint256 erc20Time,,,) = IGameData(gameData).stakingWorker(worId);
        stakingTime = erc20Time;
        if (block.timestamp.sub(erc20Time)>=erc20WithTime) {
            rece = erc20;
        } else {
            rece = erc20.mul(90).div(100);
        }
    }

    function paySearchFee() public {
        require(IERC20(token20).transferFrom(msg.sender, destoryAddress, 2e17),"Staking:TransferFrom failed");
    }

    function getUserStakingErc20() public view returns(uint256){
        uint256 amountBoss = 0;
        (uint256[] memory bos,uint256[] memory lan,uint256[] memory wor,,,uint256 boss) = IGameData(gameData).getUserInfo(msg.sender);
        if(boss > 0){
            for(uint i=0; i<bos.length; i++){
                if(bos[i] > 0){
                    (,,,uint256 erc20,,,) = IGameData(gameData).stakingBoss(bos[i]);
                    amountBoss = amountBoss.add(erc20);
                }
            }
        }
        uint256 amountLand = 0;
        for(uint i=0; i<lan.length; i++){
            if(lan[i] > 0){
                (,,,,uint256 erc20,,,,) = IGameData(gameData).stakingLand(lan[i]);
                amountLand = amountLand.add(erc20);
            }
        }
        uint256 amountWorker = 0;
        for(uint i=0; i<wor.length; i++){
            if(wor[i] > 0){
                (,,,,uint256 erc20,,,,) = IGameData(gameData).stakingWorker(wor[i]);
                amountWorker = amountWorker.add(erc20);
            }
        }
        return amountBoss.add(amountLand).add(amountWorker);
    }

    function getUserWorkerPower() public view returns(uint256 power){    
        (,,uint256[] memory wor,,,) = IGameData(gameData).getUserInfo(msg.sender);
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                (,,,,,,,uint256 toPow,) = IGameData(gameData).stakingWorker(wor[i]);
                power = power.add(toPow);
            }
        }
    }

    function getErc20IsApprove(address token,address customer) public view returns(bool){
        uint256 amount = IERC20(token).allowance(customer, address(this));
        if (amount >= 20000e18) {
            return true;
        } else {
            return false;
        }
    }

    function getPickAddPower(uint256 picId) public view returns(uint256 power){
        (uint256 id,uint256 worId,) = IGameData(gameData).stakingPick(picId);
        (uint256 wid,,,,,,,,) = IGameData(gameData).stakingWorker(worId);
        uint256 worBase = workerBasePower[wid];
        uint256 pow = pickBasePower[id];
        if(id <117){
            power = pow;
        }
        if(id == 117){   
            power = pow.add(worBase.mul(6).div(100));
        }
        if(id == 118){
            power = pow.add(worBase.mul(15).div(100));
        }
    }

    function getLandSurWithTime(uint256 lanId) public view returns(uint256){
        (,,,,,,,,uint256 withtime) = IGameData(gameData).stakingLand(lanId);
        uint256 middle = block.timestamp.sub(withtime);
        if(nftWithTime>=middle){
            return nftWithTime.sub(middle);
        }else{
            return 0;
        }
    }

    function getWorkerSurWithTime(uint256 worId) public view returns(uint256){
        (,,,,,,,,uint256 withtime) = IGameData(gameData).stakingWorker(worId);
        uint256 middle = block.timestamp.sub(withtime);
        if(nftWithTime>=middle){
            return nftWithTime.sub(middle);
        }else{
            return 0;
        }
    }

    function getBossWithdrawPayFor(address customer,uint256 bosId) public view returns(uint256){
        uint256 lanAmount = 0;
        uint256 worAmount = 0;
        (uint256[] memory middleLand,uint256[] memory middleWorker) = IGameData(gameData).getBossSubordinateLand(bosId);
        for (uint i = 0; i < middleLand.length; i++) {
            if(middleLand[i]>0){
                (,,address hol,,,,,,) = IGameData(gameData).stakingLand(middleLand[i]);
                if (hol != customer) {
                    lanAmount = lanAmount.add(1);
                } 
            }
        }
        for(uint i=0; i<middleWorker.length; i++){
            if(middleWorker[i]>0){
                (,,,address hol,,,,,) = IGameData(gameData).stakingWorker(middleWorker[i]);
                if(hol != customer){
                    worAmount = worAmount.add(1);
                }
            }
        }
        return lanAmount.mul(4e18).add(worAmount.mul(2e18));   
    }

    function getBossRemovePayFor(address customer,uint256 lanId) public view returns(uint256){
        uint256 amount = 0;
        uint256[] memory middle = IGameData(gameData).getLandSubordinateWorker(lanId);
        for (uint256 i = 0; i < middle.length; i++) {
            if(middle[i]>0){
                (,,,address holder,,,,,) = IGameData(gameData).stakingWorker(middle[i]);
                if(holder != customer){
                    amount = amount.add(1);
                }
            }
        }
        (,,address hol,,,,,,) = IGameData(gameData).stakingLand(lanId);
        if (hol != customer) {
            return amount.mul(2e18).add(4e18);
        } else {
            return amount.mul(2e18);
        }
    }

    function getLandWithdrawPayFor(uint256 lanId) public view returns(uint256){
        (,,address holder,,,,,,) = IGameData(gameData).stakingLand(lanId);
        uint256[] memory wor = IGameData(gameData).getLandSubordinateWorker(lanId);
        uint256 amount = 0;
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                (,,,address hol,,,,,) = IGameData(gameData).stakingWorker(wor[i]);
                if(holder != hol){
                    amount = amount.add(1);
                }
            }
        }
        return amount.mul(2e18);
    }

}


contract Staking{
    using SafeMath for uint256;
    address token1155;
    address token20;
    address gameData;
    address getInfo;
    address manager;
    mapping(uint256=>mapping(address=>bool)) isRewardBoss;
    mapping(uint256=>mapping(address=>bool)) isRewardLand;

    
    constructor(){
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(manager == msg.sender,"Staking:No permit");
        _;
    }
    
    function setTokenAddress(address token15,address token,address game,address get) public onlyManager{
        token1155 = token15;
        token20 = token;
        gameData = game;
        getInfo = get;
    }

    function provideBossNftForStaking(uint256 assetId) public {
        require(assetId > 0 && assetId < 6,"Staking:Asset id wrong");
        (,,,,,uint256 boss) = IGameData(gameData).getUserInfo(msg.sender);
        require(boss == 0,"Staking:Only one");
        IERC1155(token1155).safeTransferFrom(msg.sender,gameData,assetId,1,"");
        uint256 rate = IGetInfo(getInfo).bossTaxRate(assetId);
        IGameData(gameData).createBoss(msg.sender, assetId,rate);
    }

    function provideLandNftForStaking(address customer,uint256 assetId,uint256 bosId) public{
        require(assetId > 5 && assetId < 10,"Staking:Asset id wrong");
        uint256 lanBasePower = IGetInfo(getInfo).landBasePower(assetId);
        if(customer != address(0) && customer != msg.sender && bosId > 0){
            if(isRewardBoss[bosId][customer] == false){
                IGameData(gameData).addRecommend(customer);
                isRewardBoss[bosId][customer] = true;
            }    
        }
        if(bosId > 0){
            (,,uint256 lan,,,,) = IGameData(gameData).stakingBoss(bosId);
            require(lan <3,"Staking:Maximum limit exceeded");    
            IERC1155(token1155).safeTransferFrom(msg.sender,gameData,assetId,1,"");
            IGameData(gameData).createLand(msg.sender, assetId, bosId, lanBasePower);
        }else{
            IERC1155(token1155).safeTransferFrom(msg.sender,gameData,assetId,1,"");
            IGameData(gameData).createLand(msg.sender, assetId, bosId, lanBasePower);
        }
    }

    function provideWorkerNftStaking(address customer,uint256 assetId,uint256 lanId) public{
        require(lanId > 0 && assetId > 9 ,"Staking:Land id wrong");
        uint256 worBasePower = IGetInfo(getInfo).workerBasePower(assetId);
        IERC1155(token1155).safeTransferFrom(msg.sender, gameData, assetId, 1, "");
        if(customer != address(0) && customer != msg.sender){
            if(isRewardLand[lanId][customer] == false){
                IGameData(gameData).addRecommend(customer);
                isRewardLand[lanId][customer] = true;
            }  
        }
        (,uint256 bosId,,uint256 wor,,,,uint256 addPow,) = IGameData(gameData).stakingLand(lanId);
        require(wor <20,"Staking:Maximum limit exceeded");
        //IGameData(gameData).updateLandIncome(lanId);
        uint256 power = 0;
        if(bosId > 0){
            (,,,,,,uint256 percent) = IGameData(gameData).stakingBoss(bosId);
            if(percent>0){
                power = worBasePower.add(worBasePower.mul(percent).div(100)).add(addPow);
                IGameData(gameData).createWorker(msg.sender, assetId, lanId, power);
            }else{
                power = worBasePower.add(addPow);
                IGameData(gameData).createWorker(msg.sender, assetId, lanId, power);
            }    
        }else{
            power = worBasePower.add(addPow);
            IGameData(gameData).createWorker(msg.sender, assetId, lanId, power);
        }
    }

    function providePickNftForStaking(uint256 worId,uint256 assetId) public{
        require(worId>0, "Staking:Data wrong");
        uint256 pickPower = IGetInfo(getInfo).pickBasePower(assetId);
        require(pickPower > 0, "Staking:Asset wrong");
        (uint256 id,,,,,,,,) = IGameData(gameData).stakingWorker(worId);
        uint256 worBasePower = IGetInfo(getInfo).workerBasePower(id);
        IERC1155(token1155).safeTransferFrom(msg.sender,gameData,assetId,1,"");
        IGameData(gameData).updateWorkerIncome(worId);
        uint256 power = 0;
        if(assetId <=116){
            IGameData(gameData).createPick(msg.sender, worId, assetId);
            IGameData(gameData).updatePower(0, worId, pickPower);
        }
        if(assetId==117){
            power = pickPower.add(worBasePower.mul(6).div(100));
            IGameData(gameData).createPick(msg.sender, worId, assetId);
            IGameData(gameData).updatePower(0, worId, power);
        }
        if(assetId==118){
            power = pickPower.add(worBasePower.mul(15).div(100));
            IGameData(gameData).createPick(msg.sender, worId, assetId);
            IGameData(gameData).updatePower(0, worId, power);
        }
    }

    function getBossErc20AmountIn(uint256 bosId,uint256 amount) public view returns(uint256 amountIn,address holder){
        (,address hol,,uint256 erc20,,,) = IGameData(gameData).stakingBoss(bosId);
        holder = hol;
        if (amount >= erc20) {
            amountIn = amount.sub(erc20);
        } else {
            amountIn = 0;
        }
    }

    function provideErc20ForBoss(uint256 bosId,uint256 amount) public {
        (uint256 amountIn,address holder) = getBossErc20AmountIn(bosId,amount);
        require(holder == msg.sender,"Staking:No permit");
        require(amount == 400e18 || amount == 800e18 || amount == 1200e18 || amount == 1600e18, "Staking:Amount wrong");
        require(IERC20(token20).transferFrom(msg.sender, gameData, amountIn), "Staking:TransferFrom failed");
        uint256 map = amount.div(1e18);
        uint256 percent = IGetInfo(getInfo).erc20ForBossPercent(map);
        (,,,,,,uint256 beforPercent) = IGameData(gameData).stakingBoss(bosId); 
        //先更新worker的收益，继续更新woker的算力
        (,uint256[] memory wor) = IGameData(gameData).getBossSubordinateLand(bosId);
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                IGameData(gameData).updateWorkerIncome(wor[i]);
                (uint256 id,,,,,,,,) = IGameData(gameData).stakingWorker(wor[i]);
                uint256 basePower = IGetInfo(getInfo).workerBasePower(id);
                uint256 surPercent = percent.sub(beforPercent);
                uint256 power = surPercent.mul(basePower).div(100);
                IGameData(gameData).updatePower(0, wor[i], power);
            }
        }
        IGameData(gameData).updateErc20Info(0, bosId, amount,percent);
    }

    function getLandErc20AmountIn(uint256 lanId,uint256 amount) public view returns(uint256 lid,uint256 amountIn,address holder,uint256 ercAmount){
        (uint256 id,,address hol,,uint256 erc20,,,,) = IGameData(gameData).stakingLand(lanId);
        holder = hol;
        lid = id;
        ercAmount = erc20;
        if (amount >= erc20) {
            amountIn = amount.sub(erc20);
        } else {
            amountIn = 0;
        }    
    }

    function provideErc20ForLand(uint256 lanId,uint256 amount) public{
        (uint256 id,uint256 amountIn,address holder,uint256 erc20) = getLandErc20AmountIn(lanId,amount);
        require(holder == msg.sender,"Staking:No permit");
        require(amount == 100e18 || amount == 200e18 || amount == 300e18 || amount == 400e18, "Staking:Amount wrong");
        require(IERC20(token20).transferFrom(msg.sender,gameData,amountIn),"Staking:TransferFrom failed");
        uint256 afterMap = amount.div(1e18);
        uint256 afterBasePower = IGetInfo(getInfo).erc20ForLandAddPower(afterMap);
        uint256 basePower = IGetInfo(getInfo).landBasePower(id);
        uint256 worPower = 0;
        uint256 lanPower = 0;
        if(erc20>0){
            uint256 beforMap = erc20.div(1e18);
            uint256 beforBasePower = IGetInfo(getInfo).erc20ForLandAddPower(beforMap);
            worPower = afterBasePower.sub(beforBasePower);
            lanPower = afterBasePower.add(basePower);
        }
        if(erc20==0){
            worPower = afterBasePower;
            lanPower = afterBasePower.add(basePower);
        }
        uint256[] memory wor = IGameData(gameData).getLandSubordinateWorker(lanId);
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                IGameData(gameData).updateWorkerIncome(wor[i]);
                IGameData(gameData).updatePower(0, wor[i], worPower);
            }
        }
        IGameData(gameData).updateErc20Info(1, lanId, amount, lanPower);
    }

    function getWorkerErc20AmountIn(uint256 worId,uint256 amount) public view returns(uint256 amountIn,address holder,uint256 ercAmount){
        (,,,address hol,uint256 erc20,,,,) = IGameData(gameData).stakingWorker(worId);
        holder = hol;
        ercAmount = erc20;
        if (amount >= erc20) {
            amountIn = amount.sub(erc20);
        } else {
            amountIn = 0;
        }    
    }

    function provideErc20ForWorker(uint256 worId,uint256 amount) public {
        (uint256 amountIn,address holder,uint256 erc20) = getWorkerErc20AmountIn(worId,amount);
        require(holder == msg.sender,"Staking:No permit");
        require(amount == 100e18 || amount == 300e18 || amount == 600e18 || amount == 900e18, "Staking:Amount wrong");
        require(IERC20(token20).transferFrom(msg.sender,gameData,amountIn),"Staking:TransferFrom failed");
        uint256 afterMap = amount.div(1e18);
        uint256 afterErc20ForWorker = IGetInfo(getInfo).erc20ForWorkerAddPower(afterMap);
        if (erc20 > 0) {
            uint256 beforMap = erc20.div(1e18);
            uint256 beforErc20ForWorker = IGetInfo(getInfo).erc20ForWorkerAddPower(beforMap);
            uint256 power = afterErc20ForWorker.sub(beforErc20ForWorker);
            //IGameData(gameData).updateForWorkerErc20Info(0, worId, amount, power);
            IGameData(gameData).updateWorkerIncome(worId);
            IGameData(gameData).updatePower(0, worId, power);
            IGameData(gameData).updateErc20Info(2, worId, amount, 0);
        } else {
            IGameData(gameData).updateWorkerIncome(worId);
            IGameData(gameData).updatePower(0, worId, afterErc20ForWorker);
            IGameData(gameData).updateErc20Info(2, worId, amount, 0);
        }
    }

    function getErc20IsApprove(address token,address customer) public view returns(bool){
        uint256 amount = IERC20(token).allowance(customer, address(this));
        if (amount >= 20000e18) {
            return true;
        } else {
            return false;
        }
    }

    function getErc1155IsApprove(address customer) public view returns(bool){
        return IERC1155(token1155).isApprovedForAll(customer, address(this));
    }

}

contract Extract{
    using SafeMath for uint256;
    address gameData;
    address getInfo;
    address token1155;
    address token20;
    address manager;

    uint256 erc20WithTime = 604800;
    uint256 nftWithTime = 432000;

    constructor(){
        manager = msg.sender;
    }

    modifier onlyManager(){
        require(manager == msg.sender, "Extract:No permit");
        _;
    }

    function setTokenAddress(address token15,address token2,address game,address get) public onlyManager{
        gameData = game;
        getInfo = get;
        token1155 = token15;
        token20 = token2;
    }

    function setTime(uint256 erc20Time,uint256 nftTime) public onlyManager{
        erc20WithTime = erc20Time;
        nftWithTime = nftTime;
    }

    function withdrawErc20ForBoss(uint256 bosId) public{
        (,address holder,,uint256 erc20,uint256 erc20Time,,uint256 percent) = IGameData(gameData).stakingBoss(bosId);
        require(holder == msg.sender ,"Extract:No permit");
        if(erc20 > 0){     
            if(block.timestamp.sub(erc20Time)>=erc20WithTime){
                IGameData(gameData).withdrawErc20ForUser(0, msg.sender, erc20);
            }else{
                IGameData(gameData).withdrawErc20ForUser(1, msg.sender, erc20);
            }
        }
        (,uint256[] memory wor) = IGameData(gameData).getBossSubordinateLand(bosId);
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                (uint256 id,,,,,,,,) = IGameData(gameData).stakingWorker(wor[i]);
                IGameData(gameData).updateWorkerIncome(wor[i]);
                uint256 worBasePower = IGetInfo(getInfo).workerBasePower(id);
                uint256 power = worBasePower.mul(percent).div(100);
                IGameData(gameData).updatePower(1, wor[i], power);
            }
        }
        IGameData(gameData).updateErc20Info(0, bosId, 0, 0);
    }

    function withdrawBossStakingNft(uint256 bosId) public{
        require(bosId > 0,"ExtractL:Id wrong");
        (,address holder,,uint256 erc20,,,) = IGameData(gameData).stakingBoss(bosId);
        require(holder == msg.sender,"Extract:No permit");
        (uint256[] memory lan,uint256[] memory wor) = IGameData(gameData).getBossSubordinateLand(bosId);
        for(uint i=0; i<lan.length;i++){
            if(lan[i]>0){
                (,,address hollan,,,,,,) = IGameData(gameData).stakingLand(lan[i]);
                if(hollan != holder) {
                    require(IERC20(token20).transferFrom(msg.sender, hollan, 4e18), "Extract:TransferFrom failed");
                }
                IGameData(gameData).updateBossIdForLandAndWorker(lan[i],0);
            }
        }
        if(erc20 > 0){
            withdrawErc20ForBoss(bosId);
            for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                (,,,address hol,,,,,) = IGameData(gameData).stakingWorker(wor[i]);
                if(hol != holder) {
                    require(IERC20(token20).transferFrom(msg.sender, hol, 2e18), "Extract:TransferFrom failed");
                }
                IGameData(gameData).updateBossIdForLandAndWorker(0,wor[i]);
                }
            } 
            IGameData(gameData).deleteBoss(bosId);
        }else{
            IGameData(gameData).updateBossIncome(bosId);
            for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                (,,,address hol,,,,,) = IGameData(gameData).stakingWorker(wor[i]);
                if(hol != holder) {
                    require(IERC20(token20).transferFrom(msg.sender, hol, 2e18), "Extract:TransferFrom failed");
                }
                IGameData(gameData).updateBossIdForLandAndWorker(0,wor[i]);
                }
            }
            IGameData(gameData).deleteBoss(bosId);
        }
    }

    function withdrawErc20ForLand(uint256 lanId) public{
        (uint256 id,,address holder,,uint256 erc20,uint256 erc20Time,,,) = IGameData(gameData).stakingLand(lanId);
        require(holder == msg.sender , "Extract:No permit");
        if(erc20>0){
            if(block.timestamp.sub(erc20Time)>=erc20WithTime){
                IGameData(gameData).withdrawErc20ForUser(0, msg.sender, erc20);
            }else{
                IGameData(gameData).withdrawErc20ForUser(1, msg.sender, erc20);
            }
        }
        uint256 map = erc20.div(1e18);
        uint256[] memory wor = IGameData(gameData).getLandSubordinateWorker(lanId);
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){ 
                uint256 power = IGetInfo(getInfo).erc20ForLandAddPower(map);
                IGameData(gameData).updateWorkerIncome(wor[i]);
                IGameData(gameData).updatePower(1, wor[i], power);
            }
        }
        uint256 landBasePower = IGetInfo(getInfo).landBasePower(id);
        IGameData(gameData).updateErc20Info(1, lanId, 0, landBasePower);
    }

    function onlyWithdrawWorkerErc20(uint256 worId) internal{
        (,,,address worHolder,uint256 worErc20,uint256 worErc20Time,,,) = IGameData(gameData).stakingWorker(worId);
        if(worErc20>0){
            if(block.timestamp.sub(worErc20Time)>=erc20WithTime){
                IGameData(gameData).withdrawErc20ForUser(0, worHolder, worErc20);
            }else{
                IGameData(gameData).withdrawErc20ForUser(0, worHolder, worErc20);
            }
            IGameData(gameData).updateErc20Info(2, worId, 0, 0);
        }
    }


    function withdrawLandStakingNft(uint256 lanId) public {
        (,,address holder,,uint256 erc20,uint256 erc20Time,,,uint256 withTime) = IGameData(gameData).stakingLand(lanId);
        require(holder == msg.sender,"Extract:No permit");
        require(block.timestamp.sub(withTime)>=nftWithTime,"Extract:Wrong time");
        if(erc20>0){
            if(block.timestamp.sub(erc20Time)>=erc20WithTime){
                IGameData(gameData).withdrawErc20ForUser(0, msg.sender, erc20);
            }else{
                IGameData(gameData).withdrawErc20ForUser(1, msg.sender, erc20);
            }
        }
        uint256[] memory wor = IGameData(gameData).getLandSubordinateWorker(lanId);
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                uint256[] memory pic = IGameData(gameData).getWorkerSubordinatePick(wor[i]);
                IGameData(gameData).updateWorkerIncome(wor[i]);
                (,,,address hol,uint256 worErc20,,,uint256 toPow,) = IGameData(gameData).stakingWorker(wor[i]);
                if(hol != holder){
                    require(IERC20(token20).transferFrom(msg.sender,hol,2e18),"Extract:TransferFrom failed");
                } 
                for(uint j=0; j<pic.length;j++){
                    if(pic[j]>0){
                        IGameData(gameData).deletePick(pic[j]);
                    }
                }        
                if(worErc20>0){
                    onlyWithdrawWorkerErc20(wor[i]);
                }
                IGameData(gameData).updatePower(1, wor[i], toPow);
                IGameData(gameData).deleteWorker(wor[i]);
            }
        }
        IGameData(gameData).deleteLand(lanId);
    }

    function withdrawErc20ForWorker(uint256 worId) public {
        (,,,address hol,uint256 erc20,uint256 erc20Time,,,) = IGameData(gameData).stakingWorker(worId);
        if(erc20>0){
            if(block.timestamp.sub(erc20Time)>=erc20WithTime){
                IGameData(gameData).withdrawErc20ForUser(0, hol, erc20);
            }else{
                IGameData(gameData).withdrawErc20ForUser(1, hol, erc20);
            }
        }
        IGameData(gameData).updateWorkerIncome(worId);
        uint256 map = erc20.div(1e18);
        uint256 power = IGetInfo(getInfo).erc20ForWorkerAddPower(map);
        IGameData(gameData).updatePower(1,worId,power);
        IGameData(gameData).updateErc20Info(2,worId, 0, 0);
    }

    function withdrawWorkerStakingNft(uint256 worId) public{
        (,,,address hol,uint256 erc20,uint256 erc20Time,,uint256 toPow,uint256 withTime) = IGameData(gameData).stakingWorker(worId);
        require(hol == msg.sender,"Extract:No permit");
        require(block.timestamp.sub(withTime)>=nftWithTime, "Extract:Wrong time");
        IGameData(gameData).updateWorkerIncome(worId);
        if(erc20>0){
            if(block.timestamp.sub(erc20Time)>=erc20WithTime){
                IGameData(gameData).withdrawErc20ForUser(0, hol, erc20);
            }else{
                IGameData(gameData).withdrawErc20ForUser(1, hol, erc20);
            }
        }
        uint256[] memory pic = IGameData(gameData).getWorkerSubordinatePick(worId);
        for(uint i=0; i<pic.length; i++){
            if(pic[i]>0){
                IGameData(gameData).deletePick(pic[i]);
            }
        }
        IGameData(gameData).updatePower(1,worId,toPow);
        IGameData(gameData).deleteWorker(worId);
    }

    function withdrawPickStakingNft(uint256 picId) public{
        (uint256 id,uint256 worId,) = IGameData(gameData).stakingPick(picId);
        (uint256 wId,,,,,,,,) = IGameData(gameData).stakingWorker(worId);
        uint256 worBasePower = IGetInfo(getInfo).workerBasePower(wId);
        uint256 picBasePower = IGetInfo(getInfo).pickBasePower(id);
        uint256 power = 0;
        if(id<117){
            power = picBasePower;
        }
        if(id==117){ 
            power = picBasePower.add(worBasePower.mul(6).div(100));
        }
        if(id==118){
            power = picBasePower.add(worBasePower.mul(15).div(100));
        }
        IGameData(gameData).updateWorkerIncome(worId);
        IGameData(gameData).updatePower(1, worId, power);
        IGameData(gameData).deletePick(picId);
    }

    function bossRemoveLand(uint256 bosId,uint256 lanId) public{
        (,address hol,,,,,uint256 percent) = IGameData(gameData).stakingBoss(bosId);
        require(hol == msg.sender, "Extract:No permit");
        (,,address hollan,,,,,,uint256 withTime) = IGameData(gameData).stakingLand(lanId);
        require(block.timestamp.sub(withTime)>=nftWithTime, "Extract:Wrong time");
        if(hol != hollan){
            require(IERC20(token20).transferFrom(msg.sender, hollan, 4e18), "Extract:TransferFrom failed");
        }
        IGameData(gameData).updateBossIdForLandAndWorker(lanId, 0);
        uint256[] memory wors = IGameData(gameData).getLandSubordinateWorker(lanId);
        for(uint i=0; i<wors.length; i++){
            if(wors[i]>0){
                (uint256 id,,,address holwor,,,,,) = IGameData(gameData).stakingWorker(wors[i]);
                if(hol != holwor){
                    require(IERC20(token20).transferFrom(msg.sender, holwor, 2e18), "Extract:TransferFrom failed");
                }
                IGameData(gameData).updateWorkerIncome(wors[i]);
                uint256 worBasePower = IGetInfo(getInfo).workerBasePower(id);
                uint256 power = worBasePower.mul(percent).div(100);
                IGameData(gameData).updatePower(1, wors[i], power);
                IGameData(gameData).updateBossIdForLandAndWorker(0, wors[i]);
            }
        }
    }

    function landRemoveWorker(uint256 lanId,uint256 worId) public {
        (,,address hol,,,,,,) = IGameData(gameData).stakingLand(lanId);
        (,,,address holwor,uint256 erc20,
        uint256 erc20Time,,uint256 toPow,uint256 withtime) = IGameData(gameData).stakingWorker(worId);
        require(hol == msg.sender, "Extract:No permit");
        require(block.timestamp.sub(withtime)>=nftWithTime, "Extract:Wrong time");
        if(hol != holwor){
            require(IERC20(token20).transferFrom(msg.sender,holwor,2e18),"Extract:TransferFrom failed");
        }
        if(erc20>0){
            if(block.timestamp.sub(erc20Time)>=erc20WithTime){
                IGameData(gameData).withdrawErc20ForUser(0, holwor, erc20);
            }else{
                IGameData(gameData).withdrawErc20ForUser(1, holwor, erc20);
            }
        }
        uint256[] memory pics = IGameData(gameData).getWorkerSubordinatePick(worId);
        for(uint i=0; i<pics.length; i++){
            if(pics[i]>0){
                IGameData(gameData).deletePick(pics[i]);
            }
        }
        IGameData(gameData).updateWorkerIncome(worId);
        IGameData(gameData).updatePower(1, worId, toPow);
        IGameData(gameData).updateErc20Info(2, worId, 0, 0);
        IGameData(gameData).deleteWorker(worId);
    }

    function getErc20IsApprove(address token,address customer) public view returns(bool){
        uint256 amount = IERC20(token).allowance(customer, address(this));
        if (amount >= 20000e18) {
            return true;
        } else {
            return false;
        }
    }

}

contract Income{
    using SafeMath for uint256;
    address gameData;
    address token20;
    address manager;
    address getInfo;
    address token1155;
    mapping(uint256=>uint256) public destoryNftAmount;

    constructor(){
        manager = msg.sender;
    }

    modifier onlyManager(){
        require(manager == msg.sender, "Upgrade:No permit");
        _;
    }

    function setTokenAddress(address token15,address token,address game,address get) public onlyManager{
        getInfo = get;
        token1155 = token15;
        gameData = game;
        token20 = token;
    }

    function userIncome(address customer) public view returns(uint256){
        (uint256[] memory bos,uint256[] memory lan,uint256[] memory
        wor,uint256 debt,uint256 syn,) = IGameData(gameData).getUserInfo(customer);
        uint256 bossIncome = 0;
        for (uint i = 0; i < bos.length; i++) {
            if(bos[i]>0){
                bossIncome = IGameData(gameData).getBossIncome(bos[i]);
            }
        }
        uint256 landIncome = 0;
        for (uint i = 0; i < lan.length; i++) {
            if(lan[i]>0){
                landIncome = landIncome.add(IGameData(gameData).getLandIncome(lan[i]));
            }
        }
        uint256 workerIncome = 0;
        for (uint i = 0; i < wor.length; i++) {
            if(wor[i]>0){
                (uint256 worIn,) = IGameData(gameData).getWorkerIncome(wor[i]);
                workerIncome = workerIncome.add(worIn);
            }
        }
        return bossIncome.add(landIncome).add(workerIncome).add(syn).sub(debt);
    }

    function getUserNftAmount(address customer) public view returns(uint256){
        (uint256[] memory bos,uint256[] memory lan,uint256[] memory
        wor,,,) = IGameData(gameData).getUserInfo(customer);
        uint256 bossAmount =0;
        for (uint i=0; i< bos.length; i++) {
            if(bos[i]>0){
                bossAmount = 1;
            }
        }
        uint256 landAmount = 0;
        for(uint i=0; i<lan.length; i++){
            if(lan[i]>0){
                landAmount = landAmount.add(1);
            }
        }
        uint256 workerAmount = 0;
        for(uint i=0; i<wor.length; i++){
            if(wor[i]>0){
                workerAmount = workerAmount.add(1);
            }
        }
        return bossAmount.add(landAmount).add(workerAmount);
    }

    //只做debt记录，其他部分不需要管，任何算力变动及解除都会向sync同步数据
    function claim(uint256 amount) public{
        require(amount <= userIncome(msg.sender), "Income:Wrong amount");
        IGameData(gameData).withdrawErc20ForUser(0, msg.sender, amount);
        uint256 nftAmount = getUserNftAmount(msg.sender);
        if(nftAmount > 0){
            IGameData(gameData).updateUserDebt(0, msg.sender, amount);
        }else{
            IGameData(gameData).updateUserDebt(1, msg.sender, amount);
        }
    }

    function upgradeWorker(uint256 assetId) public {
        uint256 upgradeId = IGetInfo(getInfo).upgradeId(assetId);
        require(upgradeId > 0,"Staking:asset id wrong");
        IERC1155(token1155).mintNftForTrading(msg.sender, upgradeId, 1);
        IERC1155(token1155).burnNftForTrading(msg.sender, assetId, 2);
        IERC1155(token1155).burnNftForTrading(msg.sender, 16, 1);
        destoryNftAmount[assetId] = destoryNftAmount[assetId].add(2);
    }

    function upgradePickInfo(uint256 ran,uint256 assetId) public view returns(bool iss){
        uint256 amount = IERC20(token20).balanceOf(msg.sender);
        if(amount>=8e18){
            if(assetId==15 && ran<=900){
                iss = true;
            }else if(assetId==115 && ran<=650){
                iss = true;
            }else if(assetId==116 && ran<=400){
                iss = true;
            }else if(assetId==117 && ran<=200){
                iss = true;
            }else{
                iss = false;
            }
        }else{
            iss = false;
        }      
    }

    function upgradePick(uint256 ran,uint256 assetId) public {
        uint256 upgradeId = IGetInfo(getInfo).upgradeId(assetId);
        require(upgradeId > 0,"Staking:asset id wrong");
        address destory = IGetInfo(getInfo).destoryAddress();
        require(IERC20(token20).transferFrom(msg.sender, destory, 8e18),"Staking:TransferFrom failed");
        if(assetId==15 && ran<=900){
            IERC1155(token1155).mintNftForTrading(msg.sender, upgradeId, 1);
            IERC1155(token1155).burnNftForTrading(msg.sender, 15, 1);
            destoryNftAmount[assetId] = destoryNftAmount[assetId].add(1);
        } if(assetId==115 && ran<=650){
            IERC1155(token1155).mintNftForTrading(msg.sender, upgradeId, 1);
            IERC1155(token1155).burnNftForTrading(msg.sender, 115, 1);
            destoryNftAmount[assetId] = destoryNftAmount[assetId].add(1);
        } if(assetId==116 && ran<=400){
            IERC1155(token1155).mintNftForTrading(msg.sender, upgradeId, 1);
            IERC1155(token1155).burnNftForTrading(msg.sender, 116, 1);
            destoryNftAmount[assetId] = destoryNftAmount[assetId].add(1);
        } if(assetId==117 && ran<=200){
            IERC1155(token1155).mintNftForTrading(msg.sender, upgradeId, 1);
            IERC1155(token1155).burnNftForTrading(msg.sender, 117, 1);
            destoryNftAmount[assetId] = destoryNftAmount[assetId].add(1);
        }
    }

    function getErc20IsApprove(address token,address customer) public view returns(bool){
        uint256 amount = IERC20(token).allowance(customer, address(this));
        if (amount >= 20000e18) {
            return true;
        } else {
            return false;
        }
    }

    function getErc1155IsApprove(address customer) public view returns(bool){
        return IERC1155(token1155).isApprovedForAll(customer, address(this));
    }

}