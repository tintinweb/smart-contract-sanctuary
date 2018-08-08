pragma solidity ^0.4.18;

/// @title Interface for contracts conforming to ERC-721: Deed Standard
/// @author William Entriken (https://phor.net), et. al.
/// @dev Specification at https://github.com/ethereum/eips/XXXFinalUrlXXX
interface ERC721 {

    // COMPLIANCE WITH ERC-165 (DRAFT) /////////////////////////////////////////

    /// @dev ERC-165 (draft) interface signature for itself
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
    //     bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    /// @dev ERC-165 (draft) interface signature for ERC721
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
    //     bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    //     bytes4(keccak256(&#39;countOfDeeds()&#39;)) ^
    //     bytes4(keccak256(&#39;countOfDeedsByOwner(address)&#39;)) ^
    //     bytes4(keccak256(&#39;deedOfOwnerByIndex(address,uint256)&#39;)) ^
    //     bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    //     bytes4(keccak256(&#39;takeOwnership(uint256)&#39;));

    /// @notice Query a contract to see if it supports a certain interface
    /// @dev Returns `true` the interface is supported and `false` otherwise,
    ///  returns `true` for INTERFACE_SIGNATURE_ERC165 and
    ///  INTERFACE_SIGNATURE_ERC721, see ERC-165 for other interface signatures.
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

    // PUBLIC QUERY FUNCTIONS //////////////////////////////////////////////////

    /// @notice Find the owner of a deed
    /// @param _deedId The identifier for a deed we are inspecting
    /// @dev Deeds assigned to zero address are considered invalid, and
    ///  queries about them do throw.
    /// @return The non-zero address of the owner of deed `_deedId`, or `throw`
    ///  if deed `_deedId` is not tracked by this contract
    function ownerOf(uint256 _deedId) external view returns (address _owner);

    /// @notice Count deeds tracked by this contract
    /// @return A count of valid deeds tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function countOfDeeds() external view returns (uint256 _count);

    /// @notice Count all deeds assigned to an owner
    /// @dev Throws if `_owner` is the zero address, representing invalid deeds.
    /// @param _owner An address where we are interested in deeds owned by them
    /// @return The number of deeds owned by `_owner`, possibly zero
    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count);

    /// @notice Enumerate deeds assigned to an owner
    /// @dev Throws if `_index` >= `countOfDeedsByOwner(_owner)` or if
    ///  `_owner` is the zero address, representing invalid deeds.
    /// @param _owner An address where we are interested in deeds owned by them
    /// @param _index A counter less than `countOfDeedsByOwner(_owner)`
    /// @return The identifier for the `_index`th deed assigned to `_owner`,
    ///   (sort order not specified)
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

    // TRANSFER MECHANISM //////////////////////////////////////////////////////

    /// @dev This event emits when ownership of any deed changes by any
    ///  mechanism. This event emits when deeds are created (`from` == 0) and
    ///  destroyed (`to` == 0). Exception: during contract creation, any
    ///  transfers may occur without emitting `Transfer`. At the time of any transfer,
    ///  the "approved taker" is implicitly reset to the zero address.
    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);

    /// @dev The Approve event emits to log the "approved taker" for a deed -- whether
    ///  set for the first time, reaffirmed by setting the same value, or setting to
    ///  a new value. The "approved taker" is the zero address if nobody can take the
    ///  deed now or it is an address if that address can call `takeOwnership` to attempt
    ///  taking the deed. Any change to the "approved taker" for a deed SHALL cause
    ///  Approve to emit. However, an exception, the Approve event will not emit when
    ///  Transfer emits, this is because Transfer implicitly denotes the "approved taker"
    ///  is reset to the zero address.
    event Approval(address indexed owner, address indexed approved, uint256 indexed deedId);

    /// @notice Set the "approved taker" for your deed, or revoke approval by
    ///  setting the zero address. You may `approve` any number of times while
    ///  the deed is assigned to you, only the most recent approval matters. Emits
    ///  an Approval event.
    /// @dev Throws if `msg.sender` does not own deed `_deedId` or if `_to` ==
    ///  `msg.sender` or if `_deedId` is not a valid deed.
    /// @param _deedId The deed for which you are granting approval
    function approve(address _to, uint256 _deedId) external payable;

    /// @notice Become owner of a deed for which you are currently approved
    /// @dev Throws if `msg.sender` is not approved to become the owner of
    ///  `deedId` or if `msg.sender` currently owns `_deedId` or if `_deedId is not a
    ///  valid deed.
    /// @param _deedId The deed that is being transferred
    function takeOwnership(uint256 _deedId) external payable;
}

