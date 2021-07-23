// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NFTStoreBox {

    using SafeMath for uint256;

    event CreateCollection(address _who, uint256 _collectionId, uint256 size,uint256 commissionRate);
    event PublishCollection(address _who, uint256 _collectionId,uint256 size, uint256 averagePrice, uint256 publishedAt,uint256 finishedAt);
    event UnpublishCollection(address _who, uint256 _collectionId);
    event NFTDeposit(address _who, address _tokenAddress, uint256 _tokenId);
    event NFTWithdraw(address _who, address _tokenAddress, uint256 _tokenId);
    event NFTClaim(address _who, address _tokenAddress, uint256 _tokenId);

    string public name;
    //IERC721 public itemToken;
    address private owner;

    // Platform fee.
    uint256 constant FEE_BASE = 100;
    uint256 public feeRate = 5;  // 5%

    address public feeTo;

    // Collection creating fee.
    uint256 public creatingFee = 0;  // By default, 0

    
    uint256 public nextNFTId;
    uint256 public nextCollectionId;
    constructor() {
       // currToken = IERC20(_currTokenAddress);
       // itemToken = IERC721(_itemTokenAddress);
        name = "NFTStoreBox";
	    owner = msg.sender;
    }
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
        address owner;
        uint256 price;
        uint256 paid;
        uint256 collectionId;
        uint256 indexInCollection;
        bool isSold;
    }

    // nftId => NFT
    mapping(uint256 => NFT) public allNFTs;

    // owner => nftId[]
    mapping(address => uint256[]) public nftsByOwner;

    // tokenAddress => tokenId => nftId
    mapping(address => mapping(uint256 => uint256)) public nftIdMap;

    struct Collection {
        address owner;
        string name;
        uint256 size;
        uint256 commissionRate;  // for curator (owner)

        // The following are runtime variables before publish
        uint256 totalPrice;
        uint256 averagePrice;
        uint256 commission;

        // The following are runtime variables after publish
        uint256 publishedAt;  // time that published.
        uint256 timesToCall;
        uint256 soldCount;
        uint256 finishedAt;  // time that finished.

    }
    
    
     struct Slot {
        address owner;
        uint256 size;
    }
    // collectionId => Slot[]
    mapping(uint256 => Slot[]) public slotMap;
     // collectionId => Collection
    mapping(uint256 => Collection) public allCollections;

    // owner => collectionId[]
    mapping(address => uint256[]) public collectionsByOwner;

    // collectionId => who => true/false
    mapping(uint256 => mapping(address => bool)) public isCollaborator;

    // collectionId => collaborators
    mapping(uint256 => address[]) public collaborators;

    // collectionId => nftId[]
    mapping(uint256 => uint256[]) public nftsByCollectionId;
    
    function setFeeTo(address feeTo_) external{
        require(msg.sender == owner,"Only the owner of this Contract could set feeTo Address!");
        feeTo = feeTo_;
    }

    function _generateNextNFTId() private returns(uint256) {
        return ++nextNFTId;
    }

    function _generateNextCollectionId() private returns(uint256) {
        return ++nextCollectionId;
    }
    
     uint256 public nftPriceFloor = 1e18;  // 1 USDC
     uint256 public nftPriceCeil = 1e24;  // 1M USDC
     uint256 public minimumCollectionSize = 3;  // 3 blind boxes
     uint256 public maximumDuration = 14 days;  // Refund if not sold out in 14 days.

     function _depositNFT(address tokenAddress_, uint256 tokenId_) private returns(uint256) {
        IERC721(tokenAddress_).safeTransferFrom(msg.sender,address(this), tokenId_);

        NFT memory nft;
        nft.tokenAddress = tokenAddress_;
        nft.tokenId = tokenId_;
        nft.owner = msg.sender;
        nft.collectionId = 0;
        nft.indexInCollection = 0;

        uint256 nftId;

        if (nftIdMap[tokenAddress_][tokenId_] > 0) {
            nftId = nftIdMap[tokenAddress_][tokenId_];
        } else {
            nftId = _generateNextNFTId();
            nftIdMap[tokenAddress_][tokenId_] = nftId;
        }

        allNFTs[nftId] = nft;
        nftsByOwner[msg.sender].push(nftId);

        emit NFTDeposit(msg.sender, tokenAddress_, tokenId_);
        return nftId;
    }

    function _withdrawNFT(address who_, uint256 nftId_, bool isClaim_) private {
        allNFTs[nftId_].owner = address(0);
        allNFTs[nftId_].collectionId = 0;

        address tokenAddress = allNFTs[nftId_].tokenAddress;
        uint256 tokenId = allNFTs[nftId_].tokenId;

        IERC721(tokenAddress).safeTransferFrom(address(this), who_, tokenId);

        if (isClaim_) {
            emit NFTClaim(who_, tokenAddress, tokenId);
        } else {
            emit NFTWithdraw(who_, tokenAddress, tokenId);
        }
    }
    
    function _randModulus(uint mod) internal view returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(
            block.timestamp, 
            block.difficulty, 
            msg.sender,
            mod)
        )) % mod;
        //nonce++;
        return rand;
    }
    function confirmNFT(uint256 collectionId_, Slot memory slot_) internal {
        Collection storage collection = allCollections[collectionId_];
        require(collection.soldCount < collection.size, "Sold out!");
        
        require(slot_.owner==msg.sender,"Only the buyer could open the box");
        

        for (uint256 i=0;i<slot_.size;i++){
            uint256 randomNum = _randModulus(collection.size.sub(collection.soldCount));
            
            uint256 nftId = nftsByCollectionId[collectionId_][randomNum];
    
            require(allNFTs[nftId].collectionId == collectionId_, "Already claimed");
    
            allNFTs[nftId].paid = allNFTs[nftId].price.mul(
            FEE_BASE.sub(feeRate).sub(collection.commissionRate)).div(FEE_BASE);
            //IERC20(currToken).safeTransfer(allNFTs[nftId].owner, allNFTs[nftId].paid);
            payable(allNFTs[nftId].owner).transfer(allNFTs[nftId].paid);
            uint256 fee =  allNFTs[nftId].price.mul(
            feeRate).div(FEE_BASE);
            payable(feeTo).transfer(fee);
            
            allNFTs[nftId].isSold = true;
            
    
            _withdrawNFT(msg.sender, nftId, true);
            collection.soldCount = collection.soldCount.add(1);
            
            // Removes from nftsByCollectionId
            uint256 index = allNFTs[nftId].indexInCollection;
            uint256 lastNFTId = nftsByCollectionId[collectionId_][nftsByCollectionId[collectionId_].length - 1];
    
            nftsByCollectionId[collectionId_][index] = lastNFTId;
            allNFTs[lastNFTId].indexInCollection = index;
            nftsByCollectionId[collectionId_].pop();
            
            allNFTs[nftId].collectionId = 0;
            
            }
            if(collection.soldCount==collection.size) {
                payable(collection.owner).transfer(collection.commission);
                collection.commission=0;
            }
    }



    
    function createCollection(
        string calldata name_,
        uint256 size_,
        uint256 commissionRate_,
        address[] calldata collaborators_
    ) external {
        require(size_ >= minimumCollectionSize, "Size too small");
        require(commissionRate_.add(feeRate) < FEE_BASE, "Too much commission");


        Collection memory collection;
        collection.owner = msg.sender;
        collection.name = name_;
        collection.size = size_;
        collection.commissionRate = commissionRate_;
        collection.totalPrice = 0;
        collection.averagePrice = 0;
        collection.publishedAt = 0;
        collection.finishedAt = 0;

        uint256 collectionId = _generateNextCollectionId();

        allCollections[collectionId] = collection;
        collectionsByOwner[msg.sender].push(collectionId);
        collaborators[collectionId] = collaborators_;

        for (uint256 i = 0; i < collaborators_.length; ++i) {
            isCollaborator[collectionId][collaborators_[i]] = true;
        }

        emit CreateCollection(msg.sender, collectionId,size_,commissionRate_);
    }

    function isPublished(uint256 collectionId_) public view returns(bool) {
        return allCollections[collectionId_].publishedAt > 0;
    }

    function _addNFTToCollection(uint256 nftId_, uint256 collectionId_, uint256 price_) private {
        Collection storage collection = allCollections[collectionId_];

        require(allNFTs[nftId_].owner == msg.sender, "Only NFT owner can add");
        require(collection.owner == msg.sender ||
                isCollaborator[collectionId_][msg.sender], "Needs collection owner or collaborator");

        require(price_ >= nftPriceFloor && price_ <= nftPriceCeil, "Price not in range");

        require(allNFTs[nftId_].collectionId == 0, "Already added");
        require(!isPublished(collectionId_), "Collection already published");
        require(nftsByCollectionId[collectionId_].length < collection.size,
                "collection full");

        allNFTs[nftId_].price = price_;
        allNFTs[nftId_].collectionId = collectionId_;
        allNFTs[nftId_].indexInCollection = nftsByCollectionId[collectionId_].length;
        allNFTs[nftId_].isSold = false;

        // Push to nftsByCollectionId.
        nftsByCollectionId[collectionId_].push(nftId_);

        collection.totalPrice = collection.totalPrice.add(price_);

        collection.commission = collection.commission.add(price_.mul(collection.commissionRate).div(FEE_BASE));
    }

    function addNFTToCollection(address tokenAddress_, uint256 tokenId_, uint256 collectionId_, uint256 price_) external {
        uint256 nftId = _depositNFT(tokenAddress_, tokenId_);
        _addNFTToCollection(nftId, collectionId_, price_);
    }

    function editNFTInCollection(uint256 nftId_, uint256 collectionId_, uint256 price_) external {
        Collection storage collection = allCollections[collectionId_];

        require(collection.owner == msg.sender ||
                allNFTs[nftId_].owner == msg.sender, "Needs collection owner or NFT owner");

        require(price_ >= nftPriceFloor && price_ <= nftPriceCeil, "Price not in range");

        require(allNFTs[nftId_].collectionId == collectionId_, "NFT not in collection");
        require(!isPublished(collectionId_), "Collection already published");

        collection.totalPrice = collection.totalPrice.add(price_).sub(allNFTs[nftId_].price);

        collection.commission = collection.commission.add(
            price_.mul(collection.commissionRate).div(FEE_BASE)).sub(
                allNFTs[nftId_].price.mul(collection.commissionRate).div(FEE_BASE));

        allNFTs[nftId_].price = price_;  // Change price.
    }

    function _removeNFTFromCollection(uint256 nftId_, uint256 collectionId_) private {
        Collection storage collection = allCollections[collectionId_];

        require(allNFTs[nftId_].owner == msg.sender ||
                collection.owner == msg.sender,
                "Only NFT owner or collection owner can remove");
        require(allNFTs[nftId_].collectionId == collectionId_, "NFT not in collection");
        require(!isPublished(collectionId_), "Collection already published");

        collection.totalPrice = collection.totalPrice.sub(allNFTs[nftId_].price);

        collection.commission = collection.commission.sub(
            allNFTs[nftId_].price.mul(collection.commissionRate).div(FEE_BASE));


        allNFTs[nftId_].collectionId = 0;

        // Removes from nftsByCollectionId
        uint256 index = allNFTs[nftId_].indexInCollection;
        uint256 lastNFTId = nftsByCollectionId[collectionId_][nftsByCollectionId[collectionId_].length - 1];

        nftsByCollectionId[collectionId_][index] = lastNFTId;
        allNFTs[lastNFTId].indexInCollection = index;
        nftsByCollectionId[collectionId_].pop();
    }

    function removeNFTFromCollection(uint256 nftId_, uint256 collectionId_) external {
        address nftOwner = allNFTs[nftId_].owner;
        _removeNFTFromCollection(nftId_, collectionId_);
        _withdrawNFT(nftOwner, nftId_, false);
    }
     function publishCollection(uint256 collectionId_, uint256 deadline_) external {
        Collection storage collection = allCollections[collectionId_];

        require(collection.owner == msg.sender, "Only owner can publish");

        uint256 actualSize = nftsByCollectionId[collectionId_].length;
        require(actualSize >= minimumCollectionSize, "Not enough boxes");

        collection.size = actualSize;  // Fit the size.

        // Math.ceil(totalPrice / actualSize);
        collection.averagePrice = collection.totalPrice.add(actualSize.sub(1)).div(actualSize);
        collection.publishedAt = block.timestamp;
        uint256 deadline  = deadline_>= maximumDuration?maximumDuration:deadline_;
        collection.finishedAt =deadline;
        
        emit PublishCollection(msg.sender, collectionId_, actualSize, collection.averagePrice, collection.publishedAt,collection.finishedAt);
    }

    function unpublishCollection(uint256 collectionId_) external payable {
        // Anyone can call.

        Collection storage collection = allCollections[collectionId_];

        // Only if the boxes not sold out in maximumDuration, can we unpublish.
        require(block.timestamp > collection.publishedAt + maximumDuration, "Not expired yet");
        require(collection.soldCount < collection.size, "Sold out");

        collection.publishedAt = 0;
        collection.soldCount = 0;

        // Now refund to the buyers.
        uint256 length = slotMap[collectionId_].length;
        for (uint256 i = 0; i < length; ++i) {
            Slot memory slot = slotMap[collectionId_][length.sub(i + 1)];
            slotMap[collectionId_].pop();

            //IERC20(baseToken).transfer(slot.owner, collection.averagePrice.mul(slot.size));
            payable(slot.owner).transfer(collection.averagePrice.mul(slot.size));
        }

        emit UnpublishCollection(msg.sender, collectionId_);
    }
    function drawBoxes(uint256 collectionId_, uint256 times_ ) external payable{
        Collection storage collection = allCollections[collectionId_];
        require(collection.soldCount.add(times_) <= collection.size, "Not enough left");
        
        require( block.timestamp >= collection.publishedAt && block.timestamp <= collection.finishedAt, "only can draw boxes between it's publish duration");
        require(msg.value == collection.averagePrice.mul(times_),"Please input the correct Price!");
        //  uint256 cost = collection.averagePrice.mul(times_);

        //IERC20(baseToken).safeTransferFrom(msg.sender, address(this), cost);

        Slot memory slot;
        slot.owner = msg.sender;
        slot.size = times_;
        slotMap[collectionId_].push(slot);

        //collection.soldCount = collection.soldCount.add(times_);
        confirmNFT(collectionId_,slot);
    }
    
    function destroy() virtual public {
	require(msg.sender == owner,"Only the owner of this Contract could destroy It!");
        if (msg.sender == owner) selfdestruct(payable(owner));
    }
    
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}