/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

/*

 █     █░▒█████  ██▀███  ███▄    ██
▓█░ █ ░█▒██▒  ██▓██ ▒ ██▒▒██ ▀█   █
▒█░ █ ░█▒██░  ██▓██ ░▄█ ▒▓██  ▀█ ██▒
░█░ █ ░█▒██   ██▒██▀▀█▄ ▒▓██▒  ▐▌██▒
░░██▒██▓░ ████▓▒░██▓ ▒██▒▒██░   ▓██░
░ ▓░▒ ▒ ░ ▒░▒░▒░░ ▒▓ ░▒▓░░ ▒░   ▒ ▒
  ▒ ░ ░   ░ ▒ ▒░  ░▒ ░ ▒ ░ ░░   ░ ▒░
  ░   ░ ░ ░ ░ ▒   ░░   ░   ░   ░ ░
    ░       ░ ░    ░             ░

  by

 █     █░██░ ██ ██▄▄▄█████▓█████     ██▓    ██▓ ▄████ ██░ ██▄▄▄█████▓ ██████
▓█░ █ ░█▓██░ ██▓██▓  ██▒ ▓▓█   ▀    ▓██▒   ▓██▒██▒ ▀█▓██░ ██▓  ██▒ ▓▒██    ▒
▒█░ █ ░█▒██▀▀██▒██▒ ▓██░ ▒▒███      ▒██░   ▒██▒██░▄▄▄▒██▀▀██▒ ▓██░ ▒░ ▓██▄
░█░ █ ░█░▓█ ░██░██░ ▓██▓ ░▒▓█  ▄    ▒██░   ░██░▓█  ██░▓█ ░██░ ▓██▓ ░  ▒   ██▒
░░██▒██▓░▓█▒░██░██░ ▒██▒ ░░▒████▒   ░██████░██░▒▓███▀░▓█▒░██▓ ▒██▒ ░▒██████▒▒
░ ▓░▒ ▒  ▒ ░░▒░░▓   ▒ ░░  ░░ ▒░ ░   ░ ▒░▓  ░▓  ░▒   ▒ ▒ ░░▒░▒ ▒ ░░  ▒ ▒▓▒ ▒ ░
  ▒ ░ ░  ▒ ░▒░ ░▒ ░   ░    ░ ░  ░   ░ ░ ▒  ░▒ ░ ░   ░ ▒ ░▒░ ░   ░   ░ ░▒  ░ ░
  ░   ░  ░  ░░ ░▒ ░ ░        ░        ░ ░   ▒ ░ ░   ░ ░  ░░ ░ ░     ░  ░  ░
    ░    ░  ░  ░░            ░  ░       ░  ░░       ░ ░  ░  ░             ░

              ...
             ;::::;
           ;::::; :;
         ;:::::'   :;
        ;:::::;     ;.
       ,:::::'       ;           OOO\
       ::::::;       ;          OOOOO\
       ;:::::;       ;         OOOOOOOO
      ,;::::::;     ;'         / OOOOOOO
    ;:::::::::`. ,,,;.        /  / DOOOOOO
  .';:::::::::::::::::;,     /  /     DOOOO
 ,::::::;::::::;;;;::::;,   /  /        DOOO
;`::::::`'::::::;;;::::: ,#/  /          DOOO
:`:::::::`;::::::;;::: ;::#  /            DOOO
::`:::::::`;:::::::: ;::::# /              DOO
`:`:::::::`;:::::: ;::::::#/               DOO
 :::`:::::::`;; ;:::::::::##                OO
 ::::`:::::::`;::::::::;:::#                OO
 `:::::`::::::::::::;'`:;::#                O
  `:::::`::::::::;' /  / `:#
   ::::::`:::::;'  /  /   `#


* Copyright 2021
* SPDX-License-Identifier: MIT

A WebGL audiovisual artwork created by White Lights exploring the processes of
burnout and anxiety. Entirely generative, on-chain, and scalable to any
resolution. The waveform of White Lights’ song ‘Worn’ combined with the
viewer’s interactions determine the internal attributes of the piece in
real-time.

Arweave’s blockchain hosts the artwork’s source code on the permaweb, and
Ethereum’s blockchain stores its metadata on-chain within the NFT itself. The
contract additionally implements all of the latest high-security ERC721 and EIP
standards,  far exceeding those seen by larger platforms currently. This
technology makes the metadata and content impossible to lose, creating one of
the first genuinely permanent and decentralized generative pieces of 3D artwork.

The owner of this NFT can find the artwork's URL at anytime in numerous ways.
1. Follow the External URL on OpenSea.
2. Find this NFT's contract on Etherscan and then select [Contract ->
   Read Contract -> getArtworkURL -> Query]
3. Find this NFT's contract on Etherscan and then select [Contract ->
   Read Contract -> externalURL -> Query]
4. Follow the "artwork_url" property of the JSON Data URL returned by
   tokenURI(id)

*/

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


