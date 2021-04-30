/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/daveappleton/Documents/akombalabs/trait_allocator/distribution/sender721B/sender721B.sol
// flattened :  Friday, 30-Apr-21 10:47:58 UTC
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
contract sender721B {

    address  _owner;
    mapping(address=>mapping(address => bool)) public access;

    event Permission(address owner, address operator,bool permission);

    modifier onlyAllowed(address owner) {
        require(access[owner][msg.sender],"Unauthorised");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner,"Unauthorised");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function sendManyToMany(
        IERC721 token, 
        address owner, 
        address [] memory to, 
        uint256 [] memory tokenIds
        ) public  onlyAllowed(owner) {
        require(token.isApprovedForAll(owner,address(this)),"You have not set ApproveForAll");
        for (uint256 j = 0; j < to.length; j++) {
            token.transferFrom(msg.sender,to[j],tokenIds[j]);
        }
    }

   function sendManyToOne(
       IERC721 token, 
       address owner, 
       address to, 
       uint256[] memory tokenIds
       ) public onlyAllowed(owner) {
        require(token.isApprovedForAll(owner,address(this)),"You have not set ApproveForAll");
        for (uint256 j = 0; j < tokenIds.length; j++) {
            token.transferFrom(msg.sender,to,tokenIds[j]);
        }
    }

   function sendManyToManyFor(
       IERC721 token,
       address owner, 
       address [] memory to, 
       uint256 [] memory tokenIds
       ) public onlyAllowed(owner) {
        
        require(token.isApprovedForAll(owner,address(this)),"Owner has not set ApproveForAll");
        for (uint256 j = 0; j < to.length; j++) {
            token.transferFrom(owner,to[j],tokenIds[j]);
        }
    }

   function sendManyToOneFor(
       IERC721 token, 
       address owner,
       address to, 
       uint256[] memory tokenIds
       ) public onlyAllowed(owner) {
        require(token.isApprovedForAll(owner,address(this)),"Owner has not set ApproveForAll");
        for (uint256 j = 0; j < tokenIds.length; j++) {
            token.transferFrom(owner,to,tokenIds[j]);
        }
    }

    function permitAccess(address token,address operator, bool permission) external onlyOwner {
        access[token][operator] = permission;
        emit Permission(msg.sender,operator,permission);
    }
}