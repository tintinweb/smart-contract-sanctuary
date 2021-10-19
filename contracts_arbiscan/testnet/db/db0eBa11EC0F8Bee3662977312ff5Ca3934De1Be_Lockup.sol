/**
 *Submitted for verification at arbiscan.io on 2021-10-18
*/

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol
// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interface/IDevBridge.sol


interface IDevBridge {
	function mint(address _account, uint256 _amount) external returns (bool);

	function burn(address _account, uint256 _amount) external returns (bool);

	function renounceMinter() external;

	function renounceBurner() external;
}

// File: contracts/interface/IProperty.sol



interface IProperty {
	event ChangeAuthor(address _old, address _new);
	event ChangeName(string _old, string _new);
	event ChangeSymbol(string _old, string _new);

	function author() external view returns (address);

	function changeAuthor(address _nextAuthor) external;

	function changeName(string memory _name) external;

	function changeSymbol(string memory _symbol) external;

	function withdraw(address _sender, uint256 _value) external;
}

// File: contracts/interface/IPolicy.sol



interface IPolicy {
	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		returns (uint256);

	function holdersShare(uint256 _amount, uint256 _lockups)
		external
		view
		returns (uint256);

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		returns (uint256);

	function marketVotingSeconds() external view returns (uint256);

	function policyVotingSeconds() external view returns (uint256);

	function shareOfTreasury(uint256 _supply) external view returns (uint256);
}

// File: contracts/interface/ILockup.sol




interface ILockup {
	struct RewardPrices {
		uint256 reward;
		uint256 holders;
		uint256 interest;
		uint256 holdersCap;
	}

	struct LockedupProperty {
		address property;
		uint256 value;
	}

	event Lockedup(
		address indexed _from,
		address indexed _property,
		uint256 _value,
		uint256 _tokenId
	);
	event Withdrew(
		address indexed _from,
		address indexed _property,
		uint256 _value,
		uint256 _reward,
		uint256 _tokenId
	);

	event UpdateCap(uint256 _cap);

	function depositToProperty(address _property, uint256 _amount)
		external
		returns (uint256);

	function depositToPosition(uint256 _tokenId, uint256 _amount)
		external
		returns (bool);

	function getLockedupProperties()
		external
		view
		returns (LockedupProperty[] memory);

	function update() external;

	function withdrawByPosition(uint256 _tokenId, uint256 _amount)
		external
		returns (bool);

	function calculateCumulativeRewardPrices()
		external
		view
		returns (
			uint256 _reward,
			uint256 _holders,
			uint256 _interest,
			uint256 _holdersCap
		);

	function calculateRewardAmount(address _property)
		external
		view
		returns (uint256, uint256);

	function totalLockedForProperty(address _property)
		external
		view
		returns (uint256);

	function totalLocked() external view returns (uint256);

	function calculateWithdrawableInterestAmountByPosition(uint256 _tokenId)
		external
		view
		returns (uint256);

	function cap() external view returns (uint256);

	function updateCap(uint256 _cap) external;
}

// File: contracts/interface/IMetricsFactory.sol



interface IMetricsFactory {
	event Create(
		address indexed _market,
		address indexed _property,
		address _metrics
	);
	event Destroy(
		address indexed _market,
		address indexed _property,
		address _metrics
	);

	function create(address _property) external returns (address);

	function destroy(address _metrics) external;

	function isMetrics(address _addr) external view returns (bool);

	function metricsCount() external view returns (uint256);

	function metricsCountPerProperty(address _addr)
		external
		view
		returns (uint256);

	function metricsOfProperty(address _property)
		external
		view
		returns (address[] memory);

	function hasAssets(address _property) external view returns (bool);

	function authenticatedPropertiesCount() external view returns (uint256);
}

// File: contracts/interface/ISTokensManager.sol




interface ISTokensManager {
	/*
	 * @dev Struct to declares a staking position.
	 * @param owner The address of the owner of the new staking position
	 * @param property The address of the Property as the staking destination
	 * @param amount The amount of the new staking position
	 * @param price The latest unit price of the cumulative staking reward
	 * @param cumulativeReward The cumulative withdrawn reward amount
	 * @param pendingReward The pending withdrawal reward amount amount
	 */
	struct StakingPositions {
		address property;
		uint256 amount;
		uint256 price;
		uint256 cumulativeReward;
		uint256 pendingReward;
	}

