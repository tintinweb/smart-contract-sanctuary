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

contract FirstPheonix is Pausable {

    MigrationInterface core;

    constructor(MigrationInterface _core) public {
        core = _core;
    }

    address[] public approved;

    uint16 PHEONIX_PROTO = 380;

    mapping(address => bool) public claimed;

    function approvePack(address toApprove) public onlyOwner {
        approved.push(toApprove);
    }

    function isApproved(address test) public view returns (bool) {
        for (uint i = 0; i < approved.length; i++) {
            if (approved[i] == test) {
                return true;
            }
        }
        return false;
    }

    // pause once cards become tradable
    function claimPheonix(address user) public returns (bool){

        require(isApproved(msg.sender));

        if (claimed[user] || paused){
            return false;
        }

        claimed[user] = true;

        core.createCard(user, PHEONIX_PROTO, 0);

        return true;
    }

}