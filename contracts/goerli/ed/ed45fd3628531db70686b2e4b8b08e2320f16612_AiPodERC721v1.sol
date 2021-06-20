// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessExtension.sol";
import "./ERC721Enumerable.sol";

/**
 * @title AI Pod Interface
 *        Version 1
 *
 * @notice External interface of AiPodERC721 declared to support ERC165 detection.
 *      See AI Pod documentation below.
 *
 * @author Basil Gorin
 */
interface IAiPodERC721v1 {
	function exists(uint256 tokenId) external view returns (bool);
}

/**
 * @title AI Pod
 *      Version 1
 *
 * @notice AI Pod represents an access key to the Alethea AI protocol.
 *      AI Pod is linked to a regular NFT and becomes a usable iNFT.
 *
 * @notice AI Pod is fully ERC721-compatible token.
 *     The terms "token" and "AI Pod", as well as the terms "token ID" and "AI Pod ID"
 *     within current file soldoc are interchangeable
 *
 * @notice AI Pods are effectively access keys to the Alethea AI protocol.
 *     AI Pod is uniquely defined by its generation, batch within generation,
 *     and number within generation:
 *        - generation
 *        - batch within a generation
 *        - number within a batch
 *     AI Pod is also uniquely identified by its video (or video fingerprint stored on-chain)
 *     Finally, AI Pod can be uniquely identified via its tokenId tracked by this smart contract
 *     and storing the rest of the properties on-chain
 *
 * @notice Generation.
 *     AI Technology is common at the generational level, so, as an example,
 *     all Generation 1 AI Pods will bestow the same capabilities,
 *     but when AI improves significantly, we'll move to Generation 2
 *
 * @notice Batch.
 *     Keeps track of when AI Pod was released.
 *     Genesis Batch marks the beginning, and is followed by Batch 1, Batch 2, Batch 3, etc.
 *
 * @dev Limited Zeppelin-based implementation: Version 1
 *
 * @dev AI Pod ID space is limited to 64 bits, meaning there
 *      can be up to 18,446,744,073,709,551,615 AI Pods ever created
 *
 * @dev Some known limitations of Version 1:
 *     - No meta transactions support
 *     - No way to track AI Pods by generation/batch/number
 *     - No guarantee on the smart contract level of generation/batch/number combination uniqueness
 *     - No way to track AI Pods by video fingerprint
 *     - No guarantee on the smart contract level of video fingerprint uniqueness
 *
 * @author Basil Gorin
 */
