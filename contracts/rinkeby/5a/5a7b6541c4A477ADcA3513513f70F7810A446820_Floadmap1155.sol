// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../../flipmaps-app/contracts/Flipmap.sol";
import "./Flipdata.sol";
import "./Flipkey1155.sol";

contract Floadmap1155 is Context, ERC165, IERC1155, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Address for address;

    struct Quest {
        string clue;
        bytes32 answer;
        string feature;
        string keyword;
        string cipher;
        string card;
        uint256 keys;
    }

    uint256 public constant maxQuests = 12;
    uint256[13] public _solvedQuests;
    bool public initialized;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => uint256) private _totalSupply;

    mapping(uint256 => Quest)   public _quests;
    mapping(uint256 => string)  public _tokenPayload;

    Flipmap     private flipmap;
    Flipkey1155 private flipkey;
    Flipdata    private flipdata;

    event QuestUpdated(uint256 questId);
    event PayloadUpdated(uint256 tokenId);
    event QuestSolved(uint256 questId, uint256 tokenId, address solver);

    constructor(address _flipmapAddress, address _flipkeyAddress, address _flipdataAddress) {
        flipmap = Flipmap(_flipmapAddress);
        flipkey = Flipkey1155(_flipkeyAddress);
        flipdata = Flipdata(_flipdataAddress);

        for(uint i=0; i<maxQuests; i++) {
            _tokenIds.increment();
        }
    }

    function mint(uint256 id, address to) public onlyOwner {
        _mint(to, id, 1, bytes(""));
    }

    function lockInitialization() public onlyOwner {
        initialized = true;
    }

    function initializeBalance(uint256 tokenId, address[] calldata userAddresses, uint256[] calldata amounts) public onlyOwner {
        require(!initialized);
        uint256 total;
        for (uint256 i = 0; i < userAddresses.length; i++) {
            _balances[tokenId][userAddresses[i]] = amounts[i];
            unchecked {
                total += amounts[i];
            }
        }
        _totalSupply[tokenId] = total;
    }

    function setQuest(uint256 id, string memory clue, bytes32 answer, string memory feature, string memory keyword, string memory cipher, string memory card, uint256 keys) public onlyOwner {
        require(id <= maxQuests);
        Quest memory quest;
        quest.clue = clue;
        quest.answer = answer;
        quest.feature = feature;
        quest.keyword = keyword;
        quest.cipher = cipher;
        quest.card = card;
        quest.keys = keys;
        _quests[id] = quest;
        emit QuestUpdated(id);
    }

    function resetQuest(uint256 id) public onlyOwner {
        _solvedQuests[id] = 0;
    }

    function setPayload(uint256 id, string memory payload) public onlyOwner {
        _tokenPayload[id] = payload;
        emit PayloadUpdated(id);
    }

    function solveQuest(uint256 questId, string memory answer) public nonReentrant {
        require(balanceOf(msg.sender, questId) > 0);
        require(_solvedQuests[questId] == 0);
        require(checkQuest(questId, answer));

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _solvedQuests[questId] = tokenId;
        _burn(msg.sender, questId, 1);
        _mint(msg.sender, tokenId, 1, bytes(""));

        uint256 keys = _quests[questId].keys;
        if(keys > 1) {
            flipkey.mintRandomBatch(msg.sender, keys);
        } else {
            flipkey.mintRandom(msg.sender);
        }

        emit QuestSolved(questId, tokenId, msg.sender);
    }

    function checkQuest(uint256 questId, string memory answer) public view returns (bool) {
        bytes32 hashed = sha256(bytes(answer));
        if(hashed == _quests[questId].answer) {
            return true;
        }
        return false;
    }

    function getByOwner(address owner) view public returns(uint256[] memory ids, uint256[] memory result) {
        uint256 totalTokens;
        for(uint256 i = 0; i <= _tokenIds.current(); i++) {
            if(balanceOf(owner, i) > 0) {
                totalTokens++;
            }
        }
        result = new uint256[](totalTokens);
        ids = new uint256[](totalTokens);
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= _tokenIds.current(); t++) {
            if (balanceOf(owner, t) > 0) {
                result[resultIndex] += balanceOf(owner, t);
                ids[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function setFlipdataAddress(address _flipdata) public onlyOwner {
        flipdata = Flipdata(_flipdata);
    }

    function setFlipmapAddress(address _flipmap) public onlyOwner {
        flipmap = Flipmap(_flipmap);
    }

    function setFlipkeyAddress(address _flipkey) public onlyOwner {
        flipkey = Flipkey1155(_flipkey);
    }

    function uri(uint256 tokenId) public view returns (string memory) {
        uint solved;
        if(tokenId <=12) {
            solved = _solvedQuests[tokenId];
        }
        return flipdata.getJSON(tokenId, _quests[tokenId], solved, _tokenPayload[tokenId]);
    }

    function toString(uint256 value) public pure returns (string memory) {
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
     *      ************    START OF SUPPLY INCLUDE    ************
     **/

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /**
     *      ************    START OF ERC1155 INCLUDE    ************
     **/

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
    ) internal virtual {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
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

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../blitmaps/contracts/Blitmap.sol";

contract Flipmap is ERC721, ReentrancyGuard {

    uint256 public _tokenId = 1700;

    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }

    struct VariantParents {
        uint256 tokenIdA;
        uint256 tokenIdB;
    }

    mapping(uint256 => VariantParents) private _tokenParentIndex;
    mapping(bytes32 => bool) private _tokenPairs;
    mapping(address => uint256) private _creators;

    address sara    = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address lambo   = 0xafBDEc0ba91FDFf03A91CbdF07392e6D72d43712;
    address dev     = 0xE424E566BFc3f7aDDFfb17862637DD61e2da3bE2;

    Blitmap blitmap;

    address private _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address _blitAddress) ERC721("Flipmap", "FLIP") {
        _owner = msg.sender;
        blitmap = Blitmap(_blitAddress);
    }

    function transferOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenId - 1700;
    }

    function savePairs(uint256[][] memory pairHashes) public onlyOwner {
        for(uint256 i=0; i<pairHashes.length; i++) {
            bytes32 pairHash = keccak256(abi.encodePacked(pairHashes[i][0], '-', pairHashes[i][1]));
            _tokenPairs[pairHash] = true;
        }
    }

    function mintVariant(uint256 tokenIdA, uint256 tokenIdB) public nonReentrant payable {
        require(msg.value == 0.03 ether);
        require(tokenIdA != tokenIdB, "b:08");
        require(blitmap.tokenIsOriginal(tokenIdA) && blitmap.tokenIsOriginal(tokenIdB), "b:10");

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, '-', tokenIdB));
        require(_tokenPairs[pairHash] == false, "b:11");

        uint256 variantTokenId = _tokenId;
        _tokenId++;

        VariantParents memory parents;
        parents.tokenIdA = tokenIdA;
        parents.tokenIdB = tokenIdB;

        address creatorA = blitmap.tokenCreatorOf(tokenIdA);
        address creatorB = blitmap.tokenCreatorOf(tokenIdB);

        _tokenParentIndex[variantTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, variantTokenId);

        _creators[creatorA]     += .0065625 ether;
        _creators[creatorB]     += .0009375 ether;
        _creators[sara]         += .0075 ether;
        _creators[lambo]        += .0075 ether;
        _creators[dev]          += .0075 ether;
    }

    function availableBalanceForCreator(address creatorAddress) public view returns (uint256) {
        return _creators[creatorAddress];
    }

    function withdrawAvailableBalance() public nonReentrant {
        uint256 withdrawAmount = _creators[msg.sender];
        _creators[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }

    function getByOwner(address owner) view public returns(uint256[] memory result) {
        result = new uint256[](balanceOf(owner));
        uint256 resultIndex = 0;
        for (uint256 t = 0; t < _tokenId; t++) {
            if (_exists(t) && ownerOf(t) == owner) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function pairIsTaken(uint256 tokenIdA, uint256 tokenIdB) public view returns (bool) {
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, '-', tokenIdB));
        return _tokenPairs[pairHash];
    }

    function currentTokenId() public view returns (uint256) {
        return _tokenId;
    }

    function tokenIsOriginal(uint256 tokenId) public view returns (bool) {
        if(tokenId < 1700) {
            return blitmap.tokenIsOriginal(tokenId);
        }
        return false;
    }

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        if (tokenId < 1700) {
            return blitmap.tokenDataOf(tokenId);
        }

        bytes memory tokenParentData;
        if(_exists(tokenId)) {
            tokenParentData = blitmap.tokenDataOf(_tokenParentIndex[tokenId].tokenIdA);
            bytes memory tokenPaletteData = blitmap.tokenDataOf(_tokenParentIndex[tokenId].tokenIdB);
            for (uint8 i = 0; i < 12; ++i) {
                // overwrite palette data with parent B's palette data
                tokenParentData[i] = tokenPaletteData[i];
            }
        }

        return tokenParentData;
    }

    function tokenParentsOf(uint256 tokenId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(tokenId));
        return (_tokenParentIndex[tokenId].tokenIdA, _tokenParentIndex[tokenId].tokenIdB);
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function uintToHexString(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
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

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }

    function colorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }

    function pixel4(string[32] memory lookup, SVGCursor memory pos) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect fill="', pos.color1, '" x="', lookup[pos.x], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
            '<rect fill="', pos.color2, '" x="', lookup[pos.x + 1], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',

            string(abi.encodePacked(
                '<rect fill="', pos.color3, '" x="', lookup[pos.x + 2], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
                '<rect fill="', pos.color4, '" x="', lookup[pos.x + 3], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />'
            ))
        ));
    }

    function parentSvgDataOf(uint256 tokenIdA, uint256 tokenIdB) public view returns (string memory) {
        bytes memory tokenParentData = blitmap.tokenDataOf(tokenIdA);
        bytes memory tokenPaletteData = blitmap.tokenDataOf(tokenIdB);
        for (uint8 i = 0; i < 12; ++i) {
            // overwrite palette data with parent B's palette data
            tokenParentData[i] = tokenPaletteData[i];
        }
        return tokenSvgData(tokenParentData);
    }

    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        bytes memory data = tokenDataOf(tokenId);
        return tokenSvgData(data);
    }

    function tokenSvgData(bytes memory data) public pure returns (string memory) {
        string memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 1000 1000"><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32" shape-rendering="crispEdges"><g transform="translate(32, 0) scale(-1,1)">';

        string[32] memory lookup = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "10", "11", "12", "13", "14", "15",
        "16", "17", "18", "19", "20", "21", "22", "23",
        "24", "25", "26", "27", "28", "29", "30", "31"
        ];

        SVGCursor memory pos;

        string[4] memory colors = [
        string(abi.encodePacked("#", byteToHexString(data[0]), byteToHexString(data[1]), byteToHexString(data[2]))),
        string(abi.encodePacked("#", byteToHexString(data[3]), byteToHexString(data[4]), byteToHexString(data[5]))),
        string(abi.encodePacked("#", byteToHexString(data[6]), byteToHexString(data[7]), byteToHexString(data[8]))),
        string(abi.encodePacked("#", byteToHexString(data[9]), byteToHexString(data[10]), byteToHexString(data[11])))
        ];

        string[8] memory p;

        for (uint i = 12; i < 40; i += 8) {
            pos.color1 =  colors[colorIndex(data[i], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i], 0, 1)];
            p[0] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 1], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 1], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 1], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 1], 0, 1)];
            p[1] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 2], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 2], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 2], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 2], 0, 1)];
            p[2] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 3], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 3], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 3], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 3], 0, 1)];
            p[3] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 4], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 4], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 4], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 4], 0, 1)];
            p[4] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 5], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 5], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 5], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 5], 0, 1)];
            p[5] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 6], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 6], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 6], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 6], 0, 1)];
            p[6] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 7], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 7], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 7], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 7], 0, 1)];
            p[7] = pixel4(lookup, pos);
            pos.x += 4;

            svgString = string(abi.encodePacked(svgString, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]));

            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }

        svgString = string(abi.encodePacked(svgString, "</g></svg></svg>"));
        return svgString;
    }

    function tokenRGBColorsOf(uint256 tokenId) public view returns (BlitmapAnalysis.Colors memory) {
        return BlitmapAnalysis.tokenRGBColorsOf(tokenDataOf(tokenId));
    }

    function tokenSlabsOf(uint256 tokenId) public view returns (string[4] memory) {
        bytes memory data = tokenDataOf(tokenId);
        BlitmapAnalysis.Colors memory rgb = BlitmapAnalysis.tokenRGBColorsOf(data);

        string[4] memory chars = [unicode"◢", unicode"◣", unicode"◤", unicode"◥"];
        string[4] memory slabs;

        slabs[0] = chars[(rgb.r[0] + rgb.g[0] + rgb.b[0]) % 4];
        slabs[1] = chars[(rgb.r[1] + rgb.g[1] + rgb.b[1]) % 4];
        slabs[2] = chars[(rgb.r[2] + rgb.g[2] + rgb.b[2]) % 4];
        slabs[3] = chars[(rgb.r[3] + rgb.g[3] + rgb.b[3]) % 4];

        return slabs;
    }

    function tokenAffinityOf(uint256 tokenId) public view returns (string[3] memory) {
        return BlitmapAnalysis.tokenAffinityOf(tokenDataOf(tokenId));
    }

    function makeAttributes(uint256 tokenId) public view returns (string memory attributes) {
        string[5] memory traits;

        uint256 parentA = _tokenParentIndex[tokenId].tokenIdA;
        uint256 parentB = _tokenParentIndex[tokenId].tokenIdB;

        traits[0] = '{"trait_type":"Type","value":"Flipling"}';
        traits[1] = string(abi.encodePacked('{"trait_type":"Composition","value":"', blitmap.tokenNameOf(parentA), ' (#', toString(parentA), ')"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"Palette","value":"', blitmap.tokenNameOf(parentB), ' (#', toString(parentB), ')"}'));

        string[3] memory affinity = tokenAffinityOf(tokenId);
        traits[3] = string(abi.encodePacked('{"trait_type":"Affinity","value":"', affinity[0]));
        if(bytes(affinity[1]).length > 0) {
            traits[3] = string(abi.encodePacked(traits[3], ', ', affinity[1]));
        }
        if(bytes(affinity[2]).length > 0) {
            traits[3] = string(abi.encodePacked(traits[3], ', ', affinity[2]));
        }
        traits[3] = string(abi.encodePacked(traits[3], '"}'));

        string[4] memory slabs = tokenSlabsOf(tokenId);
        traits[4] = string(abi.encodePacked('{"trait_type":"Slabs","value":"', slabs[0], ' ', slabs[1], ' ', slabs[2], ' ', slabs[3], '"}'));

        attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2], ',', traits[3], ',', traits[4]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint256 parentA = _tokenParentIndex[tokenId].tokenIdA;
        uint256 parentB = _tokenParentIndex[tokenId].tokenIdB;

        string memory name = string(abi.encodePacked('#', toString(tokenId), ' - ', blitmap.tokenNameOf(parentA), ' ', blitmap.tokenNameOf(parentB)));
        string memory description = 'Flipmaps are the lost 8,300 Blitmaps, only flipped.';
        string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(tokenSvgDataOf(tokenId)))));
        string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "attributes": [', makeAttributes(tokenId), ']}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function toString(uint256 value) public pure returns (string memory) {
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
}


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../../flipmaps-app/contracts/Flipmap.sol";

