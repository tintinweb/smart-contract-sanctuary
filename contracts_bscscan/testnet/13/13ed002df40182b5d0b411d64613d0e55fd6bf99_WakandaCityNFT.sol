/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

/**
 *Submitted for verification at Etherscan.io on 2017-07-19
*/

pragma solidity ^0.4.8;
contract WakandaCityNFT  {

    // You can use this hash to verify the image file containing all the punks
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'Wakanda Arts';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextWakandaIndexToAssign = 0;

    bool public allWakandaAssigned = false;
    uint public WakandaRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping (uint => address) public WakandaIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint WakandaIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint WakandaIndex;
        address bidder;
        uint value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public WakandaOfferedForSale;

    // A record of the highest punk bid
    mapping (uint => Bid) public WakandaBids;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 WakandaIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event WakandaTransfer(address indexed from, address indexed to, uint256 WakandaIndex);
    event WakandaOffered(uint indexed WakandaIndex, uint minValue, address indexed toAddress);
    event WakandaBidEntered(uint indexed WakandaIndex, uint value, address indexed fromAddress);
    event WakandaBidWithdrawn(uint indexed WakandaIndex, uint value, address indexed fromAddress);
    event WakandaBought(uint indexed WakandaIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event WakandaNoLongerForSale(uint indexed WakandaIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function WakandaCityNFT () payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000;                        // Update total supply
        WakandaRemainingToAssign = totalSupply;
        name = "Wakanda Arts";                                   // Set the name for display purposes
        symbol = "WART";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint WakandaIndex) {
        if (msg.sender != owner) throw;
        if (allWakandaAssigned) throw;
        if (WakandaIndex >= 10000) throw;
        if (WakandaIndexToAddress[WakandaIndex] != to) {
            if (WakandaIndexToAddress[WakandaIndex] != 0x0) {
                balanceOf[WakandaIndexToAddress[WakandaIndex]]--;
            } else {
                WakandaRemainingToAssign--;
            }
            WakandaIndexToAddress[WakandaIndex] = to;
            balanceOf[to]++;
            Assign(to, WakandaIndex);
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
        allWakandaAssigned = true;
    }

    function getWakanda(uint WakandaIndex) {
        if (!allWakandaAssigned) throw;
        if (WakandaRemainingToAssign == 0) throw;
        if (WakandaIndexToAddress[WakandaIndex] != 0x0) throw;
        if (WakandaIndex >= 10000) throw;
        WakandaIndexToAddress[WakandaIndex] = msg.sender;
        balanceOf[msg.sender]++;
        WakandaRemainingToAssign--;
        Assign(msg.sender, WakandaIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferWakanda (address to, uint WakandaIndex) {
        if (!allWakandaAssigned) throw;
        if (WakandaIndexToAddress[WakandaIndex] != msg.sender) throw;
        if (WakandaIndex >= 10000) throw;
        if (WakandaOfferedForSale[WakandaIndex].isForSale) {
            WakandaNoLongerForSale(WakandaIndex);
        }
        WakandaIndexToAddress[WakandaIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        WakandaTransfer(msg.sender, to, WakandaIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = WakandaBids[WakandaIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            WakandaBids[WakandaIndex] = Bid(false, WakandaIndex, 0x0, 0);
        }
    }

 

    function offerWakandaForSale(uint WakandaIndex, uint minSalePriceInWei) {
        if (!allWakandaAssigned) throw;
        if (WakandaIndexToAddress[WakandaIndex] != msg.sender) throw;
        if (WakandaIndex >= 10000) throw;
        WakandaOfferedForSale[WakandaIndex] = Offer(true, WakandaIndex, msg.sender, minSalePriceInWei, 0x0);
        WakandaOffered(WakandaIndex, minSalePriceInWei, 0x0);
    }

    function offerWakandaForSaleToAddress(uint WakandaIndex, uint minSalePriceInWei, address toAddress) {
        if (!allWakandaAssigned) throw;
        if (WakandaIndexToAddress[WakandaIndex] != msg.sender) throw;
        if (WakandaIndex >= 10000) throw;
        WakandaOfferedForSale[WakandaIndex] = Offer(true, WakandaIndex, msg.sender, minSalePriceInWei, toAddress);
        WakandaOffered(WakandaIndex, minSalePriceInWei, toAddress);
    }

    function buyWakanda (uint WakandaIndex) payable {
        if (!allWakandaAssigned) throw;
        Offer offer = WakandaOfferedForSale[WakandaIndex];
        if (WakandaIndex >= 10000) throw;
        if (!offer.isForSale) throw;                // punk not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;  // punk not supposed to be sold to this user
        if (msg.value < offer.minValue) throw;      // Didn't send enough ETH
        if (offer.seller != WakandaIndexToAddress[WakandaIndex]) throw; // Seller no longer owner of punk

        address seller = offer.seller;

        WakandaIndexToAddress[WakandaIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        WakandaNoLongerForSale(WakandaIndex);
        pendingWithdrawals[seller] += msg.value;
        WakandaBought(WakandaIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = WakandaBids[WakandaIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            WakandaBids[WakandaIndex] = Bid(false, WakandaIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allWakandaAssigned) throw;
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForWakanda (uint WakandaIndex) payable {
        if (WakandaIndex >= 10000) throw;
        if (!allWakandaAssigned) throw;                
        if (WakandaIndexToAddress[WakandaIndex] == 0x0) throw;
        if (WakandaIndexToAddress[WakandaIndex] == msg.sender) throw;
        if (msg.value == 0) throw;
        Bid existing = WakandaBids[WakandaIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        WakandaBids[WakandaIndex] = Bid(true, WakandaIndex, msg.sender, msg.value);
        WakandaBidEntered(WakandaIndex, msg.value, msg.sender);
    }

    function acceptBidForWakanda (uint WakandaIndex, uint minPrice) {
        if (WakandaIndex >= 10000) throw;
        if (!allWakandaAssigned) throw;                
        if (WakandaIndexToAddress[WakandaIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = WakandaBids[WakandaIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        WakandaIndexToAddress[WakandaIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        WakandaOfferedForSale[WakandaIndex] = Offer(false, WakandaIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        WakandaBids[WakandaIndex] = Bid(false, WakandaIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        WakandaBought(WakandaIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForWakanda (uint WakandaIndex) {
        if (WakandaIndex >= 10000) throw;
        if (!allWakandaAssigned) throw;                
        if (WakandaIndexToAddress[WakandaIndex] == 0x0) throw;
        if (WakandaIndexToAddress[WakandaIndex] == msg.sender) throw;
        Bid bid = WakandaBids[WakandaIndex];
        if (bid.bidder != msg.sender) throw;
        WakandaBidWithdrawn(WakandaIndex, bid.value, msg.sender);
        uint amount = bid.value;
        WakandaBids[WakandaIndex] = Bid(false, WakandaIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}