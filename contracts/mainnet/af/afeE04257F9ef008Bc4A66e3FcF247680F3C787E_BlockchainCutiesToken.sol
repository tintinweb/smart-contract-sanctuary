pragma solidity ^0.4.23;

import "./CutieERC721Metadata.sol";
import "./ERC721TokenReceiver.sol";
import "./TokenRecipientInterface.sol";

contract BlockchainCutiesToken is CutieERC721Metadata {

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // @dev This struct represents a blockchain Cutie. It was ensured that struct fits well into
    // exactly two 256-bit words. The order of the members in this structure
    // matters because of the Ethereum byte-packing rules.CutieERC721Metadata
    // Reference: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Cutie {
        // The Cutie's genetic code is in these 256-bits. Cutie's genes never change.
        uint256 genes;

        // The timestamp from the block when this cutie was created.
        uint40 birthTime;

        // The minimum timestamp after which the cutie can start breeding
        // again.
        uint40 cooldownEndTime;

        // The cutie's parents ID is set to 0 for gen0 cuties.
        uint40 momId;
        uint40 dadId;

        // Set the index in the cooldown array (see below) that means
        // the current cooldown duration for this Cutie. Starts at 0
        // for gen0 cats, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding, regardless
        // of being cutie mom or cutie dad.
        uint16 cooldownIndex;

        // The "generation number" of the cutie. Cuties minted by the contract
        // for sale are called "gen0" with generation number of 0. All other cuties'
        // generation number is the larger of their parents' two generation
        // numbers, plus one (i.e. max(mom.generation, dad.generation) + 1)
        uint16 generation;

        // Some optional data used by external contracts
        // Cutie struct is 2x256 bits long.
        uint64 optional;
    }

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('tokenURI(uint256)'));

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Enumerable =
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('tokenByIndex(uint256)')) ^
        bytes4(keccak256('tokenOfOwnerByIndex(address, uint256)'));

    // @dev An mapping containing the Cutie struct for all Cuties in existence.
    // The ID of each cutie is actually an index into this mapping.
    //  ID 0 is the parent of all generation 0 cats, and both parents to itself. It is an invalid genetic code.
    mapping (uint40 => Cutie) public cuties;

    // @dev Total cuties count
    uint256 total;

    // @dev Core game contract address
    address public gameAddress;

    // @dev A mapping from cutie IDs to the address that owns them. All cuties have
    // some valid owner address, even gen0 cuties are created with a non-zero owner.
    mapping (uint40 => address) public cutieIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    // Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    // @dev A mapping from CutieIDs to an address that has been approved to call
    // transferFrom(). A Cutie can have one approved address for transfer
    // at any time. A zero value means that there is no outstanding approval.
    mapping (uint40 => address) public cutieIndexToApproved;

    // @dev A mapping from Cuties owner (account) to an address that has been approved to call
    // transferFrom() for all cuties, owned by owner.
    // Only one approved address is permitted for each account for transfer
    // at any time. A zero value means there is no outstanding approval.
    mapping (address => mapping (address => bool)) public addressToApprovedAll;

    // Modifiers to check that inputs can be safely stored with a certain number of bits
    modifier canBeStoredIn40Bits(uint256 _value) {
        require(_value <= 0xFFFFFFFFFF, "Value can't be stored in 40 bits");
        _;
    }

    modifier onlyGame {
        require(msg.sender == gameAddress || msg.sender == ownerAddress, "Access denied");
        _;
    }

    constructor() public {
        // Starts paused.
        paused = true;
    }

    // @dev Accept all Ether
    function() external payable {}

    function setup(uint256 _total) external onlyGame whenPaused {
        require(total == 0, "Contract already initialized");
        total = _total;
        paused = false;
    }

    function setGame(address _gameAddress) external onlyOwner {
        gameAddress = _gameAddress;
    }

    // @notice Query if a contract implements an interface
    // @param interfaceID The interface identifier, as specified in ERC-165
    // @dev Interface identification is specified in ERC-165. This function
    //  uses less than 30,000 gas.
    // @return `true` if the contract implements `interfaceID` and
    //  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
        interfaceID == 0x6466353c ||
        interfaceID == 0x80ac58cd || // ERC721
        interfaceID == INTERFACE_SIGNATURE_ERC721Metadata ||
        interfaceID == INTERFACE_SIGNATURE_ERC721Enumerable ||
        interfaceID == bytes4(keccak256('supportsInterface(bytes4)'));
    }

    // @notice Returns the total number of Cuties in existence.
    // @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256) {
        return total;
    }

    // @notice Returns the number of Cuties owned by a specific address.
    // @param _owner The owner address to check.
    // @dev Required for ERC-721 compliance
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != 0x0, "Owner can't be zero address");
        return ownershipTokenCount[_owner];
    }

    // @notice Returns the address currently assigned ownership of a given Cutie.
    // @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _cutieId) external view canBeStoredIn40Bits(_cutieId) returns (address owner) {
        owner = cutieIndexToOwner[uint40(_cutieId)];
        require(owner != address(0), "Owner query for nonexistent token");
    }

    // @notice Returns the address currently assigned ownership of a given Cutie.
    // @dev do not revert when cutie has no owner
    function ownerOfCutie(uint256 _cutieId) external view canBeStoredIn40Bits(_cutieId) returns (address) {
        return cutieIndexToOwner[uint40(_cutieId)];
    }

    // @notice Enumerate valid NFTs
    // @dev Throws if `_index` >= `totalSupply()`.
    // @param _index A counter less than `totalSupply()`
    // @return The token identifier for the `_index`th NFT,
    //  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < total);
        return _index - 1;
    }

    // @notice Returns the nth Cutie assigned to an address, with n specified by the
    //  _index argument.
    // @param _owner The owner of the Cuties we are interested in.
    // @param _index The zero-based index of the cutie within the owner's list of cuties.
    //  Must be less than balanceOf(_owner).
    // @dev This method must not be called by smart contract code. It will almost
    //  certainly blow past the block gas limit once there are a large number of
    //  Cuties in existence. Exists only to allow off-chain queries of ownership.
    //  Optional method for ERC-721.
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 cutieId) {
        require(_owner != 0x0, "Owner can't be 0x0");
        uint40 count = 0;
        for (uint40 i = 1; i <= totalSupply(); ++i) {
            if (_isOwner(_owner, i)) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }

    // @notice Transfers the ownership of an NFT from one address to another address.
    // @dev Throws unless `msg.sender` is the current owner, an authorized
    //  operator, or the approved address for this NFT. Throws if `_from` is
    //  not the current owner. Throws if `_to` is the zero address. Throws if
    //  `_tokenId` is not a valid NFT. When transfer is complete, this function
    //  checks if `_to` is a smart contract (code size > 0). If so, it calls
    //  `onERC721Received` on `_to` and throws if the return value is not
    //  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    // @param _from The current owner of the NFT
    // @param _to The new owner
    // @param _tokenId The NFT to transfer
    // @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public whenNotPaused canBeStoredIn40Bits(_tokenId) {
        transferFrom(_from, _to, uint40(_tokenId));

        if (_isContract(_to)) {
            ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
        }
    }

    // @notice Transfers the ownership of an NFT from one address to another address
    // @dev This works identically to the other function with an extra data parameter,
    // except this function just sets data to ""
    // @param _from The current owner of the NFT
    // @param _to The new owner
    // @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    // @notice Transfer a Cutie owned by another address, for which the calling address
    //  has been granted transfer approval by the owner.
    // @param _from The address that owns the Cutie to be transferred.
    // @param _to Any address, including the caller address, can take ownership of the Cutie.
    // @param _tokenId The ID of the Cutie to be transferred.
    // @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused canBeStoredIn40Bits(_tokenId) {
        require(_to != address(0), "Wrong cutie destination");
        require(_to != address(this), "Wrong cutie destination");

        // Check for approval and valid ownership
        require(_isApprovedOrOwner(msg.sender, uint40(_tokenId)), "Caller is not owner nor approved");
        require(_isOwner(_from, uint40(_tokenId)), "Wrong cutie owner");

        // Reassign ownership, clearing pending approvals and emitting Transfer event.
        _transfer(_from, _to, uint40(_tokenId));
    }

    // @notice Transfers a Cutie to another address. When transferring to a smart
    // contract, ensure that it is aware of ERC-721 (or BlockchainCuties specifically),
    // otherwise the Cutie may be lost forever.
    // @param _to The address of the recipient, can be a user or contract.
    // @param _cutieId The ID of the Cutie to transfer.
    // @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _cutieId) public whenNotPaused canBeStoredIn40Bits(_cutieId) {
        require(_to != address(0), "Wrong cutie destination");

        // You can only send your own cutie.
        require(_isOwner(msg.sender, uint40(_cutieId)), "Caller is not a cutie owner");

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, uint40(_cutieId));
    }

    function transferBulk(address[] to, uint[] tokens) public whenNotPaused {
        require(to.length == tokens.length);
        for (uint i = 0; i < to.length; i++) {
            transfer(to[i], tokens[i]);
        }
    }

    function transferMany(address to, uint[] tokens) public whenNotPaused {
        for (uint i = 0; i < tokens.length; i++) {
            transfer(to, tokens[i]);
        }
    }

    // @notice Grant another address the right to transfer a particular Cutie via transferFrom().
    // This flow is preferred for transferring NFTs to contracts.
    // @param _to The address to be granted transfer approval. Pass address(0) to clear all approvals.
    // @param _cutieId The ID of the Cutie that can be transferred if this call succeeds.
    // @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _cutieId) public whenNotPaused canBeStoredIn40Bits(_cutieId) {
        // Only cutie's owner can grant transfer approval.
        require(_isOwner(msg.sender, uint40(_cutieId)), "Caller is not a cutie owner");
        require(msg.sender != _to, "Approval to current owner");

        // Registering approval replaces any previous approval.
        _approve(uint40(_cutieId), _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _cutieId);
    }

    function delegatedApprove(address _from, address _to, uint40 _cutieId) external whenNotPaused onlyGame {
        require(_isOwner(_from, _cutieId), "Wrong cutie owner");
        _approve(_cutieId, _to);
    }

    function approveAndCall(address _spender, uint _tokenId, bytes data) external whenNotPaused returns (bool) {
        approve(_spender, _tokenId);
        TokenRecipientInterface(_spender).receiveApproval(msg.sender, _tokenId, this, data);
        return true;
    }

    // @notice Enable or disable approval for a third party ("operator") to manage
    //  all your asset.
    // @dev Emits the ApprovalForAll event
    // @param _operator Address to add to the set of authorized operators.
    // @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "Approve to caller");

        if (_approved) {
            addressToApprovedAll[msg.sender][_operator] = true;
        } else {
            delete addressToApprovedAll[msg.sender][_operator];
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // @notice Get the approved address for a single NFT
    // @dev Throws if `_tokenId` is not a valid NFT
    // @param _tokenId The NFT to find the approved address for
    // @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view canBeStoredIn40Bits(_tokenId) returns (address) {
        require(_tokenId <= total, "Cutie not exists");
        return cutieIndexToApproved[uint40(_tokenId)];
    }

    // @notice Query if an address is an authorized operator for another address
    // @param _owner The address that owns the NFTs
    // @param _operator The address that acts on behalf of the owner
    // @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return addressToApprovedAll[_owner][_operator];
    }

    // @dev Returns whether `spender` is allowed to manage `cutieId`.
    function _isApprovedOrOwner(address spender, uint40 cutieId) internal view returns (bool) {
        require(_exists(cutieId), "Cutie not exists");
        address owner = cutieIndexToOwner[cutieId];
        return (spender == owner || _approvedFor(spender, cutieId) || isApprovedForAll(owner, spender));
    }

    // @dev Checks if a given address is the current owner of a certain Cutie.
    // @param _claimant the address we are validating against.
    // @param _cutieId cutie id, only valid when > 0
    function _isOwner(address _claimant, uint40 _cutieId) internal view returns (bool) {
        return cutieIndexToOwner[_cutieId] == _claimant;
    }

    function _exists(uint40 _cutieId) internal view returns (bool) {
        return cutieIndexToOwner[_cutieId] != address(0);
    }

    // @dev Marks an address as being approved for transferFrom(), overwriting any previous
    //  approval. Setting _approved to address(0) clears all transfer approval.
    //  NOTE: _approve() does NOT send the Approval event. This is done on purpose:
    //  _approve() and transferFrom() are used together for putting Cuties on auction.
    //  There is no value in spamming the log with Approval events in that case.
    function _approve(uint40 _cutieId, address _approved) internal {
        cutieIndexToApproved[_cutieId] = _approved;
    }

    // @dev Checks if a given address currently has transferApproval for a certain Cutie.
    // @param _claimant the address we are confirming the cutie is approved for.
    // @param _cutieId cutie id, only valid when > 0
    function _approvedFor(address _claimant, uint40 _cutieId) internal view returns (bool) {
        return cutieIndexToApproved[_cutieId] == _claimant;
    }

    // @dev Assigns ownership of a particular Cutie to an address.
    function _transfer(address _from, address _to, uint40 _cutieId) internal {

        // since the number of cuties is capped to 2^40
        // there is no way to overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        cutieIndexToOwner[_cutieId] = _to;
        // When creating new cuties _from is 0x0, but we cannot account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete cutieIndexToApproved[_cutieId];
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _cutieId);
    }

    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.
    function _isContract(address _account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        return size > 0;
    }

    // @dev For transferring a cutie owned by this contract to the specified address.
    //  Used to rescue lost cuties. (There is no "proper" flow where this contract
    //  should be the owner of any Cutie. This function exists for us to reassign
    //  the ownership of Cuties that users may have accidentally sent to our address.)
    // @param _cutieId - ID of cutie
    // @param _recipient - Address to send the cutie to
    function restoreCutieToAddress(uint40 _cutieId, address _recipient) external whenNotPaused onlyOperator {
        require(_isOwner(this, _cutieId));
        _transfer(this, _recipient, _cutieId);
    }

    // @dev An method that creates a new cutie and stores it. This
    //  method does not check anything and should only be called when the
    //  input data is valid for sure. Will generate both a Birth event
    //  and a Transfer event.
    // @param _momId The cutie ID of the mom of this cutie (zero for gen0)
    // @param _dadId The cutie ID of the dad of this cutie (zero for gen0)
    // @param _generation The generation number of this cutie, must be computed by caller.
    // @param _genes The cutie's genetic code.
    // @param _owner The initial owner of this cutie, must be non-zero (except for the unCutie, ID 0)
    function createCutie(
        address _owner,
        uint40 _momId,
        uint40 _dadId,
        uint16 _generation,
        uint16 _cooldownIndex,
        uint256 _genes,
        uint40 _birthTime
    ) external whenNotPaused onlyGame returns (uint40) {
        Cutie memory _cutie = Cutie({
            genes : _genes,
            birthTime : _birthTime,
            cooldownEndTime : 0,
            momId : _momId,
            dadId : _dadId,
            cooldownIndex : _cooldownIndex,
            generation : _generation,
            optional : 0
        });

        total++;
        uint256 newCutieId256 = total;

        // Check if id can fit into 40 bits
        require(newCutieId256 <= 0xFFFFFFFFFF);

        uint40 newCutieId = uint40(newCutieId256);
        cuties[newCutieId] = _cutie;

        // This will assign ownership, as well as emit the Transfer event as per ERC721 draft
        _transfer(0, _owner, newCutieId);

        return newCutieId;
    }

    // @dev Recreate the cutie if it stuck on old contracts and cannot be migrated smoothly
    function restoreCutie(
        address owner,
        uint40 id,
        uint256 _genes,
        uint40 _momId,
        uint40 _dadId,
        uint16 _generation,
        uint40 _cooldownEndTime,
        uint16 _cooldownIndex,
        uint40 _birthTime
    ) external whenNotPaused onlyGame {
        require(owner != address(0), "Restore to zero address");
        require(total >= id, "Cutie restore is not allowed");
        require(cuties[id].birthTime == 0, "Cutie overwrite is forbidden");

        Cutie memory cutie = Cutie({
            genes: _genes,
            momId: _momId,
            dadId: _dadId,
            generation: _generation,
            cooldownEndTime: _cooldownEndTime,
            cooldownIndex: _cooldownIndex,
            birthTime: _birthTime,
            optional: 0
        });

        cuties[id] = cutie;
        cutieIndexToOwner[id] = owner;
        ownershipTokenCount[owner]++;
    }

    // @notice Returns all the relevant information about a certain cutie.
    // @param _id The ID of the cutie of interest.
    function getCutie(uint40 _id) external view returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    ) {
        require(_exists(_id), "Cutie not exists");

        Cutie storage cutie = cuties[_id];

        genes = cutie.genes;
        birthTime = cutie.birthTime;
        cooldownEndTime = cutie.cooldownEndTime;
        momId = cutie.momId;
        dadId = cutie.dadId;
        cooldownIndex = cutie.cooldownIndex;
        generation = cutie.generation;
    }

    function getGenes(uint40 _id) external view returns (uint256) {
        return cuties[_id].genes;
    }

    function setGenes(uint40 _id, uint256 _genes) external whenNotPaused onlyGame {
        cuties[_id].genes = _genes;
    }

    function getCooldownEndTime(uint40 _id) external view returns (uint40) {
        return cuties[_id].cooldownEndTime;
    }

    function setCooldownEndTime(uint40 _id, uint40 _cooldownEndTime) external whenNotPaused onlyGame {
        cuties[_id].cooldownEndTime = _cooldownEndTime;
    }

    function getCooldownIndex(uint40 _id) external view returns (uint16) {
        return cuties[_id].cooldownIndex;
    }

    function setCooldownIndex(uint40 _id, uint16 _cooldownIndex) external whenNotPaused onlyGame {
        cuties[_id].cooldownIndex = _cooldownIndex;
    }

    function getGeneration(uint40 _id) external view returns (uint16) {
        return cuties[_id].generation;
    }

    function setGeneration(uint40 _id, uint16 _generation) external whenNotPaused onlyGame {
        cuties[_id].generation = _generation;
    }

    function getOptional(uint40 _id) external view returns (uint64) {
        return cuties[_id].optional;
    }

    function setOptional(uint40 _id, uint64 _optional) external whenNotPaused onlyGame {
        cuties[_id].optional = _optional;
    }
}