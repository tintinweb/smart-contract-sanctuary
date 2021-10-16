// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IGhostTown.sol";
import "./StringUtil.sol";


/// @title GhostTown Metadata contract
contract GhostTownMetadata is Ownable, StringUtil {

    /// @notice Event emitted when GhostTown contract is set
    /// @param contractAddress the address of the GhostTown contract
    event GhostTownContractSet(address contractAddress);

    /// @notice Event emitted when TokenURI base changes
    /// @param tokenUriBase the base URI for tokenURI calls
    event TokenUriBaseSet(string tokenUriBase);

    /// @notice Event emitted when the `mediaUriBase` is set.
    /// Only emitted when the `mediaUriBase` is set after contract deployment.
    /// @param mediaUriBase the new URI
    event MediaUriBaseSet(string mediaUriBase);

    /// @notice Event emitted when the `viewUriBase` is set.
    /// Only emitted when the `viewUriBase` is set after contract deployment.
    /// @param viewUriBase the new URI
    event ViewUriBaseSet(string viewUriBase);

    string public constant INVALID_TOKEN_ID = "Invalid Token ID";

    string private tokenUriBase;
    string private mediaUriBase;
    string private viewUriBase;

    IGhostTown private ghostTownContract;

    /// @notice Set the address of the `GhostTown` contract.
    /// Only invokable by system admin role, when contract is paused and not upgraded.
    /// To be used if the GhostTown contract has to be upgraded and a new instance deployed.
    /// If successful, emits an `GhostTownContractSet` event.
    /// @param _address address of `GhostTown` contract
    function setGhostTownContract(address _address) external onlyOwner {
        IGhostTown candidateContract = IGhostTown(_address);
        require(candidateContract.isGhostTown());
        ghostTownContract = IGhostTown(_address);
        emit GhostTownContractSet(_address);
    }

    function isGhostTownMetadata() external pure returns (bool) {
        return true;
    }

    /// @notice Set the base URI for creating `tokenURI` for each Ghost.
    /// Only invokable by system admin role, when contract is paused and not upgraded.
    /// If successful, emits an `TokenUriBaseSet` event.
    /// @param _tokenUriBase base for the ERC721 tokenURI
    function setTokenUriBase(string calldata _tokenUriBase) external onlyOwner {
        tokenUriBase = _tokenUriBase;
        emit TokenUriBaseSet(_tokenUriBase);
    }

    /// @notice Set the base URI for the image of each Ghost.
    /// Only invokable by system admin role, when contract is paused and not upgraded.
    /// If successful, emits an `MediaUriBaseSet` event.
    /// @param _mediaUriBase base for the mediaURI shown in metadata for each Ghost
    function setMediaUriBase(string calldata _mediaUriBase) external onlyOwner {
        mediaUriBase = _mediaUriBase;
        emit MediaUriBaseSet(_mediaUriBase);
    }

    /// @notice Set the base URI for the image of each Ghost.
    /// Only invokable by system admin role, when contract is paused and not upgraded.
    /// If successful, emits an `MediaUriBaseSet` event.
    /// @param _viewUriBase base URI for viewing an Ghost on the GhostTown website
    function setViewUriBase(string calldata _viewUriBase) external onlyOwner {
        viewUriBase = _viewUriBase;
        emit ViewUriBaseSet(_viewUriBase);
    }

    function viewURI(uint _tokenId)
    external view
    returns (string memory uri) {
        require(_tokenId < ghostTownContract.totalSupply(), INVALID_TOKEN_ID);
        uri = _strConcat(viewUriBase, _uintToStr(_tokenId));
    }

    function mediaURI(uint _tokenId)
    external view
    returns (string memory uri) {
        require(_tokenId < ghostTownContract.totalSupply(), INVALID_TOKEN_ID);
        uri = _strConcat(mediaUriBase, _uintToStr(_tokenId));
    }

    function tokenURI(uint _tokenId)
    external view
    returns (string memory uri) {
        require(_tokenId < ghostTownContract.totalSupply(), INVALID_TOKEN_ID);
        uri = _strConcat(tokenUriBase, _uintToStr(_tokenId));
    }
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface IGhostTown is IERC721Enumerable {

    /// @notice Acknowledge contract is `GhostTown`
    /// @return always true if the contract is in fact `GhostTown`
    function isGhostTown() external pure returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract StringUtil {

    function _strConcat(string memory _a, string memory _b)
    internal pure
    returns (string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function _uintToStr(uint _i)
    internal pure
    returns (string memory result) {
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
        result = string(bstr);
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