contract Ownable {
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract MonsterAccessControl {
    event ContractUpgrade(address newContract);

     // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public adminAddress;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }
}

// This contract stores all data on the blockchain
// only our other contracts can interact with this
// the data here will be valid for all eternity even if other contracts get updated
// this way we can make sure that our Monsters have a hard-coded value attached to them
// that no one including us can change(!)
contract MonstersData {
    address coreContract;

    struct Monster {
        // timestamp of block when this monster was spawned/created
        uint64 birthTime;

        // generation number
        // gen0 is the very first generation - the later monster spawn the less likely they are to have
        // special attributes and stats
        uint16 generation;

        uint16 mID; // this id (from 1 to 151) is responsible for everything visually like showing the real deal!
        bool tradeable;

        // breeding
        bool female;

        // is this monster exceptionally rare?
        bool shiny;
    }

    // lv1 base stats
    struct MonsterBaseStats {
        uint16 hp;
        uint16 attack;
        uint16 defense;
        uint16 spAttack;
        uint16 spDefense;
        uint16 speed;
    }

    struct Trainer {
        // timestamp of block when this player/trainer was created
        uint64 birthTime;

        // add username
        string username;

        // current area in the "world"
        uint16 currArea;

        address owner;
    }

    // take timestamp of block this game was created on the blockchain
    uint64 creationBlock = uint64(now);
}

contract MonstersBase is MonsterAccessControl, MonstersData {
    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a monster
    ///  ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);

    bool lockedMonsterCreator = false;

    MonsterAuction public monsterAuction;
    MonsterCreatorInterface public monsterCreator;

    function setMonsterCreatorAddress(address _address) external onlyAdmin {
        // only set this once so we (the devs) can&#39;t cheat!
        require(!lockedMonsterCreator);
        MonsterCreatorInterface candidateContract = MonsterCreatorInterface(_address);

        monsterCreator = candidateContract;
        lockedMonsterCreator = true;
    }

    // An approximation of currently how many seconds are in between blocks.
    uint256 public secondsPerBlock = 15;

    // array containing all monsters in existence
    Monster[] monsters;

    uint8[] areas;
    uint8 areaIndex = 0;

    mapping(address => Trainer) public addressToTrainer;
    /// @dev A mapping from monster IDs to the address that owns them. All monster have
    ///  some valid owner address, even gen0 monster are created with a non-zero owner.
    mapping (uint256 => address) public monsterIndexToOwner;
    // @dev A mapping from owner address to count of tokens that address owns.
    // Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public monsterIndexToApproved;
    mapping (uint256 => string) public monsterIdToNickname;
    mapping (uint256 => bool) public monsterIdToTradeable;
    mapping (uint256 => uint256) public monsterIdToGeneration;
    
    mapping (uint256 => uint8[7]) public monsterIdToIVs;

    // adds new area to world
    function _createArea() internal {
        areaIndex++;
        areas.push(areaIndex);
    }

    function _createMonster(uint256 _generation, address _owner, uint256 _mID, bool _tradeable,
        bool _female, bool _shiny) internal returns (uint)
    {

        Monster memory _monster = Monster({
            generation: uint16(_generation),
            birthTime: uint64(now),
            mID: uint16(_mID),
            tradeable: _tradeable,
            female: _female,
            shiny: _shiny
        });

        uint256 newMonsterId = monsters.push(_monster) - 1;

        require(newMonsterId == uint256(uint32(newMonsterId)));

        monsterIdToNickname[newMonsterId] = "";

        _transfer(0, _owner, newMonsterId);

        return newMonsterId;
    }

    function _createTrainer(string _username, uint16 _starterId, address _owner) internal returns (uint mon) {
        Trainer memory _trainer = Trainer({
            birthTime: uint64(now),
            username: string(_username),
             // sets to first area!,
            currArea: uint16(1),
            owner: address(_owner)
        });

        addressToTrainer[_owner] = _trainer;

        bool gender = monsterCreator.getMonsterGender();

        // starters cannot be traded and are not shiny
        if (_starterId == 1) {
            mon = _createMonster(0, _owner, 1, false, gender, false);
        } else if (_starterId == 2) {
            mon = _createMonster(0, _owner, 4, false, gender, false);
        } else if (_starterId == 3) {
            mon = _createMonster(0, _owner, 7, false, gender, false);
        }
    }

    function _moveToArea(uint16 _newArea, address player) internal {
        addressToTrainer[player].currArea = _newArea;
    }

    // assigns ownership of monster to address
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        monsterIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;

            // clear any previously approved ownership exchange
            delete monsterIndexToApproved[_tokenId];
        }

        // Emit Transfer event
        Transfer(_from, _to, _tokenId);
    }

    // Only admin can fix how many seconds per blocks are currently observed.
    function setSecondsPerBlock(uint256 secs) external onlyAdmin {
        //require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}

contract MonsterOwnership is MonstersBase, ERC721 {
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToOwner[_tokenId] == _claimant;
    }

    function _isTradeable(uint256 _tokenId) public view returns (bool) {
        return monsterIdToTradeable[_tokenId];
    }

    /// @dev Checks if a given address currently has transferApproval for a particular monster.
    /// @param _claimant the address we are confirming monster is approved for.
    /// @param _tokenId monster id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToApproved[_tokenId] == _claimant;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _tokenId) public payable {
        transferFrom(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(monsterIdToTradeable[_tokenId]);
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any monsters (except very briefly
        // after a gen0 monster is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        
        require(_owns(_from, _tokenId));
        // checks if _to was aproved
        require(_from == msg.sender || msg.sender == address(monsterAuction) || _approvedFor(_to, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return monsters.length;
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount > 0) {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMonsters = totalSupply();
            uint256 resultIndex = 0;

            uint256 monsterId;

            for (monsterId = 0; monsterId <= totalMonsters; monsterId++) {
                if (monsterIndexToOwner[monsterId] == _owner) {
                    result[resultIndex] = monsterId;
                    resultIndex++;
                }
            }

            return result;
        }

        return new uint256[](0);
    }

    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 =
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("countOfDeeds()")) ^
        bytes4(keccak256("countOfDeedsByOwner(address)")) ^
        bytes4(keccak256("deedOfOwnerByIndex(address,uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("takeOwnership(uint256)"));

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return _interfaceID == INTERFACE_SIGNATURE_ERC165 || _interfaceID == INTERFACE_SIGNATURE_ERC721;
    }

    function ownerOf(uint256 _deedId) external view returns (address _owner) {
        var owner = monsterIndexToOwner[_deedId];
        require(owner != address(0));
        return owner;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        monsterIndexToApproved[_tokenId] = _approved;
    }

    function countOfDeeds() external view returns (uint256 _count) {
        return totalSupply();
    }

    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count) {
        var arr = tokensOfOwner(_owner);
        return arr.length;
    }

    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId) {
        return tokensOfOwner(_owner)[_index];
    }

    function approve(address _to, uint256 _tokenId) external payable {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        monsterIndexToApproved[_tokenId] = _to;

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _deedId) external payable {
        transferFrom(this.ownerOf(_deedId), msg.sender, _deedId);
    }
}

