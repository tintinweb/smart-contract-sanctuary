/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

//SPDX-License-Identifier: MIT Liscense
/*
   ,--,                                                                                                                              
,---.'|       ,----..                           ,--.                            ,--,                                 ,--.            
|   | :      /   /   \     ,---,              ,--.'|          .--.--.         ,--.'|   ,---,       ,-.----.      ,--/  /| .--.--.    
:   : |     /   .     :   '  .' \         ,--,:  : |         /  /    '.    ,--,  | :  '  .' \      \    /  \  ,---,': / '/  /    '.  
|   ' :    .   /   ;.  \ /  ;    '.    ,`--.'`|  ' :        |  :  /`. / ,---.'|  : ' /  ;    '.    ;   :    \ :   : '/ /|  :  /`. /  
;   ; '   .   ;   /  ` ;:  :       \   |   :  :  | |        ;  |  |--`  |   | : _' |:  :       \   |   | .\ : |   '   , ;  |  |--`   
'   | |__ ;   |  ; \ ; |:  |   /\   \  :   |   \ | :        |  :  ;_    :   : |.'  |:  |   /\   \  .   : |: | '   |  /  |  :  ;_     
|   | :.'||   :  | ; | '|  :  ' ;.   : |   : '  '; |         \  \    `. |   ' '  ; :|  :  ' ;.   : |   |  \ : |   ;  ;   \  \    `.  
'   :    ;.   |  ' ' ' :|  |  ;/  \   \'   ' ;.    ;          `----.   \'   |  .'. ||  |  ;/  \   \|   : .  / :   '   \   `----.   \ 
|   |  ./ '   ;  \; /  |'  :  | \  \ ,'|   | | \   |          __ \  \  ||   | :  | ''  :  | \  \ ,';   | |  \ |   |    '  __ \  \  | 
;   : ;    \   \  ',  / |  |  '  '--'  '   : |  ; .'         /  /`--'  /'   : |  : ;|  |  '  '--'  |   | ;\  \'   : |.  \/  /`--'  / 
|   ,/      ;   :    /  |  :  :        |   | '`--'          '--'.     / |   | '  ,/ |  :  :        :   ' | \.'|   | '_\.'--'.     /  
'---'        \   \ .'   |  | ,'        '   : |                `--'---'  ;   : ;--'  |  | ,'        :   : :-'  '   : |     `--'---'   
              `---`     `--''          ;   |.'                          |   ,/      `--''          |   |.'    ;   |,'                
                                       '---'                            '---'                      `---'      '---'                                                                                                                                                
*/

//Concept    by cca.eth
//Contract   by @alpineeth

/**
  ______ _____   _____   ______ ___  __     _____ _______       _   _ _____          _____  _____  
 |  ____|  __ \ / ____| |____  |__ \/_ |   / ____|__   __|/\   | \ | |  __ \   /\   |  __ \|  __ \ 
 | |__  | |__) | |   ______ / /   ) || |  | (___    | |  /  \  |  \| | |  | | /  \  | |__) | |  | |
 |  __| |  _  /| |  |______/ /   / / | |   \___ \   | | / /\ \ | . ` | |  | |/ /\ \ |  _  /| |  | |
 | |____| | \ \| |____    / /   / /_ | |   ____) |  | |/ ____ \| |\  | |__| / ____ \| | \ \| |__| |
 |______|_|  \_\\_____|  /_/   |____||_|  |_____/   |_/_/    \_\_| \_|_____/_/    \_\_|  \_\_____/ 
                                                                                                                                                                                                      
 */
 
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

/**
 * @dev Required interface of an ERC721 compliant contract.
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
/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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


/**
  _    _      _                   ______                _   _                 
 | |  | |    | |                 |  ____|              | | (_)                
 | |__| | ___| |_ __   ___ _ __  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
 |  __  |/ _ \ | '_ \ / _ \ '__| |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
 | |  | |  __/ | |_) |  __/ |    | |  | |_| | | | | (__| |_| | (_) | | | \__ \
 |_|  |_|\___|_| .__/ \___|_|    |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
               | |                                                            
               |_|                                                            
 */
