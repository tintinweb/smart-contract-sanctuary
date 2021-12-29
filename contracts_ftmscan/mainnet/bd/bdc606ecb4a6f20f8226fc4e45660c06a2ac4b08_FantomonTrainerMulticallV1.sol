/**
 *Submitted for verification at FtmScan.com on 2021-12-29
*/

/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.9;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)



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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)



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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)



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


// File contracts/IFantomonTrainerInteractive.sol






interface IFantomonTrainerInteractive is IERC721Enumerable, IERC721Metadata {

    /**************************************************************************
     * Stats and attributes for all trainers
     **************************************************************************/
    function getKinship(uint256 _tokenId) external view returns (uint256);
    function getFlare(uint256 _tokenId) external view returns (uint256);
    function getCourage(uint256 _tokenId) external view returns (uint256);
    function getWins(uint256 _tokenId) external view returns (uint256);
    function getLosses(uint256 _tokenId) external view returns (uint256);
    /* Stats and attributes for all trainers
     **************************************************************************/

    /**************************************************************************
     * Getters
     **************************************************************************/
    function location_(uint256 _tokenId) external view returns (address);
    function getStatus(uint256 _tokenId) external view returns (uint8);
    function getRarity(uint256 _tokenId) external view returns (uint8);
    function getClass(uint256 _tokenId) external view returns (uint8);
    function getFace(uint256 _tokenId) external view returns (uint8);
    function getHomeworld(uint256 _tokenId) external view returns (uint8);
    function getTrainerName(uint256 _tokenId) external view returns (string memory);
    function getHealing(uint256 _tokenId) external view returns (uint256);
    /* End getters
     **************************************************************************/

    /**************************************************************************
     * Interactions callable by location contracts
     **************************************************************************/
    function _enterBattle(uint256 _tokenId) external;
    function _leaveArena(uint256 _tokenId, bool _won) external;
    function _leaveHealingRift(uint256 _tokenId) external;
    function _leaveJourney(uint256 _tokenId) external;
    function _leave(uint256 _tokenId) external;
    /* End interactions callable by location contracts
     **************************************************************************/
}


// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721.sol)




// File contracts/IFantomonTrainer.sol





interface IFantomonTrainer {

    /**************************************************************************
     * Stats and attributes for all trainers
     **************************************************************************/
    function getKinship(uint256 _tokenId) external view returns (uint256);
    function getFlare(uint256 _tokenId) external view returns (uint256);
    function getCourage(uint256 _tokenId) external view returns (uint256);
    function getWins(uint256 _tokenId) external view returns (uint256);
    function getLosses(uint256 _tokenId) external view returns (uint256);
    /* Stats and attributes for all trainers
     **************************************************************************/

    /**************************************************************************
     * Getters
     **************************************************************************/
    function getStatus(uint256 _tokenId) external view returns (uint8);
    function getRarity(uint256 _tokenId) external view returns (uint8);
    function getClass(uint256 _tokenId) external view returns (uint8);
    function getFace(uint256 _tokenId) external view returns (uint8);
    function getHomeworld(uint256 _tokenId) external view returns (uint8);
    function getTrainerName(uint256 _tokenId) external view returns (string memory);
    function getHealing(uint256 _tokenId) external view returns (uint256);
    /* End getters
     **************************************************************************/
}


// File contracts/IFantomonTrainerGraphicsV2.sol

interface IFantomonTrainerGraphicsV2 {
    function      imageURI(uint256 _tokenId) external view returns (string memory);
    function    overlayURI(uint256 _tokenId) external view returns (string memory);
    function iosOverlayURI(uint256 _tokenId) external view returns (string memory);
    function      tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721NFT is IERC721, IERC721Enumerable, IERC721Metadata {
}


// File contracts/FantomonTrainerMulticallV1.sol

/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/





contract FantomonTrainerMulticallV1 {

    uint256 constant TOTAL_SUPPLY = 10000;

    IFantomonTrainerInteractive trainer_;
    IFantomonTrainerGraphicsV2 graphics_;

    constructor (address _trainer, address _graphics) {
        trainer_  = IFantomonTrainerInteractive(_trainer);
        graphics_ = IFantomonTrainerGraphicsV2(_graphics);
    }


    struct Trainer {
        uint16 tokenId;
        uint64 kinship;
        uint64 flare;
        uint64 healing;
        uint64 courage;
        uint64 wins;
        uint64 losses;
        uint8 rarity;
        uint8 class;
        uint8 face;
        uint8 homeworld;
    }
    struct NFT {
        uint256 tokenId;
        string uri;
    }
    struct TrainerNFT {
        uint256 tokenId;
        string uri;
        Trainer trainer;
    }

    function _batchIds(uint256 _batchIdx, uint256 _batchSize) internal pure returns (uint256, uint256) {
        uint256 startTok = 1 + _batchIdx*_batchSize;  // tokenIds start at 1
        uint256 endTok   = 1 + (_batchIdx+1)*_batchSize;
        if (endTok > TOTAL_SUPPLY) {
            endTok = TOTAL_SUPPLY;
        }
        return (startTok, endTok);
    }

    function _batchIdxsOfUser(address _user, uint256 _batchIdx, uint256 _batchSize) internal view returns (uint256, uint256) {
        uint256 startTok = _batchIdx*_batchSize;
        uint256 endTok   = (_batchIdx+1)*_batchSize;
        uint256 bal      = trainer_.balanceOf(_user);
        if (bal < endTok) {
            endTok = bal;
        }
        return (startTok, endTok);
    }

    function tokensOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (uint256[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        uint256[] memory tokenIds = new uint256[](_batchSize);
        for (tok = startTok; tok < endTok; tok++) {
            tokenIds[idx] = trainer_.tokenOfOwnerByIndex(_user, tok);
            idx++;
        }
        return tokenIds;
    }

    function urisOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (string[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        string[] memory uris = new string[](_batchSize);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            uris[idx] = trainer_.tokenURI(tokenId);
            idx++;
        }
        return uris;
    }

    function nftsOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (NFT[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        NFT[] memory nfts = new NFT[](_batchSize);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            nfts[idx] = NFT(tokenId, trainer_.tokenURI(tokenId));
            idx++;
        }
        return nfts;
    }

    function trainer(uint256 _tokenId) public view returns (Trainer memory) {
        return Trainer(uint16(_tokenId),
                       uint64(trainer_.getKinship(_tokenId)) , uint64(trainer_.getFlare(_tokenId))     ,
                       uint64(trainer_.getHealing(_tokenId)) , uint64(trainer_.getCourage(_tokenId))   ,
                       uint64(trainer_.getWins(_tokenId))    , uint64(trainer_.getLosses(_tokenId))    ,
                       trainer_.getRarity(_tokenId)  , trainer_.getClass(_tokenId)     ,
                       trainer_.getFace(_tokenId)    , trainer_.getHomeworld(_tokenId));
    }

    function trainersBatch(uint256 _batchIdx, uint256 _batchSize) public view returns (Trainer[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIds(_batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        Trainer[] memory trainers = new Trainer[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            trainers[idx] = trainer(tok);
            idx++;
        }
        return trainers;
    }

    function trainersOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (Trainer[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        Trainer[] memory trainers = new Trainer[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            trainers[idx] = trainer(tokenId);
            idx++;
        }
        return trainers;
    }

    function multiviewTrainersOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (TrainerNFT[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        TrainerNFT[] memory trainers = new TrainerNFT[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            string memory uri = graphics_.tokenURI(tokenId);
            trainers[idx] = TrainerNFT(tokenId, uri, trainer(tokenId));
            idx++;
        }
        return trainers;
    }
}
/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/