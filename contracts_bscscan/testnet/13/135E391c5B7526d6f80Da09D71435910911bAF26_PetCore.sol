/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-27
*/

pragma solidity ^0.5.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract KRC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

interface IGeneScience {

    /// @dev given genes of pet 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) external view returns (uint256);
}

interface IKRC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IPetCore {
    function createPet(address _owner) external;
}


contract PetAccessControl is Ownable {

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() external onlyOwner whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

contract PetBase is PetAccessControl {

    /// @dev The Birth event is fired whenever a new pet comes into existence.
    event Birth(address owner, uint256 PetId, uint256 matronId, uint256 sireId, uint256 genes);

    /// @dev Transfer event as defined in current draft of KRC721.
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/
    struct Pet {
        // The Pet's genetic code is packed into these 256-bits
        uint256 genes;

        // The timestamp from the block when this pet came into existence.
        uint64 birthTime;

        // The minimum timestamp after which this pet can engage in breeding
        // activities again.
        uint64 cooldownEndBlock;

        uint256 matronId;
        uint256 sireId;

        // Set to the ID of the sire pet for matrons that are pregnant,
        // zero otherwise. A non-zero value here is how we know a pet
        // is pregnant. Used to retrieve the genetic material for the new
        // pet when the birth transpires.
        uint256 siringWithId;

        // Set to the index in the cooldown array that represents
        // the current cooldown duration for this Pet. This starts at zero
        // for gen0 pets, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding action, regardless
        // of whether this pet is acting as matron or sire.
        uint16 cooldownIndex;

        // The "generation number" of this pet. pets minted by the CP contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other pets is the larger of the two generation
        // numbers of their parents, plus one.
        // (i.e. max(matron.generation, sire.generation) + 1)
        uint16 generation;
        
        // The stages of this pet, starts from the junior stage, when feeding on, the pet grows to adulthood and middle-Age
        uint16 stages;
    }

    /*** CONSTANTS ***/

    /// @dev A lookup table indipeting the cooldown duration after any successful
    ///  breeding action, called "pregnancy time" for matrons and "siring cooldown"
    ///  for sires. Designed such that the cooldown roughly doubles each time a pet
    ///  is bred, encouraging owners not to just keep breeding the same pet over
    ///  and over again. Caps out at one week (a pet can breed an unbounded number
    ///  of times, and the maximum cooldown is always seven days).
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    // An approximation of currently how many seconds are in between blocks.
    uint256 public secondsPerBlock = 6;

    /*** STORAGE ***/

    /// @dev An array containing the Pet struct for all pets in existence. The ID
    ///  of each pet is actually an index into this array. Note that ID 0 is a negapet,
    ///  the unPet, the mythical beast that is the parent of all gen0 pets.
    Pet[] pets;

    mapping (uint256 => address) public PetIndexToOwner;

    // Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from PetIDs to an address that has been approved to call
    ///  transferFrom().
    mapping (uint256 => address) public PetIndexToApproved;

    /// @dev A mapping from PetIDs to an address that has been approved to use
    ///  this Pet for siring via breedWith().
    mapping (uint256 => address) public sireAllowedToAddress;

    SaleClockAuction public saleAuction;

    /// @dev The address of a custom ClockAuction subclassed contract that handles siring
    ///  auctions. Needs to be separate from saleAuction because the actions taken on success
    ///  after a sales and siring auction are quite different.
    SiringClockAuction public siringAuction;

    /// @dev Assigns ownership of a specific Pet to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        PetIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete sireAllowedToAddress[_tokenId];
            delete PetIndexToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new Pet and stores it.
    /// @param _matronId The Pet ID of the matron of this pet (zero for gen0)
    /// @param _sireId The Pet ID of the sire of this pet (zero for gen0)
    /// @param _generation The generation number of this pet.
    /// @param _genes The Pet's genetic code.
    /// @param _owner The inital owner of this pet, must be non-zero (except for the unPet, ID 0)
    function _createPet(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        // New Pet starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Pet memory _Pet = Pet({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation),
            stages: uint16(1)
        });
        uint256 newpetId = pets.push(_Pet) - 1;

        emit Birth(
            _owner,
            newpetId,
            uint256(_Pet.matronId),
            uint256(_Pet.sireId),
            _Pet.genes
        );

        _transfer(address(0), _owner, newpetId);

        return newpetId;
    }

    function setSecondsPerBlock(uint256 secs) external onlyOwner {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}


