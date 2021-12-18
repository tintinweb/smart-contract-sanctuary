// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.5;

import "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol";
import "./Resource.sol";

contract ChestSale is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;

    struct UserStats {
        uint256 weeksValue;
        uint256 chestsBought;
    }

    uint256 constant public TOTAL_CHESTS = 290000;  // must be a multiple of TOTAL_WEEKS * 4
    uint256 constant public WEEK = 7 * 24 * 60 * 60;
    uint256 constant public TOTAL_WEEKS = 29;
    uint256 constant public CHESTS_PER_WEEK = TOTAL_CHESTS / TOTAL_WEEKS;
    uint256 constant public WEEK_BALANCE = CHESTS_PER_WEEK / 4;
    uint256 public limitPerUser = 250;
    uint256 public weekStart;
    uint256 public weeksLeft = TOTAL_WEEKS;
    uint256 public chestsLeft;
    uint256 public chestPricePhi = 10 ether;
    uint256 public chestPriceEth = .1 ether;

    Resource private immutable _resource;
    IERC20 private immutable _phi;
    mapping (address => UserStats) private _userStats;
    uint256[4] public balances;

    event ChestsOpened(address indexed player, uint256[] tokenIds);
    event ChestPricePhiUpdated(uint256 newValue);
    event ChestPriceEthUpdated(uint256 newValue);
    event LimitPerUserUpdated(uint256 newValue);
    event StartTimeUpdated(uint256 newValue);

    constructor(Resource resource_, IERC20 phi_, uint256 delayStart) {
        _resource = resource_;
        _phi = phi_;
        _startWeek();
        if (delayStart > 0)
            weekStart = delayStart;

        emit ChestPricePhiUpdated(chestPricePhi);
        emit ChestPriceEthUpdated(chestPriceEth);
        emit LimitPerUserUpdated(limitPerUser);
        emit StartTimeUpdated(weekStart);
    }

    function _startWeek() private {
        uint256 weeksLeft_ = weeksLeft;
        require(weeksLeft_ > 0, "chest sale is over");
        weeksLeft = weeksLeft_ - 1;
        weekStart = block.timestamp;
        chestsLeft = CHESTS_PER_WEEK;
        balances[0] = balances[1] = balances[2] = balances[3] = WEEK_BALANCE;
    }

    /// @notice Open chests. User must have at least chestPricePhi * count PHI approved to this contract
    ///         and send value of chestPriceEth * count
    /// @param count The number of chests to open
    function openChest(uint256 count) external payable {
        uint256 phiFee = chestPricePhi * count;
        IERC20 phi = _phi;

        require(block.timestamp >= weekStart, "chest sale is not started yet");
        require(count > 0 && count <= 500, "invalid count");

        // start next week if needed
        if (block.timestamp - weekStart >= WEEK)
            _startWeek();

        uint256 chestsLeft_ = chestsLeft;
        require(chestsLeft_ >= count, "not enough available chests");
        require(msg.value == chestPriceEth * count, "incorrect value sent");
        require(phi.balanceOf(msg.sender) >= phiFee, "insufficient PHI balance");

        // update user's weekly limit
        UserStats storage userStats = _userStats[msg.sender];
        if (userStats.weeksValue != weeksLeft) {
            userStats.chestsBought = 0;
            userStats.weeksValue = weeksLeft;
        }
        require(userStats.chestsBought + count <= limitPerUser, "your weekly limit is exceeded");
        userStats.chestsBought += count;

        // take PHI fee
        if (phiFee > 0)
            phi.safeTransferFrom(msg.sender, address(this), phiFee);

        // select tokens in opened chests
        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        tokenIds[3] = 4;
        uint256[] memory tokenAmounts = new uint256[](4);
        for (uint256 i=0; i<count; i++) {
            // `i` is mixed into the hash data to add randomness for each opened chest
            uint256 tokenId = uint256(keccak256(abi.encodePacked(500 - i, block.timestamp, blockhash(block.number - 1), i))) % 4;
            // move to the next tokenId if there is no selected on the contract balance, revert if none are available
            if (balances[tokenId] == 0) {
                if (balances[(tokenId+1) % 4] != 0) {
                    tokenId = (tokenId+1) % 4;
                } else if (balances[(tokenId+2) % 4] != 0) {
                    tokenId = (tokenId+2) % 4;
                } else if (balances[(tokenId+3) % 4] != 0) {
                    tokenId = (tokenId+3) % 4;
                } else {
                    revert("sold out");
                }
            }
            balances[tokenId]--;
            tokenAmounts[tokenId]++;
        }

        // send tokens
        _resource.safeBatchTransferFrom(address(this), msg.sender, tokenIds, tokenAmounts, "");

        chestsLeft = chestsLeft_ - count;
        emit ChestsOpened(msg.sender, tokenIds);
    }

    /// @notice Withdraw AVAX and PHI fees
    /// @param to Address to withdraw fees to
    function withdrawFees(address to) external onlyOwner {
        (bool sent, bytes memory data) = to.call{value: address(this).balance}("");
        require(sent, "an error occurred while sending avax");
        _phi.safeTransfer(to, _phi.balanceOf(address(this)));
    }

    /// @notice Changes AVAX fee amount
    /// @param newValue New AVAX fee value
    function updateChestPriceEth(uint256 newValue) external onlyOwner {
        require(newValue > 0, "must not be zero");
        require(chestPriceEth != newValue, "no change");
        chestPriceEth = newValue;
        emit ChestPriceEthUpdated(newValue);
    }

    /// @notice Changes AVAX fee amount
    /// @param newValue New AVAX fee value
    function updateChestPricePhi(uint256 newValue) external onlyOwner {
        require(newValue > 0, "must not be zero");
        require(chestPricePhi != newValue, "no change");
        chestPricePhi = newValue;
        emit ChestPricePhiUpdated(newValue);
    }

    /// @notice Changes weekly limit per user
    /// @param newValue New weekly limit per user value
    function updateLimitPerUser(uint256 newValue) external onlyOwner {
        require(newValue > 0, "must not be zero");
        require(limitPerUser != newValue, "no change");
        limitPerUser = newValue;
        emit LimitPerUserUpdated(newValue);
    }

    /// @notice Changes sale start time
    /// @param newTime New sale start time
    function updateStartTime(uint256 newTime) external onlyOwner {
        require(weekStart > block.timestamp, "sale has already started");
        require(weekStart != newTime, "no change");
        require(newTime >= block.timestamp, "cannot set start time in past");
        weekStart = newTime;
        emit StartTimeUpdated(newTime);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance1 = _resource.balanceOf(address(this), 1);
        uint256 balance2 = _resource.balanceOf(address(this), 2);
        uint256 balance3 = _resource.balanceOf(address(this), 3);
        uint256 balance4 = _resource.balanceOf(address(this), 4);
        if (balance1 > 0)
            _resource.safeTransferFrom(address(this), msg.sender, 1, balance1, "");
        if (balance2 > 0)
            _resource.safeTransferFrom(address(this), msg.sender, 2, balance2, "");
        if (balance3 > 0)
            _resource.safeTransferFrom(address(this), msg.sender, 3, balance3, "");
        if (balance4 > 0)
            _resource.safeTransferFrom(address(this), msg.sender, 4, balance4, "");
    }

    function startWeek() external onlyOwner {
        require(block.timestamp - weekStart >= WEEK, "too soon");
        _startWeek();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.5;

import "OpenZeppelin/[email protected]/contracts/utils/structs/EnumerableSet.sol";

library CustomEnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;

        mapping (bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    struct UintToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToUintMap storage map, uint256 key, string memory errorMessage) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }








    // UintToAddressMap

    struct AddressToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);

        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(AddressToUintMap storage map, address key, string memory errorMessage) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.5;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "OpenZeppelin/[email protected]/contracts/utils/Counters.sol";
