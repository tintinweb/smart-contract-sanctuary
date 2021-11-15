// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

interface ICrusaderNFT {
    /**
     *  @dev create an NFT that ties to a specific game object. Must be by an approved minter
     */
    function createNFT(uint gameId) external returns (uint tokenId);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import './Ownable.sol';
import './ICrusaderNFT.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _listingIds; //market item ids
  Counters.Counter private _itemsSold; //market items sold
  Counters.Counter private _storeListingIds; //store listing ids
  mapping(uint256 => string) _gameIdToURI; //store listing image uri
  uint _taxRate = 10; //10%


  struct MarketListing {
    uint listingId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
  }

  struct StoreListing {
    uint gameId;
    address nftContract;
    uint256 limit;
    uint256 sold;
    uint256 price;
    bool set;
  }

  mapping(uint256 => MarketListing) private _idToMarketListing;
  mapping(uint256 => StoreListing) private _gameIdToStoreListing;
  StoreListing[] private _storeListingArray;

  event MarketListingCreated (
    uint indexed listingId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price
  );

  event MarketListingSold (
    uint indexed listingId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address buyer,
    uint256 price
  );

  event MarketListingCancelled (
    uint indexed listingId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller
  );

  event StoreListingCreated (
    address indexed nftContract,
    uint256 indexed gameId,
    uint256 limit,
    uint256 price
  );

  event StoreListingPurchased (
    uint indexed gameId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address buyer,
    uint256 price
  );

  event Withdrawal (
    uint256 amount
  );

  constructor() {
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(amount <= address(this).balance, "Contract has insufficient bnb for withdrawal");
    payable(msg.sender).transfer(amount);
    emit Withdrawal(amount);
  }

  function addGameIdToListingURI(string memory uri, uint256 gameId) public onlyOwner {
        _gameIdToURI[gameId] = uri;
  }

  function getGameIdListingURI(uint256 gameId) public view returns (string memory) {
      return _gameIdToURI[gameId];
  }

  function getStoreListing(uint256 gameId) public view returns (StoreListing memory) {
    return _gameIdToStoreListing[gameId];
  }

  function createStoreListing(
    address nftContract,
    uint256 gameId,
    uint256 limit, //0 represents infinite
    uint256 price
  ) public nonReentrant onlyOwner {
    require(price > 0, "Price must be at least 1 wei");
    require(!_gameIdToStoreListing[gameId].set, "Listing must be unique for game id");

    _gameIdToStoreListing[gameId] =  StoreListing(
      gameId,
      nftContract,
      limit,
      0, //new listing, so none are sold yet
      price,
      true
    );

    _storeListingArray.push(_gameIdToStoreListing[gameId]);

    emit StoreListingCreated(
      nftContract,
      gameId,
      limit,
      price
    );
  }

  function removeStoreListing(
    uint256 gameId
  ) public nonReentrant onlyOwner {
    delete _gameIdToStoreListing[gameId];

    for (uint i = 0; i < _storeListingArray.length; i++) {
      if (_storeListingArray[i].gameId == gameId) {

        _storeListingArray[i] = _storeListingArray[_storeListingArray.length - 1];
        delete _storeListingArray[_storeListingArray.length - 1];

        break;
      }
    }

    delete _gameIdToStoreListing[gameId];
  }

  function purchaseStoreListing(
    uint256 gameId,
    address nftContract
    ) public payable nonReentrant {
    uint price = _gameIdToStoreListing[gameId].price;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");
    require(_gameIdToStoreListing[gameId].limit == 0 || _gameIdToStoreListing[gameId].sold < _gameIdToStoreListing[gameId].limit, "No more of this NFT in stock");

    uint256 tokenId = ICrusaderNFT(nftContract).createNFT(gameId);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

    _gameIdToStoreListing[gameId].sold++;

    emit StoreListingPurchased(
        gameId,
        _gameIdToStoreListing[gameId].nftContract,
        tokenId,
        msg.sender,
        _gameIdToStoreListing[gameId].price
    );
  }