contract PetOwnership is PetBase, KRC721 {

    string public constant name = "My DeFi Pet";
    string public constant symbol = "MDP";

    bytes4 constant InterfaceSignature_KRC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_KRC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));


    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {

        return ((_interfaceID == InterfaceSignature_KRC165) || (_interfaceID == InterfaceSignature_KRC721));
    }

    /// @dev Checks if a given address is the current owner of a particular Pet.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId pet id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return PetIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Pet.
    /// @param _claimant the address we are confirming pet is approved for.
    /// @param _tokenId pet id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return PetIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        PetIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of pets owned by a specific address.
    /// @param _owner The owner address to check.
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Pet to another address
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Pet to transfer.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Pet that can be transferred if this call succeeds.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @param _from The address that owns the Pet to be transfered.
    /// @param _to The address that should take ownership of the Pet. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Pet to be transferred.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of pets currently in existence.
    function totalSupply() public view returns (uint) {
        return pets.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given Pet.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = PetIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all Pet IDs assigned to an address.
    /// @param _owner The owner whose pets we are interested in.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalpets = totalSupply();
            uint256 resultIndex = 0;

            uint256 petId;

            for (petId = 1; petId <= totalpets; petId++) {
                if (PetIndexToOwner[petId] == _owner) {
                    result[resultIndex] = petId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

/// @title A facet of PetCore that manages Pet siring, gestation, and birth.
contract PetBreeding is PetOwnership {
    
    address public dpetToken = 0xa1De6de4DF6da5c09fe182D7D77a1D6d4732632c; //Testnet

    /// @dev The Pregnant event is fired when two pets successfully breed and the pregnancy
    ///  timer begins for the matron.
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);

    uint256 public autoBirthFee = 1*10**18; // pet token

    // Keeps track of number of pregnant pets.
    uint256 public pregnantpets;

    address public geneScience;

    function setGeneScienceAddress(address _address) external onlyOwner {
        geneScience = _address;
    }

    /// @dev Checks that a given pet is able to breed. Requires that the
    ///  current cooldown is finished (for sires) and also checks that there is
    ///  no pending pregnancy.
    function _isReadyToBreed(Pet memory _pet) internal view returns (bool) {
        return (_pet.siringWithId == 0) && (_pet.cooldownEndBlock <= uint64(block.number));
    }

    /// @dev Check if a sire has authorized breeding with this matron. True if both sire
    ///  and matron have the same owner, or if the sire has given siring permission to
    ///  the matron's owner (via approveSiring()).
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = PetIndexToOwner[_matronId];
        address sireOwner = PetIndexToOwner[_sireId];

        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

    /// @dev Set the cooldownEndTime for the given Pet, based on its current cooldownIndex.
    /// @param _pet A reference to the Pet in storage which needs its timer started.
    function _triggerCooldown(Pet storage _pet) internal {
        _pet.cooldownEndBlock = uint64((cooldowns[_pet.cooldownIndex]/secondsPerBlock) + block.number);

        if (_pet.cooldownIndex < 13) {
            _pet.cooldownIndex += 1;
        }
    }

    /// @notice Grants approval to another user to sire with one of your pets.
    /// @param _addr The address that will be able to sire with your Pet. Set to
    ///  address(0) to clear all siring approvals for this Pet.
    /// @param _sireId A Pet that you own that _addr will now be able to sire with.
    function approveSiring(address _addr, uint256 _sireId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    function setAutoBirthFee(uint256 val) external onlyOwner {
        autoBirthFee = val;
    }

    function _isReadyToGiveBirth(Pet memory _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

    /// @notice Checks that a given pet is able to breed
    /// @param _PetId reference the id of the pet
    function isReadyToBreed(uint256 _PetId)
        public
        view
        returns (bool)
    {
        require(_PetId > 0);
        Pet storage pet = pets[_PetId];
        return _isReadyToBreed(pet);
    }

    /// @dev Checks whether a Pet is currently pregnant.
    /// @param _PetId reference the id of the pet
    function isPregnant(uint256 _PetId)
        public
        view
        returns (bool)
    {
        require(_PetId > 0);
        return pets[_PetId].siringWithId != 0;
    }

    /// @param _matron A reference to the Pet struct of the potential matron.
    /// @param _matronId The matron's ID.
    /// @param _sire A reference to the Pet struct of the potential sire.
    /// @param _sireId The sire's ID
    function _isValidMatingPair(
        Pet storage _matron,
        uint256 _matronId,
        Pet storage _sire,
        uint256 _sireId
    )
        private
        view
        returns(bool)
    {
        // A Pet can't breed with itself!
        if (_matronId == _sireId) {
            return false;
        }

        // pets can't breed with their parents.
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // pets can't breed with full or half siblings.
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

    /// @dev Internal check to see if a given sire and matron are a valid mating pair for
    ///  breeding via auction.
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        Pet storage matron = pets[_matronId];
        Pet storage sire = pets[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    /// @param _matronId The ID of the proposed matron.
    /// @param _sireId The ID of the proposed sire.
    function canBreedWith(uint256 _matronId, uint256 _sireId)
        external
        view
        returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Pet storage matron = pets[_matronId];
        Pet storage sire = pets[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        // Grab a reference to the pets from storage.
        Pet storage sire = pets[_sireId];
        Pet storage matron = pets[_matronId];

        // Mark the matron as pregnant, keeping track of who the sire is.
        matron.siringWithId = uint32(_sireId);

        // Trigger the cooldown for both parents.
        _triggerCooldown(sire);
        _triggerCooldown(matron);

        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

        pregnantpets++;

        emit Pregnant(PetIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
    }

    /// @param _matronId The ID of the Pet acting as matron
    /// @param _sireId The ID of the Pet acting as sire
    function breedWithAuto(uint256 _matronId, uint256 _sireId, uint256 _amount)
        external
        whenNotPaused
    {
        // Checks for .
        require(_amount >= autoBirthFee, "Must payment");
        require(IKRC20(dpetToken).transferFrom(msg.sender, address(this), _amount));
        // Caller must own the matron.
        require(_owns(msg.sender, _matronId));
        require(_isSiringPermitted(_sireId, _matronId));

        // Grab a reference to the potential matron
        Pet storage matron = pets[_matronId];

        // Make sure matron isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(matron));

        // Grab a reference to the potential sire
        Pet storage sire = pets[_sireId];

        // Make sure sire isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(sire));

        require(_isValidMatingPair(
            matron,
            _matronId,
            sire,
            _sireId
        ));

        _breedWith(_matronId, _sireId);
    }

    /// @notice Have a pregnant Pet give birth!
    /// @param _matronId A Pet ready to give birth.
    /// @return The Pet ID of the new pet.
    function giveBirth(uint256 _matronId)
        external
        whenNotPaused
        returns(uint256)
    {
        Pet storage matron = pets[_matronId];

        // Check that the matron is a valid pet.
        require(matron.birthTime != 0, "Invalid pet");

        require(_isReadyToGiveBirth(matron), "Not ready birth");

        uint256 sireId = matron.siringWithId;
        Pet storage sire = pets[sireId];

        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        uint256 childGenes = IGeneScience(geneScience).mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);

        address owner = PetIndexToOwner[_matronId];
        uint256 petId = _createPet(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);

        delete matron.siringWithId;

        pregnantpets--;

        return petId;
    }
}

/// @title Auction Core
contract ClockAuctionBase {
    using SafeMath for uint256;
     
    address public dpetToken = 0xfb62AE373acA027177D1c18Ee0862817f9080d08;

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price at beginning of auction
        uint128 startingPrice;
        // Price at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    KRC721 public nonFungibleContract;

    uint256 public ownerCut;
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);

        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            require(IKRC20(dpetToken).transfer(seller, sellerProceeds));
        }

        uint256 bidExcess = _bidAmount - price;

        require(IKRC20(dpetToken).transfer(msg.sender, bidExcess));

        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    /// @dev Computes the current price of an auction.
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            uint256 totalPriceChange = _endingPrice.sub(_startingPrice);

            uint256 currentPriceChange = totalPriceChange * _secondsPassed / _duration;

            uint256 currentPrice = _startingPrice + currentPriceChange;

            return currentPrice;
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


/// @title Clock auction for non-fungible tokens.
contract ClockAuction is Pausable, ClockAuctionBase {

    bytes4 constant InterfaceSignature_KRC721 = bytes4(0x9a20483d);

    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        KRC721 candidateContract = KRC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_KRC721));
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external onlyOwner {
        address(uint160(owner)).transfer(address(this).balance);
        IKRC20(dpetToken).transfer(owner, getBalance());
    }
    
    function changeCut(uint256 _cut) external onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
    }
    
    function getBalance() view public returns(uint256) {
        return IKRC20(dpetToken).balanceOf(address(this));
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
        whenNotPaused
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId), "Not PetId owner");
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough KAI is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId, uint256 _amount)
        external
        whenNotPaused
    {
        // require(IKRC20(dpetToken).transfer(address(this), _amount));
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, _amount);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "TokenID is a must on auction");
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "TokenID is a must on auction");
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "TokenID is a must on auction");
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "TokenID is a must on auction");
        return _currentPrice(auction);
    }

}


