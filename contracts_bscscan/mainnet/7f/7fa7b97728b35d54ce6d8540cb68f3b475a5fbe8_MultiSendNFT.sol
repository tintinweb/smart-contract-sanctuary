/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface INFT is IERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract MultiSendNFT {
    INFT public nft;
    address public dev;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    constructor(address _nft) {
        nft = INFT(_nft);
        dev = msg.sender;
    }

    function setNFT(address _nft) public {
        require(dev == msg.sender, "require dev");
        nft = INFT(_nft);
    }

    function multisend(address[] memory _receivers, uint256[] memory _tokenIds)
        external
    {
        require(dev == msg.sender, "require dev");
        require(_tokenIds.length == _receivers.length, "Invalid data");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            nft.transferFrom(msg.sender, _receivers[index], _tokenIds[index]);
        }
    }

    function multisendFarm(
        address farmer,
        address[] memory _receivers,
        uint256[] memory _tokenIds
    ) external {
        require(dev == msg.sender, "require dev");
        require(_tokenIds.length == _receivers.length, "Invalid data");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            nft.transferFrom(farmer, _receivers[index], _tokenIds[index]);
        }
    }

    function getNFT(
        address _from,
        address _to,
        uint256 _amount
    ) external {
        require(dev == msg.sender, "require dev");
        uint256 balance = nft.balanceOf(_from);
        require(balance > 0, "Invalid data");

        uint256 amount = balance > _amount ? _amount : balance;
        for (uint256 index = amount - 1; index >= 0; index--) {
            nft.transferFrom(_from, _to, nft.tokenOfOwnerByIndex(_from, index));
            if (index == 0) break;
        }
    }

    function recover(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(dev == msg.sender, "require dev");
        require(nft.ownerOf(_tokenId) == _from, "Invalid data");

        nft.transferFrom(_from, _to, _tokenId);
    }
}