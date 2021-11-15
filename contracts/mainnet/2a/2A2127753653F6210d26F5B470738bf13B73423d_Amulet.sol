// SPDX-License-Identifier: MIT
// Derived from OpenZeppelin's ERC721 implementation, with changes for gas-efficiency.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IAmulet.sol";
import "./ProxyRegistryWhitelist.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Amulet is IAmulet, ERC165, ProxyRegistryWhitelist {
    using Address for address;

    // Mapping from token ID to token data
    // Values are packed in the form:
    // [score (32 bits)][blockRevealed (64 bits)][owner (160 bits)]
    // This is equivalent to the following Solidity structure,
    // but saves us about 4200 gas on mint, 3600 gas on reveal,
    // and 140 gas on transfer.
    // struct Token {
    //   uint32 score;
    //   uint64 blockRevealed;
    //   address owner;
    // }
    mapping (uint256 => uint256) private _tokens;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    constructor (address proxyRegistryAddress, MintData[] memory premineMints, MintAndRevealData[] memory premineReveals) ProxyRegistryWhitelist(proxyRegistryAddress) {
        mintAll(premineMints);
        mintAndRevealAll(premineReveals);
    }

    /**************************************************************************
     * Opensea-specific methods
     *************************************************************************/

    function contractURI() external pure returns (string memory) {
        return "https://at.amulet.garden/contract.json";
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return "Amulets";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return "AMULET";
    }

    /**************************************************************************
     * ERC721 methods
     *************************************************************************/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155Metadata-uri}.
     */
    function uri(uint256 /*tokenId*/) public view virtual override returns (string memory) {
        return "https://at.amulet.garden/token/{id}.json";
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
        (address owner,,) = getData(id);
        if(owner == account) {
            return 1;
        }
        return 0;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
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
        require(msg.sender != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator] || isProxyForOwner(account, operator);
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
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );

        (address oldOwner, uint64 blockRevealed, uint32 score) = getData(id);
        require(amount == 1 && oldOwner == from, "ERC1155: Insufficient balance for transfer");
        setData(id, to, blockRevealed, score);

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
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
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: transfer caller is not owner nor approved"
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            (address oldOwner, uint64 blockRevealed, uint32 score) = getData(id);
            require(amount == 1 && oldOwner == from, "ERC1155: insufficient balance for transfer");
            setData(id, to, blockRevealed, score);
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    /**************************************************************************
     * Amulet-specific methods
     *************************************************************************/

    /**
     * @dev Returns the owner of the token with id `id`.
     */
    function ownerOf(uint256 id) external override view returns(address) {
        (address owner,,) = getData(id);
        return owner;
    }


    /**
     * @dev Returns the score of an amulet.
     *      0-3: Not an amulet
     *      4: common
     *      5: uncommon
     *      6: rare
     *      7: epic
     *      8: legendary
     *      9: mythic
     *      10+: beyond mythic
     */
    function getScore(string memory amulet) public override pure returns(uint32) {
        uint256 hash = uint256(sha256(bytes(amulet)));
        uint maxlen = 0;
        uint len = 0;
        for(;hash > 0; hash >>= 4) {
            if(hash & 0xF == 8) {
                len += 1;
                if(len > maxlen) {
                    maxlen = len;
                }
            } else {
                len = 0;
            }
        }
        return uint32(maxlen);        
    }

    /**
     * @dev Returns true if an amulet has been revealed.
     *      If this returns false, we cannot be sure the amulet even exists! Don't accept an amulet from someone
     *      if it's not revealed and they won't show you the text of the amulet.
     */
    function isRevealed(uint256 tokenId) external override view returns(bool) {
        (address owner, uint64 blockRevealed,) = getData(tokenId);
        require(owner != address(0), "ERC721: isRevealed query for nonexistent token");
        return blockRevealed > 0;
    }

    /**
     * @dev Mint a new amulet.
     * @param data The ID and owner for the new token.
     */
    function mint(MintData memory data) public override {
        require(data.owner != address(0), "ERC1155: mint to the zero address");
        require(_tokens[data.tokenId] == 0, "ERC1155: mint of existing token");

        _tokens[data.tokenId] = uint256(uint160(data.owner));
        emit TransferSingle(msg.sender, address(0), data.owner, data.tokenId, 1);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), data.owner, data.tokenId, 1, "");
    }

    /**
     * @dev Mint new amulets.
     * @param data The IDs and amulets for the new tokens.
     */
    function mintAll(MintData[] memory data) public override {
        for(uint i = 0; i < data.length; i++) {
            mint(data[i]);
        }
    }

    /**
     * @dev Reveals an amulet.
     * @param data The title, text, and offset URL for the amulet.
     */
    function reveal(RevealData calldata data) public override {
        require(bytes(data.amulet).length <= 64, "Amulet: Too long");
        uint256 tokenId = uint256(keccak256(bytes(data.amulet)));
        (address owner, uint64 blockRevealed, uint32 score) = getData(tokenId);
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "Amulet: reveal caller is not owner nor approved"
        );
        require(blockRevealed == 0, "Amulet: Already revealed");

        score = getScore(data.amulet);
        require(score >= 4, "Amulet: Score too low");

        setData(tokenId, owner, uint64(block.number), score);
        emit AmuletRevealed(tokenId, msg.sender, data.title, data.amulet, data.offsetURL);
    }

    /**
     * @dev Reveals multiple amulets
     * @param data The titles, texts, and offset URLs for the amulets.
     */
    function revealAll(RevealData[] calldata data) external override {
        for(uint i = 0; i < data.length; i++) {
            reveal(data[i]);
        }
    }

    /**
     * @dev Mint and reveal an amulet.
     * @param data The title, text, offset URL, and owner for the new amulet.
     */
    function mintAndReveal(MintAndRevealData memory data) public override {
        require(bytes(data.amulet).length <= 64, "Amulet: Too long");
        uint256 tokenId = uint256(keccak256(bytes(data.amulet)));
        (address owner,,) = getData(tokenId);
        require(owner == address(0), "ERC1155: mint of existing token");
        require(data.owner != address(0), "ERC1155: mint to the zero address");

        uint32 score = getScore(data.amulet);
        require(score >= 4, "Amulet: Score too low");

        setData(tokenId, data.owner, uint64(block.number), score);
        emit TransferSingle(msg.sender, address(0), data.owner, tokenId, 1);
        emit AmuletRevealed(tokenId, msg.sender, data.title, data.amulet, data.offsetURL);
    }

    /**
     * @dev Mint and reveal amulets.
     * @param data The titles, texts, offset URLs, and owners for the new amulets.
     */
    function mintAndRevealAll(MintAndRevealData[] memory data) public override {
        for(uint i = 0; i < data.length; i++) {
            mintAndReveal(data[i]);
        }
    }

    /**
     * @dev Returns the Amulet's owner address, the block it was revealed in, and its score.
     */
    function getData(uint256 tokenId) public override view returns(address owner, uint64 blockRevealed, uint32 score) {
        uint256 t = _tokens[tokenId];
        owner = address(uint160(t));
        blockRevealed = uint64(t >> 160);
        score = uint32(t >> 224);
    }

    /**
     * @dev Sets the amulet's owner address, reveal block, and score.
     */
    function setData(uint256 tokenId, address owner, uint64 blockRevealed, uint32 score) internal {
        _tokens[tokenId] = uint256(uint160(owner)) | (uint256(blockRevealed) << 160) | (uint256(score) << 224);
    }

    /**************************************************************************
     * Internal/private methods
     *************************************************************************/

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

