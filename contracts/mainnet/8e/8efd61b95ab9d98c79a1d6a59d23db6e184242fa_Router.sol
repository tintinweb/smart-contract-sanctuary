/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

interface IMerge {
    function balanceOf(address account) external view returns (uint256);
    function massOf(uint256 tokenId) external view returns (uint256);
    function tokenOf(address account) external view returns (uint256);
    function getValueOf(uint256 tokenId) external view returns (uint256);
    function decodeClass(uint256 value) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isWhitelisted(address account) external view returns (bool);
    function isBlacklisted(address account) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}

interface IWalletProxyManager {
    function indexToWallet(uint256 class, uint256 index) external view returns (address);
    function currentIndex(uint256 class) external view returns (uint256);
}

interface IWalletProxyFactory {
    function createWallet(uint256 class) external returns (address);
}

contract Router is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Emitted when `account` contributes `tokenId` with `mass` to DAO.
     */
    event Contribute(address indexed account, address indexed wallet, uint256 tokenId, uint256 class, uint256 weight);

    uint256 public totalWeight;  // The cumulative weight of contributed NFTs

    address public merge;  // The Merge contract

    address public gToken;  // Governance token

    address public manager;  // Wallet proxy manager

    address public factory;  // factory contract address

    address public contender;  // AlphaMass contender wallet, only tier 1 NFTs are sent to this AlphaMass wallet

    address public red;  // red wallet for tier 4

    address public yellow;  // yellow wallet for tier 3

    address public blue;  // blue wallet for tier 2

    uint256 public constant WEIGHT_MULTIPLIER = 10_000 * 1e9;  // a multiplier to a weight

    uint256 public BONUS_MULTIPLIER;  // a bonus multiplier in percentage

    uint256 public cap;  // The soft cap for a wallet of a certain classId

    bool public isEnded; // a bool indicator on whether the game has ended.

    mapping(address => mapping(uint256 => uint256)) public weights;  // weights of each contributor by class

    mapping(address => uint256[]) public contributedClasses;  // Contributed classes

    mapping(uint256 => uint256) public contributionsOfEachClass;  // num of contributions for each class

    mapping(address => bool) public specialWallets;  // DAO, contender, blue, red, yellow are all special wallets

    EnumerableSet.AddressSet contributors;  // Contributors to this DAO

    /**
     * @param merge_ address contract address of merge
     * @param gToken_ address contract address of governance token
     * @param manager_ address contract address for wallet manager
     * @param factory_ address contract address for wallet factory
     * @param contender_ address AlphaMass Contender wallet
     * @param blue_ address wallet for tier blue
     * @param yellow_ address wallet for tier yellow
     * @param red_ address wallet for tier red
     */
    constructor(
        address merge_,
        address gToken_,
        address manager_,
        address factory_,
        address contender_,
        address blue_,
        address yellow_,
        address red_)
    {
        if (merge_ == address(0) ||
            gToken_ == address(0) ||
            manager_ == address(0) ||
            factory_ == address(0) ||
            contender_ == address(0) ||
            blue_ == address(0) ||
            yellow_ == address(0) ||
            red_ == address(0)) revert("Invalid address");

        cap = 50;  // soft cap
        BONUS_MULTIPLIER = 120;

        merge = merge_;
        gToken = gToken_;
        manager = manager_;
        factory = factory_;
        contender = contender_;
        blue = blue_;
        yellow = yellow_;
        red = red_;

        specialWallets[contender] = true;
        specialWallets[blue] = true;
        specialWallets[yellow] = true;
        specialWallets[red] = true;
    }

    /**
     * @dev Make a contribution with the nft in the caller's wallet.
     */
    function contribute() external {
        require(!isEnded, "Already ended");
        address account = _msgSender();
        require(!_validateAccount(account), "Invalid caller");

        _contribute(account);
    }

    /**
     * @dev Toggle the special status of a wallet between true and false.
     */
    function toggleSpecialWalletStatus(address wallet) external onlyOwner {
        specialWallets[wallet] = !specialWallets[wallet];
    }

    /**
     * @dev Transfer NFTs if there is any in this contract to address `to`.
     */
    function transfer(address to) external onlyOwner {
        require(isEnded, "Not ended");
        uint256 tokenId = _tokenOf(address(this));
        require(tokenId != 0, "No token to be transferred in this contract");
        require(specialWallets[to], "Must transfer to a special wallet");

        _transfer(address(this), to, tokenId);
    }

    /**
     * @dev Required by {IERC721-safeTransferFrom}.
     */
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev End the game of competing in Pak Merge.
     */
    function endGame() external onlyOwner {
        require(!isEnded, "Already ended");
        isEnded = true;
    }

    /**
     * @dev Set the soft cap for each wallet.
     */
    function setCap(uint256 cap_) external onlyOwner {
        cap = cap_;
    }

    /**
     * @dev Set the wallet `contender_` for AlphaMass contentder.
     */
    function setContenderWallet(address contender_) external onlyOwner {
        contender = contender_;
    }

    /**
     * @dev Set the wallet `red_` for red tier.
     */
    function setRed(address red_) external onlyOwner {
        red = red_;
    }

    /**
     * @dev Set the wallet `yellow_` for yellow tier.
     */
    function setYellow(address yellow_) external onlyOwner {
        yellow = yellow_;
    }

    /**
     * @dev Set the wallet `blue_` for blue tier.
     */
    function setBlue(address blue_) external onlyOwner {
        blue = blue_;
    }

    /**
     * @dev Set the `multiplier_` for BONUS_MULTIPLIER.
     */
    function setBonusMultiplier(uint256 multiplier_) external onlyOwner {
        if (multiplier_ < 100 || multiplier_ >= 200) revert("Out of range");

        BONUS_MULTIPLIER = multiplier_;
    }

    /**
     * @dev Returns if a given `account` is a contributor.
     */
    function isContributor(address account) external view returns (bool) {
        return contributors.contains(account);
    }

    /**
     * @dev Returns the current active `tokenId` for a given `class`.
     */
    function getTokenIdForClass(uint256 class) external view returns (uint256) {
        return _tokenOf(_getWalletByClass(class));
    }

    /**
     * @dev Returns all `tokenId`s for a given `class`.
     */
    function getTokenIdsForClass(uint256 class) external view returns (uint256[] memory) {
        uint256 index = _getClassIndex(class);
        uint256[] memory tokenIds = new uint256[](index+1);
        if (index == 0) {
            tokenIds[0] = _tokenOf(_getWalletByClass(class));
            return tokenIds;
        } else {
            for (uint256 i = 0; i < index+1; i++) {
                tokenIds[i] = _tokenOf(_getWalletByIndex(class, i));
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns the mass for `tokenId`.
     */
    function massOf(uint256 tokenId) external view returns (uint256) {
        return _massOf(tokenId);
    }

    /**
     * @dev Returns the number of contributors to this contract.
     */
    function getNumOfContributors() external view returns (uint256) {
        return contributors.length();
    }

    /**
     * @dev Returns the total weight of `account` across all classes.
     */
    function getWeightForAccount(address account) external view returns (uint256 weight) {
        uint256[] memory classes = contributedClasses[account];
        for (uint256 i = 0; i < classes.length; i++) {
            weight += weights[account][classes[i]];
        }
    }

    /**
     * @dev Execute the logic of making a contribution by `account`.
     */
    function _contribute(address account) private {
        uint256 tokenId = _tokenOf(account);
        uint256 weight = _massOf(tokenId);
        (address targetWallet, uint256 class) = _getTargetWallet(tokenId);

        _transfer(account, targetWallet, tokenId);
        _mint(account, weight);
        _updateInfo(account, class, weight);

        emit Contribute(account, targetWallet, tokenId, class, weight);
    }

    /**
     * @dev Returns the wallet address for given `class` and `index`.
     */
    function _getWalletByIndex(uint256 class, uint256 index) private view returns (address) {
        return IWalletProxyManager(manager).indexToWallet(class, index);
    }

    /**
     * @dev Returns the currently active wallet address by `class`.
     */
    function _getClassIndex(uint256 class) private view returns (uint256) {
        return IWalletProxyManager(manager).currentIndex(class);
    }

    /**
     * @dev Returns the target wallet address by `class` and `tokenId`.
     */
    function _getTargetWallet(uint256 tokenId) private returns (address wallet, uint256 class) {
        uint256 tier = _tierOf(tokenId);
        class = _classOf(tokenId);

        if (tier == 4) {
            wallet = red;
        } else if (tier == 3) {
            wallet = yellow;
        } else if (tier == 2) {
            wallet = blue;
        } else if (tier == 1) {
            if (_massOf(tokenId) >= cap) {
                wallet = contender;
            } else {
                wallet = _getWalletByClass(class);

                // No wallet for this class has been created yet.
                if (wallet == address(0)) {
                    wallet = _createWalletByClass(class);
                    require(wallet == _getWalletByClass(class), "Mismatch");
                } else {
                    uint256 _tokenId = _tokenOf(wallet);
                    if (_tokenId != 0) {
                        if (_massOf(_tokenId) >= cap) {  // Current wallet has reached the cap
                            wallet = _createWalletByClass(class);
                            require(wallet == _getWalletByClass(class), "Mismatch");
                        } else {
                            if (_classOf(_tokenId) != class) {
                                wallet = _createWalletByClass(class);
                                require(wallet == _getWalletByClass(class), "Mismatch");
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @dev Creates a new wallet for a given `class`.
     */
    function _createWalletByClass(uint256 class) private returns (address) {
        return IWalletProxyFactory(factory).createWallet(class);
    }

    /**
     * @dev Returns the currently active wallet address by `class`.
     */
    function _getWalletByClass(uint256 class) private view returns (address) {
        uint256 index = _getClassIndex(class);
        return IWalletProxyManager(manager).indexToWallet(class, index);
    }

    /**
     * @dev Mint governance tokens based on the weight of NFT the caller contributed
     */
    function _mint(address to, uint256 weight) private {
        IERC20Mintable(gToken).mint(to, weight * WEIGHT_MULTIPLIER * BONUS_MULTIPLIER / 100);
    }

    /**
     * @dev Transfer NFT with `tokenId` from address `from` to address `to`.
     * Checking if address `to` is valid is built in the function safeTransferFrom.
     */
    function _transfer(address from, address to, uint256 tokenId) private {
        _beforeTokenTransfer(from, to, tokenId);
        IMerge(merge).safeTransferFrom(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev A hook function checking if the mass of the NFT in the `to` wallet
     * has reached the soft cap before it is being transferred.
     */
    function _beforeTokenTransfer(address, address to, uint256) private view {
        if (!specialWallets[to]) {
            if (_tokenOf(to) != 0) {  // a non-existent token
                require(_massOf(_tokenOf(to)) < cap, "Exceeding cap");
            }
        }
    }

    /**
     * @dev A hook function creates a new wallet with the same class to `tokenId`
     * if the `to` wallet has reached the soft cap.
     */
    function _afterTokenTransfer(address, address to, uint256 tokenId) private {
        if (!specialWallets[to]) {
            if (_massOf(_tokenOf(to)) >= cap) {
                _createWalletByClass(_classOf(tokenId));
            }
        }
    }

    /**
     * @dev Update info for `account` and `tokenId` with `weight`
     */
    function _updateInfo(address account, uint256 class, uint256 weight) private {
        if (weights[account][class] == 0) {
            contributors.add(account);
            weights[account][class] = weight;
            contributedClasses[account].push(class);
        } else {
            weights[account][class] += weight;
        }

        totalWeight += weight;
        contributionsOfEachClass[class]++;
    }

    /**
     * @dev Returns if a given account is whitelisted or blacklisted, or does not
     * have a Merge NFT.
     */
    function _validateAccount(address account) private view returns (bool) {
        bool cond1 = IMerge(merge).isWhitelisted(account);
        bool cond2 = IMerge(merge).isBlacklisted(account);
        bool cond3 = _balanceOf(account) == 0;
        return cond1 || cond2 || cond3;
    }

    /**
     * @dev Retrieves the class/tier of token with `tokenId`.
     */
    function _tierOf(uint256 tokenId) private view returns (uint256) {
        return IMerge(merge).decodeClass(_valueOf(tokenId));
    }

    /**
     * @dev Retrieves the class of token with `tokenId`, i.e., the last two digits
     * of `tokenId`.
     */
    function _classOf(uint256 tokenId) private pure returns (uint256) {
        return tokenId % 100;
    }

    /**
     * @dev Retrieves the value of token with `tokenId`.
     */
    function _valueOf(uint256 tokenId) private view returns (uint256) {
        return IMerge(merge).getValueOf(tokenId);
    }

    /**
     * @dev Returns the `tokenId` held by `account`. Returns 0 if `account`
     * does not have a token.
     */
    function _tokenOf(address account) private view returns (uint256) {
        return IMerge(merge).tokenOf(account);
    }

    /**
     * @dev Returns the `mass` of a token given `tokenId`.
     */
    function _massOf(uint256 tokenId) private view returns (uint256) {
        return IMerge(merge).massOf(tokenId);
    }

    /**
     * @dev Returns the balance of an `account`, either 0 or 1.
     */
    function _balanceOf(address account) private view returns (uint256) {
        return IMerge(merge).balanceOf(account);
    }
}