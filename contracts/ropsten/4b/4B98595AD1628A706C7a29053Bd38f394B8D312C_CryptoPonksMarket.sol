/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.4.8;
contract CryptoPonksMarket {

    // You can use this hash to verify the image file containing all the ponks
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'CryptoPonks';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextPonkIndexToAssign = 0;

    bool public allPonksAssigned = false;
    uint public ponksRemainingToAssign = 0;

    //mapping (address => uint) public addressToPonkIndex;
    mapping (uint => address) public ponkIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint ponkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint ponkIndex;
        address bidder;
        uint value;
    }

    // A record of ponks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public ponksOfferedForSale;

    // A record of the highest ponk bid
    mapping (uint => Bid) public ponkBids;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 ponkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PonkTransfer(address indexed from, address indexed to, uint256 ponkIndex);
    event PonkOffered(uint indexed ponkIndex, uint minValue, address indexed toAddress);
    event PonkBidEntered(uint indexed ponkIndex, uint value, address indexed fromAddress);
    event PonkBidWithdrawn(uint indexed ponkIndex, uint value, address indexed fromAddress);
    event PonkBought(uint indexed ponkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PonkNoLongerForSale(uint indexed ponkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoPonksMarket() payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000;                        // Update total supply
        ponksRemainingToAssign = totalSupply;
        name = "CRYPTOPONKS";                                   // Set the name for display purposes
        symbol = "Ͼ";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint ponkIndex) {
        if (msg.sender != owner) throw;
        if (allPonksAssigned) throw;
        if (ponkIndex >= 10000) throw;
        if (ponkIndexToAddress[ponkIndex] != to) {
            if (ponkIndexToAddress[ponkIndex] != 0x0) {
                balanceOf[ponkIndexToAddress[ponkIndex]]--;
            } else {
                ponksRemainingToAssign--;
            }
            ponkIndexToAddress[ponkIndex] = to;
            balanceOf[to]++;
            Assign(to, ponkIndex);
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
        allPonksAssigned = true;
    }

    function getPonk(uint ponkIndex) {
        if (!allPonksAssigned) throw;
        if (ponksRemainingToAssign == 0) throw;
        if (ponkIndexToAddress[ponkIndex] != 0x0) throw;
        if (ponkIndex >= 10000) throw;
        ponkIndexToAddress[ponkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        ponksRemainingToAssign--;
        Assign(msg.sender, ponkIndex);
    }

    // Transfer ownership of a ponk to another user without requiring payment
    function transferPonk(address to, uint ponkIndex) {
        if (!allPonksAssigned) throw;
        if (ponkIndexToAddress[ponkIndex] != msg.sender) throw;
        if (ponkIndex >= 10000) throw;
        if (ponksOfferedForSale[ponkIndex].isForSale) {
            ponkNoLongerForSale(ponkIndex);
        }
        ponkIndexToAddress[ponkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        PonkTransfer(msg.sender, to, ponkIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = ponkBids[ponkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            ponkBids[ponkIndex] = Bid(false, ponkIndex, 0x0, 0);
        }
    }

    function ponkNoLongerForSale(uint ponkIndex) {
        if (!allPonksAssigned) throw;
        if (ponkIndexToAddress[ponkIndex] != msg.sender) throw;
        if (ponkIndex >= 10000) throw;
        ponksOfferedForSale[ponkIndex] = Offer(false, ponkIndex, msg.sender, 0, 0x0);
        PonkNoLongerForSale(ponkIndex);
    }

    function offerPonkForSale(uint ponkIndex, uint minSalePriceInWei) {
        if (!allPonksAssigned) throw;
        if (ponkIndexToAddress[ponkIndex] != msg.sender) throw;
        if (ponkIndex >= 10000) throw;
        ponksOfferedForSale[ponkIndex] = Offer(true, ponkIndex, msg.sender, minSalePriceInWei, 0x0);
        PonkOffered(ponkIndex, minSalePriceInWei, 0x0);
    }

    function offerPonkForSaleToAddress(uint ponkIndex, uint minSalePriceInWei, address toAddress) {
        if (!allPonksAssigned) throw;
        if (ponkIndexToAddress[ponkIndex] != msg.sender) throw;
        if (ponkIndex >= 10000) throw;
        ponksOfferedForSale[ponkIndex] = Offer(true, ponkIndex, msg.sender, minSalePriceInWei, toAddress);
        PonkOffered(ponkIndex, minSalePriceInWei, toAddress);
    }

    function buyPonk(uint ponkIndex) payable {
        if (!allPonksAssigned) throw;
        Offer offer = ponksOfferedForSale[ponkIndex];
        if (ponkIndex >= 10000) throw;
        if (!offer.isForSale) throw;                // ponk not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;  // ponk not supposed to be sold to this user
        if (msg.value < offer.minValue) throw;      // Didn't send enough ETH
        if (offer.seller != ponkIndexToAddress[ponkIndex]) throw; // Seller no longer owner of ponk

        address seller = offer.seller;

        ponkIndexToAddress[ponkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        ponkNoLongerForSale(ponkIndex);
        pendingWithdrawals[seller] += msg.value;
        PonkBought(ponkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = ponkBids[ponkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            ponkBids[ponkIndex] = Bid(false, ponkIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allPonksAssigned) throw;
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPonk(uint ponkIndex) payable {
        if (ponkIndex >= 10000) throw;
        if (!allPonksAssigned) throw;                
        if (ponkIndexToAddress[ponkIndex] == 0x0) throw;
        if (ponkIndexToAddress[ponkIndex] == msg.sender) throw;
        if (msg.value == 0) throw;
        Bid existing = ponkBids[ponkIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        ponkBids[ponkIndex] = Bid(true, ponkIndex, msg.sender, msg.value);
        PonkBidEntered(ponkIndex, msg.value, msg.sender);
    }

    function acceptBidForPonk(uint ponkIndex, uint minPrice) {
        if (ponkIndex >= 10000) throw;
        if (!allPonksAssigned) throw;                
        if (ponkIndexToAddress[ponkIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = ponkBids[ponkIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        ponkIndexToAddress[ponkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        ponksOfferedForSale[ponkIndex] = Offer(false, ponkIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        ponkBids[ponkIndex] = Bid(false, ponkIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        PonkBought(ponkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPonk(uint ponkIndex) {
        if (ponkIndex >= 10000) throw;
        if (!allPonksAssigned) throw;                
        if (ponkIndexToAddress[ponkIndex] == 0x0) throw;
        if (ponkIndexToAddress[ponkIndex] == msg.sender) throw;
        Bid bid = ponkBids[ponkIndex];
        if (bid.bidder != msg.sender) throw;
        PonkBidWithdrawn(ponkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        ponkBids[ponkIndex] = Bid(false, ponkIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}