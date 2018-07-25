pragma solidity 0.4.24;


contract Governable {

    event Pause();
    event Unpause();

    address public governor;
    bool public paused = false;

    constructor() public {
        governor = msg.sender;
    }

    function setGovernor(address _gov) public onlyGovernor {
        governor = _gov;
    }

    modifier onlyGovernor {
        require(msg.sender == governor);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyGovernor whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyGovernor whenPaused public {
        paused = false;
        emit Unpause();
    }

}

contract CardBase is Governable {


    struct Card {
        uint16 proto;
        uint16 purity;
    }

    function getCard(uint id) public view returns (uint16 proto, uint16 purity) {
        Card memory card = cards[id];
        return (card.proto, card.purity);
    }

    function getShine(uint16 purity) public pure returns (uint8) {
        return uint8(purity / 1000);
    }

    Card[] public cards;
    
}

contract CardProto is CardBase {

    event NewProtoCard(
        uint16 id, uint8 season, uint8 god, 
        Rarity rarity, uint8 mana, uint8 attack, 
        uint8 health, uint8 cardType, uint8 tribe, bool packable
    );

    struct Limit {
        uint64 limit;
        bool exists;
    }

    // limits for mythic cards
    mapping(uint16 => Limit) public limits;

    // can only set limits once
    function setLimit(uint16 id, uint64 limit) public onlyGovernor {
        Limit memory l = limits[id];
        require(!l.exists);
        limits[id] = Limit({
            limit: limit,
            exists: true
        });
    }

    function getLimit(uint16 id) public view returns (uint64 limit, bool set) {
        Limit memory l = limits[id];
        return (l.limit, l.exists);
    }

    // could make these arrays to save gas
    // not really necessary - will be update a very limited no of times
    mapping(uint8 => bool) public seasonTradable;
    mapping(uint8 => bool) public seasonTradabilityLocked;
    uint8 public currentSeason;

    function makeTradable(uint8 season) public onlyGovernor {
        seasonTradable[season] = true;
    }

    function makeUntradable(uint8 season) public onlyGovernor {
        require(!seasonTradabilityLocked[season]);
        seasonTradable[season] = false;
    }

    function makePermanantlyTradable(uint8 season) public onlyGovernor {
        require(seasonTradable[season]);
        seasonTradabilityLocked[season] = true;
    }

    function isTradable(uint16 proto) public view returns (bool) {
        return seasonTradable[protos[proto].season];
    }

    function nextSeason() public onlyGovernor {
        //Seasons shouldn&#39;t go to 0 if there is more than the uint8 should hold, the governor should know this &#175;\_(ツ)_/&#175; -M
        require(currentSeason <= 255); 

        currentSeason++;
        mythic.length = 0;
        legendary.length = 0;
        epic.length = 0;
        rare.length = 0;
        common.length = 0;
    }

    enum Rarity {
        Common,
        Rare,
        Epic,
        Legendary, 
        Mythic
    }

    uint8 constant SPELL = 1;
    uint8 constant MINION = 2;
    uint8 constant WEAPON = 3;
    uint8 constant HERO = 4;

    struct ProtoCard {
        bool exists;
        uint8 god;
        uint8 season;
        uint8 cardType;
        Rarity rarity;
        uint8 mana;
        uint8 attack;
        uint8 health;
        uint8 tribe;
    }

    // there is a particular design decision driving this:
    // need to be able to iterate over mythics only for card generation
    // don&#39;t store 5 different arrays: have to use 2 ids
    // better to bear this cost (2 bytes per proto card)
    // rather than 1 byte per instance

    uint16 public protoCount;
    
    mapping(uint16 => ProtoCard) protos;

    uint16[] public mythic;
    uint16[] public legendary;
    uint16[] public epic;
    uint16[] public rare;
    uint16[] public common;

    function addProtos(
        uint16[] externalIDs, uint8[] gods, Rarity[] rarities, uint8[] manas, uint8[] attacks, 
        uint8[] healths, uint8[] cardTypes, uint8[] tribes, bool[] packable
    ) public onlyGovernor returns(uint16) {

        for (uint i = 0; i < externalIDs.length; i++) {

            ProtoCard memory card = ProtoCard({
                exists: true,
                god: gods[i],
                season: currentSeason,
                cardType: cardTypes[i],
                rarity: rarities[i],
                mana: manas[i],
                attack: attacks[i],
                health: healths[i],
                tribe: tribes[i]
            });

            _addProto(externalIDs[i], card, packable[i]);
        }
        
    }

    function addProto(
        uint16 externalID, uint8 god, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 cardType, uint8 tribe, bool packable
    ) public onlyGovernor returns(uint16) {
        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: cardType,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: health,
            tribe: tribe
        });

        _addProto(externalID, card, packable);
    }

    function addWeapon(
        uint16 externalID, uint8 god, Rarity rarity, uint8 mana, uint8 attack, uint8 durability, bool packable
    ) public onlyGovernor returns(uint16) {

        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: WEAPON,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: durability,
            tribe: 0
        });

        _addProto(externalID, card, packable);
    }

    function addSpell(uint16 externalID, uint8 god, Rarity rarity, uint8 mana, bool packable) public onlyGovernor returns(uint16) {

        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: SPELL,
            rarity: rarity,
            mana: mana,
            attack: 0,
            health: 0,
            tribe: 0
        });

        _addProto(externalID, card, packable);
    }

    function addMinion(
        uint16 externalID, uint8 god, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 tribe, bool packable
    ) public onlyGovernor returns(uint16) {

        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: MINION,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: health,
            tribe: tribe
        });

        _addProto(externalID, card, packable);
    }

    function _addProto(uint16 externalID, ProtoCard memory card, bool packable) internal {

        require(!protos[externalID].exists);

        card.exists = true;

        protos[externalID] = card;

        protoCount++;

        emit NewProtoCard(
            externalID, currentSeason, card.god, 
            card.rarity, card.mana, card.attack, 
            card.health, card.cardType, card.tribe, packable
        );

        if (packable) {
            Rarity rarity = card.rarity;
            if (rarity == Rarity.Common) {
                common.push(externalID);
            } else if (rarity == Rarity.Rare) {
                rare.push(externalID);
            } else if (rarity == Rarity.Epic) {
                epic.push(externalID);
            } else if (rarity == Rarity.Legendary) {
                legendary.push(externalID);
            } else if (rarity == Rarity.Mythic) {
                mythic.push(externalID);
            } else {
                require(false);
            }
        }
    }

    function getProto(uint16 id) public view returns(
        bool exists, uint8 god, uint8 season, uint8 cardType, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 tribe
    ) {
        ProtoCard memory proto = protos[id];
        return (
            proto.exists,
            proto.god,
            proto.season,
            proto.cardType,
            proto.rarity,
            proto.mana,
            proto.attack,
            proto.health,
            proto.tribe
        );
    }

    function getRandomCard(Rarity rarity, uint16 random) public view returns (uint16) {
        // modulo bias is fine - creates rarity tiers etc
        // will obviously revert is there are no cards of that type: this is expected - should never happen
        if (rarity == Rarity.Common) {
            return common[random % common.length];
        } else if (rarity == Rarity.Rare) {
            return rare[random % rare.length];
        } else if (rarity == Rarity.Epic) {
            return epic[random % epic.length];
        } else if (rarity == Rarity.Legendary) {
            return legendary[random % legendary.length];
        } else if (rarity == Rarity.Mythic) {
            // make sure a mythic is available
            uint16 id;
            uint64 limit;
            bool set;
            for (uint i = 0; i < mythic.length; i++) {
                id = mythic[(random + i) % mythic.length];
                (limit, set) = getLimit(id);
                if (set && limit > 0){
                    return id;
                }
            }
            // if not, they get a legendary :(
            return legendary[random % legendary.length];
        }
        require(false);
        return 0;
    }

    // can never adjust tradable cards
    // each season gets a &#39;balancing beta&#39;
    // totally immutable: season, rarity
    function replaceProto(
        uint16 index, uint8 god, uint8 cardType, uint8 mana, uint8 attack, uint8 health, uint8 tribe
    ) public onlyGovernor {
        ProtoCard memory pc = protos[index];
        require(!seasonTradable[pc.season]);
        protos[index] = ProtoCard({
            exists: true,
            god: god,
            season: pc.season,
            cardType: cardType,
            rarity: pc.rarity,
            mana: mana,
            attack: attack,
            health: health,
            tribe: tribe
        });
    }

}

