// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/ICandyShop.sol";

contract CandyShop is ERC1155Pausable, Ownable, ReentrancyGuard, ICandyShop {
    struct SKU {
        uint256 id;
        uint256 price;
        string name;
    }

    struct SKUInput {
        uint256 price;
        string name;
    }

    mapping(uint256 => SKU) public inventory;
    mapping(string => uint256) public skuIds;
    bytes32[] names;
    address public chainDreamersAddress;

    function addSku(SKUInput[] memory _skus) external onlyOwner {
        for (uint256 i = 0; i < _skus.length; i++) {
            if (names.length > 0) {
                require(
                    names[skuIds[_skus[i].name]] !=
                        keccak256(bytes(_skus[i].name)),
                    "Sku already exists"
                );
            }
            uint256 tokenId = names.length;
            skuIds[_skus[i].name] = tokenId;
            names.push(keccak256(bytes(_skus[i].name)));
            inventory[tokenId] = SKU(tokenId, _skus[i].price, _skus[i].name);
        }
    }

    function setChainDreamersAddress(address _chainDreamersAddress)
        external
        onlyOwner
    {
        chainDreamersAddress = _chainDreamersAddress;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'data:application/json,{"name": "',
                    inventory[_tokenId].name,
                    '"}'
                )
            );
    }

    function mint(uint256 tokenId, uint256 amount)
        external
        payable
        nonReentrant
    {
        require(tokenId < names.length, "This candy does not exist yet");
        require(
            msg.value == inventory[tokenId].price * amount,
            "You have to pay the price to eat candies"
        );
        _mint(_msgSender(), tokenId, amount, "");
        setApprovalForAll(chainDreamersAddress, true);
    }

    function mintBatch(uint256[] calldata tokenIds, uint256[] calldata amounts)
        external
        payable
        nonReentrant
    {
        uint256 price;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] < names.length,
                "This candy does not exist yet"
            );
            price += inventory[tokenIds[i]].price * amounts[i];
        }

        require(msg.value == price, "You have to pay the price to eat candies");

        _mintBatch(_msgSender(), tokenIds, amounts, "");
        setApprovalForAll(chainDreamersAddress, true);
    }

    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _burn(from, tokenId, amount);
    }

    function burnBatch(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _burnBatch(from, tokenIds, amounts);
    }

    constructor(string memory uri_) ERC1155(uri_) {}

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICandyShop {
    function burnBatch(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../tokens/ERC721Enumerable.sol";
import "../interfaces/IDreamersRenderer.sol";
import "../interfaces/ICandyShop.sol";
import "../interfaces/IChainRunners.sol";

contract ChainDreamers is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Linked contracts
    address public renderingContractAddress;
    address public candyShopAddress;
    address public chainRunnersAddress;
    IDreamersRenderer renderer;
    ICandyShop candyShop;
    IChainRunners chainRunners;

    // Constants
    uint256 public constant MAX_DREAMERS_MINT_PUBLIC_SALE = 5;
    uint256 public constant MINT_PUBLIC_PRICE = 0.05 ether;

    // State variables
    uint256 public publicSaleStartTimestamp;

    function setPublicSaleTimestamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimestamp = timestamp;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return
            block.timestamp >= publicSaleStartTimestamp &&
            publicSaleStartTimestamp != 0;
    }

    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not open");
        _;
    }

    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyOwner
    {
        renderingContractAddress = _renderingContractAddress;
        renderer = IDreamersRenderer(renderingContractAddress);
    }

    function setCandyShopAddress(address _candyShopContractAddress)
        public
        onlyOwner
    {
        candyShopAddress = _candyShopContractAddress;
        candyShop = ICandyShop(candyShopAddress);
    }

    function setChainRunnersContractAddress(
        address _chainRunnersContractAddress
    ) public onlyOwner {
        chainRunnersAddress = _chainRunnersContractAddress;
        chainRunners = IChainRunners(_chainRunnersContractAddress);
    }

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /*
    @param tokenId a bytes interpreted as an array of uint16
    @param ownerTokenIndexes a bytes interpreted as an array of uint16. Given here to avoid indexes computation and save gas
    @param candyIdsBytes a bytes interpreted as an array of uint8
    @param candyIds the same indexes as above but as a uint8 array
    @param candyIdsCount should be an array of 1
    */
    function mintBatchRunnersAccess(
        bytes calldata tokenIds,
        bytes calldata ownerTokenIndexes,
        bytes calldata candyIdsBytes,
        uint256[] calldata candyIds,
        uint256[] calldata candyAmounts
    ) public nonReentrant returns (bool) {
        require(
            candyIdsBytes.length == candyIds.length,
            "Candy ids should have the same length"
        );
        require(
            tokenIds.length == candyIdsBytes.length * 2,
            "Each runner needs its own candy"
        );

        for (uint256 i = 0; i < tokenIds.length; i += 2) {
            require(
                chainRunners.ownerOf(BytesLib.toUint16(tokenIds, i)) ==
                    _msgSender(),
                "You cannot give candies to a runner that you do not own"
            );
            require(
                uint8(candyIds[i / 2]) == uint8(candyIdsBytes[i / 2]),
                "Candy ids should be the same"
            );
            require(
                candyAmounts[i / 2] == 1,
                "Your runner needs one and only one candy, who knows what could happen otherwise"
            );
        }
        _safeMintBatchWithCandies(
            _msgSender(),
            tokenIds,
            ownerTokenIndexes,
            candyIdsBytes
        );
        candyShop.burnBatch(_msgSender(), candyIds, candyAmounts);
        return true;
    }

    function mintBatchPublicSale(
        bytes calldata tokenIds,
        bytes calldata ownerTokenIndexes
    ) public payable nonReentrant whenPublicSaleActive returns (bool) {
        require(
            (tokenIds.length / 2) * MINT_PUBLIC_PRICE == msg.value,
            "You have to pay the bail bond"
        );
        require(
            ERC721.balanceOf(_msgSender()) + tokenIds.length / 2 <=
                MAX_DREAMERS_MINT_PUBLIC_SALE,
            "Your home is to small to welcome so many dreamers"
        );
        _safeMintBatch(_msgSender(), tokenIds, ownerTokenIndexes);
        return true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(uint16(_tokenId)),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (renderingContractAddress == address(0)) {
            return "";
        }

        return renderer.tokenURI(_tokenId, dreamers[_tokenId].dna);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

/**
 * @dev This implementation leverages the fact that there is 10k runners and so at most 10k dreamers as well.
 *      We then used bytes to stores tokens and indexes and uses uint16 (bytes2) everywhere.
 *      Using bytes.concat to batch mint will save heaps of gas.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => bytes) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    bytes private _ownedTokensIndex;

    // Array with all token ids, used for enumeration, two bytes per tokenId (uint16)
    bytes private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint16 => uint16) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return BytesLib.toUint16(_ownedTokens[owner], index * 2);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length / 2;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return BytesLib.toUint16(_allTokens, index * 2);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint16 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            // Token is minted, add it to the global list
            uint16 tokenIndex = uint16(_allTokens.length);
            _allTokensIndex[tokenId] = tokenIndex;
            _allTokens = bytes.concat(_allTokens, bytes2(tokenId));

            // Add it to the minter list as well
            bytes2 length = bytes2(uint16(_ownedTokens[to].length));
            _ownedTokensIndex = bytes.concat(_ownedTokensIndex, length);
            _ownedTokens[to] = bytes.concat(_ownedTokens[to], bytes2(tokenId));
        } else if (to == address(0)) {
            // Token is burnt, remove it from the global list
            uint16 tokenIndex = _allTokensIndex[tokenId];

            _allTokens = bytes.concat(
                BytesLib.slice(_allTokens, 0, tokenIndex),
                BytesLib.slice(
                    _allTokens,
                    tokenIndex + 2,
                    _allTokens.length - tokenIndex - 2
                )
            );

            uint16 tokenIndexForOwner = BytesLib.toUint16(
                _ownedTokensIndex,
                tokenIndex
            );

            _ownedTokens[from] = bytes.concat(
                BytesLib.slice(_ownedTokens[from], 0, tokenIndexForOwner),
                BytesLib.slice(
                    _ownedTokens[from],
                    tokenIndexForOwner + 2,
                    _ownedTokens[from].length - tokenIndexForOwner - 2
                )
            );
        } else if (from != to) {
            // Get indexes in global bytes and in owner's bytes
            uint16 tokenIndex = _allTokensIndex[tokenId];
            uint16 tokenIndexForOwner = BytesLib.toUint16(
                _ownedTokensIndex,
                tokenIndex
            );

            // Remove from "from" bytes and add to "to" one's
            _ownedTokens[from] = bytes.concat(
                BytesLib.slice(_ownedTokens[from], 0, tokenIndexForOwner),
                BytesLib.slice(
                    _ownedTokens[from],
                    tokenIndexForOwner + 2,
                    _ownedTokens[from].length - tokenIndexForOwner - 2
                )
            );
            bytes2 length = bytes2(uint16(_ownedTokens[to].length));
            _ownedTokens[to] = bytes.concat(_ownedTokens[to], bytes2(tokenId));

            // Update owner's index
            _ownedTokensIndex[tokenIndex] = length[0];
            _ownedTokensIndex[tokenIndex + 1] = length[1];
        }
    }

    function _beforeBatchMint(
        address to,
        bytes calldata tokenIds,
        bytes calldata ownerTokenIndexes
    ) internal virtual override {
        uint16 firstIndex = BytesLib.toUint16(ownerTokenIndexes, 0);
        require(
            tokenIds.length == ownerTokenIndexes.length,
            "ownerIndexes must have the same length as tokenIds"
        );
        require(
            _ownedTokens[to].length == firstIndex * 2,
            "The given ownerTokenIndexes do not start from the current owner count"
        );

        // Add them to the minter list
        _ownedTokensIndex = bytes.concat(_ownedTokensIndex, ownerTokenIndexes);
        _ownedTokens[to] = bytes.concat(_ownedTokens[to], tokenIds);

        // Add tokens to the global list
        uint16 tokenIndex = uint16(_allTokens.length);
        for (uint16 i = 0; i < tokenIds.length; i += 2) {
            require(
                BytesLib.toUint16(ownerTokenIndexes, i) == firstIndex + i / 2,
                "ownerTokenIndexes must be a sequence"
            );
            uint16 tokenId = BytesLib.toUint16(tokenIds, i);
            _allTokensIndex[tokenId] = tokenIndex + i;
        }
        _allTokens = bytes.concat(_allTokens, tokenIds);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDreamersRenderer {
    function tokenURI(uint256 tokenId, uint8 dreamerDna)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IChainRunners {
    function getDna(uint256 _tokenId) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

// This file is copied from OpenZeppelin with the addition of a _safeMintBatch function tailored for the Dreamers
// mechanism.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint16;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint16 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint16) private _balances;

    // Mapping from token ID to approved address
    mapping(uint16 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from tokenId to Dreamer
    struct ChainDreamer {
        uint8 dna;
    }
    mapping(uint256 => ChainDreamer) public dreamers;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return uint256(_balances[owner]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[uint16(tokenId)];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, uint16(tokenId));
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(uint16(tokenId)),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[uint16(tokenId)];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), uint16(tokenId)),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, uint16(tokenId));
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, uint16(tokenId), "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), uint16(tokenId)),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, uint16(tokenId), _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint16 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint16 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint16 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint16 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint16 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _safeMintBatchWithCandies(
        address to,
        bytes calldata tokenIds,
        bytes calldata ownerTokenIndexes,
        bytes calldata candyIds
    ) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(
            tokenIds.length < 512,
            "You can mint by batches up to 256 tokens at a time"
        );
        bytes32 dnas = keccak256(
            abi.encodePacked(
                candyIds,
                tokenIds,
                msg.sender,
                msg.value,
                block.timestamp,
                block.difficulty
            )
        );

        _beforeBatchMint(to, tokenIds, ownerTokenIndexes);

        for (uint256 i = 0; i < tokenIds.length / 2; i++) {
            uint16 tokenId = BytesLib.toUint16(tokenIds, i * 2);
            require(!_exists(tokenId), "ERC721: token already minted");
            _owners[tokenId] = to;
            dreamers[tokenId] = ChainDreamer(
                ((uint8(dnas[0]) >> 2) << 2) + (uint8(candyIds[i]) % 4)
            );
            dnas >>= 1;
            emit Transfer(address(0), to, tokenId);
        }
        _balances[to] += uint16(tokenIds.length);

        require(
            _checkOnERC721Received(
                address(0),
                to,
                BytesLib.toUint16(tokenIds, 0),
                ""
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _safeMintBatch(
        address to,
        bytes calldata tokenIds,
        bytes calldata ownerTokenIndexes
    ) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(
            tokenIds.length < 256,
            "You can mint by batches up to 256 tokens at a time"
        );
        bytes32 dnas = keccak256(
            abi.encodePacked(
                tokenIds,
                ownerTokenIndexes,
                msg.sender,
                msg.value,
                block.timestamp,
                block.difficulty
            )
        );

        _beforeBatchMint(to, tokenIds, ownerTokenIndexes);

        for (uint256 i = 0; i < tokenIds.length / 2; i++) {
            uint16 tokenId = BytesLib.toUint16(tokenIds, i * 2);
            require(!_exists(tokenId), "ERC721: token already minted");
            _owners[tokenId] = to;
            dreamers[tokenId] = ChainDreamer(
                ((uint8(dnas[0]) >> 2) << 2) + (uint8(dnas[0]) % 4)
            );
            dnas >>= 1;
            emit Transfer(address(0), to, tokenId);
        }
        _balances[to] += uint16(tokenIds.length);

        require(
            _checkOnERC721Received(
                address(0),
                to,
                BytesLib.toUint16(tokenIds, 0),
                ""
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint16 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint16 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint16 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint16 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint16 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint16 tokenId
    ) internal virtual {}

    function _beforeBatchMint(
        address to,
        bytes calldata tokenIds,
        bytes calldata ownerTokenIndexes
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import {Integers} from "../lib/Integers.sol";
import "./ChainRunnersConstants.sol";

import "../interfaces/IChainRunners.sol";
import "../interfaces/IDreamersRenderer.sol";

/*  @title Dreamers Renderer
    @author Clement Walter
    @dev Leverage the d attributes of svg <path> to encode a palette of base traits. Each runner trait
         is encoded as a combination of these base traits. More precisely, the Dreamers encoding scheme works as follows:
         - each one of the 330 traits is encoded as a list of <path />
         - each path combines a `d` and a `fill`
         - the storage contains the all the possible `d` and all the possible `fill`
         - each trait is then an ordered list of tuples (index of d, index of fill)
         - each dreamer is a list a trait and consequently still an ordered list of (index of d, index of fill)
*/
contract DreamersRenderer is
    IDreamersRenderer,
    Ownable,
    ReentrancyGuard,
    ChainRunnersConstants
{
    using Integers for uint8;
    using Strings for uint256;

    // We have a total of 3 bytes = 24 bits per Path
    uint8 public constant BITS_PER_D_INDEX = 12;
    uint8 public constant BITS_PER_FILL_INDEX = 12;

    // Each D is encoded with a sequence of 2 bits for each letter (M, L, Q, C) and 1 byte per attribute. Since each
    // letter does not have the same number of attributes, this number if stored as constant below as well.
    uint8 public constant BITS_PER_D_ATTRIBUTE = 3;
    bytes8 public constant D_ATTRIBUTE_PALETTE = hex"4d4c51434148565a"; // M L Q C A H V Z
    bytes8 public constant D_ATTRIBUTE_PARAMETERS_COUNT = hex"0202040607010100"; // 2 2 4 6 7 1 1 0
    bytes3 public constant NONE_COLOR = hex"000001";
    bytes public constant PATH_TAG_START = bytes("%3cpath%20d='");
    bytes public constant FILL_TAG = bytes("'%20fill='");
    bytes public constant STROKE_TAG = bytes("'%20stroke='%23000");
    bytes public constant PATH_TAG_END = bytes("'/%3e");
    bytes public constant HASHTAG = bytes("%23");
    bytes public constant SVG_TAG_START =
        bytes(
            "%3csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20255%20255'%20width='500px'%20height='500px'%3e"
        );
    bytes public constant SVG_TAG_END =
        bytes("%3cstyle%3epath{stroke-width:0.71}%3c/style%3e%3c/svg%3e");

    struct Trait {
        uint16 dIndex;
        uint16 fillIndex;
        bool stroke;
    }

    address public fillPalette;
    address[] public dPalette;
    address public dPaletteIndexes;
    address public traitPalette;
    address public traitPaletteIndexes;
    bytes layerIndexes;
    IChainRunners runnersToken;

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////  Rendering mechanics  /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Colors are concatenated and stored in a single 'bytes' with SSTORE2 to save gas.
    function setFillPalette(bytes calldata _fillPalette) external onlyOwner {
        fillPalette = SSTORE2.write(_fillPalette);
    }

    /// @dev Only the d parameter is encoded for each path. All the paths are concatenated together to save gas.
    ///      The dPaletteIndexes is used to retrieve the path from the dPalette.
    function setDPalette(bytes[] calldata _pathPalette) external onlyOwner {
        for (uint8 i = 0; i < _pathPalette.length; i++) {
            dPalette.push(SSTORE2.write(_pathPalette[i]));
        }
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    function setDPaletteIndex(bytes calldata _pathPaletteIndex)
        external
        onlyOwner
    {
        dPaletteIndexes = SSTORE2.write(_pathPaletteIndex);
    }

    /// @dev The traits are stored as a list of tuples (d index, fill index). For our case, 12 bits per index is
    ///      enough as 2^12 = 4096 is greater than total number of d and total number of fill to date.
    ///      This could be changed if needed.
    ///      Hence a trait is a sequence of several 3 bytes long (d index, fill index).
    function setTraitPalette(bytes calldata _traitPalette) external onlyOwner {
        traitPalette = SSTORE2.write(_traitPalette);
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    ///      A trait can then be retrieved with traitPalette[traitPaletteIndexes[i]: traitPaletteIndexes[i+1]]
    function setTraitPaletteIndex(bytes calldata _traitPaletteIndex)
        external
        onlyOwner
    {
        traitPaletteIndexes = SSTORE2.write(_traitPaletteIndex);
    }

    /// @dev The trait indexes allow to map from the Chain Runners 2D indexation (trait index, layer index) to the
    ///      current 1D indexation (trait index).
    function setLayerIndexes(bytes calldata _layerIndexes) external onlyOwner {
        layerIndexes = _layerIndexes;
    }

    /// @dev This function will be the pendant of the ChainRunnersBaseRenderer.getLayer ones.
    function getTraitIndex(uint16 _layerIndex, uint16 _itemIndex)
        public
        view
        returns (uint16)
    {
        uint16 traitIndex = BytesLib.toUint16(layerIndexes, _layerIndex * 2);
        uint16 nextTraitIndex = BytesLib.toUint16(
            layerIndexes,
            (_layerIndex + 1) * 2
        );
        if (traitIndex + _itemIndex >= nextTraitIndex) {
            return type(uint16).max;
        }

        return traitIndex + _itemIndex;
    }

    /// @dev 3 bytes per color because svg does not handle alpha.
    function getFill(uint16 _index) public view returns (string memory) {
        // TODO: use assembly instead
        bytes memory palette = SSTORE2.read(fillPalette);
        if (
            palette[(_index * 3)] == NONE_COLOR[0] &&
            palette[(_index * 3) + 1] == NONE_COLOR[1] &&
            palette[(_index * 3) + 2] == NONE_COLOR[2]
        ) {
            return "none";
        }

        return
            string(
                bytes.concat(
                    HASHTAG,
                    bytes(uint8(palette[3 * _index]).toString(16, 2)),
                    bytes(uint8(palette[3 * _index + 1]).toString(16, 2)),
                    bytes(uint8(palette[3 * _index + 2]).toString(16, 2))
                )
            );
    }

    /// @dev Get the start and end indexes of the bytes concerning the given d in the dPalette storage.
    function getDIndex(uint16 _index) public view returns (uint32, uint32) {
        // TODO: use assembly instead
        bytes memory _indexes = SSTORE2.read(dPaletteIndexes);
        uint32 start = uint32(BytesLib.toUint16(_indexes, _index * 2));
        uint32 next = uint32(BytesLib.toUint16(_indexes, _index * 2 + 2));
        // Magic reasonable number to deal with overflow
        if (uint32(_index) > 1000 && start < 20000) {
            start = uint32(type(uint16).max) + 1 + start;
        }
        if (uint32(_index) > 2000 && start < 40000) {
            start = uint32(type(uint16).max) + 1 + start;
        }
        if (uint32(_index) > 1000 && next < 20000) {
            next = uint32(type(uint16).max) + 1 + next;
        }
        if (uint32(_index) > 2000 && next < 40000) {
            next = uint32(type(uint16).max) + 1 + next;
        }
        return (start, next);
    }

    /// @dev Retrieve the bytes for the given d from the dPalette storage. The bytes may be split into several SSTORE2
    ///      slots.
    function getDBytes(uint16 _index) public view returns (bytes memory) {
        // TODO: use assembly instead
        (uint32 dIndex, uint32 dIndexNext) = getDIndex(_index);
        uint256 storageIndex = 0;
        bytes memory _dPalette = SSTORE2.read(dPalette[storageIndex]);
        uint256 cumSumBytes = _dPalette.length;
        uint256 pos = dIndex;
        while (dIndex >= cumSumBytes) {
            pos -= _dPalette.length;
            storageIndex++;
            _dPalette = SSTORE2.read(dPalette[storageIndex]);
            cumSumBytes += _dPalette.length;
        }
        bytes memory _d = new bytes(dIndexNext - dIndex);
        for (uint256 i = 0; i < _d.length; i++) {
            if (pos >= _dPalette.length) {
                storageIndex++;
                _dPalette = SSTORE2.read(dPalette[storageIndex]);
                pos = 0;
            }
            _d[i] = _dPalette[pos];
            pos++;
        }
        return _d;
    }

    /// @dev Decodes the path and returns it as a plain string to be used in the svg path attribute.
    function getD(bytes memory dEncodedBytes)
        public
        pure
        returns (string memory)
    {
        bytes memory d;
        bytes memory bytesBuffer;
        uint32 bitsShift = 0;
        uint16 byteIndex = 0;
        uint8 bitShiftRemainder = 0;
        uint8 dAttributeIndex;
        uint8 dAttributeParameterCount;
        while (
            bitsShift <= dEncodedBytes.length * 8 - (BITS_PER_D_ATTRIBUTE + 8) // at least BITS_PER_D_ATTRIBUTE bits for the d attribute index and 1 byte for the d attribute parameter count
        ) {
            byteIndex = uint16(bitsShift / 8);
            bitShiftRemainder = uint8(bitsShift % 8);

            dAttributeIndex =
                uint8(
                    (dEncodedBytes[byteIndex] << bitShiftRemainder) |
                        (dEncodedBytes[byteIndex + 1] >>
                            (8 - bitShiftRemainder))
                ) >>
                (8 - BITS_PER_D_ATTRIBUTE);

            dAttributeParameterCount = uint8(
                D_ATTRIBUTE_PARAMETERS_COUNT[dAttributeIndex]
            );
            d = bytes.concat(d, D_ATTRIBUTE_PALETTE[dAttributeIndex]);

            bitsShift += BITS_PER_D_ATTRIBUTE;
            byteIndex = uint16(bitsShift / 8);
            bitShiftRemainder = uint8(bitsShift % 8);
            bytesBuffer = new bytes(dAttributeParameterCount);
            // TODO: use assembly instead
            for (uint8 i = 0; i < dAttributeParameterCount; i++) {
                bytesBuffer[i] =
                    dEncodedBytes[byteIndex + i] <<
                    bitShiftRemainder;
                if (byteIndex + i + 1 < dEncodedBytes.length) {
                    bytesBuffer[i] |=
                        dEncodedBytes[byteIndex + i + 1] >>
                        (8 - bitShiftRemainder);
                }
            }

            for (uint8 i = 0; i < dAttributeParameterCount; i++) {
                d = bytes.concat(
                    d,
                    hex"2c", // comma
                    bytes(uint8(bytesBuffer[i]).toString())
                );
            }
            bitsShift += 8 * dAttributeParameterCount;
        }
        return string(d);
    }

    /// @dev Used to concat all the traits of a given dreamers given the array of trait indexes.
    function getTraits(uint16[NUM_LAYERS] memory _index)
        public
        view
        returns (Trait[] memory)
    {
        // First: retrieve all bytes indexes
        bytes memory _traitPaletteIndexes = SSTORE2.read(traitPaletteIndexes);
        bytes memory _traitPalette = SSTORE2.read(traitPalette);

        bytes memory traitsBytes;
        uint16 start;
        uint16 next;
        for (uint16 i = 0; i < NUM_LAYERS; i++) {
            if (_index[i] == type(uint16).max) {
                continue;
            }
            start = BytesLib.toUint16(_traitPaletteIndexes, _index[i] * 2);
            next = BytesLib.toUint16(_traitPaletteIndexes, _index[i] * 2 + 2);
            traitsBytes = bytes.concat(
                traitsBytes,
                BytesLib.slice(_traitPalette, start, next - start)
            );
        }

        // Second: retrieve all traits
        bool stroke;
        Trait[] memory traits = new Trait[](traitsBytes.length / 3);
        for (uint256 i = 0; i < traitsBytes.length; i += 3) {
            (uint16 dIndex, uint16 fillIndex) = Integers.load12x2(
                traitsBytes[i],
                traitsBytes[i + 1],
                traitsBytes[i + 2]
            );
            stroke = fillIndex % 2 > 0;
            fillIndex = fillIndex >> 1;
            traits[i / 3] = Trait(dIndex, fillIndex, stroke);
        }
        return traits;
    }

    /// @notice Useful for returning a single Traits in the Runner's meaning
    function getTrait(uint16 _index) public view returns (Trait[] memory) {
        uint16[NUM_LAYERS] memory _indexes;
        _indexes[0] = _index;
        for (uint256 i = 1; i < NUM_LAYERS; i++) {
            _indexes[i] = type(uint16).max;
        }
        return getTraits(_indexes);
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////  Dreamers  ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    /// @dev Each trait is the bytes representation of the final svg string concatenating several <path> elements.
    function getSvg(Trait[] memory traits) public view returns (string memory) {
        bytes memory svg = SVG_TAG_START;
        for (uint16 i = 0; i < traits.length; i++) {
            svg = bytes.concat(
                svg,
                PATH_TAG_START,
                bytes(getD(getDBytes(traits[i].dIndex))),
                FILL_TAG,
                bytes(getFill(traits[i].fillIndex))
            );
            if (traits[i].stroke) {
                svg = bytes.concat(svg, STROKE_TAG);
            }
            svg = bytes.concat(svg, PATH_TAG_END);
        }
        return string(bytes.concat(svg, SVG_TAG_END));
    }

    constructor(address _rendererAddress, address _runnersTokenAddress)
        ChainRunnersConstants(_rendererAddress)
    {
        runnersToken = IChainRunners(_runnersTokenAddress);
    }

    /// @dev Somehow copied from the original code but returns an array of trait indexes instead of Layer structs.
    ///      Flags for no layer is also updated from empty `Layer` to index = type(uint16).max.
    function getTokenData(uint16[NUM_LAYERS] memory dna)
        public
        view
        returns (uint16[NUM_LAYERS] memory traitIndexes)
    {
        uint16 raceIndex = chainRunnersBaseRenderer.getRaceIndex(dna[1]);
        bool hasFaceAcc = dna[7] < (NUM_RUNNERS - WEIGHTS[raceIndex][7][7]);
        bool hasMask = dna[8] < (NUM_RUNNERS - WEIGHTS[raceIndex][8][7]);
        bool hasHeadBelow = dna[9] < (NUM_RUNNERS - WEIGHTS[raceIndex][9][36]);
        bool hasHeadAbove = dna[11] <
            (NUM_RUNNERS - WEIGHTS[raceIndex][11][48]);
        bool useHeadAbove = (dna[0] % 2) > 0;
        for (uint8 i = 0; i < NUM_LAYERS; i++) {
            uint8 layerTraitIndex = chainRunnersBaseRenderer.getLayerIndex(
                dna[i],
                i,
                raceIndex
            );
            uint16 traitIndex = getTraitIndex(i, layerTraitIndex);
            /*
            These conditions help make sure layer selection meshes well visually.
            1. If mask, no face/eye acc/mouth acc
            2. If face acc, no mask/mouth acc/face
            3. If both head above & head below, randomly choose one
            */
            bool consistencyCheck = (((i == 2 || i == 12) &&
                !hasMask &&
                !hasFaceAcc) ||
                (i == 7 && !hasMask) ||
                (i == 10 && !hasMask) ||
                (i < 2 || (i > 2 && i < 7) || i == 8 || i == 9 || i == 11));
            bool noHeadCheck = ((hasHeadBelow &&
                hasHeadAbove &&
                (i == 9 && useHeadAbove)) || (i == 11 && !useHeadAbove));
            bool isRealTrait = traitIndex < type(uint16).max;
            if (!isRealTrait || !consistencyCheck || noHeadCheck) {
                traitIndex = type(uint16).max;
            }
            traitIndexes[i] = traitIndex;
        }
        return traitIndexes;
    }

    /// @dev The Dreamer's full DNA is an alteration of its corresponding Runner's DNA with it's consumed candy.
    ///      The candy ids are hardcoded while it should be better to retrieve their effects from the CandyShop
    ///      contract.
    function getDreamerFullDna(uint256 runnerDna, uint8 dreamerDna)
        public
        view
        returns (uint16[NUM_LAYERS] memory)
    {
        uint16[NUM_LAYERS] memory dna = splitNumber(runnerDna);
        return dna;
    }

    function tokenURI(uint256 tokenId, uint8 dreamerDna)
        external
        view
        override
        returns (string memory)
    {
        uint256 runnerDna = runnersToken.getDna(tokenId);
        uint16[NUM_LAYERS] memory dna = getDreamerFullDna(
            runnerDna,
            dreamerDna
        );
        uint16[NUM_LAYERS] memory traitIndexes = getTokenData(dna);
        Trait[] memory traits = getTraits(traitIndexes);
        string memory svg = getSvg(traits);
        return
            string(
                abi.encodePacked(
                    'data:application/json,{"image_data":',
                    svg,
                    '", "name", "Dreamer #',
                    tokenId.toString(),
                    '"}'
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < count; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
    }

    /**
     * Load 16
     *
     * Converts two bytes to a 16 bit unsigned integer
     *
     * @param _leadingBytes the first byte of the unsigned integer in [256, 65536]
     * @param _endingBytes the second byte of the unsigned integer in [0, 255]
     * @return uint16 The resulting integer value
     */
    function load16(bytes1 _leadingBytes, bytes1 _endingBytes)
        public
        pure
        returns (uint16)
    {
        return
            (uint16(uint8(_leadingBytes)) << 8) + uint16(uint8(_endingBytes));
    }

    /**
     * Load 12
     *
     * Converts three bytes into two uint12 integers
     *
     * @return (uint16, uint16) The two uint16 values up to 2^12 each
     */
    function load12x2(
        bytes1 first,
        bytes1 second,
        bytes1 third
    ) public pure returns (uint16, uint16) {
        return (
            (uint16(uint8(first)) << 4) + (uint16(uint8(second)) >> 4),
            (uint16(uint8(second & hex"0f")) << 8) + uint16(uint8(third))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IChainRunnersBaseRenderer.sol";

/*  @title Chain Runners constants
    @author Clement Walter
    @notice This contracts is used to retrieve constants used by the Chain Runners that are not exposed
            by the Chain Runners contracts.
*/
contract ChainRunnersConstants {
    uint16[][13][3] public WEIGHTS;
    uint8 public constant NUM_LAYERS = 13;
    uint16 public constant NUM_RUNNERS = 10_000;
    IChainRunnersBaseRenderer chainRunnersBaseRenderer;

    constructor(address _rendererAddress) {
        chainRunnersBaseRenderer = IChainRunnersBaseRenderer(_rendererAddress);

        WEIGHTS[0][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[0][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[0][2] = [
            303,
            303,
            303,
            303,
            151,
            30,
            0,
            0,
            151,
            151,
            151,
            151,
            30,
            303,
            151,
            30,
            303,
            303,
            303,
            303,
            303,
            303,
            30,
            151,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            3066
        ];
        WEIGHTS[0][3] = [
            645,
            0,
            1290,
            322,
            645,
            645,
            645,
            967,
            322,
            967,
            645,
            967,
            967,
            973
        ];
        WEIGHTS[0][4] = [
            0,
            0,
            0,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250
        ];
        WEIGHTS[0][5] = [
            121,
            121,
            121,
            121,
            121,
            121,
            243,
            0,
            0,
            0,
            0,
            121,
            121,
            243,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            243,
            0,
            0,
            0,
            121,
            121,
            243,
            121,
            121,
            306
        ];
        WEIGHTS[0][6] = [
            925,
            555,
            185,
            555,
            925,
            925,
            185,
            1296,
            1296,
            1296,
            1857
        ];
        WEIGHTS[0][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[0][8] = [189, 189, 47, 18, 9, 28, 37, 9483];
        WEIGHTS[0][9] = [
            340,
            340,
            340,
            340,
            340,
            340,
            34,
            340,
            340,
            340,
            340,
            170,
            170,
            170,
            102,
            238,
            238,
            238,
            272,
            340,
            340,
            340,
            272,
            238,
            238,
            238,
            238,
            170,
            34,
            340,
            340,
            136,
            340,
            340,
            340,
            340,
            344
        ];
        WEIGHTS[0][10] = [
            159,
            212,
            106,
            53,
            26,
            159,
            53,
            265,
            53,
            212,
            159,
            265,
            53,
            265,
            265,
            212,
            53,
            159,
            239,
            53,
            106,
            5,
            106,
            53,
            212,
            212,
            106,
            159,
            212,
            265,
            212,
            265,
            5066
        ];
        WEIGHTS[0][11] = [
            139,
            278,
            278,
            250,
            250,
            194,
            222,
            278,
            278,
            194,
            222,
            83,
            222,
            278,
            139,
            139,
            27,
            278,
            278,
            278,
            278,
            27,
            278,
            139,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            27,
            139,
            139,
            139,
            139,
            0,
            278,
            194,
            83,
            83,
            278,
            83,
            27,
            306
        ];
        WEIGHTS[0][12] = [981, 2945, 654, 16, 981, 327, 654, 163, 3279];

        // Skull
        WEIGHTS[1][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[1][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[1][2] = [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            10000
        ];
        WEIGHTS[1][3] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][4] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][5] = [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            384,
            7692,
            1923,
            0,
            0,
            0,
            0,
            0,
            1
        ];
        WEIGHTS[1][6] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][7] = [0, 0, 0, 0, 0, 909, 0, 9091];
        WEIGHTS[1][8] = [0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][9] = [
            526,
            526,
            526,
            0,
            0,
            0,
            0,
            0,
            526,
            0,
            0,
            0,
            526,
            0,
            526,
            0,
            0,
            0,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            0,
            0,
            526,
            0,
            0,
            0,
            0,
            532
        ];
        WEIGHTS[1][10] = [
            80,
            0,
            400,
            240,
            80,
            0,
            240,
            0,
            0,
            80,
            80,
            80,
            0,
            0,
            0,
            0,
            80,
            80,
            0,
            0,
            80,
            80,
            0,
            80,
            80,
            80,
            80,
            80,
            0,
            0,
            0,
            0,
            8000
        ];
        WEIGHTS[1][11] = [
            289,
            0,
            0,
            0,
            0,
            404,
            462,
            578,
            578,
            0,
            462,
            173,
            462,
            578,
            0,
            0,
            57,
            0,
            57,
            0,
            57,
            57,
            578,
            289,
            578,
            57,
            0,
            57,
            57,
            57,
            578,
            578,
            0,
            0,
            0,
            0,
            0,
            0,
            57,
            289,
            578,
            0,
            0,
            0,
            231,
            57,
            0,
            0,
            1745
        ];
        WEIGHTS[1][12] = [714, 714, 714, 0, 714, 0, 0, 0, 7144];

        // Bot
        WEIGHTS[2][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[2][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[2][2] = [
            303,
            303,
            303,
            303,
            151,
            30,
            0,
            0,
            151,
            151,
            151,
            151,
            30,
            303,
            151,
            30,
            303,
            303,
            303,
            303,
            303,
            303,
            30,
            151,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            3066
        ];
        WEIGHTS[2][3] = [
            645,
            0,
            1290,
            322,
            645,
            645,
            645,
            967,
            322,
            967,
            645,
            967,
            967,
            973
        ];
        WEIGHTS[2][4] = [2500, 2500, 2500, 0, 0, 0, 0, 0, 0, 2500, 0];
        WEIGHTS[2][5] = [
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            588,
            588,
            588,
            588,
            0,
            0,
            588,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            588,
            588,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            4
        ];
        WEIGHTS[2][6] = [
            925,
            555,
            185,
            555,
            925,
            925,
            185,
            1296,
            1296,
            1296,
            1857
        ];
        WEIGHTS[2][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[2][8] = [183, 274, 274, 18, 18, 27, 36, 9170];
        WEIGHTS[2][9] = [
            340,
            340,
            340,
            340,
            340,
            340,
            34,
            340,
            340,
            340,
            340,
            170,
            170,
            170,
            102,
            238,
            238,
            238,
            272,
            340,
            340,
            340,
            272,
            238,
            238,
            238,
            238,
            170,
            34,
            340,
            340,
            136,
            340,
            340,
            340,
            340,
            344
        ];
        WEIGHTS[2][10] = [
            217,
            362,
            217,
            144,
            72,
            289,
            144,
            362,
            72,
            289,
            217,
            362,
            72,
            362,
            362,
            289,
            0,
            217,
            0,
            72,
            144,
            7,
            217,
            72,
            217,
            217,
            289,
            217,
            289,
            362,
            217,
            362,
            3269
        ];
        WEIGHTS[2][11] = [
            139,
            278,
            278,
            250,
            250,
            194,
            222,
            278,
            278,
            194,
            222,
            83,
            222,
            278,
            139,
            139,
            27,
            278,
            278,
            278,
            278,
            27,
            278,
            139,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            27,
            139,
            139,
            139,
            139,
            0,
            278,
            194,
            83,
            83,
            278,
            83,
            27,
            306
        ];
        WEIGHTS[2][12] = [981, 2945, 654, 16, 981, 327, 654, 163, 3279];
    }

    function splitNumber(uint256 _number)
        public
        pure
        returns (uint16[NUM_LAYERS] memory numbers)
    {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % NUM_RUNNERS);
            _number >>= 14;
        }
        return numbers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IChainRunnersBaseRenderer {
    function getRaceIndex(uint16 _dna) external view returns (uint8);

    function getLayerIndex(
        uint16 _dna,
        uint8 _index,
        uint16 _raceIndex
    ) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ChainRunnersTypes.sol";

/*
               ::::                                                                                                                                                  :::#%=
               @*==+-                                                                                                                                               ++==*=.
               #+=#=++..                                                                                                                                        ..=*=*+-#:
                :=+++++++=====================================:    .===============================================. .=========================================++++++++=
                 .%-+%##+=--==================================+=..=+-=============================================-+*+======================================---+##+=#-.
                   [email protected]@%[email protected]@@%+++++++++++++++++++++++++++%#++++++%#+++#@@@#[email protected]@%[email protected]#+.=+*@*+*@@@@*+++++++++++++++++++++++%@@@#+++#@@+++=
                    -*-#%@@%%%=*%@%*++=++=+==+=++=++=+=++=++==#@%#%#+++=+=*@%*+=+==+=+++%*[email protected]%%#%#++++*@%#++=++=++=++=+=++=++=+=+*%%*==*%@@@*:%=
                     :@:[email protected]@@@@@*+++%@@*+===========+*=========#@@========+#%==========*@========##*#*+=======*@##*======#@#+=======*#*============+#%++#@@%#@@#++=.
                      .*+=%@%*%@%##[email protected]@%#=-==-=--==*%=========*%==--=--=-====--=--=-=##=--=-=--%%%%%+=-=--=-=*%=--=--=-=#%=--=----=#%=--=-=--=-+%#+==#%@@*#%@=++.
                        +%.#@@###%@@@@@%*---------#@%########@%*---------------------##---------------------##---------%%*[email protected]@#---------+#@=#@@#[email protected]@%*++-
                        .:*+*%@#+=*%@@@*=-------=#%#=-------=%*---------=*#*--------#+=--------===--------=#%*-------=#%*[email protected]%#--------=%@@%#*+=-+#%*+*:.
       ====================%*[email protected]@%#==+##%@*[email protected]#[email protected]@*-------=*@[email protected]@*[email protected][email protected]=--------*@@+-------+#@@%#==---+#@.*%====================
     :*=--==================-:=#@@%*===+*@%+=============%%%@=========*%@*[email protected]+=--=====+%@[email protected][email protected]========*%@@+======%%%**+=---=%@#=:-====================-#-
       +++**%@@@#*****************@#*=---=##%@@@@@@@@@@@@@#**@@@@****************%@@*[email protected]#***********#@************************************+=------=*@#*********************@#+=+:
        .-##=*@@%*----------------+%@%=---===+%@@@@@@@*+++---%#++----------------=*@@*+++=-----------=+#=------------------------------------------+%+--------------------+#@[email protected]
         :%:#%#####+=-=-*@@+--=-==-=*@=--=-==-=*@@#*[email protected][email protected]%===-==----+-==-==--+*+-==-==---=*@@@@@@%#===-=-=+%@%-==-=-==-#@%=-==-==--+#@@@@@@@@@@@@*+++
        =*=#@#=----==-=-=++=--=-==-=*@=--=-==-=*@@[email protected]===-=--=-*@@*[email protected]=--=-==--+#@-==-==---+%-==-==---=+++#@@@#--==-=-=++++-=--=-===#%[email protected]@@%.#*
        +#:@%*===================++%#=========%@%=========#%=========+#@%+=======#%==========*@#=========*%=========+*+%@@@+========+*[email protected]@%+**+================*%#*=+=
       *++#@*+=++++++*#%*+++++=+++*%%++++=++++%%*=+++++++##*=++++=++=%@@++++=++=+#%++++=++++#%@=+++++++=*#*+++++++=#%@@@@@*++=++++=#%@*[email protected]#*****=+++++++=+++++*%@@+:=+=
    :=*=#%#@@@@#%@@@%#@@#++++++++++%%*+++++++++++++++++**@*+++++++++*%#++++++++=*##++++++++*%@%+++++++++##+++++++++#%%%%%%++++**#@@@@@**+++++++++++++++++=*%@@@%#@@@@#%@@@%#@++*:.
    #*:@#=-+%#+:=*@*[email protected]%#++++++++#%@@#*++++++++++++++#%@#*++++++++*@@#[email protected]#++++++++*@@#+++++++++##*+++++++++++++++++###@@@@++*@@#+++++++++++++++++++*@@#=:+#%[email protected]*=-+%*[email protected]=
    ++=#%#+%@@%=#%@%#+%%#++++++*#@@@%###**************@@@++++++++**#@##*********#*********#@@#++++++***@#******%@%#*++**#@@@%##+==+++=*#**********%%*++++++++#%#=%@@%+*%@%*+%#*=*-
     .-*+===========*@@+++++*%%%@@@++***************+.%%*++++#%%%@@%=:=******************[email protected]@#+++*%%@#==+***--*@%*++*%@@*===+**=--   -************[email protected]%%#++++++#@@@*==========*+-
        =*******##.#%#++++*%@@@%+==+=             *#-%@%**%%###*====**-               [email protected]:*@@##@###*==+**-.-#[email protected]@#*@##*==+***=                     =+=##%@*+++++*%@@#.#%******:
               ++++%#+++*#@@@@+++==.              **[email protected]@@%+++++++===-                 -+++#@@+++++++==:  :+++%@@+++++++==:                          [email protected]%##[email protected]@%++++
             :%:*%%****%@@%+==*-                .%==*====**+...                      #*.#+==***....    #+=#%+==****:.                                ..-*=*%@%#++*#%@=+%.
            -+++#%+#%@@@#++===                  [email protected]*++===-                            #%++===           %#+++===                                          =+++%@%##**@@*[email protected]:
          .%-=%@##@@%*==++                                                                                                                                 .*==+#@@%*%@%=*=.
         .+++#@@@@@*++==.                                                                                                                                    -==++#@@@@@@=+%
       .=*=%@@%%%#=*=.                                                                                                                                          .*+=%@@@@%+-#.
       @[email protected]@@%:++++.                                                                                                                                              -+++**@@#+*=:
    .-+=*#%%++*::.                                                                                                                                                  :+**=#%@#==#
    #*:@*+++=:                                                                                                                                                          [email protected]*++=:
  :*-=*=++..                                                                                                                                                             .=*=#*.%=
 +#.=+++:                                                                                                                                                                   ++++:+#
*+=#-::                                                                                                                                                                      .::*+=*

*/

contract ChainRunnersBaseRenderer is Ownable, ReentrancyGuard {
    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct Buffer {
        string one;
        string two;
        string three;
        string four;
        string five;
        string six;
        string seven;
        string eight;
    }

    struct Color {
        string hexString;
        uint256 alpha;
        uint256 red;
        uint256 green;
        uint256 blue;
    }

    struct Layer {
        string name;
        bytes hexString;
    }

    struct LayerInput {
        string name;
        bytes hexString;
        uint8 layerIndex;
        uint8 itemIndex;
    }

    uint256 public constant NUM_LAYERS = 13;
    uint256 public constant NUM_COLORS = 8;

    mapping(uint256 => Layer)[NUM_LAYERS] layers;

    /*
    This indexes into a race, then a layer index, then an array capturing the frequency each layer should be selected.
    Shout out to Anonymice for the rarity impl inspiration.
    */
    uint16[][NUM_LAYERS][3] WEIGHTS;

    constructor() {
        // Default
        WEIGHTS[0][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[0][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[0][2] = [
            303,
            303,
            303,
            303,
            151,
            30,
            0,
            0,
            151,
            151,
            151,
            151,
            30,
            303,
            151,
            30,
            303,
            303,
            303,
            303,
            303,
            303,
            30,
            151,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            3066
        ];
        WEIGHTS[0][3] = [
            645,
            0,
            1290,
            322,
            645,
            645,
            645,
            967,
            322,
            967,
            645,
            967,
            967,
            973
        ];
        WEIGHTS[0][4] = [
            0,
            0,
            0,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250
        ];
        WEIGHTS[0][5] = [
            121,
            121,
            121,
            121,
            121,
            121,
            243,
            0,
            0,
            0,
            0,
            121,
            121,
            243,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            243,
            0,
            0,
            0,
            121,
            121,
            243,
            121,
            121,
            306
        ];
        WEIGHTS[0][6] = [
            925,
            555,
            185,
            555,
            925,
            925,
            185,
            1296,
            1296,
            1296,
            1857
        ];
        WEIGHTS[0][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[0][8] = [189, 189, 47, 18, 9, 28, 37, 9483];
        WEIGHTS[0][9] = [
            340,
            340,
            340,
            340,
            340,
            340,
            34,
            340,
            340,
            340,
            340,
            170,
            170,
            170,
            102,
            238,
            238,
            238,
            272,
            340,
            340,
            340,
            272,
            238,
            238,
            238,
            238,
            170,
            34,
            340,
            340,
            136,
            340,
            340,
            340,
            340,
            344
        ];
        WEIGHTS[0][10] = [
            159,
            212,
            106,
            53,
            26,
            159,
            53,
            265,
            53,
            212,
            159,
            265,
            53,
            265,
            265,
            212,
            53,
            159,
            239,
            53,
            106,
            5,
            106,
            53,
            212,
            212,
            106,
            159,
            212,
            265,
            212,
            265,
            5066
        ];
        WEIGHTS[0][11] = [
            139,
            278,
            278,
            250,
            250,
            194,
            222,
            278,
            278,
            194,
            222,
            83,
            222,
            278,
            139,
            139,
            27,
            278,
            278,
            278,
            278,
            27,
            278,
            139,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            27,
            139,
            139,
            139,
            139,
            0,
            278,
            194,
            83,
            83,
            278,
            83,
            27,
            306
        ];
        WEIGHTS[0][12] = [981, 2945, 654, 16, 981, 327, 654, 163, 3279];

        // Skull
        WEIGHTS[1][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[1][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[1][2] = [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            10000
        ];
        WEIGHTS[1][3] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][4] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][5] = [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            384,
            7692,
            1923,
            0,
            0,
            0,
            0,
            0,
            1
        ];
        WEIGHTS[1][6] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][7] = [0, 0, 0, 0, 0, 909, 0, 9091];
        WEIGHTS[1][8] = [0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][9] = [
            526,
            526,
            526,
            0,
            0,
            0,
            0,
            0,
            526,
            0,
            0,
            0,
            526,
            0,
            526,
            0,
            0,
            0,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            0,
            0,
            526,
            0,
            0,
            0,
            0,
            532
        ];
        WEIGHTS[1][10] = [
            80,
            0,
            400,
            240,
            80,
            0,
            240,
            0,
            0,
            80,
            80,
            80,
            0,
            0,
            0,
            0,
            80,
            80,
            0,
            0,
            80,
            80,
            0,
            80,
            80,
            80,
            80,
            80,
            0,
            0,
            0,
            0,
            8000
        ];
        WEIGHTS[1][11] = [
            289,
            0,
            0,
            0,
            0,
            404,
            462,
            578,
            578,
            0,
            462,
            173,
            462,
            578,
            0,
            0,
            57,
            0,
            57,
            0,
            57,
            57,
            578,
            289,
            578,
            57,
            0,
            57,
            57,
            57,
            578,
            578,
            0,
            0,
            0,
            0,
            0,
            0,
            57,
            289,
            578,
            0,
            0,
            0,
            231,
            57,
            0,
            0,
            1745
        ];
        WEIGHTS[1][12] = [714, 714, 714, 0, 714, 0, 0, 0, 7144];

        // Bot
        WEIGHTS[2][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[2][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[2][2] = [
            303,
            303,
            303,
            303,
            151,
            30,
            0,
            0,
            151,
            151,
            151,
            151,
            30,
            303,
            151,
            30,
            303,
            303,
            303,
            303,
            303,
            303,
            30,
            151,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            3066
        ];
        WEIGHTS[2][3] = [
            645,
            0,
            1290,
            322,
            645,
            645,
            645,
            967,
            322,
            967,
            645,
            967,
            967,
            973
        ];
        WEIGHTS[2][4] = [2500, 2500, 2500, 0, 0, 0, 0, 0, 0, 2500, 0];
        WEIGHTS[2][5] = [
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            588,
            588,
            588,
            588,
            0,
            0,
            588,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            588,
            588,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            4
        ];
        WEIGHTS[2][6] = [
            925,
            555,
            185,
            555,
            925,
            925,
            185,
            1296,
            1296,
            1296,
            1857
        ];
        WEIGHTS[2][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[2][8] = [183, 274, 274, 18, 18, 27, 36, 9170];
        WEIGHTS[2][9] = [
            340,
            340,
            340,
            340,
            340,
            340,
            34,
            340,
            340,
            340,
            340,
            170,
            170,
            170,
            102,
            238,
            238,
            238,
            272,
            340,
            340,
            340,
            272,
            238,
            238,
            238,
            238,
            170,
            34,
            340,
            340,
            136,
            340,
            340,
            340,
            340,
            344
        ];
        WEIGHTS[2][10] = [
            217,
            362,
            217,
            144,
            72,
            289,
            144,
            362,
            72,
            289,
            217,
            362,
            72,
            362,
            362,
            289,
            0,
            217,
            0,
            72,
            144,
            7,
            217,
            72,
            217,
            217,
            289,
            217,
            289,
            362,
            217,
            362,
            3269
        ];
        WEIGHTS[2][11] = [
            139,
            278,
            278,
            250,
            250,
            194,
            222,
            278,
            278,
            194,
            222,
            83,
            222,
            278,
            139,
            139,
            27,
            278,
            278,
            278,
            278,
            27,
            278,
            139,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            27,
            139,
            139,
            139,
            139,
            0,
            278,
            194,
            83,
            83,
            278,
            83,
            27,
            306
        ];
        WEIGHTS[2][12] = [981, 2945, 654, 16, 981, 327, 654, 163, 3279];
    }

    function setLayers(LayerInput[] calldata toSet) external virtual onlyOwner {
        for (uint16 i = 0; i < toSet.length; i++) {
            layers[toSet[i].layerIndex][toSet[i].itemIndex] = Layer(
                toSet[i].name,
                toSet[i].hexString
            );
        }
    }

    function getLayer(uint8 layerIndex, uint8 itemIndex)
        public
        view
        virtual
        returns (Layer memory)
    {
        return layers[layerIndex][itemIndex];
    }

    /*
    Get race index.  Race index represents the "type" of base character:

    0 - Default, representing human and alien characters
    1 - Skull
    2 - Bot

    This allows skull/bot characters to have distinct trait distributions.
    */
    function getRaceIndex(uint16 _dna) public view returns (uint8) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < WEIGHTS[0][1].length; i++) {
            percentage = WEIGHTS[0][1][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                if (i == 1) {
                    // Bot
                    return 2;
                } else if (i > 11) {
                    // Skull
                    return 1;
                } else {
                    // Default
                    return 0;
                }
            }
            lowerBound += percentage;
        }
        revert();
    }

    function getLayerIndex(
        uint16 _dna,
        uint8 _index,
        uint16 _raceIndex
    ) public view returns (uint8) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < WEIGHTS[_raceIndex][_index].length; i++) {
            percentage = WEIGHTS[_raceIndex][_index][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return uint8(WEIGHTS[_raceIndex][_index].length);
    }

    /*
    Generate base64 encoded tokenURI.

    All string constants are pre-base64 encoded to save gas.
    Input strings are padded with spacing/etc to ensure their length is a multiple of 3.
    This way the resulting base64 encoded string is a multiple of 4 and will not include any '=' padding characters,
    which allows these base64 string snippets to be concatenated with other snippets.
    */
    function tokenURI(
        uint256 tokenId,
        ChainRunnersTypes.ChainRunner memory runnerData
    ) public view returns (string memory) {
        (
            Layer[NUM_LAYERS] memory tokenLayers,
            Color[NUM_COLORS][NUM_LAYERS] memory tokenPalettes,
            uint8 numTokenLayers,
            string[NUM_LAYERS] memory traitTypes
        ) = getTokenData(runnerData.dna);
        string memory attributes;
        for (uint8 i = 0; i < numTokenLayers; i++) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    bytes(attributes).length == 0 ? "eyAg" : "LCB7",
                    "InRyYWl0X3R5cGUiOiAi",
                    traitTypes[i],
                    "IiwidmFsdWUiOiAi",
                    tokenLayers[i].name,
                    "IiB9"
                )
            );
        }
        string[4] memory svgBuffers = tokenSVGBuffer(
            tokenLayers,
            tokenPalettes,
            numTokenLayers
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,eyAgImltYWdlX2RhdGEiOiAiPHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+",
                    svgBuffers[0],
                    svgBuffers[1],
                    svgBuffers[2],
                    svgBuffers[3],
                    "PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4gIiwgImF0dHJpYnV0ZXMiOiBb",
                    attributes,
                    "XSwgICAibmFtZSI6IlJ1bm5lciAj",
                    Base64.encode(uintToByteString(tokenId, 6)),
                    "IiwgImRlc2NyaXB0aW9uIjogIkNoYWluIFJ1bm5lcnMgYXJlIE1lZ2EgQ2l0eSByZW5lZ2FkZXMgMTAwJSBnZW5lcmF0ZWQgb24gY2hhaW4uIn0g"
                )
            );
    }

    function tokenSVG(uint256 _dna) public view returns (string memory) {
        (
            Layer[NUM_LAYERS] memory tokenLayers,
            Color[NUM_COLORS][NUM_LAYERS] memory tokenPalettes,
            uint8 numTokenLayers,

        ) = getTokenData(_dna);
        string[4] memory buffer256 = tokenSVGBuffer(
            tokenLayers,
            tokenPalettes,
            numTokenLayers
        );
        return
            string(
                abi.encodePacked(
                    "PHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMiAzMicgeG1sbnM9J2h0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnJyBzaGFwZS1yZW5kZXJpbmc9J2NyaXNwRWRnZXMnIGhlaWdodD0nMTAwJScgd2lkdGg9JzEwMCUnICA+",
                    buffer256[0],
                    buffer256[1],
                    buffer256[2],
                    buffer256[3],
                    "PHN0eWxlPnJlY3R7d2lkdGg6MXB4O2hlaWdodDoxcHg7fTwvc3R5bGU+PC9zdmc+"
                )
            );
    }

    function getTokenData(uint256 _dna)
        public
        view
        returns (
            Layer[NUM_LAYERS] memory tokenLayers,
            Color[NUM_COLORS][NUM_LAYERS] memory tokenPalettes,
            uint8 numTokenLayers,
            string[NUM_LAYERS] memory traitTypes
        )
    {
        uint16[NUM_LAYERS] memory dna = splitNumber(_dna);
        uint16 raceIndex = getRaceIndex(dna[1]);

        bool hasFaceAcc = dna[7] < (10000 - WEIGHTS[raceIndex][7][7]);
        bool hasMask = dna[8] < (10000 - WEIGHTS[raceIndex][8][7]);
        bool hasHeadBelow = dna[9] < (10000 - WEIGHTS[raceIndex][9][36]);
        bool hasHeadAbove = dna[11] < (10000 - WEIGHTS[raceIndex][11][48]);
        bool useHeadAbove = (dna[0] % 2) > 0;
        for (uint8 i = 0; i < NUM_LAYERS; i++) {
            Layer memory layer = getLayer(
                i,
                getLayerIndex(dna[i], i, raceIndex)
            );
            if (layer.hexString.length > 0) {
                /*
                These conditions help make sure layer selection meshes well visually.
                1. If mask, no face/eye acc/mouth acc
                2. If face acc, no mask/mouth acc/face
                3. If both head above & head below, randomly choose one
                */
                if (
                    ((i == 2 || i == 12) && !hasMask && !hasFaceAcc) ||
                    (i == 7 && !hasMask) ||
                    (i == 10 && !hasMask) ||
                    (i < 2 || (i > 2 && i < 7) || i == 8 || i == 9 || i == 11)
                ) {
                    if (
                        (hasHeadBelow &&
                            hasHeadAbove &&
                            (i == 9 && useHeadAbove)) ||
                        (i == 11 && !useHeadAbove)
                    ) continue;
                    tokenLayers[numTokenLayers] = layer;
                    tokenPalettes[numTokenLayers] = palette(
                        tokenLayers[numTokenLayers].hexString
                    );
                    traitTypes[numTokenLayers] = [
                        "QmFja2dyb3VuZCAg",
                        "UmFjZSAg",
                        "RmFjZSAg",
                        "TW91dGgg",
                        "Tm9zZSAg",
                        "RXllcyAg",
                        "RWFyIEFjY2Vzc29yeSAg",
                        "RmFjZSBBY2Nlc3Nvcnkg",
                        "TWFzayAg",
                        "SGVhZCBCZWxvdyAg",
                        "RXllIEFjY2Vzc29yeSAg",
                        "SGVhZCBBYm92ZSAg",
                        "TW91dGggQWNjZXNzb3J5"
                    ][i];
                    numTokenLayers++;
                }
            }
        }
        return (tokenLayers, tokenPalettes, numTokenLayers, traitTypes);
    }

    /*
    Generate svg rects, leaving un-concatenated to save a redundant concatenation in calling functions to reduce gas.
    Shout out to Blitmap for a lot of the inspiration for efficient rendering here.
    */
    function tokenSVGBuffer(
        Layer[NUM_LAYERS] memory tokenLayers,
        Color[NUM_COLORS][NUM_LAYERS] memory tokenPalettes,
        uint8 numTokenLayers
    ) public pure returns (string[4] memory) {
        // Base64 encoded lookups into x/y position strings from 010 to 310.
        string[32] memory lookup = [
            "MDAw",
            "MDEw",
            "MDIw",
            "MDMw",
            "MDQw",
            "MDUw",
            "MDYw",
            "MDcw",
            "MDgw",
            "MDkw",
            "MTAw",
            "MTEw",
            "MTIw",
            "MTMw",
            "MTQw",
            "MTUw",
            "MTYw",
            "MTcw",
            "MTgw",
            "MTkw",
            "MjAw",
            "MjEw",
            "MjIw",
            "MjMw",
            "MjQw",
            "MjUw",
            "MjYw",
            "Mjcw",
            "Mjgw",
            "Mjkw",
            "MzAw",
            "MzEw"
        ];
        SVGCursor memory cursor;

        /*
        Rather than concatenating the result string with itself over and over (e.g. result = abi.encodePacked(result, newString)),
        we fill up multiple levels of buffers.  This reduces redundant intermediate concatenations, performing O(log(n)) concats
        instead of O(n) concats.  Buffers beyond a length of about 12 start hitting stack too deep issues, so using a length of 8
        because the pixel math is convenient.
        */
        Buffer memory buffer4;
        // 4 pixels per slot, 32 total.  Struct is ever so slightly better for gas, so using when convenient.
        string[8] memory buffer32;
        // 32 pixels per slot, 256 total
        string[4] memory buffer256;
        // 256 pixels per slot, 1024 total
        uint8 buffer32count;
        uint8 buffer256count;
        for (uint256 k = 32; k < 416; ) {
            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                0,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                1,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                2,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                3,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.one = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                4,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                5,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                6,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                7,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.two = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                0,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                1,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                2,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                3,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.three = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                4,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                5,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                6,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                7,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.four = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                0,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                1,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                2,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                3,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.five = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                4,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                5,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                6,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                7,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.six = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                0,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                1,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                2,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                3,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.seven = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(
                tokenLayers,
                k,
                4,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color2 = colorForIndex(
                tokenLayers,
                k,
                5,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color3 = colorForIndex(
                tokenLayers,
                k,
                6,
                tokenPalettes,
                numTokenLayers
            );
            cursor.color4 = colorForIndex(
                tokenLayers,
                k,
                7,
                tokenPalettes,
                numTokenLayers
            );
            buffer4.eight = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            buffer32[buffer32count++] = string(
                abi.encodePacked(
                    buffer4.one,
                    buffer4.two,
                    buffer4.three,
                    buffer4.four,
                    buffer4.five,
                    buffer4.six,
                    buffer4.seven,
                    buffer4.eight
                )
            );
            cursor.x = 0;
            cursor.y += 1;
            if (buffer32count >= 8) {
                buffer256[buffer256count++] = string(
                    abi.encodePacked(
                        buffer32[0],
                        buffer32[1],
                        buffer32[2],
                        buffer32[3],
                        buffer32[4],
                        buffer32[5],
                        buffer32[6],
                        buffer32[7]
                    )
                );
                buffer32count = 0;
            }
        }
        // At this point, buffer256 contains 4 strings or 256*4=1024=32x32 pixels
        return buffer256;
    }

    function palette(bytes memory data)
        internal
        pure
        returns (Color[NUM_COLORS] memory)
    {
        Color[NUM_COLORS] memory colors;
        for (uint16 i = 0; i < NUM_COLORS; i++) {
            // Even though this can be computed later from the RGBA values below, it saves gas to pre-compute it once upfront.
            colors[i].hexString = Base64.encode(
                bytes(
                    abi.encodePacked(
                        byteToHexString(data[i * 4]),
                        byteToHexString(data[i * 4 + 1]),
                        byteToHexString(data[i * 4 + 2])
                    )
                )
            );
            colors[i].red = byteToUint(data[i * 4]);
            colors[i].green = byteToUint(data[i * 4 + 1]);
            colors[i].blue = byteToUint(data[i * 4 + 2]);
            colors[i].alpha = byteToUint(data[i * 4 + 3]);
        }
        return colors;
    }

    function colorForIndex(
        Layer[NUM_LAYERS] memory tokenLayers,
        uint256 k,
        uint256 index,
        Color[NUM_COLORS][NUM_LAYERS] memory palettes,
        uint256 numTokenLayers
    ) internal pure returns (string memory) {
        for (uint256 i = 0; i < numTokenLayers; i++) {
            Color memory fg = palettes[numTokenLayers - 1 - i][
                colorIndex(
                    tokenLayers[numTokenLayers - 1 - i].hexString,
                    k,
                    index
                )
            ];
            // Since most layer pixels are transparent, performing this check first saves gas
            if (fg.alpha == 0) {
                continue;
            } else if (fg.alpha == 255) {
                return fg.hexString;
            } else {
                if (numTokenLayers - 2 - i >= 0) {
                    for (uint256 j = numTokenLayers - 2 - i; j >= 0; j--) {
                        Color memory bg = palettes[j][
                            colorIndex(tokenLayers[j].hexString, k, index)
                        ];
                        /* As a simplification, blend with first non-transparent layer then stop.
                    We won't generally have overlapping semi-transparent pixels.
                    */
                        if (bg.alpha > 0) {
                            return Base64.encode(bytes(blendColors(fg, bg)));
                        }
                    }
                } else {
                    return fg.hexString;
                }
            }
        }
        return Base64.encode(bytes("ffffff"));
    }

    /*
    Each color index is 3 bits (there are 8 colors, so 3 bits are needed to index into them).
    Since 3 bits doesn't divide cleanly into 8 bits (1 byte), we look up colors 24 bits (3 bytes) at a time.
    "k" is the starting byte index, and "index" is the color index within the 3 bytes starting at k.
    */
    function colorIndex(
        bytes memory data,
        uint256 k,
        uint256 index
    ) internal pure returns (uint8) {
        if (index == 0) {
            return uint8(data[k]) >> 5;
        } else if (index == 1) {
            return (uint8(data[k]) >> 2) % 8;
        } else if (index == 2) {
            return ((uint8(data[k]) % 4) * 2) + (uint8(data[k + 1]) >> 7);
        } else if (index == 3) {
            return (uint8(data[k + 1]) >> 4) % 8;
        } else if (index == 4) {
            return (uint8(data[k + 1]) >> 1) % 8;
        } else if (index == 5) {
            return ((uint8(data[k + 1]) % 2) * 4) + (uint8(data[k + 2]) >> 6);
        } else if (index == 6) {
            return (uint8(data[k + 2]) >> 3) % 8;
        } else {
            return uint8(data[k + 2]) % 8;
        }
    }

    /*
    Create 4 svg rects, pre-base64 encoding the svg constants to save gas.
    */
    function pixel4(string[32] memory lookup, SVGCursor memory cursor)
        internal
        pure
        returns (string memory result)
    {
        return
            string(
                abi.encodePacked(
                    "PHJlY3QgICBmaWxsPScj",
                    cursor.color1,
                    "JyAgeD0n",
                    lookup[cursor.x],
                    "JyAgeT0n",
                    lookup[cursor.y],
                    "JyAvPjxyZWN0ICBmaWxsPScj",
                    cursor.color2,
                    "JyAgeD0n",
                    lookup[cursor.x + 1],
                    "JyAgeT0n",
                    lookup[cursor.y],
                    "JyAvPjxyZWN0ICBmaWxsPScj",
                    cursor.color3,
                    "JyAgeD0n",
                    lookup[cursor.x + 2],
                    "JyAgeT0n",
                    lookup[cursor.y],
                    "JyAvPjxyZWN0ICBmaWxsPScj",
                    cursor.color4,
                    "JyAgeD0n",
                    lookup[cursor.x + 3],
                    "JyAgeT0n",
                    lookup[cursor.y],
                    "JyAgIC8+"
                )
            );
    }

    /*
    Blend colors, inspired by https://stackoverflow.com/a/12016968
    */
    function blendColors(Color memory fg, Color memory bg)
        internal
        pure
        returns (string memory)
    {
        uint256 alpha = uint16(fg.alpha + 1);
        uint256 inv_alpha = uint16(256 - fg.alpha);
        return
            uintToHexString6(
                uint24((alpha * fg.blue + inv_alpha * bg.blue) >> 8) +
                    (uint24((alpha * fg.green + inv_alpha * bg.green) >> 8) <<
                        8) +
                    (uint24((alpha * fg.red + inv_alpha * bg.red) >> 8) << 16)
            );
    }

    function splitNumber(uint256 _number)
        internal
        pure
        returns (uint16[NUM_LAYERS] memory numbers)
    {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    function uintToHexDigit(uint8 d) public pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }

    /*
    Convert uint to hex string, padding to 6 hex nibbles
    */
    function uintToHexString6(uint256 a) public pure returns (string memory) {
        string memory str = uintToHexString2(a);
        if (bytes(str).length == 2) {
            return string(abi.encodePacked("0000", str));
        } else if (bytes(str).length == 3) {
            return string(abi.encodePacked("000", str));
        } else if (bytes(str).length == 4) {
            return string(abi.encodePacked("00", str));
        } else if (bytes(str).length == 5) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to hex string, padding to 2 hex nibbles
    */
    function uintToHexString2(uint256 a) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint256 i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to byte string, padding number string with spaces at end.
    Useful to ensure result's length is a multiple of 3, and therefore base64 encoding won't
    result in '=' padding chars.
    */
    function uintToByteString(uint256 a, uint256 fixedLen)
        internal
        pure
        returns (bytes memory _uintAsString)
    {
        uint256 j = a;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        j = fixedLen;
        if (a == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(" ");
        }
        uint256 k = len;
        while (a != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(a - (a / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            a /= 10;
        }
        return bstr;
    }

    function byteToUint(bytes1 b) public pure returns (uint256) {
        return uint256(uint8(b));
    }

    function byteToHexString(bytes1 b) public pure returns (string memory) {
        return uintToHexString2(byteToUint(b));
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ChainRunnersTypes {
    struct ChainRunner {
        uint256 dna;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChainRunnersBaseRenderer.sol";
import "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract ChainRunnersSStoreRenderer is ChainRunnersBaseRenderer {
    mapping(uint256 => address)[NUM_LAYERS] layerAddresses;
    mapping(uint256 => string)[NUM_LAYERS] layerNames;

    function setLayers(LayerInput[] calldata toSet)
        external
        override
        onlyOwner
    {
        for (uint16 i = 0; i < toSet.length; i++) {
            layerAddresses[toSet[i].layerIndex][toSet[i].itemIndex] = SSTORE2
                .write(toSet[i].hexString);
            layerNames[toSet[i].layerIndex][toSet[i].itemIndex] = toSet[i].name;
        }
    }

    function getLayer(uint8 layerIndex, uint8 itemIndex)
        public
        view
        virtual
        override
        returns (Layer memory)
    {
        return
            Layer(
                layerNames[layerIndex][itemIndex],
                SSTORE2.read(layerAddresses[layerIndex][itemIndex])
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChainRunnersSStoreRenderer.sol";
import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "../lib/RLE.sol";

contract ChainRunnersSStoreRLERenderer is ChainRunnersSStoreRenderer {
    function getLayer(uint8 layerIndex, uint8 itemIndex)
        public
        view
        override
        returns (Layer memory)
    {
        return
            Layer(
                layerNames[layerIndex][itemIndex],
                RLE.decode(SSTORE2.read(layerAddresses[layerIndex][itemIndex]))
            );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library RLE {
    function decode(bytes calldata _rleBytes)
        public
        pure
        returns (bytes memory)
    {
        bytes memory decodedBytes;
        for (uint256 i = 0; i < _rleBytes.length; i += 2) {
            uint8 count = uint8(_rleBytes[i]);
            bytes1 current = _rleBytes[i + 1];
            for (uint8 j = 0; j < count; j++) {
                decodedBytes = bytes.concat(decodedBytes, current);
            }
        }
        return decodedBytes;
    }

    function decode(
        bytes calldata _rleBytes,
        uint256 _offset,
        uint256 _length
    ) public pure returns (bytes memory) {
        uint16 start = 0;
        uint16 skipped = 0;

        while (skipped < _offset) {
            skipped += uint16(uint8(_rleBytes[start]));
            start += 2;
        }
        if (skipped > _offset) {
            start -= 2;
            skipped -= uint16(uint8(_rleBytes[start]));
        }

        bytes memory decodedBytes;
        for (
            uint8 j = 0;
            j < uint8(_rleBytes[start]) - uint8(_offset - skipped);
            j++
        ) {
            decodedBytes = bytes.concat(decodedBytes, _rleBytes[start + 1]);
            if (decodedBytes.length == _length) {
                break;
            }
        }
        while (decodedBytes.length < _length) {
            start += 2;
            if (start >= _rleBytes.length) {
                revert("RLE decode error: end of data reached");
            }
            for (uint8 j = 0; j < uint8(_rleBytes[start]); j++) {
                if (decodedBytes.length >= _length) {
                    break;
                }
                decodedBytes = bytes.concat(decodedBytes, _rleBytes[start + 1]);
            }
        }
        if (decodedBytes.length > _length) {
            revert("RLE decode error: unknown error");
        }
        return decodedBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "./ChainRunnersSStoreConcatRenderer.sol";
import "../lib/RLE.sol";

contract ChainRunnersSStoreConcatRLERenderer is
    ChainRunnersSStoreConcatRenderer
{
    uint16 private immutable TRAIT_LENGTH = 416;
    uint16 private immutable TRAITS_PER_STORAGE = 57;

    function getLayer(uint8 layerIndex, uint8 itemIndex)
        public
        view
        virtual
        override
        returns (Layer memory)
    {
        // storageIndex is the index of the SSTORE2 containing the data
        uint8 storageIndex = 0;
        bytes memory layerIndexes = SSTORE2.read(
            layerLayerIndexes[storageIndex]
        );

        // Since layerIndexes are sorted, we only look at the last byte to check if this storageIndex
        // is the one we are looking for
        while (uint8(layerIndexes[layerIndexes.length - 1]) < layerIndex) {
            storageIndex++;
            layerIndexes = SSTORE2.read(layerLayerIndexes[storageIndex]);
        }

        // Actually the items for this layerIndex may be split between this storageIndex and the one after
        // So we check if the itemIndex is in the range of the itemIndexes for this storageIndex
        uint8 startItemIndex = 0;
        if (uint8(layerIndexes[layerIndexes.length - 1]) == layerIndex) {
            if (itemIndex > uint8(layerIndexes[layerIndexes.length - 2])) {
                storageIndex++;
                startItemIndex = uint8(layerIndexes[layerIndexes.length - 2]);
                layerIndexes = SSTORE2.read(layerLayerIndexes[storageIndex]);
            }
        }

        // Get the shift for the beginning of this layerIndex slots
        uint8 currentStorageShiftCount = 0;
        uint16 cumSum = 0;
        while (
            uint8(layerIndexes[currentStorageShiftCount * 2 + 1]) < layerIndex
        ) {
            cumSum += uint16(uint8(layerIndexes[currentStorageShiftCount * 2]));
            currentStorageShiftCount++;
        }

        // Move towards the slots to get max theoretical itemIndex
        uint16 layerCount = uint16(
            uint8(layerIndexes[currentStorageShiftCount * 2])
        ) + startItemIndex;
        while (
            (layerCount < itemIndex) &&
            (uint8(layerIndexes[currentStorageShiftCount * 2 + 3]) ==
                layerIndex)
        ) {
            currentStorageShiftCount++;
            layerCount += uint16(
                uint8(layerIndexes[currentStorageShiftCount * 2])
            );
            if (currentStorageShiftCount * 2 + 3 >= layerIndexes.length) {
                break;
            }
        }
        // Layer not found, return empty layer to match ChainRunnersBaseRenderer empty layer with mapping
        if (layerCount <= itemIndex) {
            return Layer("", "");
        }

        cumSum = cumSum + itemIndex - startItemIndex;
        // Decode only the right RLE data
        bytes memory hexString = RLE.decode(
            SSTORE2.read(layerHexStrings[storageIndex]),
            TRAIT_LENGTH * cumSum,
            TRAIT_LENGTH
        );

        // Retrieve trait name given storageIndex and storage shift
        string memory name = layerNames[
            uint16(storageIndex) * TRAITS_PER_STORAGE + cumSum
        ];

        return Layer(name, hexString);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChainRunnersBaseRenderer.sol";
import "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract ChainRunnersSStoreConcatRenderer is ChainRunnersBaseRenderer {
    address[] layerHexStrings;
    address[] layerLayerIndexes;
    address[] layerItemIndexes;
    string[] layerNames;

    struct LayerInputConcat {
        string[] name;
        bytes hexString;
        bytes layerIndex;
        bytes itemIndex;
    }

    function setLayers(LayerInputConcat[] calldata toSet) external onlyOwner {
        for (uint8 i = 0; i < toSet.length; i++) {
            for (uint8 j = 0; j < toSet[i].name.length; j++) {
                layerNames.push(toSet[i].name[j]);
            }
            layerHexStrings.push(SSTORE2.write(toSet[i].hexString));
            layerLayerIndexes.push(SSTORE2.write(toSet[i].layerIndex));
            layerItemIndexes.push(SSTORE2.write(toSet[i].itemIndex));
        }
    }

    function getLayer(uint8 layerIndex, uint8 itemIndex)
        public
        view
        virtual
        override
        returns (Layer memory)
    {
        // storageIndex is the index of the SSTORE2 containing the data
        uint8 storageIndex = 0;
        bytes memory layerIndexes = SSTORE2.read(
            layerLayerIndexes[storageIndex]
        );
        uint8 lastLayerIndex = uint8(layerIndexes[layerIndexes.length - 1]);

        // Since layerIndexes are sorted, we only look at the last byte to check if this storageIndex
        // is the one we are looking for
        while (lastLayerIndex < layerIndex) {
            storageIndex++;
            layerIndexes = SSTORE2.read(layerLayerIndexes[storageIndex]);
            lastLayerIndex = uint8(layerIndexes[layerIndexes.length - 1]);
        }

        // Load the corresponding item indexes for the given storageIndex
        bytes memory itemIndexes = SSTORE2.read(layerItemIndexes[storageIndex]);

        // Actually the items for this layerIndex may be split between this storageIndex and the one after
        // So we check if the itemIndex is in the range of the itemIndexes for this storageIndex
        if (lastLayerIndex == layerIndex) {
            if (itemIndex > uint8(itemIndexes[itemIndexes.length - 1])) {
                storageIndex++;
                layerIndexes = SSTORE2.read(layerLayerIndexes[storageIndex]);
                itemIndexes = SSTORE2.read(layerItemIndexes[storageIndex]);
            }
        }

        uint8 currentStorageShiftCount = 0;
        while (uint8(layerIndexes[currentStorageShiftCount]) < layerIndex) {
            currentStorageShiftCount++;
        }
        while (
            (uint8(itemIndexes[currentStorageShiftCount]) < itemIndex) &&
            (uint8(layerIndexes[currentStorageShiftCount]) == layerIndex)
        ) {
            currentStorageShiftCount++;
        }
        if (uint8(itemIndexes[currentStorageShiftCount]) < itemIndex) {
            // Layer not found, return empty layer to match ChainRunnersBaseRenderer empty layer with mapping
            return Layer("", "");
        }

        bytes memory storageHexStrings = SSTORE2.read(
            layerHexStrings[storageIndex]
        );
        bytes memory hexString = new bytes(416);
        for (uint16 i = 0; i < 416; i++) {
            hexString[i] = storageHexStrings[
                i + 416 * currentStorageShiftCount
            ];
        }

        uint16 nameIndex = uint16(storageIndex) *
            57 +
            uint16(currentStorageShiftCount);
        string memory name = layerNames[nameIndex];
        return Layer(name, hexString);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChainRunnersBaseRenderer.sol";
import "../lib/RLE.sol";

contract ChainRunnersRLERenderer is ChainRunnersBaseRenderer {
    function getLayer(uint8 layerIndex, uint8 itemIndex)
        public
        view
        override
        returns (Layer memory)
    {
        Layer memory layer = layers[layerIndex][itemIndex];
        layer.hexString = RLE.decode(layer.hexString);
        return layer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChainRunnersBaseRenderer.sol";

contract ChainRunnersLayerRenderer is ChainRunnersBaseRenderer {
    function traitSVG(uint8 layerIndex, uint8 itemIndex)
        public
        view
        returns (string memory)
    {
        Layer[NUM_LAYERS] memory tokenLayers;
        Color[NUM_COLORS][NUM_LAYERS] memory tokenPalettes;
        Layer memory layer = getLayer(layerIndex, itemIndex);

        tokenLayers[0] = layer;
        tokenPalettes[0] = palette(tokenLayers[0].hexString);
        string[4] memory buffer256 = tokenSVGBuffer(
            tokenLayers,
            tokenPalettes,
            1
        );
        return
            string(
                abi.encodePacked(
                    "PHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcycgaGVpZ2h0PScxMDAlJyB3aWR0aD0nMTAwJSc+",
                    buffer256[0],
                    buffer256[1],
                    buffer256[2],
                    buffer256[3],
                    "PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4="
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChainRunnersTypes.sol";

interface IChainRunnersRenderer {
    function tokenURI(
        uint256 tokenId,
        ChainRunnersTypes.ChainRunner memory runnerData
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ChainRunnersTypes.sol";
import "./IChainRunnersRenderer.sol";

/*
               ::::                                                                                                                                                  :::#%=
               @*==+-                                                                                                                                               ++==*=.
               #+=#=++..                                                                                                                                        ..=*=*+-#:
                :=+++++++=====================================:    .===============================================. .=========================================++++++++=
                 .%-+%##+=--==================================+=..=+-=============================================-+*+======================================---+##+=#-.
                   [email protected]@%[email protected]@@%+++++++++++++++++++++++++++%#++++++%#+++#@@@#[email protected]@%[email protected]#+.=+*@*+*@@@@*+++++++++++++++++++++++%@@@#+++#@@+++=
                    -*-#%@@%%%=*%@%*++=++=+==+=++=++=+=++=++==#@%#%#+++=+=*@%*+=+==+=+++%*[email protected]%%#%#++++*@%#++=++=++=++=+=++=++=+=+*%%*==*%@@@*:%=
                     :@:[email protected]@@@@@*+++%@@*+===========+*=========#@@========+#%==========*@========##*#*+=======*@##*======#@#+=======*#*============+#%++#@@%#@@#++=.
                      .*+=%@%*%@%##[email protected]@%#=-==-=--==*%=========*%==--=--=-====--=--=-=##=--=-=--%%%%%+=-=--=-=*%=--=--=-=#%=--=----=#%=--=-=--=-+%#+==#%@@*#%@=++.
                        +%.#@@###%@@@@@%*---------#@%########@%*---------------------##---------------------##---------%%*[email protected]@#---------+#@=#@@#[email protected]@%*++-
                        .:*+*%@#+=*%@@@*=-------=#%#=-------=%*---------=*#*--------#+=--------===--------=#%*-------=#%*[email protected]%#--------=%@@%#*+=-+#%*+*:.
       ====================%*[email protected]@%#==+##%@*[email protected]#[email protected]@*-------=*@[email protected]@*[email protected][email protected]=--------*@@+-------+#@@%#==---+#@.*%====================
     :*=--==================-:=#@@%*===+*@%+=============%%%@=========*%@*[email protected]+=--=====+%@[email protected][email protected]========*%@@+======%%%**+=---=%@#=:-====================-#-
       +++**%@@@#*****************@#*=---=##%@@@@@@@@@@@@@#**@@@@****************%@@*[email protected]#***********#@************************************+=------=*@#*********************@#+=+:
        .-##=*@@%*----------------+%@%=---===+%@@@@@@@*+++---%#++----------------=*@@*+++=-----------=+#=------------------------------------------+%+--------------------+#@[email protected]
         :%:#%#####+=-=-*@@+--=-==-=*@=--=-==-=*@@#*[email protected][email protected]%===-==----+-==-==--+*+-==-==---=*@@@@@@%#===-=-=+%@%-==-=-==-#@%=-==-==--+#@@@@@@@@@@@@*+++
        =*=#@#=----==-=-=++=--=-==-=*@=--=-==-=*@@[email protected]===-=--=-*@@*[email protected]=--=-==--+#@-==-==---+%-==-==---=+++#@@@#--==-=-=++++-=--=-===#%[email protected]@@%.#*
        +#:@%*===================++%#=========%@%=========#%=========+#@%+=======#%==========*@#=========*%=========+*+%@@@+========+*[email protected]@%+**+================*%#*=+=
       *++#@*+=++++++*#%*+++++=+++*%%++++=++++%%*=+++++++##*=++++=++=%@@++++=++=+#%++++=++++#%@=+++++++=*#*+++++++=#%@@@@@*++=++++=#%@*[email protected]#*****=+++++++=+++++*%@@+:=+=
    :=*=#%#@@@@#%@@@%#@@#++++++++++%%*+++++++++++++++++**@*+++++++++*%#++++++++=*##++++++++*%@%+++++++++##+++++++++#%%%%%%++++**#@@@@@**+++++++++++++++++=*%@@@%#@@@@#%@@@%#@++*:.
    #*:@#=-+%#+:=*@*[email protected]%#++++++++#%@@#*++++++++++++++#%@#*++++++++*@@#[email protected]#++++++++*@@#+++++++++##*+++++++++++++++++###@@@@++*@@#+++++++++++++++++++*@@#=:+#%[email protected]*=-+%*[email protected]=
    ++=#%#+%@@%=#%@%#+%%#++++++*#@@@%###**************@@@++++++++**#@##*********#*********#@@#++++++***@#******%@%#*++**#@@@%##+==+++=*#**********%%*++++++++#%#=%@@%+*%@%*+%#*=*-
     .-*+===========*@@+++++*%%%@@@++***************+.%%*++++#%%%@@%=:=******************[email protected]@#+++*%%@#==+***--*@%*++*%@@*===+**=--   -************[email protected]%%#++++++#@@@*==========*+-
        =*******##.#%#++++*%@@@%+==+=             *#-%@%**%%###*====**-               [email protected]:*@@##@###*==+**-.-#[email protected]@#*@##*==+***=                     =+=##%@*+++++*%@@#.#%******:
               ++++%#+++*#@@@@+++==.              **[email protected]@@%+++++++===-                 -+++#@@+++++++==:  :+++%@@+++++++==:                          [email protected]%##[email protected]@%++++
             :%:*%%****%@@%+==*-                .%==*====**+...                      #*.#+==***....    #+=#%+==****:.                                ..-*=*%@%#++*#%@=+%.
            -+++#%+#%@@@#++===                  [email protected]*++===-                            #%++===           %#+++===                                          =+++%@%##**@@*[email protected]:
          .%-=%@##@@%*==++                                                                                                                                 .*==+#@@%*%@%=*=.
         .+++#@@@@@*++==.                                                                                                                                    -==++#@@@@@@=+%
       .=*=%@@%%%#=*=.                                                                                                                                          .*+=%@@@@%+-#.
       @[email protected]@@%:++++.                                                                                                                                              -+++**@@#+*=:
    .-+=*#%%++*::.                                                                                                                                                  :+**=#%@#==#
    #*:@*+++=:                                                                                                                                                          [email protected]*++=:
  :*-=*=++..                                                                                                                                                             .=*=#*.%=
 +#.=+++:                                                                                                                                                                   ++++:+#
*+=#-::                                                                                                                                                                      .::*+=*

*/

contract ChainRunners is ERC721Enumerable, Ownable, ReentrancyGuard {
    mapping(uint256 => ChainRunnersTypes.ChainRunner) runners;

    address public renderingContractAddress;

    event GenerateRunner(uint256 indexed tokenId, uint256 dna);
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _reservedTokenIds;

    uint256 private constant MAX_RUNNERS = 10000;
    uint256 private constant FOUNDERS_RESERVE_AMOUNT = 85;
    uint256 private constant MAX_PUBLIC_RUNNERS =
        MAX_RUNNERS - FOUNDERS_RESERVE_AMOUNT;
    uint256 private constant MINT_PRICE = 0.05 ether;
    uint256 private constant MAX_PER_ADDRESS = 10;

    uint256 private constant MAX_PER_EARLY_ACCESS_ADDRESS = 5;

    uint256 private runnerZeroHash;
    uint256 private runnerZeroDNA;

    uint256 public earlyAccessStartTimestamp;
    uint256 public publicSaleStartTimestamp;

    mapping(address => bool) public isOnEarlyAccessList;
    mapping(address => uint256) public earlyAccessMintedCounts;
    mapping(address => uint256) private founderMintCountsRemaining;

    constructor() ERC721("Chain Runners", "RUN") {}

    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not open");
        _;
    }

    modifier whenEarlyAccessActive() {
        require(isEarlyAccessOpen(), "Early access not open");
        _;
    }

    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyOwner
    {
        renderingContractAddress = _renderingContractAddress;
    }

    function mintPublicSale(uint256 _count)
        external
        payable
        nonReentrant
        whenPublicSaleActive
        returns (uint256, uint256)
    {
        require(
            _count > 0 && _count <= MAX_PER_ADDRESS,
            "Invalid Runner count"
        );
        require(
            _tokenIds.current() + _count <= MAX_PUBLIC_RUNNERS,
            "All Runners have been minted"
        );
        require(
            _count * MINT_PRICE == msg.value,
            "Incorrect amount of ether sent"
        );

        uint256 firstMintedId = _tokenIds.current() + 1;

        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
            mint(_tokenIds.current());
        }

        return (firstMintedId, _count);
    }

    function mintEarlyAccess(uint256 _count)
        external
        payable
        nonReentrant
        whenEarlyAccessActive
        returns (uint256, uint256)
    {
        require(_count != 0, "Invalid Runner count");
        require(
            isOnEarlyAccessList[msg.sender],
            "Address not on Early Access list"
        );
        require(
            _tokenIds.current() + _count <= MAX_PUBLIC_RUNNERS,
            "All Runners have been minted"
        );
        require(
            _count * MINT_PRICE == msg.value,
            "Incorrect amount of ether sent"
        );

        uint256 userMintedAmount = earlyAccessMintedCounts[msg.sender] + _count;
        require(
            userMintedAmount <= MAX_PER_EARLY_ACCESS_ADDRESS,
            "Max Early Access count per address exceeded"
        );

        uint256 firstMintedId = _tokenIds.current() + 1;
        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
            mint(_tokenIds.current());
        }
        earlyAccessMintedCounts[msg.sender] = userMintedAmount;
        return (firstMintedId, _count);
    }

    function allocateFounderMint(address _addr, uint256 _count)
        public
        onlyOwner
        nonReentrant
    {
        founderMintCountsRemaining[_addr] = _count;
    }

    function founderMint(uint256 _count)
        public
        nonReentrant
        returns (uint256, uint256)
    {
        require(
            _count > 0 && _count <= MAX_PER_ADDRESS,
            "Invalid Runner count"
        );
        require(
            _reservedTokenIds.current() + _count <= FOUNDERS_RESERVE_AMOUNT,
            "All reserved Runners have been minted"
        );
        require(
            founderMintCountsRemaining[msg.sender] >= _count,
            "You cannot mint this many reserved Runners"
        );

        uint256 firstMintedId = MAX_PUBLIC_RUNNERS + _tokenIds.current() + 1;
        for (uint256 i = 0; i < _count; i++) {
            _reservedTokenIds.increment();
            mint(MAX_PUBLIC_RUNNERS + _reservedTokenIds.current());
        }
        founderMintCountsRemaining[msg.sender] -= _count;
        return (firstMintedId, _count);
    }

    function mint(uint256 tokenId) public {
        ChainRunnersTypes.ChainRunner memory runner;
        runner.dna = uint256(
            keccak256(
                abi.encodePacked(
                    tokenId,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        );

        _safeMint(msg.sender, tokenId);
        runners[tokenId] = runner;
    }

    function getRemainingEarlyAccessMints(address _addr)
        public
        view
        returns (uint256)
    {
        if (!isOnEarlyAccessList[_addr]) {
            return 0;
        }
        return MAX_PER_EARLY_ACCESS_ADDRESS - earlyAccessMintedCounts[_addr];
    }

    function getRemainingFounderMints(address _addr)
        public
        view
        returns (uint256)
    {
        return founderMintCountsRemaining[_addr];
    }

    function isPublicSaleOpen() public view returns (bool) {
        return
            block.timestamp >= publicSaleStartTimestamp &&
            publicSaleStartTimestamp != 0;
    }

    function isEarlyAccessOpen() public view returns (bool) {
        return
            !isPublicSaleOpen() &&
            block.timestamp >= earlyAccessStartTimestamp &&
            earlyAccessStartTimestamp != 0;
    }

    function addToEarlyAccessList(address[] memory toEarlyAccessList)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < toEarlyAccessList.length; i++) {
            isOnEarlyAccessList[toEarlyAccessList[i]] = true;
        }
    }

    function removeFromEarlyAccessList(address[] memory toRemove)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < toRemove.length; i++) {
            isOnEarlyAccessList[toRemove[i]] = false;
        }
    }

    function setPublicSaleTimestamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimestamp = timestamp;
    }

    function setEarlyAccessTimestamp(uint256 timestamp) external onlyOwner {
        earlyAccessStartTimestamp = timestamp;
    }

    function checkHash(string memory seed) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed)));
    }

    function configureRunnerZero(
        uint256 _runnerZeroHash,
        uint256 _runnerZeroDNA
    ) external onlyOwner {
        require(runnerZeroHash == 0, "Runner Zero has already been configured");
        runnerZeroHash = _runnerZeroHash;
        runnerZeroDNA = _runnerZeroDNA;
    }

    function mintRunnerZero(string memory seed) external {
        require(runnerZeroHash != 0, "Runner Zero has not been configured");
        require(!_exists(0), "Runner Zero has already been minted");
        require(checkHash(seed) == runnerZeroHash, "Incorrect seed");

        ChainRunnersTypes.ChainRunner memory runner;
        runner.dna = runnerZeroDNA;

        _safeMint(msg.sender, 0);
        runners[0] = runner;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (renderingContractAddress == address(0)) {
            return "";
        }

        IChainRunnersRenderer renderer = IChainRunnersRenderer(
            renderingContractAddress
        );
        return renderer.tokenURI(_tokenId, runners[_tokenId]);
    }

    function tokenURIForSeed(uint256 _tokenId, uint256 seed)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (renderingContractAddress == address(0)) {
            return "";
        }

        ChainRunnersTypes.ChainRunner memory runner;
        runner.dna = seed;

        IChainRunnersRenderer renderer = IChainRunnersRenderer(
            renderingContractAddress
        );
        return renderer.tokenURI(_tokenId, runner);
    }

    function getDna(uint256 _tokenId) public view returns (uint256) {
        return runners[_tokenId].dna;
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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