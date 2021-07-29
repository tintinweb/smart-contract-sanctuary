// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Exists.sol";
import "./AccessExtension.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

/**
 * @title MetaKovan iNFT
 *
 * @notice Fully ERC721-compliant NFT with additional support for:
 *      - exists()
 *      - totalSupply()
 *      and other Metadata and Enumerable functions
 *
 * @author Basil Gorin
 */
contract MarkcubanToken is ERC721Exists, ERC721Enumerable, ERC721URIStorage, AccessExtension {

	/**
	 * @notice Keeping in line with the standard industry practice, 10% of the royalties of
	 *      any secondary sale of the iNFT will be set aside for the creator of the iNFT.
	 * @dev This royalty of 10% on secondary sales is stored in the contract and we expect
	 *      that it should be honored by most major NFT platforms
	 */
	address payable public royaltyAddress;

	/**
	 * @dev Base URI is used to construct IERC721Metadata.tokenURI as
	 *      baseURI + tokenId
	 *
	 * @dev For example, if baseURI is https://alethea.ai/iNFT/, then iNFT #1
	 *      will have an URI https://alethea.ai/iNFT/1
	 */
	string private baseURI = "";

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (executing `mint` function)
	 */
	bytes32 public constant ROLE_TOKEN_CREATOR = keccak256("ROLE_TOKEN_CREATOR");

	/**
	 * @notice URI manager is responsible for managing the tokenURI
	  *     of the IERC721Metadata interface
	 * @dev Role ROLE_URI_MANAGER allows updating the baseURI and tokenURI
	 *      (executing `setBaseURI` and `setTokenURI` functions)
	 */
	bytes32 public constant ROLE_URI_MANAGER = keccak256("ROLE_URI_MANAGER");

	/**
	 * @notice Royalty manager is responsible for managing contract's royalty address
	 *      field `royaltyAddress`
	 * @dev Role ROLE_ROYALTY_MANAGER allows updating the royaltyAddress
	 *      (executing `setRoyaltyAddress` function)
	 */
	bytes32 public constant ROLE_ROYALTY_MANAGER = keccak256("ROLE_ROYALTY_MANAGER");

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string oldVal, string newVal);

	/**
	 * @dev Fired in setRoyaltyAddress()
	 *
	 * @param _by an address which executed update
	 * @param oldVal old royaltyAddress value
	 * @param newVal new royaltyAddress value
	 */
	event RoyaltyAddressUpdated(address indexed _by, address indexed oldVal, address indexed newVal);

	/// @dev Creates/deploys an MetaKovan iNFT ERC721 instance
	constructor() ERC721("Mark Cuban iNFT", "iNFT") {}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessExtension) returns (bool) {
		// reconstruct from current interface and super interfaces
		return interfaceId == type(ERC721Exists).interfaceId
			|| ERC721Enumerable.supportsInterface(interfaceId)
			|| AccessExtension.supportsInterface(interfaceId);
	}

	/// @inheritdoc ERC721Exists
	function exists(uint256 tokenId) public override view returns (bool) {
		// delegate to Zeppelin `_exists`
		return _exists(tokenId);
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `to`.
	 *      Emits a {Transfer} event.
	 *
	 * See {ERC721._safeMint}
	 *
	 * @param to an address to mint token to
	 * @param tokenId token ID to mint
	 */
	function mint(address to, uint256 tokenId) public {
		// verify the access permission
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// mint token safely - delegate to `_safeMint`
		_safeMint(to, tokenId);
	}

	/// @inheritdoc IERC721Metadata
	function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
		// delegate to ERC721URIStorage impl
		return ERC721URIStorage.tokenURI(tokenId);
	}

	/**
	 * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
	 *
	 * See {ERC721URIStorage._setTokenURI}
	 *
	 * @param tokenId an ID of the token to set URI for
	 * @param _tokenURI tokenURI to set
	 */
	function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// delegate to ERC721URIStorage impl
		super._setTokenURI(tokenId, _tokenURI);
	}

	/// @inheritdoc ERC721
	function _baseURI() internal view override returns (string memory) {
		// read _baseURI from storage into memory and return
		return baseURI;
	}

	/**
	 * @dev Restricted access function which updates _baseURI used to construct
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

	/// @inheritdoc ERC721Enumerable
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
		// delegate to ERC721Enumerable impl
		ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
	}

	/// @inheritdoc ERC721URIStorage
	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		// delegate to ERC721URIStorage impl
		ERC721URIStorage._burn(tokenId);
	}

	/**
	 * @dev Restricted access function which updates the royalty address
	 *      field `royaltyAddress`
	 *
	 * @param _royaltyAddress new royalty address to set
	 */
	function setRoyaltyAddress(address payable _royaltyAddress) public {
		// verify the access permission
		require(isSenderInRole(ROLE_ROYALTY_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit RoyaltyAddressUpdated(_msgSender(), royaltyAddress, _royaltyAddress);

		// and update the royalty address
		royaltyAddress = _royaltyAddress;
	}
}