// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDadaCollectible {
    function transfer(
        address to,
        uint256 drawingId,
        uint256 printIndex
    ) external returns (bool success);

    function DrawingPrintToAddress(uint256 print)
        external
        returns (address _address);

    function buyCollectible(uint256 drawingId, uint256 printIndex)
        external
        payable;

    function OfferedForSale(uint256)
        external
        returns (
            bool isForSale,
            uint256 drawingId,
            uint256 printIndex,
            address seller,
            uint256 minValue,
            address onlySellTo,
            uint256 lastSellValue
        );
}

interface IWeth {
    function balanceOf(address) external returns (uint256);

    function allowance(address, address) external returns (uint256);

    function withdraw(uint256 wad) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// TODO ownable just to make sure ETH can't get stuck here?

/// @title DadaMarketplaceHelper - Universal bids contract for Dada Marketplace
/// @dev seller must create sell offer of their collectible on Dada contract that can be filled by this contract
/// @author Isaac Patka
contract DadaMarketplaceHelper {
    // Dada ERC20 address
    IDadaCollectible public dadaContract;

    // Weth contract
    IWeth public weth;

    // Bid data structures
    struct Bid {
        address bidder;
        uint256 drawingId;
        uint256 value;
        uint256 quantity;
    }

    uint256 public bidCounter;
    mapping(uint256 => Bid) public bids;

    event BidEntered(
        uint256 bidId,
        uint256 indexed drawingID,
        uint256 value,
        uint256 quantity,
        address indexed bidder
    );
    event BidWithdrawn(uint256 bidId);
    event BidAccepted(uint256 bidId);

    /// @dev constructor sets the interfaces to external contracts
    /// @param _dadaCollectibleAddress ERC20 DadaCollectible contract
    /// @param _wethAddress Weth contract
    constructor(address _dadaCollectibleAddress, address _wethAddress) {
        dadaContract = IDadaCollectible(_dadaCollectibleAddress);
        weth = IWeth(_wethAddress);
    }

    /// @dev Place bid allows bidder to offer to buy any print of a drawing at a set price
    /// @param _drawingId Drawing bidder is requesting
    /// @param _value Value in Weth per drawing
    /// @param _quantity How many times this order can be filled - sender must have enough Weth to cover _quantity * _value
    function placeBid(
        uint256 _drawingId,
        uint256 _value,
        uint256 _quantity
    ) public {
        require(
            weth.balanceOf(msg.sender) >= _value * _quantity,
            "Insufficient Balance"
        );
        require(
            weth.allowance(msg.sender, address(this)) >= _value * _quantity,
            "Insufficient Approval"
        );
        require(_quantity > 0, "Quantity must be nonzero");

        bidCounter++;

        bids[bidCounter] = Bid({
            bidder: msg.sender,
            drawingId: _drawingId,
            value: _value,
            quantity: _quantity
        });

        emit BidEntered(bidCounter, _drawingId, _value, _quantity, msg.sender);
    }

    /// @dev Internal helper to unwrap ETH and complete purchase
    /// @param _value Value in Weth
    function unwrapWeth(uint256 _value) internal {
        // Check ETH balance before and after withdraw to make sure unwrap worked as expected
        uint256 ethBefore = address(this).balance;
        weth.withdraw(_value);
        uint256 ethAfter = address(this).balance;
        require(ethAfter - ethBefore == _value, "Unwrap failed");
    }

    /// @dev Accept a bid by the seller or buyer
    /// @param _bidId Bid to fill
    /// @param _printId Print to use to fill order
    function acceptBid(uint256 _bidId, uint256 _printId) public {
        Bid storage bid = bids[_bidId];
        require(bid.quantity > 0, "Invalid Bid");

        // Bid must be accepted by seller
        address seller = dadaContract.DrawingPrintToAddress(_printId);
        require(msg.sender == seller, "Bid must be accepter by seller");

        require(
            weth.balanceOf(bid.bidder) >= bid.value,
            "Insufficient Balance"
        );
        require(
            weth.allowance(bid.bidder, address(this)) >= bid.value,
            "Insufficient Approval"
        );

        // This contract must be able to buy
        (
            bool isForSale,
            uint256 drawingId,
            ,
            ,
            uint256 minValue,
            address onlySellTo,

        ) = dadaContract.OfferedForSale(_printId);

        require(isForSale, "Invalid offer");
        require(drawingId == bid.drawingId, "Drawing does not match bid");

        require(
            onlySellTo == address(this) || onlySellTo == address(0),
            "Contract not authorized to buy"
        );

        require(bid.value >= minValue, "Bid too low");

        // Mark this bid as fulfilled
        bid.quantity--;

        // Accept WETH from bidder
        require(
            weth.transferFrom(bid.bidder, address(this), bid.value),
            "WETH transfer failed"
        );

        // Unwrap transferred WETH to pay seller
        unwrapWeth(bid.value);

        // Buy drawing from seller
        dadaContract.buyCollectible{value: bid.value}(bid.drawingId, _printId);

        // Send drawing to buyer
        dadaContract.transfer(bid.bidder, bid.drawingId, _printId);

        emit BidAccepted(_bidId);
    }

    /// @dev Public helper to accept multiple bids at once
    /// @param _bids Bid IDs to fill
    /// @param _printIds Prints to use to fill orders
    function acceptBids(uint256[] memory _bids, uint256[] memory _printIds)
        public
    {
        require(_bids.length == _printIds.length, "!length");
        for (uint256 index = 0; index < _bids.length; index++) {
            acceptBid(_bids[index], _printIds[index]);
        }
    }

    /// @dev Bidder can withdraw their bid
    /// @param _bidId Bid ID to withdraw
    function withdrawBid(uint256 _bidId) public {
        Bid memory bid = bids[_bidId];
        require(bid.bidder == msg.sender);
        require(bid.quantity > 0, "Invalid bid");
        delete bids[_bidId];
        emit BidWithdrawn(_bidId);
    }

    // Allow this contract to receive ETH from WETH unwrapping
    receive() external payable {}
}