	/*
	 * @dev Struct to declares staking rewards.
	 * @param entireReward The reward amount of adding the cumulative withdrawn amount
	 to the withdrawable amount
	 * @param cumulativeReward The cumulative withdrawn reward amount
	 * @param withdrawableReward The withdrawable reward amount
	 */
	struct Rewards {
		uint256 entireReward;
		uint256 cumulativeReward;
		uint256 withdrawableReward;
	}

	/*
	 * @dev The event fired when a token is minted.
	 * @param tokenId The ID of the created new staking position
	 * @param owner The address of the owner of the new staking position
	 * @param property The address of the Property as the staking destination
	 * @param amount The amount of the new staking position
	 * @param price The latest unit price of the cumulative staking reward
	 */
	event Minted(
		uint256 tokenId,
		address owner,
		address property,
		uint256 amount,
		uint256 price
	);

	/*
	 * @dev The event fired when a token is updated.
	 * @param tokenId The ID of the staking position
	 * @param amount The new staking amount
	 * @param price The latest unit price of the cumulative staking reward
	 * This value equals the 3rd return value of the Lockup.calculateCumulativeRewardPrices
	 * @param cumulativeReward The cumulative withdrawn reward amount
	 * @param pendingReward The pending withdrawal reward amount amount
	 */
	event Updated(
		uint256 tokenId,
		uint256 amount,
		uint256 price,
		uint256 cumulativeReward,
		uint256 pendingReward
	);

	/*
	 * @dev Creates the new staking position for the caller.
	 * Mint must be called from the Lockup contract.
	 * @param _owner The address of the owner of the new staking position
	 * @param _property The address of the Property as the staking destination
	 * @param _amount The amount of the new staking position
	 * @param _price The latest unit price of the cumulative staking reward
	 * @return uint256 The ID of the created new staking position
	 */
	function mint(
		address _owner,
		address _property,
		uint256 _amount,
		uint256 _price
	) external returns (uint256);

	/*
	 * @dev Updates the existing staking position.
	 * Update must be called from the Lockup contract.
	 * @param _tokenId The ID of the staking position
	 * @param _amount The new staking amount
	 * @param _price The latest unit price of the cumulative staking reward
	 * This value equals the 3rd return value of the Lockup.calculateCumulativeRewardPrices
	 * @param _cumulativeReward The cumulative withdrawn reward amount
	 * @param _pendingReward The pending withdrawal reward amount amount
	 * @return bool On success, true will be returned
	 */
	function update(
		uint256 _tokenId,
		uint256 _amount,
		uint256 _price,
		uint256 _cumulativeReward,
		uint256 _pendingReward
	) external returns (bool);

	/*
	 * @dev Gets the existing staking position.
	 * @param _tokenId The ID of the staking position
	 * @return StakingPositions staking positions
	 */
	function positions(uint256 _tokenId)
		external
		view
		returns (StakingPositions memory);

	/*
	 * @dev Gets the reward status of the staking position.
	 * @param _tokenId The ID of the staking position
	 * @return Rewards reward information
	 */
	function rewards(uint256 _tokenId) external view returns (Rewards memory);

	/*
	 * @dev get token ids by property
	 * @param _property property address
	 * @return uint256[] token id list
	 */
	function positionsOfProperty(address _property)
		external
		view
		returns (uint256[] memory);

	/*
	 * @dev get token ids by owner
	 * @param _owner owner address
	 * @return uint256[] token id list
	 */
	function positionsOfOwner(address _owner)
		external
		view
		returns (uint256[] memory);
}

// File: contracts/src/common/libs/Decimals.sol



/**
 * Library for emulating calculations involving decimals.
 */
