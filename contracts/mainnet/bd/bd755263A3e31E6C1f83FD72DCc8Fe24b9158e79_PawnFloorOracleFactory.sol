/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title PawnFloorOracle
 * @dev Stores and retrieves floor prices for a nft collection
 */
contract PawnFloorOracle  {
    address public collection;
    address public underwriter;
    uint256 public lastUpdate;
    uint256 public floor;
    
    event FloorChange(uint256 price, address underwriter, bool sale);
    
    constructor(address collection_) payable {
        collection = collection_;
    }
    
    modifier lastTransferAtLeast69Minutes() {
        require(block.timestamp - timeSinceLastUpdate() > 69 minutes);
        _;
    }
    
    function timeSinceLastUpdate() public view returns (uint256) {
        return block.timestamp - lastUpdate;
    }
    
    function sellFloor(uint256 tokenId) public {
        IERC721 c = IERC721(collection);
        require(msg.sender == c.ownerOf(tokenId), "not the owner");
        c.safeTransferFrom(msg.sender, underwriter, tokenId);
        payable(msg.sender).transfer(floor);
        underwriter = 0x0000000000000000000000000000000000000000;
        floor = 0;
        lastUpdate = block.timestamp;
        emit FloorChange(floor, underwriter, true);
    }
    
     /**
     * @dev withdraw money 
     */
    function withdraw() public lastTransferAtLeast69Minutes {
        require(msg.sender == underwriter, "only underwriter can withdraw their eth");
        payable(msg.sender).transfer(floor);
        underwriter = 0x0000000000000000000000000000000000000000;
        floor = 0;
        lastUpdate = block.timestamp;
        emit FloorChange(floor, underwriter, false);
    }

    /**
     * @dev Change the current price of this oracle up or down
     */
    function updateFloor() public payable {
        require(floor != msg.value && msg.value != 0, "invalid update");
        if (floor == 0) {
            underwriter = tx.origin;
            floor = msg.value;
            lastUpdate = block.timestamp;
            emit FloorChange(floor, underwriter, false);
        } else {
            require(block.timestamp - timeSinceLastUpdate() > 69 seconds, "not enough time elapsed");
            if (msg.value > floor) {
                require(payable(underwriter).send(address(this).balance), "old underwriter payout failed");
                floor = msg.value;
                underwriter = tx.origin;
                lastUpdate = block.timestamp;
                emit FloorChange(floor, underwriter, false);
            } else if (msg.value < floor) {
                require(underwriter == tx.origin, "only underwriter can lower floor");
                payable(tx.origin).transfer(floor);
                floor = msg.value;
                lastUpdate = block.timestamp;
                emit FloorChange(floor, underwriter, false);
            }
        }
    }
    
    fallback() external payable {

    }
}



contract PawnFloorOracleFactory {
    
    mapping(address=>address) public oracles;
    
    constructor() {
        
    }
    
    function addOracle(address collection) public payable {
        require(oracles[collection] == 0x0000000000000000000000000000000000000000, "already exists");
        require(msg.value > 0, "non zero oracle");
        PawnFloorOracle fo = new PawnFloorOracle(collection);
        fo.updateFloor{value: msg.value}();
        oracles[collection] = address(fo);
    }

}