interface IAmulet is IERC1155, IERC1155MetadataURI {
    event AmuletRevealed(uint256 indexed tokenId, address revealedBy, string title, string amulet, string offsetUrl);

    struct MintData {
        address owner;
        uint256 tokenId;
    }

    struct RevealData {
        string title;
        string amulet;
        string offsetURL;
    }

    struct MintAndRevealData {
        string title;
        string amulet;
        string offsetURL;
        address owner;
    }

    /**
     * @dev Returns the owner of the token with id `id`.
     */
    function ownerOf(uint256 id) external view returns(address);

    /**
     * @dev Returns the score of an amulet.
     *      0-3: Not an amulet
     *      4: common
     *      5: uncommon
     *      6: rare
     *      7: epic
     *      8: legendary
     *      9: mythic
     *      10+: beyond mythic
     */
    function getScore(string calldata amulet) external pure returns(uint32);

    /**
     * @dev Returns true if an amulet has been revealed.
     *      If this returns false, we cannot be sure the amulet even exists! Don't accept an amulet from someone
     *      if it's not revealed and they won't show you the text of the amulet.
     */
    function isRevealed(uint256 tokenId) external view returns(bool);

    /**
     * @dev Mint a new amulet.
     * @param data The ID and owner for the new token.
     */
    function mint(MintData calldata data) external;

    /**
     * @dev Mint new amulets.
     * @param data The IDs and amulets for the new tokens.
     */
    function mintAll(MintData[] calldata data) external;

    /**
     * @dev Reveals an amulet.
     * @param data The title, text, and offset URL for the amulet.
     */
    function reveal(RevealData calldata data) external;

    /**
     * @dev Reveals multiple amulets
     * @param data The titles, texts, and offset URLs for the amulets.
     */
    function revealAll(RevealData[] calldata data) external;

    /**
     * @dev Mint and reveal an amulet.
     * @param data The title, text, offset URL, and owner for the new amulet.
     */
    function mintAndReveal(MintAndRevealData calldata data) external;

    /**
     * @dev Mint and reveal amulets.
     * @param data The titles, texts, offset URLs, and owners for the new amulets.
     */
    function mintAndRevealAll(MintAndRevealData[] calldata data) external;

    /**
     * @dev Returns the Amulet's owner address, the block it was revealed in, and its score.
     */
    function getData(uint256 tokenId) external view returns(address owner, uint64 blockRevealed, uint32 score);
}

// SPDX-License-Identifier: MIT
// Derived from OpenZeppelin's ERC721 implementation, with changes for gas-efficiency.

pragma solidity ^0.8.0;

contract ProxyRegistry {
    mapping(address => address) public proxies;
}

contract ProxyRegistryWhitelist {
    ProxyRegistry public proxyRegistry;

    constructor(address proxyRegistryAddress) {
        proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    function isProxyForOwner(address owner, address caller) internal view returns(bool) {
        if(address(proxyRegistry) == address(0)) {
            return false;
        }
        return proxyRegistry.proxies(owner) == caller;
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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
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

