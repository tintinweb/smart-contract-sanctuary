pragma solidity ^0.4.20;

/// @title defined the interface that will be referenced in main Cutie contract
/// @author https://BlockChainArchitect.io
contract GeneMixerInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneMixer() external pure returns (bool);

    /// @dev given genes of cutie 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of dad
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genes1, uint256 genes2) public view returns (uint256);

    function canBreed(uint40 momId, uint256 genes1, uint40 dadId, uint256 genes2) public view returns (bool);
}



/// @author https://BlockChainArchitect.io
contract PluginInterface
{
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

    /// @dev Begins new feature.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    /// @param _seller - Old owner, if not the message sender
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    ) 
    public
    payable;

    /// @dev Begins new feature, approved and signed by COO.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    )
    external
    payable;

    function withdraw() public;
}



/// @title Auction Market for Blockchain Cuties.
/// @author https://BlockChainArchitect.io
contract MarketInterface 
{
    function withdrawEthFromBalance() external;    

    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller) public payable;

    function bid(uint40 _cutieId) public payable;
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
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}


/// @title BlockchainCuties: Collectible and breedable cuties on the Ethereum blockchain.
/// @author https://BlockChainArchitect.io
/// @dev This is the main BlockchainCuties contract. For separated logical sections the code is divided in 
// several separately-instantiated sibling contracts that handle auctions and the genetic combination algorithm. 
// By keeping auctions separate it is possible to upgrade them without disrupting the main contract that tracks
// the ownership of the cutie. The genetic combination algorithm is kept separate so that all of the rest of the 
// code can be open-sourced.
// The contracts:
//
//      - BlockchainCuties: The fundamental code, including main data storage, constants and data types, as well as
//             internal functions for managing these items ans ERC-721 implementation.
//             Various addresses and constraints for operations can be executed only by specific roles - 
//             Owner, Operator and Parties.
//             Methods for interacting with additional features (Plugins).
//             The methods for breeding and keeping track of breeding offers, relies on external genetic combination 
//             contract.
//             Public methods for auctioning or bidding or breeding. 
//
//      - SaleMarket and BreedingMarket: The actual auction functionality is handled in two sibling contracts - one
//             for sales and one for breeding. Auction creation and bidding is mostly mediated through this side of 
//             the core contract.
//
//      - Effects: Contracts allow to use item effects on cuties, implemented as plugins. Items are not stored in 
//             blockchain to not overload Ethereum network. Operator generates signatures, and Plugins check it
//             and perform effect.
//
//      - ItemMarket: Plugin contract used to transfer money from buyer to seller.
//
//      - Bank: Plugin contract used to receive payments for payed features.

