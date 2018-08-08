pragma solidity ^0.4.19;

// DopeRaider Narcos Contract
// by gasmasters.io
// contact: team@doperaider.com

contract DistrictsCoreInterface {
  // callable by other contracts to control economy
  function isDopeRaiderDistrictsCore() public pure returns (bool);
  function increaseDistrictWeed(uint256 _district, uint256 _quantity) public;
  function increaseDistrictCoke(uint256 _district, uint256 _quantity) public;
  function distributeRevenue(uint256 _district , uint8 _splitW, uint8 _splitC) public payable;
  function getNarcoLocation(uint256 _narcoId) public view returns (uint8 location);
}

/// @title sale clock auction interface
contract SaleClockAuction {
  function isSaleClockAuction() public pure returns (bool);
  function createAuction(uint256 _tokenId,  uint256 _startingPrice,uint256 _endingPrice,uint256 _duration,address _seller)public;
  function withdrawBalance() public;
  function averageGen0SalePrice() public view returns (uint256);

}


//// @title A facet of NarcoCore that manages special access privileges.
contract NarcoAccessControl {
    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function withdrawBalance() external onlyCLevel {
        msg.sender.transfer(address(this).balance);
    }


    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCLevel whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /// @dev The address of the calling contract
    address public districtContractAddress;

    DistrictsCoreInterface public districtsCore;

    function setDistrictAddress(address _address) public onlyCLevel {
        _setDistrictAddresss(_address);
    }

    function _setDistrictAddresss(address _address) internal {
      DistrictsCoreInterface candidateContract = DistrictsCoreInterface(_address);
      require(candidateContract.isDopeRaiderDistrictsCore());
      districtsCore = candidateContract;
      districtContractAddress = _address;
    }


    modifier onlyDopeRaiderContract() {
        require(msg.sender == districtContractAddress);
        _;
    }




}

