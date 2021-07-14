//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./interfaces/IBEP20.sol";
import "./utils/SafeMath.sol";
import "./utils/Context.sol";
import "./utils/Ownable.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./upgradeable/Initializable.sol";

contract RFOXAuction is Context, Ownable, IERC721Receiver, Initializable {
  using SafeMath for uint256;

  struct AuctionInfo { // Struct
    address   seller;
    address   nft;
    uint      itemId;
    uint      price;
    address   bidder;
    uint      createdAt;
    uint      updatedAt;
    uint      start;
    uint      end;
    bool      isEnded;
  }

  struct BidInfo {
    uint      auctionId;
    uint      price;
    address   bidder;
    uint      bidAt;
  }

  AuctionInfo[] public auctions;
  BidInfo[] public bids;

  mapping (address => uint256) public bidCount;
  mapping (address => uint256) public wonCount;
  address private _rfox;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`

  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  event CreateAuction(address indexed sender, uint itemId, uint start, uint end);
  event Bid(address indexed sender, uint auctionId, uint price, uint bidAt);
  event CancelAuction(address indexed sender, uint auctionId);
  event EndAuction(address indexed sender, uint auctionId);
  event Withdraw(address indexed sender, uint amount);

  function initialize(address _owner, address __rfox)
      public
      initializer
  {
    Ownable.initialize(_owner);
    _rfox = __rfox;
  }
  
  function createAuction(address _nft, uint _itemId, uint _start, uint _end) external {
    require(_start < _end, 'Auction: Period is not valid');
    AuctionInfo memory newAuction = AuctionInfo(msg.sender, _nft, _itemId, 0, address(0), block.timestamp, block.timestamp, _start, _end, false);
    auctions.push(newAuction);

    IERC721(_nft).safeTransferFrom(msg.sender, address(this), _itemId);
    emit CreateAuction(msg.sender, _itemId, _start, _end);
  }

  function bid(uint _auctionId, uint _price) external {
    uint auctionLength = auctions.length;
    require(_auctionId < auctionLength, 'Auction: Invalid Auction Id');
    AuctionInfo storage auction = auctions[_auctionId];
    require(msg.sender != auction.seller, 'Auction: Invalid Bidder');
    require(msg.sender != auction.bidder, 'Auction: Invalid Bidder');
    require(block.timestamp >= auction.start, 'Auction: Auction is not started');
    require(block.timestamp <= auction.end, 'Auction: Auction is Over');
    require(_price > auction.price.mul(105).div(100), 'Auction: Price is low');

    require(IBEP20(_rfox).transferFrom(msg.sender, address(this), _price), 'Auction: RFOX transfer failed');
    require(IBEP20(_rfox).transfer(auction.bidder, auction.price), 'Auction: RFOX transfer failed');

    if (auction.bidder != address(0)) {
      bidCount[auction.bidder] = bidCount[auction.bidder].sub(1);
    }
    bidCount[msg.sender] = bidCount[msg.sender].add(1);

    auction.bidder = msg.sender;
    auction.price = _price;
    auction.updatedAt = block.timestamp;
    
    BidInfo memory newBid = BidInfo(_auctionId, _price, msg.sender, block.timestamp);
    bids.push(newBid);
    emit Bid(msg.sender, _auctionId, _price, block.timestamp);
  }

  function cancelAuction(uint _auctionId) external {
    uint auctionLength = auctions.length;
    require(_auctionId < auctionLength, 'Auction: Invalid Auction Id');

    AuctionInfo storage auction = auctions[_auctionId];
    require(auction.seller == msg.sender, 'Auction: Invalid Permission');
    require(auction.start > block.timestamp, 'Auction: Not Cancelable');
    _removeAuction(_auctionId);

    IERC721(auction.nft).safeTransferFrom(address(this), msg.sender, auction.itemId);
    emit CancelAuction(msg.sender, _auctionId);
  }

  function _removeAuction(uint _auctionId) internal {
    while (_auctionId < auctions.length-1) {
      auctions[_auctionId] = auctions[_auctionId + 1];
      _auctionId ++;
    }
    auctions.pop();
  }

  function withdraw(uint amount) external onlyOwner {
    require(IBEP20(_rfox).transfer(msg.sender, amount), 'Auction: RFOX transfer failed');
    emit Withdraw(msg.sender, amount);
  }

  function rfox() public view returns (address) {
    return _rfox;
  }

  function getAuctionCount() external view returns (uint256) {
    return auctions.length;
  }

  function getTotalBidCount() external view returns (uint256) {
    return bids.length;
  }

  function endAuction(uint _auctionId) external {
    uint auctionLength = auctions.length;
    AuctionInfo storage auction = auctions[_auctionId];
    require(_auctionId < auctionLength, 'Auction: Invalid Auction Id');
    require(auction.seller == msg.sender, 'Auction: Invalid Permission');
    require(auction.end < block.timestamp, 'Auction: Not ended yet');

    auction.isEnded = true;
    require(IBEP20(_rfox).transfer(auction.seller, auction.price), 'Auction: RFOX transfer failed');    
    IERC721(auction.nft).safeTransferFrom(address(this), auction.bidder, auction.itemId);

    wonCount[auction.bidder] = wonCount[auction.bidder].add(1);
    emit EndAuction(msg.sender, _auctionId);
  }

  function getAuctionIdsWon(address account) external view returns (uint256[] memory) {
    uint256 _wonCount = wonCount[account];
    
    if (_wonCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {

      uint256[] memory _auctionIds = new uint256[](_wonCount);
      uint256 wonIndex = 0;
      uint256 _auctionId;

      for (_auctionId = 0; _auctionId <= auctions.length-1; _auctionId++) {
        if ((auctions[_auctionId].bidder == account) && (auctions[_auctionId].isEnded)) {
          _auctionIds[wonIndex] = _auctionId;
          wonIndex++;
        }
      }

      return _auctionIds;
    }
  }

  function getAuctionIdsBid(address account) external view returns (uint256[] memory) {
    uint256 _bidCount = bidCount[account];
    
    if (_bidCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {

      uint256[] memory _auctionIds = new uint256[](_bidCount);
      uint256 bidIndex = 0;
      uint256 _auctionId;

      for (_auctionId = 0; _auctionId <= auctions.length-1; _auctionId++) {
        if ((auctions[_auctionId].bidder == account) && (!auctions[_auctionId].isEnded)) {
          _auctionIds[bidIndex] = _auctionId;
          bidIndex++;
        }
      }

      return _auctionIds;
    }
  }

  function getItemIdsWon(address account) external view returns (uint256[] memory) {
    uint256 _wonCount = wonCount[account];
    
    if (_wonCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {

      uint256[] memory _itemIds = new uint256[](_wonCount);
      uint256 wonIndex = 0;
      uint256 _auctionId;

      for (_auctionId = 0; _auctionId <= auctions.length-1; _auctionId++) {
        if ((auctions[_auctionId].bidder == account) && (auctions[_auctionId].isEnded)) {
          _itemIds[wonIndex] = auctions[_auctionId].itemId;
          wonIndex++;
        }
      }
      
      return _itemIds;
    }
  }

  function getItemIdsBid(address account) external view returns (uint256[] memory) {
    uint256 _bidCount = bidCount[account];
    
    if (_bidCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {

      uint256[] memory _itemIds = new uint256[](_bidCount);
      uint256 bidIndex = 0;
      uint256 _auctionId;

      for (_auctionId = 0; _auctionId <= auctions.length-1; _auctionId++) {
        if ((auctions[_auctionId].bidder == account) && (!auctions[_auctionId].isEnded)) {
          _itemIds[bidIndex] = auctions[_auctionId].itemId;
          bidIndex++;
        }
      }
      
      return _itemIds;
    }
  }

  function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
      return _ERC721_RECEIVED;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./IERC165.sol";

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

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

pragma solidity 0.7.2;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

pragma solidity 0.7.2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.7.2;

import "./Context.sol";

contract Ownable is Context {
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

    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }
    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}