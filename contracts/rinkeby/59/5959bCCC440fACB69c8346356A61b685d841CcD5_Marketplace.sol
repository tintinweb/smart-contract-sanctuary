// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./INFT.sol";

contract Marketplace {

    event OfferingPlaced(uint indexed offeringId, address indexed hostContract, address indexed offerer,  uint tokenId, uint price, string uri, bool minted);
    event OfferingClosed(uint indexed offeringId, address indexed buyer);
    event BalanceWithdrawn (address indexed beneficiary, uint amount);

    uint private offeringNonce;

    struct Offering {
        address offerer;
        address hostContract;
        uint tokenId;
        uint price;
        bool closed;
        bool minted;
    }

    mapping (uint => Offering) private offeringRegistry;
    mapping (address => uint) private balances;

    function placeOffering (address _offerer, address _hostContract, uint _tokenId, uint _price) external returns (uint){
        (uint offeringId, string memory uri) = _placeOffering(_offerer, _hostContract, _tokenId, _price, true);
        emit  OfferingPlaced(offeringId, _hostContract, _offerer, _tokenId, _price, uri, true);

        return offeringId;
    }

    function placeOfferingForUnminted (address _offerer, address _hostContract, uint _tokenId, uint _price) external returns (uint){
        (uint offeringId, string memory uri) = _placeOffering(_offerer, _hostContract, _tokenId, _price, false);
        emit  OfferingPlaced(offeringId, _hostContract, _offerer, _tokenId, _price, uri, false);

        return offeringId;
    }

    function _placeOffering (address _offerer, address _hostContract, uint _tokenId, uint _price, bool _minted) internal returns (uint, string memory){
        uint offeringId = uint(keccak256(abi.encodePacked(offeringNonce, _hostContract, _tokenId)));

        offeringRegistry[offeringId].offerer = _offerer;
        offeringRegistry[offeringId].hostContract = _hostContract;
        offeringRegistry[offeringId].tokenId = _tokenId;
        offeringRegistry[offeringId].price = _price;
        offeringRegistry[offeringId].minted = _minted;
        offeringNonce += 1;

        string memory uri = INFT(offeringRegistry[offeringId].hostContract).tokenURI(_tokenId);

        return (offeringId, uri);
    }

    function removeOffering(uint _offeringId) external {
        Offering storage offering = offeringRegistry[_offeringId];
        if (offering.closed) {
            revert("Offering is already closed");
        }
        if (offering.offerer != msg.sender) {
            revert("Only the offerer can remove");
        }
        delete offeringRegistry[_offeringId];
        emit OfferingClosed(_offeringId, msg.sender);
    }
    
    function closeOffering(uint _offeringId) external payable {
        Offering storage offering = offeringRegistry[_offeringId];
        require(msg.value >= offering.price, "Not enough funds to buy");
        require(offering.closed != true, "Offering is closed");

        if (offering.minted) {
            INFT(offering.hostContract).safeTransferFrom(offering.offerer, msg.sender, offering.tokenId);
        } else {
            INFT(offering.hostContract).mint(msg.sender, offering.tokenId);
        }
        offering.closed = true;
        balances[offering.offerer] += msg.value;

        emit OfferingClosed(_offeringId, msg.sender);
    } 

    function withdrawBalance() external {
        require(balances[msg.sender] > 0,"NOT ENOUGH BALANCE");

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit BalanceWithdrawn(msg.sender, amount);
    }

    function viewOfferingNFT(uint _offeringId) external view returns (address, uint, uint, bool){
        return (offeringRegistry[_offeringId].hostContract, offeringRegistry[_offeringId].tokenId, offeringRegistry[_offeringId].price, offeringRegistry[_offeringId].closed);
    }

    function viewBalances(address _address) external view returns (uint) {
        return (balances[_address]);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface INFT is IERC721, IERC721Metadata {
    function mint(address _to, uint256 _tokenId) external;
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