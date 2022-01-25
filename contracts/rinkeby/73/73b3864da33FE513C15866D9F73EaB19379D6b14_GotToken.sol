// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Checks if a given address owns a token from a given ERC721 contract or the CryptoPunks contract (which does not implement ERC721)
 * @author nfttank.eth
 */
contract GotToken {
    
    /**
     * @dev Checks whether a given address (possibleOwner) owns a given token by its contract address and the token id itself.
     * This method can only check contracts implementing the ERC721 standard and in addition the CryptoPunks contract
     * (with a custom implementation because CryptoPunks do not implement the ERC721 standard).
     *
     * Does not throw errors but returns false if the real token owner could not be found or the token does not exist.
     *
     * Sample contract addresses on Mainnet
     *   CryptoPunks:           0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8     
     *   Bored Ape Yacht Club:  0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
     *   Cool Cats:             0x1A92f7381B9F03921564a437210bB9396471050C
     *   CrypToadz:             0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
     */     
    function ownsTokenOfContract(address possibleOwner, address contractAddress, uint256 tokenId) public view returns (bool) {
        try this.unsafeOwnsTokenOfContract(possibleOwner, contractAddress, tokenId) returns (bool b) {
            return b;
        } catch { 
            return false; 
        }  
    }
        
    /**
     * @dev Checks whether a given address (possibleOwner) owns a given token by its contract address and the token id itself.
     * This method can only check contracts implementing the ERC721 standard and in addition the CryptoPunks contract
     * (with a custom implementation because CryptoPunks do not implement the ERC721 standard).
     *
     * Might revert execution if the contract address does not exist on the current net.
     *
     * Sample contract addresses on Mainnet
     *   CryptoPunks:           0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8     
     *   Bored Ape Yacht Club:  0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
     *   Cool Cats:             0x1A92f7381B9F03921564a437210bB9396471050C
     *   CrypToadz:             0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
     */ 
    function unsafeOwnsTokenOfContract(address possibleOwner, address contractAddress, uint256 tokenId) public view returns (bool) {

        address CryptoPunksContractMainnet = 0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8;
        address realTokenOwner = address(0);

        if (contractAddress == CryptoPunksContractMainnet) {
            CryptoPunksInterface punksContract = CryptoPunksInterface(CryptoPunksContractMainnet);
            realTokenOwner = punksContract.punkIndexToAddress(tokenId);
        }
        else {
            IERC721 ercContract = IERC721(contractAddress);
            realTokenOwner = ercContract.ownerOf(tokenId);
        }

        return possibleOwner == realTokenOwner && realTokenOwner != address(0);
    }
    

    /**
     * @dev Checks whether a given address (possibleOwner) owns a given token by given contract addresses and the token id itself.
     * This method can only check contracts implementing the ERC721 standard and in addition the CryptoPunks contract
     * (with a custom implementation because CryptoPunks do not implement the ERC721 standard).
     * Does not throw errors but returns false if the real token owner could not be found or the token does not exist.
     * 
     * Returns an array with the results at the given index of the array.
     *
     * Sample contract addresses on Mainnet
     *   CryptoPunks:           0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8     
     *   Bored Ape Yacht Club:  0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
     *   Cool Cats:             0x1A92f7381B9F03921564a437210bB9396471050C
     *   CrypToadz:             0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
     */ 
    function ownsTokenOfContracts(address possibleOwner, address[] calldata contractAddresses, uint256 tokenId) public view returns (bool[] memory) {

        bool[] memory result = new bool[](contractAddresses.length);

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            result[i] = ownsTokenOfContract(possibleOwner, contractAddresses[i], tokenId);
        }

        return result;
    }
}

/**
 * The CryptoPunks contract doesn't implement the ERC721 standard so we have to use this interface to call their method punkIndexToAddress()
 */
interface CryptoPunksInterface {
    function punkIndexToAddress(uint tokenId) external view returns(address);
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