/// @title Base contract for DopeRaider. Holds all common structs, events and base variables.
contract NarcoBase is NarcoAccessControl {
    /*** EVENTS ***/

    event NarcoCreated(address indexed owner, uint256 narcoId, string genes);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a narcos
    ///  ownership is assigned, including newly created narcos.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


 /*** DATA TYPES ***/

    // consumable indexes
    /*
    uint constant gasIndex = 0;
    uint constant seedsIndex = 1;
    uint constant chemicalsIndex = 2;
    uint constant ammoIndex = 3;

    // skills indexes  - each skill can range from 1 - 10 in level
    uint constant speedIndex = 0; // speed of travel
    uint constant growIndex = 1; // speed/yield of grow
    uint constant refineIndex = 2; // refine coke
    uint constant attackIndex = 3; // attack
    uint constant defenseIndex = 4; // defense
    uint constant capacityIndex = 5; // how many items can be carried.

    // stat indexes
    uint constant dealsCompleted = 0; // dealsCompleted
    uint constant weedGrowCompleted = 1; // weedGrowCompleted
    uint constant cokeRefineCompleted = 2; // refineCompleted
    uint constant attacksSucceeded = 3; // attacksSucceeded
    uint constant defendedSuccessfully = 4; defendedSuccessfully
    uint constant raidsCompleted = 5; // raidsCompleted
    uint constant escapeHijack = 6; // escapeHijack
    uint constant travelling = 7; // traveller
    uint constant recruited = 8; // recruitment
*/


    /// @dev The main Narco struct. Every narco in DopeRaider is represented by a copy
    ///  of this structure.
    struct Narco {
        // The Narco&#39;s genetic code is packed into these 256-bits.
        string genes; // represents his avatar
        string narcoName;
        // items making level
        uint16 [9] stats;
        // inventory totals
        uint16 weedTotal;
        uint16 cokeTotal;
        uint8 [4] consumables; // gas, seeds, chemicals, ammo
        uint16 [6] skills;   // travel time, grow, refine, attack, defend carry
        uint256 [6] cooldowns; // skill cooldown periods speed, grow, refine, attack, others if needed
        uint8 homeLocation;
    }

    /*** STORAGE ***/

    /// @dev An array containing the Narco struct for all Narcos in existence. The ID
    ///  of each narco is actually an index into this array.
    Narco[] narcos;

    /// @dev A mapping from  narco IDs to the address that owns them. All  narcos have
    ///  some valid owner address, even gen0  narcos are created with a non-zero owner.
    mapping (uint256 => address) public narcoIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from NarcoIDs to an address that has been approved to call
    ///  transferFrom(). A zero value means no approval is outstanding.
    mapping (uint256 => address) public  narcoIndexToApproved;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // since the number of  narcos is capped to 2^32
        // there is no way to overflow this
        ownershipTokenCount[_to]++;
        narcoIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete narcoIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    // Will generate a new Narco and generate the event
    function _createNarco(
        string _genes,
        string _name,
        address _owner
    )
        internal
        returns (uint)
    {

        uint16[6] memory randomskills= [
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+31)
        ];

        uint256[6] memory cools;
        uint16[9] memory nostats;

        Narco memory _narco = Narco({
            genes: _genes,
            narcoName: _name,
            cooldowns: cools,
            stats: nostats,
            weedTotal: 0,
            cokeTotal: 0,
            consumables: [4,6,2,1],
            skills: randomskills,
            homeLocation: uint8(random(6)+1)
        });

        uint256 newNarcoId = narcos.push(_narco) - 1;
        require(newNarcoId <= 4294967295);

        // raid character (token 0) live in 7 and have random special skills
        if (newNarcoId==0){
            narcos[0].homeLocation=7; // in vice island
            narcos[0].skills[4]=800; // defense
            narcos[0].skills[5]=65535; // carry
        }

        NarcoCreated(_owner, newNarcoId, _narco.genes);
        _transfer(0, _owner, newNarcoId);


        return newNarcoId;
    }

    function subToZero(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b <= a){
          return a - b;
        }else{
          return 0;
        }
      }

    function getRemainingCapacity(uint256 _narcoId) public view returns (uint16 capacity){
        uint256 usedCapacity = narcos[_narcoId].weedTotal + narcos[_narcoId].cokeTotal + narcos[_narcoId].consumables[0]+narcos[_narcoId].consumables[1]+narcos[_narcoId].consumables[2]+narcos[_narcoId].consumables[3];
        capacity = uint16(subToZero(uint256(narcos[_narcoId].skills[5]), usedCapacity));
    }

    // respect it&#39;s called now
    function getLevel(uint256 _narcoId) public view returns (uint16 rank){

    /*
      dealsCompleted = 0; // dealsCompleted
      weedGrowCompleted = 1; // weedGrowCompleted
      cokeRefineCompleted = 2; // refineCompleted
      attacksSucceeded = 3; // attacksSucceeded
      defendedSuccessfully = 4; defendedSuccessfully
      raidsCompleted = 5; // raidsCompleted
      escapeHijack = 6; // escapeHijack
      travel = 7; // travelling
    */

        rank =  (narcos[_narcoId].stats[0]/12)+
                 (narcos[_narcoId].stats[1]/4)+
                 (narcos[_narcoId].stats[2]/4)+
                 (narcos[_narcoId].stats[3]/6)+
                 (narcos[_narcoId].stats[4]/6)+
                 (narcos[_narcoId].stats[5]/1)+
                 (narcos[_narcoId].stats[7]/12)
                 ;
    }

    // pseudo random - but does that matter?
    uint64 _seed = 0;
    function random(uint64 upper) private returns (uint64 randomNumber) {
       _seed = uint64(keccak256(keccak256(block.blockhash(block.number-1), _seed), now));
       return _seed % upper;
     }


    // never call this from a contract
    /// @param _owner The owner whose tokens we are interested in.
    function narcosByOwner(address _owner) public view returns(uint256[] ownedNarcos) {
       uint256 tokenCount = ownershipTokenCount[_owner];
        uint256 totalNarcos = narcos.length - 1;
        uint256[] memory result = new uint256[](tokenCount);
        uint256 narcoId;
        uint256 resultIndex=0;
        for (narcoId = 0; narcoId <= totalNarcos; narcoId++) {
          if (narcoIndexToOwner[narcoId] == _owner) {
            result[resultIndex] = narcoId;
            resultIndex++;
          }
        }
        return result;
    }


}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

