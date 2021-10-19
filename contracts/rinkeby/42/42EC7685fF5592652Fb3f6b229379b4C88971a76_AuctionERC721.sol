pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ArtabiaERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Auction Repository
 * This contracts allows auctions to be created for non-fungible tokens
 * Moreover, it includes the basic functionalities of an auction house
 */

contract AuctionERC721 {
    using SafeMath for uint256;

		//Commission of the platform for listing
		uint256 public commission;

		//Service fees for using the platform
		uint256 public serviceFee;

		//Length of non zero elements in auctions mapping
		uint256 public auctionsLength;
    //Auction[] public auctions;

		// Array with all auctions
		mapping(uint256=>Auction) public auctions;

    // Mapping from auction index to user bids
    mapping(uint256 => Bid[]) public auctionBids;

    ArtabiaERC721 public NFTContract;
    mapping(uint256 => History[]) public auctionHistory;

    // Mapping from owner to a list of created auctions
    mapping(address => uint256[]) public auctionOwner;

    // Bid struct to hold bidder and amount
    struct Bid {
        address payable from;
        uint256 quantity;
        uint256 amount;
        uint256 totalAmount;
    }

     struct History {
        address from;
        uint256 duration;
        uint256 amount;
        uint256 quantity;
        uint256 history_type;
    }

    address payable _webOwner = 0x673227E9bbA59C6F4577977827987684cA5FD316;

    event AddedValuesByCall(address a, address b, uint256 productId, address c);

    event BidSuccess(address _from, uint256 _auctionId);

    event BidCheck(address _from, uint256 _singlePrice, uint256 _lastPrice);

    // AuctionCreated is fired when an auction is created
    event AuctionCreated(address _owner, uint256 _auctionId);

    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(
        address _owner,
        uint256 _auctionId,
        address from,
        uint256 productId
    );

    // AuctionCancelled is fired when an auction is cancelled
    event AuctionCancelled(
        address _owner,
        uint256 _auctionId,
        address from,
        uint256 productId
    );

    event Contract(
        uint256 id,
        string name,
        address owner,
        uint256 price,
        uint256 royaltyFee
    );

    // Auction struct which holds all the required info
    struct Auction {
        uint256 id;
        string name;
        uint256 startPrice;
        uint256 endPrice;
        string metadata;
        uint256 productId;
        address deedRepositoryAddress;
        address payable owner;
        bool active;
        uint256 startDate;
        uint256 endDate;
    }

    constructor(address _NFTAddress) public {
				commission=2000;
				serviceFee=250;
        NFTContract = ArtabiaERC721(_NFTAddress);
    }

    /**
     * @dev Guarantees msg.sender is owner of the given auction
     * @param _auctionId uint ID of the auction to validate its ownership belongs to msg.sender
     */
    modifier isOwner(uint256 _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

		/**
     * @dev Checks if the sender is admin of the contract
     */
		modifier isWebOwner{
			require(msg.sender == _webOwner);
			_;
		}

    /**
     * @dev Gets the length of auctions
     * @return uint representing the auction count
     */
    function getCount() public view returns (uint256) {
        return auctionsLength;
    }

    /**
     * @dev Gets the bid counts of a given auction
     * @param _auctionId uint ID of the auction
     */
    function getBidsCount(uint256 _auctionId) public view returns (uint256) {
        return auctionBids[_auctionId].length;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getAuctionsOf(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ownedAuctions = auctionOwner[_owner];
        return ownedAuctions;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId address of the auction owner
     */
    function getBidOfAuctions(uint256 _auctionId)
        public
        view
        returns (Bid[] memory)
    {
        Bid[] memory ownedBids = auctionBids[_auctionId];
        return ownedBids;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId address of the auction owner
     */
    function getHistoryOfAuctions(uint256 _auctionId)
        public
        view
        returns (History[] memory)
    {
        History[] memory aucHistory = auctionHistory[_auctionId];
        return aucHistory;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId uint of the auction owner
     * @return amount uint256, address of last bidder
     */
    function getCurrentBid(uint256 _auctionId)
        public
        view
        returns (uint256, address)
    {
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength > 0) {
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount, lastBid.from);
        }
        return (0, address(0));
    }

    /**
     * @dev Gets the total number of auctions owned by an address
     * @param _owner address of the owner
     * @return uint total number of auctions
     */
    function getAuctionsCountOfOwner(address _owner)
        public
        view
        returns (uint256)
    {
        return auctionOwner[_owner].length;
    }

    /**
     * @dev Gets the info of a given auction which are stored within a struct
     * @param _auctionId uint ID of the auction
     * @return string name of the auction
     * @return uint256 starting price of the auction
     * @return string representing the metadata of the auction
     * @return uint256 ID of the deed registered in DeedRepository
     * @return address Address of the DeedRepository
     * @return address owner of the auction
     * @return bool whether the auction is active
     * @return bool whether the auction is finalized
     * @return uint256 starting price of the auction
     * @return uint256 starting price of the auction
     */
    function getAuctionById(uint256 _auctionId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            uint256 startPrice,
            uint256 endPrice,
            string memory metadata,
            uint256 productId,
            address deedRepositoryAddress,
            address owner,
            bool active,
            uint256 startDate,
            uint256 endDate
        )
    {
        Auction memory auc = auctions[_auctionId];
        return (
            auc.id,
            auc.name,
            auc.startPrice,
            auc.endPrice,
            auc.metadata,
            auc.productId,
            auc.deedRepositoryAddress,
            auc.owner,
            auc.active,
            auc.startDate,
            auc.endDate
        );
    }

    // /**
    //  * @dev Gets the info of a given auction which are stored within a struct
    //  * @param _auctionId uint ID of the auction
    //  * @return uint256 bidding amount of the auction
    //  * @return address owner of the bidder
    //  */
    // function getAuctionBids(uint256 _auctionId)
    //     public
    //     view
    //      returns (Bid[] memory)
    // {
    //     Bid[] memory ownedAuctionBids = auctionBids[_auctionId];
    //     return ownedAuctionBids;
    // }

    /**
     * @dev Creates an auction with the given informatin
     * @param _deedRepositoryAddress address of the DeedRepository contract
     * @param _productId uint256 of the deed registered in DeedRepository
     * @param _auctionTitle string containing auction title
     * @param _metadata string containing auction metadata
     * @param _startPrice uint256 starting price of the auction
     * @param _endPrice uint256 starting price of the auction
     * @param _startDate uint256 starting price of the auction
     * @param _endDate uint256 starting price of the auction
     * @return bool whether the auction is created
     */
    function createAuction(
        address _deedRepositoryAddress,
        uint256 _productId,
        string memory _auctionTitle,
        string memory _metadata,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _startDate,
        uint256 _endDate
    )
        public
        returns (
            // ) public  contractIsProductOwner(_deedRepositoryAddress, _productId) returns (bool) {
            bool
        )
    {
        // require(contractIsProductOwner(_deedRepositoryAddress, _productId, _token) == true);
        uint256 auctionId = auctionsLength;
        Auction memory newAuction;
        newAuction.id = auctionId;
        newAuction.name = _auctionTitle;
        newAuction.startPrice = _startPrice;
        newAuction.endPrice = _endPrice;
        newAuction.metadata = _metadata;
        newAuction.productId = _productId;
        newAuction.deedRepositoryAddress = _deedRepositoryAddress;
        newAuction.owner = msg.sender;
        newAuction.active = true;
        newAuction.startDate = _startDate;
        newAuction.endDate = _endDate;

        auctions[auctionsLength]=newAuction;
				auctionsLength++;
        auctionOwner[msg.sender].push(auctionId);
        NFTContract.updateToken(_productId);

        History memory newHistory;
        newHistory.from = msg.sender;
        newHistory.quantity = 1;
        newHistory.amount = _startPrice;
        newHistory.history_type = 1;
        newHistory.duration = now;
        // newHistory.webOwnedAmount = _webOwnedAmount;
        auctionHistory[auctionId].push(newHistory);

        emit AuctionCreated(msg.sender, auctionId);
        return true;
    }

    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint ID of the created auction
     @param _endDate uint ID of the created auction
     */
    function finalizeAuction(uint256 _auctionId, uint256 _endDate) public {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;

        require(myAuction.owner == msg.sender);

        (
            ,
            ,
            address payable owner,
            address payable creator,
            ,
            uint256 royaltyFee,
            ,
            
        ) = NFTContract.products(myAuction.productId);

        // if there are no bids cancel
        if (bidsLength == 0) {
            // cancelAuction(_auctionId);
        } else {
            // 2. the money goes to the auction owner
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
          
            uint256 singlePrice = lastBid.totalAmount.mul(100).div(105);
						uint256 serviceFeeAmt = lastBid.amount.sub(singlePrice);
						uint256 commissionAmt = singlePrice.mul(commission).div(10**4);
						uint256 royaltyAmt = singlePrice.mul(royaltyFee).div(100);

            if (!owner.send((singlePrice.sub(commissionAmt)).sub(royaltyAmt))) {
                revert();
            }
            if (!creator.send(royaltyAmt)) {
                revert();
            }

            if (!_webOwner.send(serviceFeeAmt.add(commissionAmt))) {
                revert();
            }

            NFTContract.transferERC721Token(
            owner,
            lastBid.from,
            myAuction.productId
            );


            if (true) {
                myAuction.active = false;
                myAuction.endPrice = lastBid.amount;
                myAuction.endDate = _endDate;
								auctions[_auctionId]=myAuction;
                emit AuctionFinalized(
                    msg.sender,
                    _auctionId,
                    lastBid.from,
                    myAuction.productId
                );
                // emit Contract( id, name, owner, price,royaltyFee);
            }
        }
    }

    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint ID of the created auction
     @param _endDate uint ID of the created auction
     */
    function finalizeERC1155Auction(uint256 _auctionId, uint256 _endDate)
        public
    {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;

        require(myAuction.owner == msg.sender);

        (
            ,
            ,
            address payable owner,
            address payable creator,
            ,
            uint256 royaltyFee,
            uint256 webFee,
        ) = NFTContract.products(myAuction.productId);

        // 1. if auction not ended just revert
        // if (now < myAuction.blockDeadline) revert();

        // if there are no bids cancel
        if (bidsLength == 0) {
            // cancelAuction(_auctionId);
        } else {
            // 2. the money goes to the auction owner
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            // (bool resp, bytes memory data) = myAuction.deedRepositoryAddress.delegatecall(abi.encodeWithSignature("div(uint256,uint256)", 25, 1000));
            // uint256 webOwnerAmount = mul(div(25,1000) , lastBid.amount);
            // uint256 AuctionOwnerAmount = sub(lastBid.amount , webOwnerAmount);
            //  if (!_webOwner.send(lastBid.webOwnedAmount)) {
            //     revert();
            // }
            // if (!myAuction.owner.send(lastBid.auctionOwnerAmount)) {
            //     revert();
            // }

            uint256 remaining = lastBid.amount.sub(
                lastBid.amount.div(100).mul(royaltyFee) +
                    lastBid.amount.div(100).mul(webFee)
            );
            if (!owner.send(remaining)) {
                revert();
            }
            if (!creator.send(lastBid.amount.div(100).mul(royaltyFee))) {
                revert();
            }

            // require(NFTContract.ownerOf(myAuction.productId) == msg.sender, "NOT OWNER");
            // NFTContract.approve(address(this) to, uint256 tokenId)(msg.sender, address(this));
            // NFTContract.setApprovalForAll(address(this), true);
            // NFTContract.safeTransferFrom( msg.sender, lastBid.from , myAuction.productId);

            // approve and transfer from this contract to the bid winner
            // approve and transfer from this contract to the bid winner
            // if(approveAndTransfer(address(this), lastBid.from, myAuction.deedRepositoryAddress, myAuction.productId)){
            if (true) {
                myAuction.active = false;
                myAuction.endPrice = lastBid.amount;
                myAuction.endDate = _endDate;
								auctions[_auctionId]=myAuction;
                emit AuctionFinalized(
                    msg.sender,
                    _auctionId,
                    lastBid.from,
                    myAuction.productId
                );
                // emit Contract( id, name, owner, price,royaltyFee);
            }
        }
    }

    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint ID of the created auction
     */
    function cancelAuction(uint256 _auctionId) public {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;

        // require(myAuction.owner == msg.sender);

        // if there are no bids cancel
        if (bidsLength == 0) {
            // cancelAuction(_auctionId);
            auctions[_auctionId].active = false;
        } else {
            // 2. the money goes to the auction owner
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            // (bool resp, bytes memory data) = myAuction.deedRepositoryAddress.delegatecall(abi.encodeWithSignature("div(uint256,uint256)", 25, 1000));
            // uint256 webOwnerAmount = mul(div(25,1000) , lastBid.amount);
            // uint256 AuctionOwnerAmount = sub(lastBid.amount , webOwnerAmount);

            if (!myAuction.owner.send(lastBid.amount)) {
                revert();
            }

            // if(approveAndTransfer(address(this), lastBid.from, myAuction.deedRepositoryAddress, myAuction.productId)){
            if (true) {
                auctions[_auctionId].active = false;
                emit AuctionCancelled(
                    msg.sender,
                    _auctionId,
                    lastBid.from,
                    myAuction.productId
                );
            }
        }
    }

    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint ID of the created auction

     */
    function bidOnUnlimitedAuction(uint256 _auctionId) public payable {
        uint256 ethAmountSent = msg.value.mul(100).div(105);

        // owner can't bid on their auctions
        Auction memory myAuction = auctions[_auctionId];
        if (myAuction.owner == msg.sender) {
            revert();
        }

        // if auction is expired
        // if (now > myAuction.blockDeadline) revert();

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        // there are previous bids
        if (bidsLength > 0) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.amount;
        }

        // check if amound is greater than previous amount
        if (ethAmountSent < tempAmount) {
            revert();
        }

        // refund the last bidder
        if (bidsLength > 0) {
            if (!lastBid.from.send(lastBid.totalAmount)) {
                revert();
            }
        }

        History memory newHistory;
        newHistory.from = msg.sender;
        newHistory.quantity = 1;
        newHistory.amount = ethAmountSent;
        newHistory.history_type = 2;
        newHistory.duration = now;
        auctionHistory[_auctionId].push(newHistory);

        // insert bid
        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.amount = ethAmountSent;
        newBid.totalAmount = msg.value;
        // newBid.auctionOwnerAmount = _auctionOwnerAmount;
        // newBid.webOwnedAmount = _webOwnedAmount;
        auctionBids[_auctionId].push(newBid);
    }

    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint ID of the created auction

     */
    function bidOnTimedAuction(uint256 _auctionId) public payable {
        uint256 ethAmountSent = msg.value.mul(100).div(105);

        // owner can't bid on their auctions
        Auction memory myAuction = auctions[_auctionId];
        if (myAuction.owner == msg.sender) {
            revert();
        }

        require(now < myAuction.endDate, "Date is expired.");

        // if auction is expired
        // if (now > myAuction.blockDeadline) revert();

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        // there are previous bids
        if (bidsLength > 0) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.amount;
        }

        // check if amound is greater than previous amount
        if (ethAmountSent < tempAmount) {
            revert();
        }

        // refund the last bidder
        if (bidsLength > 0) {
            if (!lastBid.from.send(lastBid.totalAmount)) {
                revert();
            }
        }

        History memory newHistory;
        newHistory.from = msg.sender;
        newHistory.quantity = 1;
        newHistory.amount = ethAmountSent;
        newHistory.history_type = 2;
        newHistory.duration = now;
        auctionHistory[_auctionId].push(newHistory);

        // insert bid
        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.quantity = 1;
        newBid.amount = ethAmountSent;
        newBid.totalAmount = msg.value;
        // newBid.webOwnedAmount = _webOwnedAmount;
        auctionBids[_auctionId].push(newBid);
    }

    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint ID of the created auction

     */
    function fixedPriceAuction(uint256 _auctionId) public payable {
        uint256 singlePrice = msg.value.mul(100).div(105);

        Auction memory myAuction = auctions[_auctionId];

        // owner can't bid on their auctions
        if (myAuction.owner == msg.sender) {
            revert();
        }

        if (myAuction.startPrice != singlePrice) {
            revert();
        }
                    
        (
            ,
            ,
            address payable owner,
            address payable creator,
            ,
            uint256 royaltyFee,
            ,
        ) = NFTContract.products(myAuction.productId);

					uint256 serviceFeeAmt = msg.value.sub(singlePrice);
					uint256 royaltyAmount = singlePrice.mul(royaltyFee).div(100);
					uint256 commissionAmt = singlePrice.mul(commission).div(10**4);

            if (!owner.send(singlePrice.sub(royaltyAmount).sub(commissionAmt))) {
                revert();
            }
            if (!creator.send(royaltyAmount)) {
                revert();
            }

            if (!_webOwner.send(serviceFeeAmt.add(commissionAmt))) {
                revert();
            }

        NFTContract.transferERC721Token(
            owner,
            msg.sender,
            myAuction.productId
        );
					myAuction.active = false;
					myAuction.endDate = now;
					auctions[_auctionId]=myAuction;
					emit AuctionFinalized(
							msg.sender,
							singlePrice,
							0xdF6e287f9a723afaA8B2B42a984Bdc0714b35974,
							msg.value
					);
            // emit Contract( id, name, owner, price,royaltyFee);
    }

		/// @notice Function for the owner of the contract to set the new Service fees
		/// @dev It has a decimal precision of 2.
		/// @param _newValue new value for service fees
		/// @return uint256 i.e the new serviceFee value
		function setServiceFee(uint256 _newValue) public isWebOwner returns(uint256){
			serviceFee =  _newValue;
			return serviceFee;
		}

		/// @notice Function for the owner of the contract to set the new Commission
		/// @dev It has a decimal precision of 2.
		/// @param _newValue new value for commission
		/// @return uint256 i.e the new commission value
		function setCommission(uint256 _newValue) public isWebOwner returns(uint256){
			commission = _newValue;
			return commission;
		}
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "../../introspection/ERC165.sol";

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: if all token IDs share a prefix (e.g. if your URIs look like
     * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     *
     * _Available since v2.5.0._
     */
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a preffix in {tokenURI} to each token's URI, when
    * they are non-empty.
    *
    * _Available since v2.5.0._
    */
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";

/**
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC721Enumerable.sol";
import "./ERC721.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {ERC721-_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../drafts/Counters.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/drafts/Counters.sol";


contract ArtabiaERC721 is ERC721Full {
    string public name;
    uint256 public productCount = 0;

    mapping(uint256 => Product) public products;
    mapping(address => uint256[]) public tokenOwner;
    // Mapping of token owned.
    mapping(address => uint256[]) public tokenOwned;

    struct Product {
        uint256 id;
        string name;
        address payable owner;
        address payable creator;
        uint256 price;
        uint256 royaltyFee;
        uint256 webFee;
        bool onSale;
    }

    event ProductApproved(uint256 _productId);

    event TransferProduct(uint256 _productId);

    event ProductCreated(
        uint256 id,
        string _name,
        address payable owner,
        address payable created
    );

    event ProductUpdated(
        uint256 id,
        address from,
        address owner,
        uint256 price
    );

    constructor() public ERC721Full("Artabia", "ArtabiaCollection") {}

    function createProduct(
        address owner,
        string memory metadataURI,
        string memory _name,
        uint256 royaltyFee,
        uint256 webFee,
        uint256 price,
        bool onSale
    ) public {
        require(bytes(_name).length > 0);
        // // Required Valid Price
        // require(_price > 0);
        //Increment product count
        productCount++;
        _mint(msg.sender, productCount);
        addItemMetadata(productCount, metadataURI);
        tokenOwner[msg.sender].push(productCount);
        //create a product
        products[productCount] = Product(
            productCount,
            _name,
            msg.sender,
            msg.sender,
            price,
            royaltyFee,
            webFee,
            onSale
        );

        //Trigger the enter
        emit ProductCreated(productCount, _name, msg.sender, msg.sender);
    }

    function getAddress() public view returns (address) {
        address myaddress = address(this); //contract address
        return myaddress;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getTokensOf(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ownedTokens = tokenOwner[_owner];
        return ownedTokens;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getOwnedTokensOf(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ownedTokens = tokenOwned[_owner];
        return ownedTokens;
    }

    //Transfer Token
    function transferERC721Token(
        address seller,
        address payable to,
        uint256 _tokenId
    ) external {
        _transferFrom(seller, to, _tokenId);
        tokenOwned[to].push(_tokenId);
        
        Product memory _product = products[_tokenId];
        _product.owner = to;
        _product.onSale = false;
        products[_tokenId] = _product;

        deleteTokenOf(seller, _tokenId);
    }

    //Update Token
    function updateToken(
        uint256 _tokenId
    ) external {
        Product memory _product = products[_tokenId];
        _product.onSale = true;
        products[_tokenId] = _product;
    }

    /**
     * @dev delete element of owned token
     * @param _owner address of the auction owner
     */
    function deleteTokenOf(address _owner, uint256 _tokenId)
        public
        returns (uint256[] memory)
    {
        uint256[] memory ownedTokens = tokenOwned[_owner];
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            if (ownedTokens[i] == _tokenId) {
                delete ownedTokens[i];
            }
        }

        tokenOwned[_owner] = ownedTokens;
        return ownedTokens;
    }

    function addItemMetadata(uint256 _tokenId, string memory _uri)
        internal
        returns (bool)
    {
        _setTokenURI(_tokenId, _uri);
        return true;
    }

    
}