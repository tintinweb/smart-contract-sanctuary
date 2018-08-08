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

    function makeTradeable(uint8 season) public onlyGovernor {
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
        uint16[] externalIDs, uint8[] gods, Rarity[] rarities, uint8[] manas, uint8[] attacks, uint8[] healths, uint8[] cardTypes, uint8[] tribes, bool[] packable
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

interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() public view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs    owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable;
    function transfer(address _to, uint256 _tokenId) public payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
    function approve(address _to, uint256 _tokenId) public payable;
    function setApprovalForAll(address _to, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract NFT is ERC721, ERC165, ERC721Metadata, ERC721Enumerable {}

contract CardOwnership is NFT, CardProto {

    // doing this strategy doesn&#39;t save gas
    // even setting the length to the max and filling in
    // unfortunately - maybe if we stop it boundschecking
    // address[] owners;
    mapping(uint => address) owners;
    mapping(uint => address) approved;
    // support multiple operators
    mapping(address => mapping(address => bool)) operators;

    // save space, limits us to 2^40 tokens (>1t)
    mapping(address => uint40[]) public ownedTokens;

    mapping(uint => string) uris;

    // save space, limits us to 2^24 tokens per user (~17m)
    uint24[] indices;

    uint public burnCount;

    /**
    * @return the name of this token
    */
    function name() public view returns (string) {
        return "Gods Unchained";
    }

    /**
    * @return the symbol of this token
    */  
    function symbol() public view returns (string) {
        return "GODS";
    }

    /**
    * @return the total number of cards in circulation
    */
    function totalSupply() public view returns (uint) {
        return cards.length - burnCount;
    }

    /**
    * @param to : the address to which the card will be transferred
    * @param id : the id of the card to be transferred
    */
    function transfer(address to, uint id) public payable {
        require(owns(msg.sender, id));
        require(isTradable(cards[id].proto));
        require(to != address(0));
        _transfer(msg.sender, to, id);
    }

    /**
    * internal transfer function which skips checks - use carefully
    * @param from : the address from which the card will be transferred
    * @param to : the address to which the card will be transferred
    * @param id : the id of the card to be transferred
    */
    function _transfer(address from, address to, uint id) internal {
        approved[id] = address(0);
        owners[id] = to;
        _addToken(to, id);
        _removeToken(from, id);
        emit Transfer(from, to, id);
    }

    /**
    * initial internal transfer function which skips checks and saves gas - use carefully
    * @param to : the address to which the card will be transferred
    * @param id : the id of the card to be transferred
    */
    function _create(address to, uint id) internal {
        owners[id] = to;
        _addToken(to, id);
        emit Transfer(address(0), to, id);
    }

    /**
    * @param to : the address to which the cards will be transferred
    * @param ids : the ids of the cards to be transferred
    */
    function transferAll(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            transfer(to, ids[i]);
        }
    }

    /**
    * @param proposed : the claimed owner of the cards
    * @param ids : the ids of the cards to check
    * @return whether proposed owns all of the cards 
    */
    function ownsAll(address proposed, uint[] ids) public view returns (bool) {
        for (uint i = 0; i < ids.length; i++) {
            if (!owns(proposed, ids[i])) {
                return false;
            }
        }
        return true;
    }

    /**
    * @param proposed : the claimed owner of the card
    * @param id : the id of the card to check
    * @return whether proposed owns the card
    */
    function owns(address proposed, uint id) public view returns (bool) {
        return ownerOf(id) == proposed;
    }

    /**
    * @param id : the id of the card
    * @return the address of the owner of the card
    */
    function ownerOf(uint id) public view returns (address) {
        return owners[id];
    }

    /**
    * @param id : the index of the token to burn
    */
    function burn(uint id) public {
        // require(isTradable(cards[id].proto));
        require(owns(msg.sender, id));
        burnCount++;
        // use the internal transfer function as the external
        // has a guard to prevent transfers to 0x0
        _transfer(msg.sender, address(0), id);
    }

    /**
    * @param ids : the indices of the tokens to burn
    */
    function burnAll(uint[] ids) public {
        for (uint i = 0; i < ids.length; i++){
            burn(ids[i]);
        }
    }

    /**
    * @param to : the address to approve for transfer
    * @param id : the index of the card to be approved
    */
    function approve(address to, uint id) public payable {
        require(owns(msg.sender, id));
        require(isTradable(cards[id].proto));
        approved[id] = to;
        emit Approval(msg.sender, to, id);
    }

    /**
    * @param to : the address to approve for transfer
    * @param ids : the indices of the cards to be approved
    */
    function approveAll(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            approve(to, ids[i]);
        }
    }

    /**
    * @param id : the index of the token to check
    * @return the address approved to transfer this token
    */
    function getApproved(uint id) public view returns(address) {
        return approved[id];
    }

    /**
    * @param owner : the address to check
    * @return the number of tokens controlled by owner
    */
    function balanceOf(address owner) public view returns (uint) {
        return ownedTokens[owner].length;
    }

    /**
    * @param id : the index of the proposed token
    * @return whether the token is owned by a non-zero address
    */
    function exists(uint id) public view returns (bool) {
        return owners[id] != address(0);
    }

    /**
    * @param to : the address to which the token should be transferred
    * @param id : the index of the token to transfer
    */
    function transferFrom(address from, address to, uint id) public payable {
        
        require(to != address(0));
        require(to != address(this));

        // TODO: why is this necessary
        // if you&#39;re approved, why does it matter where it comes from?
        require(ownerOf(id) == from);

        require(isSenderApprovedFor(id));

        require(isTradable(cards[id].proto));

        _transfer(ownerOf(id), to, id);
    }

    /**
    * @param to : the address to which the tokens should be transferred
    * @param ids : the indices of the tokens to transfer
    */
    function transferAllFrom(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            transferFrom(address(0), to, ids[i]);
        }
    }

    /**
     * @return the number of cards which have been burned
     */
    function getBurnCount() public view returns (uint) {
        return burnCount;
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operators[owner][operator];
    }

    function setApprovalForAll(address to, bool toApprove) public {
        require(to != msg.sender);
        operators[msg.sender][to] = toApprove;
        emit ApprovalForAll(msg.sender, to, toApprove);
    }

    bytes4 constant magic = bytes4(keccak256("onERC721Received(address,uint256,bytes)"));

    function safeTransferFrom(address from, address to, uint id, bytes data) public payable {
        require(to != address(0));
        transferFrom(from, to, id);
        if (_isContract(to)) {
            bytes4 response = ERC721TokenReceiver(to).onERC721Received.gas(50000)(from, id, data);
            require(response == magic);
        }
    }

    function safeTransferFrom(address from, address to, uint id) public payable {
        safeTransferFrom(from, to, id, "");
    }

    function _addToken(address to, uint id) private {
        uint pos = ownedTokens[to].push(uint40(id)) - 1;
        indices.push(uint24(pos));
    }

    function _removeToken(address from, uint id) public payable {
        uint24 index = indices[id];
        uint lastIndex = ownedTokens[from].length - 1;
        uint40 lastId = ownedTokens[from][lastIndex];

        ownedTokens[from][index] = lastId;
        ownedTokens[from][lastIndex] = 0;
        ownedTokens[from].length--;
    }

    function isSenderApprovedFor(uint256 id) internal view returns (bool) {
        return owns(msg.sender, id) || getApproved(id) == msg.sender || isApprovedForAll(ownerOf(id), msg.sender);
    }

    function _isContract(address test) internal view returns (bool) {
        uint size; 
        assembly {
            size := extcodesize(test)
        }
        return (size > 0);
    }

    function tokenURI(uint id) public view returns (string) {
        return uris[id];
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 _tokenId){
        return ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) external view returns (uint256){
        return index;
    }

    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return (
            interfaceID == this.supportsInterface.selector || // ERC165
            interfaceID == 0x5b5e139f || // ERC721Metadata
            interfaceID == 0x6466353c || // ERC-721 on 3/7/2018
            interfaceID == 0x780e9d63
        ); // ERC721Enumerable
    }

    function implementsERC721() external pure returns (bool) {
        return true;
    }

    function getOwnedTokens(address user) public view returns (uint40[]) {
        return ownedTokens[user];
    }
    

}

