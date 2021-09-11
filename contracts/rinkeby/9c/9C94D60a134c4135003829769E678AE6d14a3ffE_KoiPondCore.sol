/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.4.18;


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

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <[email protected]> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

/// @title mix up the fish and figure out what traits they should have
contract FishTraitInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isFishTraits() public pure returns (bool);

    ///mix up the "genes" of the fish to see which genes our new fish will have
    function mixFishGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256);
}

/// @title A facet of KoiPondCore that manages special access privileges.
/// Based on work from Axiom Zen (https://www.axiomzen.co)
contract KoiPondAccessControl {
   
    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
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

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}


/// @title Base contract for KoiPond. Holds all common structs, events and base variables.
/// based on code written for CK by Axiom Zen (https://www.axiomzen.co)
contract KoiPondBase is KoiPondAccessControl {
    /*** EVENTS ***/

    /// @dev The Spawn event is fired whenever a new fish comes into existence. This obviously
    ///  includes any time a fish is created through the spawnFish method, but it is also called
    ///  when a new gen0 fish is created.
    event Spawn(address owner, uint256 koiFishId, uint256 parent1Id, uint256 parent2Id, uint256 genes, uint16 generation, uint64 timestamp);

    event BreedingSuccessful(address owner, uint256 newFishId, uint256 parent1Id, uint256 parent2Id, uint64 cooldownEndBlock);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a fish
    ///  ownership is assigned, including spwaning.
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/

    struct KoiFish {
        // The fish's genetic code - this will never change for any fish.
        uint256 genes;

        // The timestamp from the block when this fish came into existence.
        uint64 spawnTime;

        // The minimum timestamp after which this fish can engage in spawning
        // activities again.
        uint64 cooldownEndBlock;

        // The ID of the parents of this fish, set to 0 for gen0 fish.
        // With uint32 there's a limit of 4 billion fish
        uint32 parent1Id;
        uint32 parent2Id;

        // Set to the index in the cooldown array (see below) that represents
        // the current cooldown duration for this fish. This starts at zero
        // for gen0 fish, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding action.
        uint16 cooldownIndex;

        // The "generation number" of this fish. Fish minted by the KP contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other fish is the larger of the two generation
        // numbers of their parents, plus one.
        uint16 generation;
    }

    /*** CONSTANTS ***/

    /// @dev A lookup table indicating the cooldown duration after any successful
    ///  breeding action, called "cooldown" Designed such that the cooldown roughly 
    ///  doubles each time a fish is bred, encouraging owners not to just keep breeding the same fish over
    ///  and over again. Caps out at one week (a fish can breed an unbounded number
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
    uint256 public secondsPerBlock = 15;

    /*** STORAGE ***/

    /// @dev An array containing the KoiFish struct for all KoiFish in existence. The ID
    /// of each fish is actually an index into this array. Fish 0 has an invalid genetic
    /// code and can't be used to produce offspring.
    KoiFish[] koi;

    /// @dev A mapping from fish IDs to the address that owns them. All fish have
    ///  some valid owner address, even gen0 fish are created with a non-zero owner.
    mapping (uint256 => address) public koiFishIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from KoiFishIDs to an address that has been approved to call
    ///  transferFrom(). Each KoiFish can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public koiFishIndexToApproved;

    /// @dev The address of the ClockAuction contract that handles sales of KoiFish. This
    ///  same contract handles both peer-to-peer sales as well as the gen0 sales which are
    ///  initiated every 15 minutes.
    SaleClockAuction public saleAuction;

    /// @dev Assigns ownership of a specific KoiFish to an address.
    function _transferFish(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of fish is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        koiFishIndexToOwner[_tokenId] = _to;
        // When creating new fish _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete koiFishIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new fish and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _parent1Id The fish ID of the first parent (zero for gen0)
    /// @param _parent2Id The fish ID of the second parent (zero for gen0)
    /// @param _generation The generation number of this fish, must be computed by caller.
    /// @param _genes The fish's genetic code.
    /// @param _owner The inital owner of this fish, must be non-zero (except for fish ID 0)
    function _createKoiFish(
        uint256 _parent1Id,
        uint256 _parent2Id,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        // These requires are not strictly necessary, our calling code should make
        // sure that these conditions are never broken. However! _createKoiFish() is already
        // an expensive call (for storage), and it doesn't hurt to be especially careful
        // to ensure our data structures are always valid.
        require(_parent1Id == uint256(uint32(_parent1Id)));
        require(_parent2Id == uint256(uint32(_parent2Id)));
        require(_generation == uint256(uint16(_generation)));

        // New fish starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        KoiFish memory _koiFish = KoiFish({
            genes: _genes,
            spawnTime: uint64(now),
            cooldownEndBlock: 0,
            parent1Id: uint32(_parent1Id),
            parent2Id: uint32(_parent2Id),
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });

        uint256 newKoiFishId = koi.push(_koiFish) - 1;

        // It's probably never going to happen, 4 billion fish is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newKoiFishId == uint256(uint32(newKoiFishId)));

        // emit the spawn event
        Spawn(
            _owner,
            newKoiFishId,
            uint256(_koiFish.parent1Id),
            uint256(_koiFish.parent2Id),
            _koiFish.genes,
            uint16(_generation),
            uint64(now)
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transferFish(0, _owner, newKoiFishId);

        return newKoiFishId;
    }

    // Any C-level can fix how many seconds per blocks are currently observed.
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}


