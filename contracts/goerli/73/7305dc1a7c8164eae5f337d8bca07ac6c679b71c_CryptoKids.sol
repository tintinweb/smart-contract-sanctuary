/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

pragma solidity ^0.8.4;

// This was NFT was made by Arjun Jadeja Pagidipati (Age 10 at the time)
// Go to => https://y.at/{BASKETBALL-EMOJI-HERE}{KING-EMOJI-HERE}{GOAT-EMOJI-HERE}

contract CryptoKids {
    // Make some variables
    uint public nextKidIndexToAssign;
    uint public kidsRemainingToAssign;
    uint8 public decimals;
    uint256 public totalSupply;
    string public standard = 'CryptoKids';
    string public symbol = 'CK';
    string public name = 'CRYPTOKIDS';
    bool public allKidsAssigned = false;
    
    // Create the variable that will store the owner of the contracts (my) address
    address public owner;
    
    // Make a mapping of every kids index to they're owner
    mapping (uint => address) public kidIndexToAddress;
    
    /* Normal balanceOf mapping */
    mapping (address => uint256) public balanceOf;
    
    /* Make a few "structs" */
    struct Bid {
        bool hasBid;
        uint kidIndex;
        uint value;
        address bidder;
    }
    
    struct Offer {
        bool isForSale;
        uint kidIndex;
        uint minValue;
        address seller;
        address onlySellTo;
    }
    
    // A list of kids for sale
    mapping (uint => Offer) public kidsOfferedForSale;
    
    // A list of the kid bids
    mapping (uint => Bid) public kidBids;
    
    mapping (address => uint) public pendingWidthdrawls;
    
    event Assign(address indexed to, uint256 kidIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event KidTransfer(address indexed from, address indexed to, uint256 kidIndex);
    event KidOffered(uint indexed kidIndex, uint minValue, address indexed toAddress);
    /* I just felt like putting this comment here */
    event KidBidEntered(uint indexed kidIndex, uint value, address indexed fromAddress);
    event KidBidWithdrawn(uint indexed kidIndex, uint value, address indexed fromAddress);
    event KidBought(uint indexed kidIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event KidNoLongerForSale(uint indexed kidIndex);
    
    /* CryptoKids contract initializer function */
    constructor() {
        totalSupply = 11111; // Setup the total supply
        owner = msg.sender;
        kidsRemainingToAssign = totalSupply;
        decimals = 0;
    }
    
    /* Warning: Complicated Function Ahead */
    // This function sets the inital owner of the crypto kid
    function setInitialOwner(address to, uint kidIndex) public {
        /* Make sure some immature kids like me aren't playing jokes */
        require(msg.sender == owner);
        require(!allKidsAssigned);
        require(kidIndex < totalSupply);
        /* Transfering the kid */
        if(kidIndexToAddress[kidIndex] != to) {
            if (kidIndexToAddress[kidIndex] != 0x0000000000000000000000000000000000000000) {
                balanceOf[kidIndexToAddress[kidIndex]]--;
            }
            else {
                kidsRemainingToAssign--;
            }
            /* Do the REAL juicy stuff here */
            kidIndexToAddress[kidIndex] = to;
            balanceOf[to]++;
            emit Assign(to, kidIndex);
        }
    }
    
    /*
    ##############################################
    ########### COMPLICATED LAND BELOW ###########
    ##############################################
    */
    
    // This is running through all the crypto kids and calling setInitialOwner() on them
    function setInitialOwners(address[] memory _addresses, uint[] memory indices) public {
        require(msg.sender == owner);
        uint n = _addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(_addresses[i], indices[i]);
        }
    }
    
    function allInitialOwnersAssigned() public {
        require(msg.sender == owner);
        if(kidsRemainingToAssign == 0) {
            if(allKidsAssigned == false) {
                allKidsAssigned = true;
            }
        }
    }
}