pragma solidity 0.4.24;

contract Kitties {

    function ownerOf(uint id) public view returns (address);

}

contract ICollectable {

    function mint(uint32 delegateID, address to) public returns (uint);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

}

contract IAuction {

    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt);
}

contract IPack {

    function purchase(uint16, address) public payable;
    function purchaseFor(address, uint16, address) public payable;

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract CatInThePack is Ownable {

    using SafeMath for uint;

    // the pack of GU cards which will be purchased
    IPack public pack;
    // the core CK contract
    Kitties public kitties;
    // the core GU collectable contract
    ICollectable public collectables;
    // the list of CK auction contracts, usually [Sale, Sire]
    IAuction[] public auctions;
    
    // whether it is currently possible to claim cats
    bool public canClaim = true;
    // the collectable delegate id 
    uint32 public delegateID;
    // whether the contract is locked (i.e. no more claiming)
    bool public locked = false;
    // whether kitties on auction are considered to be owned by the sender
    bool public includeAuctions = true;
    // contract where funds will be sent
    address public vault;
    // max number of kitties per call
    uint public claimLimit = 20;
    // price per statue
    uint public price = 0.024 ether;
    
    
    // map to track whether a kitty has been claimed
    mapping(uint => bool) public claimed;
    // map from statue id to kitty id
    mapping(uint => uint) public statues;

    constructor(IPack _pack, IAuction[] memory _auctions, Kitties _kitties, 
        ICollectable _collectables, uint32 _delegateID, address _vault) public {
        pack = _pack;
        auctions = _auctions;
        kitties = _kitties;
        collectables = _collectables;
        delegateID = _delegateID;
        vault = _vault;
    }

    event CatsClaimed(uint[] statueIDs, uint[] kittyIDs);

    // claim statues tied to the following kittyIDs
    function claim(uint[] memory kittyIDs, address referrer) public payable returns (uint[] memory ids) {

        require(canClaim, "claiming not enabled");
        require(kittyIDs.length > 0, "you must claim at least one cat");
        require(claimLimit >= kittyIDs.length, "must claim >= the claim limit at a time");
        
        // statue id array
        ids = new uint[](kittyIDs.length);
        
        for (uint i = 0; i < kittyIDs.length; i++) {

            uint kittyID = kittyIDs[i];

            // mark the kitty as being claimed
            require(!claimed[kittyID], "kitty must not be claimed");
            claimed[kittyID] = true;

            require(ownsOrSelling(kittyID), "you must own all the cats you claim");

            // create the statue token
            uint id = collectables.mint(delegateID, msg.sender);
            ids[i] = id;
            // record which kitty is associated with this statue
            statues[id] = kittyID;    
        }
        
        // calculate the total purchase price
        uint totalPrice = price.mul(kittyIDs.length);

        require(msg.value >= totalPrice, "wrong value sent to contract");
       
        uint half = totalPrice.div(2);

        // send half the price to buy the packs
        pack.purchaseFor.value(half)(msg.sender, uint16(kittyIDs.length), referrer); 

        // send the other half directly to the vault contract
        vault.transfer(half);

        emit CatsClaimed(ids, kittyIDs);
        
        return ids;
    }

    // returns whether the msg.sender owns or is auctioning a kitty
    function ownsOrSelling(uint kittyID) public view returns (bool) {
        // call to the core CK contract to find the owner of the kitty
        address owner = kitties.ownerOf(kittyID);
        if (owner == msg.sender) {
            return true;
        } 
        // check whether we are including the auction contracts
        if (includeAuctions) {
            address seller;
            for (uint i = 0; i < auctions.length; i++) {
                IAuction auction = auctions[i];
                // make sure you check that this cat is owned by the auction 
                // before calling the method, or getAuction will throw
                if (owner == address(auction)) {
                    (seller, , , ,) = auction.getAuction(kittyID);
                    return seller == msg.sender;
                }
            }
        }
        return false;
    }
 
    function setCanClaim(bool _can, bool lock) public onlyOwner {
        require(!locked, "claiming is permanently locked");
        if (lock) {
            require(!_can, "can&#39;t lock on permanently");
            locked = true;
        }
        canClaim = _can;
    }

    function getKitty(uint statueID) public view returns (uint) {
        return statues[statueID];
    }

    function setClaimLimit(uint limit) public onlyOwner {
        claimLimit = limit;
    }

    function setIncludeAuctions(bool _include) public onlyOwner {
        includeAuctions = _include;
    }

}