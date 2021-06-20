// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessExtension.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

/**
 * @title Intelligent NFT Interface
 *        Version 1
 *
 * @notice External interface of IntelligentNFTv1 declared to support ERC165 detection.
 *      See Intelligent NFT documentation below.
 *
 * @author Basil Gorin
 */
interface IIntelligentNFTv1 {
	function totalSupply() external view returns (uint256);
	function exists(uint256 recordId) external view returns (bool);
	function ownerOf(uint256 recordId) external view returns (address);
}

/**
 * @title Intelligent NFT (iNFT)
 *        Version 1
 *
 * @notice Intelligent NFT (iNFT) represents an enhancement to an existing NFT
 *      (we call it a "target" or "target NFT"), it binds a GPT-3 prompt (a "personality prompt")
 *      to the target to embed intelligence, is controlled and belongs to the owner of the target.
 *
 * @notice iNFT stores AI Pod and some amount of ALI tokens locked, available to
 *      unlocking when iNFT is destroyed
 *
 * @notice iNFT is not an ERC721 token, but it has some very limited similarity to an ERC721:
 *      every record is identified by ID and this ID has an owner, which is effectively the target NFT owner;
 *      still, it doesn't store ownership information itself and fully relies on the target ownership instead
 *
 * @dev Internally iNFTs consist of:
 *      - personality prompt - a GPT-3 prompt defining its intelligent capabilities
 *      - target NFT - smart contract address and ID of the NFT the iNFT is bound to
 *      - AI Pod - ID of the AI Pod used to produce given iNFT, locked within an iNFT
 *      - ALI tokens amount - amount of the ALI tokens used to produce given iNFT, also locked
 *
 * @dev iNFTs can be
 *      - created, this process requires an AI Pod and ALI tokens to be locked
 *      - destroyed, this process releases an AI Pod and ALI tokens previously locked;
 *         ALI token fee may get withheld upon destruction
 *
 * @dev Some known limitations of Version 1:
 *      - doesn't support ERC1155 as a target NFT
 *      - only one-to-one iNFT-NFT bindings,
 *         no many-to-one, one-to-many, or many-to-many bindings not allowed
 *      - no AI Pod ID -> iNFT ID binding, impossible to look for iNFT by AI Pod ID
 *      - no enumeration support, iNFT IDs created must be tracked off-chain,
 *         or [recommended] generated with a predictable deterministic integer sequence,
 *         for example, 1, 2, 3, ...
 *      - no support for personality prompt upgrades (no way to update personality prompt)
 *      - burn: doesn't allow to specify where to send the iNFT burning fee, sends ALI tokens
 *         burner / transaction sender (iNFT Linker)
 *      - burn: doesn't verify if its safe to send ALI tokens released back to NFT owner;
 *         ALI tokens may get lost if iNFT is burnt when NFT belongs to a smart contract which
 *         is not aware of the ALI tokens being sent to it
 *      - no target NFT ID optimization; storage usage for IntelliBinding can be optimized
 *         if short target NFT IDs are recognized and stored optimized
 *      - AI Pod ERC721 and ALI ERC20 smart contracts are set during the deployment and cannot be changed
 *
 * @author Basil Gorin
 */