library LoanSharksLib {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function toUInt(string memory _str) public pure returns (uint256 res) {
    
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        
        return res;
    }

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

    function subbyte(bytes memory strBytes, uint startIndex, uint endIndex) internal pure returns (bytes memory) {
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return result;
    }

  function class_replace(string memory str, string memory sub, string memory new_sub) internal pure returns (string memory) {
      bytes memory strBytes = bytes(str);
      bytes memory subBytes = bytes(sub);
      bytes memory nsubBytes = bytes(new_sub);
      for (uint i = 0; i < strBytes.length-2; i++){
        bytes memory testByte = abi.encodePacked(strBytes[i], strBytes[i+1], strBytes[i+2]);
        if(keccak256(testByte) == keccak256(subBytes)){
            return string(abi.encodePacked(subbyte(strBytes, 0, i),  nsubBytes, subbyte(strBytes, i+3, strBytes.length)));
        }
      }
      //No match; Return original string
      return str;
    }
    
    function seededBetween(uint bottom, uint top, uint _seed) internal pure returns (uint) {
        return (_seed % top) >= bottom ? (_seed % (top)) : (_seed % (top))+bottom;
    }

    /**
    * @dev Gives a number string of a character defined map
     */
    function pixel_decode(string memory _char) internal pure returns (string memory){
        string[34] memory LETTERS = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H"];
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (keccak256(abi.encodePacked((LETTERS[i]))) == keccak256(abi.encodePacked((_char)))){
            return (LoanSharksLib.toString(i + 1));
            }
        }
        revert();
    }
}


/**
@dev This set of functions provides mapping between a "rarity" value and a specific index that references a data array.
I've seen alot of on-chain projects implement something similar via use of "rarity arrays" but I feel this method is 
more more readable for people trying to understand how the contract works :)

Additionally, there a few functions that handle the SVG generation.
 */