pragma solidity ^0.8.0;








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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
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
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol


pragma solidity ^0.8.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


pragma solidity ^0.8.0;


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
    constructor () {
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol


pragma solidity ^0.8.0;



/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// File: contracts/ERC2981.sol


pragma solidity ^0.8.4;


/**
 * @dev https://eips.ethereum.org/EIPS/eip-2981
 */
abstract contract ERC2981 is ERC165 {
  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;

  /// @notice Called with the sale price to determine how much royalty
  ///         is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _value - the sale price of the NFT asset specified by _tokenId
  /// @param _data - information used by extensions of this ERC.
  ///                Must not to be used by implementers of EIP-2981
  ///                alone.
  /// @return _receiver - address of who should be sent the royalty payment
  /// @return _royaltyAmount - the royalty payment amount for _value sale price
  /// @return _royaltyPaymentData - information used by extensions of this ERC.
  ///                               Must not to be used by implementers of
  ///                               EIP-2981 alone.
  function royaltyInfo(uint256 _tokenId, uint256 _value, bytes calldata _data) external virtual returns (address _receiver, uint256 _royaltyAmount, bytes memory _royaltyPaymentData);

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == _INTERFACE_ID_ERC2981
      || super.supportsInterface(interfaceId);
  }
}

// File: contracts/HasSecondarySaleFees.sol


pragma solidity ^0.8.4;


/**
 * @dev https://docs.rarible.com/asset/creating-an-asset/royalties-schema
 */
abstract contract HasSecondarySaleFees is ERC165 {

  event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);
  function getFeeBps(uint256 id) public view virtual returns (uint[] memory);

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == _INTERFACE_ID_FEES
      || super.supportsInterface(interfaceId);
  }
}

// File: contracts/WORN3POINTOH.sol


pragma solidity ^0.8.4;







/**
 * @title The WORN_3.0 NFT smart contract.
 *
 * @dev The $WORN_3.0 token implements full on-chain metadata in valid JSON
 * format. Anyone can retreive the data using the tokenURI() method, which
 * returns raw JSON data as a URI-encoded Data URL in UTF8 format. This avoids
 * the need for off-chain storage of any JSON metadata. The tradeoff is it
 * adds storage costs to this contract. The content of the art itself is stored
 * on Arweave --- the permanent or "permaweb" blockchain.
 *
 * This contract is ERC721 compliant, as well as ERC2981 and ERC165 compliant.
 * This contract allows tokens to burned, and transfers to be paused.
 * This contract implements FND/Rarible secondary sale fees.
 * This contract implements ERC2981 secondary sale fees.
 *
 *
 * @dev white lights is john shankman
 * Copyright 2021
 */