contract Flipkey1155 is ERC1155, Ownable, ERC1155Supply {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool)    public _contracts;
    mapping(uint256 => bytes)   public _keys;

    Flipmap     private flipmap;

    modifier onlyContractOrOwner() {
        require(msg.sender == owner() || _contracts[msg.sender] == true);
        _;
    }

    constructor(address flipmapAddress) ERC1155("") {
        _keys[1] = hex"77c3fd0a0a0ac90808edf10e000000000000000000000000000000000000000000004000000000000001500000001400000554000003550000155500003575500055554000d50d540055554003540354001445000d5000d5000040000d4000d5000150003500003400000000350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[2] = hex"e06addeedc17d17b1af5f5f55a500000000005a570d000094000070d8f200025500008f28f200009400008f270d000955700070d5a50095555c005a500009540095c000000025500025500000000954009540000000009555570000000000095570000000000002570000000000000255000000000000025700000000000002570000000000000267000000000000026700000000000002670000000000000267000000000000026700000000000002650000000000000265550000000000026555000000000002650900000000000267000000000000026700000005a500026709005a570d000255550070d8f200025555008f28f200009700008f270d000000000070d5a500000000005a9";
        _keys[3] = hex"5612deffdd006f6cb70f0f0f00000000000000002aaaaaaaaaaaaaa82aaa00000000aaa82aa03ffffffc0aa82a83f555555fc2a82a8fd5555557f2a82a8f57ffffd5f2a82a8d5ffffff572a82a8f5ffffff5f2a82a83d7ffffd7caa82aa0f555555f0aa82aa83d5d757c2aa82aaa0ffd7ff0aaa82aaa800d7002aaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa0d70aaaaa82aaaa80d702aaaa82aaaa8fd7f2aaaa82aaaa8d5572aaaa82aaaa0fd7f0aaaa82aaaa3fd7fcaaaa82aaaa35555caaaa82aaaa3f55fcaaaa82aaaa0fd7f0aaaa82aaaa8d5572aaaa82aaaa8dff72aaaa82aaaa8fc3f2aaaa80000000000000000";
        _keys[4] = hex"db0a0af5ef4de6d14c0c0b090000000000000000000e000000000000003580000000000000d5600000003030035b580000000cc00d60d600030303003540358000cc000035800d600030000035603550000000000d589580000030300356560000000cc000d55800000003000035600000000000000d58000000000000035600000000000000d5800000000000003560000d000000000d58003580000000035600d60000000000d58358d00000000035635b58000000000d5b5563400303000356558d8000cc0000d595b6000030000035655800000000000d5b50000000000003560000000c0c0000d5800000033000003540000000c000000d000000000000000000000000000000000000";
        _keys[5] = hex"45af18b4b432e3e61e0a0a0a000000000000000000000000000000000000000000000000000003fabc00000000003d5a97f000000000faaaaa9c00000003eaaaaaa70000000fa5ffffa9c000003e9f0000fa7000003e9c00003a7000003e9c00003a7000003e9c00003a7000003e9c0000fa7000000fa70003e9c0000003e9fffea700000000faaaaa9c000000003eaaaa70000000000ff69fc00000000003f69c000000000000369c000000000000369c000000000000369c00000000000036aa700000000000f6aa700000000000f6a5c00000000000f69f000000000000f6aa700000000000f6aa70000000000036a5c00000000000379f0000000000000ff00000000000000000000000";
        _keys[6] = hex"c0f8a85a04c68785c294e51d55005500550055007f000000000000fc7a000000000000ac780000000000006c000000155400000100000055550000010000015ea540000100000d700950000140000d5c0558000040000d55555800004000035555600000400000d55580000000000035560000010000000d5800000100000001500000010000000d580000014000000d580000004000000d580000004000000dd800000040000035d800000000000009d800000100000035d80000010000000958000001000000015800000140000035d800000040000009d80000004000003558000000400000356800000039000002a000002d3a000000000000ad3f000000000000fd0055005500550055";
        _keys[7] = hex"77c3fd0a0a0ac90808edf10e000000000000000000000000000000000000000000004000000000000001500000001400000554000003550000015000003575500014450000d50d540055554003540354005555400d5000d5001445000d4000d5000040003500003400055400350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[8] = hex"77c3fd0a0a0ac90808edf10e000000000000000000000000000000000000000000008000000000000002a00000001400000aa80000035500002aaa000035755000aaaa8000d50d54002aaa0003540354000aa8000d5000d50002a0000d4000d5000080003500003400000000350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[9] = hex"77c3fd0a0a0ac90808edf10e000000000000000000000000000000000000000000000000000000000008080000001400002a2a000003550000aaaa800035755000aaaa8000d50d54002aaa0003540354000aa8000d5000d50002a0000d4000d5000080003500003400000000350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[10] = hex"3db18b262f4e6611280dd636000000000000000000000000000000000000000000004000000000000001500000001400000554000003550000155500003575500055554000d50d540055554003540354001445000d5000d5000040000d4000d5000150003500003400000000350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[11] = hex"63023ffd244be3c77999fb695a500000000005a570d000094000070d8f200025500008f28f200009400008f270d000955700070d5a50095555c005a500009540095c000000025500025500000000954009540000000009555570000000000095570000000000002570000000000000255000000000000025700000000000002570000000000000267000000000000026700000000000002670000000000000267000000000000026700000000000002650000000000000265550000000000026555000000000002650900000000000267000000000000026700000005a500026709005a570d000255550070d8f200025555008f28f200009700008f270d000000000070d5a500000000005a9";
        _keys[12] = hex"b9648e51eb8315d7aeba0f9200000000000000002aaaaaaaaaaaaaa82aaa00000000aaa82aa03ffffffc0aa82a83f555555fc2a82a8fd5555557f2a82a8f57ffffd5f2a82a8d5ffffff572a82a8f5ffffff5f2a82a83d7ffffd7caa82aa0f555555f0aa82aa83d5d757c2aa82aaa0ffd7ff0aaa82aaa800d7002aaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa0d70aaaaa82aaaa80d702aaaa82aaaa8fd7f2aaaa82aaaa8d5572aaaa82aaaa0fd7f0aaaa82aaaa3fd7fcaaaa82aaaa35555caaaa82aaaa3f55fcaaaa82aaaa0fd7f0aaaa82aaaa8d5572aaaa82aaaa8dff72aaaa82aaaa8fc3f2aaaa80000000000000000";
        _keys[13] = hex"8998ff0b1c58c7a1b645ee500000000000000000000e000000000000003580000000000000d5600000003030035b580000000cc00d60d600030303003540358000cc000035800d600030000035603550000000000d589580000030300356560000000cc000d55800000003000035600000000000000d58000000000000035600000000000000d5800000000000003560000d000000000d58003580000000035600d60000000000d58358d00000000035635b58000000000d5b5563400303000356558d8000cc0000d595b6000030000035655800000000000d5b50000000000003560000000c0c0000d5800000033000003540000000c000000d000000000000000000000000000000000000";
        _keys[14] = hex"a22085afe31bc0915c1a2f4c000000000000000000000000000000000000000000000000000003fabc00000000003d5a97f000000000faaaaa9c00000003eaaaaaa70000000fa5ffffa9c000003e9f0000fa7000003e9c00003a7000003e9c00003a7000003e9c00003a7000003e9c0000fa7000000fa70003e9c0000003e9fffea700000000faaaaa9c000000003eaaaa70000000000ff69fc00000000003f69c000000000000369c000000000000369c000000000000369c00000000000036aa700000000000f6aa700000000000f6a5c00000000000f69f000000000000f6aa700000000000f6aa70000000000036a5c00000000000379f0000000000000ff00000000000000000000000";
        _keys[15] = hex"b5f03bd02bac9bd9c9da259555005500550055007f000000000000fc7a000000000000ac780000000000006c000000155400000100000055550000010000015ea540000100000d700950000140000d5c0558000040000d55555800004000035555600000400000d55580000000000035560000010000000d5800000100000001500000010000000d580000014000000d580000004000000d580000004000000dd800000040000035d800000000000009d800000100000035d80000010000000958000001000000015800000140000035d800000040000009d80000004000003558000000400000356800000039000002a000002d3a000000000000ad3f000000000000fd0055005500550055";
        _keys[16] = hex"303227f489959d2ceee5ea87000000000000000000000000000000000000000000004000000000000001500000001400000554000003550000015000003575500014450000d50d540055554003540354005555400d5000d5001445000d4000d5000040003500003400055400350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[17] = hex"568180fc4d5fdee2ffe7d635000000000000000000000000000000000000000000008000000000000002a00000001400000aa80000035500002aaa000035755000aaaa8000d50d54002aaa0003540354000aa8000d5000d50002a0000d4000d5000080003500003400000000350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[18] = hex"853157fa4929b50205e8ed3c000000000000000000000000000000000000000000000000000000000008080000001400002a2a000003550000aaaa800035755000aaaa8000d50d54002aaa0003540354000aa8000d5000d50002a0000d4000d5000080003500003400000000350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[19] = hex"f86892bc2c334fb1caa057db000000000000000000000000000000000000000000004000000000000001500000001400000554000003550000155500003575500055554000d50d540055554003540354001445000d5000d5000040000d4000d5000150003500003400000000350000d5000000000d50035540000000035435555000000000d5550d54000000003d50035500000000034000d54000000000000035500000000000000d54000000000000035500000000000000d540000000000003555000000000000d75540000000000354d5500000000003503554000000000000d75400000000000354d000000000000d500000000000000d4000000000000000000000000000000000000";
        _keys[20] = hex"47fed02b7fd485f758ee15f55a500000000005a570d000094000070d8f200025500008f28f200009400008f270d000955700070d5a50095555c005a500009540095c000000025500025500000000954009540000000009555570000000000095570000000000002570000000000000255000000000000025700000000000002570000000000000267000000000000026700000000000002670000000000000267000000000000026700000000000002650000000000000265550000000000026555000000000002650900000000000267000000000000026700000005a500026709005a570d000255550070d8f200025555008f28f200009700008f270d000000000070d5a500000000005a9";
        _keys[21] = hex"1f0538cc365813256cfccab600000000000000002aaaaaaaaaaaaaa82aaa00000000aaa82aa03ffffffc0aa82a83f555555fc2a82a8fd5555557f2a82a8f57ffffd5f2a82a8d5ffffff572a82a8f5ffffff5f2a82a83d7ffffd7caa82aa0f555555f0aa82aa83d5d757c2aa82aaa0ffd7ff0aaa82aaa800d7002aaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa8d72aaaaa82aaaaa0d70aaaaa82aaaa80d702aaaa82aaaa8fd7f2aaaa82aaaa8d5572aaaa82aaaa0fd7f0aaaa82aaaa3fd7fcaaaa82aaaa35555caaaa82aaaa3f55fcaaaa82aaaa0fd7f0aaaa82aaaa8d5572aaaa82aaaa8dff72aaaa82aaaa8fc3f2aaaa80000000000000000";
        _keys[22] = hex"670887625341c1a58bfcfcfc5600000000000095580000000000002560000000000000098000000000000002000000955400000000000255550000000000096aa94000000000096aa94000000000095aa54000000000025ff50000000000025ff5000000000000955400000000000009400000000000000940000000600000094000000960000009400000096000000940000009600000094000000960000009400000090000025555400000000002402540000000000000950000000000000254000000000000095000000000000025424000000000009509400000000002555540000000000255554000008000000000000002600000000000000958000000000000255600000000000095";
        _keys[23] = hex"240aeb141414cf0202929fa0000000000000000000000000000000000000000d50000000000000d554000000000001555500000000000199d500000000000074d500000000000003540000000000000d500000000000003550000000000000d503500000000003540d5000000000035535400000000000d55500000000000035540000000000000d500000000000000d400000000000000d400000000000000d400000000000000d400000000000001555000000000000354d000000000000354000000000000355500000000000003540000000000003554d00000000000005550000000000000d400000000000000d40000000000000034000038000000000000000000000000000000000";
        _keys[24] = hex"eb0aa4f1f976ddb8970adceb0000000000000000000000000000000002800000000002800aa0000000000aa008200002800008200820002aa80008200820007d7d000820095000d7d7000950069000aaaa000a90041002aaaa800410041002aeba800410041002aaaa80041006a000aaaa0006a005600028280005600820000aa00008200820000690000820082000014000082009500005500009500a90000550000a9004100001400004100410000550000410041000055000041006a00001400006a0056000055000056008201555555008200820141450540820082000145050082008200014554008200aa0001451500aa0028014145054028000001554501500000000000000000000";

        flipmap = Flipmap(flipmapAddress);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyContractOrOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyContractOrOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function getKeyIds() internal pure returns (uint256[] memory keyIds) {
        keyIds = new uint256[](24);
        for(uint256 i=0; i<24; i++) {
            keyIds[i] = i+1;
        }
    }

    function mintRandom(address to) public onlyContractOrOwner {
        uint256 keyId = getRandomKey(random(string(abi.encodePacked(toString(block.timestamp)))));
        bytes memory data;
        mint(to, keyId, 1, data);
    }

    function mintRandomBatch(address to, uint256 amount) public onlyContractOrOwner {
        uint256[] memory amounts = new uint256[](24);
        for(uint256 i=0; i<amount; i++) {
            uint256 keyId = getRandomKey(random(string(abi.encodePacked(toString(block.timestamp), toString(i)))));
            amounts[keyId-1]++;
        }
        bytes memory data;
        mintBatch(to, getKeyIds(), amounts, data);
    }

    function setKeyData(uint256 key, bytes memory data) public onlyOwner {
        _keys[key] = data;
    }

    function addContract(address contractAddress) public onlyOwner {
        _contracts[contractAddress] = true;
    }

    function removeContract(address contractAddress) public onlyOwner {
        _contracts[contractAddress] = false;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getRandomKey(uint256 randomness) internal pure returns (uint256 key) {
        key = 1;
        for(uint256 i=24; i>1; i--) {
            if(randomness % (i+1) == 0) {
                key = i;
                break;
            }
        }
    }

    function getByOwner(address owner) view public returns(uint256[] memory ids, uint256[] memory result) {
        uint256 totalTokens;
        for(uint256 i = 0; i <= 24; i++) {
            if(balanceOf(owner, i) > 0) {
                totalTokens++;
            }
        }
        result = new uint256[](totalTokens);
        ids = new uint256[](totalTokens);
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= 24; t++) {
            if (balanceOf(owner, t) > 0) {
                result[resultIndex] += balanceOf(owner, t);
                ids[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        string memory name = string(abi.encodePacked('Key #', toString(tokenId)));
        string memory description = 'Flipkeys are used for quests in the Flipverse.';
        string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(makeSVG(tokenId)))));
        string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '"}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function makeSVG(uint256 tokenId) public view returns (string memory) {
        bytes memory data = _keys[tokenId];

        // Unflip
        string memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 1000 1000"><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32" shape-rendering="crispEdges"><g>';
        string memory svg = flipmap.tokenSvgData(data);
        svg = getSlice(279, bytes(svg).length, svg);
        svg = string(abi.encodePacked(svgString, svg));
        return svg;
    }

    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);
    }

    function toString(uint256 value) public pure returns (string memory) {
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

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Floadmap1155.sol";

contract Flipdata {

    struct Palette {
        string color1;
        string color2;
    }

    Palette[13] public palettes;

    uint256 maxLineLength = 30;

    constructor() {
        palettes[0] = Palette('#F4A5AE', '#F5D7E3');
        palettes[1] = Palette('#59C3C3', '#C2F261');
        palettes[2] = Palette('#25FE84', '#000000');
        palettes[3] = Palette('#5F658E', '#DBDCE5');
        palettes[4] = Palette('#FEE761', '#FD293C');
        palettes[5] = Palette('#3B996A', '#88DB60');
        palettes[6] = Palette('#6C0850', '#BF178E');
        palettes[7] = Palette('#A14A30', '#72342F');
        palettes[8] = Palette('#960DB6', '#E8A4F8');
        palettes[9] = Palette('#25FADB', '#FD2689');
        palettes[10] = Palette('#193D3F', '#C8EAC5');
        palettes[11] = Palette('#0B3870', '#0F5577');
        palettes[12] = Palette('#CAD2C5', '#EBEBEB');
    }

    function getJSON(uint256 tokenId, Floadmap1155.Quest memory quest, uint256 questSolved, string memory payload) public view returns (string memory) {
        string memory name = string(abi.encodePacked('#', toString(tokenId)));
        string memory description = 'Floadmaps are puzzles that need to be solved with prizes for the winner.';
        string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(makeSVG(tokenId, quest, questSolved, payload)))));
        string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "attributes": [', makeAttributes(tokenId, questSolved), ']}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function makeAttributes(uint256 tokenId, uint256 questSolved) public pure returns (string memory attributes) {
        if(tokenId > 12) {
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"Type","value":"Lore"}'));
        } else {
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"Type","value":"Quest"},'));
            bool solved;
            if(questSolved > 0) {
                solved = true;
            }
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"Solved","value":"', toStringBool(solved), '"}'));
        }
    }

    function makeSVG(uint256 tokenId, Floadmap1155.Quest memory quest, uint256 questSolved, string memory payload) public view returns (string memory svg) {
        svg = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 500 500" shape-rendering="crispEdges">';

        string memory color1;
        string memory color2;
        if(questSolved > 0) {
            color1 = palettes[12].color1;
            color2 = palettes[12].color2;
        } else if(tokenId > 12) {
            uint256 colorId = tokenId % 12;
            color1 = palettes[colorId].color1;
            color2 = palettes[colorId].color2;
        } else {
            color1 = palettes[tokenId-1].color1;
            color2 = palettes[tokenId-1].color2;
        }

        svg = string(abi.encodePacked(svg, '<rect fill="', color1, '" x="0" y="0" width="500" height="500"></rect>'));
        svg = string(abi.encodePacked(svg, '<rect fill="', color1, '" x="20" y="20" width="460" height="460" stroke="', color2, '" stroke-width="10"></rect>'));

        if(bytes(payload).length > 0) {
            uint256 lines = bytes(payload).length / maxLineLength;
            string memory text;
            uint256 y;
            for(uint256 i=0; i<=lines; i++) {
                y = 60 + 20*i;
                uint256 slice2 = (i+1)*maxLineLength;
                if(slice2 > bytes(payload).length) {
                    slice2 = bytes(payload).length;
                }
                text = getSlice(i*maxLineLength+1, slice2, payload);
                svg = string(abi.encodePacked(svg, '<text x="50%" y="', toString(y), 'px" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">', text, '</text>'));
            }
        } else if(tokenId > 12) {
            svg = string(abi.encodePacked(svg, '<text x="50%" y="50%" class="base" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">LORE COMING SOON</text>'));
        } else {
            string memory text;
            if(questSolved > 0) {
                text = 'SOLVED';
            } else {
                text = quest.clue;
            }

            string[6] memory parts;
            parts[0] = string(abi.encodePacked('<text x="50%" y="50" class="base" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">', quest.feature, '</text>'));
            parts[1] = string(abi.encodePacked('<text x="50%" y="50%" class="base" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">', text, '</text>'));
            parts[2] = string(abi.encodePacked('<text x="50%" y="460" class="base" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">', quest.keyword, '</text>'));
            parts[3] = string(abi.encodePacked('<text x="50" y="460" class="base" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">', quest.card, '</text>'));
            parts[4] = string(abi.encodePacked('<text x="450" y="460" class="base" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">', quest.cipher, '</text>'));
            parts[5] = string(abi.encodePacked('<text x="50" y="50" class="base" fill="', color2, '" font-family="monospace" font-size="20px" text-anchor="middle">', toString(tokenId), '</text>'));
            svg = string(abi.encodePacked(svg, parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        }

        svg = string(abi.encodePacked(svg, '</svg>'));
    }

    function toString(uint256 value) public pure returns (string memory) {
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

    function toStringBool(bool value) public pure returns (string memory) {
        if(value) {
            return "true";
        }
        return "false";
    }

    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);
    }

}