/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
	function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}



contract CardIntegration is CardOwnership {
    
    CardPack[] packs;

    event CardCreated(uint indexed id, uint16 proto, uint16 purity, address owner);

    function addPack(CardPack approved) public onlyGovernor {
        packs.push(approved);
    }

    modifier onlyApprovedPacks {
        require(_isApprovedPack());
        _;
    }

    function _isApprovedPack() private view returns (bool) {
        for (uint i = 0; i < packs.length; i++) {
            if (msg.sender == address(packs[i])) {
                return true;
            }
        }
        return false;
    }

    function createCard(address owner, uint16 proto, uint16 purity) public whenNotPaused onlyApprovedPacks returns (uint) {
        ProtoCard memory card = protos[proto];
        require(card.season == currentSeason);
        if (card.rarity == Rarity.Mythic) {
            uint64 limit;
            bool exists;
            (limit, exists) = getLimit(proto);
            require(!exists || limit > 0);
            limits[proto].limit--;
        }
        return _createCard(owner, proto, purity);
    }

    function _createCard(address owner, uint16 proto, uint16 purity) internal returns (uint) {
        Card memory card = Card({
            proto: proto,
            purity: purity
        });

        uint id = cards.push(card) - 1;

        _create(owner, id);
        
        emit CardCreated(id, proto, purity, owner);

        return id;
    }

    /*function combineCards(uint[] ids) public whenNotPaused {
        require(ids.length == 5);
        require(ownsAll(msg.sender, ids));
        Card memory first = cards[ids[0]];
        uint16 proto = first.proto;
        uint8 shine = _getShine(first.purity);
        require(shine < shineLimit);
        uint16 puritySum = first.purity - (shine * 1000);
        burn(ids[0]);
        for (uint i = 1; i < ids.length; i++) {
            Card memory next = cards[ids[i]];
            require(next.proto == proto);
            require(_getShine(next.purity) == shine);
            puritySum += (next.purity - (shine * 1000));
            burn(ids[i]);
        }
        uint16 newPurity = uint16(((shine + 1) * 1000) + (puritySum / ids.length));
        _createCard(msg.sender, proto, newPurity);
    }*/


    // PURITY NOTES
    // currently, we only
    // however, to protect rarity, you&#39;ll never be abl
    // this is enforced by the restriction in the create-card function
    // no cards above this point can be found in packs

    

}

