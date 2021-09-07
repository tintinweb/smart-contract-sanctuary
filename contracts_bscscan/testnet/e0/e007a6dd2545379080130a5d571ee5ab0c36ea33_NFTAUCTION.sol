/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-03
*/

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint tokenId) external view returns (address owner);

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
    function safeTransferFrom(address from, address to, uint tokenId) external;

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
    function transferFrom(address from, address to, uint tokenId) external;

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
    function approve(address to, uint tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint tokenId) external view returns (address operator);

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
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}


// library Counters {
//     struct Counter {
//         // This variable should never be directly accessed by users of the library: interactions must be restricted to
//         // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
//         // this feature: see https://github.com/ethereum/solidity/issues/4637
//         uint _value; // default: 0
//     }

//     function current(Counter storage counter) internal view returns (uint) {
//         return counter._value;
//     }

//     function increment(Counter storage counter) internal {
//         unchecked {
//             counter._value += 1;
//         }
//     }

//     function decrement(Counter storage counter) internal {
//         uint value = counter._value;
//         require(value > 0, "Counter: decrement overflow");
//         unchecked {
//             counter._value = value - 1;
//         }
//     }
// }

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
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
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
// SPDX-License-Identifier: Unlicensed
contract NFTAUCTION is IERC721Receiver, Ownable {
    // using Counters for Counters.Counter;
    // Counters.Counter private _tradeCounter;
    
    uint public _tradeCounter = 0;
    
    enum TradeStatus {
        inactive , Open , Stopped , Closed
    }
    
    TradeStatus  auctionstatus;
    
    mapping (uint => TradeStatus) tradeStatus;
    
    struct Trade {
        uint id;
        address admin;
        address nftAdr;
        uint nftTokenId;
        uint nftTokenPrice;    
        
        //auction variables       
        address buyer; 
        uint highestBid; // saves gas over querying the map every time  -
        address highestBidder;       
        uint openTimestamp;         
        uint endTimestamp;       
    }

    Trade[] trades;
    mapping(uint => mapping(address => uint)) public bidsByTrade; // necessary to determine who is allowed to withdraw their bidsByTrade
    mapping(uint => mapping(address => bool)) public claim; 
    
    mapping(address => uint[]) auctionsOfUser; // for convenient querying of what auctions a particular user has bid in

    address public tokenAddress = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;
    address public nftAddress = 0x92b5DaaBe735BD6BB6505b20a8Db8f5Ee38Bceb4;


    IERC20 token;
    bool _tokenInitialized;
    IERC721 nftContract;
    bool _nftInitialized;
    
    event TradeStatusChanged(uint tradeId, TradeStatus status);
    event AuctionOpened(uint tradeId, address admin);
    event AuctionEnded(uint tradeId, address winner);
    event AuctionCancelled(uint tradeId, address admin);
    event BidPlaced(uint tradeId, address bidder, uint amount);
    event BidWithdrawn(uint tradeId, address bidder);
    event ClaimNft(uint tradeId, address bidder,uint id);

    constructor() public {
        token = IERC20(tokenAddress);
        _tokenInitialized = true;
        nftContract = IERC721(nftAddress);
        _nftInitialized = true;
    }
    
    function getBid(uint tradeId, address bidder) external view returns (uint) {
        return bidsByTrade[tradeId][bidder];
    }

    function getAuctionsOfUser(address user) public view returns (uint[] memory) {
        return auctionsOfUser[user];
    }

    function getTrade(uint tradeId) public view returns (uint nftid, address nftadd, uint startingPrice, uint maxbid, address highestBidder, address buyer) {
        return   ( trades[tradeId].nftTokenId, trades[tradeId].nftAdr, trades[tradeId].nftTokenPrice, trades[tradeId].highestBid, trades[tradeId].highestBidder, trades[tradeId].buyer);
    }
    
    function getTradetimestatus(uint tradeId) public view returns (uint _starttime, uint _endtime) {
        return (trades[tradeId].openTimestamp, trades[tradeId].endTimestamp);
    }

    // function getAllTrades() external view returns (Trade[] memory) {
    //     return trades;
    // }

    function getTradeCount() public view returns (uint) {
        return _tradeCounter;
    }


    function getTradeStatus(uint tradeId) public view returns(TradeStatus)  {
        
        
         if (tradeStatus[tradeId] == TradeStatus.Stopped)
         {
               return TradeStatus.Stopped;
         }
       
         else if (block.timestamp >=trades[tradeId].openTimestamp && block.timestamp <=trades[tradeId].endTimestamp)
         {
              return TradeStatus.Open;
         }
         
         else if (block.timestamp <= trades[tradeId].openTimestamp)
         {
              return TradeStatus.inactive;
         }
         
         else
         {
             return TradeStatus.Closed;
         }
         
       }




    function openAuction(uint nftTokenId, uint startingPrice, uint startTime, uint stopTime) external onlyNonContract onlyOwner {
        require(nftContract.ownerOf(nftTokenId) == msg.sender, "Sender has to be owner of the token.");
        require(startTime < stopTime, "Duration has to be above 0.");
      
        
        uint id = _tradeCounter;
        _tradeCounter += 1;

        trades.push(Trade({
            id: id,
            admin: msg.sender,
            nftAdr: address(nftContract),
            nftTokenId: nftTokenId,
            nftTokenPrice: startingPrice,
            
            buyer: address(0),
            highestBid: startingPrice,
            highestBidder: msg.sender,
            openTimestamp:startTime,
            endTimestamp: stopTime
        }));

        assert(trades.length == _tradeCounter);
        
        // nftContract.safeTransferFrom(msg.sender, address(this), nftTokenId);

        // emit TradeStatusChanged(id, TradeStatus.Open);
        emit AuctionOpened(id, msg.sender);
    }
    
    
    
     function openOtherAuction(uint nftTokenId, address _newnftaddress,uint startingPrice, uint startTime, uint stopTime) external onlyNonContract onlyOwner {
      
        IERC721 nft;
        nft = IERC721(_newnftaddress);
        
        require(nft.ownerOf(nftTokenId) == msg.sender, "Sender has to be owner of the token.");
        require(startTime < stopTime, "Duration has to be above 0.");
      
        
        uint id = _tradeCounter;
        _tradeCounter += 1;

        trades.push(Trade({
            id: id,
            admin: msg.sender,
            nftAdr: address(nft),
            nftTokenId: nftTokenId,
            nftTokenPrice: startingPrice,
            
            buyer: address(0),
            highestBid: startingPrice,
            highestBidder: msg.sender,
            openTimestamp:startTime,
            endTimestamp: stopTime
        }));

        assert(trades.length == _tradeCounter);
        
        emit AuctionOpened(id, msg.sender);
    }
    
    
    
     function renewAuction(uint tradeId, uint startingPrice, uint startTime, uint stopTime) external onlyNonContract onlyOwner { 
     
        Trade memory trade = trades[tradeId];
       
        auctionstatus = getTradeStatus(tradeId);
        require(auctionstatus == TradeStatus.Closed, "Trade status must be closed.");
        
        require (trade.highestBidder == trade.admin, "Already sold");
        
        trades[tradeId].nftTokenPrice = startingPrice;
        trades[tradeId].openTimestamp = startTime;
        trades[tradeId].endTimestamp = stopTime;
        trades[tradeId].highestBid = startingPrice;
    }    
    
    
    function StopAuction(uint tradeId) external onlyNonContract onlyOwner { 
     
         auctionstatus = getTradeStatus(tradeId);
    
         require(auctionstatus == TradeStatus.Open, "Cannot Stop inactive or completed Auction ");   
         
         tradeStatus[tradeId] = TradeStatus.Stopped;
     }
    
    
    function resumeAuction(uint tradeId) external onlyNonContract onlyOwner {
        
         auctionstatus = getTradeStatus(tradeId);
    
         require(auctionstatus == TradeStatus.Stopped, "Auction not stopped");   
         
         tradeStatus[tradeId] = TradeStatus.Open;
     }
    
    
    
    function placeBid(uint tradeId, uint bid) external onlyNonContract {
        Trade memory trade = trades[tradeId];
        
        auctionstatus = getTradeStatus(tradeId);
    
        require(auctionstatus == TradeStatus.Open, "Trade status must be open.");
        
        // require(trade.endTimestamp > block.timestamp, "Auction is already over its duration.");
        require(msg.sender != trade.admin, "admin can't bid on their own NFT.");
        
        
        if ( bidsByTrade[tradeId][msg.sender] == 0 ) {
         require(trade.highestBid < bid, "Bid must be higher than previous highest bid.");
         auctionsOfUser[msg.sender].push(tradeId);
         trades[tradeId].highestBid = bid;
        }
        
        else{
         uint previousbid = bidsByTrade[tradeId][msg.sender];    
         require(trade.highestBid < bid + previousbid, "Bid must be higher than previous highest bid.");
         trades[tradeId].highestBid = bid+previousbid;
        }
        
        bidsByTrade[tradeId][msg.sender] += bid;
        
        trades[tradeId].highestBidder = msg.sender;

        require(token.transferFrom(msg.sender, address(this), bid), "Tokens couldn't be transferred. Check your allowance.");
        
        emit BidPlaced(tradeId, msg.sender, bid);
    }
    

    
    function withdraw(uint tradeId) external onlyNonContract {
        
        Trade memory trade = trades[tradeId];
        uint bid = bidsByTrade[tradeId][msg.sender];
        
        require(claim[tradeId][msg.sender] == false, "Already Claimed");
        
        require (bid > 0, "There is no bid to withdraw.");

        auctionstatus = getTradeStatus(tradeId);
        require(auctionstatus == TradeStatus.Closed, "Trade status must be closed.");
      
        if (msg.sender != trade.highestBidder) 
        {
        require(token.transfer(msg.sender, bid), "Token transfer to sender failed.");
        claim[tradeId][msg.sender] = true;
        emit BidWithdrawn(tradeId, msg.sender);
        }
        
        else if (msg.sender == trade.highestBidder)
        {
            
        if (nftAddress == trade.nftAdr)    
            
        {    
            
         nftContract.safeTransferFrom(trade.admin,msg.sender,trade.nftTokenId);
         claim[tradeId][msg.sender] = true;
         trades[tradeId].buyer = msg.sender;
         emit ClaimNft(tradeId, msg.sender,trade.nftTokenId);
        
        }
        
        else {
            
         IERC721 nftc;
         nftc = IERC721(trade.nftAdr);
         nftc.safeTransferFrom(trade.admin,msg.sender,trade.nftTokenId);
         claim[tradeId][msg.sender] = true;
         trades[tradeId].buyer = msg.sender;
         emit ClaimNft(tradeId, msg.sender,trade.nftTokenId);
        }
            
        }
    }
    

    
     


    /**
     * Require token contract to be set
     */
    modifier tokenInitialized() { require(_tokenInitialized, "Token contract isn't initialized."); _; }

    /**
     * Require nft contract to be set
     */
    modifier nftInitialized() { require(_nftInitialized, "NFT contract isn't initialized."); _; }

    /**
     * Block contracts from calling a function, only allow user wallets
     */
    modifier onlyNonContract() {
        require(tx.origin == msg.sender, "Sender has to be a regular wallet, not a contract.");
        address a = msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(a)
        }
        require(size == 0);
        _;
    }
    
    /**
     * Set the token contract
     */
    // function setTokenAddress(address tokenAdr) private onlyOwner {
    //     tokenAddress = tokenAdr;
    //     token = IERC20(tokenAdr);
    //     _tokenInitialized = true;
    // }

    // /**
    //  * Set the NFT contract
    //  */
    // function setNftAddress(address nftAdr) private onlyOwner {
    //     nftAddress = nftAdr;
    //     nftContract = IERC721(nftAdr);
    //     _nftInitialized = true;
    // }
    

    
    function onERC721Received(address, address, uint, bytes calldata) public override returns (bytes4) {
        return 0x150b7a02;
    }
}