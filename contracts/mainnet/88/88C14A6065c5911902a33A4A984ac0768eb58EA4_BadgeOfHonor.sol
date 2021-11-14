// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./platform/tokens/ERC1155/ERC1155.sol";

/*******************************************************************
 * go ye, Sinners, and shine the light of Plenty onto the world,   *
 * for It is daRk and full of sIn.  tell Them who revel in poverty *
 * and >discord< to repent and unite in wealth. -- 66:14, CoE      *
 *******************************************************************/

//
// Badge of Honor - Upvoting/Downvoting of Identities for EVM-based Networks
//
// Wallets May Be Anonymous. Behaviour Is Not.
//

enum BadgeType {
    Badass,
    Asshole
}

contract BadgeOfHonor is ERC1155 {
    event BadassAwarded(address indexed to, address indexed from, uint256 indexed qt);
    event AssholeAwarded(address indexed to, address indexed from, uint256 indexed qt);
    string private constant BADASS_URI = "https://arweave.net/tRe8Y2pTQzDis2Wp6Rmh0RUVQ0p5zhyJL3uocokFYRs";
    string private constant ASSHOLE_URI = "https://arweave.net/vLFz2LGEIIyNe-oWLawbvfhIE_EtDRSkDmrNM872I40";

    uint256 public fee;
    address public owner;

    constructor(uint256 fee_) {
        fee = fee_;
        owner = msg.sender;
    }

    function award(
        address to,
        BadgeType badge,
        uint256 qt
    ) external payable {
        require(qt > 0, "InvalidQuantity");
        require(fee * qt == msg.value, "InvalidETHAmount");

        ERC1155._mint(to, uint256(badge), qt, "");

        if (badge == BadgeType.Badass) {
            emit BadassAwarded(to, msg.sender, qt);
        } else {
            emit AssholeAwarded(to, msg.sender, qt);
        }
    }

    function uri(uint256 id)
        public
        pure
        returns (string memory)
    {
        return (id == uint256(BadgeType.Badass)) ? BADASS_URI : ASSHOLE_URI;
    }

    function setFee(uint256 fee_) external {
        _enforceOnlyOwner();
        fee = fee_;
    }

    function withdraw() external {
        _enforceOnlyOwner();
        payable(msg.sender).transfer(address(this).balance);
    }

    function _enforceOnlyOwner() internal view {
        require(msg.sender == owner, "UnauthorizedAccess");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./extensions/IERC1155MetadataURI.sol";

abstract contract ERC1155 is IERC1155, IERC1155MetadataURI {
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        require(account != address(0), "ERC1155: balance of address(0)");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: param lengths mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
        public
    {
        require(msg.sender != operator, "ERC1155: approval for self");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        from; to; id; amount; data; 
        _enforceNonTransferable();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        from; to; ids; amounts; data;
        _enforceNonTransferable();
    }

    function _enforceNonTransferable() internal pure {
        revert("WearYourBadgeProudly!");
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        data;
        _balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}