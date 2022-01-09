/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// 

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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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


// File contracts/8/ILion.sol

pragma solidity ^0.8.0;

interface ILion is IERC721EnumerableUpgradeable {

    enum Gender { male,  female }

    struct Lion {
        
        string name;

        Gender gender;
        uint256 hair;
        uint256 eye;
        uint256 mouth;
        uint256 background;

        uint256 generation;

        uint256 birthTime;

        uint256 matronId;
        uint256 sireId;
        uint256[]  offsprings;

        uint256 breedCount;
        uint256 lastBreedTime;
    }


    function getLion(uint256 _tokenId) external view returns(Lion memory);

    
    function isOnAuction(uint256 _tokenId) external view returns (bool);

}


// File contracts/8/IAuction.sol

pragma solidity ^0.8.0;


interface IAuction {

    struct Auction {
        uint256 price;
        uint256 duration;
        uint256 startedAt;
    }

    function isOnAuction(uint256 _tokenId) external view returns (bool);

    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        uint256 auctionDuration,
        address _seller
    ) external;

    function bid(
        address _buyer, 
        uint256 _tokenId 
    ) external;

    function getAuction(uint256 _tokenId) external view returns (Auction memory);
    
    function getPrice(uint256 _tokenId) external view returns (uint256);
}


// File contracts/8/LionInterfaceWithMarket.sol

pragma solidity ^0.8.0;



interface INFTMarket {

    struct Ask {
        address seller; // address of the seller
        uint256 price; // price of the token
    }

    function viewAsksByCollectionAndSeller(
        address collection,
        address seller,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory tokenIds,
            Ask[] memory askInfo,
            uint256
        );

    function viewAsksByCollectionAndTokenIds(
        address collection, 
        uint256[] calldata tokenIds
    )
        external
        view
        returns (
            bool[] memory statuses, 
            Ask[] memory askInfo
        );
}


contract LionInterface {

    using SafeMath for uint256;

    IAuction public siringAuction;
    ILion public nonFungibleContract;
    INFTMarket public nftMarket;


    struct LionSimple{
        uint256 LionId;
        ILion.Lion Lion;
        IAuction.Auction auctionInfo;
        bool isOnAuction;
    }

    struct LionSimpleWithPrice{
        uint256 LionId;
        ILion.Lion Lion;
        IAuction.Auction auctionInfo;
        bool isOnAuction;
        uint256 price;
    }


    struct LionDetail {
        LionSimple Lion;
        LionSimple matron;
        LionSimple sire;
        LionSimple[]  offsprings;
        // INFTMarket.Ask[] price;
        uint256 price;
    }


    constructor(address _nftAddress, address _siringAuction, address _nftMarket) {
        nonFungibleContract = ILion(_nftAddress);
        siringAuction = IAuction(_siringAuction);
        nftMarket = INFTMarket(_nftMarket);
    }
    

    function getLionSimple(uint256 _tokenId) public view returns(LionSimple memory){
        ILion.Lion memory _Lion = nonFungibleContract.getLion(_tokenId);

        IAuction.Auction memory _auctionInfo = siringAuction.getAuction(_tokenId);
        bool _isOnAuction = siringAuction.isOnAuction(_tokenId);

        LionSimple memory lionSimple = LionSimple({
            LionId: _tokenId,
            Lion: _Lion,
            auctionInfo: _auctionInfo,
            isOnAuction: _isOnAuction
        });
        return lionSimple;
    }


    function getLionSimpleWithPrice(uint256 _tokenId, uint256 _price) public view returns(LionSimpleWithPrice memory){
        ILion.Lion memory _Lion = nonFungibleContract.getLion(_tokenId);

        IAuction.Auction memory _auctionInfo = siringAuction.getAuction(_tokenId);
        bool _isOnAuction = siringAuction.isOnAuction(_tokenId);

        LionSimpleWithPrice memory lionSimple = LionSimpleWithPrice({
            LionId: _tokenId,
            Lion: _Lion,
            auctionInfo: _auctionInfo,
            isOnAuction: _isOnAuction,
            price: _price
        });
        return lionSimple;
    }


    function tokensOfOwner(address _owner) external view returns(LionSimpleWithPrice[] memory) {
        
        uint256 tokenCount = nonFungibleContract.balanceOf(_owner);

        (uint256[] memory tokenIds, INFTMarket.Ask[] memory askInfo, uint256 marketCount) = nftMarket.viewAsksByCollectionAndSeller(address(nonFungibleContract), _owner, 0, 200);

        LionSimpleWithPrice[] memory result = new LionSimpleWithPrice[](tokenCount + marketCount);

        for (uint256 index = 0; index < tokenCount; index++) {
            uint256 tokenId = nonFungibleContract.tokenOfOwnerByIndex(_owner, index);
            result[index] = getLionSimpleWithPrice(tokenId, 0);
        }
        for (uint256 index = 0; index < marketCount; index++) {
            result[tokenCount + index] = getLionSimpleWithPrice(tokenIds[index], askInfo[index].price);
        }

        return result;

        // if (tokenCount == 0) {
        //     return new LionSimple[](0);
        // } else {
        //     LionSimple[] memory result = new LionSimple[](tokenCount);
        //     for (uint256 index = 0; index < tokenCount; index++) {
        //         uint256 tokenId = nonFungibleContract.tokenOfOwnerByIndex(_owner, index);
        //         result[index] = getLionSimple(tokenId);
        //     }
        //     return result;
        // }
    }


    function getLionDetail(uint256 _tokenId) external view returns(LionDetail memory) {

        LionSimple memory _LionSimple = getLionSimple(_tokenId);
        ILion.Lion memory _Lion = _LionSimple.Lion;
        LionSimple[] memory _offsprings = new LionSimple[](_Lion.offsprings.length);
        for (uint256 index = 0; index < _Lion.offsprings.length; index++) {
            uint256 tokenId = _Lion.offsprings[index];
            _offsprings[index] = getLionSimple(tokenId);
        }
        uint256 _matronId = _Lion.matronId;
        uint256 _sireId = _Lion.sireId;
        LionSimple memory _matron = getLionSimple(_matronId);
        LionSimple memory _sire = getLionSimple(_sireId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        (, INFTMarket.Ask[] memory askInfo) = nftMarket.viewAsksByCollectionAndTokenIds(address(nonFungibleContract), tokenIds);


        LionDetail memory h = LionDetail({
            Lion: _LionSimple,
            matron: _matron,
            sire: _sire,
            offsprings: _offsprings,
            price: askInfo[0].price
        });

        return h;
    }


}