pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract DutchAution is Ownable {

    IERC721 public nftContract;
    uint256 public royaltyRate;

    uint256 public constant MAX_ROYALTY = 1000;//10%
    uint256 public constant MIN_DURATION = 1 hours;

    enum AutionStatus{
        OPEN,
        FINISHED,
        CANCELLED
    }

    struct Aution{
        uint256 tokenId;
        address seller;
        uint256 startPrice;
        uint256 endPrice;
        uint256 duration;
        uint256 startedAt;
        AutionStatus status;
    }

    Aution[] public autions;   
    mapping(uint256 => uint256) public tokenIdToAution;

    event AuctionCreated(uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    constructor(address _nftContract, uint256 _royaltyRate){
        IERC721 _IERC721 = IERC721(_nftContract);

        require(_IERC721.supportsInterface(type(IERC721).interfaceId), "_nftContract not support IERC721");
        require(_royaltyRate <= MAX_ROYALTY, "_royaltyRate exceed MAX_ROYALTY");

        nftContract = _IERC721;
        royaltyRate = _royaltyRate;
        autions.push(Aution({//避免AutionId出现0，AutionId=0默认是未拍卖
            tokenId: 0,
            seller: address(0),
            startPrice: 0,
            endPrice: 0,
            duration: 0,
            startedAt: 0,
            status: AutionStatus.CANCELLED
        }));
    }

    function createAution(uint256 _tokenId, uint256 _startPrice, uint256 
        _endPrice, uint256 _duration) external onlyOwner {

        require(_duration >= MIN_DURATION, "_duration less than MIN_DURATION");
        require(_startPrice >= _endPrice, "_startPrice less than _endPrice");
        require(nftContract.ownerOf(_tokenId) == msg.sender, "this nft not belong to you");
        
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        uint256 autionId = autions.length;
        tokenIdToAution[_tokenId] = autionId;

        autions.push(Aution({
            tokenId: _tokenId,
            seller: msg.sender,
            startPrice: _startPrice,
            endPrice: _endPrice,
            duration: _duration,
            startedAt: block.timestamp,
            status: AutionStatus.OPEN
        }));

        emit AuctionCreated(_tokenId, _startPrice, _endPrice, _duration);
    }

    function cancelAution(uint256 _tokenId) external {
        Aution storage aution = autions[tokenIdToAution[_tokenId]];

        require(aution.seller == msg.sender, "aution.seller is not you");
        require(aution.status == AutionStatus.OPEN, "aution not open");

        nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);
        aution.status = AutionStatus.CANCELLED;
        delete tokenIdToAution[_tokenId];

        emit AuctionCancelled(_tokenId);
    }

    function bid(uint256 _tokenId) external payable {

        Aution storage aution = autions[tokenIdToAution[_tokenId]];
        uint256 currentPrice = _computeCurrentPrice(aution);
        
        require(aution.status == AutionStatus.OPEN, "aution not open");
        require(msg.value >= currentPrice, "pay not enough");

        if(currentPrice > 0){
            uint256 royalty = _computeRoyalty(currentPrice);
            payable(aution.seller).transfer(currentPrice-royalty);
        }

        aution.status = AutionStatus.FINISHED;
        delete tokenIdToAution[_tokenId];
        nftContract.safeTransferFrom(address(this), msg.sender, aution.tokenId);

        emit AuctionSuccessful(_tokenId, currentPrice, msg.sender);
    }

    function computeCurrentPrice(uint256 _tokenId) external view returns (uint256){
        Aution storage aution = autions[tokenIdToAution[_tokenId]];
        require(aution.status == AutionStatus.OPEN, "aution not open");
        return _computeCurrentPrice(aution);
    }

    function _computeCurrentPrice(Aution memory aution) internal view returns (uint256){
        uint256 secondsPassed = block.timestamp - aution.startedAt;
        if(secondsPassed >= aution.duration ){
            return aution.endPrice;
        }
        int256 totalPriceChange = int256(aution.endPrice) - int256(aution.startPrice);
        int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int256(aution.duration);
        int256 currentPrice = int256(aution.startPrice) + currentPriceChange;
        return uint256(currentPrice);
    }

    function _computeRoyalty(uint256 currentPrice) internal view returns (uint256) {
        return currentPrice * royaltyRate / 10000 ;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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