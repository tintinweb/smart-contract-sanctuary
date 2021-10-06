/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.6;



// Part: IERC721Bridge

interface IERC721Bridge {
    event ERC721DepositInitiated (
        address indexed _l1Token,
        uint256 indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _tokenId
    );

    function depositTo(
        address l1Token_,
        uint256 tokenId_,
        uint256 l2Token_,
        uint256 l2Destination_
    ) external;

    function finalizeWithdrawal(
        address l1Token_,
        uint256 tokenId_,
        uint256 l2Token_,
        address l1Destination_
    ) external;
}

// Part: IStarknetCore

interface IStarknetCore {
    /// @dev Sends a message to an L2 contract.
    function sendMessageToL2(
        uint256 toAddress_,
        uint256 selector_,
        uint256[] calldata payload_
    ) external;

    /// @dev Consumes a message that was sent from an L2 contract.
    function consumeMessageFromL2(uint256 fromAddress_, uint256[] calldata payload_) external;
}

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC721

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

// File: ERC721Bridge.sol

contract ERC721Bridge is IERC721Bridge {
    // cairo selector of the "finalize_deposit" method.
    uint256 constant FINALIZE_DEPOSIT_SELECTOR =
        352040181584456735608515580760888541466059565068553383579463728554843487745;

    uint256 constant MESSAGE_WITHDRAW = 0;

    address private starknetCore;

    // flag that is true if address-tokenId where deposited in the bridge.
    mapping(address => mapping(uint256 => bool)) public deposited;

    // map between address-tokenId and layer 2 address.
    mapping(address => mapping(uint256 => uint256)) private bridgedAddress;

    constructor(address starknetCore_) {
        starknetCore = starknetCore_;
    }

    function depositTo(
        address l1Token_,
        uint256 tokenId_,
        uint256 l2Token_,
        uint256 l2Destination_
    )
        external
        virtual
        override
    {
        _initiateDeposit(l1Token_, tokenId_, l2Token_, l2Destination_);
    }

    function finalizeWithdrawal(
        address l1Token_,
        uint256 tokenId_,
        uint256 l2Token_,
        address l1Destination_
    )
        external
        virtual
        override
    {
        deposited[l1Token_][tokenId_] = false;

        uint256[] memory payload = new uint256[](4);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = uint160(l1Token_);
        payload[2] = tokenId_;
        payload[3] = uint160(l1Destination_);

        // reverts if message does not exist
        IStarknetCore(starknetCore).consumeMessageFromL2(l2Token_, payload);

        IERC721(l1Token_).safeTransferFrom(address(this), l1Destination_, tokenId_);
    }

    function _initiateDeposit(
        address l1Token_,
        uint256 tokenId_,
        uint256 l2Token_,
        uint256 l2Destination_
    )
        internal
    {
        require(deposited[l1Token_][tokenId_] == false, "ALREADY_DEPOSITED");

        deposited[l1Token_][tokenId_] = true;
        bridgedAddress[l1Token_][tokenId_] = l2Token_;

        IERC721(l1Token_).safeTransferFrom(msg.sender, address(this), tokenId_);

        uint256[] memory payload = new uint256[](3);
        payload[0] = uint160(l1Token_);
        payload[1] = tokenId_;
        payload[2] = l2Destination_;

        IStarknetCore(starknetCore).sendMessageToL2(l2Token_, FINALIZE_DEPOSIT_SELECTOR, payload);
    }
}