/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

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


interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external;

    /**
      Consumes a message that was sent from an L2 contract.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external;
}

interface IBridgedERC721 is IERC721 {
    function mint(address to, uint256 tokenId, string memory uri) external;
    function exists(uint256 tokenId) external view returns (bool);
}

contract Gateway {
    address public initialSetter;
    IBridgedERC721 public l1Token;
    uint256 public l2Token;
    uint256 public l2Gateway;
    IStarknetCore public starknetCore;
    uint256 constant L2_GATEWAY_SELECTOR =
        1738423374452994793145864788013146788518531877200292826651981332061687045062; // bridge_from_mainnet
    uint256 constant BRIDGE_MODE_WITHDRAW = 1;

    // Bootstrap
    constructor(address _starknetCore) {
        require(
            _starknetCore != address(0),
            "Gateway/Invalid Starknet Core Address"
        );

        starknetCore = IStarknetCore(_starknetCore);
        initialSetter = msg.sender;
    }

    function initializeGateway(IBridgedERC721 _l1Token, uint256 _l2Token, uint256 _l2Gateway) external {
        require(
            msg.sender == initialSetter,
            "Gateway/Unauthorized"
        );
        require(address(l1Token) == address(0), "Gateway/L1 Token Already Set");
        require(l2Token == 0, "Gateway/L2 Token Already Set");
        require(l2Gateway == 0, "Gateway/L2 Gateway Already Set");

        l1Token = _l1Token;
        l2Token = _l2Token;
        l2Gateway = _l2Gateway;
    }

    // Utils
    function addressToUint(address value)
        internal
        pure
        returns (uint256 convertedValue)
    {
        convertedValue = uint256(uint160(address(value)));
    }

    // Bridging to Starknet
    // Note: check and msg.sender to approve l1Gateway as an operator for l1Token beforehand
    function bridgeToStarknet(
        uint256 _tokenId,
        uint256 _account
    ) external {
        uint256[] memory payload = new uint256[](4);

        // optimistic transfer, should revert if not approved or not owner
        l1Token.transferFrom(msg.sender, address(this), _tokenId);

        // build deposit message payload
        payload[0] = _account;
        payload[1] = addressToUint(address(l1Token));
        payload[2] = l2Token;
        payload[3] = _tokenId;

        // send message
        starknetCore.sendMessageToL2(
            l2Gateway,
            L2_GATEWAY_SELECTOR,
            payload
        );
    }

    // Bridging back from Starknet
    function bridgeFromStarknet(
        uint256 _tokenId,
        string memory _uri
    ) external {
        uint256[] memory payload = new uint256[](5);

        // build withdraw message payload
        payload[0] = BRIDGE_MODE_WITHDRAW;
        payload[1] = addressToUint(msg.sender);
        payload[2] = addressToUint(address(l1Token));
        payload[3] = l2Token;
        payload[4] = _tokenId;

        // consume withdraw message
        starknetCore.consumeMessageFromL2(l2Gateway, payload);

        if (l1Token.exists(_tokenId)) {
            // optimistic transfer, should revert if gateway is not token owner
            l1Token.transferFrom(address(this), msg.sender, _tokenId);
        } else {
            // mint the NFT on L1
            l1Token.mint(msg.sender, _tokenId, _uri);
        }
    }
}