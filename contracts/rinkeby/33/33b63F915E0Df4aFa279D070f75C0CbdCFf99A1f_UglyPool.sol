pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract UglyPool is IERC721Receiver, Ownable(){

    struct pool {
        IERC721 registry;
        address owner;
        uint[] tokenIDs;
        uint256 price;
        uint256 balance;
        bool random;
    }

    pool[] pools;

    mapping(address => uint256[]) internal ownerDirectory;
    mapping(IERC721 => uint256[]) internal registryDirectory;

    event AddedToPool(IERC721 indexed registry, uint256 indexed tokenID, address sender);
    event TradeExecuted(IERC721 indexed registry, uint256 indexed tokenID);

    constructor() { 
        // Set Regular NFT contract owner
        // owners[IERC721(0x6d0de90CDc47047982238fcF69944555D27Ecb25)] = msg.sender;
    }

    function createPool(IERC721 _registry, uint[] memory _tokenIDs, uint _price, bool _random) public payable returns(bool success) {
        pool memory _pool = pool({
            registry : _registry,
            owner : msg.sender,
            tokenIDs : _tokenIDs,
            price : _price,
            balance : msg.value,
            random : _random
        });
        uint _index = pools.length;
        pools.push(_pool);
        ownerDirectory[msg.sender].push(_index);
        registryDirectory[_registry].push(_index);
        // send the NFTs
        for (uint i; i < _tokenIDs.length; i++){
            _registry.safeTransferFrom(msg.sender,  address(this), _tokenIDs[i]);
            emit AddedToPool(_registry, _tokenIDs[i], msg.sender);
        }
        return true;
    }

    function getPoolID(address _owner, IERC721 _registry) public view returns(uint) {
        uint[] memory poolIDs = ownerDirectory[_owner];
        for (uint i = 0; i < poolIDs.length;i++){
            if (pools[poolIDs[i]].registry == _registry)
                return poolIDs[i];
        }
        revert("Pool not found.");
    }

    function getPool(address _owner, IERC721 _registry) public view returns(pool memory) {
        return pools[getPoolID(_owner,_registry)];
    }

    function getPoolByID(uint _id) public view returns(pool memory){
        return pools[_id];
    }

    function poolIDsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerDirectory[_owner];
    }

    function poolIDsByRegistery(IERC721 _registry) public view returns (uint256[] memory){
        return registryDirectory[_registry];
    }

    function poolCountById(uint _id) public view returns (uint) {
        return pools[_id].tokenIDs.length;
    }

    function withdrawFromPool(IERC721 _registry, uint _count) public { 
        pool memory _pool = getPool(msg.sender, _registry);
        require(_pool.owner == msg.sender, "You are not the pool owner"); 
        require(_count <= _pool.tokenIDs.length, "Not enough NFTs in the pool");

        for (uint i;i < _count;i++){
           _registry.safeTransferFrom( address(this), msg.sender, _pool.tokenIDs[i]);
           delete _pool.tokenIDs[i];
        }
    }

    // swaps random ugly
    function swapUgly(IERC721 _registry, uint _id) public { 
        pool memory _pool = getPool(msg.sender, _registry);
        require(_pool.tokenIDs.length > 0, "Nothing in pool.");

        uint _randomID = uint(generateRandom()) % _pool.tokenIDs.length;
        
        _registry.safeTransferFrom(msg.sender,  address(this), _id);
        _registry.safeTransferFrom( address(this), msg.sender, _randomID);

        _pool.tokenIDs[_randomID] = _id;

        emit TradeExecuted(_registry, _id); 
    }

    function sellUgly(IERC721 _registry, uint _id) public { // this should probably take an array of uints
        _registry.safeTransferFrom(msg.sender,  address(this), _id);
        pools[getPoolID(msg.sender, _registry)].tokenIDs.push(_id);
        uint _price = pools[getPoolID(msg.sender, _registry)].price;
        pools[getPoolID(msg.sender, _registry)].balance -= _price;
        payable(msg.sender).transfer(_price);
    }

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

    function poolBalance(IERC721 _registry) public returns (uint) {
        return getPool(msg.sender, _registry).balance;
    }

    // function poolSize(IERC721 _registry) public view returns (uint) {
    //     return pools[_registry].length;
    // }

    // function isOwner(IERC721 _registry, uint _id) public view returns (bool) {
    //     return _registry.ownerOf(_id) == msg.sender;
    // }

    // function getOwner(IERC721 _registry, uint _id) public view returns (address){
    //     return _registry.ownerOf(_id);
    // }

    // function showPool(IERC721 _registry) public view returns (uint[] memory){
    //     return pools[_registry];
    // }

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