/// @title Reverse auction modified for siring
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract SiringClockAuction is ClockAuction {

    bool public isSiringClockAuction = true;

    constructor(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Places a bid for siring. Requires the sender
    /// is the PetCore contract because all bid methods
    /// should be wrapped. Also returns the Pet to the
    /// seller rather than the winner.
    function bid(uint256 _tokenId, uint256 _amount)
        external
    {   
        // require(IKRC20(dpetToken).transferFrom(msg.sender, address(this), _amount));
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        // _bid checks that token ID is valid and will throw if bid fails
        _bid(_tokenId, _amount);
        // We transfer the Pet back to the seller, the winner will get
        // the offspring
        _transfer(seller, _tokenId);
    }

}


/// @title Clock auction modified for sale of pets
contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;

    // Tracks last 5 sale price of gen0 Pet sales
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    constructor(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId, uint256 _amount)
        external
    {
        require(IKRC20(dpetToken).transferFrom(msg.sender, address(this), _amount));

        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, _amount);
        _transfer(msg.sender, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(nonFungibleContract)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}


/// @title all functions related to creating pets
contract PetMinting is PetBreeding, IPetCore {

    // Counts the number of pets the contract owner has created.
    uint256 public gen0CreatedCount;
    uint256 public gen0Price = 1* 10**18;
    address public stakingContract;
    
    uint256 private nonce;
    
    /**
     * @dev Throws if called by any account other than the staking contract.
     */
    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "Ownable: caller is not the staking contract");
        _;
    }


    /// @param _owner the future owner of the created pets.
    function createPromoPet(address _owner, uint256 _amount) external  {
        require(_amount >= gen0Price, "INVALID AMOUNT");
        require(IKRC20(dpetToken).transferFrom(msg.sender, address(this), _amount));

        gen0CreatedCount++;
        uint256 genes = _randomPetGenes();
        _createPet(0, 0, 0, genes, _owner);
    }
    
    function createPet(address _owner) external onlyStakingContract {
        gen0CreatedCount++;
        uint256 genes = _randomPetGenes();
        _createPet(0, 0, 0, genes, _owner);
    }
    
    function createGen0Auction(address _owner, uint256 _genes) external onlyOwner {
        gen0CreatedCount++;
        _createPet(0, 0, 0, _genes, _owner);
    }
    
    function updateGen0Price(uint256 _gen0Price) external onlyOwner {
        gen0Price = _gen0Price;
    }
    
    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }

    function _randomPetGenes() internal returns (uint256) {
        uint256 randomN = uint256(blockhash(block.number));
        uint256 genes = uint256(keccak256(abi.encodePacked(randomN, block.timestamp, nonce))) % (10 **72) + 1*10**71;
        nonce++;
        
        return genes;
    }
}

