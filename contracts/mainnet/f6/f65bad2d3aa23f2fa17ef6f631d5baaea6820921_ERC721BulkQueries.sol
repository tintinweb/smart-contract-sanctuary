/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// File: contracts/interface/IERC165.sol

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

// File: contracts/interface/IERC721.sol

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

// File: contracts/interface/IERC721Metadata.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/wrappers/ERC721BulkQueries.sol

pragma solidity 0.8.6;



contract ERC721BulkQueries {
    constructor() {}

    function balanceOfBulk(address contract_, address[] memory owners) public view returns (uint256[] memory) {
        require(owners.length > 0 && owners.length <= 2500, "Query limit is 2500");
        IERC721 contractERC721 = IERC721(contract_);

        uint256[] memory balances = new uint256[](owners.length);
        for(uint256 i = 0; i < owners.length; i++) {
            balances[i] = contractERC721.balanceOf(owners[i]);
        }

        return balances;
    }

    function ownerOfBulk(address contract_, uint256[] memory tokenIds) public view returns (address[] memory) {
        require(tokenIds.length > 0 && tokenIds.length <= 2500, "Query limit is 2500");
        IERC721 contractERC721 = IERC721(contract_);

        address[] memory owners = new address[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            owners[i] = contractERC721.ownerOf(tokenIds[i]);
        }

        return owners;
    }

    function getApprovedBulk(address contract_, uint256[] memory tokenIds) public view returns (address[] memory) {
        require(tokenIds.length > 0 && tokenIds.length <= 2500, "Query limit is 2500");
        IERC721 contractERC721 = IERC721(contract_);

        address[] memory operators = new address[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            operators[i] = contractERC721.getApproved(tokenIds[i]);
        }

        return operators;
    }

    function isApprovedForAllBulk(address contract_, address owner, address[] memory operators) public view returns (bool[] memory) {
        require(operators.length > 0 && operators.length <= 2500, "Query limit is 2500");
        IERC721 contractERC721 = IERC721(contract_);

        bool[] memory approvalsForAll = new bool[](operators.length);
        for(uint256 i = 0; i < operators.length; i++) {
            approvalsForAll[i] = contractERC721.isApprovedForAll(owner, operators[i]);
        }

        return approvalsForAll;
    }

    function tokenURIBulk(address contract_, uint256[] memory tokenIds) public view returns (string[] memory) {
        require(tokenIds.length > 0 && tokenIds.length <= 2500, "Query limit is 2500");
        IERC721Metadata contractERC721 = IERC721Metadata(contract_);

        string[] memory uris = new string[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uris[i] = contractERC721.tokenURI(tokenIds[i]);
        }

        return uris;
    }

}