/// @title The facet of the DopeRaider core contract that manages ownership, ERC-721 (draft) compliant.
contract NarcoOwnership is NarcoBase, ERC721 {
    string public name = "DopeRaider";
    string public symbol = "DOPR";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

    /// @dev Checks if a given address is the current owner of a particular narco.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId narco id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return narcoIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular narco.
    /// @param _claimant the address we are confirming narco is approved for.
    /// @param _tokenId narco id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return narcoIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event.
    function _approve(uint256 _tokenId, address _approved) internal {
        narcoIndexToApproved[_tokenId] = _approved;
    }


    /// @notice Returns the number of narcos owned by a specific address.
    /// @param _owner The owner address to check.
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a narco to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  DopeRaider specifically) or your narco may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the narco to transfer.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public

    {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific narco via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the narco that can be transferred if this call succeeds.
    function approve(
        address _to,
        uint256 _tokenId
    )
        public

    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a narco owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the narco to be transfered.
    /// @param _to The address that should take ownership of the narco. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the narco to be transferred.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public

    {
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        require(_to != address(0));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return narcos.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = narcoIndexToOwner[_tokenId];

        require(owner != address(0));
    }



}


// this helps with district functionality
// it gives the ability to an external contract to do the following:
// * update narcos stats
contract NarcoUpdates is NarcoOwnership {

    function updateWeedTotal(uint256 _narcoId, bool _add, uint16 _total) public onlyDopeRaiderContract {
      if(_add==true){
        narcos[_narcoId].weedTotal+= _total;
      }else{
        narcos[_narcoId].weedTotal-= _total;
      }
    }

    function updateCokeTotal(uint256 _narcoId, bool _add, uint16 _total) public onlyDopeRaiderContract {
       if(_add==true){
        narcos[_narcoId].cokeTotal+= _total;
      }else{
        narcos[_narcoId].cokeTotal-= _total;
      }
    }

    function updateConsumable(uint256 _narcoId, uint256 _index, uint8 _new) public onlyDopeRaiderContract  {
      narcos[_narcoId].consumables[_index] = _new;
    }

    function updateSkill(uint256 _narcoId, uint256 _index, uint16 _new) public onlyDopeRaiderContract  {
      narcos[_narcoId].skills[_index] = _new;
    }

    function incrementStat(uint256 _narcoId , uint256 _index) public onlyDopeRaiderContract  {
      narcos[_narcoId].stats[_index]++;
    }

    function setCooldown(uint256 _narcoId , uint256 _index , uint256 _new) public onlyDopeRaiderContract  {
      narcos[_narcoId].cooldowns[_index]=_new;
    }

}