import "OpenZeppelin/[email protected]/contracts/security/Pausable.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol";
import "OpenZeppelin/[email protected]/contracts/utils/structs/EnumerableSet.sol";
import "./CustomEnumerableMap.sol";
import "./Resource.sol";

contract Game2 is Ownable, ERC1155Holder, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using CustomEnumerableMap for CustomEnumerableMap.AddressToUintMap;

    struct GamePlayer {
        address addr;
        uint256[3] placedCards;
        uint256 boostValue;
        uint256 boostUsedRound;
    }

    struct GameInfo {
        uint256 gameId;
        GamePlayer[2] player;
        bool started;
        bool finished;
        uint8 turn;
        address winner;
        uint8 round;
        uint256 lastAction;
        uint256 bank;
    }

    struct LeaderboardItem {
        address player;
        uint256 wins;
    }

    Counters.Counter internal _gameIds;
    mapping (uint256 => GameInfo) _games;
    uint256 public boostPrice = 1 ether;
    uint256 public abortTimeout = 5 * 60;  // seconds
    uint256 public joinPrice;
    uint256 public minWeight;
    uint256 public maxWeight;
    uint256 public epoch = 30 * 60;
    uint256 public fee = 50000;  // 1e6
    CustomEnumerableMap.AddressToUintMap _playerWins;
    mapping (address => EnumerableSet.UintSet) internal _playerGames;
    mapping (address => uint256) public lastGameTimestamps;
    mapping (address => uint256) public currentGames;

    Resource internal immutable _resource;
    IERC20 internal immutable _phi;

    event PlayerEntered(uint256 indexed gameId, address indexed player);
    event GameStarted(uint256 indexed gameId);
    event PlayerPlacedCard(uint256 indexed gameId, address indexed player, uint256 tokenId);
    event GameFinished(uint256 indexed gameId, address indexed winner);
    event GameAborted(uint256 indexed gameId, address indexed winner);
    event BoostUsed(uint256 indexed gameId, address indexed player, uint256 round, uint256 value);

    event JoinPriceUpdated(uint256 newValue);
    event MinWeightUpdated(uint256 newValue);
    event MaxWeightUpdated(uint256 newValue);
    event AbortTimeoutUpdated(uint256 newValue);
    event BoostPriceUpdated(uint256 newValue);
    event EpochUpdated(uint256 newValue);

    constructor(Resource resource, IERC20 phi, uint256 joinPrice_, uint256 minWeight_, uint256 maxWeight_) {
        _resource = resource;
        _phi = phi;
        joinPrice = joinPrice_;
        minWeight = minWeight_;
        maxWeight = maxWeight_;
        _createGame();

        emit JoinPriceUpdated(joinPrice_);
        emit MinWeightUpdated(minWeight_);
        emit MaxWeightUpdated(maxWeight_);
        emit AbortTimeoutUpdated(abortTimeout);
        emit BoostPriceUpdated(boostPrice);
        emit EpochUpdated(epoch);
    }

    function _createGame() private {
        _gameIds.increment();
        uint256 gameId = _gameIds.current();
        GameInfo storage game_ = _games[gameId];
        game_.gameId = gameId;
        game_.player[0].boostUsedRound = 0xFF;
        game_.player[1].boostUsedRound = 0xFF;
    }

    function game(uint256 gameId) external view returns (GameInfo memory) {
        return _games[gameId];
    }

    function playerWins(address player) external view returns (uint256) {
        return _playerWins.get(player);
    }

    function playerGames(address player) external view returns (uint256[] memory) {
        return _playerGames[player].values();
    }

    function joinGame() external whenNotPaused {
        require(currentGames[msg.sender] == 0, "you are playing already");
        require(block.timestamp - lastGameTimestamps[msg.sender] >= epoch, "wait for join timeout");
        uint256 gameId = _gameIds.current();
        GameInfo storage game_ = _games[gameId];

        // check if total owned cards weight is in range
        uint256 accumulatedWeight = 0;
        uint256 cardsCount = 0;
        uint256[] memory ownedTokens = _resource.ownedTokens(msg.sender);
        for (uint256 i=0; i < ownedTokens.length; i++) {
            // skip element cards
            if (ownedTokens[i] > 4) {
                uint256 balance = _resource.balanceOf(msg.sender, ownedTokens[i]);
                accumulatedWeight += _resource.getResourceWeight(ownedTokens[i]) * balance;
                cardsCount += balance;
                require(accumulatedWeight <= maxWeight, "you have too much cards weight");
            }
        }
        require(accumulatedWeight >= minWeight, "you don't have enough cards weight");
        require(cardsCount >= 3, "you don't have 3 cards");

        _phi.safeTransferFrom(msg.sender, address(this), joinPrice);
        game_.bank += joinPrice;

        if (game_.player[0].addr == address(0)) {
            game_.player[0].addr = msg.sender;
        } else {
            game_.player[1].addr = msg.sender;

            game_.started = true;
            emit GameStarted(gameId);
            _createGame();
        }
        emit PlayerEntered(gameId, msg.sender);

        _playerGames[msg.sender].add(gameId);
        game_.lastAction = block.timestamp;
        currentGames[msg.sender] = gameId;
        lastGameTimestamps[msg.sender] = block.timestamp;
    }

    function placeCard(uint256 tokenId) external {
        uint256 gameId = currentGames[msg.sender];
        require(gameId != 0, "you are not playing a game");
        GameInfo storage game_ = _games[gameId];
        require(game_.started, "game has not started");
        bool turn0 = game_.turn == 0;
        require(turn0 && game_.player[0].addr == msg.sender || !turn0 && game_.player[1].addr == msg.sender, "not your turn");
        _resource.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        game_.player[game_.turn].placedCards[game_.round] = tokenId;
        game_.turn = turn0 ? 1 : 0;
        if (!turn0)
            game_.round++;
        emit PlayerPlacedCard(gameId, msg.sender, tokenId);
        game_.lastAction = block.timestamp;
        if (game_.round == 3)
            _finishGame(game_);
    }

    function _finishGame(GameInfo storage game_) private {
        game_.finished = true;
        uint256[2] memory weights;
        uint256 multiplier = 1;
        int8 balance = 0;
        for (uint8 r=0; r < 3; r++) {
            for (uint8 p=0; p < 2; p++) {
                multiplier = game_.player[p].boostUsedRound == r ? game_.player[p].boostValue : 1;
                weights[p] = _resource.getResourceWeight(game_.player[p].placedCards[r]) * multiplier;
                _resource.safeTransferFrom(address(this), game_.player[p].addr, game_.player[p].placedCards[r], 1, "");
            }
            if (weights[0] > weights[1])
                balance++;
            else if (weights[1] > weights[0])
                balance--;
        }
        if (balance > 0)
            game_.winner = game_.player[0].addr;
        else if (balance < 0)
            game_.winner = game_.player[1].addr;
        if (balance != 0) {
            uint256 prevWins = 0;
            if (_playerWins.contains(game_.winner))
                prevWins = _playerWins.get(game_.winner);
            _playerWins.set(game_.winner, prevWins + 1);
            _phi.safeTransfer(game_.winner, game_.bank * (1e6 - fee) / 1e6);
        } else {
            _phi.safeTransfer(game_.player[0].addr, game_.bank / 2);
            _phi.safeTransfer(game_.player[1].addr, game_.bank / 2);
        }

        currentGames[game_.player[0].addr] = 0;
        currentGames[game_.player[1].addr] = 0;

        emit GameFinished(game_.gameId, game_.winner);
    }

    function boost() external {
        uint256 gameId = currentGames[msg.sender];
        require(gameId != 0, "you are not playing a game");
        GameInfo storage game_ = _games[gameId];
        require(game_.started, "game is not running");
        bool turn0 = game_.turn == 0;
        require(turn0 && game_.player[0].addr == msg.sender || !turn0 && game_.player[1].addr == msg.sender, "not your turn");
        require(turn0 && game_.player[0].boostUsedRound == 0xFF || !turn0 && game_.player[1].boostUsedRound == 0xFF, "boost already used");
        require(_phi.balanceOf(msg.sender) >= boostPrice, "insufficient funds");

        _phi.safeTransferFrom(msg.sender, address(this), boostPrice);
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))) % 6 + 1;
        game_.player[game_.turn].boostValue = rand;
        game_.player[game_.turn].boostUsedRound = game_.round;
        emit BoostUsed(game_.gameId, msg.sender, game_.round, rand);
    }

    function abort() external {
        uint256 gameId = currentGames[msg.sender];
        require(gameId != 0, "you are not playing a game");
        GameInfo storage game_ = _games[gameId];
        require(game_.started, "game is not running");
        require(block.timestamp - game_.lastAction >= abortTimeout, "timeout has not passed");
        bool turn0 = game_.turn == 0;
        require(turn0 && game_.player[1].addr == msg.sender || !turn0 && game_.player[0].addr == msg.sender, "now is your turn");
        _abort(game_, msg.sender);
    }

    function ownerAbort(uint256 gameId) external onlyOwner {
        GameInfo storage game_ = _games[gameId];
        require(game_.started && !game_.finished, "game is not running");
        _abort(game_, address(0));
    }

    function _abort(GameInfo storage game_, address winner) private {
        game_.finished = true;
        game_.winner = winner;
        if (winner == address(0)) {
            _phi.safeTransfer(game_.player[0].addr, game_.bank / 2);
            _phi.safeTransfer(game_.player[1].addr, game_.bank / 2);
        } else {
            _phi.safeTransfer(winner, game_.bank * (1e6 - fee) / 1e6);
            uint256 prevWins = 0;
            if (_playerWins.contains(winner))
                prevWins = _playerWins.get(winner);
            _playerWins.set(winner, prevWins + 1);
        }

        for (uint8 r=0; r < 3; r++) {
            for (uint8 p=0; p < 2; p++) {
                uint256 tokenId = game_.player[p].placedCards[r];
                if (tokenId != 0) {
                    _resource.safeTransferFrom(address(this), game_.player[p].addr, tokenId, 1, "");
                }
            }
        }

        currentGames[game_.player[0].addr] = 0;
        currentGames[game_.player[1].addr] = 0;

        emit GameAborted(game_.gameId, winner);
    }

    function updateJoinPrice(uint256 newValue) external onlyOwner {
        require(newValue != joinPrice, "no change");
        joinPrice = newValue;
        emit JoinPriceUpdated(newValue);
    }

    function updateMinWeight(uint256 newValue) external onlyOwner {
        require(newValue != minWeight, "no change");
        minWeight = newValue;
        emit MinWeightUpdated(newValue);
    }

    function updateMaxWeight(uint256 newValue) external onlyOwner {
        require(newValue != maxWeight, "no change");
        maxWeight = newValue;
        emit MaxWeightUpdated(newValue);
    }

    function updateAbortTimeout(uint256 newValue) external onlyOwner {
        require(newValue != abortTimeout, "no change");
        abortTimeout = newValue;
        emit AbortTimeoutUpdated(newValue);
    }

    function updateBoostPrice(uint256 newValue) external onlyOwner {
        require(newValue != boostPrice, "no change");
        boostPrice = newValue;
        emit BoostPriceUpdated(newValue);
    }

    function updateEpoch(uint256 newValue) external onlyOwner {
        require(newValue != epoch, "no change");
        epoch = newValue;
        emit EpochUpdated(newValue);
    }

    function withdrawFee(address to) external onlyOwner {
        uint256 balance = _phi.balanceOf(address(this));
        require(balance > 0, "nothing to withdraw");
        _phi.safeTransfer(to, balance);
    }

    function togglePause() external onlyOwner {
        if (paused())
            _unpause();
        else
            _pause();
    }

    function leaderboard() external view returns (LeaderboardItem[] memory) {
        LeaderboardItem[] memory result = new LeaderboardItem[](_playerWins.length());
        for (uint256 i=0; i < _playerWins.length(); i++) {
            (address player, uint256 wins) = _playerWins.at(i);
            result[i] = LeaderboardItem(player, wins);
        }
        return result;
    }

    function leaderboardPaginated(uint256 offset, uint256 count) external view returns (LeaderboardItem[] memory) {
        uint256 totalLength = _playerWins.length();
        uint256 length = count;
        if (offset + length > totalLength)
            length = totalLength - offset;
        LeaderboardItem[] memory result = new LeaderboardItem[](length);
        for (uint256 i=0; i < length; i++) {
            (address player, uint256 wins) = _playerWins.at(offset + i);
            result[i] = LeaderboardItem(player, wins);
        }
        return result;
    }

    function emergencyWithdraw(uint256[] memory tokenId, uint256[] memory amount) external onlyOwner {
        _resource.safeBatchTransferFrom(address(this), msg.sender, tokenId, amount, "");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.5;
pragma abicoder v2;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "OpenZeppelin/[email protected]/contracts/utils/Counters.sol";
import "OpenZeppelin/[email protected]/contracts/utils/structs/EnumerableSet.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155.sol";
import "./ChestSale.sol";

contract Resource is ERC1155, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum Tier {
        None,
        Stone,
        Iron,
        Silver,
        Gold,
        PhiStone
    }

    struct ResourceType {
        string name;
        uint256 weight;
        Tier tier;
        uint256[] ingredients;
        string ipfsHash;
    }

    struct PendingCraft {
        uint256 tokenId;
        uint256 finishTimestamp;
        bool claimed;
    }

    Counters.Counter internal _tokenIds;
    Counters.Counter internal _craftIds;
    IERC20 internal immutable _phi;
    bool internal _initialMintComplete;
    EnumerableSet.AddressSet internal _players;
    uint256 public craftWaitSkipPrice = 10 ether;  // default 10 CRAFT
    bool public reverseCraftActive = false;
    bool public premintFinished = false;

    mapping (uint256 => ResourceType) public resourceTypes;
    mapping (address => EnumerableSet.UintSet) internal _pendingCraftsByUser;
    mapping (uint256 => PendingCraft) internal _pendingCrafts;
    mapping (address => EnumerableSet.UintSet) internal _ownedTokens;
    mapping (uint256 => mapping (uint256 => uint256)) internal _recipes;

    event ResourceTypeRegistered(uint256 indexed tokenId, string name, uint256 weight, string ipfsHash);
    event CraftStarted(address indexed player, uint256 craftId);
    event CraftClaimed(address indexed player, uint256 craftId);
    event CraftWaitSkipped(uint256 craftId);

    event CraftWaitSkipPriceUpdated(uint256 newValue);
    event ReverseCraftStatusUpdated(bool newValue);

    constructor(IERC20 phi) ERC1155("http://dev.bennnnsss.com:39100/_meta/") {
        _phi = phi;
        ResourceType[] memory resources_ = new ResourceType[](4);
        resources_[0] = ResourceType("earth", 1, Tier.None, new uint256[](0), "QmYKGb7p6k23XP7HGd63tJ8c4ftPT8mYQZuLZpLj26eFtc");
        resources_[1] = ResourceType("water", 1, Tier.None, new uint256[](0), "QmT3jQjCzAmPY8Mo4sHYpgN3covtw7o7XbudMDDiCX4Qh9");
        resources_[2] = ResourceType("fire", 1, Tier.None, new uint256[](0), "QmUaRGqSywM4UyvBhLW66ewWDheK2hKfnv4PYotjuCvoAa");
        resources_[3] = ResourceType("air", 1, Tier.None, new uint256[](0), "Qmf2ZAyZXGiB3PRp1nEG1ss9VMrtrnwutaotThU5tMxjj5");
        registerResourceTypes(resources_);
    }

    /// @notice Mint base resource token amounts to the chest contract
    /// @param chest Address to mint tokens to
    function initialMint(ChestSale chest) external onlyOwner {
        require(!_initialMintComplete, "initial mint is performed already");
        _mint(address(chest), 1, 72500, "");
        _mint(address(chest), 2, 72500, "");
        _mint(address(chest), 3, 72500, "");
        _mint(address(chest), 4, 72500, "");
        _initialMintComplete = true;
    }

    /// @notice Register new resource types
    /// @param types Array of resource types data ([name, weight, tier, [ingredient1, ingredient2], ipfsHash]) to register
    function registerResourceTypes(ResourceType[] memory types) public onlyOwner {
        for (uint256 i=0; i < types.length; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            resourceTypes[tokenId] = types[i];
            if (types[i].ingredients.length == 0) {
                // do nothing
            } else if (types[i].ingredients.length == 2) {
                _recipes[types[i].ingredients[0]][types[i].ingredients[1]] = tokenId;
            } else {
                revert("Invalid ingredients count");
            }
            emit ResourceTypeRegistered(tokenId, types[i].name, types[i].weight, types[i].ipfsHash);
        }
    }

    /// @notice Start crafting a token
    /// @param tokenId A token ID to craft
    function craft(uint256 tokenId) external {
        require(resourceTypes[tokenId].ingredients.length > 0, "No recipe for this resource");
        uint256[] memory ingredients = resourceTypes[tokenId].ingredients;
        Tier maxTier = Tier.None;
        for (uint256 i=0; i < ingredients.length; i++) {
            require(balanceOf(msg.sender, ingredients[i]) > 0, "insufficient ingredients");
            _burn(msg.sender, ingredients[i], 1);
            if (resourceTypes[ingredients[i]].tier > maxTier) {
                maxTier = resourceTypes[ingredients[i]].tier;
            }
        }
        uint256 delay = 0;
        uint256 price = 0;
        if (maxTier == Tier.Stone) {
            delay = 30 * 60;            // 30 min
            price = 1 ether;            // 1 CRAFT
        } else if (maxTier == Tier.Iron) {
            delay = 2 * 60 * 60;        // 2 h
            price = 2 ether;            // 2 CRAFT
        } else if (maxTier == Tier.Silver) {
            delay = 12 * 60 * 60;       // 12 h
            price = 3 ether;            // 3 CRAFT
        } else if (maxTier == Tier.Gold) {
            delay = 24 * 60 * 60;       // 1 day
            price = 4 ether;            // 4 CRAFT
        } else if (maxTier == Tier.PhiStone) {
            delay = 7 * 24 * 60 * 60;   // 1 week
            price = 5 ether;            // 5 CRAFT
        }
        if (price > 0) {
            _phi.safeTransferFrom(msg.sender, address(this), price);
        }
        _craftIds.increment();
        uint256 craftId = _craftIds.current();
        _pendingCrafts[craftId] = PendingCraft(tokenId, block.timestamp + delay, false);
        _pendingCraftsByUser[msg.sender].add(craftId);
        emit CraftStarted(msg.sender, craftId);
    }

    /// @notice Start reverse crafting a token
    /// @param tokenId A token ID to reverse craft
    function reverseCraft(uint256 tokenId) external {
        require(reverseCraftActive, "reverse craft is not active");
        require(balanceOf(msg.sender, tokenId) > 0, "you do not own this resource");
        uint256[] memory ingredients = resourceTypes[tokenId].ingredients;
        require(ingredients.length > 0, "you cannot reverse a base resource");
        Tier tier = resourceTypes[tokenId].tier;
        uint256 delay = 0;
        uint256 price = 0;
        if (tier == Tier.Stone) {
            delay = 30 * 60;            // 30 min
            price = 1 ether;            // 1 CRAFT
        } else if (tier == Tier.Iron) {
            delay = 2 * 60 * 60;        // 2 h
            price = 2 ether;            // 2 CRAFT
        } else if (tier == Tier.Silver) {
            delay = 12 * 60 * 60;       // 12 h
            price = 3 ether;            // 3 CRAFT
        } else if (tier == Tier.Gold) {
            delay = 24 * 60 * 60;       // 1 day
            price = 4 ether;            // 4 CRAFT
        } else if (tier == Tier.PhiStone) {
            delay = 7 * 24 * 60 * 60;   // 1 week
            price = 5 ether;            // 5 CRAFT
        }
        _burn(msg.sender, tokenId, 1);
        _phi.safeTransferFrom(msg.sender, address(this), price);
        for (uint256 i=0; i < ingredients.length; i++) {
            _craftIds.increment();
            uint256 craftId = _craftIds.current();
            _pendingCrafts[craftId] = PendingCraft(ingredients[i], block.timestamp + delay, false);
            _pendingCraftsByUser[msg.sender].add(craftId);
            emit CraftStarted(msg.sender, craftId);
        }
    }

    /// @notice Claim result token from craft started using craft(tokenId) method
    /// @param craftId Craft ID to claim result from
    function claimCraft(uint256 craftId) public {
        require(_pendingCraftsByUser[msg.sender].contains(craftId), "this craft is not pending for you");
        PendingCraft storage craft_ = _pendingCrafts[craftId];
        require(craft_.finishTimestamp <= block.timestamp, "this craft is still pending");
        craft_.claimed = true;
        _pendingCraftsByUser[msg.sender].remove(craftId);
        _mint(msg.sender, craft_.tokenId, 1, "");
        emit CraftClaimed(msg.sender, craftId);
    }

    /// @notice Skip craft waiting for `craftWaitSkipPrice` CRAFT
    /// @param craftId A craft ID to skip waiting for
    function skipCraftWait(uint256 craftId) external {
        require(_pendingCraftsByUser[msg.sender].contains(craftId), "this craft is not pending for you");
        PendingCraft storage craft_ = _pendingCrafts[craftId];
        require(craft_.finishTimestamp > block.timestamp, "this craft is not pending");
        _phi.safeTransferFrom(msg.sender, address(this), craftWaitSkipPrice);
        craft_.finishTimestamp = block.timestamp - 1;
        emit CraftWaitSkipped(craftId);
        claimCraft(craftId);
    }

    /// @notice Withdraw PHI fees
    /// @param to Address to withdraw fees to
    function withdrawFees(address to) external onlyOwner {
        _phi.safeTransfer(to, _phi.balanceOf(address(this)));
    }

    /// @notice List token IDs owned by an address
    /// @param player Address to list owned tokens for
    /// @return List of token IDs
    function ownedTokens(address player) external view returns (uint256[] memory) {
        return _ownedTokens[player].values();
    }

    /// @notice List token IDs owned by an address (paginated)
    /// @param player Address to list owned tokens for
    /// @param offset Array offset
    /// @param count Count of items to return
    /// @return List of token IDs
    function ownedTokensPaginated(address player, uint256 offset, uint256 count) external view returns (uint256[] memory) {
        uint256[] memory values = _ownedTokens[player].values();
        uint256[] memory result = new uint256[](count);
        for (uint256 i=0; i < count; i++) {
            result[i] = values[offset + i];
        }
        return result;
    }

    /// @notice Get resource types info by IDs
    /// @param ids Array of resource types IDs to return info for
    /// @return Resource type array
    function getResourceTypes(uint256[] memory ids) external view returns (ResourceType[] memory) {
        ResourceType[] memory result = new ResourceType[](ids.length);
        for (uint256 i=0; i<ids.length; i++) {
            result[i] = resourceTypes[ids[i]];
        }
        return result;
    }

    /// @notice Get resource type weight by IDs
    /// @param id Resource type ID to return weight for
    /// @return Resource type weight
    function getResourceWeight(uint256 id) external view returns (uint256) {
        return resourceTypes[id].weight;
    }

    /// @notice Get result of crafting with two ingredients
    /// @param tokenId1 Ingredient 1
    /// @param tokenId2 Ingredient 2
    /// @return Result token ID, 0 if no matching recipe
    function getCraftingResult(uint256 tokenId1, uint256 tokenId2) external view returns (uint256) {
        uint256 result = _recipes[tokenId1][tokenId2];
        if (result == 0)
            result = _recipes[tokenId2][tokenId1];
        return result;
    }

    /// @notice Get pending crafts for a player
    /// @param player Player address
    /// @return Array of craft IDs
    function pendingCrafts(address player) external view returns (uint256[] memory) {
        return _pendingCraftsByUser[player].values();
    }

    /// @notice Get pending crafts by IDs
    /// @param ids Craft IDs to return
    /// @return Crafts info
    function getCrafts(uint256[] memory ids) external view returns (PendingCraft[] memory) {
        PendingCraft[] memory result = new PendingCraft[](ids.length);
        for (uint256 i=0; i<ids.length; i++) {
            result[i] = _pendingCrafts[ids[i]];
        }
        return result;
    }

    /// @notice Get all players addresses (all addresses that sent or received tokens)
    /// @return Array of players addresses
    function getPlayers() external view returns (address[] memory) {
        return _players.values();
    }

    /// @notice Get all players addresses (all addresses that sent or received tokens) (paginated)
    /// @param offset Array offset
    /// @param count Count of items to return
    /// @return Array of players addresses
    function getPlayersPaginated(uint256 offset, uint256 count) external view returns (address[] memory) {
        address[] memory values = _players.values();
        address[] memory result = new address[](count);
        for (uint256 i=0; i < count; i++) {
            result[i] = values[offset + i];
        }
        return result;
    }

    /// @notice Get resource types count
    /// @return Resource types count
    function resourceCount() external view returns (uint256) {
        return _tokenIds.current();
    }

    function setCraftSkipWaitPrice(uint256 newValue) external onlyOwner {
        require(craftWaitSkipPrice != newValue, "no change");
        craftWaitSkipPrice = newValue;
        emit CraftWaitSkipPriceUpdated(newValue);
    }

    function setReverseCraftActive(bool newValue) external onlyOwner {
        require(newValue != reverseCraftActive, "no change");
        reverseCraftActive = newValue;
        emit ReverseCraftStatusUpdated(newValue);
    }

    function updateResource(uint256 tokenId, string calldata name, uint256 weight, string calldata ipfsHash) external onlyOwner {
        ResourceType storage rt = resourceTypes[tokenId];
        rt.name = name;
        rt.weight = weight;
        rt.ipfsHash = ipfsHash;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i=0; i<ids.length; i++) {
            if (from != address(0) && balanceOf(from, ids[i]) <= amounts[i])
                _ownedTokens[from].remove(ids[i]);
            if (to != address(0) && balanceOf(to, ids[i]) == 0)
                _ownedTokens[to].add(ids[i]);
        }
        _players.add(from);
        _players.add(to);
    }

    function premint(address[] calldata to, uint256[][] calldata tokenId, uint256[][] calldata amount) external onlyOwner {
        require(!premintFinished, "premint is finished");
        require(to.length == amount.length && tokenId.length == amount.length, "invalid args");
        for (uint256 i=0; i < to.length; i++) {
            _mintBatch(to[i], tokenId[i], amount[i], "");
        }
    }

    function finishPremint() external onlyOwner {
        require(!premintFinished, "premint is finished");
        premintFinished = true;
    }
}