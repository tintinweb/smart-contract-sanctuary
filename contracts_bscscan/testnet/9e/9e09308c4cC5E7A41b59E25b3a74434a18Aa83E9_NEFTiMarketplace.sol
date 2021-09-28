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
import "./NEFTiMPStorages.sol";

// abstract contract IERC20Ext is IERC20 {
//     function decimals() public virtual view returns (uint8);
// }

contract NEFTiMarketplace is NEFTiMPStorages, Ownable {
    using SafeMath for uint256;
    // using SafeERC20 for IERC20Ext;
    using SafeERC20 for IERC20;

    // mapping (address => uint256) internal txNonce;

    // bool internal feeCalcMechanism = false;
    // StaticFee internal staticFee = StaticFee(
    //     /* BNB+NFT */   [6, 0, 2],
    //     /* BNB     */   [8, 0, 0],
    //     /* B20+NFT */   [0, 6, 2],
    //     /* B20     */   [0, 8, 0],
    //     /* NFT     */   [0, 0, 8]
    // );

    IERC20 internal NEFTi20;
    uint256 internal NEFTi20_decimals = 16;

    INEFTiMultiTokens internal NEFTiMT;

    // INEFTiMPFeeCalcExt internal NEFTiMPFeeCalcExt = INEFTiMPFeeCalcExt(c__NEFTiMPFeeCalcExtension);

    uint256 internal ratingValue = 100 * (10**NEFTi20_decimals);
    uint8 internal ratingScore = 10;
    
    // struct SaleFees {
    //     uint8 directListingFee;                  // FREE
    //     uint8 directNegotiateFee;                // FREE
    //     uint8 directNegotiateCancellationFee;    // 0.5% x Negotiate Price
    //     uint8 directCancellationFee;             // FREE
    //     uint8 directTxFee;                       // 0.8% x Item Price
    // }

    // SaleFees internal saleFees = SaleFees(
    //     0,
    //     0,
    //     5,
    //     0,
    //     8
    // );

    uint8 internal directListingFee = 0;                  // FREE
    uint8 internal directNegotiateFee = 0;                // FREE
    uint8 internal directNegotiateCancellationFee = 5;    // 0.5% x Negotiate Price
    uint8 internal directCancellationFee = 0;             // FREE
    uint8 internal directTxFee = 8;                       // 0.8% x Item Price

    uint8 internal auctionListingFee = 3;                 // 0.3% x Item Price
    uint8 internal auctionListingCancellationFee = 5;     // 0.5% x Item Price
    uint8 internal auctionBiddingFee = 1;                 // 0.1% x Bid Price
    uint8 internal auctionBiddingCancellationFee = 5;     // 0.5% x Bid Price
    uint8 internal auctionTxFee = 8;                      // 0.8% x Item Price

    uint8 internal contractListingFee = 3;                // 0.3% x Item Price
    uint8 internal contractListingCancellationFee = 5;    // 0.5% x Item Price
    uint8 internal contractNegotiateFee = 1;              // 0.1% x Negotiate Price
    uint8 internal contractTxFee = 8;                     // 0.8% x Item Price
    
    uint256 constant staticPercent = 1000;

    // event Logger(address _log);

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
        uint256[2] saleDate,
        uint8 status
    );

    event Negotiate(
        uint256 indexed saleId,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address indexed negotiator,
        uint256 negoDate,
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
        uint256 indexed purchaseId,
        uint256 indexed saleId,
        uint256 indexed tokenId,
        uint256 price,
        uint256 amount,
        uint8 saleMethod,
        address seller,
        bool[4] states,
        uint8 status
    );
    
    
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
    function sellToken(uint256 _id, uint256 _amount, uint256 _price, SaleMethods _saleMethod)
        internal
    {
        uint256 listingFee = (
            SaleMethods(_saleMethod) == SaleMethods.DIRECT
            // _saleMethod == 0
            ?   0   // directListingFee * (10**NEFTi20_decimals)
            :   (
                SaleMethods(_saleMethod) == SaleMethods.AUCTION
                // _saleMethod == 1
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
        // bool _isContract,
        uint256[2] memory _saleDate
    )
        public
    {
        require(_saleMethod <= 3, "Unknown Sale Method!");
        require(_saleDate[0] >= block.timestamp, "Time for sale is behind current time!");
        require(NEFTiMT.balanceOf(msg.sender, _tokenId) > 0, "Not enough current token id balance for listing!");
        require(_amount > 0, "Zero amount is not applicable for listing!");

        _poolSales[msg.sender][_tokenId] += _amount; // necessarily multi tx for the same address of item collection ?
        if ((_selling[_sid].amount == 0) && (_selling[_sid].amount == 0)) {
            _saleItems.push(_sid);
            _itemsOnSaleItems[msg.sender].push(_sid);
        }

        uint256[3] memory values = [
            !_states[3]         // isContract
                ? uint(0)
                : _price,
            uint(0),
            uint(0)
        ];
        _selling[_sid] = SaleItems(
            _tokenId,
            (
                !_states[3]     // isContract
                ? _price
                : ratingValue * (10**NEFTi20_decimals)
            ),
            _amount,
            // SaleMethods(_saleMethod),
            msg.sender,
            [
                _states[0],
                _states[1],
                _states[2],
                _states[3]
            ],
                // _isPostPaid,
                // _isNegotiable,
                // _isAuction,
                // _isContract,
            _saleDate,
            values,
                // 0,
                // 0,
                // 0,
            address(0),
            SaleStatus.OPEN
        );

        sellToken(
            _tokenId,
            _amount,
            (
                !_states[3]
                    ? _price
                    : (ratingValue.div(ratingScore)) * (10**NEFTi20_decimals)
            ),
            SaleMethods(_saleMethod)
        );
        
        emit Sale(
            _sid,
            _tokenId,
            (
                !_states[3]
                    ? _price
                    : (ratingValue.div(ratingScore)) * (10**NEFTi20_decimals)
            ),
            _amount,
            _saleMethod,
            msg.sender,
            [ _states[0], _states[1], _states[2], false ],
            _saleDate,
            uint8(SaleStatus.OPEN)
        );
    }


    ///////////////////////////////////////////////////////////////////////////
    // SALE UTILITIES
    ///////////////////////////////////////////////////////////////////////////

    /**
    ** @dev Get items SaleItems ID
    ** @return Array of SaleItems IDs (uint256)
    **/
    // function getSaleItems()
    //     public view
    //     returns (uint256[] memory saleIds)
    // {
    //     // uint256 skipper = 0;
    //     // uint256[] memory ids;
    //     // for (uint256 i=0; i < _saleItems.length; i++) {
    //     //     if (
    //     //         (_selling[_saleItems[i]].status == SaleStatus.OPEN) ||
    //     //         (_selling[_saleItems[i]].status == SaleStatus.RENTING)
    //     //     ) {
    //     //         // ids[i-skipper] = _saleItems[i];
    //     //         ids[i-skipper] = _saleItems[i];
    //     //     } else {
    //     //         skipper++;
    //     //     }
    //     // }
    //     // return ids;

    //     return _saleItems;
    // }
    /**
    ** @dev Get item information by SaleItems ID
    ** @param _sid SaleItems ID
    ** @return Item information (SaleItems)
    **/
    function getSaleItemsInfo(uint256 _sid)
        public view
        returns (
            uint256[3] memory info,
                // uint256 tokenId,
                // uint256 price,
                // uint256 amount,

            // uint8 saleMethod,
            address seller,

            bool[4] memory states,
                // bool isPostPaid,
                // bool isNegotiable,
                // bool isAuction,
                // bool isContract,

            uint256[2] memory saleDate,

            uint256[3] memory values,
                // uint256 valContract,
                // uint256 highBid,
                // uint256 bidMultiplier,

            address buyer,
            uint8 status
        )
    {
        return (
            [
                _selling[_sid].tokenId,
                _selling[_sid].price,
                _selling[_sid].amount
            ],
            // uint8(_selling[_sid].saleMethod),
            _selling[_sid].seller,
            _selling[_sid].states,
                // _selling[_sid].isPostPaid,
                // _selling[_sid].isNegotiable,
                // _selling[_sid].isAuction,
                // _selling[_sid].isContract,
            _selling[_sid].saleDate,
            _selling[_sid].values,
                // _selling[_sid].valContract,
                // _selling[_sid].highBid,
                // _selling[_sid].bidMultiplier,
            _selling[_sid].buyer,
            uint8(_selling[_sid].status)
        );
    }
    /**
    ** @dev Get sale item amount by seller address and token ID
    ** @param _sid SaleItems ID
    ** @param _tokenId Token ID of the NEFTiMultiToken
    ** @return Amount
    **/
    function balanceOf(address _seller, uint256 _tokenId)
        public view
        returns (uint256)
    { return (_poolSales[_seller][_tokenId]); }
    /**
    ** @dev Get sale items by seller address
    ** @param _seller Address of the seller
    ** @return Array of SaleItems IDs (bytes32)
    **/
    function itemsOf(address _seller)
        public view
        returns (uint256[] memory items)
    { return _itemsOnSaleItems[_seller]; }

    function cancelNegotiation(uint256 _sid, address _negotiator)
        public
    {
        bool isNegotiator = false;
        bool isSeller = (msg.sender == _selling[_sid].seller);
        address negotiator = address(0);
        NegotiateStatus cancelStatus;

        if (isSeller || msg.sender == owner()) {
            cancelStatus = NegotiateStatus.REJECTED;
            negotiator = _negotiator;
        } else {
            for (uint256 i=0; _negotiators[_sid].length > i; i++) {
                if (_negotiators[_sid][i] == msg.sender) {
                    isNegotiator = true;
                    negotiator = msg.sender;
                    break;
                }
            }
            require(isNegotiator, "Only seller or negotiator can cancel the negotiation!");
            cancelStatus = NegotiateStatus.CANCELED;
        }
        
        if (isSeller && cancelStatus == NegotiateStatus.CANCELED) {
            uint256 cancellationFee = (_poolNegotiating[_sid][msg.sender].value.mul( directNegotiateCancellationFee )).div( staticPercent );
            require(NEFTi20.balanceOf(msg.sender) >= cancellationFee, "Not enough current token balance for cancellation!");
            NEFTi20.safeTransferFrom(
                msg.sender,
                owner(),
                cancellationFee
            );
        }

        for (uint256 i=0; _negotiators[_sid].length > i; i++) {
            if (_negotiators[_sid][i] == negotiator) {
                NEFTi20.safeTransferFrom(
                    address(this),
                    _negotiators[_sid][i],   // negotiator
                    _poolNegotiating[_sid][negotiator].value
                );
                _poolNegotiating[_sid][negotiator].status = cancelStatus;

                _negotiators[_sid][i] = _negotiators[_sid][_negotiators[_sid].length-1];
                delete _negotiators[_sid][_negotiators[_sid].length-1];
            }
        }

        emit NegotiationCanceled(_sid, negotiator);
    }

    function cancelAuctionBid(uint256 _sid, address _bidder)
        public
    {
        bool isBidder = false;
        bool isSeller = (msg.sender == _selling[_sid].seller);
        address bidder = address(0);

        if (isSeller || msg.sender == owner()) {
            bidder = _bidder;
        } else {
            for (uint256 i=0; _bidders[_sid].length > i; i++) {
                if (_bidders[_sid][i] == msg.sender) {
                    isBidder = true;
                    bidder = msg.sender;
                    break;
                }
            }
            require(isBidder, "Only seller or bidder can cancel the negotiation!");
        }
        
        if (isSeller) {
            uint256 cancellationFee = (_poolBidding[_sid][msg.sender].mul(auctionListingCancellationFee)).div( staticPercent );
            require(NEFTi20.balanceOf(msg.sender) >= cancellationFee, "Not enough current token balance for cancellation!");
            NEFTi20.safeTransferFrom(
                msg.sender,
                owner(),
                cancellationFee
            );
        }

        for (uint256 i=0; _negotiators[_sid].length > i; i++) {
            if (_bidders[_sid][i] == bidder) {
                NEFTi20.safeTransferFrom(
                    address(this),
                    _bidders[_sid][i],   // bidder
                    _poolBidding[_sid][bidder]
                );
                _poolBidding[_sid][bidder] = 0;

                _bidders[_sid][i] = _bidders[_sid][_bidders[_sid].length-1];
                delete _bidders[_sid][_bidders[_sid].length-1];
            }
        }

        emit BidCanceled(_sid, bidder);
    }

    function getListingCancellationFee(uint256 _sid)
        public view
        returns (uint256)
    {
        require(_sid > 0, "Unknown Sale ID");
        require(_selling[_sid].status == SaleStatus.OPEN, "Only open sale can be canceled!");

        uint256 fee = (
            (!_selling[_sid].states[2] && !_selling[_sid].states[3])
            ?   (
                directCancellationFee > 0
                    ? ((_selling[_sid].price * _selling[_sid].amount).mul( directCancellationFee )).div( staticPercent )
                    : 0
            )
            :   (
                (_selling[_sid].states[2] && !_selling[_sid].states[3])
                    ?   (
                        auctionListingCancellationFee > 0
                            ? ((_selling[_sid].price * _selling[_sid].amount).mul(auctionListingCancellationFee)).div( staticPercent )
                            : 0
                    )
                    :   (
                        contractListingCancellationFee > 0
                            ? ((_selling[_sid].price * _selling[_sid].amount).mul(contractListingCancellationFee)).div( staticPercent )
                            : 0
                    )
            )
        );
        return fee;
    }

    function cancelSaleItem(uint256 _sid)
        public
    {
        require(_sid > 0, "Unknown Sale ID");
        address seller = _selling[_sid].seller;
        require(msg.sender == seller || msg.sender == owner(), "Only seller can cancel the sale!");
        require(_selling[_sid].status == SaleStatus.OPEN, "Only open sale can be canceled!");
        require(msg.sender.balance > 0, "Cancellation cost gas fee");

        NEFTiMT.safeTransferFrom(
            address(this),
            _selling[_sid].seller,
            _selling[_sid].tokenId,
            _selling[_sid].amount,
            ""
        );

        // when it's Auction
        if (_selling[_sid].states[2]) {
            if (_bidders[_sid].length > 0) {
                for (uint256 i=0; i < _bidders[_sid].length; i++) {
                    if (_bidders[_sid][0] != address(0)) {
                        cancelAuctionBid(_sid, _bidders[_sid][0]);   
                    }
                }
            }
        }
        // when it's Direct Sale or Contract
        else if (
            !_selling[_sid].states[2] ||
            _selling[_sid].states[3]
        ) {
            if (_negotiators[_sid].length > 0) {
                for (uint256 i=0; i < _negotiators[_sid].length; i++) {
                    if (_negotiators[_sid][0] != address(0)) {
                        cancelNegotiation(_sid, _negotiators[_sid][0]);   
                    }
                }
            }
        }

        if (_itemsOnSaleItems[seller].length > 0) {
            for (uint256 i=0; i < _itemsOnSaleItems[seller].length; i++) {
                if (_itemsOnSaleItems[seller][0] != _sid) {
                    _itemsOnSaleItems[seller][i] = _itemsOnSaleItems[seller][_itemsOnSaleItems[seller].length-1];
                    delete _itemsOnSaleItems[seller][_itemsOnSaleItems[seller].length-1];
                }
            }
        }

        _poolSales[seller][_selling[_sid].tokenId] -= _selling[_sid].amount;
        _selling[_sid].buyer = address(0);
        _selling[_sid].status = SaleStatus.CANCELED;

        emit CancelSale(
            _sid,
            _selling[_sid].tokenId,
            seller,
            uint8(SaleStatus.CANCELED)
        );
    }

    function getNegotiators(uint256 _sid) 
        public view
        returns (address[] memory)
    {
        require(_sid > 0, "Unknown Sale ID");
        return _negotiators[_sid];
    }

    function getNegotiationInfo(uint256 _sid, address _negotiator) 
        public view
        returns (
            uint256 saleId,
            uint256 value,
            uint256 amount,
            uint256 negoDate,
            uint8 status
        )
    {
        require(_sid > 0, "Unknown Sale ID");
        require(_negotiator != address(0), "Unknown Negotiator");
        return (
            _poolNegotiating[_sid][_negotiator].saleHash,
            _poolNegotiating[_sid][_negotiator].value,
            _poolNegotiating[_sid][_negotiator].amount,
            _poolNegotiating[_sid][_negotiator].negoDate,
            uint8(_poolNegotiating[_sid][_negotiator].status)
        );
    }

    function getAuctionBidders(uint256 _sid) 
        public view
        returns (address[] memory)
    {
        require(_sid > 0, "Unknown Sale ID");
        return _bidders[_sid];
    }

    function getBidValue(uint256 _sid, address _bidder) 
        public view
        returns (uint256)
    {
        require(_sid > 0, "Unknown Sale ID");
        require(_bidder != address(0), "Unknown Bidder");
        return _poolBidding[_sid][_bidder];
    }

    function getHighestBidValue(uint256 _sid)
        public view
        returns (address bidder, uint256 bid)
    { return ( _selling[_sid].buyer, _selling[_sid].values[1] ); }
    

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
        require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for sale!");
        require (_selling[_sid].saleDate[0] <= block.timestamp, "Item is not yet for sale!");
        require (_selling[_sid].amount >= _amount, "Not enough tokens for sale!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance > 0, "Not enough BNB to spend for Gas fee!");
        
        uint256 subTotal = _selling[_sid].price * _amount;
        uint256 txFee = ( subTotal.mul( directTxFee ) ).div( staticPercent );

        require (NEFTi20.balanceOf(msg.sender) >= subTotal, "Not enough NFT balance for purchase!");

        // transfer NFT20 purchase value to seller
        NEFTi20.safeTransferFrom(
            msg.sender,
            _selling[_sid].seller,
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
            _selling[_sid].tokenId,
            _amount,
            ""
        );

        // uint256[3] memory values = [ uint(0), uint(0), uint(0) ];
        // _purchasing[_pid] = PurchaseItems(
        //     _pid,
        //     _sid,
        //     _selling[_sid].tokenId,
        //     _selling[_sid].price,
        //     _selling[_sid].amount,
        //     // _selling[_sid].resourceClass,
        //     // _selling[_sid].saleMethod,
        //     _selling[_sid].seller,
        //     // _selling[_sid].listDate,
        //     [ false, false, false, false ],
        //     block.timestamp,
        //     values,
        //     // 0,
        //     // 0,
        //     // 0,
        //     msg.sender,
        //     PurchaseStatus.FULFILLED
        // );

        _poolSales[ _selling[_sid].seller ][ _selling[_sid].tokenId ] = _selling[_sid].amount.sub(_amount);

        _selling[_sid].amount = _selling[_sid].amount.sub(_amount);
        
        if (_selling[_sid].amount == 0) {
            _selling[_sid].status = SaleStatus.FULFILLED;
        }
        
        emit Purchase(
            _pid,
            _sid,
            _selling[_sid].tokenId,
            _selling[_sid].price,
            _selling[_sid].amount,
            1,
            _selling[_sid].seller,
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
        require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for sale!");
        require (_selling[_sid].saleDate[0] <= block.timestamp, "Item is not yet for sale!");
        require (_selling[_sid].amount >= _amount, "Not enough tokens for sale!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance > 0, "Not enough BNB to spend for Gas fee!");

        require (_selling[_sid].states[1], "This item is not for negotiation!"); 
        // require (_selling[_sid].isNegotiable, "This item is not for negotiation!"); 
        require (
            (_price * _amount) < NEFTi20.balanceOf(msg.sender),
            "Not enough NFT token to trade!"
        );
        require (
            _price < _selling[_sid].price,
            "negotiate value is too low!"
        );

        uint256 txFee = ( _price * _amount ).mul(contractNegotiateFee).div(staticPercent);
        uint256 subTotal = ( _price * _amount ).sub(txFee);
        
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

        if (_poolNegotiating[_sid][msg.sender].value == 0) {
            _negotiators[_sid].push(msg.sender);
        }

        uint256 prevPrice = (
            _poolNegotiating[_sid][msg.sender].amount == 0
                ? 0
                : _poolNegotiating[_sid][msg.sender].value.div( _poolNegotiating[_sid][msg.sender].amount )
        );
        uint256 totalAmount = _poolNegotiating[_sid][msg.sender].amount.add( _amount );
        
        _poolNegotiating[_sid][msg.sender] = Negotiating(
            _sid,
            msg.sender,
            ( prevPrice.add(_price) * totalAmount ),
            totalAmount,
            block.timestamp,
            NegotiateStatus.OPEN
        );

        //todo: emit event
        emit Negotiate(
            _sid,
            _selling[_sid].tokenId,
            _amount,
            _price,
            msg.sender,
            block.timestamp,
            uint8(NegotiateStatus.OPEN)
        );
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
        require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for sale anymore!");
        require (
            (_selling[_sid].amount > 0) &&
            (_poolSales[msg.sender][_selling[_sid].tokenId] > 0) &&
            (_selling[_sid].amount >= _poolNegotiating[_sid][_negotiator].amount),
            "Not enough tokens at pool for sale!"
        );
        require (_poolNegotiating[_sid][_negotiator].status == NegotiateStatus.OPEN, "This negotiation is not available anymore!");
        require (_poolNegotiating[_sid][_negotiator].value > 0, "Current negotiation price was not set!");
        require (_poolNegotiating[_sid][_negotiator].amount > 0, "Current negotiation amount was not set!");
        
        uint256 txFee = (_poolNegotiating[_sid][_negotiator].value.mul( directTxFee )).div(staticPercent);
        uint256 subTotal = _poolNegotiating[_sid][_negotiator].value.sub(txFee);
        
        // transfer NFT20 purchased value to seller - fee
        NEFTi20.safeTransfer(
            // address(this),
            _selling[_sid].seller,
            subTotal
        );
        // transfer NFT20 fee to owner
        NEFTi20.safeTransfer(
            // address(this),
            owner(),
            txFee
        );
        // transfer NFT1155 asset to buyer
        NEFTiMT.safeTransferFrom(
            address(this),
            _negotiator,
            _selling[_sid].tokenId,
            _poolNegotiating[_sid][_negotiator].amount,
            ""
        );

        // uint256[3] memory values = [ uint(0), uint(0), uint(0) ];
        // _purchasing[_pid] = PurchaseItems(
        //     _pid,
        //     _sid,
        //     _selling[_sid].tokenId,
        //     _poolNegotiating[_sid][_negotiator].value,
        //     _poolNegotiating[_sid][_negotiator].value,
        //     // _selling[_sid].saleMethod,
        //     _selling[_sid].seller,
        //     [ false, true, false, false ],
        //         // false,
        //         // true,
        //         // false,
        //         // false,
        //     block.timestamp,
        //     values,
        //         // 0,
        //         // 0,
        //         // 0,
        //     _negotiator,
        //     PurchaseStatus.FULFILLED
        // );
        
        uint256 updateAmount = _selling[_sid].amount.sub(1);
        _poolSales[msg.sender][_selling[_sid].tokenId] = updateAmount;
        _selling[_sid].amount = updateAmount;

        if (_selling[_sid].amount == 0) {
            _selling[_sid].status = SaleStatus.FULFILLED;
        }
        
        _poolNegotiating[_sid][_negotiator].status = NegotiateStatus.FULFILLED;
        
        emit Purchase(
            _pid,
            _sid,
            _selling[_sid].tokenId,
            _selling[_sid].price,
            _selling[_sid].amount,
            1,
            _selling[_sid].seller,
            [ false, false, false, false ],
            uint8(PurchaseStatus.FULFILLED)
        );
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
        require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for auction!");
        require (_selling[_sid].saleDate[0] <= block.timestamp, "Item is not yet for sale!");
        require (_selling[_sid].amount >= 1, "Not enough token for auction!");
        require (_price < NEFTi20.balanceOf(msg.sender), "Not enough NFT token to bid in auction!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance > 0, "Not enough BNB to spend for Gas fee!");

        // when Auction
        // if (_selling[_sid].isAuction) {
        if (_selling[_sid].states[2]) {
            // require (_price >= _selling[_sid].bidMultiplier, "Bid value less than required multiplier!");
            require (_price >= _selling[_sid].values[2], "Bid value less than required multiplier!");

            uint256 _updatePrice = _poolBidding[_sid][msg.sender].add(_price);
            // require (_selling[_sid].highBid >= _updatePrice, "Price is too lower than highest bid!");
            require (_selling[_sid].values[1] >= _updatePrice, "Price is too lower than highest bid!");

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

            if (_poolBidding[_sid][msg.sender] == 0) {
                _bidders[_sid].push(msg.sender);
            }

            // if exist and higher than the highest bid, update to auction bidding pool
            _poolBidding[_sid][msg.sender] = _updatePrice;

            // update highest bidder price and address
            // _selling[_sid].highBid = _updatePrice;
            _selling[_sid].values[1] = _updatePrice;
            _selling[_sid].buyer = msg.sender;
            
            _poolBidding[_sid][msg.sender] = _updatePrice;

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
        uint256 _sid
        // uint256 _pid
    )
        public
    {
        require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for auction anymore!");
        require (
            (_selling[_sid].amount > 0) &&
            (_poolSales[msg.sender][_selling[_sid].tokenId] > 0),
            "Not enough tokens at pool for sale!"
        );
        
        require (
            (_selling[_sid].buyer != address(0)) ||
            (_selling[_sid].buyer != address(0x0)),
            "Current bidder address was not set!"
        );
        require (_poolBidding[_sid][_selling[_sid].buyer] > 0, "Current bid price was not set!");
        // require (_selling[_sid].highBid > 0, "Highest bid value was not set!");
        require (_selling[_sid].values[1] > 0, "Highest bid value was not set!");
        
        // uint256 txFee = (_selling[_sid].highBid.mul(auctionTxFee)).div(staticPercent);
        uint256 txFee = (_selling[_sid].values[1].mul(auctionTxFee)).div(staticPercent);
        // uint256 subTotal = _selling[_sid].highBid.add(txFee);
        uint256 subTotal = _selling[_sid].values[1].add(txFee);
        
        // transfer NFT20 purchased value to seller - fee
        NEFTi20.safeTransferFrom(
            address(this),
            _selling[_sid].seller,
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
            _selling[_sid].buyer,
            _selling[_sid].tokenId,
            _selling[_sid].amount,
            ""
        );

        // _purchasing[_pid] = PurchaseItems(
        //     _pid,
        //     _sid,
        //     _selling[_sid].tokenId,
        //     // _selling[_sid].highBid,
        //     _selling[_sid].values[1],
        //     _selling[_sid].amount,
        //     // _selling[_sid].resourceClass,
        //     // _selling[_sid].saleMethod,
        //     _selling[_sid].seller,
        //     // _selling[_sid].saleDate,
        //     [ false, false, true, false ],
        //     // false,
        //     // false,
        //     // true,
        //     // false,
        //     block.timestamp,
        //     [ 0, _selling[_sid].values[1], _selling[_sid].values[2] ],
        //     // 0
        //     // _selling[_sid].highBid,
        //     // _selling[_sid].bidMultiplier,
        //     _selling[_sid].buyer,
        //     PurchaseStatus.FULFILLED
        // );
        
        uint256 updateAmount = _selling[_sid].amount.sub(1);
        _poolSales[msg.sender][_selling[_sid].tokenId] = updateAmount;
        _selling[_sid].amount = updateAmount;

        if (_selling[_sid].amount == 0) {
            _selling[_sid].status = SaleStatus.FULFILLED;
        }
        
        _poolBidding[_sid][_selling[_sid].buyer] = 0;
        
        //todo: emit event
    }


    ///////////////////////////////////////////////////////////////////////////
    // CONTRACT OFFERING
    ///////////////////////////////////////////////////////////////////////////

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
        require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for rent!");
        require (_selling[_sid].amount >= _amount, "Not enough tokens for rent!");

        // check BNB if less than gas fee ?
        require (address(msg.sender).balance > 0, "Not enough BNB to spend for Gas fee!");
        
        // require (_selling[_sid].isContract, "Rent class require time range to apply!");
        require (_selling[_sid].states[3], "Rent class require time range to apply!");
        require (block.timestamp <= _dates[0], "Invalid starting time less than current time!");
        require (_dates[0] <= _dates[1], "Invalid end time less than starting time!");

        // require (_selling[_sid].isNegotiable, "This item is not for negotiation!"); 
        require (_selling[_sid].states[1], "This item is not for negotiation!"); 
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

        // _negotiators count for current _sid
        if (_poolNegotiating[_sid][msg.sender].value == 0) {
            _negotiators[_sid].push(msg.sender);
        }

        uint256 prevPrice = _poolNegotiating[_sid][msg.sender].value.div( _poolNegotiating[_sid][msg.sender].amount );
        uint256 totalAmount = _poolNegotiating[_sid][msg.sender].amount.add( _amount );
        _poolNegotiating[_sid][msg.sender] = Negotiating(
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
        // uint256 _pid,
        address _negotiator
    )
        public
    {
        require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for contract anymore!");
        require (
            (_selling[_sid].amount > 0) &&
            (_poolSales[msg.sender][_selling[_sid].tokenId] > 0) &&
            (_selling[_sid].amount >= _poolNegotiating[_sid][_negotiator].amount),
            "Not enough tokens at pool for sale!"
        );
        require (_poolNegotiating[_sid][_negotiator].status == NegotiateStatus.OPEN, "This negotiation is not available anymore!");
        require (_poolNegotiating[_sid][_negotiator].value > 0, "Current negotiation price was not set!");
        require (_poolNegotiating[_sid][_negotiator].amount > 0, "Current negotiation amount was not set!");
        
        // _purchasing[_pid] = PurchaseItems(
        //     _pid,
        //     _sid,
        //     _selling[_sid].tokenId,
        //     ratingValue * (10**NEFTi20_decimals),
        //     _poolNegotiating[_sid][_negotiator].amount,
        //     // _selling[_sid].resourceClass,
        //     // _selling[_sid].saleMethod,
        //     _selling[_sid].seller,
        //     // _selling[_sid].listDate,
        //     [ true, true, false, false ],
        //     // true,
        //     // true,
        //     // false,
        //     // false,
        //     block.timestamp,
        //     [ _poolNegotiating[_sid][_negotiator].value, 0, 0 ],
        //     // _poolNegotiating[_sid][_negotiator].value,
        //     // 0,
        //     // 0,
        //     _negotiator,
        //     PurchaseStatus.INPROGRESS
        // );
        
        uint256 updateAmount = _selling[_sid].amount.sub(1);
        _poolSales[msg.sender][_selling[_sid].tokenId] = updateAmount;
        _selling[_sid].amount = updateAmount;
        
        _poolNegotiating[_sid][_negotiator].status = NegotiateStatus.FULFILLED;
        
        //todo: emit event
    }

    /**
    ** @dev Buyer do finalize the contract
    ** @param _sid SaleItems ID
    ** @param _pid
    ** @param _ratingScore
    **/
    // function txFinalizeContract(
    //     uint256 _sid,
    //     uint256 _pid,
    //     uint8 _ratingScore
    // )
    //     public
    // {
    //     require (_selling[_sid].status == SaleStatus.OPEN, "Item is not for contract anymore!");
    //     require (
    //         (_selling[_sid].amount > 0) &&
    //         (_poolSales[msg.sender][_selling[_sid].tokenId] > 0),
    //         "Not enough tokens at pool for sale!"
    //     );
    //     require (_poolNegotiating[_sid][msg.sender].status == NegotiateStatus.FULFILLED, "This negotiation is not exists or in progress!");
    //     require (_purchasing[_pid].status == PurchaseStatus.INPROGRESS, "This purchase is not exists in progress!");
    //         // require (_purchasing[_pid].valContract > 0, "Current contract value was not set!");
    //     require (_purchasing[_pid].values[1] > 0, "Current contract value was not set!");
    //     require (_purchasing[_pid].amount > 0, "Current purchase amount was not set!");
        
    //     uint256 txRating = (ratingValue.div(ratingScore)).mul(_ratingScore);
        
    //     // transfer NFT20 purchased value to seller - fee
    //     NEFTi20.safeTransferFrom(
    //         address(this),
    //         _selling[_sid].seller,
    //         txRating
    //     );
    //     // transfer NFT1155 asset to buyer
    //     NEFTiMT.safeTransferFrom(
    //         address(this),
    //         msg.sender,
    //         _purchasing[_pid].tokenId,
    //         _purchasing[_pid].amount,
    //         ""
    //     );

    //     // _purchasing[_pid].buyer = msg.sender;
    //     // _purchasing[_pid].status = PurchaseStatus.FULFILLED;
        
    //     uint256 updateAmount = _selling[_sid].amount.sub(1);
    //     _poolSales[msg.sender][_selling[_sid].tokenId] = updateAmount;
    //     _selling[_sid].amount = updateAmount;

    //     if (_selling[_sid].amount == 0) {
    //         _selling[_sid].status = SaleStatus.FULFILLED;
    //     }
        
    //     //todo: emit event
    // }


    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
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