library TraitHandler{

    /**
     * @dev Returns a mouth index
     * @param _seed The rarity seed to generate an index for.
     */
    function mouthIndexGen(uint256 _seed) internal pure returns (uint256){
        uint rarity = _seed % 100;
        if(rarity >= 95){ //Tier 5
        //TODO CCA needs 2 new traits
            return LoanSharksLib.seededBetween(17, 18, rarity);
        }
        else if(rarity >= 82){ //Tier 4
            return LoanSharksLib.seededBetween(15, 17, rarity);
        }
        else if(rarity >= 61){ //Tier 3
            return LoanSharksLib.seededBetween(12, 15, rarity);
        }
        else if(rarity >= 32){ //Tier 2
            return LoanSharksLib.seededBetween(7, 12, rarity);
        }
        else{ //Tier 1
            return LoanSharksLib.seededBetween(0, 7, rarity);
        }
    }

   /**
     * @dev Returns an eye index
     * @param _seed The rarity seed to generate an index for.
     */
    function eyeIndexGen(uint256 _seed) internal pure returns (uint256){
        uint rarity = _seed % 100;
        if(rarity >= 95){ //Tier 5
        //TODO 1 new eye trait from CCA
            return LoanSharksLib.seededBetween(17, 19, rarity);
        }
        else if(rarity >= 82){ //Tier 4
            return LoanSharksLib.seededBetween(14, 17, rarity);
        }
        else if(rarity >= 61){ //Tier 3
            return LoanSharksLib.seededBetween(10, 14, rarity);
        }
        else if(rarity >= 32){ //Tier 2
            return LoanSharksLib.seededBetween(5, 10, rarity);
        }
        else{ //Tier 1
            return LoanSharksLib.seededBetween(0, 5, rarity);
        }
    }
    /**
     * @dev Returns a hat index
     * @param _seed The rarity seed to generate an index for.
     */
    function hatIndexGen(uint256 _seed) internal pure returns (uint256){
        uint rarity = _seed % 100;
        if(rarity >= 95){ //Tier 5
        //TODO Maybe more hats?
            return LoanSharksLib.seededBetween(24, 25, rarity);
        }
        else if(rarity >= 82){ //Tier 4
            return LoanSharksLib.seededBetween(20, 24, rarity);
        }
        else if(rarity >= 61){ //Tier 3
            return LoanSharksLib.seededBetween(14, 20, rarity);
        }
        else if(rarity >= 32){ //Tier 2
            return LoanSharksLib.seededBetween(7, 14, rarity);
        }
        else{ //Tier 1
            return LoanSharksLib.seededBetween(0, 8, rarity);
        }
    }

    /**
     * @dev Returns a body index
     * @param _seed The rarity seed to generate an index for.
     */
    function bodyIndexGen(uint256 _seed) internal pure returns (uint256){
        uint rarity = _seed % 100;
        if(rarity >= 80){ //Only 20% chance of getting a body
            //Use permutation of block.timestamp and _seed for simplicity
            uint trarity = (_seed+100) % 100;
            if(trarity >= 95){ //Tier 5
            //TODO CCA needs 2 new body traits
            return LoanSharksLib.seededBetween(11, 13, trarity); 
            }
            else if(trarity >= 82){ //Tier 4
                return LoanSharksLib.seededBetween(11, 13, trarity);
            }
            else if(trarity >= 61){ //Tier 3
                return LoanSharksLib.seededBetween(8, 11, trarity);
            }
            else if(trarity >= 32){ //Tier 2
                return LoanSharksLib.seededBetween(6, 8, trarity);
            }
            else{ //Tier 1, Don't include index of 0 because user has been given a body trait.
                return LoanSharksLib.seededBetween(1, 6, trarity);
            }
        }
        else{ //No body
            return 0;
        }
    }

    /**
     * @dev Returns a background index
     * @param _seed The rarity seed to generate an index for.
     */
    function bgIndexGen(uint256 _seed) internal pure returns (uint256){
        //Note:
        uint rarity = _seed % 100;
        if(rarity >= 90){ //Tier 3
            return LoanSharksLib.seededBetween(10, 15, rarity);
        }
        else if(rarity >= 55){ //Tier 2
            return LoanSharksLib.seededBetween(5, 10, rarity);
        }
        else{ //Tier 1
            return LoanSharksLib.seededBetween(0, 5, rarity);
        }
    }
    /**
     * @dev Returns a species index
     * @param _seed The rarity seed to generate an index for.
     */
    function speciesIndexGen(uint256 _seed) internal pure returns (uint256){
        //Notice how beautifully simple it is when rarities aren't required ;)
        return _seed % 5;
    }
    
    /**
     * @dev Returns the SVG for a set of shark trait attributes
     * @param currentShark The shark list to return svg elements for
     */
    function svg_unpack(string[4][6] memory currentShark) internal pure returns (string memory){
        //Must be in the order of BACKGROUND, SPECIES, BODY, HAT, EYE, MOUTH
        string memory currentBody = '';
        for(uint i = 0; i < currentShark.length; i++){
            if(keccak256(abi.encodePacked(currentShark[i][2])) == keccak256(abi.encodePacked("0"))){ 
                //Solid color backgrounds
                currentBody = string(abi.encodePacked(currentBody, currentShark[i][3]));
                continue;
            }
            string memory sStr = (currentShark[i][3]);
            uint traitEncodingLength = LoanSharksLib.toUInt(currentShark[i][2]);
            string memory css_code = LoanSharksLib.substring(sStr, 0, 3);
            uint j = 4; //Begin reading pixels
             while(j < traitEncodingLength-2){
                string memory x = LoanSharksLib.substring(sStr, j, j + 1);
                string memory y = LoanSharksLib.substring(sStr, j+1, j+2);
                //Create component
                string memory cur_svg = string(abi.encodePacked(
                    '<rect class="s',
                    css_code,
                    '" x="',
                    LoanSharksLib.pixel_decode(x),
                    '" y="',
                    LoanSharksLib.pixel_decode(y),
                    '">'
                    ));
                currentBody = string(abi.encodePacked(currentBody,cur_svg));
                string memory iPos = LoanSharksLib.substring(sStr,j+2,j+3); //Forecast next point
                if(keccak256(abi.encodePacked(iPos)) == keccak256(abi.encodePacked("."))){
                    css_code = LoanSharksLib.substring(sStr, j+3, j+6);
                    j += 5;
                    if(j >= traitEncodingLength){
                        break;
                    }
                }
                j += 2;
                
            }
            //Add final point
            currentBody = string(abi.encodePacked(currentBody,
            string(abi.encodePacked(
                    '<rect class="s',
                    css_code,
                    '" x="',
                    LoanSharksLib.substring(sStr, j, j + 1),
                    '" y="',
                    LoanSharksLib.substring(sStr, j  +1, j + 2),
                    '">'
                    ))
            ));
        }
        return currentBody;
    }
}