contract PetCore is PetMinting {
    
    uint256 public amountToAdulthood = 10 * 10**18;
    uint256 public amountToMiddleAge = 15 * 10**18;
    address public siringAuctionAddr;
    address public saleAuctionAddr;


    constructor() public {
        paused = false;

        // start with the mythical pet 0 - so we don't have generation-0 parent issues
        _createPet(0, 0, 0, uint256(-1), address(0));
    }
    
    /// @dev Reject all KAI from being sent here, unless it's from one of the
    ///  two auction contracts.
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyOwner {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
        saleAuctionAddr = _address;
    }

    function setSiringAuctionAddress(address _address) external  onlyOwner {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        require(candidateContract.isSiringClockAuction());

        // Set the new contract address
        siringAuction = candidateContract;
        siringAuctionAddr = _address;
    }

    function createSaleAuction(
        uint256 _PetId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _PetId), "Not PetId owner");

        require(!isPregnant(_PetId), "Pet is pregnant");
        _approve(_PetId, address(saleAuction));
        saleAuction.createAuction(
            _PetId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function createSiringAuction(
        uint256 _PetId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If Pet is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _PetId), "Not PetId owner");
        require(isReadyToBreed(_PetId), "Not ready to breed");
        _approve(_PetId, address(siringAuction));
        // Siring auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the Pet.
        siringAuction.createAuction(
            _PetId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Completes a siring auction by bidding.
    ///  Immediately breeds the winning matron with the sire on auction.
    /// @param _sireId - ID of the sire on auction.
    /// @param _matronId - ID of the matron owned by the bidder.
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId,
        uint256 _amount
    )
        external
        whenNotPaused
    {
        require(IKRC20(dpetToken).transferFrom(msg.sender, address(this), _amount));
        // Auction contract checks input sizes
        require(_owns(msg.sender, _matronId), "Not matron owner");
        require(isReadyToBreed(_matronId), "Not ready to breed");
        require(_canBreedWithViaAuction(_matronId, _sireId), "Can't breed with via auction");
        
        // Define the current price of the auction.
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(_amount >= currentPrice + autoBirthFee);

        // // Siring auction will throw if the bid fails.
        require(IKRC20(dpetToken).transfer(siringAuctionAddr, _amount));
        siringAuction.bid(_sireId, _amount);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

    /// @notice Returns all the relevant information about a specific Pet.
    /// @param _id The ID of the Pet of interest.
    function getPet(uint256 _id)
        public
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        string memory genes,
        uint256 stages
    ) {
        Pet storage pet = pets[_id];

        isGestating = (pet.siringWithId != 0);
        isReady = (pet.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(pet.cooldownIndex);
        nextActionAt = uint256(pet.cooldownEndBlock);
        siringWithId = uint256(pet.siringWithId);
        birthTime = uint256(pet.birthTime);
        matronId = uint256(pet.matronId);
        sireId = uint256(pet.sireId);
        generation = uint256(pet.generation);
        genes = _uintToStr(pet.genes);
        stages = uint256(pet.stages);
    }
    
    /// @notice feed on a specific Pet.
    /// @param _petId The ID of the Pet of interest.
    /// @param _amount.
    function feedOnPet(uint256 _petId, uint256 _amount) external {
        require(IKRC20(dpetToken).transferFrom(msg.sender, address(this), _amount));
        
        Pet storage pet = pets[_petId];
        if (_amount == amountToAdulthood) {
            require(pet.stages == 1, "INVALID STAGE 1");
            pet.stages += 1;
        }
        
        if (_amount == amountToMiddleAge) {
            require(pet.stages == 2, "INVALID STAGE 2");
            pet.stages += 1;
        }
    }
    
    function setAmountToAdulthood(uint256 _amountToAdulthood) external onlyOwner {
        amountToAdulthood = _amountToAdulthood;
    }
    
    function setAmountToMiddleAge(uint256 _amountToMiddleAge) external onlyOwner {
        amountToMiddleAge = _amountToMiddleAge;
    }
    
    function getBalance() public view returns(uint256) {
        return IKRC20(dpetToken).balanceOf(address(this));
    }
    
    function withdrawBalance() external onlyOwner {
        IKRC20(dpetToken).transfer(owner, getBalance());
    }
    
    function _uintToStr(uint _i) private pure returns (string memory _uintAsString) {
        uint number = _i;
        if (number == 0) {
            return "0";
        }
        uint j = number;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (number != 0) {
            bstr[k--] = byte(uint8(48 + number % 10));
            number /= 10;
        }
        return string(bstr);
    }
}


