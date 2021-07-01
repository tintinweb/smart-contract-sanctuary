// SPDX-License-Identifier: MIT

/**
 * The auctioned items are bid with ETH.            --
 * The NFT is won by the highest bidder.            --
 * The starting bid of each auctioned NFT is 1 ETH. --                                    
 * If one bid is won, the next bidder needs to bid  --
 * 10% more of the previous winning bid.            --
 * For each auction, starting countdown clock is set to 24 hours.  --
 * When there is less than 1 hour on the countdown clock, --
 * a new bid will increase the countdown clock by 10 minutes --
 * while the countdown clock is capped at 1 hour.
 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeSpaceAuction is ERC721Holder, Ownable {

    uint public initialBidAmount = 1 ether;
    uint public feePercentage;      //1% = 1000
    uint private constant DIVISOR = 100 * 1000;
    address payable public feeReceipient;

    struct Auction {
        address payable seller;
        address payable highestBidder;
        uint highestBidAmount;
        uint endPeriod;
        uint bidCount;
    }

    mapping(address => mapping(uint => Auction)) public auctions;

    event NewAuction(
        address indexed seller,
        address token,
        uint tokenId,
        uint endPeriod
    );

    event NewBid(
        address indexed bidder,
        address token,
        uint tokenId,
        uint amount
    );

    event BidClosed(
        address indexed highestBidder, 
        address token, 
        uint tokenId, 
        uint highestBidAmount
    );

    event FeeSet(
        address indexed sender, 
        uint fee
    );

    event FeeReceipientSet(
        address indexed sender, 
        address feeReceipient
    );

    constructor(
        address _feeReceipient, 
        uint _fee
        ) {
        
        _setFeeReceipient(_feeReceipient);
        _setFeePercentage(_fee);
    }

    function createAuction(
        address _token, 
        uint _tokenId
        ) external returns(bool created) {
        
        Auction storage auction = auctions[_token][_tokenId];
        require(auction.seller == address(0), "Error: auction already exist"); 
        
        //collect NFT from sender
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);
        
        //create auction
        uint period = block.timestamp + 1 days;
        auction.endPeriod = period;
        auction.seller = payable(msg.sender); 
        
        emit NewAuction(msg.sender, _token, _tokenId, period);
        return true;
    }

    function bid(
        address _token,
        uint _tokenId
        ) external payable returns(bool bidded) {
        
        Auction storage auction = auctions[_token][_tokenId];
        uint endPeriod = auction.endPeriod;
        require(auction.seller != msg.sender, "Error: cannot bid your auction"); 
        require(endPeriod != 0, "Error: auction does not exist");
        require(endPeriod > block.timestamp, "Error: auction has ended");
        
        if(auction.bidCount == 0) require(
                msg.value == initialBidAmount, 
                "Error: must start bid with 1 ether"
            );
        else {
            uint tenPercentOfHighestBid = _nextBidAmount(_token, _tokenId);
            require(
                msg.value == tenPercentOfHighestBid, 
                "Error: must bid 10 percent more than previous bid"
            );
            //return ether to the prevous highest bidder
            auction.highestBidder.transfer(auction.highestBidAmount);
        }

        //increase countdown clock
        uint timeLeft = endPeriod - block.timestamp;
        if(timeLeft < 1 hours) {
            timeLeft + 10 minutes <= 1 hours 
            ? auction.endPeriod += 10 minutes 
            : auction.endPeriod += (1 hours - timeLeft);
        }

        //update data
        auction.highestBidder = payable(msg.sender);
        auction.highestBidAmount = msg.value; 
        auction.bidCount++;

        emit NewBid(msg.sender, _token, _tokenId, msg.value);
        return true;
    }

    function closeBid(
        address _token, 
        uint _tokenId
        ) external returns(bool closed) {

        Auction storage auction = auctions[_token][_tokenId];
        require(auction.seller != address(0), "Error: auction does not exist");
        require(
            _bidTimeRemaining(_token, _tokenId) == 0, 
            "Error: auction has not ended"
        );
        
        uint highestBidAmount = auction.highestBidAmount;
        address highestBidder = auction.highestBidder;

        if(highestBidAmount == 0) {
            //auction failed, no bidder showed up
            IERC721(_token).transferFrom(address(this), auction.seller, _tokenId);
            delete auctions[_token][_tokenId];
        } else {
            //auction succeeded, pay fee, send money to seller, and token to buyer
            uint fee = (feePercentage * highestBidAmount) / DIVISOR;
            feeReceipient.transfer(fee);
            auction.seller.transfer(highestBidAmount - fee);
            IERC721(_token).safeTransferFrom(address(this), highestBidder, _tokenId);
            delete auctions[_token][_tokenId];
        }
        emit BidClosed(highestBidder, _token, _tokenId, highestBidAmount);
        return true;
    }

    //_________________
    //ADMIN FUNCTIONS
    //_________________

    function setFeePercentage(
        uint _newFee
        ) external onlyOwner returns(bool feeSet) {
        
        _setFeePercentage(_newFee);
        
        emit FeeSet(msg.sender, _newFee);
        return true;
    }

    function setFeeReceipient(
        address _newFeeReceipient
        ) external onlyOwner returns(bool feeReceipientSet) {
        
        _setFeeReceipient(_newFeeReceipient);
        
        emit FeeReceipientSet(msg.sender, _newFeeReceipient);
        return true;
    }

    //_________________
    //READ FUNCTIONS
    //_________________

    function bidTimeRemaining(
        address _token, 
        uint _tokenId
        ) external view returns(uint secondsLeft) {
        
        return _bidTimeRemaining(_token, _tokenId);
    }

    function nextBidAmount(
        address _token, 
        uint _tokenId
        ) external view returns(uint amount) {
        
        return _nextBidAmount(_token, _tokenId);
    }

    //_________________
    //PRIVATE FUNCTIONS
    //_________________

    function _bidTimeRemaining(
        address _token,
        uint _tokenId
        ) private view returns(uint secondsLeft) {
        
        uint endPeriod = auctions[_token][_tokenId].endPeriod;

        if(endPeriod > block.timestamp) 
        return endPeriod - block.timestamp;
        return 0;
    }

    function _nextBidAmount(
        address _token,
        uint _tokenId
        ) private view returns(uint amount) {
        
        address seller = auctions[_token][_tokenId].seller;
        if(seller != address(0)) {
            uint count = auctions[_token][_tokenId].bidCount;
            uint current = auctions[_token][_tokenId].highestBidAmount;
            if(count == 0) return 1 ether;
            else return ((current * 10) / 100);
        }
    }

    function _setFeePercentage(
        uint _newFee
        ) private {
        require(_newFee != feePercentage, "Error: already set");
        feePercentage = _newFee;
    }

    function _setFeeReceipient(
        address _newFeeReceipient
        ) private {
        require(_newFeeReceipient != feeReceipient, "Error: already receipient");
        feeReceipient = payable(_newFeeReceipient);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}