contract MonsterAuctionBase {

    // Reference to contract tracking NFT ownership
    MonsterOwnership public nonFungibleContract;
    ChainMonstersCore public core;

    struct Auction {
        // current owner
        address seller;
        // price in wei
        uint256 price;
        // time when auction started
        uint64 startedAt;
        uint256 id;
    }

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping(uint256 => Auction) tokenIdToAuction;
    mapping(uint256 => address) public auctionIdToSeller;
    mapping (address => uint256) public ownershipAuctionCount;

    event AuctionCreated(uint256 tokenId, uint256 price, uint256 uID, address seller);
    event AuctionSuccessful(uint256 tokenId, uint256 price, address newOwner, uint256 uID);
    event AuctionCancelled(uint256 tokenId, uint256 uID);

    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.price),
            uint256(_auction.id),
            address(_auction.seller)
        );
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        Auction storage _auction = tokenIdToAuction[_tokenId];

        uint256 uID = _auction.id;

        _removeAuction(_tokenId);
        ownershipAuctionCount[_seller]--;
        _transfer(_seller, _tokenId);

        AuctionCancelled(_tokenId, uID);
    }

    function _buy(uint256 _tokenId, uint256 _bidAmount) internal returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        uint256 price = auction.price;
        require(_bidAmount >= price);

        address seller = auction.seller;
        uint256 uID = auction.id;

        // Auction Bid looks fine! so remove
        _removeAuction(_tokenId);

        ownershipAuctionCount[seller]--;

        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it&#39;s an
            // accident, they can call cancelAuction(). )
            if (seller != address(core)) {
                seller.transfer(sellerProceeds);
            }
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        msg.sender.transfer(bidExcess);

        // Tell the world!
        AuctionSuccessful(_tokenId, price, msg.sender, uID);

        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }
}

