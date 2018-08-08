pragma solidity ^0.4.8;

//import "./ConvertLib.sol";

contract CryptoStars {

    address owner;
    string public standard = "STRZ";     
    string public name;                     
    string public symbol;  
    uint8 public decimals;                         //Zero for this type of token
    uint256 public totalSupply;                    //Total Supply of STRZ tokens 
    uint256 public initialPrice;                  //Price to buy an offered star for sale
    uint256 public transferPrice;                 //Minimum price to transfer star to another address
    uint256 public MaxStarIndexAvailable;         //Set a maximum for range of offered stars for sale
    uint256 public MinStarIndexAvailable;        //Set a minimum for range of offered stars for sale
    uint public nextStarIndexToAssign = 0;
    uint public starsRemainingToAssign = 0;
    uint public numberOfStarsToReserve;
    uint public numberOfStarsReserved = 0;

    mapping (uint => address) public starIndexToAddress;    
    mapping (uint => string) public starIndexToSTRZName;        //Allowed to be set or changed by STRZ token owner
    mapping (uint => string) public starIndexToSTRZMasterName;  //Only allowed to be set or changed by contract owner

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint starIndex;
        address seller;
        uint minValue;          // In Wei
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint starIndex;
        address bidder;        
        uint value;              //In Wei
    }

    

    // A record of stars that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public starsOfferedForSale;

    // A record of the highest star bid
    mapping (uint => Bid) public starBids;

    // Accounts may have credit that can be withdrawn.   Credit can be from withdrawn bids or losing bids.
    // Credits also occur when STRZ tokens are sold.   
    mapping (address => uint) public pendingWithdrawals;


    event Assign(address indexed to, uint256 starIndex, string GivenName, string MasterName);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event StarTransfer(address indexed from, address indexed to, uint256 starIndex);
    event StarOffered(uint indexed starIndex, uint minValue, address indexed fromAddress, address indexed toAddress);
    event StarBidEntered(uint indexed starIndex, uint value, address indexed fromAddress);
    event StarBidWithdrawn(uint indexed starIndex, uint value, address indexed fromAddress);
    event StarBidAccepted(uint indexed starIndex, uint value, address indexed fromAddress);
    event StarBought(uint indexed starIndex, uint value, address indexed fromAddress, address indexed toAddress, string GivenName, string MasterName, uint MinStarAvailable, uint MaxStarAvailable);
    event StarNoLongerForSale(uint indexed starIndex);
    event StarMinMax(uint MinStarAvailable, uint MaxStarAvailable, uint256 Price);
    event NewOwner(uint indexed starIndex, address indexed toAddress);

   
    function CryptoStars() payable {
        
        owner = msg.sender;
        totalSupply = 119614;                        // Update total supply
        starsRemainingToAssign = totalSupply;
        numberOfStarsToReserve = 1000;
        name = "CRYPTOSTARS";                        // Set the name for display purposes
        symbol = "STRZ";                             // Set the symbol for display purposes
        decimals = 0;                                // Amount of decimals for display purposes
        initialPrice = 99000000000000000;          // Initial price when tokens are first sold 0.099 ETH
        transferPrice = 10000000000000000;          //Set min transfer price to 0.01 ETH
        MinStarIndexAvailable = 11500;               //Min Available Star Index for range of current offer group                                           
        MaxStarIndexAvailable = 12000;               //Max Available Star Index for range of current offer group

        //Sol - 0
        starIndexToSTRZMasterName[0] = "Sol";
        starIndexToAddress[0] = owner;
        Assign(owner, 0, starIndexToSTRZName[0], starIndexToSTRZMasterName[0]);

        //Odyssey 2001
        starIndexToSTRZMasterName[2001] = "Odyssey";
        starIndexToAddress[2001] = owner;
        Assign(owner, 2001, starIndexToSTRZName[2001], starIndexToSTRZMasterName[2001]);

        //Delta Velorum - 119006
        starIndexToSTRZMasterName[119006] = "Delta Velorum";
        starIndexToAddress[119006] = owner;
        Assign(owner, 119006, starIndexToSTRZName[119006], starIndexToSTRZMasterName[119006]);

        //Gamma Camelopardalis - 119088
        starIndexToSTRZMasterName[119088] = "Gamma Camelopardalis";
        starIndexToAddress[119088] = owner;
        Assign(owner, 119088, starIndexToSTRZName[119088], starIndexToSTRZMasterName[119088]);

        //Capella - 119514
        starIndexToSTRZMasterName[119514] = "Capella";
        starIndexToAddress[119514] = owner;
        Assign(owner, 119514, starIndexToSTRZName[119514], starIndexToSTRZMasterName[119514]);

    }


    function reserveStarsForOwner(uint maxForThisRun) {              //Assign groups of stars to the owner
        if (msg.sender != owner) throw;
        if (numberOfStarsReserved >= numberOfStarsToReserve) throw;
        uint numberStarsReservedThisRun = 0;
        while (numberOfStarsReserved < numberOfStarsToReserve && numberStarsReservedThisRun < maxForThisRun) {
            starIndexToAddress[nextStarIndexToAssign] = msg.sender;
            Assign(msg.sender, nextStarIndexToAssign,starIndexToSTRZName[nextStarIndexToAssign], starIndexToSTRZMasterName[nextStarIndexToAssign]);
            numberStarsReservedThisRun++;
            nextStarIndexToAssign++;
        }
        starsRemainingToAssign -= numberStarsReservedThisRun;
        numberOfStarsReserved += numberStarsReservedThisRun;
        balanceOf[msg.sender] += numberStarsReservedThisRun;
    }

    function setGivenName(uint starIndex, string name) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;     //Only allow star owner to change GivenName
        starIndexToSTRZName[starIndex] = name;
        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);  //Update Info
    }

    function setMasterName(uint starIndex, string name) {
        if (msg.sender != owner) throw;                             //Only allow contract owner to change MasterName
        if (starIndexToAddress[starIndex] != owner) throw;          //Only allow contract owner to change MasterName if they are owner of the star
       
        starIndexToSTRZMasterName[starIndex] = name;
        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);  //Update Info
    }

    function getMinMax(){
        StarMinMax(MinStarIndexAvailable,MaxStarIndexAvailable, initialPrice);
    }

    function setMinMax(uint256 MaxStarIndexHolder, uint256 MinStarIndexHolder) {
        if (msg.sender != owner) throw;
        MaxStarIndexAvailable = MaxStarIndexHolder;
        MinStarIndexAvailable = MinStarIndexHolder;
        StarMinMax(MinStarIndexAvailable,MaxStarIndexAvailable, initialPrice);
    }

    function setStarInitialPrice(uint256 initialPriceHolder) {
        if (msg.sender != owner) throw;
        initialPrice = initialPriceHolder;
        StarMinMax(MinStarIndexAvailable,MaxStarIndexAvailable, initialPrice);
    }

    function setTransferPrice(uint256 transferPriceHolder){
        if (msg.sender != owner) throw;
        transferPrice = transferPriceHolder;
    }

    function getStar(uint starIndex, string strSTRZName, string strSTRZMasterName) {
        if (msg.sender != owner) throw;
       
        if (starIndexToAddress[starIndex] != 0x0) throw;

        starIndexToSTRZName[starIndex] = strSTRZName;
        starIndexToSTRZMasterName[starIndex] = strSTRZMasterName;

        starIndexToAddress[starIndex] = msg.sender;
    
        balanceOf[msg.sender]++;
        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
    }

    
    function transferStar(address to, uint starIndex) payable {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        if (msg.value < transferPrice) throw;                       // Didn&#39;t send enough ETH

        starIndexToAddress[starIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        StarTransfer(msg.sender, to, starIndex);
        Assign(to, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
        pendingWithdrawals[owner] += msg.value;
        //kill any bids and refund bid
        Bid bid = starBids[starIndex];
        if (bid.hasBid) {
            pendingWithdrawals[bid.bidder] += bid.value;
            starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
            StarBidWithdrawn(starIndex, bid.value, to);
        }
        
        //Remove any offers
        Offer offer = starsOfferedForSale[starIndex];
        if (offer.isForSale) {
             starsOfferedForSale[starIndex] = Offer(false, starIndex, msg.sender, 0, 0x0);
        }

    }

    function starNoLongerForSale(uint starIndex) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        starsOfferedForSale[starIndex] = Offer(false, starIndex, msg.sender, 0, 0x0);
        StarNoLongerForSale(starIndex);
        Bid bid = starBids[starIndex];
        if (bid.bidder == msg.sender ) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
            StarBidWithdrawn(starIndex, bid.value, msg.sender);
        }
    }

    function offerStarForSale(uint starIndex, uint minSalePriceInWei) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        starsOfferedForSale[starIndex] = Offer(true, starIndex, msg.sender, minSalePriceInWei, 0x0);
        StarOffered(starIndex, minSalePriceInWei, msg.sender, 0x0);
    }

    function offerStarForSaleToAddress(uint starIndex, uint minSalePriceInWei, address toAddress) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        starsOfferedForSale[starIndex] = Offer(true, starIndex, msg.sender, minSalePriceInWei, toAddress);
        StarOffered(starIndex, minSalePriceInWei, msg.sender, toAddress);
    }

    //New owner buys a star that has been offered
    function buyStar(uint starIndex) payable {
        Offer offer = starsOfferedForSale[starIndex];
        if (!offer.isForSale) throw;                                            // star not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;   // star not supposed to be sold to this user
        if (msg.value < offer.minValue) throw;                                  // Didn&#39;t send enough ETH
        if (offer.seller != starIndexToAddress[starIndex]) throw;               // Seller no longer owner of star

        address seller = offer.seller;
        
        balanceOf[seller]--;
        balanceOf[msg.sender]++;

        Assign(msg.sender, starIndex,starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);

        uint amountseller = msg.value*97/100;
        uint amountowner = msg.value*3/100;           //Owner of contract receives 3% registration fee

        pendingWithdrawals[owner] += amountowner;    
        pendingWithdrawals[seller] += amountseller;

        starIndexToAddress[starIndex] = msg.sender;
 
        starNoLongerForSale(starIndex);
    
        string STRZName = starIndexToSTRZName[starIndex];
        string STRZMasterName = starIndexToSTRZMasterName[starIndex];

        StarBought(starIndex, msg.value, offer.seller, msg.sender, STRZName, STRZMasterName, MinStarIndexAvailable, MaxStarIndexAvailable);

        Bid bid = starBids[starIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
            StarBidWithdrawn(starIndex, bid.value, msg.sender);
        }

    }

    function buyStarInitial(uint starIndex, string strSTRZName) payable {
         
    // We only allow the Nextavailable star to be sold 
        if (starIndex > MaxStarIndexAvailable) throw;     //Above Current Offering Range
        if (starIndex < MinStarIndexAvailable) throw;       //Below Current Offering Range
        if (starIndexToAddress[starIndex] != 0x0) throw;    //Star is already owned
        if (msg.value < initialPrice) throw;               // Didn&#39;t send enough ETH
        
        starIndexToAddress[starIndex] = msg.sender;   
        starIndexToSTRZName[starIndex] = strSTRZName;      //Assign the star to new owner
        
        balanceOf[msg.sender]++;                            //Update the STRZ token balance for the new owner
        pendingWithdrawals[owner] += msg.value;

        string STRZMasterName = starIndexToSTRZMasterName[starIndex];
        StarBought(starIndex, msg.value, owner, msg.sender, strSTRZName, STRZMasterName ,MinStarIndexAvailable, MaxStarIndexAvailable);

        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
        //Assign(msg.sender, starIndex);
    }

    function enterBidForStar(uint starIndex) payable {

        if (starIndex >= totalSupply) throw;             
        if (starIndexToAddress[starIndex] == 0x0) throw;
        if (starIndexToAddress[starIndex] == msg.sender) throw;
        if (msg.value == 0) throw;

        Bid existing = starBids[starIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }

        starBids[starIndex] = Bid(true, starIndex, msg.sender, msg.value);
        StarBidEntered(starIndex, msg.value, msg.sender);
    }

    function acceptBidForStar(uint starIndex, uint minPrice) {
        if (starIndex >= totalSupply) throw;
        //if (!allStarsAssigned) throw;                
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = starBids[starIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        starIndexToAddress[starIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        starsOfferedForSale[starIndex] = Offer(false, starIndex, bid.bidder, 0, 0x0);
        
        uint amount = bid.value;
        uint amountseller = amount*97/100;
        uint amountowner = amount*3/100;
        
        pendingWithdrawals[seller] += amountseller;
        pendingWithdrawals[owner] += amountowner;               //Registration Fee 3%

        string STRZGivenName = starIndexToSTRZName[starIndex];
        string STRZMasterName = starIndexToSTRZMasterName[starIndex];
        StarBought(starIndex, bid.value, seller, bid.bidder, STRZGivenName, STRZMasterName, MinStarIndexAvailable, MaxStarIndexAvailable);
        StarBidWithdrawn(starIndex, bid.value, bid.bidder);
        Assign(bid.bidder, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
        StarNoLongerForSale(starIndex);

        starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
    }

    function withdrawBidForStar(uint starIndex) {
        if (starIndex >= totalSupply) throw;            
        if (starIndexToAddress[starIndex] == 0x0) throw;
        if (starIndexToAddress[starIndex] == msg.sender) throw;

        Bid bid = starBids[starIndex];
        if (bid.bidder != msg.sender) throw;
        StarBidWithdrawn(starIndex, bid.value, msg.sender);
        uint amount = bid.value;
        starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
        // Refund the bid money
        pendingWithdrawals[msg.sender] += amount;
    
    }

    function withdraw() {
        //if (!allStarsAssigned) throw;
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.send(amount);
    }

    function withdrawPartial(uint withdrawAmount) {
        //Only available to owner
        //Withdraw partial amount of the pending withdrawal
        if (msg.sender != owner) throw;
        if (withdrawAmount > pendingWithdrawals[msg.sender]) throw;

        pendingWithdrawals[msg.sender] -= withdrawAmount;
        msg.sender.send(withdrawAmount);
    }
}