contract BlockchainCutiesCore /*is ERC721, CutieCoreInterface*/
{
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name) 
    {
        return "BlockchainCuties"; 
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol)
    {
        return "BC";
    }
    
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external pure returns (bool)
    {
        return
            interfaceID == 0x6466353c || 
            interfaceID == bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @dev The Birth event is fired as soon as a new cutie is created. This
    ///  is any time a cutie comes into existence through the giveBirth method, as well as
    ///  when a new gen0 cutie is created.
    event Birth(address indexed owner, uint40 cutieId, uint40 momId, uint40 dadId, uint256 genes);

    /// @dev This struct represents a blockchain Cutie. It was ensured that struct fits well into
    ///  exactly two 256-bit words. The order of the members in this structure
    ///  matters because of the Ethereum byte-packing rules.
    ///  Reference: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Cutie
    {
        // The Cutie&#39;s genetic code is in these 256-bits. Cutie&#39;s genes never change.
        uint256 genes;

        // The timestamp from the block when this cutie was created.
        uint40 birthTime;

        // The minimum timestamp after which the cutie can start breeding
        // again.
        uint40 cooldownEndTime;

        // The cutie&#39;s parents ID is set to 0 for gen0 cuties.
        // Because of using 32-bit unsigned integers the limit is 4 billion cuties. 
        // Current Ethereum annual limit is about 500 million transactions.
        uint40 momId;
        uint40 dadId;

        // Set the index in the cooldown array (see below) that means
        // the current cooldown duration for this Cutie. Starts at 0
        // for gen0 cats, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding, regardless
        // of being cutie mom or cutie dad.
        uint16 cooldownIndex;

        // The "generation number" of the cutie. Cutioes minted by the contract
        // for sale are called "gen0" with generation number of 0. All other cuties&#39; 
        // generation number is the larger of their parents&#39; two generation
        // numbers, plus one (i.e. max(mom.generation, dad.generation) + 1)
        uint16 generation;

        // Some optional data used by external contracts
        // Cutie struct is 2x256 bits long.
        uint64 optional;
    }

    /// @dev An array containing the Cutie struct for all Cuties in existence. The ID
    ///  of each cutie is actually an index into this array. ID 0 is the parent 
    /// of all generation 0 cats, and both parents to itself. It is an invalid genetic code.
    Cutie[] public cuties;

    /// @dev A mapping from cutie IDs to the address that owns them. All cuties have
    ///  some valid owner address, even gen0 cuties are created with a non-zero owner.
    mapping (uint40 => address) public cutieIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from CutieIDs to an address that has been approved to call
    ///  transferFrom(). A Cutie can have one approved address for transfer
    ///  at any time. A zero value means that there is no outstanding approval.
    mapping (uint40 => address) public cutieIndexToApproved;

    /// @dev A mapping from CutieIDs to an address that has been approved to use
    ///  this Cutie for breeding via breedWith(). A Cutie can have one approved
    ///  address for breeding at any time. A zero value means that there is no outstanding approval.
    mapping (uint40 => address) public sireAllowedToAddress;


    /// @dev The address of the Market contract used to sell cuties. This
    ///  contract used both peer-to-peer sales and the gen0 sales that are
    ///  initiated each 15 minutes.
    MarketInterface public saleMarket;

    /// @dev The address of a custom Market subclassed contract used for breeding
    ///  auctions. Is to be separated from saleMarket as the actions taken on success
    ///  after a sales and breeding auction are quite different.
    MarketInterface public breedingMarket;


    // Modifiers to check that inputs can be safely stored with a certain
    // number of bits.
    modifier canBeStoredIn40Bits(uint256 _value) {
        require(_value <= 0xFFFFFFFFFF);
        _;
    }    

    /// @notice Returns the total number of Cuties in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() external view returns (uint256)
    {
        return cuties.length - 1;
    }

    /// @notice Returns the total number of Cuties in existence.
    /// @dev Required for ERC-721 compliance.
    function _totalSupply() internal view returns (uint256)
    {
        return cuties.length - 1;
    }
    
    // Internal utility functions assume that their input arguments
    // are valid. Public methods sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a certain Cutie.
    /// @param _claimant the address we are validating against.
    /// @param _cutieId cutie id, only valid when > 0
    function _isOwner(address _claimant, uint40 _cutieId) internal view returns (bool)
    {
        return cutieIndexToOwner[_cutieId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a certain Cutie.
    /// @param _claimant the address we are confirming the cutie is approved for.
    /// @param _cutieId cutie id, only valid when > 0
    function _approvedFor(address _claimant, uint40 _cutieId) internal view returns (bool)
    {
        return cutieIndexToApproved[_cutieId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is done on purpose:
    ///  _approve() and transferFrom() are used together for putting Cuties on auction. 
    ///  There is no value in spamming the log with Approval events in that case.
    function _approve(uint40 _cutieId, address _approved) internal
    {
        cutieIndexToApproved[_cutieId] = _approved;
    }

    /// @notice Returns the number of Cuties owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) external view returns (uint256 count)
    {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Cutie to another address. When transferring to a smart
    ///  contract, ensure that it is aware of ERC-721 (or
    ///  BlockchainCuties specifically), otherwise the Cutie may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _cutieId The ID of the Cutie to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _cutieId) external whenNotPaused canBeStoredIn40Bits(_cutieId)
    {
        // You can only send your own cutie.
        require(_isOwner(msg.sender, uint40(_cutieId)));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, uint40(_cutieId));
    }

    /// @notice Grant another address the right to transfer a perticular Cutie via transferFrom().
    /// This flow is preferred for transferring NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to clear all approvals.
    /// @param _cutieId The ID of the Cutie that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _cutieId) external whenNotPaused canBeStoredIn40Bits(_cutieId)
    {
        // Only cutie&#39;s owner can grant transfer approval.
        require(_isOwner(msg.sender, uint40(_cutieId)));

        // Registering approval replaces any previous approval.
        _approve(uint40(_cutieId), _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _cutieId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        external whenNotPaused canBeStoredIn40Bits(_tokenId)
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleMarket));
        require(_to != address(breedingMarket));
       
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, uint40(_tokenId)) || _isApprovedForAll(_from, msg.sender));
        require(_isOwner(_from, uint40(_tokenId)));

        // Reassign ownership, clearing pending approvals and emitting Transfer event.
        _transfer(_from, _to, uint40(_tokenId));
        ERC721TokenReceiver (_to).onERC721Received(_from, _tokenId, data);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external whenNotPaused canBeStoredIn40Bits(_tokenId)
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleMarket));
        require(_to != address(breedingMarket));
       
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, uint40(_tokenId)) || _isApprovedForAll(_from, msg.sender));
        require(_isOwner(_from, uint40(_tokenId)));

        // Reassign ownership, clearing pending approvals and emitting Transfer event.
        _transfer(_from, _to, uint40(_tokenId));
    }

    /// @notice Transfer a Cutie owned by another address, for which the calling address
    ///  has been granted transfer approval by the owner.
    /// @param _from The address that owns the Cutie to be transfered.
    /// @param _to Any address, including the caller address, can take ownership of the Cutie.
    /// @param _tokenId The ID of the Cutie to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) 
        external whenNotPaused canBeStoredIn40Bits(_tokenId) 
    {
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, uint40(_tokenId)) || _isApprovedForAll(_from, msg.sender));
        require(_isOwner(_from, uint40(_tokenId)));

        // Reassign ownership, clearing pending approvals and emitting Transfer event.
        _transfer(_from, _to, uint40(_tokenId));
    }

    /// @notice Returns the address currently assigned ownership of a given Cutie.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _cutieId)
        external
        view
        canBeStoredIn40Bits(_cutieId)
        returns (address owner)
    {
        owner = cutieIndexToOwner[uint40(_cutieId)];

        require(owner != address(0));
    }

    /// @notice Returns the nth Cutie assigned to an address, with n specified by the
    ///  _index argument.
    /// @param _owner The owner of the Cuties we are interested in.
    /// @param _index The zero-based index of the cutie within the owner&#39;s list of cuties.
    ///  Must be less than balanceOf(_owner).
    /// @dev This method must not be called by smart contract code. It will almost
    ///  certainly blow past the block gas limit once there are a large number of
    ///  Cuties in existence. Exists only to allow off-chain queries of ownership.
    ///  Optional method for ERC-721.
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 cutieId)
    {
        uint40 count = 0;
        for (uint40 i = 1; i <= _totalSupply(); ++i) {
            if (cutieIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external pure returns (uint256)
    {
        return _index;
    }

    /// @dev A mapping from Cuties owner (account) to an address that has been approved to call
    ///  transferFrom() for all cuties, owned by owner.
    ///  Only one approved address is permitted for each account for transfer
    ///  at any time. A zero value means there is no outstanding approval.
    mapping (address => address) public addressToApprovedAll;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your asset.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external
    {
        if (_approved)
        {
            addressToApprovedAll[msg.sender] = _operator;
        }
        else
        {
            delete addressToApprovedAll[msg.sender];
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) 
        external view canBeStoredIn40Bits(_tokenId) 
        returns (address)
    {
        require(_tokenId <= _totalSupply());

        if (cutieIndexToApproved[uint40(_tokenId)] != address(0))
        {
            return cutieIndexToApproved[uint40(_tokenId)];
        }

        address owner = cutieIndexToOwner[uint40(_tokenId)];
        return addressToApprovedAll[owner];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return addressToApprovedAll[_owner] == _operator;
    }

    function _isApprovedForAll(address _owner, address _operator) internal view returns (bool)
    {
        return addressToApprovedAll[_owner] == _operator;
    }

    /// @dev A lookup table that shows the cooldown duration after a successful
    ///  breeding action, called "breeding cooldown". The cooldown roughly doubles each time
    /// a cutie is bred, so that owners don&#39;t breed the same cutie continuously. Maximum cooldown is seven days.
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

    function setCooldown(uint16 index, uint32 newCooldown) public onlyOwner
    {
        cooldowns[index] = newCooldown;
    }

    /// @dev An internal method that creates a new cutie and stores it. This
    ///  method does not check anything and should only be called when the
    ///  input data is valid for sure. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _momId The cutie ID of the mom of this cutie (zero for gen0)
    /// @param _dadId The cutie ID of the dad of this cutie (zero for gen0)
    /// @param _generation The generation number of this cutie, must be computed by caller.
    /// @param _genes The cutie&#39;s genetic code.
    /// @param _owner The initial owner of this cutie, must be non-zero (except for the unCutie, ID 0)
    function _createCutie(
        uint40 _momId,
        uint40 _dadId,
        uint16 _generation,
        uint256 _genes,
        address _owner,
        uint40 _birthTime
    )
        internal
        returns (uint40)
    {
        // New cutie starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > cooldowns.length) {
            cooldownIndex = uint16(cooldowns.length - 1);
        }

        Cutie memory _cutie = Cutie({
            genes: _genes, 
            birthTime: _birthTime, 
            cooldownEndTime: 0, 
            momId: _momId, 
            dadId: _dadId, 
            cooldownIndex: cooldownIndex, 
            generation: _generation,
            optional: 0
        });
        uint256 newCutieId256 = cuties.push(_cutie) - 1;

        // Check if id can fit into 40 bits
        require(newCutieId256 <= 0xFFFFFFFFFF);

        uint40 newCutieId = uint40(newCutieId256);

        // emit the birth event
        emit Birth(_owner, newCutieId, _cutie.momId, _cutie.dadId, _cutie.genes);

        // This will assign ownership, as well as emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newCutieId);

        return newCutieId;
    }
  
    /// @notice Returns all the relevant information about a certain cutie.
    /// @param _id The ID of the cutie of interest.
    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    ) {
        Cutie storage cutie = cuties[_id];

        genes = cutie.genes;
        birthTime = cutie.birthTime;
        cooldownEndTime = cutie.cooldownEndTime;
        momId = cutie.momId;
        dadId = cutie.dadId;
        cooldownIndex = cutie.cooldownIndex;
        generation = cutie.generation;
    }    
    
    /// @dev Assigns ownership of a particular Cutie to an address.
    function _transfer(address _from, address _to, uint40 _cutieId) internal {
        // since the number of cuties is capped to 2^40
        // there is no way to overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        cutieIndexToOwner[_cutieId] = _to;
        // When creating new cuties _from is 0x0, but we cannot account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // once the cutie is transferred also clear breeding allowances
            delete sireAllowedToAddress[_cutieId];
            // clear any previously approved ownership exchange
            delete cutieIndexToApproved[_cutieId];
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _cutieId);
    }

    /// @dev For transferring a cutie owned by this contract to the specified address.
    ///  Used to rescue lost cuties. (There is no "proper" flow where this contract
    ///  should be the owner of any Cutie. This function exists for us to reassign
    ///  the ownership of Cuties that users may have accidentally sent to our address.)
    /// @param _cutieId - ID of cutie
    /// @param _recipient - Address to send the cutie to
    function restoreCutieToAddress(uint40 _cutieId, address _recipient) public onlyOperator whenNotPaused {
        require(_isOwner(this, _cutieId));
        _transfer(this, _recipient, _cutieId);
    }

    address ownerAddress;
    address operatorAddress;

    bool public paused = false;

    modifier onlyOwner()
    {
        require(msg.sender == ownerAddress);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner
    {
        require(_newOwner != address(0));

        ownerAddress = _newOwner;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == ownerAddress);
        _;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));

        operatorAddress = _newOperator;
    }

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused
    {
        paused = true;
    }

    string public metadataUrlPrefix = "https://blockchaincuties.co/cutie/";
    string public metadataUrlSuffix = ".svg";

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string infoUrl)
    {
        return 
            concat(toSlice(metadataUrlPrefix), 
                toSlice(concat(toSlice(uintToString(_tokenId)), toSlice(metadataUrlSuffix))));
    }

    function setMetadataUrl(string _metadataUrlPrefix, string _metadataUrlSuffix) public onlyOwner
    {
        metadataUrlPrefix = _metadataUrlPrefix;
        metadataUrlSuffix = _metadataUrlSuffix;
    }


    mapping(address => PluginInterface) public plugins;
    PluginInterface[] public pluginsArray;
    mapping(uint40 => address) public usedSignes;
    uint40 public minSignId;

    event GenesChanged(uint40 indexed cutieId, uint256 oldValue, uint256 newValue);
    event CooldownEndTimeChanged(uint40 indexed cutieId, uint40 oldValue, uint40 newValue);
    event CooldownIndexChanged(uint40 indexed cutieId, uint16 ololdValue, uint16 newValue);
    event GenerationChanged(uint40 indexed cutieId, uint16 oldValue, uint16 newValue);
    event OptionalChanged(uint40 indexed cutieId, uint64 oldValue, uint64 newValue);
    event SignUsed(uint40 signId, address sender);
    event MinSignSet(uint40 signId);

    /// @dev Sets the reference to the plugin contract.
    /// @param _address - Address of plugin contract.
    function addPlugin(address _address) public onlyOwner
    {
        PluginInterface candidateContract = PluginInterface(_address);

        // verify that a contract is what we expect
        require(candidateContract.isPluginInterface());

        // Set the new contract address
        plugins[_address] = candidateContract;
        pluginsArray.push(candidateContract);
    }

    /// @dev Remove plugin and calls onRemove to cleanup
    function removePlugin(address _address) public onlyOwner
    {
        plugins[_address].onRemove();
        delete plugins[_address];

        uint256 kindex = 0;
        while (kindex < pluginsArray.length)
        {
            if (address(pluginsArray[kindex]) == _address)
            {
                pluginsArray[kindex] = pluginsArray[pluginsArray.length-1];
                pluginsArray.length--;
            }
            else
            {
                kindex++;
            }
        }
    }

    /// @dev Put a cutie up for plugin feature.
    function runPlugin(
        address _pluginAddress,
        uint40 _cutieId,
        uint256 _parameter
    )
        public
        whenNotPaused
        payable
    {
        // If cutie is already on any auction or in adventure, this will throw
        // because it will be owned by the other contract.
        // If _cutieId is 0, then cutie is not used on this feature.
        require(_cutieId == 0 || _isOwner(msg.sender, _cutieId));
        require(address(plugins[_pluginAddress]) != address(0));
        if (_cutieId > 0)
        {
            _approve(_cutieId, _pluginAddress);
        }

        // Plugin contract throws if inputs are invalid and clears
        // transfer after escrowing the cutie.
        plugins[_pluginAddress].run.value(msg.value)(
            _cutieId,
            _parameter,
            msg.sender
        );
    }

    /// @dev Called from plugin contract when using items as effect
    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    )
    {
        Cutie storage cutie = cuties[_id];
        genes = cutie.genes;
    }

    /// @dev Called from plugin contract when using items as effect
    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public
        whenNotPaused
    {
        // if caller is registered plugin contract
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.genes != _genes)
        {
            emit GenesChanged(_cutieId, cutie.genes, _genes);
            cutie.genes = _genes;
        }
    }

    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    ) {
        Cutie storage cutie = cuties[_id];

        cooldownEndTime = cutie.cooldownEndTime;
    }

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.cooldownEndTime != _cooldownEndTime)
        {
            emit CooldownEndTimeChanged(_cutieId, cutie.cooldownEndTime, _cooldownEndTime);
            cutie.cooldownEndTime = _cooldownEndTime;
        }
    }

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    ) {
        Cutie storage cutie = cuties[_id];

        cooldownIndex = cutie.cooldownIndex;
    }

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.cooldownIndex != _cooldownIndex)
        {
            emit CooldownIndexChanged(_cutieId, cutie.cooldownIndex, _cooldownIndex);
            cutie.cooldownIndex = _cooldownIndex;
        }
    }

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.generation != _generation)
        {
            emit GenerationChanged(_cutieId, cutie.generation, _generation);
            cutie.generation = _generation;
        }
    }

    function getGeneration(uint40 _id)
        public
        view
        returns (uint16 generation)
    {
        Cutie storage cutie = cuties[_id];
        generation = cutie.generation;
    }

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.optional != _optional)
        {
            emit OptionalChanged(_cutieId, cutie.optional, _optional);
            cutie.optional = _optional;
        }
    }

    function getOptional(uint40 _id)
        public
        view
        returns (uint64 optional)
    {
        Cutie storage cutie = cuties[_id];
        optional = cutie.optional;
    }

    /// @dev Common function to be used also in backend
    function hashArguments(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(_pluginAddress, _signId, _cutieId, _value, _parameter);
    }

    /// @dev Common function to be used also in backend
    function getSigner(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(_pluginAddress, _signId, _cutieId, _value, _parameter);
        return ecrecover(msgHash, _v, _r, _s);
    }

    /// @dev Common function to be used also in backend
    function isValidSignature(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        )
        public
        view
        returns (bool)
    {
        return getSigner(_pluginAddress, _signId, _cutieId, _value, _parameter, _v, _r, _s) == operatorAddress;
    }

    /// @dev Put a cutie up for plugin feature with signature.
    ///  Can be used for items equip, item sales and other features.
    ///  Signatures are generated by Operator role.
    function runPluginSigned(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        whenNotPaused
        payable
    {
        // If cutie is already on any auction or in adventure, this will throw
        // as it will be owned by the other contract.
        // If _cutieId is 0, then cutie is not used on this feature.
        require(_cutieId == 0 || _isOwner(msg.sender, _cutieId));
    
        require(address(plugins[_pluginAddress]) != address(0));    

        require (usedSignes[_signId] == address(0));
        require (_signId >= minSignId);
        // value can also be zero for free calls
        require (_value <= msg.value);

        require (isValidSignature(_pluginAddress, _signId, _cutieId, _value, _parameter, _v, _r, _s));
        
        usedSignes[_signId] = msg.sender;
        emit SignUsed(_signId, msg.sender);

        // Plugin contract throws if inputs are invalid and clears
        // transfer after escrowing the cutie.
        plugins[_pluginAddress].runSigned.value(_value)(
            _cutieId,
            _parameter,
            msg.sender
        );
    }

    /// @dev Sets minimal signId, than can be used.
    ///       All unused signatures less than signId will be cancelled on off-chain server
    ///       and unused items will be transfered back to owner.
    function setMinSign(uint40 _newMinSignId)
        public
        onlyOperator
    {
        require (_newMinSignId > minSignId);
        minSignId = _newMinSignId;
        emit MinSignSet(minSignId);
    }


    event BreedingApproval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // Set in case the core contract is broken and an upgrade is required
    address public upgradedContractAddress;

    function isCutieCore() pure public returns (bool) { return true; }

    /// @notice Creates the main BlockchainCuties smart contract instance.
    function BlockchainCutiesCore() public
    {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial owner
        ownerAddress = msg.sender;

        // the creator of the contract is also the initial operator
        operatorAddress = msg.sender;

        // start with the mythical cutie 0 - so there are no generation-0 parent issues
        _createCutie(0, 0, 0, uint256(-1), address(0), 0);
    }

    event ContractUpgrade(address newContract);

    /// @dev Aimed to mark the smart contract as upgraded if there is a crucial
    ///  bug. This keeps track of the new contract and indicates that the new address is set. 
    /// Updating to the new contract address is up to the clients. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _newAddress new address
    function setUpgradedAddress(address _newAddress) public onlyOwner whenPaused
    {
        require(_newAddress != address(0));
        upgradedContractAddress = _newAddress;
        emit ContractUpgrade(upgradedContractAddress);
    }

    /// @dev Override unpause so it requires upgradedContractAddress not set, because then the contract was upgraded.
    function unpause() public onlyOwner whenPaused
    {
        require(upgradedContractAddress == address(0));

        paused = false;
    }

    // Counts the number of cuties the contract owner has created.
    uint40 public promoCutieCreatedCount;
    uint40 public gen0CutieCreatedCount;
    uint40 public gen0Limit = 50000;
    uint40 public promoLimit = 5000;

    /// @dev Creates a new gen0 cutie with the given genes and
    ///  creates an auction for it.
    function createGen0Auction(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration) public onlyOperator
    {
        require(gen0CutieCreatedCount < gen0Limit);
        uint40 cutieId = _createCutie(0, 0, 0, _genes, address(this), uint40(now));
        _approve(cutieId, saleMarket);

        saleMarket.createAuction(
            cutieId,
            startPrice,
            endPrice,
            duration,
            address(this)
        );

        gen0CutieCreatedCount++;
    }

    function createPromoCutie(uint256 _genes, address _owner) public onlyOperator
    {
        require(promoCutieCreatedCount < promoLimit);
        if (_owner == address(0)) {
             _owner = operatorAddress;
        }
        promoCutieCreatedCount++;
        gen0CutieCreatedCount++;
        _createCutie(0, 0, 0, _genes, _owner, uint40(now));
    }

    /// @dev Put a cutie up for auction to be dad.
    ///  Performs checks to ensure the cutie can be dad, then
    ///  delegates to reverse auction.
    ///  Optional money amount can be sent to contract to feature auction.
    ///  Pricea are available on web.
    function createBreedingAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
        public
        whenNotPaused
        payable
    {
        // Auction contract checks input sizes
        // If cutie is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_isOwner(msg.sender, _cutieId));
        require(canBreed(_cutieId));
        _approve(_cutieId, breedingMarket);
        // breeding auction function is called if inputs are invalid and clears
        // transfer and sire approval after escrowing the cutie.
        breedingMarket.createAuction.value(msg.value)(
            _cutieId,
            _startPrice,
            _endPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Sets the reference to the breeding auction.
    /// @param _breedingAddress - Address of breeding market contract.
    /// @param _saleAddress - Address of sale market contract.
    function setMarketAddress(address _breedingAddress, address _saleAddress) public onlyOwner
    {
        //require(address(breedingMarket) == address(0));
        //require(address(saleMarket) == address(0));

        breedingMarket = MarketInterface(_breedingAddress);
        saleMarket = MarketInterface(_saleAddress);
    }

    /// @dev Completes a breeding auction by bidding.
    ///  Immediately breeds the winning mom with the dad on auction.
    /// @param _dadId - ID of the dad on auction.
    /// @param _momId - ID of the mom owned by the bidder.
    function bidOnBreedingAuction(
        uint40 _dadId,
        uint40 _momId
    )
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        // Auction contract checks input sizes
        require(_isOwner(msg.sender, _momId));
        require(canBreed(_momId));
        require(_canMateViaMarketplace(_momId, _dadId));

        // breeding auction will throw if the bid fails.
        breedingMarket.bid.value(msg.value)(_dadId);
        return _breedWith(_momId, _dadId);
    }

    /// @dev Put a cutie up for auction.
    ///  Does some ownership trickery for creating auctions in one transaction.
    ///  Optional money amount can be sent to contract to feature auction.
    ///  Pricea are available on web.
    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
        public
        whenNotPaused
        payable
    {
        // Auction contract checks input sizes
        // If cutie is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_isOwner(msg.sender, _cutieId));
        _approve(_cutieId, saleMarket);
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the cutie.
        saleMarket.createAuction.value(msg.value)(
            _cutieId,
            _startPrice,
            _endPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev The address of the sibling contract that is used to implement the genetic combination algorithm.
    GeneMixerInterface geneMixer;

    /// @dev Check if dad has authorized breeding with the mom. True if both dad
    ///  and mom have the same owner, or if the dad has given breeding permission to
    ///  the mom&#39;s owner (via approveBreeding()).
    function _isBreedingPermitted(uint40 _dadId, uint40 _momId) internal view returns (bool)
    {
        address momOwner = cutieIndexToOwner[_momId];
        address dadOwner = cutieIndexToOwner[_dadId];

        // Breeding is approved if they have same owner, or if the mom&#39;s owner was given
        // permission to breed with the dad.
        return (momOwner == dadOwner || sireAllowedToAddress[_dadId] == momOwner);
    }

    /// @dev Update the address of the genetic contract.
    /// @param _address An address of a GeneMixer contract instance to be used from this point forward.
    function setGeneMixerAddress(address _address) public onlyOwner
    {
        GeneMixerInterface candidateContract = GeneMixerInterface(_address);

        require(candidateContract.isGeneMixer());

        // Set the new contract address
        geneMixer = candidateContract;
    }

    /// @dev Checks that a given cutie is able to breed. Requires that the
    ///  current cooldown is finished (for dads)
    function _canBreed(Cutie _cutie) internal view returns (bool)
    {
        return _cutie.cooldownEndTime <= now;
    }

    /// @notice Grants approval to another user to sire with one of your Cuties.
    /// @param _addr The address that will be able to sire with your Cutie. Set to
    ///  address(0) to clear all breeding approvals for this Cutie.
    /// @param _dadId A Cutie that you own that _addr will now be able to dad with.
    function approveBreeding(address _addr, uint40 _dadId) public whenNotPaused
    {
        require(_isOwner(msg.sender, _dadId));
        sireAllowedToAddress[_dadId] = _addr;
        emit BreedingApproval(msg.sender, _addr, _dadId);
    }

    /// @dev Set the cooldownEndTime for the given Cutie, based on its current cooldownIndex.
    ///  Also increments the cooldownIndex (unless it has hit the cap).
    /// @param _cutie A reference to the Cutie in storage which needs its timer started.
    function _triggerCooldown(uint40 _cutieId, Cutie storage _cutie) internal
    {
        // Compute the end of the cooldown time, based on current cooldownIndex
        uint40 oldValue = _cutie.cooldownIndex;
        _cutie.cooldownEndTime = uint40(now + cooldowns[_cutie.cooldownIndex]);
        emit CooldownEndTimeChanged(_cutieId, oldValue, _cutie.cooldownEndTime);

        // Increment the breeding count.
        if (_cutie.cooldownIndex + 1 < cooldowns.length) {
            uint16 oldValue2 = _cutie.cooldownIndex;
            _cutie.cooldownIndex++;
            emit CooldownIndexChanged(_cutieId, oldValue2, _cutie.cooldownIndex);
        }
    }

    /// @notice Checks that a certain cutie is not
    ///  in the middle of a breeding cooldown and is able to breed.
    /// @param _cutieId reference the id of the cutie, any user can inquire about it
    function canBreed(uint40 _cutieId)
        public
        view
        returns (bool)
    {
        require(_cutieId > 0);
        Cutie storage cutie = cuties[_cutieId];
        return _canBreed(cutie);
    }

    /// @dev Check if given mom and dad are a valid mating pair.
    function _canPairMate(
        Cutie storage _mom,
        uint40 _momId,
        Cutie storage _dad,
        uint40 _dadId
    )
        private
        view
        returns(bool)
    {
        // A Cutie can&#39;t breed with itself.
        if (_dadId == _momId) { 
            return false; 
        }

        // Cuties can&#39;t breed with their parents.
        if (_mom.momId == _dadId) {
            return false;
        }
        if (_mom.dadId == _dadId) {
            return false;
        }

        if (_dad.momId == _momId) {
            return false;
        }
        if (_dad.dadId == _momId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either cat is
        // gen zero (has a mom ID of zero).
        if (_dad.momId == 0) {
            return true;
        }
        if (_mom.momId == 0) {
            return true;
        }

        // Cuties can&#39;t breed with full or half siblings.
        if (_dad.momId == _mom.momId) {
            return false;
        }
        if (_dad.momId == _mom.dadId) {
            return false;
        }
        if (_dad.dadId == _mom.momId) {
            return false;
        }
        if (_dad.dadId == _mom.dadId) {
            return false;
        }

        if (geneMixer.canBreed(_momId, _mom.genes, _dadId, _dad.genes)) {
            return true;
        }
        return false;
    }

    /// @notice Checks to see if two cuties can breed together (checks both
    ///  ownership and breeding approvals, but does not check if both cuties are ready for
    ///  breeding).
    /// @param _momId The ID of the proposed mom.
    /// @param _dadId The ID of the proposed dad.
    function canBreedWith(uint40 _momId, uint40 _dadId)
        public
        view
        returns(bool)
    {
        require(_momId > 0);
        require(_dadId > 0);
        Cutie storage mom = cuties[_momId];
        Cutie storage dad = cuties[_dadId];
        return _canPairMate(mom, _momId, dad, _dadId) && _isBreedingPermitted(_dadId, _momId);
    }
    
    /// @dev Internal check to see if a given dad and mom are a valid mating pair for
    ///  breeding via market (this method doesn&#39;t check ownership and if mating is allowed).
    function _canMateViaMarketplace(uint40 _momId, uint40 _dadId)
        internal
        view
        returns (bool)
    {
        Cutie storage mom = cuties[_momId];
        Cutie storage dad = cuties[_dadId];
        return _canPairMate(mom, _momId, dad, _dadId);
    }

    /// @notice Breed cuties that you own, or for which you
    ///  have previously been given Breeding approval. Will either make your cutie give birth, or will
    ///  fail.
    /// @param _momId The ID of the Cutie acting as mom (will end up give birth if successful)
    /// @param _dadId The ID of the Cutie acting as dad (will begin its breeding cooldown if successful)
    function breedWith(uint40 _momId, uint40 _dadId) public whenNotPaused returns (uint40)
    {
        // Caller must own the mom.
        require(_isOwner(msg.sender, _momId));

        // Neither dad nor mom can be on auction during
        // breeding.
        // For mom: The caller of this function can&#39;t be the owner of the mom
        //   because the owner of a Cutie on auction is the auction house, and the
        //   auction house will never call breedWith().
        // For dad: Similarly, a dad on auction will be owned by the auction house
        //   and the act of transferring ownership will have cleared any outstanding
        //   breeding approval.
        // Thus we don&#39;t need check if either cutie
        // is on auction.

        // Check that mom and dad are both owned by caller, or that the dad
        // has given breeding permission to caller (i.e. mom&#39;s owner).
        // Will fail for _dadId = 0
        require(_isBreedingPermitted(_dadId, _momId));

        // Grab a reference to the potential mom
        Cutie storage mom = cuties[_momId];

        // Make sure mom&#39;s cooldown isn&#39;t active, or in the middle of a breeding cooldown
        require(_canBreed(mom));

        // Grab a reference to the potential dad
        Cutie storage dad = cuties[_dadId];

        // Make sure dad cooldown isn&#39;t active, or in the middle of a breeding cooldown
        require(_canBreed(dad));

        // Test that these cuties are a valid mating pair.
        require(_canPairMate(
            mom,
            _momId,
            dad,
            _dadId
        ));

        return _breedWith(_momId, _dadId);
    }

    /// @dev Internal utility function to start breeding, assumes that all breeding
    ///  requirements have been checked.
    function _breedWith(uint40 _momId, uint40 _dadId) internal returns (uint40)
    {
        // Grab a reference to the Cuties from storage.
        Cutie storage dad = cuties[_dadId];
        Cutie storage mom = cuties[_momId];

        // Trigger the cooldown for both parents.
        _triggerCooldown(_dadId, dad);
        _triggerCooldown(_momId, mom);

        // Clear breeding permission for both parents.
        delete sireAllowedToAddress[_momId];
        delete sireAllowedToAddress[_dadId];

        // Check that the mom is a valid cutie.
        require(mom.birthTime != 0);

        // Determine the higher generation number of the two parents
        uint16 parentGen = mom.generation;
        if (dad.generation > mom.generation) {
            parentGen = dad.generation;
        }

        // Call the gene mixing operation.
        uint256 childGenes = geneMixer.mixGenes(mom.genes, dad.genes);

        // Make the new cutie
        address owner = cutieIndexToOwner[_momId];
        uint40 cutieId = _createCutie(_momId, _dadId, parentGen + 1, childGenes, owner, mom.cooldownEndTime);

        // return the new cutie&#39;s ID
        return cutieId;
    }

    mapping(address => uint40) isTutorialPetUsed;

    /// @dev Completes a breeding tutorial cutie (non existing in blockchain)
    ///  with auction by bidding. Immediately breeds with dad on auction.
    /// @param _dadId - ID of the dad on auction.
    function bidOnBreedingAuctionTutorial(
        uint40 _dadId
    )
        public
        payable
        whenNotPaused
        returns (uint)
    {
        require(isTutorialPetUsed[msg.sender] == 0);

        // breeding auction will throw if the bid fails.
        breedingMarket.bid.value(msg.value)(_dadId);

        // Grab a reference to the Cuties from storage.
        Cutie storage dad = cuties[_dadId];

        // Trigger the cooldown for parent.
        _triggerCooldown(_dadId, dad);

        // Clear breeding permission for parent.
        delete sireAllowedToAddress[_dadId];

        // Tutorial pet gen is 26
        uint16 parentGen = 26;
        if (dad.generation > parentGen) {
            parentGen = dad.generation;
        }

        // tutorial pet genome is zero
        uint256 childGenes = geneMixer.mixGenes(0x0, dad.genes);

        // tutorial pet id is zero
        uint40 cutieId = _createCutie(0, _dadId, parentGen + 1, childGenes, msg.sender, 12);

        isTutorialPetUsed[msg.sender] = cutieId;

        // return the new cutie&#39;s ID
        return cutieId;
    }

    address party1address;
    address party2address;
    address party3address;
    address party4address;
    address party5address;

    /// @dev Setup project owners
    function setParties(address _party1, address _party2, address _party3, address _party4, address _party5) public onlyOwner
    {
        require(_party1 != address(0));
        require(_party2 != address(0));
        require(_party3 != address(0));
        require(_party4 != address(0));
        require(_party5 != address(0));

        party1address = _party1;
        party2address = _party2;
        party3address = _party3;
        party4address = _party4;
        party5address = _party5;
    }

    /// @dev Reject all Ether which is not from game contracts from being sent here.
    function() external payable {
        require(
            msg.sender == address(saleMarket) ||
            msg.sender == address(breedingMarket) ||
            address(plugins[msg.sender]) != address(0)
        );
    }

    /// @dev The balance transfer from the market and plugins contract
    /// to the CutieCore contract.
    function withdrawBalances() external
    {
        require(
            msg.sender == ownerAddress || 
            msg.sender == operatorAddress);

        saleMarket.withdrawEthFromBalance();
        breedingMarket.withdrawEthFromBalance();
        for (uint32 i = 0; i < pluginsArray.length; ++i)        
        {
            pluginsArray[i].withdraw();
        }
    }

    /// @dev The balance transfer from CutieCore contract to project owners
    function withdrawEthFromBalance() external
    {
        require(
            msg.sender == party1address ||
            msg.sender == party2address ||
            msg.sender == party3address ||
            msg.sender == party4address ||
            msg.sender == party5address ||
            msg.sender == ownerAddress || 
            msg.sender == operatorAddress);

        require(party1address != 0);
        require(party2address != 0);
        require(party3address != 0);
        require(party4address != 0);
        require(party5address != 0);

        uint256 total = address(this).balance;

        party1address.transfer(total*105/1000);
        party2address.transfer(total*105/1000);
        party3address.transfer(total*140/1000);
        party4address.transfer(total*140/1000);
        party5address.transfer(total*510/1000);
    }

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <<span class="__cf_email__" data-cfemail="0d6c7f6c6e656364694d63627969627923636879">[email&#160;protected]</span>>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a &#39;slice&#39;. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first &#39;.&#39;,
 *      modifying s to only contain the remainder of the string after the &#39;.&#39;.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew(&#39;.&#39;)` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

    struct slice
    {
        uint _len;
        uint _ptr;
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string self) internal pure returns (slice)
    {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(uint dest, uint src, uint len) private pure
    {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice self, slice other) internal pure returns (string)
    {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }


    function uintToString(uint256 a) internal pure returns (string result)
    {
        string memory r = "";
        do
        {
            uint b = a % 10;
            a /= 10;

            string memory c = "";

            if (b == 0) c = "0";
            else if (b == 1) c = "1";
            else if (b == 2) c = "2";
            else if (b == 3) c = "3";
            else if (b == 4) c = "4";
            else if (b == 5) c = "5";
            else if (b == 6) c = "6";
            else if (b == 7) c = "7";
            else if (b == 8) c = "8";
            else if (b == 9) c = "9";

            r = concat(toSlice(c), toSlice(r));
        }
        while (a > 0);
        result = r;
    }
}