/// @title Handles creating auctions for sale of narcos.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract NarcoAuction is NarcoUpdates {
    SaleClockAuction public saleAuction;

    function setSaleAuctionAddress(address _address) public onlyCLevel {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _narcoId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If narco is already on any auction, this will throw
        // because it will be owned by the auction contract
        require(_owns(msg.sender, _narcoId));
        _approve(_narcoId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer approval after escrowing the narco.
        saleAuction.createAuction(
            _narcoId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Transfers the balance of the sale auction contract
    /// to the DopeRaiderCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
    }
}


/// @title all functions related to creating narcos
contract NarcoMinting is NarcoAuction {

    // Limits the number of narcos the contract owner can ever create.
    uint256 public promoCreationLimit = 200;
    uint256 public gen0CreationLimit = 5000;

    // Constants for gen0 auctions.
    uint256 public gen0StartingPrice = 1 ether;
    uint256 public gen0EndingPrice = 20 finney;
    uint256 public gen0AuctionDuration = 1 days;

    // Counts the number of narcos the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    /// @dev we can create promo narco, up to a limit
    function createPromoNarco(
        string _genes,
        string _name,
        address _owner
    ) public onlyCLevel {
        if (_owner == address(0)) {
             _owner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);
        require(gen0CreatedCount < gen0CreationLimit);

        promoCreatedCount++;
        gen0CreatedCount++;

        _createNarco(_genes, _name, _owner);
    }

    /// @dev Creates a new gen0 narco with the given genes and
    ///  creates an auction for it.
    function createGen0Auction(
       string _genes,
        string _name
    ) public onlyCLevel {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 narcoId = _createNarco(_genes,_name,address(this));

        _approve(narcoId, saleAuction);

        saleAuction.createAuction(
            narcoId,
            _computeNextGen0Price(),
            gen0EndingPrice,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

    /// @dev Computes the next gen0 auction starting price, given
    ///  the average of the past 4 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // sanity check to ensure we don&#39;t overflow arithmetic (this big number is 2^128-1).
        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}


/// @title DopeRaider: Collectible, narcos on the Ethereum blockchain.
/// @dev The main DopeRaider contract
contract DopeRaiderCore is NarcoMinting {

    // This is the main DopeRaider contract. We have several seperately-instantiated  contracts
    // that handle auctions, districts and the creation of new narcos. By keeping
    // them in their own contracts, we can upgrade them without disrupting the main contract that tracks
    // narco ownership.
    //
    //      - NarcoBase: This is where we define the most fundamental code shared throughout the core
    //             functionality. This includes our main data storage, constants and data types, plus
    //             internal functions for managing these items.
    //
    //      - NarcoAccessControl: This contract manages the various addresses and constraints for operations
    //             that can be executed only by specific roles. Namely CEO, CFO and COO.
    //
    //      - NarcoOwnership: This provides the methods required for basic non-fungible token
    //             transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
    //
    //      - NarcoUpdates: This file contains the methods necessary to allow a separate contract to update narco stats
    //
    //      - NarcoAuction: Here we have the public methods for auctioning or bidding on narcos.
    //             The actual auction functionality is handled in a sibling sales contract,
    //             while auction creation and bidding is mostly mediated through this facet of the core contract.
    //
    //      - NarcoMinting: This final facet contains the functionality we use for creating new gen0 narcos.
    //             We can make up to 4096 "promo" narcos

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    bool public gamePaused = true;

    modifier whenGameNotPaused() {
        require(!gamePaused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenGamePaused {
        require(gamePaused);
        _;
    }

    function pause() public onlyCLevel whenGameNotPaused {
        gamePaused = true;
    }

    function unpause() public onlyCLevel whenGamePaused {
        // can&#39;t unpause if contract was upgraded
        gamePaused = false;
    }


    // EVENTS
    event GrowWeedCompleted(uint256 indexed narcoId, uint yield);
    event RefineCokeCompleted(uint256 indexed narcoId, uint yield);

    function DopeRaiderCore() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) public onlyCLevel whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it&#39;s from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(msg.sender == address(saleAuction));
    }

    /// @param _id The ID of the narco of interest.

   function getNarco(uint256 _id)
        public
        view
        returns (
        string  narcoName,
        uint256 weedTotal,
        uint256 cokeTotal,
        uint16[6] skills,
        uint8[4] consumables,
        string genes,
        uint8 homeLocation,
        uint16 level,
        uint256[6] cooldowns,
        uint256 id,
        uint16 [9] stats
    ) {
        Narco storage narco = narcos[_id];
        narcoName = narco.narcoName;
        weedTotal = narco.weedTotal;
        cokeTotal = narco.cokeTotal;
        skills = narco.skills;
        consumables = narco.consumables;
        genes = narco.genes;
        homeLocation = narco.homeLocation;
        level = getLevel(_id);
        cooldowns = narco.cooldowns;
        id = _id;
        stats = narco.stats;
    }

    uint256 public changeIdentityNarcoRespect = 30;
    function setChangeIdentityNarcoRespect(uint256 _respect) public onlyCLevel {
      changeIdentityNarcoRespect=_respect;
    }

    uint256 public personalisationCost = 0.01 ether; // pimp my narco
    function setPersonalisationCost(uint256 _cost) public onlyCLevel {
      personalisationCost=_cost;
    }
    function updateNarco(uint256 _narcoId, string _genes, string _name) public payable whenGameNotPaused {
       require(getLevel(_narcoId)>=changeIdentityNarcoRespect); // minimum level to recruit a narco
       require(msg.sender==narcoIndexToOwner[_narcoId]); // can&#39;t be moving other peoples narcos about
       require(msg.value>=personalisationCost);
       narcos[_narcoId].genes = _genes;
       narcos[_narcoId].narcoName = _name;
    }

    uint256 public respectRequiredToRecruit = 150;

    function setRespectRequiredToRecruit(uint256 _respect) public onlyCLevel {
      respectRequiredToRecruit=_respect;
    }

    function recruitNarco(uint256 _narcoId, string _genes, string _name) public whenGameNotPaused {
       require(msg.sender==narcoIndexToOwner[_narcoId]); // can&#39;t be moving other peoples narcos about
       require(getLevel(_narcoId)>=respectRequiredToRecruit); // minimum level to recruit a narco
       require(narcos[_narcoId].stats[8]<getLevel(_narcoId)/respectRequiredToRecruit); // must have recruited < respect / required reqpect (times)
      _createNarco(_genes,_name, msg.sender);
      narcos[_narcoId].stats[8]+=1; // increase number recruited
    }

   // crafting section
    uint256 public growCost = 0.003 ether;
    function setGrowCost(uint256 _cost) public onlyCLevel{
      growCost=_cost;
    }

    function growWeed(uint256 _narcoId) public payable whenGameNotPaused{
         require(msg.sender==narcoIndexToOwner[_narcoId]); // can&#39;t be moving other peoples narcos about
         require(msg.value>=growCost);
         require(now>narcos[_narcoId].cooldowns[1]); //cooldown must have expired
         uint16 growSkillLevel = narcos[_narcoId].skills[1]; // grow
         uint16 maxYield = 9 + growSkillLevel; // max amount can be grown based on skill
         uint yield = min(narcos[_narcoId].consumables[1],maxYield);
         require(yield>0); // gotta produce something

         // must be home location
         uint8 district = districtsCore.getNarcoLocation(_narcoId);
         require(district==narcos[_narcoId].homeLocation);

         // do the crafting
         uint256 cooldown = now + ((910-(10*growSkillLevel))* 1 seconds); //calculate cooldown switch to minutes later

         narcos[_narcoId].cooldowns[1]=cooldown;
         // use all available  - for now , maybe later make optional
         narcos[_narcoId].consumables[1]=uint8(subToZero(uint256(narcos[_narcoId].consumables[1]),yield));
         narcos[_narcoId].weedTotal+=uint8(yield);

         narcos[_narcoId].stats[1]+=1; // update the statistic for grow
         districtsCore.increaseDistrictWeed(district , yield);
         districtsCore.distributeRevenue.value(growCost)(uint256(district),50,50); // distribute the revenue to districts pots
         GrowWeedCompleted(_narcoId, yield); // notification event
    }


    uint256 public refineCost = 0.003 ether;
    function setRefineCost(uint256 _cost) public onlyCLevel{
      refineCost=_cost;
    }

    function refineCoke(uint256 _narcoId) public payable whenGameNotPaused{
         require(msg.sender==narcoIndexToOwner[_narcoId]); // can&#39;t be moving other peoples narcos about
         require(msg.value>=refineCost);
         require(now>narcos[_narcoId].cooldowns[2]); //cooldown must have expired
         uint16 refineSkillLevel = narcos[_narcoId].skills[2]; // refine
         uint16 maxYield = 3+(refineSkillLevel/3); // max amount can be grown based on skill
         uint yield = min(narcos[_narcoId].consumables[2],maxYield);
         require(yield>0); // gotta produce something

         // must be home location
         uint8 district = districtsCore.getNarcoLocation(_narcoId);
         require(district==narcos[_narcoId].homeLocation);

         // do the crafting
        // uint256 cooldown = now + min(3 minutes,((168-(2*refineSkillLevel))* 1 seconds)); // calculate cooldown
         uint256 cooldown = now + ((910-(10*refineSkillLevel))* 1 seconds); // calculate cooldown

         narcos[_narcoId].cooldowns[2]=cooldown;
         // use all available  - for now , maybe later make optional
         narcos[_narcoId].consumables[2]=uint8(subToZero(uint256(narcos[_narcoId].consumables[2]),yield));
         narcos[_narcoId].cokeTotal+=uint8(yield);

         narcos[_narcoId].stats[2]+=1;
         districtsCore.increaseDistrictCoke(district, yield);
         districtsCore.distributeRevenue.value(refineCost)(uint256(district),50,50); // distribute the revenue to districts pots
         RefineCokeCompleted(_narcoId, yield); // notification event

    }


    function min(uint a, uint b) private pure returns (uint) {
             return a < b ? a : b;
    }

}