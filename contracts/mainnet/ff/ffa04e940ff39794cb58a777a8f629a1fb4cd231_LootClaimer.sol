/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// File: @openzeppelin/contracts/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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

interface IERC1155_Mintable {
    // Multiple mint tokens. Assign directly to _to[].
    function safeBatchMint(address _to, uint256[] calldata _id, uint256[] calldata _quantities) external;
    
    //mint tokens. Assign directly to _to[].
    function safeMint(address _to, uint256 _id, uint256 _quantities) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract LootClaimer is Context {
    IERC1155_Mintable public nftTicket;
    IERC721 public lootNFT;
    IERC721 public xlootNFT;
    uint256[] rewardTicketId = [0,1,2];
    uint256[] rewardTicketLeft = [50, 300, 650];
    uint256 claimLeft = 1000;

    mapping(address => bool) claimedStatus; //address claimed or not
    
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account);

    constructor(address _nftTicket, address _lootNFT, address _xlootNFT) {
        nftTicket = IERC1155_Mintable(_nftTicket);
        lootNFT = IERC721(_lootNFT);
        xlootNFT = IERC721(_xlootNFT);
    }

    function isClaimed(address user) public view returns (bool) {
        return claimedStatus[user];
    }

    function _setClaimed(address user) private {
        claimedStatus[user] = true;
    }

    function claim() public returns (uint256 nftTicketId){
        require(!isClaimed(_msgSender()), "Drop already claimed");
        require(claimLeft > 0, "No Claim Left");
        require(lootNFT.balanceOf(_msgSender())>0 || xlootNFT.balanceOf(_msgSender())>0, "No loot item");

        
        // Mark it claimed
        _setClaimed(_msgSender());
        emit Claimed(claimLeft, _msgSender());
        
        uint256 result = randomGen(claimLeft, claimLeft);
        uint256 filter = 0;
        for (uint256 i = 0; i < rewardTicketId.length; ++i) {
            filter = filter + rewardTicketLeft[i];
            if (filter > result) {
                nftTicket.safeMint(_msgSender(), rewardTicketId[i], 1);
                claimLeft = claimLeft - 1;
                rewardTicketLeft[i] = rewardTicketLeft[i] - 1;
                return rewardTicketId[i];
            }
        }
        
    }
    
    function randomGen(uint256 seed, uint256 max) private view returns (uint256 randomNumber) {
        return (uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, block.difficulty, seed))) % max);
    }
    
}