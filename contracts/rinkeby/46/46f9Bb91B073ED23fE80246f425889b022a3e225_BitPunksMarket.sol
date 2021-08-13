/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.4.8;
contract BitPunksMarket {

    // You can use this hash to verify the image file containing all the bitpunk pixels
    string public imageHash = "63676155d589a35431d152fb15fb893cc2aca67fb729aa14ff20955be44eba21";
    address public OriginalCryptoPunksOwner = "0x6C22fa46Cb7FABd775bb0c4E13948e75Aa458a60";

    address owner;

    string public standard = 'BitPunks';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextPixelIndexToAssign = 0;

    bool public allPixelsAssigned = false;
    uint public pixelsRemainingToAssign = 0;

    //mapping (address => uint) public addressToPixelIndex;
    mapping (uint => address) public pixelIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint pixelIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint pixelIndex;
        address bidder;
        uint value;
    }

    // A record of pixels that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public pixelsOfferedForSale;

    // A record of the highest pixel bid
    mapping (uint => Bid) public pixelBids;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 pixelIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PixelTransfer(address indexed from, address indexed to, uint256 pixelIndex);
    event PixelOffered(uint indexed pixelIndex, uint minValue, address indexed toAddress);
    event PixelBidEntered(uint indexed pixelIndex, uint value, address indexed fromAddress);
    event PixelBidWithdrawn(uint indexed pixelIndex, uint value, address indexed fromAddress);
    event PixelBought(uint indexed pixelIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PixelNoLongerForSale(uint indexed pixelIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function BitPunksMarket() payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 844;                        // Update total supply
        pixelsRemainingToAssign = totalSupply;
        name = "BITPUNKS";                                   // Set the name for display purposes
        symbol = "Ḅ";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint pixelIndex) {
        if (msg.sender != owner) throw;
        if (allPixelsAssigned) throw;
        if (pixelIndex >= 844) throw;
        if (pixelIndexToAddress[pixelIndex] != to) {
            if (pixelIndexToAddress[pixelIndex] != 0x0) {
                balanceOf[pixelIndexToAddress[pixelIndex]]--;
            } else {
                pixelsRemainingToAssign--;
            }
            pixelIndexToAddress[pixelIndex] = to;
            balanceOf[to]++;
            Assign(to, pixelIndex);
        }
    }

    function setInitialOwners(address[] addresses, uint[] indices) {
        if (msg.sender != owner) throw;
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) throw;
        allPixelsAssigned = true;
    }

    function getPixel(uint pixelIndex) {
        if (!allPixelsAssigned) throw;
        if (pixelsRemainingToAssign == 0) throw;
        if (pixelIndexToAddress[pixelIndex] != 0x0) throw;
        if (pixelIndex >= 844) throw;
        pixelIndexToAddress[pixelIndex] = msg.sender;
        balanceOf[msg.sender]++;
        pixelsRemainingToAssign--;
        Assign(msg.sender, pixelIndex);
    }

    // Transfer ownership of a pixel to another user without requiring payment
    function transferPixel(address to, uint pixelIndex) {
        if (!allPixelsAssigned) throw;
        if (pixelIndexToAddress[pixelIndex] != msg.sender) throw;
        if (pixelIndex >= 844) throw;
        if (pixelsOfferedForSale[pixelIndex].isForSale) {
            pixelNoLongerForSale(pixelIndex);
        }
        pixelIndexToAddress[pixelIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        PixelTransfer(msg.sender, to, pixelIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = pixelBids[pixelIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            pixelBids[pixelIndex] = Bid(false, pixelIndex, 0x0, 0);
        }
    }

    function pixelNoLongerForSale(uint pixelIndex) {
        if (!allPixelsAssigned) throw;
        if (pixelIndexToAddress[pixelIndex] != msg.sender) throw;
        if (pixelIndex >= 844) throw;
        pixelsOfferedForSale[pixelIndex] = Offer(false, pixelIndex, msg.sender, 0, 0x0);
        PixelNoLongerForSale(pixelIndex);
    }

    function offerPixelForSale(uint pixelIndex, uint minSalePriceInWei) {
        if (!allPixelsAssigned) throw;
        if (pixelIndexToAddress[pixelIndex] != msg.sender) throw;
        if (pixelIndex >= 844) throw;
        pixelsOfferedForSale[pixelIndex] = Offer(true, pixelIndex, msg.sender, minSalePriceInWei, 0x0);
        PixelOffered(pixelIndex, minSalePriceInWei, 0x0);
    }

    function offerPixelForSaleToAddress(uint pixelIndex, uint minSalePriceInWei, address toAddress) {
        if (!allPixelsAssigned) throw;
        if (pixelIndexToAddress[pixelIndex] != msg.sender) throw;
        if (pixelIndex >= 844) throw;
        pixelsOfferedForSale[pixelIndex] = Offer(true, pixelIndex, msg.sender, minSalePriceInWei, toAddress);
        PixelOffered(pixelIndex, minSalePriceInWei, toAddress);
    }

    function buyPixel(uint pixelIndex) payable {
        if (!allPixelsAssigned) throw;
        Offer offer = pixelsOfferedForSale[pixelIndex];
        if (pixelIndex >= 844) throw;
        if (!offer.isForSale) throw;                // pixel not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;  // pixel not supposed to be sold to this user
        if (msg.value < offer.minValue) throw;      // Didn't send enough ETH
        if (offer.seller != pixelIndexToAddress[pixelIndex]) throw; // Seller no longer owner of pixel

        address seller = offer.seller;

        pixelIndexToAddress[pixelIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        pixelNoLongerForSale(pixelIndex);
        pendingWithdrawals[seller] += msg.value;
        PixelBought(pixelIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = pixelBids[pixelIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            pixelBids[pixelIndex] = Bid(false, pixelIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allPixelsAssigned) throw;
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPixel(uint pixelIndex) payable {
        if (pixelIndex >= 844) throw;
        if (!allPixelsAssigned) throw;
        if (pixelIndexToAddress[pixelIndex] == 0x0) throw;
        if (pixelIndexToAddress[pixelIndex] == msg.sender) throw;
        if (msg.value == 0) throw;
        Bid existing = pixelBids[pixelIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        pixelBids[pixelIndex] = Bid(true, pixelIndex, msg.sender, msg.value);
        PixelBidEntered(pixelIndex, msg.value, msg.sender);
    }

    function acceptBidForPixel(uint pixelIndex, uint minPrice) {
        if (pixelIndex >= 844) throw;
        if (!allPixelsAssigned) throw;
        if (pixelIndexToAddress[pixelIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = pixelBids[pixelIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        pixelIndexToAddress[pixelIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        pixelsOfferedForSale[pixelIndex] = Offer(false, pixelIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        pixelBids[pixelIndex] = Bid(false, pixelIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        PixelBought(pixelIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPixel(uint pixelIndex) {
        if (pixelIndex >= 844) throw;
        if (!allPixelsAssigned) throw;
        if (pixelIndexToAddress[pixelIndex] == 0x0) throw;
        if (pixelIndexToAddress[pixelIndex] == msg.sender) throw;
        Bid bid = pixelBids[pixelIndex];
        if (bid.bidder != msg.sender) throw;
        PixelBidWithdrawn(pixelIndex, bid.value, msg.sender);
        uint amount = bid.value;
        pixelBids[pixelIndex] = Bid(false, pixelIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}