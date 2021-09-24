// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.4 <=0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
// import "./IERC1155.sol";
import "./INEFTiMultiTokens.sol";
// import "./INEFTiMPFeeCalcExt.sol";
// import "./INEFTiMPServiceExt.sol";
import "./SafeERC20.sol";

// abstract contract IERC20Ext is IERC20 {
//     function decimals() public virtual view returns (uint8);
// }

contract NEFTiMarketplace is Ownable {
    using SafeMath for uint256;
    // using SafeERC20 for IERC20Ext;
    using SafeERC20 for IERC20;

    // enum ResourceClasses {
    //     IMAGE,          // 0x00,
    //     AUDIO,          // 0x01,
    //     VIDEO,          // 0x02,
    //     OBJECT3D,       // 0x03,
    //     DOCUMENT,       // 0x04,
    //     FONT,           // 0x05,
    //     REDEEMABLE,     // 0x06,
    //     GAMEASSETS      // 0x07,
    // }

    // enum SaleMethods {
    //     DIRECT,         // 0x00,                                    (1) seller pays gas to get listing,
    //                     //                                          (2) buyer pays gas to purchase,
    //                     //                                          (3) seller receive payment from buyer - transaction fee

    //     AUCTION,        // 0x01,                                    (1) seller pays gas and auction listing fee,
    //                     //                                          (2) bidder pays gas for each bids to purchase,
    //                     //                                          (3) auction which have no bidder are able cancel by seller, costs gas
    //                     //                                          (4) bidder pays gas for cancellation, also costs transaction fee
    //                     //                                          (5) bidder unable to cancel bids last 1 hour before auction time expired
    //                     //                                          (6) seller may claim the highest bid when auction was completed
    //                     //                                              within 1 hour after the expiration time, cost gas and transaction fee
    //                     //                                          (7) or the company pays gas to set auto-expired for auction after 1 hour

    //     RENTAL          // 0x02,                                    (1) seller pays gas and rental listing fee,
    //                     //                                          (2) buyer pays gas to propose rent contract schedule
    //                     //                                              and notify the seller for new rent contract schedule
    //                     //                                          (3) seller pays gas to accept the new rent contract schedule, recieve rent fee - transaction fee
    //                     //                                          (4) buyer pays gas to renew (extend) rent contract, also rent fee
    //                     //                                          (5) seller pays gas to accept the new rent contract schedule, receive rent fee - transaction fee
    //                     //                                          (6) the company pays gas to mark rent to be expired (token => disabled state)
    //                     //                                              and notify both seller and buyer (if schedule has expired)
    // }

    // enum PaymentMethods {
    //     PREPAID,        // 0x00,                                    (1) seller decide to be paid soon,
    //     POSTPAID        // 0x01,                                    (1) seller decide to be paid at the end
    // }

    enum SaleStatus {
        OPEN,           // 0x00,    sale is open                    (gas pays by the seller)
        FULFILLED,      // 0x01,    sale is filfilled               (gas pays by the buyer)
        RENTING,        // 0x02,    an item goes on rent                
        PAUSED,         // 0x03,    an item paused                  (gas pays by the seller)                
        CANCELED,       // 0x04,    sale is cancelled               (gas may pays by the seller or the buyer)
        EXPIRED,        // 0x05,    sale is expired                 (gas may pays by the seller or the company)
        SUSPENDED,      // 0x06,    sale is suspended               (gas pays by the company)
        DELISTED        // 0x07,    sale is delisted                (gas pays by the company)
    }

    enum PurchaseStatus {
        ACCEPTED,       // 0x00,    sale is open                    (gas pays by the seller)
        SENDING,        // 0x01,    sale is closed                  (gas pays by the buyer)
        INPROGRESS,     // 0x02,    an item goes on rent            
        REJECTED,       // 0x03,    an item on escrow               
        FULFILLED       // 0x04,    sale is cancelled               (gas may pays by the seller or the buyer)
    }

    enum NegotiateStatus {
        OPEN,           // 0x00,    negotiation is open             (gas pays by the buyer as negotiator)
        SENDING,        // 0x01,    negotiation OK, sending         (gas pays by the seler to accept, and sending items)
        INPROGRESS,     // 0x02,    negotiation OK, in progress     (gas pays by the seler to accept, and in progress)
        FULFILLED,      // 0x03,    negotiation is fulfilled        (gas pays by the buyer to fulfill the rent)
        REJECTED,       // 0x04,    negotiation is rejected         (gas pays by the seller to reject)
        CANCELED       // 0x05,    IF BUYER cancel negotiation     (gas pays by the buyer, also charge cancellation fee as income to the company)
                        //          IF SELLER cancel negotiation    (gas pays by the seller, also charge cancellation fee as income to the company)
    }

    struct SaleItems {
        // uint256 saleId;
        uint256 tokenId;
        uint256 price;
        uint256 amount;
        // ResourceClasses resourceClass;
        // SaleMethods saleMethod;
        address seller;
        // uint256 listDate;
        bool[4] states;
        // bool isPostPaid;
        // bool isNegotiable;
        // bool isAuction;
        // bool isContract; === false
        uint256 saleDate;
        uint256[3] values;
        // uint256 valContract;
        // uint256 highBid;
        // uint256 bidMultiplier;
        address buyer;
        SaleStatus status;
    }

    struct PurchaseItems {
        uint256 buyId;
        uint256 saleId;
        uint256 tokenId;
        uint256 price;
        uint256 amount;
        // ResourceClasses resourceClass;
        // SaleMethods saleMethod;
        address seller;
        // uint256 listDate;
        bool[4] states;
        // bool isPostPaid;
        // bool isNegotiable;
        // bool isAuction;
        // bool isContract;
        uint256 purchaseDate;
        uint256[3] values;
        // uint256 valContract;
        // uint256 highBid;
        // uint256 bidMultiplier;
        address buyer;
        PurchaseStatus status;
    }

    struct Negotiating {
        uint256 saleHash;
        address negosiator;
        uint256 value;
        uint256 amount;
        uint256 negoDate;
        NegotiateStatus status;
    }

    struct StaticFee {
        uint8[3] MODE_BNB_NFT;
        uint8[3] MODE_BNB;
        uint8[3] MODE_B20_NFT;
        uint8[3] MODE_B20;
        uint8[3] MODE_NFT;
    }

    // @dev Sale Pool
    // @params address Seller address
    // @params uint256 TokenId
    // @return uint256 Balance amount of token
    mapping (address => mapping (uint256 => uint256)) internal poolSales;

    // @dev Sale Pool Info
    // @params uint256 Sale ID
    // @return SaleItems struct of SaleItems
    mapping (uint256 => SaleItems) internal selling;

    // @dev Listed items by Seller address
    // @params address Seller address
    // @return uint256[] Sale Ids
    mapping (address => uint256[]) internal itemsOnSaleItems;

    // @dev All listed items Sale Ids
    uint256[] internal saleItems;

    // @dev Purchase Pool Info
    // @params uint256 Purchase ID
    // @return PurchaseItems struct of PurchaseItems
    mapping (uint256 => PurchaseItems) internal purchasing;
    
    // @dev Bidding pool for Auction
    // @params uint256 Sale/Auction ID
    // @params address Buyers (bidders)
    // @return uint256 Bid value
    mapping (uint256 => mapping (address => uint256)) internal poolBidding;

    // @dev Negotiation pool
    // @params uint256 Sale ID
    // @params address Negotiator
    // @return uint256 Negotiating Info
    mapping (uint256 => mapping (address => Negotiating)) internal poolNegotiating;

    // @dev Bidders in Auction
    // @params uint256 Sale ID
    // @return address[] Bidders
    mapping (uint256 => address[]) bidders;

    // @dev Negotiators in Sale
    // @params uint256 Sale ID
    // @return address[] Negotiators
    mapping (uint256 => address[]) negotiators;

    // mapping (address => uint256) internal txNonce;

    // bool internal feeCalcMechanism = false;
    StaticFee internal staticFee = StaticFee(
        /* BNB+NFT */   [6, 0, 2],
        /* BNB     */   [8, 0, 0],
        /* B20+NFT */   [0, 6, 2],
        /* B20     */   [0, 8, 0],
        /* NFT     */   [0, 0, 8]
    );

    IERC20 internal NEFTi20;
    uint256 internal NEFTi20_decimals = 16;

    INEFTiMultiTokens internal NEFTiMT;

    // INEFTiMPFeeCalcExt internal NEFTiMPFeeCalcExt = INEFTiMPFeeCalcExt(c__NEFTiMPFeeCalcExtension);

    uint256 internal ratingValue = 100 * (10**NEFTi20_decimals);
    uint8 internal ratingScore = 10;
    
    uint256 internal directListingFee = 0;                  // FREE
    uint256 internal directNegotiateFee = 1;                // 0.1% x Negotiate Price
    uint256 internal directNegotiateCancellationFee = 5;    // 0.5% x Negotiate Price
    uint256 internal directCancellationFee = 0;             // FREE
    uint256 internal directTxFee = 8;                       // 0.8% x Item Price

    uint256 internal auctionListingFee = 3;                 // 0.3% x Item Price
    uint256 internal auctionListingCancellationFee = 5;     // 0.5% x Item Price
    uint256 internal auctionBiddingFee = 1;                 // 0.1% x Bid Price
    uint256 internal auctionBiddingCancellationFee = 5;     // 0.5% x Bid Price
    uint256 internal auctionTxFee = 8;                      // 0.8% x Item Price

    uint256 internal contractListingFee = 3;                // 0.3% x Item Price
    uint256 internal contractListingCancellationFee = 5;    // 0.5% x Item Price
    uint256 internal contractNegotiateFee = 1;              // 0.1% x Negotiate Price
    uint256 internal contractTxFee = 8;                     // 0.8% x Item Price
    
    uint256 constant staticPercent = 1000;

    event Logger(address _log);

    event Sale(
        uint256 indexed saleId,
        uint256 indexed tokenId,
        uint256 price,
        uint256 amount,
        uint8 saleMethod,
        address indexed seller,
        bool[4] states,
        // bool isPostPaid;
        // bool isNegotiable;
        // bool isAuction;
        // bool isContract;
        uint256 saleDate,
        uint8 status
    );

    event NegotiationCanceled(uint256 _sid, address _negotiator);
    
    event BidCanceled(uint256 _sid, address _negotiator);

    event CancelSale(
        uint256 indexed saleId,
        uint256 indexed tokenId,
        address indexed seller,
        uint8 status
    );

    event Purchase(
            uint256 purchaseId,
            uint256 saleId,
            uint256 tokenId,
            uint256 price,
            uint256 amount,
            uint8 saleMethod,
            address seller,
            bool[4] states,
            uint8 status
        );


    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
    
    ///////////////////////////////////////////////////////////////////////////
    // LISTING
    ///////////////////////////////////////////////////////////////////////////

    /**
    ** @dev Proceed Listing item into Marketplace
    ** @param _from Owner of the item
    ** @param _id Token ID of the NEFTiMultiToken
    ** @param _amount Amount of the item
    ** @param _price Price of the item
    ** @param _saleMethod Selling method
    **/
    function sellToken(uint256 _id, uint256 _amount, uint256 _price, uint8 _saleMethod)
        internal
    {
        uint256 listingFee = (
            // SaleMethods(_saleMethod) == SaleMethods.DIRECT
            _saleMethod == 0
            ?   0   // directListingFee * (10**NEFTi20_decimals)
            :   (
                // SaleMethods(_saleMethod) == SaleMethods.AUCTION
                _saleMethod == 1
                ?   _price.mul(auctionListingFee).div(staticPercent)
                :   _price.mul(contractListingFee).div(staticPercent)
            )
        );
        
        if (listingFee > 0) {
            require(NEFTi20.balanceOf(msg.sender) >= listingFee, "Not enough NFT balance for listing");

            NEFTi20.safeTransferFrom(
                msg.sender,
                address(this),
                listingFee
            );
        }

        NEFTiMT.safeTransferFrom(msg.sender, address(this), _id, _amount, "");
    }
    /**
    ** @dev Listing NEFTiMultiTokens (MT) into the Marketplace (MP)
    ** @param _sid Input SaleItems ID (client-side)
    ** @param _tokenId Token ID of the NEFTiMultiToken
    ** @param _price Price of the item
    ** @param _amount Amount of the item
    ** @param _saleMethod Selling method
    ** @param _states States in array
    ** @param _saleDate Listing date for sale
    **/
    function txSaleItems(
        uint256 _sid,
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount,
        // uint8 _resourceClass,
        uint8 _saleMethod,
        bool[4] memory _states,
        // bool _isPostPaid,
        // bool _isNegotiable,
        // bool _isAuction,
        uint _saleDate
    )
        public
    {
        require(_saleMethod <= 2, "Unknown Sale Method!");
        require(_saleDate >= block.timestamp, "Time for sale is behind current time!");
        require(NEFTiMT.balanceOf(msg.sender, _tokenId) > 0, "Not enough current token id balance for listing!");
        require(_amount > 0, "Zero amount is not applicable for listing!");

        poolSales[msg.sender][_tokenId] += _amount; // necessarily multi tx for the same address of item collection ?
        if ((selling[_sid].amount == 0) && (selling[_sid].amount == 0)) {
            saleItems.push(_sid);
            itemsOnSaleItems[msg.sender].push(_sid);
        }

        uint256[3] memory values = [ uint(0), uint(0), uint(0) ];
        selling[_sid] = SaleItems(
            // _sid,
            _tokenId,
            _price,
            _amount,
            // ResourceClasses(_resourceClass),
            // SaleMethods(_saleMethod),
            msg.sender,
            // block.timestamp,
            [
                _states[0],
                _states[1],
                _states[2],
                false
            ],
            // _isPostPaid,
            // _isNegotiable,
            // _isAuction,
            // false,
            _saleDate,
            values,
            // 0,
            // 0,
            // 0,
            address(0),
            SaleStatus.OPEN
        );

        sellToken(_tokenId, _amount, _price, _saleMethod);
        
        emit Sale(
            _sid,
            _tokenId,
            _price,
            _amount,
            _saleMethod,
            msg.sender,
            [ _states[0], _states[1], _states[2], false ],
            _saleDate,
            uint8(SaleStatus.OPEN)
        );
    }

    ///////////////////////////////////////////////////////////////////////////
    // SALE UTILITY
    ///////////////////////////////////////////////////////////////////////////

    /**
    ** @dev Get items SaleItems ID
    ** @return Array of SaleItems IDs (bytes32)
    **/
    function getSaleItems()
        public view
        returns (uint256[] memory saleIds)
    {
        uint skipper = 0;
        for (uint256 i=0; i < saleItems.length; i++) {
            if (
                (selling[saleItems[i]].status == SaleStatus.OPEN) ||
                (selling[saleItems[i]].status == SaleStatus.RENTING)
            ) {
                saleIds[i-skipper] = saleItems[i];
            } else {
                skipper++;
            }
        }
    }
    /**
    ** @dev Get item information by SaleItems ID
    ** @param _sid SaleItems ID
    ** @return Item information (SaleItems)
    **/
    function getSaleItemsInfo(uint256 _sid)
        public view
        returns (
            // uint256 saleId,
            uint256[3] memory info,
            // uint256 tokenId,
            // uint256 price,
            // uint256 amount,
            // uint8 resourceClass,
            // uint8 saleMethod,
            address seller,
            // uint256 listDate,
            bool[4] memory states,
            // bool isPostPaid,
            // bool isNegotiable,
            // bool isAuction,
            // bool isContract,
            uint256 saleDate,
            uint256[3] memory values,
            // uint256 valContract,
            // uint256 highBid,
            // uint256 bidMultiplier,
            address buyer,
            uint8 status
        )
    {
        return (
            // _sid,
            [
                selling[_sid].tokenId,
                selling[_sid].price,
                selling[_sid].amount
            ],
            // uint8(selling[_sid].resourceClass),
            // uint8(selling[_sid].saleMethod),
            selling[_sid].seller,
            // selling[_sid].listDate,
            selling[_sid].states,
            // selling[_sid].isPostPaid,
            // selling[_sid].isNegotiable,
            // selling[_sid].isAuction,
            // selling[_sid].isContract,
            selling[_sid].saleDate,
            selling[_sid].values,
            // selling[_sid].valContract,
            // selling[_sid].highBid,
            // selling[_sid].bidMultiplier,
            selling[_sid].buyer,
            uint8(selling[_sid].status)
        );
    }
    // Amount of item on sale by seller address
    /**
    ** @dev Get sale item amount by seller address and token ID
    ** @param _sid SaleItems ID
    ** @param _tokenId Token ID of the NEFTiMultiToken
    ** @return Amount
    **/
    function balanceOf(address _seller, uint256 _tokenId)
        public view
        returns (uint256)
    { return (poolSales[_seller][_tokenId]); }
    /**
    ** @dev Get sale items by seller address
    ** @param _seller Address of the seller
    ** @return Array of SaleItems IDs (bytes32)
    **/
    function itemsOf(address _seller)
        public view
        returns (uint256[] memory items)
    { return itemsOnSaleItems[_seller]; }

    function cancelNegotiation(uint256 _sid, address _negotiator)
        public
    {
        bool isNegotiator = false;
        bool isSeller = (msg.sender == selling[_sid].seller);
        address negotiator = address(0);
        NegotiateStatus cancelStatus;

        if (isSeller || msg.sender == owner()) {
            cancelStatus = NegotiateStatus.REJECTED;
            negotiator = _negotiator;
        } else {
            for (uint256 i=0; negotiators[_sid].length > i; i++) {
                if (negotiators[_sid][i] == msg.sender) {
                    isNegotiator = true;
                    negotiator = msg.sender;
                    break;
                }
            }
            require(isNegotiator, "Only seller or negotiator can cancel the negotiation!");
            cancelStatus = NegotiateStatus.CANCELED;
        }
        
        if (isSeller && cancelStatus == NegotiateStatus.CANCELED) {
            uint256 cancellationFee = (poolNegotiating[_sid][msg.sender].value.mul(directNegotiateCancellationFee)).div( staticPercent );
            require(NEFTi20.balanceOf(msg.sender) >= cancellationFee, "Not enough current token balance for cancellation!");
            NEFTi20.safeTransferFrom(
                msg.sender,
                owner(),
                cancellationFee
            );
        }

        for (uint256 i=0; negotiators[_sid].length > i; i++) {
            if (negotiators[_sid][i] == negotiator) {
                NEFTi20.safeTransferFrom(
                    address(this),
                    negotiators[_sid][i],   // negotiator
                    poolNegotiating[_sid][negotiator].value
                );
                poolNegotiating[_sid][negotiator].status = cancelStatus;

                negotiators[_sid][i] = negotiators[_sid][negotiators[_sid].length-1];
                delete negotiators[_sid][negotiators[_sid].length-1];
            }
        }

        emit NegotiationCanceled(_sid, negotiator);
    }

    function cancelAuctionBid(uint256 _sid, address _bidder)
        public
    {
        bool isBidder = false;
        bool isSeller = (msg.sender == selling[_sid].seller);
        address bidder = address(0);

        if (isSeller || msg.sender == owner()) {
            bidder = _bidder;
        } else {
            for (uint256 i=0; bidders[_sid].length > i; i++) {
                if (bidders[_sid][i] == msg.sender) {
                    isBidder = true;
                    bidder = msg.sender;
                    break;
                }
            }
            require(isBidder, "Only seller or bidder can cancel the negotiation!");
        }
        
        if (isSeller) {
            uint256 cancellationFee = (poolBidding[_sid][msg.sender].mul(auctionListingCancellationFee)).div( staticPercent );
            require(NEFTi20.balanceOf(msg.sender) >= cancellationFee, "Not enough current token balance for cancellation!");
            NEFTi20.safeTransferFrom(
                msg.sender,
                owner(),
                cancellationFee
            );
        }

        for (uint256 i=0; negotiators[_sid].length > i; i++) {
            if (bidders[_sid][i] == bidder) {
                NEFTi20.safeTransferFrom(
                    address(this),
                    bidders[_sid][i],   // bidder
                    poolBidding[_sid][bidder]
                );
                poolBidding[_sid][bidder] = 0;

                bidders[_sid][i] = bidders[_sid][bidders[_sid].length-1];
                delete bidders[_sid][bidders[_sid].length-1];
            }
        }

        emit BidCanceled(_sid, bidder);
    }

    function getListingCancellationFee(uint256 _sid)
        public view
        returns (uint256)
    {
        require(_sid > 0, "Unknown Sale ID");
        require(selling[_sid].status == SaleStatus.OPEN, "Only open sale can be canceled!");

        uint256 fee = (
            (!selling[_sid].states[2] && !selling[_sid].states[3])
            ?   ((selling[_sid].price * selling[_sid].amount).mul(directCancellationFee)).div( staticPercent )
            :   (
                (selling[_sid].states[2] && !selling[_sid].states[3])
                    ?   ((selling[_sid].price * selling[_sid].amount).mul(auctionListingCancellationFee)).div( staticPercent )
                    :   ((selling[_sid].price * selling[_sid].amount).mul(contractListingCancellationFee)).div( staticPercent )
            )
        );
        return fee;
    }

    function cancelSaleItem(uint256 _sid)
        public
    {
        require(_sid > 0, "Unknown Sale ID");
        address seller = selling[_sid].seller;
        require(msg.sender == seller || msg.sender == owner(), "Only seller can cancel the sale!");
        require(selling[_sid].status == SaleStatus.OPEN, "Only open sale can be canceled!");
        require(msg.sender.balance > 0, "Cancellation cost gas fee");

        NEFTiMT.safeTransferFrom(
            address(this),
            selling[_sid].seller,
            selling[_sid].tokenId,
            selling[_sid].amount,
            ""
        );

        // when it's Auction
        if (selling[_sid].states[2]) {
            if (bidders[_sid].length > 0) {
                for (uint256 i=0; i < bidders[_sid].length; i++) {
                    if (bidders[_sid][0] != address(0)) {
                        cancelAuctionBid(_sid, bidders[_sid][0]);   
                    }
                }
            }
        }
        // when it's Direct Sale or Contract
        else if (
            !selling[_sid].states[2] ||
            selling[_sid].states[3]
        ) {
            if (negotiators[_sid].length > 0) {
                for (uint256 i=0; i < negotiators[_sid].length; i++) {
                    if (negotiators[_sid][0] != address(0)) {
                        cancelNegotiation(_sid, negotiators[_sid][0]);   
                    }
                }
            }
        }

        if (itemsOnSaleItems[seller].length > 0) {
            for (uint256 i=0; i < itemsOnSaleItems[seller].length; i++) {
                if (itemsOnSaleItems[seller][0] != _sid) {
                    itemsOnSaleItems[seller][i] = itemsOnSaleItems[seller][itemsOnSaleItems[seller].length-1];
                    delete itemsOnSaleItems[seller][itemsOnSaleItems[seller].length-1];
                }
            }
        }

        poolSales[seller][selling[_sid].tokenId] -= selling[_sid].amount;
        selling[_sid].buyer = address(0);
        selling[_sid].status = SaleStatus.CANCELED;

        emit CancelSale(
            _sid,
            selling[_sid].tokenId,
            seller,
            uint8(SaleStatus.CANCELED)
        );
    }

    function getAuctionBidders(uint256 _sid) 
        public view
        returns (address[] memory auctionBidders)
    {
        require(_sid > 0, "Unknown Sale ID");
        return bidders[_sid];
    }

    function getBidValue(uint256 _sid, address _bidder) 
        public view
        returns (uint256)
    {
        require(_sid > 0, "Unknown Sale ID");
        require(_bidder != address(0), "Unknown Bidder");
        return poolBidding[_sid][_bidder];
    }
    

    ///////////////////////////////////////////////////////////////////////////
    // PURCHASING DIRECT BUY
    ///////////////////////////////////////////////////////////////////////////

    /**
    ** @dev Buying item directly
    ** @param _sid SaleItems ID
    ** @param _pid Input PurchaseItems ID (client-side)
    ** @param _amount Amount to buy
    **/
    function txDirectBuy(
        uint256 _sid,
        uint256 _pid,
        uint256 _amount
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for sale!");
        require (selling[_sid].saleDate <= block.timestamp, "Item is not yet for sale!");
        require (selling[_sid].amount >= _amount, "Not enough tokens for sale!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance > 0, "Not enough BNB to spend for Gas fee!");
        
        uint256 subTotal = selling[_sid].price * _amount;
        uint256 txFee = ( subTotal.mul( directTxFee ) ).div( staticPercent );

        require (NEFTi20.balanceOf(msg.sender) >= subTotal, "Not enough NFT balance for purchase!");

        // transfer NFT20 purchase value to seller
        NEFTi20.safeTransferFrom(
            msg.sender,
            selling[_sid].seller,
            subTotal.sub(txFee)
        );
        // transfer NFT20 fee to owner
        NEFTi20.safeTransferFrom(
            msg.sender,
            owner(),
            txFee
        );
        // then transfer NFT1155 token in return
        NEFTiMT.safeTransferFrom(
            address(this),
            msg.sender,
            selling[_sid].tokenId,
            _amount,
            ""
        );

        uint256[3] memory values = [ uint(0), uint(0), uint(0) ];
        purchasing[_pid] = PurchaseItems(
            _pid,
            _sid,
            selling[_sid].tokenId,
            selling[_sid].price,
            selling[_sid].amount,
            // selling[_sid].resourceClass,
            // selling[_sid].saleMethod,
            selling[_sid].seller,
            // selling[_sid].listDate,
            [ false, false, false, false ],
            block.timestamp,
            values,
            // 0,
            // 0,
            // 0,
            msg.sender,
            PurchaseStatus.FULFILLED
        );

        poolSales[ selling[_sid].seller ][ selling[_sid].tokenId ] = selling[_sid].amount.sub(_amount);

        selling[_sid].amount = selling[_sid].amount.sub(_amount);
        
        if (selling[_sid].amount == 0) {
            selling[_sid].status = SaleStatus.FULFILLED;
        }
        
        emit Purchase(
            _pid,
            _sid,
            selling[_sid].tokenId,
            selling[_sid].price,
            selling[_sid].amount,
            1,
            selling[_sid].seller,
            [ false, false, false, false ],
            uint8(PurchaseStatus.FULFILLED)
        );
    }

    /**
    ** @dev Buyer negotiate an offer
    ** @param _sid SaleItems ID
    ** @param _amount Amount to buy
    ** @param _price Price per token
    **/
    function txDirectOffering(
        uint256 _sid,
        uint256 _amount,
        uint256 _price
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for sale!");
        require (selling[_sid].saleDate >= block.timestamp, "Item is not yet for sale!");
        require (selling[_sid].amount >= _amount, "Not enough tokens for sale!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance == 0, "Not enough BNB to spend for Gas fee!");

        require (selling[_sid].states[1], "This item is not for negotiation!"); 
        // require (selling[_sid].isNegotiable, "This item is not for negotiation!"); 
        require (
            (_price * _amount) < NEFTi20.balanceOf(msg.sender),
            "Not enough NFT token to trade!"
        );
        require (
            _price < selling[_sid].price,
            "negotiate value is too low!"
        );

        uint256 txFee = ( _price * _amount ).mul(contractNegotiateFee).div(staticPercent);
        uint256 subTotal = ( _price * _amount ).add(txFee);
        
        // transfer NFT20 negotiation price to pool
        NEFTi20.safeTransferFrom(
            msg.sender,
            address(this),
            subTotal
        );
        // transfer NFT20 fee to owner
        NEFTi20.safeTransferFrom(
            msg.sender,
            owner(),
            txFee
        );

        if (poolNegotiating[_sid][msg.sender].value == 0) {
            negotiators[_sid].push(msg.sender);
        }

        uint256 prevPrice = poolNegotiating[_sid][msg.sender].value.div( poolNegotiating[_sid][msg.sender].amount );
        uint256 totalAmount = poolNegotiating[_sid][msg.sender].amount.add( _amount );
        
        poolNegotiating[_sid][msg.sender] = Negotiating(
            _sid,
            msg.sender,
            ( prevPrice.add(_price) * totalAmount ),
            totalAmount,
            block.timestamp,
            NegotiateStatus.OPEN
        );

        //todo: emit event
    }

    /**
    ** @dev Seller accept an offer
    ** @param _sid SaleItems ID
    ** @param _pid Input PurchaseItems ID (client-side)
    ** @param _negotiator Selected negotiator address
    **/
    function txAcceptDirectOffering(
        uint256 _sid,
        uint256 _pid,
        address _negotiator
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for sale anymore!");
        require (
            (selling[_sid].amount > 0) &&
            (poolSales[msg.sender][selling[_sid].tokenId] > 0) &&
            (selling[_sid].amount >= poolNegotiating[_sid][_negotiator].amount),
            "Not enough tokens at pool for sale!"
        );
        require (poolNegotiating[_sid][_negotiator].status == NegotiateStatus.OPEN, "This negotiation is not available anymore!");
        require (poolNegotiating[_sid][_negotiator].value > 0, "Current negotiation price was not set!");
        require (poolNegotiating[_sid][_negotiator].amount > 0, "Current negotiation amount was not set!");
        
        uint256 txFee = (poolNegotiating[_sid][_negotiator].value.mul(directTxFee)).div(staticPercent);
        uint256 subTotal = poolNegotiating[_sid][_negotiator].value.sub(txFee);
        
        // transfer NFT20 purchased value to seller - fee
        NEFTi20.safeTransferFrom(
            address(this),
            selling[_sid].seller,
            subTotal
        );
        // transfer NFT20 fee to owner
        NEFTi20.safeTransferFrom(
            address(this),
            owner(),
            txFee
        );
        // transfer NFT1155 asset to buyer
        NEFTiMT.safeTransferFrom(
            address(this),
            _negotiator,
            selling[_sid].tokenId,
            poolNegotiating[_sid][_negotiator].amount,
            ""
        );

        uint256[3] memory values = [ uint(0), uint(0), uint(0) ];
        purchasing[_pid] = PurchaseItems(
            _pid,
            _sid,
            selling[_sid].tokenId,
            poolNegotiating[_sid][_negotiator].value,
            poolNegotiating[_sid][_negotiator].value,
            // selling[_sid].resourceClass,
            // selling[_sid].saleMethod,
            selling[_sid].seller,
            // selling[_sid].listDate,
            [ false, true, false, false ],
            // false,
            // true,
            // false,
            // false,
            block.timestamp,
            values,
            // 0,
            // 0,
            // 0,
            _negotiator,
            PurchaseStatus.FULFILLED
        );
        
        uint256 updateAmount = selling[_sid].amount.sub(1);
        poolSales[msg.sender][selling[_sid].tokenId] = updateAmount;
        selling[_sid].amount = updateAmount;

        if (selling[_sid].amount == 0) {
            selling[_sid].status = SaleStatus.FULFILLED;
        }
        
        poolNegotiating[_sid][_negotiator].status = NegotiateStatus.FULFILLED;
        
        //todo: emit event
    }


    ///////////////////////////////////////////////////////////////////////////
    // PURCHASING IN AUCTION
    ///////////////////////////////////////////////////////////////////////////

    /**
    ** @dev Buyer bid an offer
    ** @param _sid SaleItems ID
    ** @param _price Price to bid
    **/
    function txBid(
        uint256 _sid,
        uint256 _price
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for auction!");
        require (selling[_sid].saleDate <= block.timestamp, "Item is not yet for sale!");
        require (selling[_sid].amount >= 1, "Not enough token for auction!");
        require (_price < NEFTi20.balanceOf(msg.sender), "Not enough NFT token to bid in auction!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance == 0, "Not enough BNB to spend for Gas fee!");

        // when Auction
        // if (selling[_sid].isAuction) {
        if (selling[_sid].states[2]) {
            // require (_price >= selling[_sid].bidMultiplier, "Bid value less than required multiplier!");
            require (_price >= selling[_sid].values[2], "Bid value less than required multiplier!");

            uint256 _updatePrice = poolBidding[_sid][msg.sender].add(_price);
            // require (selling[_sid].highBid >= _updatePrice, "Price is too lower than highest bid!");
            require (selling[_sid].values[1] >= _updatePrice, "Price is too lower than highest bid!");

            // send NFT20 to auction pool
            NEFTi20.safeTransferFrom(
                msg.sender,
                address(this),
                _price
            );
            // send fee NFT20 to owner
            NEFTi20.safeTransferFrom(
                msg.sender,
                owner(),
                _price.mul(auctionBiddingFee).div(staticPercent)
            );

            if (poolBidding[_sid][msg.sender] == 0) {
                bidders[_sid].push(msg.sender);
            }

            // if exist and higher than the highest bid, update to auction bidding pool
            poolBidding[_sid][msg.sender] = _updatePrice;

            // update highest bidder price and address
            // selling[_sid].highBid = _updatePrice;
            selling[_sid].values[1] = _updatePrice;
            selling[_sid].buyer = msg.sender;
            
            poolBidding[_sid][msg.sender] = _updatePrice;

            //todo: emit event
        } else {
            revert("This item is not for auction!");
        }
    }

    /**
    ** @dev Buyer accept an offer of highest bid
    ** @param _sid SaleItems ID
    ** @param _pid Input PurchaseItems ID (client-side)
    **/
    function txAcceptAuctionBid(
        uint256 _sid,
        uint256 _pid
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for auction anymore!");
        require (
            (selling[_sid].amount > 0) &&
            (poolSales[msg.sender][selling[_sid].tokenId] > 0),
            "Not enough tokens at pool for sale!"
        );
        
        require (
            (selling[_sid].buyer != address(0)) ||
            (selling[_sid].buyer != address(0x0)),
            "Current bidder address was not set!"
        );
        require (poolBidding[_sid][selling[_sid].buyer] > 0, "Current bid price was not set!");
        // require (selling[_sid].highBid > 0, "Highest bid value was not set!");
        require (selling[_sid].values[1] > 0, "Highest bid value was not set!");
        
        // uint256 txFee = (selling[_sid].highBid.mul(auctionTxFee)).div(staticPercent);
        uint256 txFee = (selling[_sid].values[1].mul(auctionTxFee)).div(staticPercent);
        // uint256 subTotal = selling[_sid].highBid.add(txFee);
        uint256 subTotal = selling[_sid].values[1].add(txFee);
        
        // transfer NFT20 purchased value to seller - fee
        NEFTi20.safeTransferFrom(
            address(this),
            selling[_sid].seller,
            subTotal
        );
        // transfer NFT20 fee to owner
        NEFTi20.safeTransferFrom(
            address(this),
            owner(),
            txFee
        );
        // transfer NFT1155 asset to buyer
        NEFTiMT.safeTransferFrom(
            address(this),
            selling[_sid].buyer,
            selling[_sid].tokenId,
            selling[_sid].amount,
            ""
        );

        purchasing[_pid] = PurchaseItems(
            _pid,
            _sid,
            selling[_sid].tokenId,
            // selling[_sid].highBid,
            selling[_sid].values[1],
            selling[_sid].amount,
            // selling[_sid].resourceClass,
            // selling[_sid].saleMethod,
            selling[_sid].seller,
            // selling[_sid].saleDate,
            [ false, false, true, false ],
            // false,
            // false,
            // true,
            // false,
            block.timestamp,
            [ 0, selling[_sid].values[1], selling[_sid].values[2] ],
            // 0
            // selling[_sid].highBid,
            // selling[_sid].bidMultiplier,
            selling[_sid].buyer,
            PurchaseStatus.FULFILLED
        );
        
        uint256 updateAmount = selling[_sid].amount.sub(1);
        poolSales[msg.sender][selling[_sid].tokenId] = updateAmount;
        selling[_sid].amount = updateAmount;

        if (selling[_sid].amount == 0) {
            selling[_sid].status = SaleStatus.FULFILLED;
        }
        
        poolBidding[_sid][selling[_sid].buyer] = 0;
        
        //todo: emit event
    }


    ///////////////////////////////////////////////////////////////////////////
    // CONTRACT OFFERING
    ///////////////////////////////////////////////////////////////////////////

    /**
    ** @dev Offering a contract (rent/promise)
    ** @param _sid SaleItems ID
    ** @param _tokenId Token ID
    ** @param _contractPrice Price representate in contract
    ** @param _amount Amount of tokens to sale
    ** @param _resourceClass Resource class of the token
    ** @param _saleMethod SaleItems method of the token
    ** @param _isPostPaid Is the contract post-paid?
    ** @param _isNegotiable Is the contract negotiable?
    ** @param _startDate Date of the sale
    **/
    function txContract(
        uint256 _sid,
        uint256 _tokenId,
        uint256 _contractPrice,
        uint256 _amount,
        // uint8 _resourceClass,
        // uint8 _saleMethod,
        bool _isPostPaid,
        bool _isNegotiable,
        uint256 _startDate
    )
        public payable
    {
        poolSales[msg.sender][_tokenId] += _amount; // necessarily multi tx for the same address of item collection ?
        if ((selling[_sid].amount == 0) && (selling[_sid].amount == 0)) {
            saleItems.push(_sid);
            itemsOnSaleItems[msg.sender].push(_sid);
        }

        selling[_sid] = SaleItems(
            // _sid,
            _tokenId,
            ratingValue * (10**NEFTi20_decimals),
            _amount,
            // ResourceClasses(_resourceClass),
            // SaleMethods(_saleMethod),
            msg.sender,
            // selling[_sid].listDate,
            [ _isPostPaid, _isNegotiable, false, true ],
            // _isPostPaid,
            // _isNegotiable,
            // false,
            // true,
            _startDate,
            [ _contractPrice, 0, 0 ],
            // _contractPrice,
            // 0,
            // 0,
            address(0),
            SaleStatus.OPEN
        );
        sellToken(
            _tokenId,
            _amount,
            (ratingValue.div(ratingScore)) * (10**NEFTi20_decimals),
            2 // _saleMethod
        );
        
        //todo: emit event
    }

    /**
    ** @dev Offering a contract (rent/promise)
    ** @param _sid SaleItems ID
    ** @param _amount Amount of tokens to sale
    ** @param _price Price note for the contract
    ** @param _dates [startDate, endDate]
    **/
    function txContractOffering(
        uint256 _sid,
        uint256 _amount,
        uint256 _price,
        uint256[2] memory _dates
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for rent!");
        require (selling[_sid].amount >= _amount, "Not enough tokens for rent!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance == 0, "Not enough BNB to spend for Gas fee!");
        
        // require (selling[_sid].isContract, "Rent class require time range to apply!");
        require (selling[_sid].states[3], "Rent class require time range to apply!");
        require (block.timestamp <= _dates[0], "Invalid starting time less than current time!");
        require (_dates[0] <= _dates[1], "Invalid end time less than starting time!");

        // require (selling[_sid].isNegotiable, "This item is not for negotiation!"); 
        require (selling[_sid].states[1], "This item is not for negotiation!"); 
        require (
            (_price * _amount) <= NEFTi20.balanceOf(msg.sender),
            "Not enough NFT token to make an offering!"
        );

        // uint256 txFee = ( _price * _amount ).mul(rentNegotiateFee).div(staticPercent);
        // uint256 subTotal = ( _price * _amount ).add(txFee);
        
        // transfer NFT20 negotiation price to pool
        // NEFTi20.safeTransferFrom(
        //     msg.sender,
        //     address(this),
        //     subTotal
        // );
        // transfer NFT20 fee to owner
        // NEFTi20.safeTransferFrom(
        //     msg.sender,
        //     owner(),
        //     txFee
        // );

        // negotiators count for current _sid
        if (poolNegotiating[_sid][msg.sender].value == 0) {
            negotiators[_sid].push(msg.sender);
        }

        uint256 prevPrice = poolNegotiating[_sid][msg.sender].value.div( poolNegotiating[_sid][msg.sender].amount );
        uint256 totalAmount = poolNegotiating[_sid][msg.sender].amount.add( _amount );
        poolNegotiating[_sid][msg.sender] = Negotiating(
            _sid,
            msg.sender,
            ( prevPrice.add(_price) * totalAmount ),
            totalAmount,
            block.timestamp,
            NegotiateStatus.OPEN
        );
        
        //todo: emit event
    }

    /**
    ** @dev Negotiate a contract (rent/promise)
    ** @param _sid SaleItems ID
    ** @param _pid
    ** @param _negotiator
    **/
    function txAcceptContract(
        uint256 _sid,
        uint256 _pid,
        address _negotiator
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for contract anymore!");
        require (
            (selling[_sid].amount > 0) &&
            (poolSales[msg.sender][selling[_sid].tokenId] > 0) &&
            (selling[_sid].amount >= poolNegotiating[_sid][_negotiator].amount),
            "Not enough tokens at pool for sale!"
        );
        require (poolNegotiating[_sid][_negotiator].status == NegotiateStatus.OPEN, "This negotiation is not available anymore!");
        require (poolNegotiating[_sid][_negotiator].value > 0, "Current negotiation price was not set!");
        require (poolNegotiating[_sid][_negotiator].amount > 0, "Current negotiation amount was not set!");
        
        purchasing[_pid] = PurchaseItems(
            _pid,
            _sid,
            selling[_sid].tokenId,
            ratingValue * (10**NEFTi20_decimals),
            poolNegotiating[_sid][_negotiator].amount,
            // selling[_sid].resourceClass,
            // selling[_sid].saleMethod,
            selling[_sid].seller,
            // selling[_sid].listDate,
            [ true, true, false, false ],
            // true,
            // true,
            // false,
            // false,
            block.timestamp,
            [ poolNegotiating[_sid][_negotiator].value, 0, 0 ],
            // poolNegotiating[_sid][_negotiator].value,
            // 0,
            // 0,
            _negotiator,
            PurchaseStatus.INPROGRESS
        );
        
        uint256 updateAmount = selling[_sid].amount.sub(1);
        poolSales[msg.sender][selling[_sid].tokenId] = updateAmount;
        selling[_sid].amount = updateAmount;
        
        poolNegotiating[_sid][_negotiator].status = NegotiateStatus.FULFILLED;
        
        //todo: emit event
    }

    /**
    ** @dev Buyer do finalize the contract
    ** @param _sid SaleItems ID
    ** @param _pid
    ** @param _ratingScore
    **/
    function txFinalizeContract(
        uint256 _sid,
        uint256 _pid,
        uint8 _ratingScore
    )
        public
    {
        require (selling[_sid].status == SaleStatus.OPEN, "Item is not for contract anymore!");
        require (
            (selling[_sid].amount > 0) &&
            (poolSales[msg.sender][selling[_sid].tokenId] > 0),
            "Not enough tokens at pool for sale!"
        );
        require (poolNegotiating[_sid][msg.sender].status == NegotiateStatus.FULFILLED, "This negotiation is not exists or in progress!");
        require (purchasing[_pid].status == PurchaseStatus.INPROGRESS, "This purchase is not exists in progress!");
        // require (purchasing[_pid].valContract > 0, "Current contract value was not set!");
        require (purchasing[_pid].values[1] > 0, "Current contract value was not set!");
        require (purchasing[_pid].amount > 0, "Current purchase amount was not set!");
        
        uint256 txRating = (ratingValue.div(ratingScore)).mul(_ratingScore);
        
        // transfer NFT20 purchased value to seller - fee
        NEFTi20.safeTransferFrom(
            address(this),
            selling[_sid].seller,
            txRating
        );
        // transfer NFT1155 asset to buyer
        NEFTiMT.safeTransferFrom(
            address(this),
            msg.sender,
            purchasing[_pid].tokenId,
            purchasing[_pid].amount,
            ""
        );

        purchasing[_pid].buyer = msg.sender;
        purchasing[_pid].status = PurchaseStatus.FULFILLED;
        
        uint256 updateAmount = selling[_sid].amount.sub(1);
        poolSales[msg.sender][selling[_sid].tokenId] = updateAmount;
        selling[_sid].amount = updateAmount;

        if (selling[_sid].amount == 0) {
            selling[_sid].status = SaleStatus.FULFILLED;
        }
        
        //todo: emit event
    }

    constructor(address _NEFTi20, address _NEFTiMT) {
        NEFTi20 = IERC20(_NEFTi20);
        NEFTiMT = INEFTiMultiTokens(_NEFTiMT);
    }

    // WARNING: There are no handler in fallback function,
    //          If there are any incoming value directly to Smart Contract address
    //          consider apply as generous donation. And Thank you!
    receive () external payable /* nonReentrant */ {}
    fallback () external payable /* nonReentrant */ {}
}