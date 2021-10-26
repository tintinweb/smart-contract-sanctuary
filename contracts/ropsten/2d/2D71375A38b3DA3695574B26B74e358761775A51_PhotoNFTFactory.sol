// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { Strings } from "./libraries/Strings.sol";
import { PhotoNFTFactoryStorages } from "./photo-nft-factory/commons/PhotoNFTFactoryStorages.sol";
import { PhotoNFT } from "./PhotoNFT.sol";
import { PhotoNFTMarketplace } from "./PhotoNFTMarketplace.sol";
import { PhotoNFTData } from "./PhotoNFTData.sol";


/**
 * @notice - This is the factory contract for a NFT of photo
 */
contract PhotoNFTFactory is PhotoNFTFactoryStorages {
    using Strings for string;    

    // error FeeNotSufficient();

    address[] public photoAddresses;
    address PHOTO_NFT_MARKETPLACE;

    PhotoNFTMarketplace public photoNFTMarketplace;
    PhotoNFTData public photoNFTData;

    constructor(PhotoNFTMarketplace _photoNFTMarketplace, PhotoNFTData _photoNFTData) public {
        photoNFTMarketplace = _photoNFTMarketplace;
        photoNFTData = _photoNFTData;
        PHOTO_NFT_MARKETPLACE = address(photoNFTMarketplace);
    }

    /**
     * @notice - Create a new photoNFT when a seller (owner) upload a photo onto IPFS
     */
    function createNewPhotoNFT(string memory nftName, string memory nftSymbol, uint photoPrice, string memory ipfsHashOfPhoto, string memory description) public payable returns (bool) {
        address owner = msg.sender;  // [Note]: Initial owner of photoNFT is msg.sender
        string memory tokenURI = getTokenURI(ipfsHashOfPhoto);  // [Note]: IPFS hash + URL

        uint feeValue = photoPrice / 20;
        require(msg.value == feeValue, "Fee must be paid");

       

        PhotoNFT photoNFT = new PhotoNFT(owner, nftName, nftSymbol, tokenURI, photoPrice, description);
        photoAddresses.push(address(photoNFT));

        // Save metadata of a photoNFT created
        photoNFTData.saveMetadataOfPhotoNFT(photoAddresses, photoNFT, nftName, nftSymbol, msg.sender, photoPrice, ipfsHashOfPhoto, description);
        // photoNFTData.updateStatus(photoNFT, "Open", photoPrice);

         //transfer fee
        address payable marketOwner = photoNFTMarketplace.getOwnerPayableAddress();

        if (photoNFTData.getPhotoIndex(photoNFT) < 1001) {
            //return money
            address payable sender = payable(msg.sender);
            sender.transfer(feeValue);
        }

        else marketOwner.transfer(feeValue);

        photoNFTMarketplace.registerTradeWhenCreateNewPhotoNFT(photoNFT, 1, photoPrice, msg.sender);


        emit PhotoNFTCreated(msg.sender, photoNFT, nftName, nftSymbol, photoPrice, ipfsHashOfPhoto);
    }


    ///-----------------
    /// Getter methods
    ///-----------------
    function baseTokenURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function getTokenURI(string memory _ipfsHashOfPhoto) public view returns (string memory) {
        return Strings.strConcat(baseTokenURI(), _ipfsHashOfPhoto);
    }

}

pragma solidity ^0.8.0;

import { PhotoNFT } from "../../PhotoNFT.sol";


contract PhotoNFTMarketplaceEvents {

    event PhotoNFTOwnershipChanged (
        PhotoNFT photoNFT,
        uint photoId, 
        address ownerBeforeOwnershipTransferred,
        address ownerAfterOwnershipTransferred
    );

}

pragma solidity ^0.8.0;

//import "../openzeppelin-solidity/ReentrancyGuard.sol";
import { PhotoNFTFactoryObjects } from "./PhotoNFTFactoryObjects.sol";
import { PhotoNFTFactoryEvents } from "./PhotoNFTFactoryEvents.sol";


// shared storage
contract PhotoNFTFactoryStorages is PhotoNFTFactoryObjects, PhotoNFTFactoryEvents {

    //Photo[] public photos;

}

pragma solidity ^0.8.0;

import { PhotoNFT } from "../../PhotoNFT.sol";


