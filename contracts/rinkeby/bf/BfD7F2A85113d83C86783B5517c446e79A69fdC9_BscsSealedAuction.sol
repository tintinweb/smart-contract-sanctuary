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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BscsSealedAuction is ERC721Holder, Pausable, Ownable {
    address private feeAddr; //
    uint private feePecent; // x100 e.g. 2% then feePecent is 200

    uint blockTimeCount;

    uint bidIncrement; //wei
    uint private auctionId;

    //Auction state
    enum State {
        Started,
        Running,
        Ended,
        Cancelled
    }

    struct Auction {
        uint id;
        address seller;
        uint tokenId;
        address tokenAddress;
        uint price; // wei
        uint startBlock; // time
        uint duration;
        State auctionState;
        uint highestBindingBid;
        address highestBidder;
        mapping(address => uint)  bidderToAmount;
    }

    //ERC721 address => token id => auction flag
    mapping(address => mapping(uint => bool)) private hasAuction;

    mapping(uint => Auction) internal auctionIdToAuction;

    event AuctionCreated(
      uint id,
      address seller,
      uint tokenId,
      address tokenAddress,
      uint price, // wei
      uint startBlock, // time
      uint duration,
      State auctionState,
      uint highestBindingBid,
      address highestBidder
    );

    event AuctionBid(
        uint auctionId,
        address seller,
        address indexed bidder,
        address indexed tokenAddress,
        uint indexed tokenId,
        uint price
    );

    event AuctionEnded(
        uint auctionId,
        address seller,
        address indexed winner,
        address indexed tokenAddress,
        uint indexed tokenId,
        uint price
    );

    event AuctionCancelled(uint auctionId, uint tokenId);

    constructor(address _feeAddr, uint _feePecent) {
        feeAddr = _feeAddr;
        feePecent = _feePecent;
        bidIncrement = 100; //wei
        blockTimeCount = 14; // set 14 seconds by default
    }

    receive() external payable {}

    function min(uint a, uint b) internal pure returns (uint) {
        if (a > b) {
            return b;
        }
        return a;
    }
    function updateBlockTime(uint _newBlockTimeCount) public onlyOwner {
        blockTimeCount = _newBlockTimeCount;
    }

    // get roughly block number for given timestamp in the future
    function getEndBlockNumber(uint _blockStart, uint _duration)
        view
        internal
        returns (uint)
    {
        return
            uint(_blockStart) +
            (uint(_duration) / uint(blockTimeCount));
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // return BSCS quote amount (wei) base on percentage and price
    function getFeeBscs(uint pct, uint _price)
        private
        pure
        returns (uint)
    {
        require(_price > 9999, "Price is too small");
        if (pct == 0) {
            return 0;
        }
        return (pct * _price) / 10000;
    }

    // return seller payment amount (wei) base on percentage and price
    function getSellerPayment(uint pct, uint _price)
        private
        pure
        returns (uint)
    {
        //9999: so minimum percentage is 0.1% and price is 10000 wei
        require(_price > 9999, "Price is too small");

        uint sellerPct;
        if (pct < 10000) {
            sellerPct = 10000 - pct;
        } else {
            sellerPct = 10000;
        }
        return (sellerPct * _price) / 10000;
    }

    function createAuction(
        address _tokenAddress,
        uint _tokenId,
        uint _price,
        uint _duration
    ) 
      external 
      whenNotPaused 
    {
        require(
            !hasAuction[_tokenAddress][_tokenId],
            "createAuction: Please cancel current auction first"
        );

        require(_duration > 60, "Duration at least 1 minute");

        require(
            IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender,
            "createAuction: You are not the owner"
        );

        IERC721(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        uint blockNumber = block.number;

        Auction storage auction = auctionIdToAuction[auctionId];

        auction.id = auctionId;
        auction.seller = msg.sender;
        auction.tokenId = _tokenId;
        auction.tokenAddress = _tokenAddress;
        auction.price = _price;
        auction.startBlock = blockNumber;
        auction.duration = _duration;
        auction.auctionState = State.Running;
        auction.highestBindingBid = 0;
        auction.highestBidder = address(0);

        hasAuction[_tokenAddress][_tokenId] = true;

        emit AuctionCreated(
          auctionId, 
          msg.sender, 
          _tokenId, 
          _tokenAddress, 
          _price, 
          blockNumber, 
          _duration, 
          State.Running, 
          0, 
          address(0)
        );
        auctionId++;
    }

    function placeBid(uint _auctionId, uint _amount)
        public
        payable
        whenNotPaused
    {
        Auction storage auction = auctionIdToAuction[_auctionId];

        require(
            _amount >= auction.price,
            "placeBid: Price must bigger than minimum price"
        );

        require(msg.sender != auction.seller, "placeBid: You are the onwer");
        require(
            block.number > auction.startBlock,
            "placeBid: Auction is not yet started"
        );
        require(
            block.number < getEndBlockNumber(auction.startBlock, auction.duration),
            "placeBid: Auction is already ended"
        );
        require(
            auction.auctionState == State.Running,
            "Auction is already ended or cancelled"
        );

        // one user can bid multiple times
        uint currentBid = auction.bidderToAmount[msg.sender] + msg.value;

        //assign current bid to the bidderToAmount, later on refund if not winner
        auction.bidderToAmount[msg.sender] = currentBid;

        // if current bid is greather than highest bid
        if (currentBid > auction.bidderToAmount[auction.highestBidder]) {
            //Set highest bidder
            auction.highestBidder = msg.sender;

            //Set highest binding bid
            auction.highestBindingBid = min(
                currentBid,
                auction.bidderToAmount[auction.highestBidder] + bidIncrement
            );
        } else {
            //Set highest binding bid
            auction.highestBindingBid = min(
                currentBid + bidIncrement,
                auction.bidderToAmount[auction.highestBidder]
            );
        }

        // temporary lock fund to this contract
        payable(address(this)).transfer(_amount);

        emit AuctionBid(
            auction.id,
            auction.seller,
            msg.sender,
            auction.tokenAddress,
            auction.tokenId,
            _amount
        );
    }

    function cancelAuction(uint _auctionId) public whenNotPaused {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(
            msg.sender == auction.seller,
            "placeBid: You are not the onwer"
        );
        require(
            block.number > auction.startBlock,
            "placeBid: Auction is not yet started"
        );
        require(
            block.number < getEndBlockNumber(auction.startBlock, auction.duration),
            "placeBid: Auction is already ended"
        );
        require(
            auction.auctionState == State.Running,
            "Auction is already ended or cancelled"
        );

        auction.auctionState = State.Cancelled;
        hasAuction[auction.tokenAddress][auction.tokenId] = false;

        IERC721(auction.tokenAddress).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit AuctionCancelled(_auctionId, auction.tokenId);
    }

    function cancelBid(uint _auctionId) 
        public
        payable
        whenNotPaused {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(
            block.number > auction.startBlock,
            "cancelBid: Auction is not yet started"
        );

        uint bidAmount = auction.bidderToAmount[msg.sender];
        require(bidAmount > 0, "cancelBid: You are not the bidder");
        auction.bidderToAmount[msg.sender] = 0;
        
        payable(msg.sender).transfer(bidAmount);

        emit AuctionCancelled(_auctionId, auction.tokenId);
    }

    // finishing the auction, transfering NFT and fund
    function finalizeAuction(uint _auctionId) public whenNotPaused {
        Auction storage auction = auctionIdToAuction[_auctionId];

        //Auction was Cancelled or the auction is ended
        require(
            auction.auctionState == State.Cancelled ||
                block.number > getEndBlockNumber(auction.startBlock, auction.duration),
            "Auction is not yet ended"
        );

        //The seller or bidder but he has bidded
        require(
            msg.sender == auction.seller ||
                auction.bidderToAmount[msg.sender] > 0,
            "You are not the seller or the bidder"
        );

        address recipient;
        uint value;

        if (auction.auctionState == State.Cancelled) {
            recipient = msg.sender;
            value = auction.bidderToAmount[msg.sender];
        } else {
            /* Auction is ended */

            //Owner
            if (msg.sender == auction.seller) {
                recipient = address(this);
                value = auction.highestBindingBid;
            } else {
                //bidder
                if (msg.sender == auction.highestBidder) {
                    value =
                        auction.bidderToAmount[auction.highestBidder] -
                        auction.highestBindingBid;
                    recipient = auction.highestBidder;
                } else {
                    value = auction.bidderToAmount[msg.sender];
                    recipient = msg.sender;
                }

                // transfering NFT to winner
                IERC721(auction.tokenAddress).safeTransferFrom(
                    address(this),
                    recipient,
                    auction.tokenId
                );
            }
        }

        // resetting the bids of the recipient to avoid multiple transfers to the same recipient
       auction.bidderToAmount[recipient] = 0;

        // transfering fund to seller or owner
        uint feeAmt = getFeeBscs(feePecent, value);
        uint sellerPayment = getSellerPayment(feePecent, value);

        payable(feeAddr).transfer(feeAmt);
        payable(recipient).transfer(sellerPayment);

        hasAuction[auction.tokenAddress][auction.tokenId] = false;

        auction.auctionState = State.Ended;

        emit AuctionEnded(
            _auctionId,
            auction.seller,
            recipient,
            auction.tokenAddress,
            auction.tokenId,
            value
        );
    }

    function pause() public  onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}

