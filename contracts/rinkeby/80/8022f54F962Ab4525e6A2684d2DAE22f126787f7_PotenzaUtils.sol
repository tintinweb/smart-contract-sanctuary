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
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IN is IERC721Enumerable, IERC721Metadata {
    function getFirst(uint256 tokenId) external view returns (uint256);

    function getSecond(uint256 tokenId) external view returns (uint256);

    function getThird(uint256 tokenId) external view returns (uint256);

    function getFourth(uint256 tokenId) external view returns (uint256);

    function getFifth(uint256 tokenId) external view returns (uint256);

    function getSixth(uint256 tokenId) external view returns (uint256);

    function getSeventh(uint256 tokenId) external view returns (uint256);

    function getEight(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "../interfaces/IN.sol";

library PotenzaUtils {

    function getZeroOrFourteenScore(uint256 tokenId, IN n) public view returns(uint256) {
        if(n.getFirst(tokenId) == 0 || n.getFirst(tokenId) == 14 ||
        n.getSecond(tokenId) == 0 || n.getSecond(tokenId) == 14 ||
        n.getThird(tokenId) == 0 || n.getThird(tokenId) == 14 ||
        n.getFourth(tokenId) == 0 || n.getFourth(tokenId) == 14 ||
        n.getFifth(tokenId) == 0 || n.getFifth(tokenId) == 14 ||
        n.getSixth(tokenId) == 0 || n.getSixth(tokenId) == 14 ||
        n.getSeventh(tokenId) == 0 || n.getSeventh(tokenId) == 14 ||
        n.getEight(tokenId) == 0 || n.getEight(tokenId) == 14) {
            return 20;
        }
        return 0;
    }

    function getMaxSequence(uint256 tokenId,IN n) public view returns(uint256) {
        uint256 count = 1;
        uint256 highest = 1;
        uint256[8] memory  sequenceArray = [n.getFirst(tokenId),n.getSecond(tokenId),n.getThird(tokenId),n.getFourth(tokenId),n.getFifth(tokenId),n.getSixth(tokenId),n.getSeventh(tokenId),n.getEight(tokenId)];
        for(uint256 i = 1; i < sequenceArray.length;i++) {
            if(sequenceArray[i-1] == sequenceArray[i]) {
                count += 1;
                if(i == sequenceArray.length-1 && count > highest) {
                    highest = count;
                }
            } else {
                if(count > highest) {
                    highest = count;
                }
                count = 1;
            }
        }
        return highest;
    }

    function getSum(uint256 tokenId,IN n) public view returns(uint256) {
        return n.getFirst(tokenId)+
        n.getSecond(tokenId)+
        n.getThird(tokenId)+
        n.getFourth(tokenId)+
        n.getFifth(tokenId)+
        n.getSixth(tokenId)+
        n.getSeventh(tokenId)+
        n.getEight(tokenId);
    }

    function getHighestFrequency(uint256 tokenId, IN n) public view returns(uint256[3] memory) {
        uint256[15] memory set;
        set[n.getFirst(tokenId)] = set[n.getFirst(tokenId)]+1;
        set[n.getSecond(tokenId)] = set[n.getSecond(tokenId)]+1;
        set[n.getThird(tokenId)] = set[n.getThird(tokenId)]+1;
        set[n.getFourth(tokenId)] = set[n.getFourth(tokenId)]+1;
        set[n.getFifth(tokenId)] = set[n.getFifth(tokenId)]+1;
        set[n.getSixth(tokenId)] = set[n.getSixth(tokenId)]+1;
        set[n.getSeventh(tokenId)] = set[n.getSeventh(tokenId)]+1;
        set[n.getEight(tokenId)] = set[n.getEight(tokenId)]+1;
        uint256[3] memory highest;

        for(uint256 i = 1; i < set.length;i++) {
            if(set[i] > highest[0]) {
                highest[2] = highest[1];
                highest[1] = highest[0];
                highest[0] = set[i];
            } else {
                if(set[i] > highest[1]) {
                    highest[2] = highest[1];
                    highest[1] = set[i];
                } else {
                    if(set[i] > highest[2]) {
                        highest[2] = set[i];
                    }
                }
            }
        }
        return highest;
    }
}