contract GeneScience is IGeneScience {

    uint256 internal constant maskLast8Bits = uint256(0xff);
    uint256 internal constant maskFirst248Bits = uint256(~0xff);

    /// @dev given a characteristic and 2 genes (unsorted) - returns > 0 if the genes ascended, that's the value
    /// @param trait1 any trait of that characteristic
    /// @param trait2 any trait of that characteristic
    /// @param rand is expected to be a 3 bits number (0~7)
    /// @return -1 if didnt match any ascention, OR a number from 0 to 30 for the ascended trait
    function _ascend(uint8 trait1, uint8 trait2, uint256 rand) internal pure returns(uint8 ascension) {
        ascension = 0;

        uint8 smallT = trait1;
        uint8 bigT = trait2;

        if (smallT > bigT) {
            bigT = trait1;
            smallT = trait2;
        }

        if ((bigT - smallT == 1) && smallT % 2 == 0) {

            // The rand argument is expected to be a random number 0-7.
            // 1st and 2nd tier: 1/4 chance (rand is 0 or 1)
            // 3rd and 4th tier: 1/8 chance (rand is 0)

            // must be at least this much to ascend
            uint256 maxRand;
            if (smallT < 23) maxRand = 1;
            else maxRand = 0;

            if (rand <= maxRand ) {
                ascension = (smallT / 2) + 16;
            }
        }
    }

    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }

    /// @dev Get a 5 bit slice from an input as a number
    /// @param _input bits, encoded as uint
    /// @param _slot from 0 to 50
    function _get5Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(5), _slot * 5));
    }

    /// @dev Parse a pet gene and returns all of 12 "trait stack" that makes the characteristics
    /// @param _genes pet gene
    /// @return the 48 traits that composes the genetic code, logically divided in stacks of 4, where only the first trait of each stack may express
    function decode(uint256 _genes) public pure returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](48);
        uint256 i;
        for(i = 0; i < 48; i++) {
            traits[i] = _get5Bits(_genes, i);
        }
        return traits;
    }

    /// @dev Given an array of traits return the number that represent genes
    function encode(uint8[] memory _traits) public pure returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < 48; i++) {
            _genes = _genes << 5;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[47 - i];
        }
        return _genes;
    }

    /// @dev return the expressing traits
    /// @param _genes the long number expressing pet genes
    function expressingTraits(uint256 _genes) public pure returns(uint8[12] memory) {
        uint8[12] memory express;
        for(uint256 i = 0; i < 12; i++) {
            express[i] = _get5Bits(_genes, i * 4);
        }
        return express;
    }

    /// @dev the function as defined in the breeding contract - as defined in CK bible
    function mixGenes(uint256 _genes1, uint256 _genes2, uint256 _targetBlock) public view returns (uint256) {
        // require(block.number > _targetBlock);

        uint256 randomN = uint256(blockhash(_targetBlock));
        uint256 rand;

        if (randomN == 0) {

            _targetBlock = (block.number & maskFirst248Bits) + (_targetBlock & maskLast8Bits);

            // The computation above could result in a block LARGER than the current block,
            // if so, subtract 256.
            if (_targetBlock >= block.number) _targetBlock -= 256;

            randomN = uint256(blockhash(_targetBlock));
        }

        // generate 256 bits of random, using as much entropy as we can from
        // sources that can't change between calls.
        randomN = uint256(keccak256(abi.encodePacked(randomN, _genes1, _genes2, _targetBlock)));
        uint256 randomIndex = 0;

        uint8[] memory genes1Array = decode(_genes1);
        uint8[] memory genes2Array = decode(_genes2);
        // All traits that will belong to baby
        uint8[] memory babyArray = new uint8[](48);
        // A pointer to the trait we are dealing with currently
        uint256 traitPos;
        // Trait swap value holder
        uint8 swap;
        // iterate all 12 characteristics
        for(uint256 i = 0; i < 12; i++) {
            // pick 4 traits for characteristic i
            uint256 j;
            // store the current random value
            // uint256 rand;
            for(j = 3; j >= 1; j--) {
                traitPos = (i * 4) + j;

                rand = _sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                // 1/4 of a chance of gene swapping forward towards expressing.
                if (rand == 0) {
                    // do it for parent 1
                    swap = genes1Array[traitPos];
                    genes1Array[traitPos] = genes1Array[traitPos - 1];
                    genes1Array[traitPos - 1] = swap;

                }

                rand = _sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                if (rand == 0) {
                    // do it for parent 2
                    swap = genes2Array[traitPos];
                    genes2Array[traitPos] = genes2Array[traitPos - 1];
                    genes2Array[traitPos - 1] = swap;
                }
            }
        }

        // We have 256 - 144 = 112 bits of randomness left at this point. We will use up to
        // four bits for the first slot of each trait (three for the possible ascension, one
        // to pick between mom and dad if the ascension fails, for a total of 48 bits. The other
        // traits use one bit to pick between parents (36 gene pairs, 36 genes), leaving us
        // well within our entropy budget.

        // done shuffling parent genes, now let's decide on choosing trait and if ascending.
        // NOTE: Ascensions ONLY happen in the "top slot" of each characteristic. This saves
        //  gas and also ensures ascensions only happen when they're visible.
        for(traitPos = 0; traitPos < 48; traitPos++) {

            // See if this trait pair should ascend
            uint8 ascendedTrait = 0;

            // There are two checks here. The first is straightforward, only the trait
            // in the first slot can ascend. The first slot is zero mod 4.
            //
            // The second check is more subtle: Only values that are one apart can ascend,
            // which is what we check inside the _ascend method. However, this simple mask
            // and compare is very cheap (9 gas) and will filter out about half of the
            // non-ascending pairs without a function call.
            //
            // The comparison itself just checks that one value is even, and the other
            // is odd.
            if ((traitPos % 4 == 0) && (genes1Array[traitPos] & 1) != (genes2Array[traitPos] & 1)) {
                rand = _sliceNumber(randomN, 3, randomIndex);
                randomIndex += 3;

                ascendedTrait = _ascend(genes1Array[traitPos], genes2Array[traitPos], rand);
            }

            if (ascendedTrait > 0) {
                babyArray[traitPos] = uint8(ascendedTrait);
            } else {
                // did not ascend, pick one of the parent's traits for the baby
                // We use the top bit of rand for this (the bottom three bits were used
                // to check for the ascension itself).
                rand = _sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;

                if (rand == 0) {
                    babyArray[traitPos] = uint8(genes1Array[traitPos]);
                } else {
                    babyArray[traitPos] = uint8(genes2Array[traitPos]);
                }
            }
        }

        return encode(babyArray);
    }
}