contract MonsterAuction is  MonsterAuctionBase, Ownable {
    bool public isMonsterAuction = true;
    uint256 public auctionIndex = 0;

    function MonsterAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        var candidateContract = MonsterOwnership(_nftAddress);

        nonFungibleContract = candidateContract;
        ChainMonstersCore candidateCoreContract = ChainMonstersCore(_nftAddress);
        core = candidateCoreContract;
    }

    // only possible to decrease ownerCut!
    function setOwnerCut(uint256 _cut) external onlyOwner {
        require(_cut <= ownerCut);
        ownerCut = _cut;
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        owner.transfer(balance);
    }

    function tokensInAuctionsOfOwner(address _owner) external view returns(uint256[] auctionTokens) {
        uint256 numAuctions = ownershipAuctionCount[_owner];

        uint256[] memory result = new uint256[](numAuctions);
        uint256 totalAuctions = core.totalSupply();
        uint256 resultIndex = 0;

        uint256 auctionId;

        for (auctionId = 0; auctionId <= totalAuctions; auctionId++) {
            Auction storage auction = tokenIdToAuction[auctionId];
            if (auction.seller == _owner) {
                result[resultIndex] = auctionId;
                resultIndex++;
            }
        }

        return result;
    }

    function createAuction(uint256 _tokenId, uint256 _price, address _seller) external {
        require(_seller != address(0));
        require(_price == uint256(_price));
        require(core._isTradeable(_tokenId));
        require(_owns(msg.sender, _tokenId));

        
        _escrow(msg.sender, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint256(_price),
            uint64(now),
            uint256(auctionIndex)
        );

        auctionIdToSeller[auctionIndex] = _seller;
        ownershipAuctionCount[_seller]++;

        auctionIndex++;
        _addAuction(_tokenId, auction);
    }

    function buy(uint256 _tokenId) external payable {
        //delete auctionIdToSeller[_tokenId];
        // buy will throw if the bid or funds transfer fails
        _buy (_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        address seller = auction.seller;
        require(msg.sender == seller);

        _cancelAuction(_tokenId, seller);
    }

    function getAuction(uint256 _tokenId) external view returns (address seller, uint256 price, uint256 startedAt) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        return (
            auction.seller,
            auction.price,
            auction.startedAt
        );
    }

    function getPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return auction.price;
    }
}

