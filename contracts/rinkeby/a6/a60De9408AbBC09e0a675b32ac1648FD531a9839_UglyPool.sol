pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface NFTContract {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function name() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract UglyPool is IERC721Receiver, Ownable() {
    using EnumerableSet for EnumerableSet.UintSet;

    struct pool {
        IERC721 registry;
        address owner;
        uint256 price;
        uint256 balance;
        bool random; 
    }

    uint public version = 9;

    pool[] public pools;

    mapping(uint => EnumerableSet.UintSet) tokenIds;
    mapping(address => uint256[]) internal ownerDirectory;
    mapping(IERC721 => uint256[]) internal registryDirectory;

    event AddedToPool(IERC721 indexed registry, uint256 indexed tokenId, address sender);
    event TradeExecuted(IERC721 indexed registry, address user, uint256 indexed inTokenId, uint256 indexed outTokenId);

    constructor(){
        // set pools[0] to nothing
        uint[] memory emptyArray;
        createPool(IERC721(0x0000000000000000000000000000000000000000),emptyArray,0, false);

        // //testing data (regular contract)
        // createPool(IERC721(0x6d0de90CDc47047982238fcF69944555D27Ecb25),emptyArray,50000000000000000, true);
    }

    // Create a new pool owned by msg.sender
    // _registry : address of NFT token contract
    // _tokenIds : array of ids of NFTs owned by msg sender (these will be sent to pool)
    // _price : 'buyback price'.. if there is ether sent to the pool, anyone can sell a NFT to the pool for this price
    // _random : if true, the pool will swap for a random NFT. Otherwise the users can choose
    function createPool(IERC721 _registry, uint[] memory _tokenIds, uint _price, bool _random) public payable { 
        require(!poolExists(msg.sender, _registry),"You already own this pool.");
        pool memory _pool = pool({
            registry : _registry,
            owner : msg.sender,
            price : _price,
            balance : msg.value, 
            random : _random
        });
        uint _poolId = pools.length;
        pools.push(_pool);
        setTokenIds(_tokenIds, _poolId);
        ownerDirectory[msg.sender].push(_poolId);
        registryDirectory[_registry].push(_poolId);
        // send the NFTs
        for (uint i; i < _tokenIds.length; i++){
            _registry.safeTransferFrom(msg.sender,  address(this), _tokenIds[i]);
            emit AddedToPool(_registry, _tokenIds[i], msg.sender);
        }
    }

    function depositEth(IERC721 _registry) public payable {
        uint _poolId = getPoolId(msg.sender, _registry);
        pools[_poolId].balance += msg.value;
    }

    function depositNFTs(IERC721 _registry, uint[] memory _tokenIds) public payable { 
        uint _poolId = getPoolId(msg.sender, _registry);
        for (uint i; i < _tokenIds.length; i++){
            _registry.safeTransferFrom(msg.sender,  address(this), _tokenIds[i]);
            tokenIds[_poolId].add(_tokenIds[i]);
            emit AddedToPool(_registry, _tokenIds[i], msg.sender);
        }
    }

    function setBuybackPrice(IERC721 _registry, uint _newPrice) public {
        uint _poolId = getPoolId(msg.sender, _registry);
        pools[_poolId].price = _newPrice;
    }

    function withdrawEth(IERC721 _registry) public { 
        uint _poolId = getPoolId(msg.sender, _registry);
        uint _balance = pools[_poolId].balance;
        pools[_poolId].balance = 0;
        payable(msg.sender).transfer(_balance);
    }

    function withdrawNFTs(IERC721 _registry, uint _count) public { 
        uint _poolId = getPoolId(msg.sender, _registry);
        require(_count <= tokenIds[_poolId].length(), "Not enough NFTs in the pool");

        for (uint i;i < _count;i++){
           _registry.safeTransferFrom( address(this), msg.sender, tokenIds[_poolId].at(i));
           tokenIds[_poolId].remove(tokenIds[_poolId].at(i));
        }
    }

    // function getBalance() public view returns (uint) {
    //     return address(this).balance;
    // }

    function getPoolId(address _owner, IERC721 _registry) public view returns(uint) {
        uint[] memory poolIds = ownerDirectory[_owner];
        for (uint i = 0; i < poolIds.length;i++){
            if (pools[poolIds[i]].registry == _registry)
                return poolIds[i];
        }
        revert("Pool not found.");
    }

    function getPoolNFTIds(IERC721 _registry, address _poolOwner) public view returns (uint[] memory){ // address _owner, 
        uint _poolId = getPoolId(_poolOwner, _registry); // UPDATED
        return tokenIds[_poolId].values();
    }

    function poolExists(address _owner, IERC721 _registry) private view returns(bool) {
        uint[] memory poolIds = ownerDirectory[_owner];
        for (uint i = 0; i < poolIds.length;i++){
            if (pools[poolIds[i]].registry == _registry)
                return true;
        }
        return false;
    }



    function ethBalance(IERC721 _registry, address _poolOwner) public view returns (uint) { // 
        uint _poolId = getPoolId(_poolOwner, _registry);
        return pools[_poolId].balance;
    }

    function nftBalance(IERC721 _registry, address _poolOwner) public view returns (uint) { // 
        uint _poolId = getPoolId(_poolOwner, _registry);
        return tokenIds[_poolId].length();
    }

    // // swaps random ugly
    function swapRandomUgly(uint _poolId, uint _id) public returns (uint) { 
        IERC721 _registry = pools[_poolId].registry;
        require(pools[_poolId].random == true,"This pool is not for random swaps.");
        require(tokenIds[_poolId].length() > 0, "Nothing in pool.");
        uint _randomIndex = uint(generateRandom()) % tokenIds[_poolId].length();
        uint _randomId = tokenIds[_poolId].at(_randomIndex);

        _registry.safeTransferFrom(msg.sender,  address(this), _id);
        _registry.safeTransferFrom( address(this), msg.sender, _randomId);
        tokenIds[_poolId].remove(_randomId);
        tokenIds[_poolId].add(_id);
        emit TradeExecuted(_registry, msg.sender, _id, _randomId); 
        return _randomId;
    }

    // // swaps for specific ugly
    function swapUgly(uint _poolId, uint _idFromPool, uint _idToPool) public { 
        IERC721 _registry = pools[_poolId].registry;
        require(pools[_poolId].random == false,"This pool only allows random swaps.");
        require(tokenIds[_poolId].length() > 0, "Nothing in pool.");

        _registry.safeTransferFrom(msg.sender,  address(this), _idFromPool);
        _registry.safeTransferFrom( address(this), msg.sender, _idToPool);
        tokenIds[_poolId].remove(_idToPool);
        tokenIds[_poolId].add(_idFromPool);
        emit TradeExecuted(_registry, msg.sender, _idFromPool, _idToPool); 
    }

    function sellUglies(uint _poolId, uint[] memory _ids) public { 
        IERC721 _registry = pools[_poolId].registry;
        uint _price = pools[_poolId].price;
        require(_price > 0, "price not set.");
        require(pools[_poolId].balance >= _price * _ids.length ,"not enough funds in pool.");
        for (uint i = 0; i < _ids.length;i++){
            _registry.safeTransferFrom(msg.sender,  address(this), _ids[i]);
            tokenIds[_poolId].add(_ids[i]);
            pools[_poolId].balance -= _price;
            payable(msg.sender).transfer(_price);
        }
    }

    function poolIdsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerDirectory[_owner];
    }

    function poolIdsByRegistery(IERC721 _registry) public view returns (uint256[] memory){
        return registryDirectory[_registry];
    }

    function numPools() public view returns (uint) {
        return pools.length;
    }

    // function poolSizeById(uint _Id) public view returns (uint) {
    //     return tokenIds[_Id].length();
    // }

    function onERC721Received( address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;// ^ this.transfer.selector; <--- i dont know what this does
    }

    function generateRandom() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    function setTokenIds(uint[] memory _myArray, uint _poolId) private  {
        for (uint i = 0; i < _myArray.length;i++){
            tokenIds[_poolId].add(_myArray[i]);
        }
    }

    // Proxy Methods

    function allNFTsByAddress(address _wallet, address _registry) public view returns(uint[] memory){
        uint[] memory nfts = new uint[](balanceOfNFTs(_wallet, _registry));
        for (uint i = 0; i < nfts.length;i++){
            nfts[i] = tokenOfOwnerByIndex(_wallet, i, _registry);
        }
        return nfts;
    }

    // function ownerOfNFT(uint _tokenId) private view returns (address) {
    //     return NFTContract(_registry).ownerOf(_tokenId);
    // }

    // All NFTs in collection owned by wallet address
    function balanceOfNFTs(address _address, address _registry) private view returns (uint) {
        return NFTContract(_registry).balanceOf(_address);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index, address _registry) private view returns (uint256) {
        return NFTContract(_registry).tokenOfOwnerByIndex(_owner,_index);
    }

    function registryName(address _registry) public view returns (string memory){
        return NFTContract(_registry).name();
    }

    function tokenURI(address _registry, uint256 tokenId) public view returns (string memory){
        return NFTContract(_registry).tokenURI(tokenId);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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