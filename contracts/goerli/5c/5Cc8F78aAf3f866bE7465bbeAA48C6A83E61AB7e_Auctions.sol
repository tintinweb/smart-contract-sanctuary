// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auctions is Ownable {
    constructor() {}
    // ------- structs ------- //
    struct Auction {
        uint256 start_price;
        address highest_bidder;
        address coin_buy;
        address creator;
        bool ended;
    }
    // ------- structs ------- //
    
    // ------- var ------- //
    address constant public EMPTY_ADDRESS = 0x0000000000000000000000000000000000000000;
    // ------- var ------- //

    // ------- mapping ------- //
    // mapping contract sale and id to bidding data;
    mapping(bytes32 => Auction) private mapTokenToAuction;
    // mapping bidder address, contract sale and id to bid amount
    mapping(bytes32 => uint256) private mapBiddedAddress;

    // start an auction
    function start(address _contract_sale, uint256 _token_id, address _coin_buy, uint256 _start_price) external {
        bytes32 hashed = sha256(abi.encodePacked(_contract_sale, _token_id));
        IERC721 contractSale = IERC721(_contract_sale);
        // must be owner
        require(contractSale.ownerOf(_token_id) == msg.sender, "NOT_OWNED");
        // transfer to sale contract
        contractSale.transferFrom(msg.sender, address(this), _token_id);
        // write data to map
        mapTokenToAuction[hashed] = Auction(_start_price, EMPTY_ADDRESS, _coin_buy, msg.sender, false);
    }

    // bid
    function bid(address _contract_sale, uint256 _token_id, uint256 amount) external {
        // get auction data out
        bytes32 hashedAuction = sha256(abi.encodePacked(_contract_sale, _token_id));
        require(mapTokenToAuction[hashedAuction].creator == EMPTY_ADDRESS, "NOT_EXISTED");
        
        bytes32 hashedBidder = sha256(abi.encodePacked(_contract_sale, _token_id, msg.sender));

        // transfer to sale contract
        IERC20 contractCoinBuy = IERC20(mapTokenToAuction[hashedAuction].coin_buy);

        contractCoinBuy.transferFrom(msg.sender, address(this), amount);
        mapBiddedAddress[hashedBidder] = mapBiddedAddress[hashedBidder] + amount;
        // must be higher than current highest bid
        bytes32 highestBidderHash = sha256(abi.encodePacked(_contract_sale, _token_id, mapTokenToAuction[hashedAuction].highest_bidder));
        require(mapBiddedAddress[highestBidderHash] < mapBiddedAddress[hashedBidder], "BID_TOO_LOW");
        mapTokenToAuction[hashedAuction].highest_bidder = msg.sender;
    }

    // return auction info
    function auctionInfo(address _contract_sale, uint256 _token_id) external view returns(
        uint256 start_price,
        address highest_bidder,
        address coin_buy,
        address creator,
        bool ended
    ) {
        bytes32 hashed = sha256(abi.encodePacked(_contract_sale, _token_id));
        start_price = mapTokenToAuction[hashed].start_price;
        highest_bidder = mapTokenToAuction[hashed].highest_bidder;
        coin_buy = mapTokenToAuction[hashed].coin_buy;
        creator = mapTokenToAuction[hashed].creator;
        ended = mapTokenToAuction[hashed].ended;
    }


    function biddedBalance(address _contract_sale, uint256 _token_id, address _bidder) external view returns(uint256 bidded) {
        bytes32 hashed = sha256(abi.encodePacked(_contract_sale, _token_id, _bidder));
        bidded = mapBiddedAddress[hashed];
    }

    // withdraw back when bidding is end
    function withdraw(address _contract_sale, uint256 _token_id) external {
        bytes32 hashedAuction = sha256(abi.encodePacked(_contract_sale, _token_id));
        bytes32 hashedBidder = sha256(abi.encodePacked(_contract_sale, _token_id, msg.sender));
        require(mapTokenToAuction[hashedAuction].creator == EMPTY_ADDRESS, "NOT_END_YET");
        IERC20 contractCoinBuy = IERC20(mapTokenToAuction[hashedAuction].coin_buy);
        contractCoinBuy.transferFrom(address(this), msg.sender, mapBiddedAddress[hashedBidder]);
    }

    // finish auction, only can call by creator to force stop auction. Asset will deliver to the highest bidded account
    function finish(address _contract_sale, uint256 _token_id) external {
        bytes32 hashed = sha256(abi.encodePacked(_contract_sale, _token_id));
        Auction memory auction;
        auction = mapTokenToAuction[hashed];
        require(auction.creator == msg.sender || this.owner() == msg.sender, "NO PERMISSION");
        IERC721 contractSale = IERC721(_contract_sale);
        // transfer asset
        if (auction.highest_bidder == EMPTY_ADDRESS) {
            // if highest bidded is empty, send back to creator
            contractSale.transferFrom(address(this), auction.creator, _token_id);
        } else {
            IERC20 contractCoin = IERC20(auction.coin_buy);
            // if exist bidder, transfer to bidder
            contractSale.transferFrom(address(this), auction.highest_bidder, _token_id);
            bytes32 hashedBidder = sha256(abi.encodePacked(_contract_sale, _token_id, auction.highest_bidder));
            uint256 amount = mapBiddedAddress[hashedBidder];
            // transfer coin buy to creator
            contractCoin.transfer(auction.creator, amount);
        }
        auction.ended = true;
    }
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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