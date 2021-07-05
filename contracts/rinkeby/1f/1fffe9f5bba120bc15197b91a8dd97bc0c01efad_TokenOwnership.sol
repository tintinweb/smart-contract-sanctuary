/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/utils/[email protected]

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File @openzeppelin/contracts/utils/[email protected]

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File contracts/shared/ModifiedErc721.sol

/**
 * @author  @vonie610 (Twitter & Telegram) | @Nicca42 (GitHub)
 * @dev     Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721]
 *          Non-Fungible Token Standard, including the Metadata extension, but
 *          not including the Enumerable extension, which is available
 *          separately as {ERC721Enumerable}.
 * @notice  This contract was pulled out of the openzeppelin contract library
 *          and modified to allow for multiple token types to exist on one
 *          contract. This is required for treasure maps and coordinates to be
 *          retrieved and executed as gas effetely as possible.
 */
contract ModifiedErc721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private name_;

    // Token symbol
    string private symbol_;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners_;

    // Mapping of token ID to token type
    mapping(uint256 => bytes32) private tokenType_;
    // FUTURE could make mapping for all types allowing for permission-ed
    // minting of tokens, type creations and ownership.

    // Mapping of owners to token type to balance. 0 type is balance total.
    mapping(address => mapping(bytes32 => uint256)) private balances_;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals_;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals_;

    /**
     * @param   _name Name for token.
     * @param   _symbol Symbol for token.
     */
    constructor(string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
    }

    //--------------------------------------------------------------------------
    // EDITED
    //--------------------------------------------------------------------------
    // The below code is modified and added code in order to facilitate having
    // typed tokens.
    //
    // When minting tokens you now need to specify the token type. A view
    // function was also added for getting a tokens type.
    //
    // Additional notes:
    // A lot more grace can go into the way this is done, i.e
    // being able to approve an address as a spender of all your tokens of the
    // same price.
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // FUTURE IMPROVEMENTS (possibly make this an EIP?)
    //--------------------------------------------------------------------------
    // This contract can be significantly improved via the creation of the 
    // following public functions:
    // - `createTokenType(bytes32 _type, bool _publiclyMintable, bool _isBurnable)`
        // This function allows callers to add unique token types. Marking a 
        // token as not burnable will block burning and transfering to the 0x0
        // address. Making a type publicly mintable means that anyone can mint
        // a token of that type. If the token is not publicly mintable the
        // minter role can be controlled through:
        // - `addMinterForType(address _minter, bool _canMint)`
        // - `addMintControllerForType(address _controller, bool _canAddMinters)`
    // - `mint(bytes32 _type, address _to)`
        // Mints a new token (restricted by the token type and minter roles)
        // Enforces unique token IDs, keeps a count for total circulating supply
        // of each token type. 
    // - `burn(uint256 _tokenID)`
        // Allows for the burning of a token. If burning for the token type is
        // disabled this function will revert. 
    //--------------------------------------------------------------------------

    /**
     * @param   _owner Address of the owner.
     * @param   _type The type of token.
     * @return  uint256 How many tokens the owner has of the specified token 
     *          type.
     */
    function balanceOfType(address _owner, bytes32 _type)
        public
        view
        returns (uint256)
    {
        return balances_[_owner][_type];
    }

    /**
     * @param   _tokenID The ID of the token. 
     * @return  bytes32 The identifier for the token type.
     */
    function getTokenType(uint256 _tokenID) public view returns (bytes32) {
        return tokenType_[_tokenID];
    }

    /**
     * @param   _type The type of token being minted.
     * @param   _to The receiving address for the newly minted token.
     * @param   _tokenId The ID for the token. 
     * @dev     Safely mints `tokenId` and transfers it to `to`. If `to` refers 
     *          to a smart contract, it must implement 
     *          {IERC721Receiver-onERC721Received}, which is called upon a safe 
     *          transfer.
     */
    function _safeMint(
        bytes32 _type,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        _safeMint(_type, _to, _tokenId, "");
    }

    /**
     * @param   _type The type of token being minted.
     * @param   _to The receiving address for the newly minted token.
     * @param   _tokenId The ID for the token.
     * @dev     Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], 
     *          with an additional `data` parameter which is forwarded in 
     *          {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        bytes32 _type,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(_type, _to, _tokenId);
        require(
            _checkOnERC721Received(address(0), _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @param   _type The type of token being minted.
     * @param   _to The receiving address for the newly minted token.
     * @param   _tokenId The ID for the token.
     */
    function _mint(
        bytes32 _type,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(_type != bytes32(0), "ERC721: cannot mint without type");
        require(!_exists(_tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), _to, _tokenId);

        balances_[_to][bytes32(0)] += 1;
        balances_[_to][_type] += 1;
        tokenType_[_tokenId] = _type;
        owners_[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @param   _tokenId ID of the token to be destroyed. 
     */
    function _burn(uint256 _tokenId) internal virtual {
        address owner = this.ownerOf(_tokenId);

        _beforeTokenTransfer(owner, address(0), _tokenId);

        // Clear approvals
        _approve(address(0), _tokenId);

        bytes32 tokenType = tokenType_[_tokenId];

        balances_[owner][bytes32(0)] -= 1;
        balances_[owner][tokenType] -= 1;
        delete owners_[_tokenId];
        delete tokenType_[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    //--------------------------------------------------------------------------
    // UNEDITED OPENZEPPELIN CODE
    //--------------------------------------------------------------------------
    // Below is the mostly unchanged openzeppelin code for ERC721 
    // implementation. The only difference is how the mapping `balances_` is 
    // used and accessed, as it is now a 2D mapping.
    //--------------------------------------------------------------------------

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
        
        return balances_[owner][bytes32(0)];
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
        address owner = owners_[tokenId];
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
        return name_;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = this.ownerOf(tokenId);
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return tokenApprovals_[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        operatorApprovals_[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        return operatorApprovals_[owner][operator];
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
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return owners_[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = this.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        require(
            this.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        bytes32 tokenType = tokenType_[tokenId];

        balances_[from][tokenType] -= 1;
        balances_[from][bytes32(0)] -= 1;
        balances_[to][tokenType] += 1;
        balances_[to][bytes32(0)] += 1;
        owners_[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        tokenApprovals_[tokenId] = to;
        emit Approval(this.ownerOf(tokenId), to, tokenId);
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File contracts/treasure-plannet/ModifiedOwnership.sol

/**
 * @author  @vonie610 (Twitter & Telegram) | @Nicca42 (GitHub)
 * @author  @thornm9 (GitHub)
 * @notice  This contract has been modified away from the OZ standard Ownable in
 *          order to allow ownership to be represented by an NFT token.
 *          The owner of the NFT will have ownership rights over the owned 
 *          contract.
 * @dev     Contract module which provides a basic access control mechanism, 
 *          where there is an account (an owner) that can be granted exclusive 
 *          access to specific functions.
 *          This module is used through inheritance. It will make available the 
 *          modifier `onlyOwner`, which can be applied to your functions to 
 *          restrict their use to the owner.
 */
abstract contract ModifiedOwnership is Context {
    // Instance of the NFT token contract that represents ownership.
    ModifiedErc721 internal ownerTokenInstance_;
    // ID of the token that is the owner of contract.
    uint256 private ownerTokenID_;

    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(
        address _ownerTokenInstance,
        uint256 _ownerTokenID
    ) {
        ownerTokenID_ = _ownerTokenID;
        ownerTokenInstance_ = ModifiedErc721(_ownerTokenInstance);
        address currentOwner = ownerTokenInstance_.ownerOf(ownerTokenID_);
        emit OwnershipTransferred(address(0), currentOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns(address) {
        return ownerTokenInstance_.ownerOf(ownerTokenID_);
    }

    function isOwned() public view returns(bool) {
        return true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyToken() {
        require(
            _msgSender() == address(ownerTokenInstance_),
            "Ownable: ownership managed by token"
        );
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyToken() returns(bool) {
        emit OwnershipTransferred(
            ownerTokenInstance_.ownerOf(ownerTokenID_), 
            address(0)
        );

        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(
        address _newOwner
    ) 
        public 
        virtual 
        onlyToken() 
        returns(bool) 
    {
        require(
            _newOwner != address(0), 
            "Ownable: new owner is the zero address"
        );
        address currentOwner = ownerTokenInstance_.ownerOf(ownerTokenID_);
        emit OwnershipTransferred(currentOwner, _newOwner);

        return true;
    }
}

// File contracts/treasure-plannet/TokenOwnership.sol

/**
 * @author  @vonie610 (Twitter & Telegram) | @Nicca42 (GitHub)
 * @notice  This contract is the ownership token that works with the 
 *          `ModifiedOwnership` contract (which the owned contract MUST inherit).
 *          
 *          !! Transferring the ownership token transfers ownership rights to 
 *          the owned contract. 
 */
contract TokenOwnership is ModifiedErc721 {
    bytes32 constant OWNER_TOKEN = bytes32(keccak256("OWNER_TOKEN"));
    // Address of the factory contract.
    address public factory_;
    // Counter for token IDs. 
    uint256 public tokenIDCounter_;
    // Token ID     => Owned contract
    mapping(uint256 => address) public ownedContracts_;
    // Contract owner => Token ID
    mapping(address => uint256) public contractOwners_;

    modifier onlyFactory() {
        require(
            msg.sender == factory_,
            "Caller is not factory"
        );
        _;
    }

    constructor() 
        ModifiedErc721(
            "Owner Token",
            "OWT"
        )
    {

    }

    /**
     * @param   _owner Address of the owner. 
     * @return  address The address of the contract that the owner owns. 
     */
    function getOwnedContract(address _owner) external view returns(address) {
        uint256 tokenID = contractOwners_[_owner];
        return ownedContracts_[tokenID];
    }

    function getOwnerToken(address _owner) external view returns(uint256) {
        return contractOwners_[_owner];
    }

    /**
     * @param   _factory Address of the factory contract. 
     * @notice  The set factory address will be the only address able to mint
     *          and link minted tokens to their owned contracts. 
     *
     *          This function can only be called once. 
     *
     *          // FUTURE should probably have some kind of ownership setting so
     *          that the factory can transfer its minting rights.
     */
    function setFactory(address _factory) external {
        require(
            factory_ == address(0),
            "Factory has already been set"
        );
        factory_ = _factory;
    }

    /**
     * @param   _to Address receiving ownership token. 
     * @notice  All storage for owner to owned contract is handled in the 
     *          `_beforeTokenTransfer` function.
     *          Only the factory can mint tokens.
     */
    function mintOwnershipToken(
        address _to
    )
        external
        onlyFactory()
        returns(uint256 tokenID)
    {
        tokenIDCounter_ += 1;
        tokenID = tokenIDCounter_;

        // FUTURE this is just here to make it easier for the front end, you 
        // should be able to own more than one planet for sure. 
        require(
            contractOwners_[_to] == 0,
            "Owner has token"
        );

        _mint(
            OWNER_TOKEN,
            _to,
            tokenID
        );
    }

    /**
     * @param   _tokenID ID of the minted token.
     * @param   _ownedContract Address of the owned contract.
     * @notice  Only the factory can link owner tokens to owned contracts. 
     */
    function linkOwnershipToken(
        uint256 _tokenID,
        address _ownedContract
    )
        external
        onlyFactory()
    {
        ModifiedOwnership owned = ModifiedOwnership(_ownedContract);
        require(
            ownedContracts_[_tokenID] == address(0),
            "Ownership has already been linked"
        );
        require(
            owned.isOwned(),
            "Owned contract invalid"
        );
        ownedContracts_[_tokenID] = _ownedContract;
    }

    /**
     * @param   _from The address that the token is being moved from. If this is
     *          the 0x0 address, the token is being minted. 
     * @param   _to The address that the token is being moved to. If this is the
     *          0x0 address, the token is being burnt. 
     * @param   _tokenID The ID of the token. 
     * @notice  This hook is called within the ModifiedErc721 on mint, burn and
     *          all variations of transfer. Within this function the address of
     *          the current owner is tracked. 
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenID
    ) 
        internal 
        override 
    {
        ModifiedOwnership ownedContract = ModifiedOwnership(
            ownedContracts_[_tokenID]
        );
        if(_to == address(0)) {
            // If token is being burnt
            ownedContract.renounceOwnership();
            contractOwners_[address(0)] = _tokenID;

        } else if(_from == address(0)) {
            // If token is being minted
            contractOwners_[_to] = _tokenID;

        } else if(
            _from != address(0) &&
            _to != address(0)
        ) {
            // If token is being transferred
            ownedContract.transferOwnership(_to);
            contractOwners_[_from] = 0;
            contractOwners_[_to] = _tokenID;
        }
    }
}