/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

/// @title The facet of the BitKoi core contract that manages ownership, ERC-721 (draft) compliant.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
///  See the KoiPondCore contract documentation to understand how the various contract facets are arranged.
contract KoiPondOwnership is KoiPondBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "KoiPond";
    string public constant symbol = "KP";

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
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

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular fish.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId fish or pond id, only valid when > 0
    function _ownsFish(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return koiFishIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular KoiFish.
    /// @param _claimant the address we are confirming fish is approved for.
    /// @param _tokenId fish id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return koiFishIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting KoiFish on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        koiFishIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of KoiFish owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a KoiFish to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  KoiPond specifically) or your KoiFish may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the KoiFish to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any fish (except very briefly
        // after a gen0 fish is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of fish
        // through the allow + transferFrom flow.
        require(_to != address(saleAuction));
        // You can only send your own fish.
        require(_ownsFish(msg.sender, _tokenId));
        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transferFish(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific KoiFish via
    /// transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    /// clear all approvals.
    /// @param _tokenId The ID of the KoiFish that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_ownsFish(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a KoiFish owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the KoiFish to be transfered.
    /// @param _to The address that should take ownership of the KoiFish. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the KoiFish to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any fish (except very briefly
        // after a gen0 fish is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_ownsFish(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transferFish(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of KoiFish currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return koi.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given KoiFish.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = koiFishIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all KoiFish IDs assigned to an address.
    /// @param _owner The owner whose KoiFish we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire KoiFish array looking for fish belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalKoi = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all fish have IDs starting at 1 and increasing
            // sequentially up to the totalKoi count.
            uint256 koiId;

            for (koiId = 1; koiId <= totalKoi; koiId++) {
                if (koiFishIndexToOwner[koiId] == _owner) {
                    result[resultIndex] = koiId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
    string public baseURI = "http://google.com";
    
    function setBaseURI(string __newURI) external onlyCEO { 
       baseURI = __newURI;
    }
    
    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    function tokenURI(uint256 _tokenId) public view returns (string){
        
        bytes memory __uriBase = bytes(baseURI);
    
        //prepare our tokenId's byte array
        uint maxLength = 78;
        bytes memory reversed = new bytes(maxLength);
        uint i = 0;
        //loop through and add byte values to the array
        while (_tokenId != 0) {
            uint remainder = _tokenId % 10;
            _tokenId /= 10;
            reversed[i++] = byte(48 + remainder);
        }
        //prepare the final array
        bytes memory s = new bytes(__uriBase.length + i);
        uint j;
        //add the base to the final array
        for (j = 0; j < __uriBase.length; j++) {
            s[j] = __uriBase[j];
        }
        //add the tokenId to the final array
        for (j = 0; j < i; j++) {
            s[j + __uriBase.length] = reversed[i - 1 - j];
        }
        //turn it into a string and return it
        return string(s);
        
    }
}


/// @title A facet of KoiPondCore that manages Koi siring, gestation, and spawn.
contract KoiPondBreeding is KoiPondOwnership {
    
    event Hatch(address owner, uint256 fishId, uint256 genes);

    /// @notice The minimum payment required to use breedWithAuto(). This fee goes towards
    ///  the gas cost paid by whatever calls giveBirth(), and can be dynamically updated by
    ///  the COO role as the gas price changes.
    uint256 public autoBirthFee = 2 finney;

    /// @dev The address of the sibling contract that is used to implement the genetic combination algorithm.
    FishTraitInterface public fishTraits;

    /// @dev Update the address of the genetic contract, can only be called by the CEO.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setFishTraitAddress(address _address) external onlyCEO {
        FishTraitInterface candidateContract = FishTraitInterface(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isFishTraits());

        // Set the new contract address
        fishTraits = candidateContract;
    }

    /// @dev Checks to see if a given fish is ready to hatch after the gestation period has passed.
    function _isReadyToHatch(uint256 _fishId) private view returns (bool) {
        KoiFish storage fishToHatch = koi[_fishId];
        return fishToHatch.cooldownEndBlock <= uint64(block.number);
    }

    /// @dev Checks that a given fish is able to breed. Requires that the
    ///  current cooldown is finished
    
    function _isReadyToBreed(KoiFish _fish) internal view returns (bool) {
        // In addition to checking the cooldownEndBlock, we also need to check to see if
        // the fish has a pending birth; there can be some period of time between the end
        // of the pregnacy timer and the spawn event.
        return _fish.cooldownEndBlock <= uint64(block.number);
    }

    ///check to see if the caller owns both fish
    function _isBreedingPermitted(uint256 _parent1Id, uint256 _parent2Id) internal view returns (bool) {
        address parent1Owner = koiFishIndexToOwner[_parent1Id];
        address parent2Owner = koiFishIndexToOwner[_parent2Id];

        //return true if the caller owns them both
        return (parent1Owner == parent2Owner);
    }

    /// @dev Set the cooldownEndTime for the given fish based on its current cooldownIndex.
    ///  Also increments the cooldownIndex (unless it has hit the cap).
    /// @param _koiFish A reference to the KoiFish in storage which needs its timer started.
    function _triggerCooldown(KoiFish storage _koiFish) internal {
        // Compute an estimation of the cooldown time in blocks (based on current cooldownIndex).
        _koiFish.cooldownEndBlock = uint64((cooldowns[_koiFish.cooldownIndex]/secondsPerBlock) + block.number);

        // Increment the breeding count, clamping it at 13, which is the length of the
        // cooldowns array. We could check the array size dynamically, but hard-coding
        // this as a constant saves gas. Yay, Solidity!
        if (_koiFish.cooldownIndex < 13) {
            _koiFish.cooldownIndex += 1;
        }
    }

    /// @dev Updates the minimum payment required for calling giveBirthAuto(). Can only
    ///  be called by the COO address. (This fee is used to offset the gas cost incurred
    ///  by the autobirth daemon).
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }


    /// @notice Checks that a given fish is able to breed (i.e. it is not 
    ///  in the middle of a siring cooldown).
    /// @param _koiId reference the id of the fish, any user can inquire about it
    function isReadyToBreed(uint256 _koiId)
        public
        view
        returns (bool)
    {
        require(_koiId > 0);
        KoiFish storage fish = koi[_koiId];
        return _isReadyToBreed(fish);
    }

    /// @notice Checks that a given fish is able to breed (i.e. it is not 
    ///  in the middle of a siring cooldown).
    /// @param _koiId reference the id of the fish, any user can inquire about it
    function isReadyToHatch(uint256 _koiId)
        public
        view
        returns (bool)
    {
        require(_koiId > 0);
        return _isReadyToHatch(_koiId);
    }

    /// @dev Internal check to see if a the parents are a valid mating pair. DOES NOT
    ///  check ownership permissions (that is up to the caller).
    /// @param _parent1 A reference to the Fish struct of the potential first parent
    /// @param _parent1Id The first parent's ID.
    /// @param _parent2 A reference to the Fish struct of the potential second parent
    /// @param _parent2Id The second parent's ID.
    function _isValidMatingPair(
        KoiFish storage _parent1,
        uint256 _parent1Id,
        KoiFish storage _parent2,
        uint256 _parent2Id
    )
        private
        view
        returns(bool)
    {
        // A Fish can't breed with itself!
        if (_parent1Id == _parent2Id) {
            return false;
        }
        
        //the fish have to have genes
        if (_parent1.genes == 0 || _parent2.genes == 0) {
            return false;
        }

        // Fish can't breed with their parents.
        if (_parent1.parent1Id == _parent1Id || _parent1.parent2Id == _parent2Id) {
            return false;
        }
        if (_parent2.parent1Id == _parent1Id || _parent2.parent2Id == _parent2Id) {
            return false;
        }

        // We can short circuit the sibling check (below) if either fish is
        // gen zero (no parent found).
        if (_parent2.parent1Id == 0 || _parent1.parent1Id == 0) {
            return true;
        }

        // Fish can't breed with full or half siblings.
        if (_parent2.parent1Id == _parent1.parent1Id || _parent2.parent1Id == _parent1.parent2Id) {
            return false;
        }
        if (_parent2.parent1Id == _parent1.parent1Id || _parent2.parent2Id == _parent1.parent2Id) {
            return false;
        }

        // All checks passed
        return true;
    }


    /// @notice Checks to see if two FISH can breed together, including checks for
    ///  ownership and siring approvals. Does NOT check that both fish are ready for
    ///  breeding (i.e. breedWith could still fail until the cooldowns are finished).
    /// @param _parent1Id The ID of the proposed first parent.
    /// @param _parent2Id The ID of the proposed second parent.
    function canBreedWith(uint256 _parent1Id, uint256 _parent2Id)
        external
        view
        returns(bool)
    {
        require(_parent1Id > 0);
        require(_parent2Id > 0);
        KoiFish storage parent1 = koi[_parent1Id];
        KoiFish storage parent2 = koi[_parent2Id];
        return _isValidMatingPair(parent1, _parent1Id, parent2, _parent2Id);
    }

    /// @dev Internal utility function to initiate breeding, assumes that all breeding
    ///  requirements have been checked.
    function _breedWith(uint256 _parent1Id, uint256 _parent2Id) internal returns(uint256) {
        // Grab a reference to the Koi from storage.
        KoiFish storage parent1 = koi[_parent1Id];
        KoiFish storage parent2 = koi[_parent2Id];

        // Determine the higher generation number of the two parents
        uint16 parentGen = parent1.generation;
        if (parent2.generation > parent1.generation) {
            parentGen = parent2.generation;
        }

        // Make the new fish!
        address owner = koiFishIndexToOwner[_parent1Id];
        uint256 newFishId = _createKoiFish(_parent1Id, _parent2Id, parentGen + 1, 0, owner);

        // Trigger the cooldown for both parents.
        _triggerCooldown(parent1);
        _triggerCooldown(parent2);

        // Emit the breeding event.
        BreedingSuccessful(koiFishIndexToOwner[_parent1Id], newFishId, _parent1Id, _parent2Id, parent1.cooldownEndBlock);
        
        KoiFish storage newFish = koi[newFishId];
        _triggerCooldown(newFish);
        
        return newFishId;

    }

    function breedWithAuto(uint256 _parent1Id, uint256 _parent2Id)
        external
        payable
        whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= autoBirthFee);

        // Check that both fish being bred are owned by caller, or that the sire
        // Will fail for _parent1Id = 0
        require(_isBreedingPermitted(_parent1Id, _parent2Id));
        
         // Grab a reference to the first parent
        KoiFish storage parent1 = koi[_parent1Id];

        // Make sure sire enough time has passed since the last time this fish was bred
        require(_isReadyToBreed(parent1));

        // Grab a reference to the second parent
        KoiFish storage parent2 = koi[_parent2Id];

        // Make sure sire enough time has passed since the last time this fish was bred
        require(_isReadyToBreed(parent2));


        // Test that these fish are a valid mating pair.
        require(_isValidMatingPair(
            parent2,
            _parent2Id,
            parent1,
            _parent1Id
        ));

        // All checks passed, make a new fish!!
        _breedWith(_parent1Id, _parent2Id);
    }

    function hatchFishAuto(uint256 _fishId)
        external
        payable
        whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= autoBirthFee);
        
        _hatchFish(_fishId);
    }

    function _hatchFish(uint256 _fishId) internal {
        KoiFish storage fishToHatch = koi[_fishId];
        KoiFish storage parent1 = koi[fishToHatch.parent1Id];
        KoiFish storage parent2 = koi[fishToHatch.parent2Id];


        // Check that the parent is a valid fish
        require(parent1.spawnTime != 0);

        //  Check to see if the fish is ready to hatch
        require(_isReadyToHatch(_fishId));
        
        // Make sure this fish doesn't already have genes
        require(fishToHatch.genes == 0);

        //  next, let's get new genes for the fish we're about to hatch
        uint256 newFishGenes = fishTraits.mixFishGenes(parent1.genes, parent2.genes, parent1.cooldownEndBlock - 1);

        koi[_fishId].genes = uint256(newFishGenes);

        // Send the balance fee to the person who made birth happen.
        msg.sender.transfer(autoBirthFee);
        
        Hatch(msg.sender, _fishId, newFishGenes);
        
    }
}

