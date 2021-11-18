// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Contracts
import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IImpactTheoryFoundersKey.sol";
import "./IITFKFreeMintable.sol";

contract ITFKPeer is Ownable {
    IImpactTheoryFoundersKey private itfk;

    mapping(address => bool) private _approvedContracts;
    mapping(uint256 => uint8) private _fkFreeMintUsage;
    mapping(uint256 => mapping(uint8 => address))
        private _fkFreeMintUsageContract;

    // Constructor
    constructor(address _itfkContractAddress) {
        itfk = IImpactTheoryFoundersKey(_itfkContractAddress);
    }

    function addFreeMintableContracts(address[] memory _contracts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _contracts.length; i++) {
            require(
                IERC165(_contracts[i]).supportsInterface(
                    type(IITFKFreeMintable).interfaceId
                ),
                "Contract is not ITFKFreeMintable"
            );

            _approvedContracts[_contracts[i]] = true;
        }
    }

    function getFreeMintsRemaining(uint256 _tokenId)
        public
        view
        returns (uint8)
    {
        (uint256 tierId, ) = itfk.tokenTier(_tokenId);
        if (tierId == 1)
            // Legendary
            return
                _fkFreeMintUsage[_tokenId] > 3
                    ? 0
                    : 3 - _fkFreeMintUsage[_tokenId];
        if (tierId == 2)
            // Heroic
            return _fkFreeMintUsage[_tokenId] == 0 ? 1 : 0;
        return 0;
    }

    function updateFreeMintAllocation(uint256 _tokenId) public {
        require(_approvedContracts[msg.sender], "Not a free mintable contract");
        (uint256 tierId, ) = itfk.tokenTier(_tokenId);

        require(
            tierId == 1 || tierId == 2,
            "Only Legendary & Heroic can free mint"
        );

        if (tierId == 1)
            require(
                _fkFreeMintUsage[_tokenId] < 3,
                "All Legendary free mints used"
            );
        if (tierId == 2)
            require(_fkFreeMintUsage[_tokenId] < 1, "Heroic free mint used");

        uint8 newUsedFreeMint = _fkFreeMintUsage[_tokenId] + 1;
        _fkFreeMintUsageContract[_tokenId][newUsedFreeMint] = msg.sender;
        _fkFreeMintUsage[_tokenId] = newUsedFreeMint;
    }

    function getFreeMintContracts(uint256 _tokenId)
        external
        view
        returns (address[] memory contracts)
    {
        uint8 usageCount = _fkFreeMintUsage[_tokenId];
        address[] memory _contracts = new address[](usageCount);

        for (uint8 i; i < usageCount; i++) {
            _contracts[i] = _fkFreeMintUsageContract[_tokenId][i + 1];
        }

        return _contracts;
    }

    function getFoundersKeysByTierIds(address _wallet, uint8 _includeTier)
        external
        view
        returns (uint256[] memory fks)
    {
        // _includeTier = 3 bit field
        // 100 = relentless
        // 010 = heroic
        // 001 = legendary
        uint256 balance = itfk.balanceOf(_wallet);
        uint256[] memory fkMapping = new uint256[](balance);
        uint256 fkCount;

        for (uint256 i; i < balance; i++) {
            uint256 tokenId = itfk.tokenOfOwnerByIndex(_wallet, i);

            (uint256 tierId, ) = itfk.tokenTier(tokenId);
            uint8 bitFieldTierId = tierId > 0 ? uint8(1 << (tierId - 1)) : 0;
            if (_includeTier & bitFieldTierId != 0) {
                fkMapping[fkCount] = tokenId;
                fkCount++;
            }
        }

        uint256[] memory _fks = new uint256[](fkCount);
        for (uint256 i; i < fkCount; i++) {
            _fks[i] = fkMapping[i];
        }

        return _fks;
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

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IImpactTheoryFoundersKey is IERC721Enumerable {
    struct Tier {
        uint256 id;
        string name;
    }

    function tokenTier(uint256)
        external
        view
        returns (uint256 tierId, string memory tierName);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IITFKFreeMintable is IERC165 {
    function fkMint(
        uint256[] memory _fkPresaleTokenIds,
        uint256[] memory _fkFreeMintTokenIds,
        uint32 _amount,
        string memory _nonce,
        bytes memory _signature
    ) external;
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