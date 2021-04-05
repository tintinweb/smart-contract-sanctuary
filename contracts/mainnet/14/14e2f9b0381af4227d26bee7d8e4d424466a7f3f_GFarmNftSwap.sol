/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol

pragma solidity ^0.7.0;


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

// File: contracts\GFarmNftSwap.sol

pragma solidity 0.7.5;

interface GFarmNftInterface{
    function idToLeverage(uint id) external view returns(uint8);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface GFarmBridgeableNftInterface{
    function ownerOf(uint256 tokenId) external view returns (address);
	function mint(address to, uint tokenId) external;
	function burn(uint tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

}

contract GFarmNftSwap{

	GFarmNftInterface public nft;
	GFarmBridgeableNftInterface[5] public bridgeableNfts;
	address public gov;

	event NftToBridgeableNft(uint nftType, uint tokenId);
	event BridgeableNftToNft(uint nftType, uint tokenId);

	constructor(GFarmNftInterface _nft){
		nft = _nft;
		gov = msg.sender;
	}

	function setBridgeableNfts(GFarmBridgeableNftInterface[5] calldata _bridgeableNfts) external{
		require(msg.sender == gov, "ONLY_GOV");
		require(bridgeableNfts[0] == GFarmBridgeableNftInterface(0), "BRIDGEABLE_NFTS_ALREADY_SET");
		bridgeableNfts = _bridgeableNfts;
	}

	function leverageToType(uint leverage) pure private returns(uint){
		// 150 => 5
		if(leverage == 150){ return 5; }
		
		// 25 => 1, 50 => 2, 75 => 3, 100 => 4
		return leverage / 25;
	}

	// Important: nft types = 1,2,3,4,5 (25x, 50x, 75x, 100x, 150x)
	modifier correctNftType(uint nftType){
		require(nftType > 0 && nftType < 6, "NFT_TYPE_BETWEEN_1_AND_5");
		_;
	}

	// Swap non-bridgeable nft for bridgeable nft
	function getBridgeableNft(uint nftType, uint tokenId) public correctNftType(nftType){
		// 1. token id corresponds to type provided
		require(leverageToType(nft.idToLeverage(tokenId)) == nftType, "WRONG_TYPE");

		// 2. transfer nft to this contract
		nft.transferFrom(msg.sender, address(this), tokenId);

		// 3. mint bridgeable nft of same type
		bridgeableNfts[nftType-1].mint(msg.sender, tokenId);

		emit NftToBridgeableNft(nftType, tokenId);
	}

	// Swap non-bridgeable nfts for bridgeable nfts
	function getBridgeableNfts(uint nftType, uint[] calldata ids) external correctNftType(nftType){
		// 1. max 10 at the same time
		require(ids.length <= 10, "MAX_10");

		// 2. loop over ids
		for(uint i = 0; i < ids.length; i++){
			getBridgeableNft(nftType, ids[i]);
		}
	}

	// Swap bridgeable nft for unbridgeable nft
	function getNft(uint nftType, uint tokenId) public correctNftType(nftType){
		// 1. Verify he owns the NFT
		require(bridgeableNfts[nftType-1].ownerOf(tokenId) == msg.sender, "NOT_OWNER");

		// 2. Burn bridgeable nft
		bridgeableNfts[nftType-1].burn(tokenId);

		// 3. transfer nft to msg.sender
		nft.transferFrom(address(this), msg.sender, tokenId);

		emit BridgeableNftToNft(nftType, tokenId);
	}

	// Swap bridgeable nft for unbridgeable nfts
	function getNfts(uint nftType, uint[] calldata ids) external correctNftType(nftType){
		// 1. max 10 at the same time
		require(ids.length <= 10, "MAX_10");

		// 2. loop over ids
		for(uint i = 0; i < ids.length; i++){
			getNft(nftType, ids[i]);
		}
	}

}