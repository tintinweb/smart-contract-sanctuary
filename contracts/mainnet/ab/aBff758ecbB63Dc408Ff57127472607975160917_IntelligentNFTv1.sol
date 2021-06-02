// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessExtension.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Access Control List Extension Interface
 *
 * @notice External interface of AccessExtension declared to support ERC165 detection.
 *      See Access Control List Extension documentation below.
 *
 * @author Basil Gorin
 */
interface IAccessExtension is IAccessControl {
	function removeFeature(bytes32 feature) external;
	function addFeature(bytes32 feature) external;
	function isFeatureEnabled(bytes32 feature) external view returns(bool);
}

/**
 * @title Access Control List Extension
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
 * @notice Terms "permission", "single permission" implies only one permission set.
 *
 * @dev OpenZeppelin AccessControl based implementation. Features are stored as
 *      "self"-roles: feature is a role assigned to the smart contract itself
 *
 * @dev Automatically assigns the deployer an admin permission
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @author Basil Gorin
 */
contract AccessExtension is IAccessExtension, AccessControl {
	constructor() {
		// setup admin role for smart contract deployer initially
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}

	/**
	 * @inheritdoc IERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(IAccessExtension).interfaceId || super.supportsInterface(interfaceId);
	}

	/**
	 * @notice Removes the feature from the set of the globally enabled features,
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have a permission to set the feature requested
	 *
	 * @param feature a feature to disable
	 */
	function removeFeature(bytes32 feature) public override {
		// delegate to Zeppelin's `revokeRole`
		revokeRole(feature, address(this));
	}

	/**
	 * @notice Adds the feature to the set of the globally enabled features,
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have a permission to set the feature requested
	 *
	 * @param feature a feature to enable
	 */
	function addFeature(bytes32 feature) public override {
		// delegate to Zeppelin's `grantRole`
		grantRole(feature, address(this));
	}

	/**
	 * @notice Checks if requested feature is enabled globally on the contract
	 *
	 * @param feature the feature to check
	 * @return true if the feature requested is enabled, false otherwise
	 */
	function isFeatureEnabled(bytes32 feature) public override view returns(bool) {
		// delegate to Zeppelin's `hasRole`
		return hasRole(feature, address(this));
	}

	/**
 * @notice Checks if transaction sender `msg.sender` has the role required
 *
 * @param role the role to check against
 * @return true if sender has the role required, false otherwise
 */
	function isSenderInRole(bytes32 role) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return hasRole(role, _msgSender());
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}