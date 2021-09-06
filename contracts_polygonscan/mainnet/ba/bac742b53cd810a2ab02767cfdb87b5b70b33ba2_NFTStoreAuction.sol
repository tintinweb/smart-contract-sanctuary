/**
 *Submitted for verification at polygonscan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// File: contracts/NFTStoreAuction.sol

contract NFTStoreAuction {
    string public name;
    IERC20 public currToken;
    IERC721 public itemToken;
    address private owner;
    struct Auction {
        address seller;
        uint128 price;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool finished;
        bool active;
    }
    
     struct Bidder {
        address addr;
        uint256 amount;
        uint256 bidAt;
    }

    uint256 public totalHoldings = 0;
     
    uint256 public platformFee = 5;
    uint256 constant feeBase = 100;
    Auction[] public auctions;
    Bidder[] public bidders;
    
    mapping(uint256 => Auction) public tokenIdToAuction;
    mapping(uint256 => uint256) public tokenIdToIndex;
    mapping(address => Auction[]) public auctionOwner;
    mapping(uint256 => Bidder[]) public tokenIdToBidder;
    
    constructor() {
       // currToken = IERC20(_currTokenAddress);
        //itemToken = IERC721(_itemTokenAddress);
	name = "NFTStoreAuction";
	owner = msg.sender;
    }
    function setItemToken(address itemTokenAddress_) external {
        require(msg.sender==owner,"Only Owner Function!");
        itemToken = IERC721(itemTokenAddress_);
    }
    function setCurrToken(address currTokenAddress_) external {
        require(msg.sender==owner,"Only Owner Function!");
        currToken = IERC20(currTokenAddress_);
    }
    function setWithDraw (address withDrawTo_) external{
        require(msg.sender==owner,"Only Owner Function!");
        withdrawAddress = withDrawTo_;
    }
    function setRecipAddr (address recipAddr_) external{
        require(msg.sender==owner,"Only Owner Function!");
        recipientAddr = recipAddr_;
    }

    function setPlatformFee (uint256 platformFee_) external{
        require(msg.sender==owner,"Only Owner Function!");
        platformFee = platformFee_;
    }
     event AuctionStatusChange(
	   uint256 tokenID, 
	   bytes32 status,
	   address indexed poster,
	   uint256 price,
	   address indexed buyer,
	   uint256 startTime,
	   uint256 endTime
	   
    );
     event AuctionCreated(
        uint256 _tokenId,
        address indexed _seller,
        uint256 _value
    );
    event AuctionCanceled(uint256 _tokenId);
    
    event AuctionBidden(
        uint256 _tokenId,
        address indexed _bidder,
        uint256 _amount
    );
    event AuctionFinished(
        uint256 _tokenId, 
        address indexed _awarder, 
        uint256 price
        );
    
    address public withdrawAddress;
    address public recipientAddr;
    
     
    function createAuction(
        uint256 _tokenId,
        uint128 _price,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        require(
            msg.sender == itemToken.ownerOf(_tokenId),
            "Should be the owner of token"
        );
        require(_startTime >= block.timestamp);
        require(_endTime >= block.timestamp);
        require(_endTime > _startTime);

        itemToken.transferFrom(msg.sender, address(this), _tokenId);
        
        Auction memory auction =
            Auction({
                seller: msg.sender,
                price: _price,
                tokenId: _tokenId,
                startTime: _startTime,
                endTime: _endTime,
                highestBid: 0,
                highestBidder: address(0x0),
                finished:false,
                active:true
        });
        tokenIdToAuction[_tokenId] = auction;
        auctions.push(auction);
        
        auctionOwner[msg.sender].push(auction);
       //emit AuctionCreated(_tokenId,msg.sender,_price);
	emit AuctionStatusChange(_tokenId,"Create",msg.sender,_price,address(this),_startTime,_endTime);
    }
    
    function bidAuction(uint256 _tokenId) public payable {
        require(isBidValid(_tokenId, msg.value));
        Auction memory auction = tokenIdToAuction[_tokenId];
        if(block.timestamp> auction.endTime) revert();

	require(msg.sender != auction.seller, "Owner can't bid");
        
        uint256 highestBid = auction.highestBid;
	address highestBidder = auction.highestBidder;
        require(msg.value > auction.highestBid);
        //require(balanceOf(msg.sender) >=msg.value, "insufficient balance");
	require(payable(msg.sender).balance >=msg.value, "insufficient balance");
        if (msg.value > highestBid) {
            tokenIdToAuction[_tokenId].highestBid = msg.value;
            tokenIdToAuction[_tokenId].highestBidder = msg.sender;
	    //require(currToken.approve(address(this), price), "Approve has failed");
            //currToken.transferFrom(msg.sender,address(this),price);
             // refund the last bidder
            if( highestBid > 0 ) {
		//require(currToken.approve(address(this), highestBid), "Approve has failed");
		//currToken.transferFrom(address(this),highestBidder, highestBid);
		payable(highestBidder).transfer(highestBid);
            }

	    Bidder memory bidder =  
            Bidder({
                addr:msg.sender, 
                amount:msg.value, 
                bidAt:block.timestamp
            });
            
            tokenIdToBidder[_tokenId].push(bidder);
            //emit AuctionBidden(_tokenId, msg.sender, msg.value);
	    emit AuctionStatusChange(_tokenId,"Bid",address(this),msg.value,msg.sender,block.timestamp,block.timestamp);
        }
    }

    function finishAuction(uint256 _tokenId) public payable {
        Auction memory auction = tokenIdToAuction[_tokenId];
        require(
           msg.sender == auction.seller,
           "Should only be called by the seller"
        );
        require(block.timestamp >= auction.endTime);
        uint256 _bidAmount = auction.highestBid;
        address _bider = auction.highestBidder;
        
        if(_bidAmount == 0) {
            cancelAuction(_tokenId);
        } else {
	
            //require(currToken.approve(address(this), _bidAmount), "Approve has failed"); 
            uint256 receipientAmount =
                (_bidAmount * platformFee) / feeBase;
            uint256 sellerAmount = _bidAmount - receipientAmount;
	    //currToken.transferFrom(address(this),recipientAddr, receipientAmount);
	    //currToken.transferFrom(address(this),auction.seller,sellerAmount);
	     payable(recipientAddr).transfer(receipientAmount);
         payable(auction.seller).transfer(sellerAmount);

            itemToken.transferFrom(address(this), _bider, _tokenId);
    	    tokenIdToAuction[_tokenId].finished = true;
    	    tokenIdToAuction[_tokenId].active = false;
	    delete tokenIdToBidder[_tokenId];
	    //emit AuctionFinished(_tokenId, _bider,_bidAmount);
	    emit AuctionStatusChange(_tokenId,"Finish",address(this),_bidAmount,_bider,block.timestamp,block.timestamp);
        }
    }
    
    
   

    function isBidValid(uint256 _tokenId, uint256 _bidAmount)
        internal
        view
        returns (bool)
    {
        Auction memory auction = tokenIdToAuction[_tokenId];
        uint256 startTime = auction.startTime;
        uint256 endTime = auction.endTime;
        address seller = auction.seller;
        uint128 price = auction.price;	
        
        bool withinTime =
            block.timestamp >= startTime && block.timestamp <= endTime;
        bool bidAmountValid = _bidAmount >= price;
        bool sellerValid = seller != address(0);
        return withinTime && bidAmountValid && sellerValid;
    }

    function getAuction(uint256 _tokenId)
    public
    view
    returns (address, 
        uint128,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
	bool,
	bool)
	  {
	     Auction memory auction = tokenIdToAuction[_tokenId];
	     return (auction.seller,
	     auction.price,
	     auction.tokenId,
	     auction.startTime,
	     auction.endTime,
	     auction.highestBid,
	     auction.highestBidder,
	     auction.finished,
	     auction.active);
	  }
	  
    function getBidders(uint256 _tokenId)
    public
    view
    returns (
        Bidder[] memory 
       )
	  {
	     Bidder[] memory biddersOfToken = tokenIdToBidder[_tokenId];
	     return (biddersOfToken);
	  }
    
   
   function cancelAuction(uint256 _tokenId)
    public
    {
	Auction memory auction = tokenIdToAuction[_tokenId];
	require(
            msg.sender == auction.seller,
            "Auction can be cancelled only by seller."
        );
	uint256 amount = auction.highestBid;
	address bidder = auction.highestBidder;
       // require(block.timestamp <= auction.endTime, "Only be canceled before end");
       
        itemToken.transferFrom(address(this), msg.sender, _tokenId);
        
        //refund losers funds
        
        // if there are bids refund the last bid
        if( amount > 0 ) {
	    //require(currToken.approve(address(this), amount), "Approve has failed"); 
            //currToken.transferFrom(address(this),bidder,amount);
	     payable(bidder).transfer(amount);
  
        }
        
        tokenIdToAuction[_tokenId].active=false;
	delete tokenIdToBidder[_tokenId];
        //emit AuctionCanceled(_tokenId);
	emit AuctionStatusChange(_tokenId,"Cancel",address(this),0, auction.seller,block.timestamp,block.timestamp);
    }
    
    
     /**
    * @dev Gets an array of owned auctions
    * @param _tokenId uint of the Token
    * @return amount uint256, address of last bidder
    */
    function getCurrentBid(uint256 _tokenId) public view returns(address,uint256,uint256) {
        uint bidsLength = tokenIdToBidder[_tokenId].length;
        // if there are bids refund the last bid
        if( bidsLength > 0 ) {
            Bidder memory lastBid = tokenIdToBidder[_tokenId][bidsLength - 1];
            return (lastBid.addr,lastBid.amount,lastBid.bidAt);
        }
        return ( address(0),uint256(0),uint256(0));
    }
    
     /**
    * @dev Gets an array of owned auctions
    * @param _owner address of the auction owner
    */
    function getAuctionsOf(address _owner) public view returns(Auction[] memory) {
        Auction[] memory ownedAuctions = auctionOwner[_owner];
        return ownedAuctions;
    }
    
    
    /**
    * @dev Gets the total number of auctions owned by an address
    * @param _owner address of the owner
    * @return uint total number of auctions
    */
    function getAuctionsCountOfOwner(address _owner) public view returns(uint) {
        return auctionOwner[_owner].length;
    }
    
     /**
    * @dev Gets the length of auctions
    * @return uint representing the auction count
    */
    function getCount() public view returns(uint) {
        return auctions.length;
    }

    /**
    * @dev Gets the bid counts of a given auction
    * @param _tokenId uint ID of the auction
    */
    function getBidsCount(uint256 _tokenId) public view returns(uint) {
        return tokenIdToBidder[_tokenId].length;
    }

     /**
    **withdraw
    **
    **
    **/
    function totalBalance() external view returns(uint) {
     //return currToken.balanceOf(address(this));
     return payable(address(this)).balance;
     }

   function withdrawFunds() external withdrawAddressOnly() {
     //require(currToken.approve(address(this), this.totalBalance()), "Approve has failed"); 
     //currToken.transferFrom(address(this),msg.sender, this.totalBalance());
       payable(msg.sender).transfer(this.totalBalance());
   }

   modifier withdrawAddressOnly() {
     require(msg.sender == withdrawAddress, 'only withdrawer can call this');
   _;
   }

   function destroy() virtual public {
	require(msg.sender == owner,"Only the owner of this Contract could destroy It!");

        if (msg.sender == owner) selfdestruct(payable(owner));
    }
}