contract AiPodERC721v1 is IAiPodERC721v1, ERC721Enumerable, AccessExtension {
	/**
	 * @dev AI Pod is an access key to the Alethea AI protocol.
	 *
	 * @dev Pods come in generations, further split into batches, each containing a number of pods
	 *
	 * @dev Each generation consists from a number of AI Pod batches
	 *      (all of which have the same functionality within the generation,
	 *      as such generation 1 pods will be less technically capable of generation two pods)
	 *      with each individual AI Pod having its number within the batch.
	 *
	 * @dev AI Pod stores some essential information on-chain;
	 *      the data structure stored is defined by Pod struct
	 */
	struct Pod {
		/**
		 * @notice AI Pod generation
		 */
		uint64 generation;

		/**
		 * @notice AI Pod batch number within the generation
		 */
		uint64 batch;

		/**
		 * @notice AI Pod number within the batch
		 */
		uint64 number;

		/**
		 * @dev Fingerprint of the associated with AI Pod video;
		 *      it can be a cryptographic hash, or any other kind of hash,
		 *      which uniquely determines a particular video
		 */
		uint256 videoFingerprint;
	}

	/**
	 * @dev Storage for all the AI Pods data tracked by this contract
	 */
	mapping(uint256 => Pod) public pods;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (executing `mint` function)
	 */
	bytes32 public constant ROLE_TOKEN_CREATOR = keccak256("ROLE_TOKEN_CREATOR");

	/**
	 * @notice URI manager is responsible for managing baseURI
	 *      part of the tokenURI IERC721Metadata interface
   * @dev Role ROLE_URI_MANAGER allows updating the base URI
   *      (executing `setBaseURI` function)
	 */
	bytes32 public constant ROLE_URI_MANAGER = keccak256("ROLE_URI_MANAGER");

	/**
	 * @dev Base URI is used to construct IERC721Metadata.tokenURI as
	 *      baseURI + tokenId
	 *
	 * @dev For example, if baseURI is https://alethea.ai/iNFT/, then iNFT #1
	 *      will have an URI https://alethea.ai/iNFT/1
	 */
	// TODO: approve initially set baseURI with Alethea
	string private baseURI = "https://inft.alethea.ai/pod/";

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string oldVal, string newVal);

	/**
	 * @dev Fired in mint()
	 *
	 * @param by an address which minted the token
	 * @param to an address token was minted to
	 * @param tokenId token ID minted
	 * @param generation AI Pod generation
	 * @param batch AI Pod batch
	 * @param number AI Pod number
	 * @param videoFingerprint fingerprint of the associated video
	 */
	event Minted(
		address indexed by,
		address to,
		uint64 tokenId,
		uint64 indexed generation,
		uint64 indexed batch,
		uint64 number,
		uint256 videoFingerprint
	);

	/**
	 * @dev Fired in burn()
	 *
	 * @param by an address which burnt the token
	 * @param from an address token was burnt from
	 * @param tokenId token ID burnt
	 * @param generation AI Pod generation
	 * @param batch AI Pod batch
	 * @param number AI Pod number
	 * @param videoFingerprint fingerprint of the associated video
	 */
	event Burnt(
		address indexed by,
		address from,
		uint64 tokenId,
		uint64 indexed generation,
		uint64 indexed batch,
		uint64 number,
		uint256 videoFingerprint
	);

	/**
	 * @dev Creates/deploys an AI Pod ERC721 instance
	 */
	constructor() ERC721("Alethea AI Pod", "POD") {}

	/**
	 * @inheritdoc IERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessExtension) returns (bool) {
		// reconstruct from current interface and super interfaces
		return interfaceId == type(IAiPodERC721v1).interfaceId
			|| ERC721Enumerable.supportsInterface(interfaceId)
			|| AccessExtension.supportsInterface(interfaceId);
	}

	/**
	 * @dev Restricted access function which updates iNFT _baseURI used to construct
	 *      IERC721Metadata.tokenURI
	 *
	 * @param __baseURI new _baseURI to set
	 */
	function setBaseURI(string memory __baseURI) public {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(_msgSender(), baseURI, __baseURI);

		// and update base URI
		baseURI = __baseURI;
	}

	/**
	 * @notice Checks if token defined by its ID exists
	 *
	 * @notice Tokens can be managed by their owner or approved
	 *      accounts via `approve` or `setApprovalForAll`.
	 *
	 * @notice Tokens start existing when they are minted (`mint`),
	 *      and stop existing when they are burned (`burn`).
	 *
	 * @param tokenId ID of the token to check existence for
	 * @return true if token exists, false otherwise
	 */
	function exists(uint256 tokenId) public override view returns (bool) {
		// delegate to Zeppelin `_exists`
		return _exists(tokenId);
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `to`.
	 *      Emits a {Transfer} event.
	 *
	 * @dev Stores AI Pod data associated with the tokenId on-chain
	 *
	 * See {ERC721._safeMint}
	 *
	 * @param to an address to mint token to
	 * @param tokenId token ID to mint
	 * @param generation AI Pod generation
	 * @param batch AI Pod batch
	 * @param number AI Pod number
	 * @param videoFingerprint fingerprint of the associated video
	 */
	function mint(
		address to,
		uint64 tokenId,
		uint64 generation,
		uint64 batch,
		uint64 number,
		uint256 videoFingerprint
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// mint token safely - delegate to `_safeMint`
		_safeMint(to, tokenId);

		// save AI Pod data into the storage
		pods[tokenId] = Pod({
			generation: generation,
			batch: batch,
			number: number,
			videoFingerprint: videoFingerprint
		});

		// emit an event
		emit Minted(_msgSender(), to, tokenId, generation, batch, number, videoFingerprint);
	}

	/**
	 * @dev Destroys `tokenId` owned by transaction sender.
	 *      The approval is cleared when the token is burned.
	 *      Emits a {Transfer} event.
	 *
	 * @dev Releases AI Pod data associated with the tokenId on-chain
	 *
	 * See {ERC721._burn}
	 *
	 * @param tokenId token ID to burn
	 */
	function burn(uint64 tokenId) public {
		// get the token owner info
		address owner = ownerOf(tokenId);

		// verify token is burnt by its owner
		require(_msgSender() == owner, "access denied");

		// burn - delegate to `_burn`
		_burn(tokenId);

		// load AI Pod into memory for logging
		Pod memory pod = pods[tokenId];

		// cleanup the storage
		delete pods[tokenId];

		// emit an event
		emit Burnt(_msgSender(), owner, tokenId, pod.generation, pod.batch, pod.number, pod.videoFingerprint);
	}

	/**
	 * @inheritdoc ERC721
	 */
	function _baseURI() internal view override returns (string memory) {
		// read _baseURI from storage into memory and return
		return baseURI;
	}

}