/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockAuctionBase {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }


    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(address sellerId, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _ownsFish(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(address _sellerId, uint256 _tokenId, Auction _auction, uint256 _auctionStarted) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            address(_sellerId),
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            uint256(_auctionStarted)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));

        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can't go negative.)
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it's an
            // accident, they can call cancelAuction(). )
            seller.transfer(sellerProceeds);
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
        AuctionSuccessful(_tokenId, price, msg.sender);

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

    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn't ever go backwards).
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

    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
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
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
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
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


/// @title Clock auction for non-fungible tokens.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockAuction is Pausable, ClockAuctionBase {

    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    /// @dev Remove all Ether from the contract, which is the owner's cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        // We are using this boolean method to make sure that even if one fails it will still work
        bool res = nftAddress.send(this.balance);
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
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_ownsFish(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_seller, _tokenId, auction, now);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
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
        require(_isOnAuction(auction));
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
        require(_isOnAuction(auction));
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
        require(_isOnAuction(auction));
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
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


/// @title Clock auction modified for sale of fish
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract SaleClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isSaleClockAuction = true;

    // Tracks last 5 sale price of gen0 fish sales
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    // Delegate constructor
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
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
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            address(_seller),
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_seller, _tokenId, auction, now);
    }

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId)
        external
        payable
    {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
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


/// @title Handles creating auctions for sale of fish.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract KoiPondAuction is KoiPondBreeding {

    // @notice The auction contract variables are defined in KoiPondBase to allow
    //  us to refer to them in KoiPondOwnership to prevent accidental transfers.
    // `saleAuction` refers to the auction for gen0 and p2p sale of fish.

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    ///  @dev Put a fish up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _koiId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If fish is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_ownsFish(msg.sender, _koiId));
        _approve(_koiId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the fish.

        saleAuction.createAuction(
            _koiId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
}


/// @title all functions related to creating fish (and their eggs)
contract KoiPondMinting is KoiPondAuction {

    // Limits the number of fish the contract owner can ever create.
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;

    // Constants for gen0 auctions.
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;

    // Counts the number of fish the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    /// @dev we can create promo fish, up to a limit. Only callable by COO
    /// @param _genes the encoded genes of the fish to be created, any value is accepted
    /// @param _owner the future owner of the created fish. Default to contract COO
    function createPromoFish(uint256 _genes, address _owner) external onlyCOO {
        address koiFishOwner = _owner;
        if (koiFishOwner == address(0)) {
             koiFishOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createKoiFish(0, 0, 0, _genes, koiFishOwner);
    }

    /// @dev Creates a new gen0 fish with the given genes and
    ///  creates an auction for it.
    function createGen0FishAuction(uint256 _genes) external onlyCOO returns(uint256){
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 koiFishId = _createKoiFish(0, 0, 0, _genes, address(this));
        _approve(koiFishId, saleAuction);

        saleAuction.createAuction(
            koiFishId,
            _computeNextGen0Price(),
            0,
            GEN0_AUCTION_DURATION,
            address(this)
        );

        gen0CreatedCount++;

        return koiFishId;
    }

    /// @dev Computes the next gen0 auction starting price, given
    ///  the average of the past 5 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // Sanity check to ensure we don't overflow arithmetic
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }
}


/// @title BitKoi: Fancy Fish and surprises at scale on the Ethereum blockchain.
/// @dev The main BitKoi contract
contract KoiPondCore is KoiPondMinting {

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main BitKoi smart contract instance.
    function KoiPondCore() public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // start with fish 0 - so we don't have generation-0 parent issues
        _createKoiFish(0, 0, 0, uint256(-1), address(0));
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it's from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(saleAuction)
        );
    }

    /// @notice Returns all the relevant information about a specific fish.
    /// @param _id The ID of the fish we're looking up
    function getKoiFish(uint256 _id)
        external
        view
        returns (
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 spawnTime,
        uint256 parent1Id,
        uint256 parent2Id,
        uint256 generation,
        uint256 genes
    ) {
        KoiFish storage fish = koi[_id];
        isReady = (fish.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(fish.cooldownIndex);
        nextActionAt = uint256(fish.cooldownEndBlock);
        spawnTime = uint256(fish.spawnTime);
        parent1Id = uint256(fish.parent1Id);
        parent2Id = uint256(fish.parent2Id);
        generation = uint256(fish.generation);
        genes = fish.genes;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(fishTraits != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the CFO to capture the balance available to the contract.
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        cfoAddress.transfer(balance);
    }
}