contract CardPack {

    CardIntegration public integration;
    uint public creationBlock;

    constructor(CardIntegration _integration) public payable {
        integration = _integration;
        creationBlock = block.number;
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

contract PresalePack is CardPack, Pausable {

    CappedVault public vault;

    Purchase[] purchases;

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

    constructor(CardIntegration integration, CappedVault _vault) public payable CardPack(integration) {
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

    uint public purchaseCount;
    uint public totalCount;

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
    function callback(uint id) public {

        Purchase storage p = purchases[id];

        require(p.randomness == 0);

        bytes32 bhash = blockhash(p.commit);

        uint random = uint(keccak256(abi.encodePacked(totalCount, bhash)));

        totalCount += p.count;

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
                ids[j] = integration.createCard(user, proto, purity);
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

pragma solidity 0.4.24;

// from OZ

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

contract LegendaryPack is PresalePack {

    TournamentPass pass;

    constructor(CardIntegration integration, CappedVault _vault, TournamentPass _pass) public payable PresalePack(integration, _vault) {
        pass = _pass;
    }

    function purchase(uint16 packCount, address referrer) public payable {
        super.purchase(packCount, referrer);
        pass.mint(msg.sender, packCount);
    }

    function basePrice() public returns (uint) {
        return 450 finney;
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
        } else if (cardIndex == 3) {
            rarity = _getRarePlusRarity(rarityRandom);
        } else {
            rarity = _getCommonPlusRarity(rarityRandom);
        }

        purity = _getPurity(purityOne, purityTwo);
    
        proto = integration.getRandomCard(rarity, protoRandom);

        return (proto, purity);
    } 
    
}