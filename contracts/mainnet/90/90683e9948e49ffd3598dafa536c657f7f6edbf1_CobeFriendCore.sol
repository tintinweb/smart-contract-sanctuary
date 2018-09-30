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
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="92f6f7e6f7d2f3eafbfdffe8f7fcbcf1fd">[email&#160;protected]</a>> (https://github.com/dete)
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

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


/// @title A facet of CobeFriendCore that manages special access privileges.
/// @author CybEye (http://www.cybeye.com/us/index.jsp)
/// @dev See the CobeFriendCore contract documentation to understand how the various contract facets are arranged.
contract CobeFriendACL {
    // This facet controls access control for CobeFriends. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the CobeFriendCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from CobeFriendCore and its auction contracts.
    //
    //     - The COO: The COO can release gen0 CobeFriends to auction, and mint promo CobeFriends.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn&#39;t have the ability to act in those roles. This
    // restriction is intentional so that we aren&#39;t tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
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
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}


/// @title Base contract for CobeFriend. Holds all common structs, events and base variables.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the CobeFriendCore contract documentation to understand how the various contract facets are arranged.
contract CobeFriendBase is CobeFriendACL {
	/*** EVENTS ***/

	/// @dev The Birth event is fired whenever a new CobeFriend comes into existence. This obviously
	///  includes any time a CobeFriend is created through the giveBirth method, but it is also called
	///  when a new gen0 CobeFriend is created.
	event Birth(address owner, uint256 CobeFriendId, uint256 matronId, uint256 sireId, uint256 genes, uint256 generation);

	/// @dev Transfer event as defined in current draft of ERC721. Emitted every time a CobeFriend
	///  ownership is assigned, including births.
	event Transfer(address from, address to, uint256 tokenId);

	/*** DATA TYPES ***/

	/// @dev The main CobeFriend struct. Every CobeFriend in CobeFriend is represented by a copy
	///  of this structure, so great care was taken to ensure that it fits neatly into
	///  exactly two 256-bit words. Note that the order of the members in this structure
	///  is important because of the byte-packing rules used by Ethereum.
	///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
	struct CobeFriend {
		// The CobeFriend&#39;s genetic code is packed into these 256-bits, the format is
		// sooper-sekret! A CobeFriend&#39;s genes never change.
		uint256 genes;

		// The timestamp from the block when this CobeFriend came into existence.
		uint64 birthTime;

		// The minimum timestamp after which this CobeFriend can engage in breeding
		// activities again. This same timestamp is used for the pregnancy
		// timer (for matrons) as well as the siring cooldown.
		uint64 cooldownEndBlock;

		// The ID of the parents of this CobeFriend, set to 0 for gen0 CobeFriends.
		// Note that using 32-bit unsigned integers limits us to a "mere"
		// 4 billion CobeFriends. This number might seem small until you realize
		// that Ethereum currently has a limit of about 500 million
		// transactions per year! So, this definitely won&#39;t be a problem
		// for several years (even as Ethereum learns to scale).
		uint32 matronId;
		uint32 sireId;

		// Set to the ID of the sire CobeFriend for matrons that are pregnant,
		// zero otherwise. A non-zero value here is how we know a CobeFriend
		// is pregnant. Used to retrieve the genetic material for the new
		// CobeFriend when the birth transpires.
		uint32 siringWithId;

		// Set to the index in the cooldown array (see below) that represents
		// the current cooldown duration for this CobeFriend. This starts at zero
		// for gen0 CobeFriends, and is initialized to floor(generation/2) for others.
		// Incremented by one for each successful breeding action, regardless
		// of whether this CobeFriend is acting as matron or sire.
		uint16 cooldownIndex;

		// The "generation number" of this CobeFriend. CobeFriends minted by the CZ contract
		// for sale are called "gen0" and have a generation number of 0. The
		// generation number of all other CobeFriends is the larger of the two generation
		// numbers of their parents, plus one.
		// (i.e. max(matron.generation, sire.generation) + 1)
		uint16 generation;
	}

	/*** CONSTANTS ***/

	/// @dev A lookup table inCobeFriending the cooldown duration after any successful
	///  breeding action, called "pregnancy time" for matrons and "siring cooldown"
	///  for sires. Designed such that the cooldown roughly doubles each time a CobeFriend
	///  is bred, encouraging owners not to just keep breeding the same CobeFriend over
	///  and over again. Caps out at one week (a CobeFriend can breed an unbounded number
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

	/// @dev An array containing the CobeFriend struct for all CobeFriends in existence. The ID
	///  of each CobeFriend is actually an index into this array. Note that ID 0 is a negaCobeFriend,
	///  the unCobeFriend, the mythical beast that is the parent of all gen0 CobeFriends. A bizarre
	///  creature that is both matron and sire... to itself! Has an invalid genetic code.
	///  In other words, CobeFriend ID 0 is invalid... ;-)
	CobeFriend[] CobeFriends;

	/// @dev A mapping from CobeFriend IDs to the address that owns them. All CobeFriends have
	///  some valid owner address, even gen0 CobeFriends are created with a non-zero owner.
	mapping (uint256 => address) public CobeFriendIndexToOwner;

	// @dev A mapping from owner address to count of tokens that address owns.
	//  Used internally inside balanceOf() to resolve ownership count.
	mapping (address => uint256) ownershipTokenCount;

	/// @dev A mapping from CobeFriendIDs to an address that has been approved to call
	///  transferFrom(). Each CobeFriend can only have one approved address for transfer
	///  at any time. A zero value means no approval is outstanding.
	mapping (uint256 => address) public CobeFriendIndexToApproved;

	/// @dev A mapping from CobeFriendIDs to an address that has been approved to use
	///  this CobeFriend for siring via breedWith(). Each CobeFriend can only have one approved
	///  address for siring at any time. A zero value means no approval is outstanding.
	mapping (uint256 => address) public sireAllowedToAddress;

	/// @dev The address of the ClockAuction contract that handles sales of CobeFriends. This
	///  same contract handles both peer-to-peer sales as well as the gen0 sales which are
	///  initiated every 15 minutes.
	SaleClockAuction public saleAuction;

	/// @dev Assigns ownership of a specific CobeFriend to an address.
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		// Since the number of CobeFriends is capped to 2^32 we can&#39;t overflow this
		ownershipTokenCount[_to]++;
		// transfer ownership
		CobeFriendIndexToOwner[_tokenId] = _to;
		// When creating new CobeFriends _from is 0x0, but we can&#39;t account that address.
		if (_from != address(0)) {
			ownershipTokenCount[_from]--;
			// once the CobeFriend is transferred also clear sire allowances
			delete sireAllowedToAddress[_tokenId];
			// clear any previously approved ownership exchange
			delete CobeFriendIndexToApproved[_tokenId];
		}
		// Emit the transfer event.
		Transfer(_from, _to, _tokenId);
	}

	/// @dev An internal method that creates a new CobeFriend and stores it. This
	///  method doesn&#39;t do any checking and should only be called when the
	///  input data is known to be valid. Will generate both a Birth event
	///  and a Transfer event.
	/// @param _matronId The CobeFriend ID of the matron of this CobeFriend (zero for gen0)
	/// @param _sireId The CobeFriend ID of the sire of this CobeFriend (zero for gen0)
	/// @param _generation The generation number of this CobeFriend, must be computed by caller.
	/// @param _genes The CobeFriend&#39;s genetic code.
	/// @param _owner The inital owner of this CobeFriend, must be non-zero (except for the unCobeFriend, ID 0)
	function _createCobeFriend(
		uint256 _matronId,
		uint256 _sireId,
		uint256 _generation,
		uint256 _genes,
		address _owner
	)
		internal
		returns (uint)
	{
		// These requires are not strictly necessary, our calling code should make
		// sure that these conditions are never broken. However! _createCobeFriend() is already
		// an expensive call (for storage), and it doesn&#39;t hurt to be especially careful
		// to ensure our data structures are always valid.
		require(_matronId == uint256(uint32(_matronId)));
		require(_sireId == uint256(uint32(_sireId)));
		require(_generation == uint256(uint16(_generation)));

		// New CobeFriend starts with the same cooldown as parent gen/2
		uint16 cooldownIndex = uint16(_generation / 2);
		if (cooldownIndex > 13) {
			cooldownIndex = 13;
		}

		CobeFriend memory _CobeFriend = CobeFriend({
			genes: _genes,
			birthTime: uint64(now),
			cooldownEndBlock: 0,
			matronId: uint32(_matronId),
			sireId: uint32(_sireId),
			siringWithId: 0,
			cooldownIndex: cooldownIndex,
			generation: uint16(_generation)
		});
		uint256 newCobeFriendId = CobeFriends.push(_CobeFriend) - 1;

		// It&#39;s probably never going to happen, 4 billion CobeFriends is A LOT, but
		// let&#39;s just be 100% sure we never let this happen.
		require(newCobeFriendId == uint256(uint32(newCobeFriendId)));

		// emit the birth event
		Birth(
			_owner,
			newCobeFriendId,
			uint256(_CobeFriend.matronId),
			uint256(_CobeFriend.sireId),
			_CobeFriend.genes,
            uint256(_CobeFriend.generation)
		);

		// This will assign ownership, and also emit the Transfer event as
		// per ERC721 draft
		_transfer(0, _owner, newCobeFriendId);

		return newCobeFriendId;
	}

	/// @dev An internal method that creates a new CobeFriend and stores it. This
	///  method doesn&#39;t do any checking and should only be called when the
	///  input data is known to be valid. Will generate both a Birth event
	///  and a Transfer event.
	/// @param _matronId The CobeFriend ID of the matron of this CobeFriend (zero for gen0)
	/// @param _sireId The CobeFriend ID of the sire of this CobeFriend (zero for gen0)
	/// @param _generation The generation number of this CobeFriend, must be computed by caller.
	/// @param _genes The CobeFriend&#39;s genetic code.
	/// @param _owner The inital owner of this CobeFriend, must be non-zero (except for the unCobeFriend, ID 0)
    /// @param _time The birth time of CobeFriend
    /// @param _cooldownIndex The cooldownIndex of CobeFriend
	function _createCobeFriendWithTime(
		uint256 _matronId,
		uint256 _sireId,
		uint256 _generation,
		uint256 _genes,
		address _owner,
        uint256 _time,
        uint256 _cooldownIndex
	)
	internal
	returns (uint)
	{
		// These requires are not strictly necessary, our calling code should make
		// sure that these conditions are never broken. However! _createCobeFriend() is already
		// an expensive call (for storage), and it doesn&#39;t hurt to be especially careful
		// to ensure our data structures are always valid.
		require(_matronId == uint256(uint32(_matronId)));
		require(_sireId == uint256(uint32(_sireId)));
		require(_generation == uint256(uint16(_generation)));
        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

        // Copy down CobeFriend cooldownIndex
        uint16 cooldownIndex = uint16(_cooldownIndex);
		if (cooldownIndex > 13) {
			cooldownIndex = 13;
		}

		CobeFriend memory _CobeFriend = CobeFriend({
			genes: _genes,
			birthTime: uint64(_time),
			cooldownEndBlock: 0,
			matronId: uint32(_matronId),
			sireId: uint32(_sireId),
			siringWithId: 0,
			cooldownIndex: cooldownIndex,
			generation: uint16(_generation)
			});
		uint256 newCobeFriendId = CobeFriends.push(_CobeFriend) - 1;

		// It&#39;s probably never going to happen, 4 billion CobeFriends is A LOT, but
		// let&#39;s just be 100% sure we never let this happen.
		require(newCobeFriendId == uint256(uint32(newCobeFriendId)));

		// emit the birth event
		Birth(
			_owner,
			newCobeFriendId,
			uint256(_CobeFriend.matronId),
			uint256(_CobeFriend.sireId),
			_CobeFriend.genes,
            uint256(_CobeFriend.generation)
		);

		// This will assign ownership, and also emit the Transfer event as
		// per ERC721 draft
		_transfer(0, _owner, newCobeFriendId);

		return newCobeFriendId;
	}

	// Any C-level can fix how many seconds per blocks are currently observed.
	function setSecondsPerBlock(uint256 secs) external onlyCLevel {
		require(secs < cooldowns[0]);
		secondsPerBlock = secs;
	}
}


