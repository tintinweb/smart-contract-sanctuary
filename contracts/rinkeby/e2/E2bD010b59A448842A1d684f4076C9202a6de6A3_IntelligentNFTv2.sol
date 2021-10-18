// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC20Spec.sol";
import "../interfaces/ERC721Spec.sol";
import "../lib/StringUtils.sol";
import "../utils/AccessControl.sol";

/**
 * @title Intelligent NFT Interface
 *        Version 2
 *
 * @notice External interface of IntelligentNFTv2 declared to support ERC165 detection.
 *      Despite some similarity with ERC721 interfaces, iNFT is not ERC721, any similarity
 *      should be treated as coincidental. Client applications may benefit from this similarity
 *      to reuse some of the ERC721 client code for display/reading.
 *
 * @dev See Intelligent NFT documentation below.
 */
interface IntelligentNFTv2Spec {
	/**
	 * @dev ERC20/ERC721 like name - Intelligent NFT
	 *
	 * @return "Intelligent NFT"
	 */
	function name() external view returns (string memory);

	/**
	 * @dev ERC20/ERC721 like symbol - iNFT
	 *
	 * @return "iNFT"
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev ERC721 like link to the iNFT metadata
	 *
	 * @param recordId iNFT ID to get metadata URI for
	 */
	function tokenURI(uint256 recordId) external view returns (string memory);

	/**
	 * @dev ERC20/ERC721 like counter of the iNFTs in existence (upper bound),
	 *      some (or all) of which may not exist due to target NFT destruction
	 *
	 * @return amount of iNFT tracked by this smart contract
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Check if iNFT binding with the given ID exists
	 *
	 * @return true if iNFT binding exist, false otherwise
	 */
	function exists(uint256 recordId) external view returns (bool);

	/**
	 * @dev ERC721 like function to get owner of the iNFT, which is by definition
	 *      an owner of the underlying NFT
	 */
	function ownerOf(uint256 recordId) external view returns (address);
}

/**
 * @title Intelligent NFT (iNFT)
 *        Version 2
 *
 * @notice Intelligent NFT (iNFT) represents an enhancement to an existing NFT
 *      (we call it a "target" or "target NFT"), it binds a GPT-3 prompt (a "personality prompt",
 *      delivered as a Personality Pod ERC721 token bound to iNFT)
 *      to the target to embed intelligence, is controlled and belongs to the owner of the target.
 *
 * @notice iNFT stores AI Personality and some amount of ALI tokens locked, available for
 *      unlocking when iNFT is destroyed
 *
 * @notice iNFT is not an ERC721 token, but it has some very limited similarity to an ERC721:
 *      every record is identified by ID and this ID has an owner, which is effectively the target NFT owner;
 *      still, it doesn't store ownership information itself and fully relies on the target ownership instead
 *
 * @dev Internally iNFTs consist of:
 *      - target NFT - smart contract address and ID of the NFT the iNFT is bound to
 *      - AI Personality - smart contract address and ID of the AI Personality used to produce given iNFT,
 *        representing a "personality prompt", and locked within an iNFT
 *      - ALI tokens amount - amount of the ALI tokens used to produce given iNFT, also locked
 *
 * @dev iNFTs can be
 *      - created, this process requires an AI Personality and ALI tokens to be locked
 *      - destroyed, this process releases an AI Personality and ALI tokens previously locked
 */