// SPDX-License-Identifier: Apache-2.0

/*
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright 2018 James Lockhart <[email protected]>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.8.0;

/**
 * Strings Library
 *
 * In summary this is a simple library of string functions which make simple
 * string operations less tedious in solidity.
 *
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 *
 * @author James Lockhart <[email protected]>
 */
library StringUtil {

    function titleCase(string memory _base)
    internal
    pure
    returns (string[] memory) {
        string[] memory components = split(_base, " ");
        for (uint8 i = 0; i < components.length; ++i) {
            if (length(components[i]) == 0) {
                continue;
            }
            string memory firstChar = substring(components[i], 1);
            string memory remainingChars = _substring(components[i], int(StringUtil.length(components[i]) - 1), 1);
            components[i] = string(abi.encodePacked(upper(firstChar), remainingChars));
        }

        return components;
    }

    /**
     * Concat (High gas cost)
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
    internal
    pure
    returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
    internal
    pure
    returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
    internal
    pure
    returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     *
     * Extracts the beginning part of a string based on the desired length
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
    internal
    pure
    returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     *
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    /**
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * @param _value The delimiter to split the string on which must be a single
     *               character
     * @return splitArr An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string memory _base, string memory _value)
    internal
    pure
    returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
    internal
    pure
    returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     *
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
    internal
    pure
    returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
    private
    pure
    returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
    private
    pure
    returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BlitmapAnalysis {
    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function tokenRGBColorsOf(bytes memory data) public pure returns (Colors memory) {
        Colors memory rgb;

        rgb.r[0] = byteToUint(data[0]);
        rgb.g[0] = byteToUint(data[1]);
        rgb.b[0] = byteToUint(data[2]);

        rgb.r[1] = byteToUint(data[3]);
        rgb.g[1] = byteToUint(data[4]);
        rgb.b[1] = byteToUint(data[5]);

        rgb.r[2] = byteToUint(data[6]);
        rgb.g[2] = byteToUint(data[7]);
        rgb.b[2] = byteToUint(data[8]);

        rgb.r[3] = byteToUint(data[9]);
        rgb.g[3] = byteToUint(data[10]);
        rgb.b[3] = byteToUint(data[11]);

        return rgb;
    }

    function tokenSlabsOf(bytes memory data) public pure returns (string[4] memory) {
        Colors memory rgb = tokenRGBColorsOf(data);

        string[4] memory chars = ["&#9698;", "&#9699;", "&#9700;", "&#9701;"];
        string[4] memory slabs;

        slabs[0] = chars[(rgb.r[0] + rgb.g[0] + rgb.b[0]) % 4];
        slabs[1] = chars[(rgb.r[1] + rgb.g[1] + rgb.b[1]) % 4];
        slabs[2] = chars[(rgb.r[2] + rgb.g[2] + rgb.b[2]) % 4];
        slabs[3] = chars[(rgb.r[3] + rgb.g[3] + rgb.b[3]) % 4];

        return slabs;
    }

    function tokenAffinityOf(bytes memory data) public pure returns (string[3] memory) {
        Colors memory rgb = tokenRGBColorsOf(data);

        uint r = rgb.r[0] + rgb.r[1] + rgb.r[2];
        uint g = rgb.g[0] + rgb.g[1] + rgb.g[2];
        uint b = rgb.b[0] + rgb.b[1] + rgb.b[2];

        string[3] memory essences;
        uint8 offset;

        if (r >= g && r >= b) {
            essences[offset] = "Fire";
            ++offset;

            if (g > 256) {
                essences[offset] = "Earth";
                ++offset;
            }

            if (b > 256) {
                essences[offset] = "Water";
                ++offset;
            }
        } else if (g >= r && g >= b) {
            essences[offset] = "Earth";
            ++offset;

            if (r > 256) {
                essences[offset] = "Fire";
                ++offset;
            }

            if (b > 256) {
                essences[offset] = "Water";
                ++offset;
            }
        } else if (b >= r && b >= g) {
            essences[offset] = "Water";
            ++offset;

            if (r > 256) {
                essences[offset] = "Fire";
                ++offset;
            }

            if (g > 256) {
                essences[offset] = "Earth";
                ++offset;
            }
        }

        if (offset == 1) {
            essences[0] = string(abi.encodePacked(essences[0], " III"));
        } else if (offset == 2) {
            essences[0] = string(abi.encodePacked(essences[0], " II"));
            essences[1] = string(abi.encodePacked(essences[1], " I"));
        } else if (offset == 3) {
            essences[0] = string(abi.encodePacked(essences[0], " I"));
            essences[1] = string(abi.encodePacked(essences[1], " I"));
            essences[2] = string(abi.encodePacked(essences[2], " I"));
        }

        return essences;
    }
}

/*
______ _     _____ _____
| ___ \ |   |_   _|_   _|
| |_/ / |     | |   | |
| ___ \ |     | |   | |
| |_/ / |_____| |_  | |
\____/\_____/\___/  \_/
___  ___  ___  ______
|  \/  | / _ \ | ___ \
| .  . |/ /_\ \| |_/ /
| |\/| ||  _  ||  __/
| |  | || | | || |
\_|  |_/\_| |_/\_|

by dom hofmann and friends
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./blitmap-analysis.sol";
import "./string-util.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Blitmap is ERC721Enumerable {
    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct VariantParents {
        uint256 tokenIdA;
        uint256 tokenIdB;
    }

    struct Creator {
        string name;
        bool isAllowed;
        uint256 availableBalance;
        uint8 remainingMints;
    }

    struct TokenMetadata {
        string name;
        address creator;
        uint8 remainingVariants;
    }

    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }

    address private _owner;
    mapping (address => Creator) private _allowedList;
    event AddedToAllowedList(address indexed account);
    event RemovedFromAllowedList(address indexed account);
    event Published();
    event MetadataChanged(uint256 indexed tokenId, TokenMetadata indexed newMetadata);

    mapping(uint256 => VariantParents) private _tokenParentIndex;
    mapping(bytes32 => bool) private _tokenPairs;

    bytes[] private _tokenDataIndex;
    TokenMetadata[] private _tokenMetadataIndex;

    string private _uriPrefix;

    uint8 private _numOriginals;
    uint8 private constant _maxNumOriginals = 128;
    uint8 private constant _maxNumVariants = 16;

    bool public published;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier onlyAllowed() {
        require(isAllowed(msg.sender));
        _;
    }

    constructor() ERC721("Blitmap", "BLIT") {
        _owner = msg.sender;

        published = false;

        setBaseURI("https://api.blitmap.com/v1/metadata/");

        addAllowed(msg.sender, "sara", 128);
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _uriPrefix;
    }

    function setBaseURI(string memory prefix) public onlyOwner {
        _uriPrefix = prefix;
    }

    function addAllowed(address _address, string memory name, uint8 allowedMints) public onlyOwner {
        Creator memory creator;
        creator.name = name;
        creator.isAllowed = true;
        creator.remainingMints = allowedMints;
        _allowedList[_address] = creator;
        emit AddedToAllowedList(_address);
    }

    function changeMetadataOf(uint256 tokenId, TokenMetadata memory newMetadata) public onlyOwner {
        require(published == false, "b:01"); // only allow changes prior to publishing
        _tokenMetadataIndex[tokenId] = newMetadata;
        emit MetadataChanged(tokenId, newMetadata);
    }

    function publish() public onlyOwner {
        published = true;
        emit Published();
    }

    /*
    function removeAllowed(address _address) public onlyOwner {
        _allowedList[_address].isAllowed = false;
        emit RemovedFromAllowedList(_address);
    }
    */

    function isAllowed(address _address) public view returns (bool) {
        return _allowedList[_address].isAllowed == true;
    }

    function creatorNameOf(address _address) public view returns (string memory) {
        return _allowedList[_address].name;
    }

    function mintOriginal(bytes memory tokenData, string memory name) public onlyAllowed {
        require(published == false, "b:01");
        require(_numOriginals < _maxNumOriginals, "b:03");
        require(tokenData.length == 268, "b:04"); // any combination of 268 bytes is technically a valid blit
        require(bytes(name).length > 0 && bytes(name).length < 11, "b:05");
        require(_allowedList[msg.sender].remainingMints > 0, "b:06");

        uint256 tokenId = totalSupply();

        _tokenDataIndex.push(tokenData);

        TokenMetadata memory metadata;
        metadata.name = name;
        metadata.remainingVariants = _maxNumVariants;
        metadata.creator = msg.sender;
        _allowedList[msg.sender].remainingMints--;
        _tokenMetadataIndex.push(metadata);

        _numOriginals++;

        _safeMint(msg.sender, tokenId);
    }

    /*
    function remainingNumOriginals() public view returns (uint8) {
        return _maxNumOriginals - _numOriginals;
    }

    function remainingNumMints(address _address) public view returns (uint8) {
        return _allowedList[_address].remainingMints;
    }

    function allowedNumOriginals() public pure returns (uint8) {
        return _maxNumOriginals;
    }

    function allowedNumVariants() public pure returns (uint8) {
        return _maxNumVariants;
    }

    function availableBalanceForCreator(address creatorAddress) public view returns (uint256) {
        return _allowedList[creatorAddress].availableBalance;
    }

    function withdrawAvailableBalance() public onlyAllowed {
        uint256 withdrawAmount = _allowedList[msg.sender].availableBalance;
        _allowedList[msg.sender].availableBalance = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }
    */

    function mintVariant(uint256 tokenIdA, uint256 tokenIdB) public payable {
        require(msg.value == 0.1 ether);
        require(published == true, "b:02");
        require(_exists(tokenIdA) && _exists(tokenIdB), "b:07");
        require(tokenIdA != tokenIdB, "b:08");
        require(tokenRemainingVariantsOf(tokenIdA) > 0, "b:09");
        require(tokenIsOriginal(tokenIdA) && tokenIsOriginal(tokenIdB), "b:10");

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, tokenIdB));
        require(_tokenPairs[pairHash] == false, "b:11");

        uint256 variantTokenId = totalSupply();

        VariantParents memory parents;
        parents.tokenIdA = tokenIdA;
        parents.tokenIdB = tokenIdB;

        _tokenMetadataIndex[tokenIdA].remainingVariants--;

        // don't need to write real data here since we can assemble sibling data from parent data
        _tokenDataIndex.push(hex"00");

        TokenMetadata memory metadata;
        metadata.name = "";
        metadata.remainingVariants = 0;
        metadata.creator = msg.sender;
        _tokenMetadataIndex.push(metadata);

        _tokenParentIndex[variantTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, variantTokenId);

        _allowedList[_tokenMetadataIndex[tokenIdA].creator].availableBalance += 0.0875 ether;
        _allowedList[_tokenMetadataIndex[tokenIdB].creator].availableBalance += 0.0125 ether;
    }

    function tokenNameOf(uint256 tokenId) public view returns (string memory) {
        string memory name;
        if (tokenIsOriginal(tokenId)) {
            name = _tokenMetadataIndex[tokenId].name;
        } else {
            VariantParents memory parents = _tokenParentIndex[tokenId];
            name = string(abi.encodePacked(tokenNameOf(parents.tokenIdA), " ", tokenNameOf(parents.tokenIdB)));
        }

        string[] memory components = StringUtil.titleCase(name);
        string memory titleCaseName;
        for (uint8 i = 0; i < components.length; ++i) {
            if (i == 0) {
                titleCaseName = components[i];
            } else {
                titleCaseName = string(abi.encodePacked(titleCaseName, " ", components[i]));
            }
        }

        return titleCaseName;
    }

    function tokenIsOriginal(uint256 tokenId) public view returns (bool) {
        return (_tokenDataIndex[tokenId].length == 268);
    }

    function tokenParentsOf(uint256 tokenId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(tokenId));
        return (_tokenParentIndex[tokenId].tokenIdA, _tokenParentIndex[tokenId].tokenIdB);
    }

    function tokenCreatorOf(uint256 tokenId) public view returns (address) {
        return _tokenMetadataIndex[tokenId].creator;
    }

    /*
    function tokenCreatorNameOf(uint256 tokenId) public view returns (string memory) {
        return _allowedList[tokenCreatorOf(tokenId)].name;
    }
    */

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        bytes memory data = _tokenDataIndex[tokenId];
        if (tokenIsOriginal(tokenId)) {
            return data;
        }

        bytes memory tokenParentData = _tokenDataIndex[_tokenParentIndex[tokenId].tokenIdA];
        bytes memory tokenPaletteData = _tokenDataIndex[_tokenParentIndex[tokenId].tokenIdB];
        for (uint8 i = 0; i < 12; ++i) {
            // overwrite palette data with parent B's palette data
            tokenParentData[i] = tokenPaletteData[i];
        }

        return tokenParentData;
    }

    function tokenRemainingVariantsOf(uint256 tokenId) public view returns (uint256) {
        if (!tokenIsOriginal(tokenId)) {
            return 0;
        }
        return _tokenMetadataIndex[tokenId].remainingVariants;
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function uintToHexString(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
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

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }

    function colorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }

    function pixel4(string[32] memory lookup, SVGCursor memory pos) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<rect fill="', pos.color1, '" x="', lookup[pos.x], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
                '<rect fill="', pos.color2, '" x="', lookup[pos.x + 1], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',

                string(abi.encodePacked(
                    '<rect fill="', pos.color3, '" x="', lookup[pos.x + 2], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
                    '<rect fill="', pos.color4, '" x="', lookup[pos.x + 3], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />'
                ))
            ));
    }

    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        string memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32">';

        string[32] memory lookup = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "10", "11", "12", "13", "14", "15",
        "16", "17", "18", "19", "20", "21", "22", "23",
        "24", "25", "26", "27", "28", "29", "30", "31"
        ];

        SVGCursor memory pos;

        bytes memory data = tokenDataOf(tokenId);

        string[4] memory colors = [
        string(abi.encodePacked("#", byteToHexString(data[0]), byteToHexString(data[1]), byteToHexString(data[2]))),
        string(abi.encodePacked("#", byteToHexString(data[3]), byteToHexString(data[4]), byteToHexString(data[5]))),
        string(abi.encodePacked("#", byteToHexString(data[6]), byteToHexString(data[7]), byteToHexString(data[8]))),
        string(abi.encodePacked("#", byteToHexString(data[9]), byteToHexString(data[10]), byteToHexString(data[11])))
        ];

        string[8] memory p;

        for (uint i = 12; i < 268; i += 8) {
            pos.color1 =  colors[colorIndex(data[i], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i], 0, 1)];
            p[0] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 1], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 1], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 1], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 1], 0, 1)];
            p[1] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 2], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 2], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 2], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 2], 0, 1)];
            p[2] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 3], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 3], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 3], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 3], 0, 1)];
            p[3] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 4], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 4], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 4], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 4], 0, 1)];
            p[4] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 5], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 5], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 5], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 5], 0, 1)];
            p[5] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 6], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 6], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 6], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 6], 0, 1)];
            p[6] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 7], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 7], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 7], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 7], 0, 1)];
            p[7] = pixel4(lookup, pos);
            pos.x += 4;

            svgString = string(abi.encodePacked(svgString, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]));

            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }

        svgString = string(abi.encodePacked(svgString, "</svg>"));
        return svgString;
    }

    function tokenRGBColorsOf(uint256 tokenId) public view returns (BlitmapAnalysis.Colors memory) {
        return BlitmapAnalysis.tokenRGBColorsOf(tokenDataOf(tokenId));
    }

    function tokenSlabsOf(uint256 tokenId) public view returns (string[4] memory) {
        return BlitmapAnalysis.tokenSlabsOf(tokenDataOf(tokenId));
    }

    function tokenAffinityOf(uint256 tokenId) public view returns (string[3] memory) {
        return BlitmapAnalysis.tokenAffinityOf(tokenDataOf(tokenId));
    }
}

/*
errors:
01: This can only be done before the project has been published.
02: This can only be done after the project has been published.
03: The maximum number of originals has been minted.
04: Blitmaps must be exactly 268 bytes.
05: Blitmaps must have a title must be between 1 and 10 characters.
06: You have reached your quota for minted originals.
07: One of the originals in this combination doesn't exist.
08: An original cannot be combined with itself.
09: This original has sold out all of its siblings.
10: Both blitmaps in this combination must be originals.
11: A sibling with this combination already exists.
*/