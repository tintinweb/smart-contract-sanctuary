// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/GotTokenInterface.sol";
import "../interfaces/OGColorInterface.sol";

library Customizer {
    
    function safeOwnerOf(IERC721 callingContract, uint256 tokenId) public view returns (address) {
        
        address ownerOfToken = address(0);
                
        try callingContract.ownerOf(tokenId) returns (address a) {
            ownerOfToken = a;
        }
        catch { }

        return ownerOfToken;
    }

    function getColors(IERC721 callingContract, address ogColorContractAddress, uint256 tokenId) external view returns (string memory back, string memory frame, string memory digit, string memory slug) {

        address ownerOfToken = safeOwnerOf(callingContract, tokenId);
        if (ownerOfToken != address(0)) {
            if (ogColorContractAddress != address(0)) {
                OGColorInterface ogColorContract = OGColorInterface(ogColorContractAddress);
                try ogColorContract.getColors(ownerOfToken, tokenId) returns (string memory extBack, string memory extFrame, string memory extDigit, string memory extSlug) {
                    return (extBack, extFrame, extDigit, extSlug);
                }
                catch { }
            }
        }
        
        return ("<linearGradient id='back'><stop stop-color='#FFFFFF'/></linearGradient>",
                "<linearGradient id='frame'><stop stop-color='#000000'/></linearGradient>",
                "<linearGradient id='digit'><stop stop-color='#000000'/></linearGradient>",
                "<linearGradient id='slug'><stop stop-color='#FFFFFF'/></linearGradient>");
    }

    function getColorAttributes(IERC721 callingContract, address ogColorContractAddress, uint256 tokenId) external view returns (string memory) {

        address ownerOfToken = safeOwnerOf(callingContract, tokenId);
        if (ownerOfToken != address(0)) {
            if (ogColorContractAddress != address(0)) {
                OGColorInterface ogColorContract = OGColorInterface(ogColorContractAddress);
                try ogColorContract.getOgAttributes(ownerOfToken, tokenId) returns (string memory extAttributes) {
                    return extAttributes;
                }
                catch { }
            }
        }
        
        return "";
    }
    
    function getOwnedSupportedCollection(IERC721 callingContract, address gotTokenContractAddress, address[] memory supportedCollections, uint256 tokenId) external view returns (address) {
        
        if (gotTokenContractAddress == address(0))
            return address(0);
        
        address ownerOfToken = safeOwnerOf(callingContract, tokenId);
        if (ownerOfToken == address(0))
            return address(0);
    
        bool[] memory ownsTokens;
        
        GotTokenInterface gotTokenContract = GotTokenInterface(gotTokenContractAddress);        
        try gotTokenContract.ownsTokenOfContracts(ownerOfToken, supportedCollections, tokenId) returns (bool[] memory returnValue) {
            ownsTokens = returnValue;
        }
        catch { return address(0); }

        // find the first contract which is owned
        for (uint256 i = 0; i < ownsTokens.length; i++) {
            if (ownsTokens[i])
                return supportedCollections[i];
        }

        return address(0);
    }

    function suggestFreeIds(IERC721 callingContract, uint16 desiredCount, uint256 minValue, uint256 maxValue, uint256 seed) public view returns (uint256[] memory) {
        require(desiredCount > 0 && desiredCount < 11, "Desired count too low or too large");
        require(minValue >= 0, "Min value too low or too large");
        require(maxValue > 0 && maxValue > minValue, "Max value too low or too large");

        uint256[] memory freeIds = new uint256[](desiredCount);
        uint16 approach = 0;
        uint16 count = 0;
        
        // try to find some random free ids
        for (uint16 i = 0; i < desiredCount; i++) {

            uint256 rnd = random(approach++ + seed, maxValue);
            if (rnd >= minValue && safeOwnerOf(callingContract, rnd) == address(0)) {
                freeIds[count++] = rnd;
                if (count >= desiredCount) {
                    return freeIds;
                }
            }

            // if we have a lot of minted tokens, it might get hard to find random numbers, so stop
            if (approach > 100)
                break;
        }

        // we tried so hard and got so far - but we did not find random free ids, so take free ones sequentially
        count = 0;
        // https://ethereum.stackexchange.com/questions/63653/why-i-cannot-loop-through-array-backwards-in-solidity/63654
        for (uint256 id = maxValue; id >= 0; id--) {
            if (safeOwnerOf(callingContract, id) == address(0)) {
                freeIds[count] = id - 1;
                count++;
                if (count >= desiredCount) {
                    break;
                }
            }
        }

        return freeIds;
    }

    /**
    * @dev I am aware that these are only pseudo random numbers and that they can be predicted.
    * However, exploiting this method won't get an attacker much benefit as these random numbers
    * are just used to suggest some free token ids to mint.
    * Anyone can choose his favorite ids while minting.
    */
    function random(uint256 seed, uint256 maxValue) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed))) % maxValue;      
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the OGColor contract to get the colors to render OG svgs
 * @author nfttank.eth
 */
interface OGColorInterface {
    function getColors(address forAddress, uint256 tokenId) external view returns (string memory back, string memory frame, string memory digit, string memory slug);
    function getOgAttributes(address forAddress, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the GotToken contract to check if an address owns a given token of a given contract
 * @author nfttank.eth
 */
interface GotTokenInterface {
    function ownsTokenOfContract(address possibleOwner, address contractAddress, uint256 tokenId) external view returns (bool);
    function ownsTokenOfContracts(address possibleOwner, address[] calldata upToTenContractAddresses, uint256 tokenId) external view returns (bool[] memory);
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