contract MigrationInterface {

    function createCard(address user, uint16 proto, uint16 purity) public returns (uint);

    function getRandomCard(CardProto.Rarity rarity, uint16 random) public view returns (uint16);

    function migrate(uint id) public;

}

contract CardPackFour {

    MigrationInterface public migration;
    uint public creationBlock;

    constructor(MigrationInterface _core) public payable {
        migration = _core;
        creationBlock = 5939061 + 2000; // set to creation block of first contracts + 8 hours for down time
    }

    event Referral(address indexed referrer, uint value, address purchaser);

    /**
    * purchase &#39;count&#39; of this type of pack
    */
    function purchase(uint16 packCount, address referrer) public payable;

    // store purity and shine as one number to save users gas
    function _getPurity(uint16 randOne, uint16 randTwo) internal pure returns (uint16) {
        if (randOne >= 998) {
            return 3000 + randTwo;
        } else if (randOne >= 988) {
            return 2000 + randTwo;
        } else if (randOne >= 938) {
            return 1000 + randTwo;
        } else {
            return randTwo;
        }
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

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract Pausable is Ownable {
    
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

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

library SafeMath64 {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint64 a, uint64 b) internal pure returns (uint64 c) {
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
  function div(uint64 a, uint64 b) internal pure returns (uint64) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint64 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AuctionPack is CardPackFour, Pausable {

    using SafeMath for uint;
    // probably a better way to do this/don&#39;t need to do it at all
    using SafeMath64 for uint64;

    mapping(address => uint) owed;

    event Created(uint indexed id, uint16 proto, uint16 purity, uint minBid, uint length);
    event Opened(uint indexed id, uint64 start);
    event Extended(uint indexed id, uint64 length);
    event Bid(uint indexed id, address indexed bidder, uint value);
    event Claimed(uint indexed id, uint indexed cardID, address indexed bidder, uint value, uint16 proto, uint16 purity);
    event Bonus(uint indexed id, uint indexed cardID, address indexed bidder, uint16 proto, uint16 purity);

    enum Status {
        Closed,
        Open,
        Claimed
    }

    struct Auction {
        Status status;
        uint16 proto;
        uint16 purity;
        uint highestBid;
        address highestBidder;
        uint64 start;
        uint64 length;
        address beneficiary;
        uint16 bonusProto;
        uint16 bonusPurity;
        uint64 bufferPeriod;
        uint minIncreasePercent;
    }

    Auction[] auctions;

    constructor(MigrationInterface _migration) public CardPackFour(_migration) {
        
    }

    function getAuction(uint id) public view returns (
        Status status,
        uint16 proto,
        uint16 purity,
        uint highestBid,
        address highestBidder,
        uint64 start,
        uint64 length,
        uint16 bonusProto,
        uint16 bonusPurity,
        uint64 bufferPeriod,
        uint minIncreasePercent,
        address beneficiary
    ) {
        require(auctions.length > id);
        Auction memory a = auctions[id];
        return (
            a.status, a.proto, a.purity, a.highestBid, 
            a.highestBidder, a.start, a.length, a.bonusProto, 
            a.bonusPurity, a.bufferPeriod, a.minIncreasePercent, a.beneficiary
        );
    }

    function createAuction(
        address beneficiary, uint16 proto, uint16 purity, 
        uint minBid, uint64 length, uint16 bonusProto, uint16 bonusPurity,
        uint64 bufferPeriod, uint minIncrease
    ) public onlyOwner whenNotPaused returns (uint) {

        require(beneficiary != address(0));
        require(minBid >= 100 wei);

        Auction memory auction = Auction({
            status: Status.Closed,
            proto: proto,
            purity: purity,
            highestBid: minBid,
            highestBidder: address(0),
            start: 0,
            length: length,
            beneficiary: beneficiary,
            bonusProto: bonusProto,
            bonusPurity: bonusPurity,
            bufferPeriod: bufferPeriod,
            minIncreasePercent: minIncrease
        });

        uint id = auctions.push(auction) - 1;

        emit Created(id, proto, purity, minBid, length);

        return id;
    }

    function openAuction(uint id) public onlyOwner {
        Auction storage auction = auctions[id];
        require(auction.status == Status.Closed);
        auction.status = Status.Open;
        auction.start = uint64(block.number);
        emit Opened(id, auction.start);
    }

    // dummy implementation to support interface
    function purchase(uint16, address) public payable { 
        
    }

    function getMinBid(uint id) public view returns (uint) {

        Auction memory auction = auctions[id];

        uint highest = auction.highestBid;
        
        // calculate one percent of the number
        // highest will always be >= 100
        uint numerator = highest.div(100);

        // calculate the minimum increase required
        uint minIncrease = numerator.mul(auction.minIncreasePercent);

        uint threshold = highest + minIncrease;

        return threshold;
    }

    function bid(uint id) public payable {

        Auction storage auction = auctions[id];

        require(auction.status == Status.Open);

        uint64 end = auction.start.add(auction.length);

        require(end >= block.number);

        uint threshold = getMinBid(id);
        
        require(msg.value >= threshold);

        
        // if within the buffer period of the auction
        // extend to the buffer period of blocks

        uint64 differenceToEnd = end.sub(uint64(block.number));

        if (auction.bufferPeriod > differenceToEnd) {
            
            // extend the auction period to be at least the buffer period
            uint64 toAdd = auction.bufferPeriod.sub(differenceToEnd);

            auction.length = auction.length.add(toAdd);

            emit Extended(id, auction.length);
        }

        emit Bid(id, msg.sender, msg.value);

        if (auction.highestBidder != address(0)) {

            // let&#39;s just go with the safe option rather than using send(): probably fine but no loss
            owed[auction.highestBidder] = owed[auction.highestBidder].add(auction.highestBid);

            // give the previous bidder their bonus/consolation card 
            if (auction.bonusProto != 0) {
                uint cardID = migration.createCard(auction.highestBidder, auction.bonusProto, auction.bonusPurity);
                emit Bonus(id, cardID, auction.highestBidder, auction.bonusProto, auction.bonusPurity);
            }
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
    }

    // anyone can claim the card/pay gas for them
    function claim(uint id) public returns (uint) {

        Auction storage auction = auctions[id];

        uint64 end = auction.start.add(auction.length);

        require(block.number > end);

        require(auction.status == Status.Open);
        
        auction.status = Status.Claimed;

        uint cardID = migration.createCard(auction.highestBidder, auction.proto, auction.purity);

        emit Claimed(id, cardID, auction.highestBidder, auction.highestBid, auction.proto, auction.purity);

        // don&#39;t require this to be a trusted address
        owed[auction.beneficiary] = owed[auction.beneficiary].add(auction.highestBid);

        return cardID;
    }

    function withdraw(address user) public {
        uint balance = owed[user];
        require(balance > 0);
        owed[user] = 0;
        user.transfer(balance);
    }

    function getOwed(address user) public view returns (uint) {
        return owed[user];
    }
    
}