contract ChainMonstersAuction is MonsterOwnership {
    bool lockedMonsterAuction = false;

    function setMonsterAuctionAddress(address _address) external onlyAdmin {
        require(!lockedMonsterAuction);
        MonsterAuction candidateContract = MonsterAuction(_address);

        require(candidateContract.isMonsterAuction());

        monsterAuction = candidateContract;
        lockedMonsterAuction = true;
    }

    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 5000;

    // Counts the number of monster the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    // its stats are completely dependent on the spawn alghorithm
    function createPromoMonster(uint256 _mId, address _owner) external onlyAdmin {
        // during generation we have to keep in mind that we have only 10,000 tokens available
        // which have to be divided by 151 monsters, some rarer than others
        // see WhitePaper for gen0/promo monster plan
        
        // sanity check that this monster ID is actually in game yet
        require(monsterCreator.baseStats(_mId, 1) > 0);
        
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;

        uint8[7] memory ivs = uint8[7](monsterCreator.getGen0IVs());

        bool gender = monsterCreator.getMonsterGender();
        
        bool shiny = false;
        if (ivs[6] == 1) {
            shiny = true;
        }
        uint256 monsterId = _createMonster(0, _owner, _mId, true, gender, shiny);
        monsterIdToTradeable[monsterId] = true;

        monsterIdToIVs[monsterId] = ivs;
    }

    function createGen0Auction(uint256 _mId, uint256 price) external onlyAdmin {
         // sanity check that this monster ID is actually in game yet
        require(monsterCreator.baseStats(_mId, 1) > 0);
        
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint8[7] memory ivs = uint8[7](monsterCreator.getGen0IVs());

        bool gender = monsterCreator.getMonsterGender();
        
        bool shiny = false;
        if (ivs[6] == 1) {
            shiny = true;
        }
        
        uint256 monsterId = _createMonster(0, this, _mId, true, gender, shiny);
        monsterIdToTradeable[monsterId] = true;

        _approve(monsterId, monsterAuction);

        monsterIdToIVs[monsterId] = ivs;

        monsterAuction.createAuction(monsterId, price, address(this));

        gen0CreatedCount++;
    }
}

// used during launch for world championship
// can and will be upgraded during development with new battle system!
// this is just to give players something to do and test their monsters
// also demonstrates how we can build up more mechanics on top of our locked core contract!
contract MonsterChampionship is Ownable {

    bool public isMonsterChampionship = true;

    ChainMonstersCore core;

    // list of top ten
    address[10] topTen;

    // holds the address current "world" champion
    address public currChampion;

    mapping (address => uint256) public addressToPowerlevel;
    mapping (uint256 => address) public rankToAddress;
    
    // try to beat every other player in the top10 with your strongest monster!
    // effectively looping through all top10 players, beating them one by one
    // and if strong enough placing your in the top10 as well
    function contestChampion(uint256 _tokenId) external {
        //uint maxIndex = 9;

        // fail tx if player is already champion!
        // in theory players could increase their powerlevel by contesting themselves but
        // this check stops that from happening so other players have the chance to
        // become the temporary champion!
        if (currChampion == msg.sender) {
            revert();
        }

        require(core.isTrainer(msg.sender));
        require(core.monsterIndexToOwner(_tokenId) == msg.sender);

       
        
        var (n, m, stats, l, k, d) =  core.getMonster(_tokenId);
        //uint8[7] ivs = core.monsterIdToIVs(_tokenId);
        
        uint256 myPowerlevel = uint256(stats[0]) + uint256(stats[1]) + uint256(stats[2]) + uint256(stats[3]) + uint256(stats[4]) + uint256(stats[5]);
        

        // checks if this transaction is useless
        // since we can&#39;t fight against ourself!
        // also stops reentrancy attacks
        require(myPowerlevel > addressToPowerlevel[msg.sender]);

        uint myRank = 0;

        for (uint i = 0; i <= 9; i++) {
            if (myPowerlevel > addressToPowerlevel[topTen[i]]) {
                // you have beaten this one so increase temporary rank
                myRank = i;

                if (myRank == 9) {
                    currChampion = msg.sender;
                }
            }
        }

        addressToPowerlevel[msg.sender] = myPowerlevel;

        address[10] storage newTopTen = topTen;

        if (currChampion == msg.sender) {
            for (uint j = 0; j < 9; j++) {
                // remove ourselves from this list in case
                if (newTopTen[j] == msg.sender) {
                    newTopTen[j] = 0x0;
                    break;
                }
            }
        }

        for (uint x = 0; x <= myRank; x++) {
            if (x == myRank) {
                newTopTen[x] = msg.sender;
            } else {
                if (x < 9)
                    newTopTen[x] = topTen[x+1];
            }
        }

        topTen = newTopTen;
    }

    function getTopPlayers() external view returns (address[10] players) {
        players = topTen;
    }

    function MonsterChampionship(address coreContract) public {
        core = ChainMonstersCore(coreContract);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        owner.transfer(balance);
    }
}