contract WORN3POINTOH is ERC721Burnable, ERC721Pausable, ERC2981, HasSecondarySaleFees, Ownable {
  address payable public withdrawalAddress;

  uint256 internal idToMintNext;
  uint256 internal maxNumberOfPieces;

  // HasSecondarySaleFees
  address payable royaltyRecipient;
  uint256 constant valueInBPS = 1000;

  // the hash for the artwork on Arweave
  string internal arweaveHash;
  // the hash for the still image preview on Arweave
  string internal arweaveImageHash;
  // the hash for the animated preview on Arweave
  string internal arweaveAnimationHash;
  // the external URL where you can purchase and trade the NFT
  string public externalURL;
  // Base URL that leads to Arweave, can be changed by Owner
  string public arweaveBaseURL;

  event Mint(address buyer, uint256 tokenId);
  event ArweaveBaseURLUpdated(string newBaseURL);

  constructor(
    uint256 givenMaxNumberOfPieces,
    string memory givenArweaveArtworkId,
    string memory givenArweaveImageId,
    string memory givenArweaveAnimationId,
    address payable givenWithdrawalAddress
  ) ERC721("WORN_3.0 by White Lights", "WORN_3.0") {
    maxNumberOfPieces = givenMaxNumberOfPieces;

    withdrawalAddress = givenWithdrawalAddress;
    royaltyRecipient = givenWithdrawalAddress;

    arweaveHash = givenArweaveArtworkId;
    arweaveImageHash = givenArweaveImageId;
    arweaveAnimationHash = givenArweaveAnimationId;

    arweaveBaseURL = 'https://www.arweave.net/';
    externalURL = getArtworkURL();

    idToMintNext = 0; // counter starts at 0

    mintArtwork();
  }

  /**
   * Supports ERC165, Rarible Secondary Sale Interface, and ERC721
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, HasSecondarySaleFees, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   *
   * @param tokenId the token ID
   * @return Base64 encoded URL containing the metadata for this token as JSON
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "DNE");
    return string(
      abi.encodePacked(
        'data:application/json;utf8,',
        getMetadata(tokenId)
      )
    );
  }

  /**
   * Returns the base URI for finding assets on Arweave chain.
   * This is settable by the owner of the contract.
   *
   * arweaveBaseURL + an_arweave_hash = functioning URL leading to asset
   *
   * arweaveBaseURL is NOT A CONSTANT because certain marketplaces don't know how
   * to follow a URL using 'arweave://' protocol. For now we allow the owner
   * to update and change this in case the 'https://arweave.net/' service dies
   * unexexpectedly, changes, or in te best case scenario whereplatforms begin
   * properly recognizing 'arweave://' the way 'ipfs://' is currently.
   */
  function setArweaveBaseURL(string memory _arweaveBaseURL) external onlyOwner {
    arweaveBaseURL = _arweaveBaseURL;
    emit ArweaveBaseURLUpdated(_arweaveBaseURL);
  }

  function setExternalURL(string memory url) external onlyOwner {
    externalURL = url;
  }

  function setWithdrawalAddress(address payable givenWithdrawalAddress) external onlyOwner {
    withdrawalAddress = givenWithdrawalAddress;
  }

  function withdrawFromEscrow() external onlyOwner {
    Address.sendValue(withdrawalAddress, address(this).balance);
  }

  /// @title lazy minting buy function
  // function buy() public payable {
  //   require(msg.value == pricePerPiece, "incorrect price");
  //   mintArtwork();
  // }

  /**
   * @dev This mints the 1/1 token.
   * @notice This will not work while the contract is paused.
   */
  function mintArtwork() internal {
    require(idToMintNext < maxNumberOfPieces, "sold out");

    emit Mint(msg.sender, idToMintNext);
    _safeMint(msg.sender, idToMintNext); // emits a Transfer event

    idToMintNext += 1;
  }

  function getArtworkURL() public view returns (string memory metadata) {
    return string(
      abi.encodePacked(
        arweaveBaseURL,
        arweaveHash
      )
    );
  }

  /**
   * @dev Given a token ID, return all on-chain metadata for the
   * token as a URI encoded JSON string.
   *
   * For each NFT, the following on-chain metadata is returned:
   *    - Name: The title of the art piece
   *    - Description: Details about the art piece
   *    - Creator: The creator of this token and art piece
   *    - External URL: The Arweave URL of the WebGL artwork
   *    - Image (URL): The Arweave URL location of the image preview
   *    - Animation (URL_: The Arweave URL location of the video preview
   *    - Artwork (URL): The Arweave URL of the WebGL artwork
   *    - Arweave Artwork Hash: Arweave storage hash of the actual WebGL piece
   *    - I've also included various metadata for the URLs like file format etc.
   *
   *    ATTRIBUTES (OpenSea):
   *    - Artist name: The artist
   *    - Editions: Edition related information for the token and overall.
   *    - Dimensions: The resolution or dimension of the work
   *    - Duration: The duration length of the work
   *    - Interactive: Shows up for interactivework
   *    - Burnout: Superficial
   *    - Anxiety: Superficial
   *
   * @notice Strings should be URI encoded UTF8 beforehand.
   * @notice arweaveBaseURL is not URI encoded but it works fine.
   *
   * @param tokenId the token ID
   * @return metadata a JSON string of the metadata
   */
  function getMetadata(uint256 tokenId) internal view virtual returns (string memory metadata) {
    require(_exists(tokenId), "DNE");

    return string(
      abi.encodePacked(
        // Name & Description & Created By
        '{"name":"WORN_3.0","created_by":"White%20Lights","description":"WORN_3.0%5Cn%5CnEdition%201%20of%201%5Cn%5CnA%20WebGL%20audiovisual%20artwork%20created%20by%20White%20Lights%20exploring%20the%20processes%20of%20burnout%20and%20anxiety.%20Entirely%20generative%2C%20on-chain%2C%20and%20scalable%20to%20any%20resolution.%20The%20waveform%20of%20White%20Lights%E2%80%99%20song%20%E2%80%98Worn%E2%80%99%20combined%20with%20the%20viewer%E2%80%99s%20interactions%20determine%20the%20internal%20attributes%20of%20the%20piece%20in%20real-time.%5Cn%5CnArweave%E2%80%99s%20blockchain%20hosts%20the%20artwork%E2%80%99s%20source%20code%20on%20the%20permaweb%2C%20and%20Ethereum%E2%80%99s%20blockchain%20stores%20its%20metadata%20on-chain%20within%20the%20NFT%20itself.%20This%20technology%20makes%20it%20one%20of%20the%20first%20genuinely%20permanent%2C%20decentralized%2C%20and%20generative%20pieces%20of%203D%20artwork.%5Cn%5Cn.html%20Format%5Cn%5CnInfinite%20Duration%20and%20Resolution%5Cn%5CnWebGL%2C%20JS%2C%20CSS%2C%20HTML%5Cn%5CnTo%20view%2C%20follow%20the%20External%20Link%20of%20this%20NFT%20when%20viewed%20on%20OpenSea.%20You%20may%20also%20retrieve%20the%20URL%20manually%20via%20public%20contract%20functions%20externalURL%2C%20getArtworkURL%2C%20and%20tokenURI.","external_url":"',
        externalURL,
        '",',

        // Image URL
        '"image":"', arweaveBaseURL, arweaveImageHash, '",',
        '"image_url":"', arweaveBaseURL, arweaveImageHash, '",',
        '"image_format":"png","image_height":3000,"image_width":3000,"image_sha256_checksum":"56dd351c0c949b47dd2d25a55762e770c2ed02b60bd1355d21e3391ac9227786",',

        // Animation URL
        '"animation":"', arweaveBaseURL, arweaveAnimationHash, '",',
        '"animation_url":"', arweaveBaseURL, arweaveAnimationHash, '",',
        '"animation_format":"mp4","animation_height":1080,"animation_width":1080,"animation_duration":15,"animation_sha256_checksum":"430b5788f641f5bcf6cea5f13a679ecbeb3e473a7de50956b3cf4e23b92cfc28",',

        // // Arweave Artwork Information
        '"artwork_arweave_hash":"', arweaveHash, '",',
        '"artwork_url":"', arweaveBaseURL, arweaveHash, '",',
        '"artwork_format":"html","artwork_sha256_checksum":"56dd351c0c949b47dd2d25a55762e770c2ed02b60bd1355d21e3391ac9227786","background_color":"000000","attributes":[{"trait_type":"Artist","value":"White%20Lights"},{"trait_type":"Edition","display_type":"number","value":1,"max_value":1},{"trait_type":"Dimensions","value":"Responsive"},{"trait_type":"Duration","value":"Infinite"},{"trait_type":"Interactive","value":"Interactive"},{"display_type":"boost_percentage","trait_type":"Burnout","value":100},{"display_type":"boost_percentage","trait_type":"Anxiety","value":100}]',
        // End object
        "}"
      )
    );


  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
   */
  function pause() public virtual onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   */
  function unpause() public virtual onlyOwner{
    _unpause();
  }

  /**
   * @dev Required for ERC721Pausable
   *
   * See {ERC721Pausable}
   */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /*
   * Rarible/Foundation Royalties Protocol
   */
  function getFeeRecipients(uint256 id) public view override returns (address payable[] memory) {
    require(_exists(id), "DNE");
    address payable[] memory result = new address payable[](1);
    result[0] = royaltyRecipient;
    return result;
  }

  function getFeeBps(uint256 id) public view override returns (uint[] memory) {
    require(_exists(id), "DNE");
    uint[] memory result = new uint[](1);
    result[0] = valueInBPS;
    return result;
  }

  /**
   * ERC2981 Royalties Standards (Mintable)
   */
  function royaltyInfo(uint256 _tokenId, uint256 _value, bytes calldata _data) external view override returns (address _receiver, uint256 _royaltyAmount, bytes memory _royaltyPaymentData) {
    return (withdrawalAddress, _value / 10, _data);
  }
}