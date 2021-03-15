/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.5.17;


contract CryptoPunks {

    // You can use this hash to verify the image file containing all the punks
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'CryptoPunks';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextPunkIndexToAssign = 0;

    //bool public allPunksAssigned = false;
    uint public punksRemainingToAssign = 0;
    uint public numberOfPunksToReserve;
    uint public numberOfPunksReserved = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping (uint => address) public punkIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public punksOfferedForSale;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000;                        // Update total supply
        punksRemainingToAssign = totalSupply;
        numberOfPunksToReserve = 1000;
        name = "CRYPTOPUNKS";                                   // Set the name for display purposes
        symbol = "Ͼ";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

    function reservePunksForOwner(uint maxForThisRun) public {
        if (msg.sender != owner) revert();
        if (numberOfPunksReserved >= numberOfPunksToReserve) revert();
        uint numberPunksReservedThisRun = 0;
        while (numberOfPunksReserved < numberOfPunksToReserve && numberPunksReservedThisRun < maxForThisRun) {
            punkIndexToAddress[nextPunkIndexToAssign] = msg.sender;
            emit Assign(msg.sender, nextPunkIndexToAssign);
            numberPunksReservedThisRun++;
            nextPunkIndexToAssign++;
        }
        punksRemainingToAssign -= numberPunksReservedThisRun;
        numberOfPunksReserved += numberPunksReservedThisRun;
        balanceOf[msg.sender] += numberPunksReservedThisRun;
    }

    function getPunk(uint punkIndex) public {
        if (punksRemainingToAssign == 0) revert();
        if (punkIndexToAddress[punkIndex] != address(0x0)) revert();
        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;
        emit Assign(msg.sender, punkIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) external {
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);
    }

    function punkNoLongerForSale(uint punkIndex) public {
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0x0));
        emit PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) public {
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0x0));
        emit PunkOffered(punkIndex, minSalePriceInWei, address(0x0));
    }

    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) public {
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint punkIndex) external payable {
        Offer memory offer = punksOfferedForSale[punkIndex];
        if (!offer.isForSale) revert();                // punk not actually for sale
        if (offer.onlySellTo != address(0x0) && offer.onlySellTo != msg.sender) revert();  // punk not supposed to be sold to this user
        if (msg.value < offer.minValue) revert();   // Didn't send enough ETH
        if (offer.seller != punkIndexToAddress[punkIndex]) revert(); // Seller no longer owner of punk

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[offer.seller]--;
        balanceOf[msg.sender]++;
        emit Transfer(offer.seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[offer.seller] += msg.value;
        emit PunkBought(punkIndex, msg.value, offer.seller, msg.sender);
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}