/*
   _____ ____  _   _ _______ _____            _____ _______ 
  / ____/ __ \| \ | |__   __|  __ \     /\   / ____|__   __|
 | |   | |  | |  \| |  | |  | |__) |   /  \ | |       | |   
 | |   | |  | | . ` |  | |  |  _  /   / /\ \| |       | |   
 | |___| |__| | |\  |  | |  | | \ \  / ____ \ |____   | |   
  \_____\____/|_| \_|  |_|  |_|  \_\/_/    \_\_____|  |_|   
                                                                                                                                     
*/

contract LoanSharks is ERC721 {
    using LoanSharksLib for uint8;
    using Counters for Counters.Counter;

    /*
       ________    ____  ____  ___    __   _____
      / ____/ /   / __ \/ __ )/   |  / /  / ___/
     / / __/ /   / / / / __  / /| | / /   \__ \ 
    / /_/ / /___/ /_/ / /_/ / ___ |/ /______/ / 
    \____/_____/\____/_____/_/  |_/_____/____/  
                                            
    */
    
    //Contract Constants
    uint256 public MAX_SUPPLY = 6900;
    uint256 public ETH_SUPPLY  = 3450;
    uint256 public ETH_COST = 0.05 ether;
    
    //Mint Events
    event LoanSharksMinted(uint indexed tokenId, bytes indexed encodedId, address indexed owner);
    
    //Required Address'
    address tokenAddress;
    address _owner;
    
    //Owners
    address payable alpine = payable(0xfDeEBB7D5eF8BA128cd0F8CFCde7cD6b7E9B6891); //Same as _owner but for readability's sake.
    address payable cca = payable(0x114ac80EFDDF56FA31348A954Fd9b1e0f42362dd);
    
    //Initialize
    bool public saleStarted = true;

    //SVG Header
    string internal HEADER;
    
    //SVG Footer
    string internal FOOTER;
    
    //Trait Map
    //0 => Background
    //1 => Species
    //2 => Body
    //3 => Hat
    //4 => Eyes
    //5 => Mouth
    mapping(uint256 => string[4][]) internal traits;

    //Token Id related maps
    mapping(bytes => uint256) internal genHash;
    mapping(uint256 => bytes) public tokenIdBytes;

    //Helper maps
    mapping(uint256 => uint256[]) internal shadingMap;
    
    //Using Counters from OpenZeppelin instead of ERC721Enumerable's totalSupply() for gas efficiency.
    Counters.Counter public _tokenSupply;

    constructor() ERC721("Loan Sharks", "SHARKS") { 
        _owner = msg.sender;
    }
    /*
     _       ______  ________________
    | |     / / __ \/  _/_  __/ ____/
    | | /| / / /_/ // /  / / / __/   
    | |/ |/ / _, _// /  / / / /___   
    |__/|__/_/ |_/___/ /_/ /_____/   
                                 
   */

    /**
     * @dev Returns a unique byte encoded representing a set of trait indexes for a fresh tokenId
     * @param _tokenId The tokenId to generate an encoding for.
     */
    function tokenRarityGen(uint256 _tokenId) internal returns (bytes memory){
        bool fresh = false;
        uint nonce = 0;
        bytes memory test_hash;
        do {
            test_hash = abi.encodePacked(
                TraitHandler.speciesIndexGen(uint(keccak256(abi.encodePacked(block.timestamp+1,_tokenId,nonce)))), //Species
                TraitHandler.eyeIndexGen(uint(keccak256(abi.encodePacked(block.timestamp+2,_tokenId,nonce)))), //Eyes
                TraitHandler.mouthIndexGen(uint(keccak256(abi.encodePacked(block.timestamp+3,_tokenId,nonce)))), //Mouth
                TraitHandler.bodyIndexGen(uint(keccak256(abi.encodePacked(block.timestamp+4,_tokenId,nonce)))), //Body
                TraitHandler.hatIndexGen(uint(keccak256(abi.encodePacked(block.timestamp+5,_tokenId,nonce)))), //Hats
                TraitHandler.bgIndexGen(uint(keccak256(abi.encodePacked(block.timestamp+6,_tokenId,nonce)))) //Background
            );
            
            if(genHash[test_hash] == 0){
                tokenIdBytes[_tokenId] = test_hash;
                genHash[test_hash] = 1;
                fresh = true;
            }
            nonce += 1;
        }while(!fresh);
        return test_hash;
    }

    function mintShark() external payable {
        uint tokId = _tokenSupply.current() + 1;
        require(saleStarted, "Loan Sharks has not yet launched.");
        require(tokId <= MAX_SUPPLY, "Loan Sharks sold out.");
        if(tokId <= ETH_SUPPLY){ //Pay with ETH
            require(msg.value >= ETH_COST, "Ether sent is below the price for a Loan Shark.");
            (bool s1, ) = alpine.call{value:(msg.value/2)}("");
            (bool s2, ) = cca.call{value:(msg.value/2)}("");
            require(s1 && s2, "Transfer failed.");
        }   
        else{ //Pay with $LFBLD
            
        }
        //Payment Sucess
        
        bytes memory encoded_token = tokenRarityGen(tokId);
        _safeMint(msg.sender, tokId);
        _tokenSupply.increment;
        emit LoanSharksMinted(tokId, encoded_token, msg.sender);
    }



    /*
        ____  _________    ____ 
       / __ \/ ____/   |  / __ \
      / /_/ / __/ / /| | / / / /
     / _, _/ /___/ ___ |/ /_/ / 
    /_/ |_/_____/_/  |_/_____/  
                                                                                                                  
    */
    /**
     * @dev Returns the SVG and metadata for an existent token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory){
        require(_exists(_tokenId));
        bytes memory tokenEncoding = tokenIdBytes[_tokenId];
        uint species;
        uint eyes;
        uint mouth;
        uint body;
        uint hat;
        uint bg;
        (species, eyes, mouth, body, hat, bg) = abi.decode(tokenEncoding, (uint, uint, uint, uint, uint, uint));
        //Implicit Render Stack
        //TODO Clean Data

        string memory SHARK = TraitHandler.svg_unpack([
            (traits[0])[bg],
            (traits[1])[species],
            (traits[2])[body],
            (traits[3])[hat],
            (traits[4])[eyes],
            (traits[5])[mouth]
        ]);

        string memory svg_b64 = LoanSharksLib.encode(bytes(string(abi.encodePacked(
            HEADER,
            SHARK,
            FOOTER
            ))));
        return svg_b64;
    }

    /*
         ____ _       ___   ____________ 
        / __ \ |     / / | / / ____/ __ \
       / / / / | /| / /  |/ / __/ / /_/ /
      / /_/ /| |/ |/ / /|  / /___/ _, _/ 
      \____/ |__/|__/_/ |_/_____/_/ |_|  
                                                                                                                                       
    */

    /**
     * @dev Sets the $LFBLD ERC20 address
     * @param _tokenAddress The ERC20 token address
     */
    function setLFBLDAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
    
    /**
     * @dev Populates trait data arrays
     * @param _index The specific data array to populate
     * @param trait_set The data array to populate the in-contract array with
     */
    function addTraitArray(uint256 _index, string[4][] memory trait_set) public onlyOwner {
         for (uint256 i = 0; i < trait_set.length; i++) {
            traits[_index].push(trait_set[i]);
        }
        return;
    }
    
    /**
     * @dev Populates svg string header and footers.
     * @param _index The specific data string to populate
     * @param str The string to populate the in-contract variable with
     */
    function addSVGString(uint256 _index, string memory str) public onlyOwner {
        if(_index == 0){
            HEADER = str;
        }
        if(_index == 1){
            FOOTER = str;
        }
        return;
    }


     /**
     * @dev Sets the contract sale state.
     * @param _state The state to set.
     */
    function setSaleState(bool _state) public onlyOwner {
        saleStarted = _state;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}