contract IntelligentNFTv1 is IIntelligentNFTv1, AccessExtension {
	/**
	 * @notice Deployer is responsible for AI Pod and ALI tokens contract address initialization
	 *
	 * @dev Role ROLE_DEPLOYER allows executing `setPodContract` and `setAliContract` functions
	 */
	bytes32 public constant ROLE_DEPLOYER = keccak256("ROLE_DEPLOYER");

	/**
	 * @notice Minter is responsible for creating (minting) iNFTs
	 *
	 * @dev Role ROLE_MINTER allows minting iNFTs (calling `mint` function)
	 */
	bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");

	/**
	 * @notice Burner is responsible for destroying (burning) iNFTs
	 *
	 * @dev Role ROLE_BURNER allows burning iNFTs (calling `burn` function)
	 */
	bytes32 public constant ROLE_BURNER = keccak256("ROLE_BURNER");

	/**
	 * @dev Each intelligent token, represented by its unique ID, is bound to the target NFT,
	 *      defined by the pair of the target NFT smart contract address and unique token ID
	 *      within the target NFT smart contract
	 *
	 * @dev Effectively iNFT is owned by the target NFT owner
	 *
	 * @dev Additionally, each token holds an AI Pod and some amount of ALI tokens bound to it
	 *
	 * @dev `IntelliBinding` keeps all the binding information, including target NFT coordinates,
	 *      bound AI Pod ID, and amount of ALI ERC20 tokens bound to the iNFT
	 */
	struct IntelliBinding {
		// Note: structure members are reordered to fit into less memory slots, see EVM memory layout
		// ----- SLOT.1 (256/256)
		/**
		 * @dev Personality prompt is a hash of the data used to feed GPT-3 algorithm
		 */
		uint256 personalityPrompt;

		// ----- SLOT.2 (160/256)
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

		// ----- SLOT.4 (160/256)
		/**
		 * @dev AI Pod ID bound to (owned by) the iNFT
		 *
		 * @dev Similar to target NFT, specific AI Pod is also defined by pair of AI Pod smart contract address
		 *       and AI Pod ID; the first one, however, is defined globally and stored in `podContract` constant.
		 */
		uint64 podId;

		/**
		 * @dev Amount of an ALI ERC20 tokens bound to (owned by) the iNFTs
		 *
		 * @dev ALI ERC20 smart contract address is defined globally as `aliContract` constant
		 */
		uint96 aliValue;
	}

	/**
	 * @notice iNFT binding storage, stores binding information for each existing iNFT
	 * @dev Maps iNFT ID to its binding data, which includes underlying NFT data
	 */
	mapping (uint256 => IntelliBinding) public bindings;

	/**
	 * @notice Reverse iNFT binding allows to find iNFT bound to a particular NFT
	 * @dev Maps target NFT (smart contract address and unique token ID) to the linked iNFT:
	 *      NFT Contract => NFT ID => iNFT ID
	 */
	mapping (address => mapping(uint256 => uint256)) reverseBinding;

	/**
	 * @notice Total amount (maximum value estimate) of iNFT in existence.
	 *       This value can be higher than number of effectively accessible iNFTs
	 *       since when underlying NFT gets burned this value doesn't get updated.
	 */
	uint256 public override totalSupply;

	/**
	 * @notice Each iNFT holds an AI Pod which is tracked by the AI Pod NFT smart contract defined here
	 */
	address public podContract;

	/**
	 * @notice Each iNFT holds some ALI tokens, which are tracked by the ALI token ERC20 smart contract defined here
	 */
	address public aliContract;

	/**
	 * @dev Fired in mint() when new iNFT is created
	 *
	 * @param by an address which executed the mint function
	 * @param owner current owner of the NFT
	 * @param recordId ID of the iNFT to mint (create, bind)
	 * @param payer and address which funds the creation (supplies AI Pod and ALI tokens)
	 * @param podId ID of the AI Pod to bind (transfer) to newly created iNFT
	 * @param aliValue amount of ALI tokens to bind (transfer) to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId target NFT ID (where this iNFT binds to and belongs to)
	 * @param personalityPrompt personality prompt for the minted iNFT
	 */
	event Minted(
		address indexed by,
		address owner,
		uint64 recordId,
		address payer,
		uint64 podId,
		uint96 aliValue,
		address targetContract,
		uint256 targetId,
		uint256 personalityPrompt
	);

	/**
	 * @dev Fired in burn() when an existing iNFT gets destroyed
	 *
	 * @param by an address which executed the burn function
	 * @param recordId ID of the iNFT to burn (destroy, unbind)
	 * @param recipient and address which receives unlocked AI Pod and ALI tokens (NFT owner)
	 * @param podId ID of the AI Pod to unbind (transfer) from the destroyed iNFT
	 * @param aliValue amount of ALI tokens to unbind (transfer) from the destroyed iNFT
	 * @param aliFee service fee in ALI tokens withheld by burn executor
	 * @param targetContract target NFT smart contract
	 * @param targetId target NFT ID (where this iNFT was bound to and belonged to)
	 * @param personalityPrompt personality prompt for that iNFT
	 */
	event Burnt(
		address indexed by,
		uint64 recordId,
		address recipient,
		uint64 podId,
		uint96 aliValue,
		uint96 aliFee,
		address targetContract,
		uint256 targetId,
		uint256 personalityPrompt
	);

	/**
	 * @dev Fired in setPodContract()
	 *
	 * @param by an address which set the `podContract`
	 * @param podContract AI Pod contract address set
	 */
	event PodContractSet(address indexed by, address podContract);

	/**
	 * @dev Fired in setAliContract()
	 *
	 * @param by an address which set the `aliContract`
	 * @param aliContract ALI token contract address set
	 */
	event AliContractSet(address indexed by, address aliContract);

	/**
	 * @dev Creates/deploys an iNFT instance not bound to AI Pod / ALI token instances
	 */
	constructor() {
		// setup admin role for smart contract deployer initially
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}

	/**
	 * @dev Binds an iNFT instance to already deployed AI Pod instance
	 *
	 * @param _pod address of the deployed AI Pod instance to bind iNFT to
	 */
	function setPodContract(address _pod) public {
		// verify sender has permission to access this function
		require(isSenderInRole(ROLE_DEPLOYER), "access denied");

		// verify the input is set
		require(_pod != address(0), "AI Pod addr is not set");

		// verify _pod is valid ERC721
		require(IERC165(_pod).supportsInterface(type(IERC721).interfaceId), "AI Pod addr is not ERC721");

		// setup smart contract internal state
		podContract = _pod;

		// emit an event
		emit PodContractSet(_msgSender(), _pod);
	}

	/**
	 * @dev Binds an iNFT instance to already deployed ALI Token instance
	 *
	 * @param _ali address of the deployed ALI Token instance to bind iNFT to
	 */
	function setAliContract(address _ali) public {
		// verify sender has permission to access this function
		require(isSenderInRole(ROLE_DEPLOYER), "access denied");

		// verify the input is set
		require(_ali != address(0), "ALI Token addr is not set");

		// verify _ali is valid ERC20
		require(IERC165(_ali).supportsInterface(type(IERC20).interfaceId), "ALI Token addr is not ERC20");

		// setup smart contract internal state
		aliContract = _ali;

		// emit an event
		emit AliContractSet(_msgSender(), _ali);
	}

	/**
	 * @inheritdoc IERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(IIntelligentNFTv1).interfaceId || super.supportsInterface(interfaceId);
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
		// read the token binding
		IntelliBinding memory binding = bindings[recordId];

		// verify the binding exists and throw standard Zeppelin message if not
		require(binding.targetContract != address(0), "iNFT doesn't exist");

		// delegate `ownerOf` call to the target NFT smart contract
		return IERC721(binding.targetContract).ownerOf(binding.targetId);
	}

	/**
	 * @dev Restricted access function which creates an iNFT, binding it to the specified
	 *      NFT, locking the AI Pod specified, and funded with the amount of ALI specified
	 *
	 * @dev Transfers AI Pod defined by its ID into iNFT smart contract for locking;
	 *      linking funder must authorize the transfer operation before the mint is called
	 * @dev Transfers specified amount of ALI token into iNFT smart contract for locking;
	 *      funder must authorize the transfer operation before the mint is called
	 * @dev The NFT to be linked to doesn't required to belong to the funder, but it must exist
	 *
	 * @dev Throws if target NFT doesn't exist
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to mint (create, bind)
	 * @param funder and address which funds the creation (supplies AI Pod and ALI tokens)
	 * @param personalityPrompt personality prompt for that iNFT
	 * @param podId ID of the AI Pod to bind (transfer) to newly created iNFT
	 * @param aliValue amount of ALI tokens to bind (transfer) to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	function mint(
		uint64 recordId,
		address funder,
		uint256 personalityPrompt,
		uint64 podId,
		uint96 aliValue,
		address targetContract,
		uint256 targetId
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_MINTER), "access denied");

		// verify this token ID is not yet bound
		require(!exists(recordId), "iNFT already exists");

		// verify the NFT is not yet bound
		require(reverseBinding[targetContract][targetId] == 0, "target NFT already linked");

		// transfer the AI Pod from the specified address `_from`
		// using unsafe transfer to avoid unnecessary `onERC721Received` triggering
		// Note: we explicitly request AI Pod transfer from the linking funder to be safe
		// from the scenarios of potential misuse of AI Pods
		IERC721(podContract).transferFrom(funder, address(this), podId);

		// transfer the ALI tokens from the specified address `_from`
		// using unsafe transfer to avoid unnecessary callback triggering
		if(aliValue > 0) {
			// note: Zeppelin based AliERC20v1 transfer implementation fails on any error
			IERC20(aliContract).transferFrom(funder, address(this), aliValue);
		}

		// retrieve NFT owner and verify if target NFT exists
		address owner = IERC721(targetContract).ownerOf(targetId);
		// Note: we do not require funder to be NFT owner,
		// if required this constraint should be added by the caller (iNFT Linker)
		require(owner != address(0), "target NFT doesn't exist");

		// bind AI Pod transferred and ALI ERC20 value transferred to an NFT specified
		bindings[recordId] = IntelliBinding({
			personalityPrompt: personalityPrompt,
			targetContract: targetContract,
			targetId: targetId,
			podId: podId,
			aliValue: aliValue
		});

		// fill in the reverse binding
		reverseBinding[targetContract][targetId] = recordId;

		// increase total supply counter
		totalSupply++;

		// emit an event
		emit Minted(_msgSender(), owner, recordId, funder, podId, aliValue, targetContract, targetId, personalityPrompt);
	}

	/**
	 * @dev Restricted access function which destroys an iNFT, unbinding it from the
	 *      linked NFT, releasing an AI Pod, and ALI tokens locked in the iNFT
	 *
	 * @dev Transfers an AI Pod locked in iNFT to its owner via ERC721.safeTransferFrom;
	 *      owner must be an EOA or implement IERC721Receiver.onERC721Received properly
	 * @dev Transfers ALI tokens locked in iNFT to its owner and a fee specified to
	 *      transaction executor
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
	 * @param aliFee service fee in ALI tokens to be withheld
	 */
	function burn(uint64 recordId, uint96 aliFee) public {
		// verify the access permission
		require(isSenderInRole(ROLE_BURNER), "access denied");

		// decrease total supply counter
		totalSupply--;

		// read the token binding
		IntelliBinding memory binding = bindings[recordId];

		// verify binding exists
		require(binding.targetContract != address(0), "not bound");

		// destroy binding first to protect from any reentrancy possibility
		delete bindings[recordId];

		// free the reverse binding
		delete reverseBinding[binding.targetContract][binding.targetId];

		// make sure fee doesn't exceed what is bound to iNFT
		require(aliFee <= binding.aliValue);

		// send the fee to transaction sender
		if(aliFee > 0) {
			// note: Zeppelin based AliERC20v1 transfer implementation fails on any error
			require(IERC20(aliContract).transfer(_msgSender(), aliFee));
		}

		// determine an owner of the underlying NFT
		address owner = IERC721(binding.targetContract).ownerOf(binding.targetId);

		// verify that owner address is set (not a zero address)
		require(owner != address(0), "no such NFT");

		// transfer the AI Pod to the NFT owner
		// using safe transfer since we don't know if owner address can accept the AI Pod right now
		IERC721(podContract).safeTransferFrom(address(this), owner, binding.podId);

		// transfer the ALI tokens to the NFT owner
		if(binding.aliValue > aliFee) {
			// note: Zeppelin based AliERC20v1 transfer implementation fails on any error
			IERC20(aliContract).transfer(owner, binding.aliValue - aliFee);
		}

		// emit an event
		emit Burnt(_msgSender(), recordId, owner, binding.podId, binding.aliValue, aliFee, binding.targetContract, binding.targetId, binding.personalityPrompt);
	}
}