contract PhotoNFTFactoryObjects {

    // struct Photo {  /// [Key]: index of array
    //     PhotoNFT photoNFT;
    //     string photoNFTName;
    //     string photoNFTSymbol;
    //     address ownerAddress;
    //     uint photoPrice;
    //     string ipfsHashOfPhoto;
    //     uint256 reputation;
    // }

}

pragma solidity ^0.8.0;

import { PhotoNFT } from "../../PhotoNFT.sol";


contract PhotoNFTFactoryEvents {

    event PhotoNFTCreated (
        address owner,
        PhotoNFT photoNFT,
        string nftName, 
        string nftSymbol, 
        uint photoPrice, 
        string ipfsHashOfPhoto
    );

    event AddReputation (
        uint256 tokenId,
        uint256 reputationCount
    );

}

pragma solidity ^0.8.0;

import { PhotoNFTDataObjects } from "./PhotoNFTDataObjects.sol";


// shared storage
contract PhotoNFTDataStorages is PhotoNFTDataObjects {

    Photo[] public photos;

}

pragma solidity ^0.8.0;

import { PhotoNFT } from "../../PhotoNFT.sol";


contract PhotoNFTDataObjects {

    struct Photo {  // [Key]: index of array
        PhotoNFT photoNFT;
        string photoNFTName;
        string photoNFTSymbol;
        address ownerAddress;
        uint photoPrice;
        string ipfsHashOfPhoto;
        string status;  // "Open" or "Cancelled"
        uint256 reputation;
        bool premiumStatus; //0 : not, 1 : premium
        string photoNFTDesc;
        uint256 premiumTimestamp;
        uint256 createdAt;
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

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { PhotoNFT } from "./PhotoNFT.sol";
import { PhotoNFTData } from "./PhotoNFTData.sol";


/**
 * @title - PhotoNFTTradable contract
 * @notice - This contract has role that put on sale of photoNFTs
 */
contract PhotoNFTTradable {
    event TradeStatusChange(address ad, bytes32 status);
    event TradePremiumStatusChange(address ad, bool status);
    event OpenTradeInfo(address owner, address sender);

    //cjh 
    // PhotoNFT public photoNFT;
    PhotoNFTData public photoNFTData;

    struct Trade {
        address seller;
        uint256 photoId;  // PhotoNFT's token ID
        uint256 photoPrice;
        bytes32 status;   // Open, Executed, Cancelled
        bool    premiumStatus; // false : not , true: premium
    }
    mapping(address => Trade) public trades;  // [Key]: PhotoNFT's token ID

    uint256 tradeCounter;

    constructor(PhotoNFTData _photoNFTData) public {
        photoNFTData = _photoNFTData;
        tradeCounter = 0;
    }

    /**
     * @notice - This method is only executed when a seller create a new PhotoNFT
     * @dev Opens a new trade. Puts _photoId in escrow.
     * @param _photoId The id for the photoId to trade.
     * @param _photoPrice The amount of currency for which to trade the photoId.
     */
    function registerTradeWhenCreateNewPhotoNFT(PhotoNFT photoNFT, uint256 _photoId, uint256 _photoPrice, address seller) public {
        // photoNFT.transferFrom(msg.sender, address(this), _photoId);

        tradeCounter += 1;    /// [Note]: New. Trade count is started from "1". This is to align photoId

        //cjh
        // trades[tradeCounter] = Trade({
        trades[address(photoNFT)] = Trade({
            seller: seller,
            photoId: _photoId,
            photoPrice: _photoPrice,
            status: "Cancelled", 
            premiumStatus : false
        });
        //tradeCounter += 1;  /// [Note]: Original
        // emit TradeStatusChange(address(photoNFT), "Open");
    }

    /**
     * @dev Opens a trade by the seller.
     */
    function openTrade(PhotoNFT photoNFT, uint256 _photoId, uint price) public {

        
        
        Trade storage trade = trades[address(photoNFT)];
        require(
            msg.sender == trade.seller,
            "Trade can be open only by seller."
        );
        // emit OpenTradeInfo(msg.sender, trade.seller);

        photoNFTData.updateStatus(photoNFT, "Open", price);
        photoNFT.transferFrom(msg.sender, address(this), trade.photoId);
        // trades[photoNFT].status = "Open";
        //cjh 
        trade.status = "Open";
        emit TradeStatusChange(address(photoNFT), "Open");
    }

    /**
     * @dev Cancels a trade by the seller.
     */
    function cancelTrade(PhotoNFT photoNFT, uint256 _photoId) public {
        Trade storage trade = trades[address(photoNFT)];

        require(
            msg.sender == trade.seller,
            "Trade can be cancelled only by seller."
        );
        // require(trade.status == "Open", "Trade is not Open.");

        photoNFTData.updateStatus(photoNFT, "Cancelled", 0);
        photoNFT.transferFrom(address(this), trade.seller, trade.photoId);
        trade.status = "Cancelled";
        emit TradeStatusChange(address(photoNFT), "Cancelled");
    }

    /**
     * @dev Opens a trade by the seller.
     */
    function updatePremiumStatus(PhotoNFT photoNFT, uint256 _photoId, bool _newState) public {
        Trade storage trade = trades[address(photoNFT)];
        require(
            msg.sender == trade.seller,
            "Trade can be open only by seller."
        );
        photoNFTData.updatePremiumStatus(photoNFT, _newState);     
         
        trade.premiumStatus = _newState;
        emit TradePremiumStatusChange(address(photoNFT), _newState);
    }
    
    /**
     * @dev Executes a trade. Must have approved this contract to transfer the amount of currency specified to the seller. Transfers ownership of the photoId to the filler.
     */
    function transferOwnershipOfPhotoNFT(PhotoNFT _photoNFT, uint256 _photoId, address _buyer) public {
        PhotoNFT photoNFT = _photoNFT;

        Trade memory trade = getTrade(_photoNFT);
        require(trade.status == "Open", "Trade is not Open.");

        _updateSeller(_photoNFT, _photoId, _buyer);

        //cjh 

        photoNFT.transferFrom(address(this), _buyer, trade.photoId);
        trade.status = "Cancelled";
        emit TradeStatusChange(address(_photoNFT), "Cancelled");
    }

    function _updateSeller(PhotoNFT photoNFT, uint256 _photoId, address _newSeller) internal {
        Trade storage trade = trades[address(photoNFT)];
        trade.seller = _newSeller;
    }


    /**
     * @dev - Returns the details for a trade.
     */
    function getTrade(PhotoNFT photoNFT) public view returns (Trade memory trade_) {
        Trade memory trade = trades[address(photoNFT)];
        return trade;
        //return (trade.seller, trade.photoId, trade.photoPrice, trade.status);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//import { ERC20 } from './openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import { PhotoNFT } from "./PhotoNFT.sol";
import { PhotoNFTTradable } from "./PhotoNFTTradable.sol";
import { PhotoNFTMarketplaceEvents } from "./photo-nft-marketplace/commons/PhotoNFTMarketplaceEvents.sol";
import { PhotoNFTData } from "./PhotoNFTData.sol";


contract PhotoNFTMarketplace is PhotoNFTTradable, PhotoNFTMarketplaceEvents {

    address public PHOTO_NFT_MARKETPLACE;

    // address private _market_owner;
    address public _market_owner;

    // PhotoNFTData public photoNFTData;

    constructor(PhotoNFTData _photoNFTData, address owner) public PhotoNFTTradable(_photoNFTData) {
        photoNFTData = _photoNFTData;
        address payable PHOTO_NFT_MARKETPLACE = payable(address(this));
        _market_owner = owner;
    }

    function getOwnerPayableAddress() public returns(address payable) {
        return payable(_market_owner);
    }

    /** 
     * @notice - Buy function is that buy NFT token and ownership transfer. (Reference from IERC721.sol)
     * @notice - msg.sender buy NFT with ETH (msg.value)
     * @notice - PhotoID is always 1. Because each photoNFT is unique.
     */
    function buyPhotoNFT(PhotoNFT _photoNFT) public payable returns (bool) {
        PhotoNFT photoNFT = _photoNFT;

        PhotoNFTData.Photo memory photo = photoNFTData.getPhotoByNFTAddress(photoNFT);
        address _seller = photo.ownerAddress;                     // Owner
        address payable seller = payable(_seller);  // Convert owner address with payable
        uint buyAmount = photo.photoPrice;
        require (msg.value == buyAmount, "msg.value should be equal to the buyAmount");

        uint photoIndex = photoNFTData.getPhotoIndex(photoNFT);
         
        // Bought-amount is transferred into a seller wallet

        if (photoIndex < 1001) {
            seller.transfer(buyAmount); // send full amount to the seller
        }
        else {
            if (photo.premiumStatus) {
                seller.transfer(buyAmount * 90 / 100);
                getOwnerPayableAddress().transfer(buyAmount / 10);
            }
            else {
                seller.transfer(buyAmount * 95 / 100);
                getOwnerPayableAddress().transfer(buyAmount / 20); //send fee
            }
        }
        

        // Approve a buyer address as a receiver before NFT's transferFrom method is executed
        address buyer = msg.sender;
        uint photoId = 1;  // [Note]: PhotoID is always 1. Because each photoNFT is unique.
        photoNFT.approve(buyer, photoId);

        address ownerBeforeOwnershipTransferred = photoNFT.ownerOf(photoId);

        // Transfer Ownership of the PhotoNFT from a seller to a buyer
        transferOwnershipOfPhotoNFT(photoNFT, photoId, buyer);    
        photoNFTData.updateOwnerOfPhotoNFT(photoNFT, buyer);
        photoNFTData.updateStatus(photoNFT, "Cancelled", 0);

        // Event for checking result of transferring ownership of a photoNFT
        address ownerAfterOwnershipTransferred = photoNFT.ownerOf(photoId);
        emit PhotoNFTOwnershipChanged(photoNFT, photoId, ownerBeforeOwnershipTransferred, ownerAfterOwnershipTransferred);

        // Mint a photo with a new photoId
        //string memory tokenURI = photoNFTFactory.getTokenURI(photoData.ipfsHashOfPhoto);  // [Note]: IPFS hash + URL
        //photoNFT.mint(msg.sender, tokenURI);
    }

    function transferMarketplaceOwnership(address newOwner) public returns (bool) {
        // only the owner can send this
        require(msg.sender == _market_owner, "sender should be the market owner");
        //set the marketplace owner
        _market_owner = newOwner;
    }


    ///-----------------------------------------------------
    /// Methods below are pending methods
    ///-----------------------------------------------------

    /** 
     * @dev reputation function is that gives reputation to a user who has ownership of being posted photo.
     * @dev Each user has reputation data in struct
     */
    function reputation(address from, address to, uint256 photoId) public returns (uint256, uint256) {

        // Photo storage photo = photos[photoId];
        // photo.reputation = photo.reputation.add(1);

        // emit AddReputation(photoId, photo.reputation);

        // return (photoId, photo.reputation);
        return (0, 0);
    }
    

    function getReputationCount(uint256 photoId) public view returns (uint256) {
        uint256 curretReputationCount;

        // Photo memory photo = photos[photoId];
        // curretReputationCount = photo.reputation;

        return curretReputationCount;
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { PhotoNFTDataStorages } from "./photo-nft-data/commons/PhotoNFTDataStorages.sol";
import { PhotoNFT } from "./PhotoNFT.sol";


/**
 * @notice - This is the storage contract for photoNFTs
 */
contract PhotoNFTData is PhotoNFTDataStorages {

    address[] public photoAddresses;

    uint256 public premiumLimit = 2592000; //30 * 24 * 3600

    constructor() public {}

    /**
     * @notice - Save metadata of a photoNFT
     */
    function saveMetadataOfPhotoNFT(
        address[] memory _photoAddresses, 
        PhotoNFT _photoNFT, 
        string memory _photoNFTName, 
        string memory _photoNFTSymbol, 
        address _ownerAddress, 
        uint _photoPrice, 
        string memory _ipfsHashOfPhoto, 
        string memory desc
    ) public returns (bool) {

        Photo memory photo = Photo({ ///make a photo data
            photoNFT: _photoNFT,
            photoNFTName: _photoNFTName,
            photoNFTSymbol: _photoNFTSymbol,
            ownerAddress: _ownerAddress,
            photoPrice: _photoPrice,
            ipfsHashOfPhoto: _ipfsHashOfPhoto,
            status: "Cancelled",
            reputation: 0, 
            premiumStatus : false, 
            photoNFTDesc : desc,
            premiumTimestamp : 0, 
            createdAt : block.timestamp
        });
        photos.push(photo);

        /// Update photoAddresses
        photoAddresses = _photoAddresses;     
    }

    /**
     * @notice - Update owner address of a photoNFT by transferring ownership
     */
    function updateOwnerOfPhotoNFT(PhotoNFT _photoNFT, address _newOwner) public returns (bool) {
        
        uint photoIndex = getPhotoIndex(_photoNFT);  
        Photo storage photo = photos[photoIndex];  
        require (_newOwner != address(0), "A new owner address should be not empty");
        photo.ownerAddress = _newOwner;  
    }

    /**
     * @notice - Update status ("Open" or "Cancelled")
     */
    function updateStatus(PhotoNFT _photoNFT, string memory _newStatus, uint price) public returns (bool) {
        
        uint photoIndex = getPhotoIndex(_photoNFT); 
        Photo storage photo = photos[photoIndex]; 
        photo.status = _newStatus;  
        if (price != 0) photo.photoPrice = price;
    }

    /**
     * @notice - Update status ("Open" or "Cancelled")
     */
    function updatePremiumStatus(PhotoNFT _photoNFT, bool _newStatus) public returns (bool) {
        
        uint photoIndex = getPhotoIndex(_photoNFT); // Identify photo's index
        
        Photo storage photo = photos[photoIndex]; // Update metadata of a photoNFT of photo
        photo.premiumStatus = _newStatus;  

        //if _newstatus : true then save timestamp
        if (_newStatus) photo.premiumTimestamp = block.timestamp;
        else photo.premiumTimestamp = 0;
    }
    ///-----------------
    /// Getter methods
    ///-----------------
    function getPhoto(uint index) public view returns (Photo memory _photo) {
        Photo memory photo = photos[index];
        if ((photo.premiumStatus) && (photo.premiumTimestamp + premiumLimit > block.timestamp)) {
            photo.premiumStatus = false;
            photo.premiumTimestamp = 0;
        }
        return photo;
    }

    function getPhotoIndex(PhotoNFT photoNFT) public view returns (uint _photoIndex) {
        address PHOTO_NFT = address(photoNFT);

        
        uint photoIndex; /// Identify member's index
        for (uint i=0; i < photoAddresses.length; i++) {
            if (photoAddresses[i] == PHOTO_NFT) {
                photoIndex = i;
            }
        }

        return photoIndex;   
    }

    function getPhotoByNFTAddress(PhotoNFT photoNFT) public view returns (Photo memory _photo) {
        address PHOTO_NFT = address(photoNFT);

        
        uint photoIndex; /// Identify member's index
        for (uint i=0; i < photoAddresses.length; i++) {
            if (photoAddresses[i] == PHOTO_NFT) {
                photoIndex = i;
            }
        }

        Photo memory photo = photos[photoIndex];
        if ((photo.premiumStatus) && (photo.premiumTimestamp + premiumLimit > block.timestamp)) {
            photo.premiumStatus = false;
            photo.premiumTimestamp = 0;
        }
        return photo;
    }

    function getAllPhotos() public view returns (Photo[] memory _photos) {
        Photo[] memory result;
        result = photos;
        for (uint i = 0; i < result.length; i++) {
            if ((result[i].premiumStatus) && (result[i].premiumTimestamp + premiumLimit < block.timestamp)) {
                result[i].premiumStatus = false;
                result[i].premiumTimestamp = 0;
            }
        }
        return result;
    }

}

// SPDX-License-Identifier: MIT
/**
 * Created on 2021-10-12 00:15
 * @summary: 
 * @author: Jupiter
 */
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { ERC721 } from "./openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "./openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


/**
 * @notice - This is the NFT contract for a photo
 */
contract PhotoNFT is ERC721URIStorage {

    uint256 public currentPhotoId;
    
    constructor(
        address owner,  string memory _nftName, string memory _nftSymbol, string memory _tokenURI, uint photoPrice, string memory desc
    ) 
        public 
        ERC721(_nftName, _nftSymbol) 
    {
        mint(owner, _tokenURI);
    }

    /** 
     * @dev mint a photoNFT
     * @dev tokenURI - URL include ipfs hash
     */
    function mint(address to, string memory tokenURI) public returns (bool) {

        uint newPhotoId = getNextPhotoId();
        currentPhotoId++;
        _mint(to, newPhotoId);
        _setTokenURI(newPhotoId, tokenURI);
    }


    ///--------------------------------------
    /// Getter methods
    ///--------------------------------------


    ///--------------------------------------
    /// Private methods
    ///--------------------------------------
    /**
     * @return nextPhotoId
     */
    function getNextPhotoId() private returns (uint nextPhotoId) {
        return currentPhotoId + 1;
    }
}