// where the not-so-much "hidden" magic happens
contract MonsterCreatorInterface is Ownable {
    uint8 public lockedMonsterStatsCount = 0;
    uint nonce = 0;

    function rand(uint16 min, uint16 max) public returns (uint16) {
        nonce++;
        uint16 result = (uint16(keccak256(block.blockhash(block.number-1), nonce))%max);

        if (result < min) {
            result = result+min;
        }

        return result;
    }

    mapping(uint256 => uint8[8]) public baseStats;

    function addBaseStats(uint256 _mId, uint8[8] data) external onlyOwner {
        // lock" the stats down forever
        // since hp is never going to be 0 this is a valid check
        // so we have to be extra careful when adding new baseStats!
        require(data[0] > 0);
        require(baseStats[_mId][0] == 0);
        baseStats[_mId] = data;
    }

    function _addBaseStats(uint256 _mId, uint8[8] data) internal {
        baseStats[_mId] = data;
        lockedMonsterStatsCount++;
    }

    function MonsterCreatorInterface() public {
       // these monsters are already down and "locked" down stats/design wise
        _addBaseStats(1, [45, 49, 49, 65, 65, 45, 12, 4]);
        _addBaseStats(2, [60, 62, 63, 80, 80, 60, 12, 4]);
        _addBaseStats(3, [80, 82, 83, 100, 100, 80, 12, 4]);
        _addBaseStats(4, [39, 52, 43, 60, 50, 65, 10, 6]);
        _addBaseStats(5, [58, 64, 58, 80, 65, 80, 10, 6]);
        _addBaseStats(6, [78, 84, 78, 109, 85, 100, 10, 6]);
        _addBaseStats(7, [44, 48, 65, 50, 64, 43, 11, 14]);
        _addBaseStats(8, [59, 63, 80, 65, 80, 58, 11, 14]);
        _addBaseStats(9, [79, 83, 100, 85, 105, 78, 11, 14]);
        _addBaseStats(10, [40, 35, 30, 20, 20, 50, 7, 4]);

        _addBaseStats(149, [55, 50, 45, 135, 95, 120, 8, 14]);
        _addBaseStats(150, [91, 134, 95, 100, 100, 80, 2, 5]);
        _addBaseStats(151, [100, 100, 100, 100, 100, 100, 5, 19]);
    }

    // this serves as a lookup for new monsters to be generated since all monsters
    // of the same id share the base stats
    // also makes it possible to only store the monsterId on core and change this one
    // during evolution process to save gas and additional transactions
    function getMonsterStats( uint256 _mID) external constant returns(uint8[8] stats) {
        stats[0] = baseStats[_mID][0];
        stats[1] = baseStats[_mID][1];
        stats[2] = baseStats[_mID][2];
        stats[3] = baseStats[_mID][3];
        stats[4] = baseStats[_mID][4];
        stats[5] = baseStats[_mID][5];
        stats[6] = baseStats[_mID][6];
        stats[7] = baseStats[_mID][7];
    }

    function getMonsterGender () external returns(bool female) {
        uint16 femaleChance = rand(0, 100);

        if (femaleChance >= 50) {
            female = true;
        }
    }

    // generates randomized IVs for a new monster
    function getMonsterIVs() external returns(uint8[7] ivs) {
        bool shiny = false;

        uint16 chance = rand(1, 8192);

        if (chance == 42) {
            shiny = true;
        }

        // IVs range between 0 and 31
        // stat range modified for shiny monsters!
        if (shiny) {
            ivs[0] = uint8(rand(10, 31));
            ivs[1] = uint8(rand(10, 31));
            ivs[2] = uint8(rand(10, 31));
            ivs[3] = uint8(rand(10, 31));
            ivs[4] = uint8(rand(10, 31));
            ivs[5] = uint8(rand(10, 31));
            ivs[6] = 1;

        } else {
            ivs[0] = uint8(rand(0, 31));
            ivs[1] = uint8(rand(0, 31));
            ivs[2] = uint8(rand(0, 31));
            ivs[3] = uint8(rand(0, 31));
            ivs[4] = uint8(rand(0, 31));
            ivs[5] = uint8(rand(0, 31));
            ivs[6] = 0;
        }
    }

    // gen0 monsters profit from shiny boost while shiny gen0s have potentially even higher IVs!
    // further increasing the rarity by also doubling the shiny chance!
    function getGen0IVs() external returns (uint8[7] ivs) {
        bool shiny = false;

        uint16 chance = rand(1, 4096);

        if (chance == 42) {
            shiny = true;
        }

        if (shiny) {
            ivs[0] = uint8(rand(15, 31));
            ivs[1] = uint8(rand(15, 31));
            ivs[2] = uint8(rand(15, 31));
            ivs[3] = uint8(rand(15, 31));
            ivs[4] = uint8(rand(15, 31));
            ivs[5] = uint8(rand(15, 31));
            ivs[6] = 1;
        } else {
            ivs[0] = uint8(rand(10, 31));
            ivs[1] = uint8(rand(10, 31));
            ivs[2] = uint8(rand(10, 31));
            ivs[3] = uint8(rand(10, 31));
            ivs[4] = uint8(rand(10, 31));
            ivs[5] = uint8(rand(10, 31));
            ivs[6] = 0;
        }
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        owner.transfer(balance);
    }
}

