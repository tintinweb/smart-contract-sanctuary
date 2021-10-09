// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

interface CryptoPunksMarket {
    function punkIndexToAddress(uint256) external view returns (address);
}

interface LostPunkSociety is IERC721Enumerable {
    function punkAttributes(uint16) external view returns (string memory);
    function mintLostPunk(uint16, uint16) external payable;
}

//  ██╗      ██████╗ ███████╗████████╗██████╗ ██╗   ██╗███╗   ██╗██╗  ██╗███████╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗███████╗████████╗
//  ██║     ██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██║   ██║████╗  ██║██║ ██╔╝██╔════╝████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔════╝╚══██╔══╝
//  ██║     ██║   ██║███████╗   ██║   ██████╔╝██║   ██║██╔██╗ ██║█████╔╝ ███████╗██╔████╔██║███████║██████╔╝█████╔╝ █████╗     ██║   
//  ██║     ██║   ██║╚════██║   ██║   ██╔═══╝ ██║   ██║██║╚██╗██║██╔═██╗ ╚════██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝     ██║   
//  ███████╗╚██████╔╝███████║   ██║   ██║     ╚██████╔╝██║ ╚████║██║  ██╗███████║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗███████╗   ██║   
//  ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   
                                                                                                                                 
contract LostPunksMarket is Ownable {
    event PriceSet(address indexed from, uint256 indexed tokenId, uint256 priceInWei);
    event PriceCleared(address indexed from, uint256 indexed tokenId);
    event PartnerSet(address indexed from, uint256 indexed tokenId, uint256 indexed partnerTokenId);
    event PartnerCleared(address indexed from, uint256 indexed tokenId);
    event Claimed(address indexed from, address indexed to, uint256 indexed tokenId);

    CryptoPunksMarket private cryptoPunksMarket;
    LostPunkSociety private lostPunkSociety;
    mapping(uint16 => address) private virtualOwners;
    mapping(uint16 => bool) private hasPriceSet;
    mapping(uint16 => uint256) private pricesInWei;
    mapping(uint16 => bool) private hasPartnerSet;
    mapping(uint16 => uint16) private partners;
    
    uint256 private GLOBAL_PRICE_IN_WEI;
    bool private HAS_GLOBAL_PRICE_SET;
    uint16 private constant CRYPTO_PUNKS_COUNT = 10000;

    constructor() {
        cryptoPunksMarket = CryptoPunksMarket(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
        lostPunkSociety = LostPunkSociety(0xa583bEACDF3Ed3808402f8dB4F6628a7E1C6ceC6);
    }
    
//   ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//   ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    function destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }
    
    function setGlobalPrice(bool hasGlobalPrice, uint256 globalPriceInWei) external onlyOwner {
        HAS_GLOBAL_PRICE_SET = hasGlobalPrice;
        GLOBAL_PRICE_IN_WEI = globalPriceInWei;
    }
    
    address private constant giveDirectlyDonationAddress = 0xc7464dbcA260A8faF033460622B23467Df5AEA42;
    
    function withdraw() external onlyOwner {
        uint256 donation = address(this).balance / 10;
        payable(giveDirectlyDonationAddress).transfer(donation);
        payable(owner()).transfer(address(this).balance); 
    }
    
//  ██████╗ ███████╗ █████╗ ██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██████╔╝█████╗  ███████║██║  ██║    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██╔══██╗██╔══╝  ██╔══██║██║  ██║    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ██║  ██║███████╗██║  ██║██████╔╝    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

   function punkIndexToAddress(uint256 punkIndex) public view returns (address) {
        require(punkIndex < CRYPTO_PUNKS_COUNT);
        address virtualOwner = virtualOwners[uint16(punkIndex)];
        return (virtualOwner != address(0)) ? virtualOwner : cryptoPunksMarket.punkIndexToAddress(punkIndex);
    }
    
    function numberOfRemainingChildrenToMintForPunk(uint16 punkIndex) public view returns (uint8) {
        uint8 numberOfEmptyChildren = 0;
        bytes memory stringAsBytes = bytes(lostPunkSociety.punkAttributes(punkIndex));
        bytes memory buffer = new bytes(stringAsBytes.length);

        uint j = 0;
        for (uint i = 0; i < stringAsBytes.length; i++) {
            if (stringAsBytes[i] != ",") {
                buffer[j++] = stringAsBytes[i];
            } else {
                if (isEmptyChildAttribute(buffer, j)) {
                    numberOfEmptyChildren++;
                }
                i++; // skip space
                j = 0;
            }
        }
        if ((j > 0) && isEmptyChildAttribute(buffer, j)) {
            numberOfEmptyChildren++;
        }
        return numberOfEmptyChildren;
    }
    
    function isEmptyChildAttribute(bytes memory buffer, uint length) internal pure returns (bool) {
        return (length == 10) 
        && (buffer[0] == bytes1('C')) 
        && (buffer[1] == bytes1('h'))
        && (buffer[2] == bytes1('i'))
        && (buffer[3] == bytes1('l'))
        && (buffer[4] == bytes1('d'));
    }

    function hasPriceSetToMintRemainingChildrenForPunk(uint16 punkIndex) public view returns (bool) {
        require(punkIndex < CRYPTO_PUNKS_COUNT);
        return hasPriceSet[punkIndex] || HAS_GLOBAL_PRICE_SET;
    }

    function getPriceInWeiToMintRemainingChildrenForPunk(uint16 punkIndex) public view returns (uint256) {
        require(hasPriceSetToMintRemainingChildrenForPunk(punkIndex));
        return hasPriceSet[punkIndex] ? pricesInWei[punkIndex] : GLOBAL_PRICE_IN_WEI;
    }

//  ████████╗██████╗  █████╗ ██████╗ ██╗███╗   ██╗ ██████╗ 
//  ╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║████╗  ██║██╔════╝ 
//     ██║   ██████╔╝███████║██║  ██║██║██╔██╗ ██║██║  ███╗
//     ██║   ██╔══██╗██╔══██║██║  ██║██║██║╚██╗██║██║   ██║
//     ██║   ██║  ██║██║  ██║██████╔╝██║██║ ╚████║╚██████╔╝
//     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ 

    function setPriceToMintRemainingChildrenForPunk(uint16 punkIndex, uint256 priceInWei) external {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        pricesInWei[punkIndex] = priceInWei;
        hasPriceSet[punkIndex] = true;
        emit PriceSet(punkOwner, punkIndex, priceInWei);
    }

    function clearPriceToMintRemainingChildrenForPunk(uint16 punkIndex) public {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        hasPriceSet[punkIndex] = false;
        pricesInWei[punkIndex] = 0;
        emit PriceCleared(punkOwner, punkIndex);
    }
    
    function claimRightToMintRemainingChildrenForPunk(uint16 punkIndex) external payable {
        require(getPriceInWeiToMintRemainingChildrenForPunk(punkIndex) <= msg.value);
        require(numberOfRemainingChildrenToMintForPunk(punkIndex) > 0);

        uint256 royalties = msg.value / 10;
        address previousOwner = punkIndexToAddress(punkIndex);
        payable(previousOwner).transfer(msg.value - royalties);

        virtualOwners[punkIndex] = msg.sender;
        clearPriceToMintRemainingChildrenForPunk(punkIndex);
        clearPartnerToMintChildrenForPunk(punkIndex);

        emit Claimed(previousOwner, msg.sender, punkIndex);
    }

//  ██████╗  █████╗ ██████╗ ████████╗███╗   ██╗███████╗██████╗ ██╗███╗   ██╗ ██████╗ 
//  ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝████╗  ██║██╔════╝██╔══██╗██║████╗  ██║██╔════╝ 
//  ██████╔╝███████║██████╔╝   ██║   ██╔██╗ ██║█████╗  ██████╔╝██║██╔██╗ ██║██║  ███╗
//  ██╔═══╝ ██╔══██║██╔══██╗   ██║   ██║╚██╗██║██╔══╝  ██╔══██╗██║██║╚██╗██║██║   ██║
//  ██║     ██║  ██║██║  ██║   ██║   ██║ ╚████║███████╗██║  ██║██║██║ ╚████║╚██████╔╝
//  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 

    function setPartnerToMintChildrenForPunk(uint16 punkIndex, uint16 partnerIndex) external {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        partners[punkIndex] = partnerIndex;
        hasPartnerSet[punkIndex] = true;
        emit PartnerSet(punkOwner, punkIndex, partnerIndex);
    }
    
    function clearPartnerToMintChildrenForPunk(uint16 punkIndex) public {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        hasPartnerSet[punkIndex] = false;
        partners[punkIndex] = 0;
        emit PartnerCleared(punkOwner, punkIndex);
    }

    function mintDistributedChildrenForPartnerPunks(uint16 fatherIndex, uint16 motherIndex) external {
        require(hasPartnerSet[fatherIndex]);
        require(hasPartnerSet[motherIndex]);
        require(partners[fatherIndex] == motherIndex);
        require(partners[motherIndex] == fatherIndex);
        require(numberOfRemainingChildrenToMintForPunk(fatherIndex) >= 2);
        require(numberOfRemainingChildrenToMintForPunk(motherIndex) >= 2);
        
        address fatherOwner = punkIndexToAddress(fatherIndex);
        address motherOwner = punkIndexToAddress(motherIndex);
        virtualOwners[fatherIndex] = address(this);
        virtualOwners[motherIndex] = address(this);
        
        uint256 child1Index = CRYPTO_PUNKS_COUNT + lostPunkSociety.totalSupply();
        lostPunkSociety.mintLostPunk(fatherIndex, motherIndex);
        uint256 child2Index = CRYPTO_PUNKS_COUNT + lostPunkSociety.totalSupply();
        lostPunkSociety.mintLostPunk(fatherIndex, motherIndex);
        
        lostPunkSociety.safeTransferFrom(address(this), fatherOwner, child1Index);
        lostPunkSociety.safeTransferFrom(address(this), motherOwner, child2Index);
        
        virtualOwners[fatherIndex] = fatherOwner;
        virtualOwners[motherIndex] = motherOwner;
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