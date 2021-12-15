// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@jpegmint/contracts/harvest/ERC721Harvest.sol";

/**____________________________________________________________________
|   ________________________________________________________________   |
|  |                                                                |  |
|  |                                                                |  |
|  |                           ▓▓                ▒▒░░░░░░           |  |
|  |                           ▓▓            ░░    ▒▒░░░░           |  |
|  |                         ░░▓▓            ░░░░  ░░               |  |
|  |                         ░░▓▓      ░░░░░░  ░░░░▒▒░░▒▒           |  |
|  |                         ░░▓▓          ░░  ▒▒  ░░▒▒▒▒           |  |
|  |       ▓▓▓▓            ░░░░▓▓  ░░  ░░░░░░░░░░▒▒░░               |  |
|  |         ▓▓██▓▓        ░░░░░░    ░░    ░░  ▒▒░░▒▒               |  |
|  |           ▓▓██▓▓      ░░░░░░░░░░░░░░░░▒▒▒▒░░▒▒                 |  |
|  |           ▓▓██▓▓▓▓  ░░░░░░  ░░  ░░    ▒▒░░▒▒▒▒                 |  |
|  |             ██▓▓▓▓  ░░▒▒  ░░░░▒▒░░▒▒▒▒░░▒▒▒▒                   |  |
|  |             ▓▓██▓▓▓▓░░  ░░░░▒▒░░▒▒    ▒▒░░▒▒                   |  |
|  |             ▓▓██▓▓▓▓  ░░░░  ░░▒▒▒▒▒▒▒▒░░▒▒                     |  |
|  |               ▓▓▓▓▓▓▒▒  ▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒                     |  |
|  |               ▓▓▓▓▓▓░░  ▒▒░░▒▒  ▒▒▒▒▒▒▒▒▒▒                     |  |
|  |               ▓▓▓▓▓▓  ▒▒▒▒  ▒▒░░▒▒░░░░▒▒                       |  |
|  |             ▓▓██▓▓░░▒▒░░▒▒▒▒▒▒▒▒░░▒▒▒▒██████▓▓                 |  |
|  |             ▓▓██▓▓░░▒▒▒▒░░▒▒░░▒▒▒▒▒▒▒▒██▓▓▓▓▓▓▓▓▓▓▓▓           |  |
|  |             ▓▓██▓▓░░▒▒▒▒▒▒▒▒▒▒░░▒▒████▓▓████▓▓▓▓▓▓▓▓▓▓         |  |
|  |             ▓▓██▓▓████▒▒▒▒░░▒▒▒▒████████▓▓▓▓        ▓▓         |  |
|  |             ▓▓██▓▓████▒▒▒▒▒▒▒▒████▓▓▓▓                         |  |
|  |               ▓▓██▓▓██▒▒▒▒▒▒████                               |  |
|  |               ▓▓██▓▓██▒▒████                                   |  |
|  |                 ▓▓██▓▓██                                       |  |
|  |                                                                |  |
|  |                                                                |  |
|  |    ██╗  ██╗ █████╗ ██████╗ ██╗   ██╗███████╗███████╗████████╗  |  |
|  |    ██║  ██║██╔══██╗██╔══██╗██║   ██║██╔════╝██╔════╝╚══██╔══╝  |  |
|  |    ███████║███████║██████╔╝██║   ██║█████╗  ███████╗   ██║     |  |
|  |    ██╔══██║██╔══██║██╔══██╗╚██╗ ██╔╝██╔══╝  ╚════██║   ██║     |  |
|  |    ██║  ██║██║  ██║██║  ██║ ╚████╔╝ ███████╗███████║   ██║     |  |
|  |    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝   ╚═╝     |  |
|  |________________________________________________________________|  |
|_____________________________________________________________________*/

                 contract Harvest is ERC721Harvest {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC721Harvest is IERC721Receiver {
    
// Amount per token purchased
    uint256 public constant AMOUNT_PER_TOKEN = 1 gwei;

// Contract owner
    address public owner;

// Initialization

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

// Ownable

    modifier onlyOwner() {
        require(owner == msg.sender, "X");
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

// Harvest

    modifier hasAvailableBalance(uint256 howMany) {
        require(address(this).balance > AMOUNT_PER_TOKEN * howMany, "$");
        _;
    }

    function sellTokenIds(address erc721Contract, uint256[] memory tokenIds)
        external
        hasAvailableBalance(tokenIds.length)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _receiveToken(erc721Contract, tokenIds[i]);
        }

        _payForTransaction(msg.sender, tokenIds.length);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata)
        external
        override
        hasAvailableBalance(1)
        returns (bytes4)
    {
        _payForTransaction(operator, 1);
        return this.onERC721Received.selector;
    }

    function _receiveToken(address erc721Contract, uint256 tokenId) internal {
        IERC721(erc721Contract).transferFrom(msg.sender, address(this), tokenId);
    }

    function _payForTransaction(address to, uint256 howMany) internal {
        (bool sent, ) = payable(to).call{ value: AMOUNT_PER_TOKEN * howMany }("");
        require(sent, "$");
    }

// Recover

    function recover(address erc721Contract, uint256 tokenId, address to) external onlyOwner {
        IERC721(erc721Contract).transferFrom(address(this), to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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