library Decimals {
	uint120 private constant BASIS_VALUE = 1000000000000000000;

	/**
	 * @dev Returns the ratio of the first argument to the second argument.
	 * @param _a Numerator.
	 * @param _b Fraction.
	 * @return result Calculated ratio.
	 */
	function outOf(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256 result)
	{
		if (_a == 0) {
			return 0;
		}
		uint256 a = _a * BASIS_VALUE;
		if (a < _b) {
			return 0;
		}
		return a / _b;
	}

	/**
	 * @dev Returns multiplied the number by 10^18.
	 * @param _a Numerical value to be multiplied.
	 * @return Multiplied value.
	 */
	function mulBasis(uint256 _a) internal pure returns (uint256) {
		return _a * BASIS_VALUE;
	}

	/**
	 * @dev Returns divisioned the number by 10^18.
	 * This function can use it to restore the number of digits in the result of `outOf`.
	 * @param _a Numerical value to be divisioned.
	 * @return Divisioned value.
	 */
	function divBasis(uint256 _a) internal pure returns (uint256) {
		return _a / BASIS_VALUE;
	}
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol




/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// File: contracts/interface/IAddressRegistry.sol



interface IAddressRegistry {
	function setRegistry(string memory _key, address _addr) external;

	function registries(string memory _key) external view returns (address);
}

// File: contracts/src/common/registry/InitializableUsingRegistry.sol





/**
 * Module for using AddressRegistry contracts.
 */
abstract contract InitializableUsingRegistry is Initializable {
	address private _registry;

	/**
	 * Initialize the argument as AddressRegistry address.
	 */
	/* solhint-disable func-name-mixedcase */
	function __UsingRegistry_init(address _addressRegistry)
		internal
		initializer
	{
		_registry = _addressRegistry;
	}

	/**
	 * Returns the latest AddressRegistry instance.
	 */
	function registry() internal view returns (IAddressRegistry) {
		return IAddressRegistry(_registry);
	}

	/**
	 * Returns the AddressRegistry address.
	 */
	function registryAddress() external view returns (address) {
		return _registry;
	}
}

// File: contracts/src/lockup/Lockup.sol













/**
 * A contract that manages the staking of DEV tokens and calculates rewards.
 * Staking and the following mechanism determines that reward calculation.
 *
 * Variables:
 * -`M`: Maximum mint amount per block determined by Allocator contract
 * -`B`: Number of blocks during staking
 * -`P`: Total number of staking locked up in a Property contract
 * -`S`: Total number of staking locked up in all Property contracts
 * -`U`: Number of staking per account locked up in a Property contract
 *
 * Formula:
 * Staking Rewards = M * B * (P / S) * (U / P)
 *
 * Note:
 * -`M`, `P` and `S` vary from block to block, and the variation cannot be predicted.
 * -`B` is added every time the Ethereum block is created.
 * - Only `U` and `B` are predictable variables.
 * - As `M`, `P` and `S` cannot be observed from a staker, the "cumulative sum" is often used to calculate ratio variation with history.
 * - Reward withdrawal always withdraws the total withdrawable amount.
 *
 * Scenario:
 * - Assume `M` is fixed at 500
 * - Alice stakes 100 DEV on Property-A (Alice's staking state on Property-A: `M`=500, `B`=0, `P`=100, `S`=100, `U`=100)
 * - After 10 blocks, Bob stakes 60 DEV on Property-B (Alice's staking state on Property-A: `M`=500, `B`=10, `P`=100, `S`=160, `U`=100)
 * - After 10 blocks, Carol stakes 40 DEV on Property-A (Alice's staking state on Property-A: `M`=500, `B`=20, `P`=140, `S`=200, `U`=100)
 * - After 10 blocks, Alice withdraws Property-A staking reward. The reward at this time is 5000 DEV (10 blocks * 500 DEV) + 3125 DEV (10 blocks * 62.5% * 500 DEV) + 2500 DEV (10 blocks * 50% * 500 DEV).
 */
contract Lockup is ILockup, InitializableUsingRegistry {
	uint256 public override cap; // From [get/set]StorageCap
	uint256 public override totalLocked; // From [get/set]StorageAllValue
	uint256 public cumulativeHoldersRewardCap; // From [get/set]StorageCumulativeHoldersRewardCap
	uint256 public lastCumulativeHoldersPriceCap; // From [get/set]StorageLastCumulativeHoldersPriceCap
	uint256 public lastLockedChangedCumulativeReward; // From [get/set]StorageLastStakesChangedCumulativeReward
	uint256 public lastCumulativeHoldersRewardPrice; // From [get/set]StorageLastCumulativeHoldersRewardPrice
	uint256 public lastCumulativeRewardPrice; // From [get/set]StorageLastCumulativeInterestPrice
	uint256 public cumulativeGlobalReward; // From [get/set]StorageCumulativeGlobalRewards
	uint256 public lastSameGlobalRewardAmount; // From [get/set]StorageLastSameRewardsAmountAndBlock
	uint256 public lastSameGlobalRewardTimestamp; // From [get/set]StorageLastSameRewardsAmountAndBlock
	EnumerableSet.AddressSet private lockedupProperties;
	mapping(address => uint256)
		public lastCumulativeHoldersRewardPricePerProperty; // {Property: Value} // [get/set]StorageLastCumulativeHoldersRewardPricePerProperty
	mapping(address => uint256) public initialCumulativeHoldersRewardCap; // {Property: Value} // From [get/set]StorageInitialCumulativeHoldersRewardCap
	mapping(address => uint256) public override totalLockedForProperty; // {Property: Value} // From [get/set]StoragePropertyValue
	mapping(address => uint256)
		public lastCumulativeHoldersRewardAmountPerProperty; // {Property: Value} // From [get/set]StorageLastCumulativeHoldersRewardAmountPerProperty

	using Decimals for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	/**
	 * Initialize the passed address as AddressRegistry address.
	 */
	function initialize(address _registry) external initializer {
		__UsingRegistry_init(_registry);
	}

	/**
	 * @dev Validates the passed Property has greater than 1 asset.
	 * @param _property property address
	 */
	modifier onlyAuthenticatedProperty(address _property) {
		require(
			IMetricsFactory(registry().registries("MetricsFactory")).hasAssets(
				_property
			),
			"unable to stake to unauthenticated property"
		);
		_;
	}

	/**
	 * @dev Check if the owner of the token is a sender.
	 * @param _tokenId The ID of the staking position
	 */
	modifier onlyPositionOwner(uint256 _tokenId) {
		require(
			IERC721(registry().registries("STokensManager")).ownerOf(
				_tokenId
			) == msg.sender,
			"illegal sender"
		);
		_;
	}

	/**
	 * @dev deposit dev token to dev protocol and generate s-token
	 * @param _property target property address
	 * @param _amount staking value
	 * @return tokenId The ID of the created new staking position
	 */
	function depositToProperty(address _property, uint256 _amount)
		external
		override
		onlyAuthenticatedProperty(_property)
		returns (uint256)
	{
		/**
		 * Validates _amount is not 0.
		 */
		require(_amount != 0, "illegal deposit amount");
		/**
		 * Gets the latest cumulative sum of the interest price.
		 */
		(
			uint256 reward,
			uint256 holders,
			uint256 interest,
			uint256 holdersCap
		) = calculateCumulativeRewardPrices();
		/**
		 * Saves variables that should change due to the addition of staking.
		 */
		updateValues(
			true,
			_property,
			_amount,
			RewardPrices(reward, holders, interest, holdersCap)
		);
		/**
		 * transfer dev tokens
		 */
		require(
			IERC20(registry().registries("Dev")).transferFrom(
				msg.sender,
				_property,
				_amount
			),
			"dev transfer failed"
		);
		/**
		 * mint s tokens
		 */
		ISTokensManager sTokenManager = ISTokensManager(
			registry().registries("STokensManager")
		);
		if (sTokenManager.positionsOfProperty(_property).length == 0) {
			lockedupProperties.add(_property);
		}
		uint256 tokenId = sTokenManager.mint(
			msg.sender,
			_property,
			_amount,
			interest
		);
		emit Lockedup(msg.sender, _property, _amount, tokenId);

		return tokenId;
	}

	/**
	 * @dev deposit dev token to dev protocol and update s-token status
	 * @param _tokenId s-token id
	 * @param _amount staking value
	 * @return bool On success, true will be returned
	 */
	function depositToPosition(uint256 _tokenId, uint256 _amount)
		external
		override
		onlyPositionOwner(_tokenId)
		returns (bool)
	{
		/**
		 * Validates _amount is not 0.
		 */
		require(_amount != 0, "illegal deposit amount");
		ISTokensManager sTokenManager = ISTokensManager(
			registry().registries("STokensManager")
		);
		/**
		 * get position information
		 */
		ISTokensManager.StakingPositions memory positions = sTokenManager
			.positions(_tokenId);
		/**
		 * Gets the withdrawable amount.
		 */
		(
			uint256 withdrawable,
			RewardPrices memory prices
		) = _calculateWithdrawableInterestAmount(positions);
		/**
		 * Saves variables that should change due to the addition of staking.
		 */
		updateValues(true, positions.property, _amount, prices);
		/**
		 * transfer dev tokens
		 */
		require(
			IERC20(registry().registries("Dev")).transferFrom(
				msg.sender,
				positions.property,
				_amount
			),
			"dev transfer failed"
		);
		/**
		 * update position information
		 */
		bool result = sTokenManager.update(
			_tokenId,
			positions.amount + _amount,
			prices.interest,
			positions.cumulativeReward + withdrawable,
			positions.pendingReward + withdrawable
		);
		require(result, "failed to update");
		/**
		 * generate events
		 */
		emit Lockedup(msg.sender, positions.property, _amount, _tokenId);
		return true;
	}

	/**
	 * Withdraw staking.(NFT)
	 * Releases staking, withdraw rewards, and transfer the staked and withdraw rewards amount to the sender.
	 */
	function withdrawByPosition(uint256 _tokenId, uint256 _amount)
		external
		override
		onlyPositionOwner(_tokenId)
		returns (bool)
	{
		ISTokensManager sTokenManager = ISTokensManager(
			registry().registries("STokensManager")
		);
		/**
		 * get position information
		 */
		ISTokensManager.StakingPositions memory positions = sTokenManager
			.positions(_tokenId);
		/**
		 * If the balance of the withdrawal request is bigger than the balance you are staking
		 */
		require(positions.amount >= _amount, "insufficient tokens staked");
		/**
		 * Withdraws the staking reward
		 */
		(uint256 value, RewardPrices memory prices) = _withdrawInterest(
			positions
		);
		/**
		 * Transfer the staked amount to the sender.
		 */
		if (_amount != 0) {
			IProperty(positions.property).withdraw(msg.sender, _amount);
		}
		/**
		 * Saves variables that should change due to the canceling staking..
		 */
		updateValues(false, positions.property, _amount, prices);
		uint256 cumulative = positions.cumulativeReward + value;

		/**
		 * update position information
		 */
		bool result = sTokenManager.update(
			_tokenId,
			positions.amount - _amount,
			prices.interest,
			cumulative,
			0
		);
		if (totalLockedForProperty[positions.property] == 0) {
			lockedupProperties.remove(positions.property);
		}

		emit Withdrew(msg.sender, positions.property, _amount, value, _tokenId);
		/**
		 * update position information
		 */
		return result;
	}

	/**
	 * get lockup info
	 */
	function getLockedupProperties()
		external
		view
		override
		returns (LockedupProperty[] memory)
	{
		uint256 propertyCount = lockedupProperties.length();
		LockedupProperty[] memory results = new LockedupProperty[](
			propertyCount
		);
		for (uint256 i = 0; i < propertyCount; i++) {
			address property = lockedupProperties.at(i);
			uint256 value = totalLockedForProperty[property];
			results[i] = LockedupProperty(property, value);
		}
		return results;
	}

	/**
	 * set cap
	 */
	function updateCap(uint256 _cap) external override {
		address setter = registry().registries("CapSetter");
		require(setter == msg.sender, "illegal access");

		/**
		 * Updates cumulative amount of the holders reward cap
		 */
		(
			,
			uint256 holdersPrice,
			,
			uint256 cCap
		) = calculateCumulativeRewardPrices();

		// TODO: When this function is improved to be called on-chain, the source of `lastCumulativeHoldersPriceCap` can be rewritten to `lastCumulativeHoldersRewardPrice`.
		cumulativeHoldersRewardCap = cCap;
		lastCumulativeHoldersPriceCap = holdersPrice;
		cap = _cap;
		emit UpdateCap(_cap);
	}

	/**
	 * Returns the latest cap
	 */
	function _calculateLatestCap(uint256 _holdersPrice)
		private
		view
		returns (uint256)
	{
		uint256 cCap = cumulativeHoldersRewardCap;
		uint256 lastHoldersPrice = lastCumulativeHoldersPriceCap;
		uint256 additionalCap = (_holdersPrice - lastHoldersPrice) * cap;
		return cCap + additionalCap;
	}

	/**
	 * Store staking states as a snapshot.
	 */
	function beforeStakesChanged(address _property, RewardPrices memory _prices)
		private
	{
		/**
		 * Gets latest cumulative holders reward for the passed Property.
		 */
		uint256 cHoldersReward = _calculateCumulativeHoldersRewardAmount(
			_prices.holders,
			_property
		);

		/**
		 * Sets `InitialCumulativeHoldersRewardCap`.
		 * Records this value only when the "first staking to the passed Property" is transacted.
		 */
		if (
			lastCumulativeHoldersRewardPricePerProperty[_property] == 0 &&
			initialCumulativeHoldersRewardCap[_property] == 0 &&
			totalLockedForProperty[_property] == 0
		) {
			initialCumulativeHoldersRewardCap[_property] = _prices.holdersCap;
		}

		/**
		 * Store each value.
		 */
		lastLockedChangedCumulativeReward = _prices.reward;
		lastCumulativeHoldersRewardPrice = _prices.holders;
		lastCumulativeRewardPrice = _prices.interest;
		lastCumulativeHoldersRewardAmountPerProperty[
			_property
		] = cHoldersReward;
		lastCumulativeHoldersRewardPricePerProperty[_property] = _prices
			.holders;
		cumulativeHoldersRewardCap = _prices.holdersCap;
		lastCumulativeHoldersPriceCap = _prices.holders;
	}

	/**
	 * Gets latest value of cumulative sum of the reward amount, cumulative sum of the holders reward per stake, and cumulative sum of the stakers reward per stake.
	 */
	function calculateCumulativeRewardPrices()
		public
		view
		override
		returns (
			uint256 _reward,
			uint256 _holders,
			uint256 _interest,
			uint256 _holdersCap
		)
	{
		uint256 lastReward = lastLockedChangedCumulativeReward;
		uint256 lastHoldersPrice = lastCumulativeHoldersRewardPrice;
		uint256 lastInterestPrice = lastCumulativeRewardPrice;
		uint256 allStakes = totalLocked;

		/**
		 * Gets latest cumulative sum of the reward amount.
		 */
		(uint256 reward, ) = dry();
		uint256 mReward = reward.mulBasis();

		/**
		 * Calculates reward unit price per staking.
		 * Later, the last cumulative sum of the reward amount is subtracted because to add the last recorded holder/staking reward.
		 */
		uint256 price = allStakes > 0 ? (mReward - lastReward) / allStakes : 0;

		/**
		 * Calculates the holders reward out of the total reward amount.
		 */
		uint256 holdersShare = IPolicy(registry().registries("Policy"))
			.holdersShare(price, allStakes);

		/**
		 * Calculates and returns each reward.
		 */
		uint256 holdersPrice = holdersShare + lastHoldersPrice;
		uint256 interestPrice = price - holdersShare + lastInterestPrice;
		uint256 cCap = _calculateLatestCap(holdersPrice);
		return (mReward, holdersPrice, interestPrice, cCap);
	}

	/**
	 * Calculates cumulative sum of the holders reward per Property.
	 * To save computing resources, it receives the latest holder rewards from a caller.
	 */
	function _calculateCumulativeHoldersRewardAmount(
		uint256 _holdersPrice,
		address _property
	) private view returns (uint256) {
		(uint256 cHoldersReward, uint256 lastReward) = (
			lastCumulativeHoldersRewardAmountPerProperty[_property],
			lastCumulativeHoldersRewardPricePerProperty[_property]
		);

		/**
		 * `cHoldersReward` contains the calculation of `lastReward`, so subtract it here.
		 */
		uint256 additionalHoldersReward = (_holdersPrice - lastReward) *
			totalLockedForProperty[_property];

		/**
		 * Calculates and returns the cumulative sum of the holder reward by adds the last recorded holder reward and the latest holder reward.
		 */
		return cHoldersReward + additionalHoldersReward;
	}

	/**
	 * Calculates holders reward and cap per Property.
	 */
	function calculateRewardAmount(address _property)
		external
		view
		override
		returns (uint256, uint256)
	{
		(
			,
			uint256 holders,
			,
			uint256 holdersCap
		) = calculateCumulativeRewardPrices();
		uint256 initialCap = initialCumulativeHoldersRewardCap[_property];

		/**
		 * Calculates the cap
		 */
		uint256 capValue = holdersCap - initialCap;
		return (
			_calculateCumulativeHoldersRewardAmount(holders, _property),
			capValue
		);
	}

	/**
	 * Updates cumulative sum of the maximum mint amount calculated by Allocator contract, the latest maximum mint amount per block,
	 * and the last recorded block number.
	 * The cumulative sum of the maximum mint amount is always added.
	 * By recording that value when the staker last stakes, the difference from the when the staker stakes can be calculated.
	 */
	function update() public override {
		/**
		 * Gets the cumulative sum of the maximum mint amount and the maximum mint number per block.
		 */
		(uint256 _nextRewards, uint256 _amount) = dry();

		/**
		 * Records each value and the latest block number.
		 */
		cumulativeGlobalReward = _nextRewards;
		lastSameGlobalRewardAmount = _amount;
		lastSameGlobalRewardTimestamp = block.timestamp;
	}

	/**
	 * @dev Returns the maximum number of mints per block.
	 * @return Maximum number of mints per block.
	 */
	function calculateMaxRewardsPerBlock() private view returns (uint256) {
		uint256 totalAssets = IMetricsFactory(
			registry().registries("MetricsFactory")
		).metricsCount();
		uint256 totalLockedUps = totalLocked;
		return
			IPolicy(registry().registries("Policy")).rewards(
				totalLockedUps,
				totalAssets
			);
	}

	/**
	 * Referring to the values recorded in each storage to returns the latest cumulative sum of the maximum mint amount and the latest maximum mint amount per block.
	 */
	function dry()
		private
		view
		returns (uint256 _nextRewards, uint256 _amount)
	{
		/**
		 * Gets the latest mint amount per block from Allocator contract.
		 */
		uint256 rewardsAmount = calculateMaxRewardsPerBlock();

		/**
		 * Gets the maximum mint amount per block, and the last recorded block number from `LastSameRewardsAmountAndBlock` storage.
		 */
		(uint256 lastAmount, uint256 lastTs) = (
			lastSameGlobalRewardAmount,
			lastSameGlobalRewardTimestamp
		);

		/**
		 * If the recorded maximum mint amount per block and the result of the Allocator contract are different,
		 * the result of the Allocator contract takes precedence as a maximum mint amount per block.
		 */
		uint256 lastMaxRewards = lastAmount == rewardsAmount
			? rewardsAmount
			: lastAmount;

		/**
		 * Calculates the difference between the latest block number and the last recorded block number.
		 */
		uint256 time = lastTs > 0 ? block.timestamp - lastTs : 0;

		/**
		 * Adds the calculated new cumulative maximum mint amount to the recorded cumulative maximum mint amount.
		 */
		uint256 additionalRewards = lastMaxRewards * time;
		uint256 nextRewards = cumulativeGlobalReward + additionalRewards;

		/**
		 * Returns the latest theoretical cumulative sum of maximum mint amount and maximum mint amount per block.
		 */
		return (nextRewards, rewardsAmount);
	}

	/**
	 * Returns the staker reward as interest.
	 */
	function _calculateInterestAmount(uint256 _amount, uint256 _price)
		private
		view
		returns (
			uint256 amount_,
			uint256 interestPrice_,
			RewardPrices memory prices_
		)
	{
		/**
		 * Gets the latest cumulative sum of the interest price.
		 */
		(
			uint256 reward,
			uint256 holders,
			uint256 interest,
			uint256 holdersCap
		) = calculateCumulativeRewardPrices();

		/**
		 * Calculates and returns the latest withdrawable reward amount from the difference.
		 */
		uint256 result = interest >= _price
			? ((interest - _price) * _amount).divBasis()
			: 0;
		return (
			result,
			interest,
			RewardPrices(reward, holders, interest, holdersCap)
		);
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from inside the contract)
	 */
	function _calculateWithdrawableInterestAmount(
		ISTokensManager.StakingPositions memory positions
	) private view returns (uint256 amount_, RewardPrices memory prices_) {
		/**
		 * If the passed Property has not authenticated, returns always 0.
		 */
		if (
			IMetricsFactory(registry().registries("MetricsFactory")).hasAssets(
				positions.property
			) == false
		) {
			return (0, RewardPrices(0, 0, 0, 0));
		}

		/**
		 * Gets the latest withdrawal reward amount.
		 */
		(
			uint256 amount,
			,
			RewardPrices memory prices
		) = _calculateInterestAmount(positions.amount, positions.price);

		/**
		 * Returns the sum of all values.
		 */
		uint256 withdrawableAmount = amount + positions.pendingReward;
		return (withdrawableAmount, prices);
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from external of the contract)
	 */
	function calculateWithdrawableInterestAmountByPosition(uint256 _tokenId)
		external
		view
		override
		returns (uint256)
	{
		ISTokensManager sTokensManagerInstance = ISTokensManager(
			registry().registries("STokensManager")
		);
		ISTokensManager.StakingPositions
			memory positions = sTokensManagerInstance.positions(_tokenId);
		(uint256 result, ) = _calculateWithdrawableInterestAmount(positions);
		return result;
	}

	/**
	 * Withdraws staking reward as an interest.
	 */
	function _withdrawInterest(
		ISTokensManager.StakingPositions memory positions
	) private returns (uint256 value_, RewardPrices memory prices_) {
		/**
		 * Gets the withdrawable amount.
		 */
		(
			uint256 value,
			RewardPrices memory prices
		) = _calculateWithdrawableInterestAmount(positions);

		/**
		 * Mints the reward.
		 */
		require(
			IDevBridge(registry().registries("DevBridge")).mint(
				msg.sender,
				value
			),
			"dev mint failed"
		);

		/**
		 * Since the total supply of tokens has changed, updates the latest maximum mint amount.
		 */
		update();

		return (value, prices);
	}

	/**
	 * Status updates with the addition or release of staking.
	 */
	function updateValues(
		bool _addition,
		address _property,
		uint256 _value,
		RewardPrices memory _prices
	) private {
		beforeStakesChanged(_property, _prices);
		/**
		 * If added staking:
		 */
		if (_addition) {
			/**
			 * Updates the current staking amount of the protocol total.
			 */
			addAllValue(_value);

			/**
			 * Updates the current staking amount of the Property.
			 */
			addPropertyValue(_property, _value);

			/**
			 * If released staking:
			 */
		} else {
			/**
			 * Updates the current staking amount of the protocol total.
			 */
			subAllValue(_value);

			/**
			 * Updates the current staking amount of the Property.
			 */
			subPropertyValue(_property, _value);
		}

		/**
		 * Since each staking amount has changed, updates the latest maximum mint amount.
		 */
		update();
	}

	/**
	 * Adds the staking amount of the protocol total.
	 */
	function addAllValue(uint256 _value) private {
		uint256 value = totalLocked;
		value = value + _value;
		totalLocked = value;
	}

	/**
	 * Subtracts the staking amount of the protocol total.
	 */
	function subAllValue(uint256 _value) private {
		uint256 value = totalLocked;
		value = value - _value;
		totalLocked = value;
	}

	/**
	 * Adds the staking amount of the Property.
	 */
	function addPropertyValue(address _property, uint256 _value) private {
		uint256 value = totalLockedForProperty[_property];
		value = value + _value;
		totalLockedForProperty[_property] = value;
	}

	/**
	 * Subtracts the staking amount of the Property.
	 */
	function subPropertyValue(address _property, uint256 _value) private {
		uint256 value = totalLockedForProperty[_property];
		uint256 nextValue = value - _value;
		totalLockedForProperty[_property] = nextValue;
	}
}