  function fetchStoreListings(uint page, uint limit) public view returns (StoreListing[] memory) {

    require(page * limit <= _storeListingArray.length, "page must exist in listings");

    uint pageLimit = page * limit;
    uint actualLimit = _storeListingArray.length < pageLimit + limit ? (pageLimit + limit) - _storeListingArray.length : limit;

    if (actualLimit > _storeListingArray.length) {
      actualLimit = _storeListingArray.length;
    }

    StoreListing[] memory listings = new StoreListing[](actualLimit);
    uint index = 0;
    for (uint i = pageLimit; i < pageLimit + actualLimit && i < _storeListingArray.length; i++) {
      if (!_storeListingArray[i].set) {
        continue;
      }
      
      listings[index] = _storeListingArray[i];
      listings[index].sold = _gameIdToStoreListing[listings[index].gameId].sold; //we manually update the sold value, as this is not saved during purchase in the array to save gas
      index++;
    }
   
    return listings;
  }

  function getMarketListing(uint256 marketlistingId) public view returns (MarketListing memory) {
    return _idToMarketListing[marketlistingId];
  }

  function createMarketListing(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant returns (uint256) {
    require(price > 0, "Price must be at least 1 wei");

    _listingIds.increment();
    uint256 listingId = _listingIds.current();
  
    _idToMarketListing[listingId] =  MarketListing(
      listingId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketListingCreated(
      listingId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price
    );

    return listingId;
  }

  function purchaseMarketListing(
    uint256 listingId
    ) public payable nonReentrant {
    uint price = _idToMarketListing[listingId].price;
    uint tokenId = _idToMarketListing[listingId].tokenId;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");

    uint fee = msg.value / _taxRate;

    _idToMarketListing[listingId].seller.transfer(msg.value - fee); //seller gets amount sans fee, the rest automatically go to contract
    IERC721(_idToMarketListing[listingId].nftContract).transferFrom(address(this), msg.sender, tokenId);

    _itemsSold.increment();

    emit MarketListingSold(
        listingId,
        _idToMarketListing[listingId].nftContract,
        _idToMarketListing[listingId].tokenId,
        _idToMarketListing[listingId].seller,
        msg.sender,
        _idToMarketListing[listingId].price
    );

    delete _idToMarketListing[listingId];
  }

  function cancelMarketListing(
    uint256 listingId
    ) public payable nonReentrant {

    MarketListing memory item = _idToMarketListing[listingId];

    require(item.seller == msg.sender || msg.sender == owner(), "Must be seller to cancel market listing");

    IERC721(item.nftContract).transferFrom(address(this), item.seller, item.tokenId);

    _itemsSold.increment(); //this is because the items still exist within the area internally, so we count it as "Sold"

    emit MarketListingCancelled(listingId, item.nftContract, item.tokenId, item.seller);

    delete _idToMarketListing[listingId];
  }

  function fetchMarketListing(uint listingId) public view returns (MarketListing memory) {
    MarketListing memory item = _idToMarketListing[listingId];
    return item;
  }

  function fetchMarketListings(uint page, uint limit) public view returns (MarketListing[] memory) {
    uint itemCount = _listingIds.current();
    uint unsoldItemCount = _listingIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    uint actualLimit = limit < unsoldItemCount ? limit : unsoldItemCount;
    uint availableListingCounter = 0;
    MarketListing[] memory items = new MarketListing[](actualLimit);
    for (uint i = 0; i < itemCount && currentIndex < actualLimit; i++) {
      if (_idToMarketListing[i + 1].seller != address(0) && _idToMarketListing[i + 1].owner == address(0)) {
        availableListingCounter += 1;
        if (page == 0 || availableListingCounter >= page * limit) {
          MarketListing storage currentItem = _idToMarketListing[i + 1];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
       }
    }
   
    return items;
  }

  function fetchMyMarketListings() public view returns (MarketListing[] memory) {
    uint totalItemCount = _listingIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (_idToMarketListing[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketListing[] memory items = new MarketListing[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (_idToMarketListing[i + 1].seller == msg.sender) {
        items[currentIndex] = _idToMarketListing[i + 1];
        currentIndex += 1;
      }
    }
   
    return items;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";

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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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

