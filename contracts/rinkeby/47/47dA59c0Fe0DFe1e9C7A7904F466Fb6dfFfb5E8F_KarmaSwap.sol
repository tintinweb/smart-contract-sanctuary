/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface NiftyBuilderInstance {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address); 
}

interface NFTmint {
    function batchMint(address _to, uint256 _numberOfToken) external;
    function mint(address _to) external;
}

contract KarmaSwap is Ownable, Pausable, ReentrancyGuard {
    
    mapping(address => bool) public isWhIsBeBurningCollection;
    mapping(address => bool) public isWhIsBeGiftingCollection;
    mapping(uint256 => bool) public tokenClaimed;
    mapping(address => uint256) public burnToKarma;
    
    address[] public collections;
    NFTmint mintingContract;
    address public burnAddress;

    /**
     * @dev Initializes the contract settings
     */
    constructor(address[] memory _WhisbeCollections, address _mintingContract, address _burnAddress)
    {   
        require(_mintingContract != address(0), "KarmaSwap: minting contract cannot be zero");
        require(_burnAddress != address(0), "KarmaSwap: burn address cannot be zero");
        for(uint256 i=0; i < _WhisbeCollections.length; i++){
            address collection = _WhisbeCollections[i];
            isWhIsBeBurningCollection[collection] = true;
            collections.push(collection);
        }
        mintingContract= NFTmint(_mintingContract);
        burnAddress = _burnAddress;
    }
    function getAllCollections() public view returns(address[] memory){
        return collections;
    }
    function changeBurnAddress(address _burnAddress) 
        public 
        onlyOwner 
    {
        require(_burnAddress != address(0), "KarmaSwap: burn address cannot be zero");
        burnAddress = _burnAddress;
    }
    
    function setBurnToKarmaTokens(uint256 _collectionId, uint256 _numberOfTokens) 
        public
        onlyOwner
    {
        require(isWhIsBeBurningCollection[collections[_collectionId]], "KarmaSwap: collection not a burning collection");
        burnToKarma[collections[_collectionId]] = _numberOfTokens;
    }

    
    function addGiftingCollection(address _collection)
        public
        onlyOwner
    {
        require(!isWhIsBeGiftingCollection[_collection], "KarmaSwap: Gifting collection already added");
        isWhIsBeGiftingCollection[_collection] = true;
        collections.push(_collection);
    }
    
    function addBurningCollection(address _collection)
        public
        onlyOwner
    {
        require(!isWhIsBeBurningCollection[_collection], "KarmaSwap: Burning collection already added");
        isWhIsBeBurningCollection[_collection] = true;
        collections.push(_collection);
    }
    
    function removeBurningCollection(uint _collectionId)
        public
        onlyOwner
    {
        require(isWhIsBeBurningCollection[collections[_collectionId]], "KarmaSwap: Burning collection not added");
        isWhIsBeBurningCollection[collections[_collectionId]] = false;
        collections[_collectionId] = collections[collections.length - 1];
        collections.pop();
    }
    
    function removeGiftingCollection(uint _collectionId)
        public
        onlyOwner
    {
        require(isWhIsBeGiftingCollection[collections[_collectionId]], "KarmaSwap: Gifting collection not added");
        isWhIsBeGiftingCollection[collections[_collectionId]] = false;
        collections[_collectionId] = collections[collections.length - 1];
        collections.pop();
    }
    
    

    /**
     * @dev Sets the base URI for all token
     */

    /**
     * @dev Triggers smart contract to stopped state
     */
    function pause()
        public
        onlyOwner
    {
        _pause();
    }

    /**
     * @dev Returns smart contract to normal state
     */
    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }
    
    function claimToken(uint256 _collectionId, uint256 _tokenId) 
        public
        whenNotPaused
        nonReentrant
    {
        NiftyBuilderInstance collection = NiftyBuilderInstance(collections[_collectionId]);
        address userAddress = _msgSender();
        require(isWhIsBeGiftingCollection[address(collection)], "KarmaSwap: collection should be a gifting collection");
        require(collection.ownerOf(_tokenId) == userAddress, "KarmaSwap: caller is not the owner of tokenId");
        require(!tokenClaimed[_tokenId], "KarmaSwap: Karma token already claimed");
        tokenClaimed[_tokenId] = true;
        mintingContract.mint(userAddress);
    }

    function burnOLD(uint256 _collectionId, uint256 _tokenId)
        public
        whenNotPaused
        nonReentrant
    {   
        NiftyBuilderInstance collection = NiftyBuilderInstance(collections[_collectionId]);
        require(isWhIsBeBurningCollection[address(collection)], "KarmaSwap: collection should be a burning collection");
        address sender = _msgSender();
        collection.safeTransferFrom(sender, burnAddress, _tokenId);
        require(burnToKarma[address(collection)] > 0, "KarmaSwap: number of karma to be minted is zero");
        mintingContract.batchMint(sender, burnToKarma[address(collection)]);
    }

}