contract GameLogicContract {
    bool public isGameLogicContract = true;

    function GameLogicContract() public {

    }
}


contract OmegaContract {
    bool public isOmegaContract = true;

    function OmegaContract() public {

    }
}

contract ChainMonstersCore is ChainMonstersAuction, Ownable {
    // using a bool to enable us to prepare the game
    bool hasLaunched = false;

    // this address will hold future gamelogic in place
    address gameContract;

    // this contract
    address omegaContract;

    function ChainMonstersCore() public {
        adminAddress = msg.sender;

        _createArea(); // area 1
        _createArea(); // area 2
    }

    // we don&#39;t know the exact interfaces yet so use the lockedMonsterStats value to determine if the game is "ready"
    // see WhitePaper for explaination for our upgrade and development roadmap
    function setGameLogicContract(address _candidateContract) external onlyOwner {
        require(monsterCreator.lockedMonsterStatsCount() == 151);

        require(GameLogicContract(_candidateContract).isGameLogicContract());

        gameContract = _candidateContract;
    }

    function setOmegaContract(address _candidateContract) external onlyOwner {
        require(OmegaContract(_candidateContract).isOmegaContract());
        omegaContract = _candidateContract;
    }

    // omega contract takes care of all neccessary checks so assume that this is correct(!)
    function evolveMonster(uint256 _tokenId, uint16 _toMonsterId) external {
        require(msg.sender == omegaContract);

        // retrieve current monster struct
        Monster storage mon = monsters[_tokenId];

        // evolving only changes monster ID since this is responsible for base Stats
        // an evolved monster keeps its gender, generation, IVs and EVs
        mon.mID = _toMonsterId;
    }

    // only callable by gameContract after the full game is launched
    // since all additional monsters after the promo/gen0 ones need to use this coreContract
    // contract as well we have to prepare this core for our future updates where
    // players can freely roam the world and hunt ChainMonsters thus generating more
    function spawnMonster(uint256 _mId, address _owner) external {
        require(msg.sender == gameContract);

        uint8[7] memory ivs = uint8[7](monsterCreator.getMonsterIVs());

        bool gender = monsterCreator.getMonsterGender();

        bool shiny = false;
        if (ivs[6] == 1) {
            shiny = true;
        }
        
        // important to note that the IV generators do not use Gen0 methods and are Generation 1
        // this means there won&#39;t be more than the 10,000 Gen0 monsters sold during the development through the marketplace
        uint256 monsterId = _createMonster(1, _owner, _mId, false, gender, shiny);
        monsterIdToTradeable[monsterId] = true;

        monsterIdToIVs[monsterId] = ivs;
    }

    // used to add playable content to the game
    // monsters will only spawn in certain areas so some are locked on release
    // due to the game being in active development on "launch"
    // each monster has a maximum number of 3 areas where it can appear
    function createArea() public onlyAdmin {
        _createArea();
    }

    function createTrainer(string _username, uint16 _starterId) public {
        require(hasLaunched);

        // only one trainer/account per ethereum address
        require(addressToTrainer[msg.sender].owner == 0);

        // valid input check
        require(_starterId == 1 || _starterId == 2 || _starterId == 3);

        uint256 mon = _createTrainer(_username, _starterId, msg.sender);

        // due to stack limitations we have to assign the IVs here:
        monsterIdToIVs[mon] = monsterCreator.getMonsterIVs();
    }

    function changeUsername(string _name) public {
        require(addressToTrainer[msg.sender].owner == msg.sender);
        addressToTrainer[msg.sender].username = _name;
    }

    function changeMonsterNickname(uint256 _tokenId, string _name) public {
        // users won&#39;t be able to rename a monster that is part of an auction
        require(_owns(msg.sender, _tokenId));

        // some string checks...?
        monsterIdToNickname[_tokenId] = _name;
    }

    function moveToArea(uint16 _newArea) public {
        require(addressToTrainer[msg.sender].currArea > 0);

        // never allow anyone to move to area 0 or below since this is used
        // to determine if a trainer profile exists in another method!
        require(_newArea > 0);

        // make sure that this area exists yet!
        require(areas.length >= _newArea);

        // when player is not stuck doing something else he can move freely!
        _moveToArea(_newArea, msg.sender);
    }

    // to be changed to retrieve current stats!
    function getMonster(uint256 _id) external view returns (
        uint256 birthTime, uint256 generation, uint8[8] stats,
        uint256 mID, bool tradeable, uint256 uID)
    {
        Monster storage mon = monsters[_id];
        birthTime = uint256(mon.birthTime);
        generation = mon.generation; // hardcoding due to stack too deep error
        mID = uint256(mon.mID);
        tradeable = bool(mon.tradeable);

        // these values are retrieved from monsterCreator
        stats = uint8[8](monsterCreator.getMonsterStats(uint256(mon.mID)));

        // hack to overcome solidity&#39;s stack limitation in monster struct....
        uID = _id;
    }

    function isTrainer(address _check) external view returns (bool isTrainer) {
        Trainer storage trainer = addressToTrainer[_check];

        return (trainer.currArea > 0);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;

        owner.transfer(balance);
    }

    // after we have setup everything we can unlock the game
    // for public
    function launchGame() external onlyOwner {
        hasLaunched = true;
    }
}