contract IntelligentNFTv2 is IntelligentNFTv2Spec, AccessControl, ERC165 {
	/**
	 * @inheritdoc IntelligentNFTv2Spec
	 */
	string public override name = "Intelligent NFT";

	/**
	 * @inheritdoc IntelligentNFTv2Spec
	 */
	string public override symbol = "iNFT";

	/**
	 * @dev Each intelligent token, represented by its unique ID, is bound to the target NFT,
	 *      defined by the pair of the target NFT smart contract address and unique token ID
	 *      within the target NFT smart contract
	 *
	 * @dev Effectively iNFT is owned by the target NFT owner
	 *
	 * @dev Additionally, each token holds an AI Personality and some amount of ALI tokens bound to it
	 *
	 * @dev `IntelliBinding` keeps all the binding information, including target NFT coordinates,
	 *      bound AI Personality ID, and amount of ALI ERC20 tokens bound to the iNFT
	 */
	struct IntelliBinding {
		// Note: structure members are reordered to fit into less memory slots, see EVM memory layout
		// ----- SLOT.1 (256/256)
		/**
		 * @dev Specific AI Personality is defined by the pair of AI Personality smart contract address
		 *       and AI Personality ID
		 *
		 * @dev Address of the AI Personality smart contract
		 */
		address personalityContract;

		/**
		 * @dev AI Personality ID within the AI Personality smart contract
		 */
		uint96 personalityId;

		// ----- SLOT.2 (256/256)
		/**
		 * @dev Amount of an ALI ERC20 tokens bound to (owned by) the iNFTs
		 *
		 * @dev ALI ERC20 smart contract address is defined globally as `aliContract` constant
		 */
		uint96 aliValue;

		/**
		 * @dev Address of the target NFT deployed smart contract,
		 *      this is a contract a particular iNFT is bound to
		 */
		address targetContract;

		// ----- SLOT.3 (256/256)
		/**
		 * @dev Target NFT ID within the target NFT smart contract,
		 *      effectively target NFT ID and contract address define the owner of an iNFT
		 */
		uint256 targetId;
	}

	/**
	 * @notice iNFT binding storage, stores binding information for each existing iNFT
	 * @dev Maps iNFT ID to its binding data, which includes underlying NFT data
	 */
	mapping(uint256 => IntelliBinding) public bindings;

	/**
	 * @notice Reverse iNFT binding allows to find iNFT bound to a particular NFT
	 * @dev Maps target NFT (smart contract address and unique token ID) to the iNFT ID:
	 *      NFT Contract => NFT ID => iNFT ID
	 */
	mapping(address => mapping(uint256 => uint256)) public reverseBindings;

	/**
	 * @notice Ai Personality to iNFT binding allows to find iNFT bound to a particular Ai Personality
	 * @dev Maps Ai Personality NFT (unique token ID) to the linked iNFT:
	 *      AI Personality Contract => AI Personality ID => iNFT ID
	 */
	mapping(address => mapping(uint256 => uint256)) public personalityBindings;

	/**
	 * @notice Total amount (maximum value estimate) of iNFT in existence.
	 *       This value can be higher than number of effectively accessible iNFTs
	 *       since when underlying NFT gets burned this value doesn't get updated.
	 */
	uint256 public override totalSupply;

	/**
	 * @notice Each iNFT holds some ALI tokens, which are tracked by the ALI token ERC20 smart contract defined here
	 */
	address public immutable aliContract;

	/**
	 * @notice ALI token balance the contract is aware of, cumulative ALI obligation,
	 *      i.e. sum of all iNFT locked ALI balances
	 *
	 * @dev Sum of all `IntelliBinding.aliValue` for each iNFT in existence
	 */
	uint256 public aliBalance;

	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public baseURI = "";

	/**
	 * @dev Optional mapping for token URIs to be returned as is when `tokenURI()`
	 *      is called; if mapping doesn't exist for token, the URI is constructed
	 *      as `base URI + token ID`, where plus (+) denotes string concatenation
	 */
	mapping(uint256 => string) internal _tokenURIs;

	/**
	 * @notice Minter is responsible for creating (minting) iNFTs
	 *
	 * @dev Role ROLE_MINTER allows minting iNFTs (calling `mint` function)
	 */
	uint32 public constant ROLE_MINTER = 0x0001_0000;

	/**
	 * @notice Burner is responsible for destroying (burning) iNFTs
	 *
	 * @dev Role ROLE_BURNER allows burning iNFTs (calling `burn` function)
	 */
	uint32 public constant ROLE_BURNER = 0x0002_0000;

	/**
	 * @notice Editor is responsible for editing (updating) iNFT records in general,
	 *      adding/removing locked ALI tokens to/from iNFT in particular
	 *
	 * @dev Role ROLE_EDITOR allows editing iNFTs (calling `increaseAli`, `decreaseAli` functions)
	 */
	uint32 public constant ROLE_EDITOR = 0x0004_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string _oldVal, string _newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param _tokenId token ID which URI was updated
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 indexed _tokenId, string _oldVal, string _newVal);

	/**
	 * @dev Fired in mint() when new iNFT is created
	 *
	 * @param _by an address which executed the mint function
	 * @param _owner current owner of the NFT
	 * @param _recordId ID of the iNFT minted (created, bound)
	 * @param _aliValue amount of ALI tokens locked within newly created iNFT
	 * @param _personalityContract AI Personality smart contract address
	 * @param _personalityId ID of the AI Personality locked within newly created iNFT
	 * @param _targetContract target NFT smart contract address
	 * @param _targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	event Minted(
		address indexed _by,
		address indexed _owner,
		uint256 indexed _recordId,
		uint96 _aliValue,
		address _personalityContract,
		uint96 _personalityId,
		address _targetContract,
		uint256 _targetId
	);

	/**
	 * @dev Fired in increaseAli() and decreaseAli() when iNFT record is updated
	 *
	 * @param _by an address which executed the update
	 * @param _owner iNFT (target NFT) owner
	 * @param _recordId ID of the updated iNFT
	 * @param _oldAliValue amount of ALI tokens locked within iNFT before update
	 * @param _newAliValue amount of ALI tokens locked within iNFT after update
	 */
	event Updated(
		address indexed _by,
		address indexed _owner,
		uint256 indexed _recordId,
		uint96 _oldAliValue,
		uint96 _newAliValue
	);

	/**
	 * @dev Fired in burn() when an existing iNFT gets destroyed
	 *
	 * @param _by an address which executed the burn function
	 * @param _recordId ID of the iNFT burnt (destroyed, unbound)
	 * @param _recipient and address which received unlocked AI Personality and ALI tokens
	 * @param _aliValue amount of ALI tokens transferred from the destroyed iNFT
	 * @param _personalityContract AI Personality smart contract address
	 * @param _personalityId ID of the AI Personality transferred from the destroyed iNFT
	 * @param _targetContract target NFT smart contract
	 * @param _targetId target NFT ID (where this iNFT was bound to and belonged to)
	 */
	event Burnt(
		address indexed _by,
		uint256 indexed _recordId,
		address indexed _recipient,
		uint96 _aliValue,
		address _personalityContract,
		uint96 _personalityId,
		address _targetContract,
		uint256 _targetId
	);

	/**
	 * @dev Creates/deploys an iNFT instance bound to already ALI token instance
	 *
	 * @param _ali address of the deployed ALI ERC20 Token instance the iNFT is bound to
	 */
	constructor(address _ali) {
		// verify the inputs are set
		require(_ali != address(0), "ALI Token addr is not set");

		// verify _ali is a valid ERC20
		require(ERC165(_ali).supportsInterface(type(ERC20).interfaceId), "unexpected ALI Token type");

		// setup smart contract internal state
		aliContract = _ali;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(IntelligentNFTv2Spec).interfaceId;
	}

	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @dev Returns token URI if it was previously set with `setTokenURI`,
	 *      otherwise constructs it as base URI + token ID
	 *
	 * @param _recordId iNFT ID to query metadata link URI for
	 * @return URI link to fetch iNFT metadata from
	 */
	function tokenURI(uint256 _recordId) public view override returns (string memory) {
		// verify token exists
		require(exists(_recordId), "iNFT doesn't exist");

		// read the token URI for the token specified
		string memory _tokenURI = _tokenURIs[_recordId];

		// if token URI is set
		if(bytes(_tokenURI).length > 0) {
			// just return it
			return _tokenURI;
		}

		// if base URI is not set
		if(bytes(baseURI).length == 0) {
			// return an empty string
			return "";
		}

		// otherwise concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_recordId, 10));
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, _tokenURIs[_tokenId], _tokenURI);

		// and update token URI
		_tokenURIs[_tokenId] = _tokenURI;
	}

	/**
	 * @notice Verifies if given iNFT exists
	 *
	 * @param recordId iNFT ID to verify existence of
	 * @return true if iNFT exists, false otherwise
	 */
	function exists(uint256 recordId) public view override returns (bool) {
		// verify if biding exists for that tokenId and return the result
		return bindings[recordId].targetContract != address(0);
	}

	/**
	 * @notice Returns an owner of the given iNFT.
	 *      By definition iNFT owner is an owner of the target NFT
	 *
	 * @param recordId iNFT ID to query ownership information for
	 * @return address of the given iNFT owner
	 */
	function ownerOf(uint256 recordId) public view override returns (address) {
		// get the link to the token binding (we need to access only one field)
		IntelliBinding storage binding = bindings[recordId];

		// verify the binding exists and throw standard Zeppelin message if not
		require(binding.targetContract != address(0), "iNFT doesn't exist");

		// delegate `ownerOf` call to the target NFT smart contract
		return ERC721(binding.targetContract).ownerOf(binding.targetId);
	}

	/**
	 * @dev Restricted access function which creates an iNFT, binding it to the specified
	 *      NFT, locking the AI Personality specified, and funded with the amount of ALI specified
	 *
	 * @dev Locks AI Personality defined by its ID within iNFT smart contract;
	 *      AI Personality must be transferred to the iNFT smart contract
	 *      prior to calling the `mint`, but in the same transaction with `mint`
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract;
	 *      ALI token amount must be transferred to the iNFT smart contract
	 *      prior to calling the `mint`, but in the same transaction with `mint`
	 *
	 * @dev To summarize, minting transaction (a transaction which executes `mint`) must
	 *      1) transfer AI Personality
	 *      2) transfer ALI tokens if they are to be locked
	 *      3) mint iNFT
	 *      NOTE: breaking the items above into multiple transactions is not acceptable!
	 *            (results in a security risk)
	 *
	 * @dev The NFT to be linked to is not required to owned by the funder, but it must exist;
	 *      throws if target NFT doesn't exist
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to mint (create, bind)
	 * @param aliValue amount of ALI tokens to bind to newly created iNFT
	 * @param personalityContract AI Personality contract address
	 * @param personalityId ID of the AI Personality to bind to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	function mint(
		uint256 recordId,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_MINTER), "access denied");

		// verify personalityContract is a valid ERC721
		require(ERC165(personalityContract).supportsInterface(type(ERC721).interfaceId), "personality is not ERC721");

		// verify targetContract is a valid ERC721
		require(ERC165(targetContract).supportsInterface(type(ERC721).interfaceId), "target NFT is not ERC721");

		// verify this iNFT is not yet minted
		require(!exists(recordId), "iNFT already exists");

		// verify target NFT is not yet bound to
		require(reverseBindings[targetContract][targetId] == 0, "NFT is already bound");

		// verify AI Personality is not yet locked
		require(personalityBindings[personalityContract][personalityId] == 0, "personality already linked");

		// verify if AI Personality is already transferred to iNFT
		require(ERC721(personalityContract).ownerOf(personalityId) == address(this), "personality is not yet transferred");

		// retrieve NFT owner and verify if target NFT exists
		address owner = ERC721(targetContract).ownerOf(targetId);
		// Note: we do not require funder to be NFT owner,
		// if required this constraint should be added by the caller (iNFT Linker)
		require(owner != address(0), "target NFT doesn't exist");

		// in case when ALI tokens are expected to be locked within iNFT
		if(aliValue > 0) {
			// verify ALI tokens are already transferred to iNFT
			require(aliBalance + aliValue <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");

			// update ALI balance on the contract
			aliBalance += aliValue;
		}

		// bind AI Personality transferred and ALI ERC20 value transferred to an NFT specified
		bindings[recordId] = IntelliBinding({
			personalityContract : personalityContract,
			personalityId : personalityId,
			aliValue : aliValue,
			targetContract : targetContract,
			targetId : targetId
		});

		// fill in the reverse binding
		reverseBindings[targetContract][targetId] = recordId;

		// fill in the AI Personality to iNFT binding
		personalityBindings[personalityContract][personalityId] = recordId;

		// increase total supply counter
		totalSupply++;

		// emit an event
		emit Minted(
			msg.sender,
			owner,
			recordId,
			aliValue,
			personalityContract,
			personalityId,
			targetContract,
			targetId
		);
	}

	/**
	 * @dev Restricted access function which creates several iNFTs, binding them to the specified
	 *      NFTs, locking the AI Personalities specified, each funded with the amount of ALI specified
	 *
	 * @dev Locks AI Personalities defined by their IDs within iNFT smart contract;
	 *      AI Personalities must be transferred to the iNFT smart contract
	 *      prior to calling the `mintBatch`, but in the same transaction with `mintBatch`
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract for each iNFT minted;
	 *      ALI token amount must be transferred to the iNFT smart contract
	 *      prior to calling the `mintBatch`, but in the same transaction with `mintBatch`
	 *
	 * @dev To summarize, minting transaction (a transaction which executes `mintBatch`) must
	 *      1) transfer AI Personality
	 *      2) transfer ALI tokens if they are to be locked
	 *      3) mint iNFT
	 *      NOTE: breaking the items above into multiple transactions is not acceptable!
	 *            (results in a security risk)
	 *
	 * @dev The NFTs to be linked to are not required to owned by the funder, but they must exist;
	 *      throws if target NFTs don't exist
	 *
	 * @dev iNFT IDs to be minted: [recordId, recordId + n)
	 * @dev AI Personality IDs to be locked: [personalityId, personalityId + n)
	 * @dev NFT IDs to be bound to: [targetId, targetId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the first iNFT to mint (create, bind)
	 * @param aliValue amount of ALI tokens to bind to each newly created iNFT
	 * @param personalityContract AI Personality contract address
	 * @param personalityId ID of the first AI Personality to bind to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId first target NFT ID (where this iNFT binds to and belongs to)
	 * @param n how many iNFTs to mint, sequentially increasing the recordId, personalityId, and targetId
	 */
	function mintBatch(
		uint256 recordId,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId,
		uint96 n
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_MINTER), "access denied");

		// verify n is set properly
		require(n > 1, "n is too small");

		// verify personalityContract is a valid ERC721
		require(ERC165(personalityContract).supportsInterface(type(ERC721).interfaceId), "personality is not ERC721");

		// verify targetContract is a valid ERC721
		require(ERC165(targetContract).supportsInterface(type(ERC721).interfaceId), "target NFT is not ERC721");

		// verifications: for each iNFT in a batch
		for(uint96 i = 0; i < n; i++) {
			// verify this token ID is not yet bound
			require(!exists(recordId + i), "iNFT already exists");

			// verify the AI Personality is not yet bound
			require(personalityBindings[personalityContract][personalityId + i] == 0, "personality already linked");

			// verify if AI Personality is already transferred to iNFT
			require(ERC721(personalityContract).ownerOf(personalityId + i) == address(this), "personality is not yet transferred");

			// retrieve NFT owner and verify if target NFT exists
			address owner = ERC721(targetContract).ownerOf(targetId + i);
			// Note: we do not require funder to be NFT owner,
			// if required this constraint should be added by the caller (iNFT Linker)
			require(owner != address(0), "target NFT doesn't exist");

			// emit an event - we log owner for each iNFT
			// and its convenient to do it here when we have the owner inline
			emit Minted(
				msg.sender,
				owner,
				recordId + i,
				aliValue,
				personalityContract,
				personalityId + i,
				targetContract,
				targetId + i
			);
		}

		// cumulative ALI value may overflow uint96, store it into uint256 on stack
		uint256 _aliValue = uint256(aliValue) * n;

		// in case when ALI tokens are expected to be locked within iNFT
		if(_aliValue > 0) {
			// verify ALI tokens are already transferred to iNFT
			require(aliBalance + _aliValue <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");
			// update ALI balance on the contract
			aliBalance += _aliValue;
		}

		// minting: for each iNFT in a batch
		for(uint96 i = 0; i < n; i++) {
			// bind AI Personality transferred and ALI ERC20 value transferred to an NFT specified
			bindings[recordId + i] = IntelliBinding({
				personalityContract : personalityContract,
				personalityId : personalityId + i,
				aliValue : aliValue,
				targetContract : targetContract,
				targetId : targetId + i
			});

			// fill in the AI Personality to iNFT binding
			personalityBindings[personalityContract][personalityId + i] = recordId + i;

			// fill in the reverse binding
			reverseBindings[targetContract][targetId + i] = recordId + i;
		}

		// increase total supply counter
		totalSupply += n;
	}

	/**
	 * @dev Restricted access function which destroys an iNFT, unbinding it from the
	 *      linked NFT, releasing an AI Personality, and ALI tokens locked in the iNFT
	 *
	 * @dev Transfers an AI Personality locked in iNFT to its owner via ERC721.safeTransferFrom;
	 *      owner must be an EOA or implement ERC721Receiver.onERC721Received properly
	 * @dev Transfers ALI tokens locked in iNFT to its owner
	 * @dev Since iNFT owner is determined as underlying NFT owner, this underlying NFT must
	 *      exist and its ownerOf function must not throw and must return non-zero owner address
	 *      for the underlying NFT ID
	 *
	 * @dev Doesn't verify if it's safe to send ALI tokens to the NFT owner, this check
	 *      must be handled by the transaction executor
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to burn (destroy, unbind)
	 */
	function burn(uint256 recordId) public {
		// verify the access permission
		require(isSenderInRole(ROLE_BURNER), "access denied");

		// decrease total supply counter
		totalSupply--;

		// read the token binding (we'll need to access all the fields)
		IntelliBinding memory binding = bindings[recordId];

		// verify binding exists
		require(binding.targetContract != address(0), "not bound");

		// destroy binding first to protect from any reentrancy possibility
		delete bindings[recordId];

		// free the reverse binding
		delete reverseBindings[binding.targetContract][binding.targetId];

		// free the AI Personality binding
		delete personalityBindings[binding.personalityContract][binding.personalityId];

		// determine an owner of the underlying NFT
		address owner = ERC721(binding.targetContract).ownerOf(binding.targetId);

		// verify that owner address is set (not a zero address)
		require(owner != address(0), "no such NFT");

		// transfer the AI Personality to the NFT owner
		// using safe transfer since we don't know if owner address can accept the AI Personality right now
		ERC721(binding.personalityContract).safeTransferFrom(address(this), owner, binding.personalityId);

		// in case when ALI tokens were locked within iNFT
		if(binding.aliValue > 0) {
			// update ALI balance on the contract prior to token transfer (reentrancy style)
			aliBalance -= binding.aliValue;

			// transfer the ALI tokens to the NFT owner
			ERC20(aliContract).transfer(owner, binding.aliValue);
		}

		// emit an event
		emit Burnt(
			msg.sender,
			recordId,
			owner,
			binding.aliValue,
			binding.personalityContract,
			binding.personalityId,
			binding.targetContract,
			binding.targetId
		);
	}

	/**
	 * @dev Restricted access function which updates iNFT record by increasing locked ALI tokens value,
	 *      effectively locking additional ALI tokens to the iNFT
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract;
	 *      ALI token amount must be transferred to the iNFT smart contract
	 *      prior to calling the `increaseAli`, but in the same transaction with `increaseAli`
	 *
	 * @dev To summarize, update transaction (a transaction which executes `increaseAli`) must
	 *      1) transfer ALI tokens
	 *      2) update the iNFT
	 *      NOTE: breaking the items above into multiple transactions is not acceptable!
	 *            (results in a security risk)
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to update
	 * @param aliDelta amount of ALI tokens to lock
	 */
	function increaseAli(uint256 recordId, uint96 aliDelta) public {
		// verify the access permission
		require(isSenderInRole(ROLE_EDITOR), "access denied");

		// verify the inputs are set
		require(aliDelta != 0, "zero value");

		// get iNFT owner for logging (check iNFT record exists under the hood)
		address owner = ownerOf(recordId);

		// cache the ALI value of the record
		uint96 aliValue = bindings[recordId].aliValue;

		// verify ALI tokens are already transferred to iNFT
		require(aliBalance + aliDelta <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");

		// update ALI balance on the contract
		aliBalance += aliDelta;

		// update ALI balance on the binding
		bindings[recordId].aliValue = aliValue + aliDelta;

		// emit an event
		emit Updated(msg.sender, owner, recordId, aliValue, aliValue + aliDelta);
	}

	/**
	 * @dev Restricted access function which updates iNFT record by decreasing locked ALI tokens value,
	 *      effectively unlocking some or all ALI tokens from the iNFT
	 *
	 * @dev Unlocked tokens are sent to the recipient address specified
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to update
	 * @param aliDelta amount of ALI tokens to unlock
	 * @param recipient an address to send unlocked tokens to
	 */
	function decreaseAli(uint256 recordId, uint96 aliDelta, address recipient) public {
		// verify the access permission
		require(isSenderInRole(ROLE_EDITOR), "access denied");

		// verify the inputs are set
		require(aliDelta != 0, "zero value");
		require(recipient != address(0), "zero address");

		// get iNFT owner for logging (check iNFT record exists under the hood)
		address owner = ownerOf(recordId);

		// cache the ALI value of the record
		uint96 aliValue = bindings[recordId].aliValue;

		// positive or zero resulting balance check
		require(aliValue >= aliDelta, "not enough ALI");

		// update ALI balance on the contract
		aliBalance -= aliDelta;

		// update ALI balance on the binding
		bindings[recordId].aliValue = aliValue - aliDelta;

		// transfer the ALI tokens to the recipient
		ERC20(aliContract).transfer(recipient, aliDelta);

		// emit an event
		emit Updated(msg.sender, owner, recordId, aliValue, aliValue - aliDelta);
	}

	/**
	 * @notice Determines how many tokens are locked in a particular iNFT
	 *
	 * @dev A shortcut for bindings(recordId).aliValue
	 * @dev Throws if iNFT specified doesn't exist
	 *
	 * @param recordId iNFT ID to query locked tokens balance for
	 * @return locked tokens balance, bindings[recordId].aliValue
	 */
	function lockedValue(uint256 recordId) public view returns(uint96) {
		// ensure iNFT exists
		require(exists(recordId), "iNFT doesn't exist");

		// read and return ALI value locked in the binding
		return bindings[recordId].aliValue;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC165Spec.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev Solidity issue #3412: The ERC721 interfaces include explicit mutability guarantees for each function.
 *      Mutability guarantees are, in order weak to strong: payable, implicit nonpayable, view, and pure.
 *      Implementation MUST meet the mutability guarantee in this interface and MAY meet a stronger guarantee.
 *      For example, a payable function in this interface may be implemented as nonpayable
 *      (no state mutability specified) in implementing contract.
 *      It is expected a later Solidity release will allow stricter contract to inherit from this interface,
 *      but current workaround is that we edit this interface to add stricter mutability before inheriting:
 *      we have removed all "payable" modifiers.
 *
 * @dev The ERC-165 identifier for this interface is 0x80ac58cd.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721 is ERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external /*payable*/;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external /*payable*/;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
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
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x5b5e139f.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Metadata is ERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x780e9d63.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Enumerable is ERC721 {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title String Utils Library
 *
 * @dev Library for working with strings, primarily converting
 *      between strings and integer types
 */
library StringUtils {
	/**
	 * @dev Converts a string to unsigned integer using the specified `base`
	 * @dev Throws on invalid input
	 *      (wrong characters for a given `base`)
	 * @dev Throws if given `base` is not supported
	 * @param a string to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return i a number representing given string
	 */
	function atoi(string memory a, uint8 base) internal pure returns (uint256 i) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// convert string into bytes for convenient iteration
		bytes memory buf = bytes(a);

		// iterate over the string (bytes buffer)
		for(uint256 p = 0; p < buf.length; p++) {
			// extract the digit
			uint8 digit = uint8(buf[p]) - 0x30;

			// if digit is greater then 10 - mind the gap
			// see `itoa` function for more details
			if(digit > 10) {
				// remove the gap
				digit -= 7;
			}

			// check if digit meets the base
			require(digit < base);

			// move to the next digit slot
			i *= base;

			// add digit to the result
			i += digit;
		}

		// return the result
		return i;
	}

	/**
	 * @dev Converts a integer to a string using the specified `base`
	 * @dev Throws if given `base` is not supported
	 * @param i integer to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return a a string representing given integer
	 */
	function itoa(uint256 i, uint8 base) internal pure returns (string memory a) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// for zero input the result is "0" string for any base
		if(i == 0) {
			return "0";
		}

		// bytes buffer to put ASCII characters into
		bytes memory buf = new bytes(256);

		// position within a buffer to be used in cycle
		uint256 p = 0;

		// extract digits one by one in a cycle
		while(i > 0) {
			// extract current digit
			uint8 digit = uint8(i % base);

			// convert it to an ASCII code
			// 0x20 is " "
			// 0x30-0x39 is "0"-"9"
			// 0x41-0x5A is "A"-"Z"
			// 0x61-0x7A is "a"-"z" ("A"-"Z" XOR " ")
			uint8 ascii = digit + 0x30;

			// if digit is greater then 10,
			// fix the 0x3A-0x40 gap of punctuation marks
			// (7 characters in ASCII table)
			if(digit >= 10) {
				// jump through the gap
				ascii += 7;
			}

			// write character into the buffer
			buf[p++] = bytes1(ascii);

			// move to the next digit
			i /= base;
		}

		// `p` contains real length of the buffer now,
		// allocate the resulting buffer of that size
		bytes memory result = new bytes(p);

		// copy the buffer in the reversed order
		for(p = 0; p < result.length; p++) {
			// copy from the beginning of the original buffer
			// to the end of resulting smaller buffer
			result[result.length - p - 1] = buf[p];
		}

		// construct string and return
		return string(result);
	}

	/**
	 * @dev Concatenates two strings `s1` and `s2`, for example, if
	 *      `s1` == `foo` and `s2` == `bar`, the result `s` == `foobar`
	 * @param s1 first string
	 * @param s2 second string
	 * @return s concatenation result s1 + s2
	 */
	function concat(string memory s1, string memory s2) internal pure returns (string memory s) {
		// an old way of string concatenation (Solidity 0.4) is commented out
/*
		// convert s1 into buffer 1
		bytes memory buf1 = bytes(s1);
		// convert s2 into buffer 2
		bytes memory buf2 = bytes(s2);
		// create a buffer for concatenation result
		bytes memory buf = new bytes(buf1.length + buf2.length);

		// copy buffer 1 into buffer
		for(uint256 i = 0; i < buf1.length; i++) {
			buf[i] = buf1[i];
		}

		// copy buffer 2 into buffer
		for(uint256 j = buf1.length; j < buf2.length; j++) {
			buf[j] = buf2[j - buf1.length];
		}

		// construct string and return
		return string(buf);
*/

		// simply use built in function
		return string(abi.encodePacked(s1, s2));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}