/// @title The external contract that is responsible for generating metadata for the CobeFriends,
///  it has one function that will return the data as bytes.
contract ERC721Metadata {
    /// @dev Given a token Id, returns a byte array that is supposed to be converted into string.
    function getMetadata(uint256 _tokenId, string) public pure returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}


/// @title The facet of the CobeFriends core contract that manages ownership, ERC-721 (draft) compliant.
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
///  See the CobeFriendCore contract documentation to understand how the various contract facets are arranged.
contract CobeFriendOwnership is CobeFriendBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "CobeFriends";
    string public constant symbol = "CBF";

    // The contract that will return CobeFriend metadata
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256(&#39;name()&#39;)) ^
        bytes4(keccak256(&#39;symbol()&#39;)) ^
        bytes4(keccak256(&#39;totalSupply()&#39;)) ^
        bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
        bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
        bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
        bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /// @dev Set the address of the sibling contract that tracks metadata.
    ///  CEO only.
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular CobeFriend.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId CobeFriend id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return CobeFriendIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular CobeFriend.
    /// @param _claimant the address we are confirming CobeFriend is approved for.
    /// @param _tokenId CobeFriend id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return CobeFriendIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting CobeFriends on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        CobeFriendIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of CobeFriends owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a CobeFriend to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  CobeFriends specifically) or your CobeFriend may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the CobeFriend to transfer.
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
        // The contract should never own any CobeFriends (except very briefly
        // after a gen0 cbf is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of CobeFriends
        // through the allow + transferFrom flow.
        require(_to != address(saleAuction));

        // You can only send your own cbf.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific CobeFriend via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the CobeFriend that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a CobeFriend owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the CobeFriend to be transfered.
    /// @param _to The address that should take ownership of the CobeFriend. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the CobeFriend to be transferred.
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
        // The contract should never own any CobeFriends (except very briefly
        // after a gen0 cbf is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of CobeFriends currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return CobeFriends.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given CobeFriend.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = CobeFriendIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all CobeFriend IDs assigned to an address.
    /// @param _owner The owner whose CobeFriends we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire CobeFriend array looking for cbfs belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalcbfs = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all cbfs have IDs starting at 1 and increasing
            // sequentially up to the totalcbf count.
            uint256 cbfId;

            for (cbfId = 1; cbfId <= totalcbfs; cbfId++) {
                if (CobeFriendIndexToOwner[cbfId] == _owner) {
                    result[resultIndex] = cbfId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @dev Adapted from memcpy() by @arachnid (Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c1a0b3a0a2a9afa8a581afaeb5a5aeb5efafa4b5">[email&#160;protected]</a>>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _memcpy(uint _dest, uint _src, uint _len) private view {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    /// @dev Adapted from toString(slice) by @arachnid (Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7a1b081b191214131e3a14150e1e150e54141f0e">[email&#160;protected]</a>>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the CobeFriend whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
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
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
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
        // (Because of how Ethereum mappings work, we can&#39;t just count
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
        // to the sender so we can&#39;t have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the auctioneer&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can&#39;t go negative.)
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
        // now variable doesn&#39;t ever go backwards).
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
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We&#39;ve reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can&#39;t overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /// @dev Computes owner&#39;s cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
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

    /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
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
        nftAddress.transfer(this.balance);
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
        // Sanity check that no inputs overflow how many bits we&#39;ve allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
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

    /// @dev Cancels an auction that hasn&#39;t been won yet.
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


/// @title Clock auction modified for sale of CobeFriends
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract SaleClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isSaleClockAuction = true;

    // Tracks last 5 sale price of gen0 CobeFriend sales
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
        // Sanity check that no inputs overflow how many bits we&#39;ve allocated
        // to store them in the auction struct.
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


/// @title Handles creating auctions for sale and siring of CobeFriends.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract CobeFriendAuction is CobeFriendOwnership {

    // @notice The auction contract variables are defined in CobeFriendBase to allow
    //  us to refer to them in CobeFriendOwnership to prevent accidental transfers.
    // `saleAuction` refers to the auction for gen0 and p2p sale of CobeFriends.
    // `siringAuction` refers to the auction for siring rights of CobeFriends.

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Put a CobeFriend up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _CobeFriendId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If CobeFriend is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _CobeFriendId));
        _approve(_CobeFriendId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the CobeFriend.
        saleAuction.createAuction(
            _CobeFriendId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }


    /// @dev Transfers the balance of the sale auction contract
    /// to the CobeFriendCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
    }
}


/// @title all functions related to creating CobeFriends
contract CobeFriendMinting is CobeFriendAuction {

    // Limits the number of cbfs the contract owner can ever create.
    uint256 public constant DEFAULT_CREATION_LIMIT = 50000;

    // Counts the number of cbfs the contract owner has created.
    uint256 public defaultCreatedCount;


    /// @dev we can create CobeFriends with different generations. Only callable by COO
    /// @param _genes The encoded genes of the CobeFriend to be created, any value is accepted
    /// @param _owner The future owner of the created CobeFriend. Default to contract COO
    /// @param _time The birth time of CobeFriend
    /// @param _cooldownIndex The cooldownIndex of CobeFriend
    function createDefaultGen0CobeFriend(uint256 _genes, address _owner, uint256 _time, uint256 _cooldownIndex) external onlyCOO {

        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

        require(_time > 0);
        require(_cooldownIndex >= 0 && _cooldownIndex <= 13);

        address CobeFriendOwner = _owner;
        if (CobeFriendOwner == address(0)) {
            CobeFriendOwner = cooAddress;
        }
        require(defaultCreatedCount < DEFAULT_CREATION_LIMIT);

        defaultCreatedCount++;
        _createCobeFriendWithTime(0, 0, 0, _genes, CobeFriendOwner, _time, _cooldownIndex);
    }

    /// @dev we can create CobeFriends with different generations. Only callable by COO
    /// @param _matronId The CobeFriend ID of the matron of this CobeFriend
    /// @param _sireId The CobeFriend ID of the sire of this CobeFriend
    /// @param _genes The encoded genes of the CobeFriend to be created, any value is accepted
    /// @param _owner The future owner of the created CobeFriend. Default to contract COO
    /// @param _time The birth time of CobeFriend
    /// @param _cooldownIndex The cooldownIndex of CobeFriend
    function createDefaultCobeFriend(uint256 _matronId, uint256 _sireId, uint256 _genes, address _owner, uint256 _time, uint256 _cooldownIndex) external onlyCOO {

        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

        require(_time > 0);
        require(_cooldownIndex >= 0 && _cooldownIndex <= 13);

        address CobeFriendOwner = _owner;
        if (CobeFriendOwner == address(0)) {
            CobeFriendOwner = cooAddress;
        }

        require(_matronId > 0);
        require(_sireId > 0);

        // Grab a reference to the matron in storage.
        CobeFriend storage matron = CobeFriends[_matronId];

        // Grab a reference to the sire in storage.
        CobeFriend storage sire = CobeFriends[_sireId];

        // Determine the higher generation number of the two parents
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        _createCobeFriendWithTime(_matronId, _sireId, parentGen + 1, _genes, CobeFriendOwner, _time, _cooldownIndex);
    }

}


/// @title CobeFriends: Collectible, breedable, and oh-so-adorable CobeFriends on the Ethereum blockchain.
/// @dev The main CobeFriends contract, keeps track of cbfs so they don&#39;t wander around and get lost.
contract CobeFriendCore is CobeFriendMinting {
/* contract CobeFriendCore { */
    // This is the main CobeFriends contract. In order to keep our code seperated into logical sections,
    // we&#39;ve broken it up in two ways. First, we have several seperately-instantiated sibling contracts
    // that handle auctions and our super-top-secret genetic combination algorithm. The auctions are
    // seperate since their logic is somewhat complex and there&#39;s always a risk of subtle bugs. By keeping
    // them in their own contracts, we can upgrade them without disrupting the main contract that tracks
    // CobeFriend ownership. The genetic combination algorithm is kept seperate so we can open-source all of
    // the rest of our code without making it _too_ easy for folks to figure out how the genetics work.
    // Don&#39;t worry, I&#39;m sure someone will reverse engineer it soon enough!
    //
    // Secondly, we break the core contract into multiple files using inheritence, one for each major
    // facet of functionality of CK. This allows us to keep related code bundled together while still
    // avoiding a single giant file with everything in it. The breakdown is as follows:
    //
    //      - CobeFriendBase: This is where we define the most fundamental code shared throughout the core
    //             functionality. This includes our main data storage, constants and data types, plus
    //             internal functions for managing these items.
    //
    //      - CobeFriendAccessControl: This contract manages the various addresses and constraints for operations
    //             that can be executed only by specific roles. Namely CEO, CFO and COO.
    //
    //      - CobeFriendOwnership: This provides the methods required for basic non-fungible token
    //             transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
    //
    //      - CobeFriendBreeding: This file contains the methods necessary to breed CobeFriends together, including
    //             keeping track of siring offers, and relies on an external genetic combination contract.
    //
    //      - CobeFriendAuctions: Here we have the public methods for auctioning or bidding on CobeFriends or siring
    //             services. The actual auction functionality is handled in two sibling contracts (one
    //             for sales and one for siring), while auction creation and bidding is mostly mediated
    //             through this facet of the core contract.
    //
    //      - CobeFriendMinting: This final facet contains the functionality we use for creating new gen0 CobeFriends.
    //             We can make up to 5000 "promo" CobeFriends that can be given away (especially important when
    //             the community is new), and all others can only be created and then immediately put up
    //             for auction via an algorithmically determined starting price. Regardless of how they
    //             are created, there is a hard limit of 2400*12*12 gen0 CobeFriends. After that, it&#39;s all up to the
    //             community to breed, breed, breed!

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main CobeFriends smart contract instance.
    function CobeFriendCore() public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // start with the mythical CobeFriend 0 - so we don&#39;t have generation-0 parent issues
        _createCobeFriend(0, 0, 0, uint256(-1), address(0));
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it&#39;s from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(saleAuction)
        );
    }

    /// @notice Returns all the relevant information about a specific CobeFriend.
    /// @param _id The ID of the CobeFriend of interest.
    function getCobeFriend(uint256 _id)
        external
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
        uint256 genes
    ) {
        CobeFriend storage cbf = CobeFriends[_id];

        // if this variable is 0 then it&#39;s not gestating
        isGestating = (cbf.siringWithId != 0);
        isReady = (cbf.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(cbf.cooldownIndex);
        nextActionAt = uint256(cbf.cooldownEndBlock);
        siringWithId = uint256(cbf.siringWithId);
        birthTime = uint256(cbf.birthTime);
        matronId = uint256(cbf.matronId);
        sireId = uint256(cbf.sireId);
        generation = uint256(cbf.generation);
        genes = cbf.genes;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
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