pragma solidity 0.4.24;

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

contract Vault is Ownable { 

    function () public payable {

    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        owner.transfer(amount);
    }

    function withdrawAll() public onlyOwner {
        withdraw(address(this).balance);
    }
}

contract ERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) public view returns (uint256);
    
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);
    
    function transfer(address to, uint256 value) public returns (bool);
    
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

contract TournamentPass is ERC20, Ownable {

    using SafeMath for uint256;

    Vault vault;

    constructor(Vault _vault) public {
        vault = _vault;
    }

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    address[] public minters;
    uint256 supply;
    uint mintLimit = 20000;
    
    function name() public view returns (string){
        return "GU Tournament Passes";
    }

    function symbol() public view returns (string) {
        return "PASS";
    }

    function addMinter(address minter) public onlyOwner {
        minters.push(minter);
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function isMinter(address test) internal view returns (bool) {
        for (uint i = 0; i < minters.length; i++) {
            if (minters[i] == test) {
                return true;
            }
        }
        return false;
    }

    function mint(address to, uint amount) public returns (bool) {
        require(isMinter(msg.sender));
        if (amount.add(supply) > mintLimit) {
            return false;
        } 
        supply = supply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    uint public price = 250 finney;

    function purchase(uint amount) public payable {
        
        require(msg.value >= price.mul(amount));
        require(supply.add(amount) <= mintLimit);

        supply = supply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit Transfer(address(0), msg.sender, amount);

        address(vault).transfer(msg.value);
    }

}

contract CappedVault is Vault { 

    uint public limit;
    uint withdrawn = 0;

    constructor() public {
        limit = 33333 ether;
    }

    function () public payable {
        require(total() + msg.value <= limit);
    }

    function total() public view returns(uint) {
        return getBalance() + withdrawn;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        owner.transfer(amount);
        withdrawn += amount;
    }

}


contract PreviousInterface {

    function ownerOf(uint id) public view returns (address);

    function getCard(uint id) public view returns (uint16, uint16);

    function totalSupply() public view returns (uint);

    function burnCount() public view returns (uint);

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

contract CardPackThree {

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

contract PresalePackThree is CardPackThree, Pausable {

    CappedVault public vault;

    Purchase[] public purchases;

    function getPurchaseCount() public view returns (uint) {
        return purchases.length;
    }

    struct Purchase {
        uint16 current;
        uint16 count;
        address user;
        uint randomness;
        uint64 commit;
    }

    event PacksPurchased(uint indexed id, address indexed user, uint16 count);
    event PackOpened(uint indexed id, uint16 startIndex, address indexed user, uint[] cardIDs);
    event RandomnessReceived(uint indexed id, address indexed user, uint16 count, uint randomness);

    constructor(MigrationInterface _core, CappedVault _vault) public payable CardPackThree(_core) {
        vault = _vault;
    }

    function basePrice() public returns (uint);
    function getCardDetails(uint16 packIndex, uint8 cardIndex, uint result) public view returns (uint16 proto, uint16 purity);
    
    function packSize() public view returns (uint8) {
        return 5;
    }

    function packsPerClaim() public view returns (uint16) {
        return 15;
    }

    // start in bytes, length in bytes
    function extract(uint num, uint length, uint start) internal pure returns (uint) {
        return (((1 << (length * 8)) - 1) & (num >> ((start * 8) - 1)));
    }

    function purchase(uint16 packCount, address referrer) whenNotPaused public payable {

        require(packCount > 0);
        require(referrer != msg.sender);

        uint price = calculatePrice(basePrice(), packCount);

        require(msg.value >= price);

        Purchase memory p = Purchase({
            user: msg.sender,
            count: packCount,
            commit: uint64(block.number),
            randomness: 0,
            current: 0
        });

        uint id = purchases.push(p) - 1;

        emit PacksPurchased(id, msg.sender, packCount);

        if (referrer != address(0)) {
            uint commission = price / 10;
            referrer.transfer(commission);
            price -= commission;
            emit Referral(referrer, commission, msg.sender);
        }
        
        address(vault).transfer(price); 
    }

    // can be called by anybody
    // can miners withhold blocks --> not really
    // giving up block reward for extra chance --> still really low
    function callback(uint id) public {

        Purchase storage p = purchases[id];

        require(p.randomness == 0);

        bytes32 bhash = blockhash(p.commit);
        // will get the same on every block
        // only use properties which can&#39;t be altered by the user
        uint random = uint(keccak256(abi.encodePacked(bhash, p.user, address(this), p.count)));

        // can&#39;t callback on the original block
        require(uint64(block.number) != p.commit);

        if (uint(bhash) == 0) {
            // should never happen (must call within next 256 blocks)
            // if it does, just give them 1: will become common and therefore less valuable
            // set to 1 rather than 0 to avoid calling claim before randomness
            p.randomness = 1;
        } else {
            p.randomness = random;
        }

        emit RandomnessReceived(id, p.user, p.count, p.randomness);
    }

    function claim(uint id) public {
        
        Purchase storage p = purchases[id];

        require(canClaim);

        uint16 proto;
        uint16 purity;
        uint16 count = p.count;
        uint result = p.randomness;
        uint8 size = packSize();

        address user = p.user;
        uint16 current = p.current;

        require(result != 0); // have to wait for the callback
        // require(user == msg.sender); // not needed
        require(count > 0);

        uint[] memory ids = new uint[](size);

        uint16 end = current + packsPerClaim() > count ? count : current + packsPerClaim();

        require(end > current);

        for (uint16 i = current; i < end; i++) {
            for (uint8 j = 0; j < size; j++) {
                (proto, purity) = getCardDetails(i, j, result);
                ids[j] = migration.createCard(user, proto, purity);
            }
            emit PackOpened(id, (i * size), user, ids);
        }
        p.current += (end - current);
    }

    function predictPacks(uint id) external view returns (uint16[] protos, uint16[] purities) {

        Purchase memory p = purchases[id];

        uint16 proto;
        uint16 purity;
        uint16 count = p.count;
        uint result = p.randomness;
        uint8 size = packSize();

        purities = new uint16[](size * count);
        protos = new uint16[](size * count);

        for (uint16 i = 0; i < count; i++) {
            for (uint8 j = 0; j < size; j++) {
                (proto, purity) = getCardDetails(i, j, result);
                purities[(i * size) + j] = purity;
                protos[(i * size) + j] = proto;
            }
        }
        return (protos, purities);
    }

    function calculatePrice(uint base, uint16 packCount) public view returns (uint) {
        // roughly 6k blocks per day
        uint difference = block.number - creationBlock;
        uint numDays = difference / 6000;
        if (20 > numDays) {
            return (base - (((20 - numDays) * base) / 100)) * packCount;
        }
        return base * packCount;
    }

    function _getCommonPlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else if (rand >= 998345) {
            return CardProto.Rarity.Legendary;
        } else if (rand >= 986765) {
            return CardProto.Rarity.Epic;
        } else if (rand >= 924890) {
            return CardProto.Rarity.Rare;
        } else {
            return CardProto.Rarity.Common;
        }
    }

    function _getRarePlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else if (rand >= 981615) {
            return CardProto.Rarity.Legendary;
        } else if (rand >= 852940) {
            return CardProto.Rarity.Epic;
        } else {
            return CardProto.Rarity.Rare;
        } 
    }

    function _getEpicPlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else if (rand >= 981615) {
            return CardProto.Rarity.Legendary;
        } else {
            return CardProto.Rarity.Epic;
        }
    }

    function _getLegendaryPlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else {
            return CardProto.Rarity.Legendary;
        } 
    }

    bool public canClaim = true;

    function setCanClaim(bool claim) public onlyOwner {
        canClaim = claim;
    }

    function getComponents(
        uint16 i, uint8 j, uint rand
    ) internal returns (
        uint random, uint32 rarityRandom, uint16 purityOne, uint16 purityTwo, uint16 protoRandom
    ) {
        random = uint(keccak256(abi.encodePacked(i, rand, j)));
        rarityRandom = uint32(extract(random, 4, 10) % 1000000);
        purityOne = uint16(extract(random, 2, 4) % 1000);
        purityTwo = uint16(extract(random, 2, 6) % 1000);
        protoRandom = uint16(extract(random, 2, 8) % (2**16-1));
        return (random, rarityRandom, purityOne, purityTwo, protoRandom);
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

}

contract PackMultiplier is PresalePackThree {

    address[] public packs;
    uint16 public multiplier = 3;
    FirstPheonix pheonix;
    PreviousInterface old;

    uint16 public packLimit = 5;

    constructor(PreviousInterface _old, address[] _packs, MigrationInterface _core, CappedVault vault, FirstPheonix _pheonix) 
        public PresalePackThree(_core, vault) 
    {
        packs = _packs;
        pheonix = _pheonix;
        old = _old;
    }

    function getCardCount() internal view returns (uint) {
        return old.totalSupply() + old.burnCount();
    }

    function isPriorPack(address test) public view returns(bool) {
        for (uint i = 0; i < packs.length; i++) {
            if (packs[i] == test) {
                return true;
            }
        }
        return false;
    }

    event Status(uint before, uint aft);

    function claimMultiple(address pack, uint purchaseID) public returns (uint16, address) {

        require(isPriorPack(pack));

        uint length = getCardCount();

        PresalePackThree(pack).claim(purchaseID);

        uint lengthAfter = getCardCount();

        require(lengthAfter > length);

        uint16 cardDifference = uint16(lengthAfter - length);

        require(cardDifference % 5 == 0);

        uint16 packCount = cardDifference / 5;

        uint16 extra = packCount * multiplier;

        address lastCardOwner = old.ownerOf(lengthAfter - 1);

        Purchase memory p = Purchase({
            user: lastCardOwner,
            count: extra,
            commit: uint64(block.number),
            randomness: 0,
            current: 0
        });

        uint id = purchases.push(p) - 1;

        emit PacksPurchased(id, lastCardOwner, extra);

        // try to give them a first pheonix
        pheonix.claimPheonix(lastCardOwner);

        emit Status(length, lengthAfter);


        if (packCount <= packLimit) {
            for (uint i = 0; i < cardDifference; i++) {
                migration.migrate(lengthAfter - 1 - i);
            }
        }

        return (extra, lastCardOwner);
    }

    function setPackLimit(uint16 limit) public onlyOwner {
        packLimit = limit;
    }


}

contract ShinyLegendaryPackThree is PackMultiplier {
    
    function basePrice() public returns (uint) {
        return 1 ether;
    }

    TournamentPass public tournament;

    constructor(PreviousInterface _old, address[] _packs, MigrationInterface _core, CappedVault vault, TournamentPass _tournament, FirstPheonix _pheonix) 
        public PackMultiplier(_old, _packs, _core, vault, _pheonix) {
        
        tournament = _tournament;
    }
    

    function claimMultiple(address pack, uint purchaseID) public returns (uint16, address) {
        uint16 extra;
        address user;
        (extra, user) = super.claimMultiple(pack, purchaseID);
        tournament.mint(user, extra);
    }

    function getCardDetails(uint16 packIndex, uint8 cardIndex, uint result) public view returns (uint16 proto, uint16 purity) {
        uint random;
        uint32 rarityRandom;
        uint16 protoRandom;
        uint16 purityOne;
        uint16 purityTwo;
        CardProto.Rarity rarity;

        (random, rarityRandom, purityOne, purityTwo, protoRandom) = getComponents(packIndex, cardIndex, result);

        if (cardIndex == 4) {
            rarity = _getLegendaryPlusRarity(rarityRandom);
            purity = _getShinyPurity(purityOne, purityTwo);
        } else if (cardIndex == 3) {
            rarity = _getRarePlusRarity(rarityRandom);
            purity = _getPurity(purityOne, purityTwo);
        } else {
            rarity = _getCommonPlusRarity(rarityRandom);
            purity = _getPurity(purityOne, purityTwo);
        }
    
        proto = migration.getRandomCard(rarity, protoRandom);

        return (proto, purity);
    } 

    function _getShinyPurity(uint16 randOne, uint16 randTwo) public pure returns (uint16) {
        if (randOne >= 998) {
            return 3000 + randTwo;
        } else if (randOne >= 748) {
            return 2000 + randTwo;
        } else {
            return 1000 + randTwo;
        }
    }
    
}