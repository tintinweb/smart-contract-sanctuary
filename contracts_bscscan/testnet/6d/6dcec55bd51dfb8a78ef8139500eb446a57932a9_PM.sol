/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    function symbol() external view returns (string memory);

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
    function allowance(address owner, address spender)
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PM is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tradeCounter;

    mapping(address => bool) public sellToken;
    address[] sellTokenArray ; 
    mapping(address => uint256) public tokenfee;

    enum TradeStatus {
        inactive,
        Open,
        Stopped,
        Closed
    }

    TradeStatus auctionstatus;
    mapping(uint256 => TradeStatus) tradeStatus;

    struct Trade {
        uint256 id;
        address lister;
        address nftAdr;
        uint256 nftTokenId;
        uint256 nftTokenPrice;
        address priceTokenAdr;
        address buyer;
        string title;
        //auction variables
        bool isAuction;
        uint256 highestBid;
        address highestBidder;
        uint256 openTimestamp;
        uint256 endTimestamp;
    }

    Trade[] trades;
    mapping(uint256 => mapping(address => uint256)) bidsByTrade;
    mapping(address => uint256[]) auctionsOfUser;
    mapping(uint256 => mapping(address => bool)) public claim;

    uint256 public bidIncreasePercentage = 5;

    address public nftAddress = 0x92b5DaaBe735BD6BB6505b20a8Db8f5Ee38Bceb4;

    mapping(address => uint256) _collectedFees;

    IERC721 nftContract;

    event AuctionOpened(uint256 tradeId, address lister);
    event AuctionCancelled(uint256 tradeId, address lister);
    event BidPlaced(uint256 tradeId, address bidder, uint256 amount);
    event BidWithdrawn(uint256 tradeId, address bidder);
    event ClaimNft(uint256 tradeId, address buyer, uint256 nftid);
    event NFTSold(uint256 tradeId, address buyer, uint256 nftid);

    event DebugLog(string text, uint256 value);

    constructor(address nftToken, address BepToken) {
        nftAddress = nftToken;
        nftContract = IERC721(nftToken);
        sellToken[BepToken] = true;
    }

    function getBid(uint256 tradeId, address bidder)
        external
        view
        returns (uint256)
    {
        return bidsByTrade[tradeId][bidder];
    }

    function getAuctionsOfUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        return auctionsOfUser[user];
    }

     
    function getApprovedToken()
        public
        view
        returns(string[] memory,uint256[] memory,address[] memory,uint256)
    {
       uint256 tokenCount =  sellTokenArray.length ; 
       uint256 tokenLength = 0 ; 
       string[] memory tokenSymbol  ; 
       uint256[] memory tokenFee  ; 
       address[] memory tokenAddress  ; 
       for(uint256 i = 0 ; i < tokenCount ; i++ ){
           address _token =  sellTokenArray[i] ;
           if(sellToken[_token]){
               tokenSymbol[tokenLength] =  IERC20(_token).symbol();
               tokenFee[tokenLength] = tokenfee[_token];
               tokenAddress[tokenLength] = _token;
               tokenLength++ ; 
           }
       }
        
       return (tokenSymbol,tokenFee,tokenAddress,tokenLength) ;

    }

    function getTrade(uint256 tradeId)
        public
        view
        returns (
            string memory title,
            uint256 nftid,
            address nftadd,
            uint256 startingPrice,
            uint256 maxbid,
            address highestBidder,
            address buyer
        )
    {
        return (
            trades[tradeId].title,
            trades[tradeId].nftTokenId,
            trades[tradeId].nftAdr,
            trades[tradeId].nftTokenPrice,
            trades[tradeId].highestBid,
            trades[tradeId].highestBidder,
            trades[tradeId].buyer
        );
    }

    function getFullTrade(uint256 tradeId)
        public
        view
        returns (Trade memory _trade)
    {
        return trades[tradeId];
    }

    function istradeAuction(uint256 tradeId) public view returns (bool) {
        return trades[tradeId].isAuction;
    }

    function getAuctionTime(uint256 tradeId)
        public
        view
        returns (uint256 _starttime, uint256 _endtime)
    {
        return (trades[tradeId].openTimestamp, trades[tradeId].endTimestamp);
    }

    function getTradeCount() public view returns (uint256) {
        return _tradeCounter.current();
    }

    function getCollectedFees(address tokenAdr) public view returns (uint256) {
        return _collectedFees[tokenAdr];
    }

    function getAuctionStatus(uint256 tradeId)
        public
        view
        returns (TradeStatus)
    {
        require(trades[tradeId].isAuction == true, "Trade must be an auction.");

        if (tradeStatus[tradeId] == TradeStatus.Stopped) {
            return TradeStatus.Stopped;
        } else if (
            block.timestamp >= trades[tradeId].openTimestamp &&
            block.timestamp <= trades[tradeId].endTimestamp
        ) {
            return TradeStatus.Open;
        } else if (block.timestamp <= trades[tradeId].openTimestamp) {
            return TradeStatus.inactive;
        } else {
            return TradeStatus.Closed;
        }
    }

    function openAuction(
        address tokenaddr,
        uint256 nftTokenId,
        uint256 startingPrice,
        uint256 startTime,
        uint256 stopTime,
        string memory _title
    ) external onlyNonContract {
        require(
            nftContract.ownerOf(nftTokenId) == msg.sender,
            "Sender has to be owner of the token."
        );
        require(startTime < stopTime, "Duration has to be above 0.");
        require(
            sellToken[tokenaddr] == true,
            "Platform doesnot support this token"
        );

        uint256 id = _tradeCounter.current();
        _tradeCounter.increment();

        trades.push(
            Trade({
                id: id,
                lister: msg.sender,
                nftAdr: address(nftContract),
                nftTokenId: nftTokenId,
                nftTokenPrice: startingPrice,
                priceTokenAdr: address(tokenaddr),
                buyer: address(0),
                isAuction: true,
                highestBid: startingPrice,
                highestBidder: msg.sender,
                openTimestamp: startTime,
                endTimestamp: stopTime,
                title: _title
            })
        );

        assert(trades.length == _tradeCounter.current());

        nftContract.safeTransferFrom(msg.sender, address(this), nftTokenId);

        emit AuctionOpened(id, msg.sender);
    }

    function openOtherAuction(
        address tokenaddr,
        address _nftaddress,
        uint256 nftTokenId,
        uint256 startingPrice,
        uint256 startTime,
        uint256 stopTime,
        string memory _title
    ) external onlyNonContract {
        IERC721 nftC;
        nftC = IERC721(_nftaddress);

        require(
            nftC.ownerOf(nftTokenId) == msg.sender,
            "Sender has to be owner of the token."
        );
        require(startTime < stopTime, "Duration has to be above 0.");
        require(
            sellToken[tokenaddr] == true,
            "Platform doesnot support this token"
        );

        uint256 id = _tradeCounter.current();
        _tradeCounter.increment();

        trades.push(
            Trade({
                id: id,
                lister: msg.sender,
                nftAdr: address(_nftaddress),
                nftTokenId: nftTokenId,
                nftTokenPrice: startingPrice,
                priceTokenAdr: address(tokenaddr),
                buyer: address(0),
                isAuction: true,
                highestBid: startingPrice,
                highestBidder: msg.sender,
                openTimestamp: startTime,
                endTimestamp: stopTime,
                title: _title
            })
        );

        assert(trades.length == _tradeCounter.current());

        nftC.safeTransferFrom(msg.sender, address(this), nftTokenId);

        emit AuctionOpened(id, msg.sender);
    }

    function placeBid(uint256 tradeId, uint256 bid) external onlyNonContract {
        Trade memory trade = trades[tradeId];

        require(trade.isAuction == true, "Trade must be an auction.");
        require(
            (trade.highestBid * (bidIncreasePercentage + 100)) / 100 <= bid,
            "Bid must be at least 5% higher than highest bid."
        );

        auctionstatus = getAuctionStatus(tradeId);
        require(
            auctionstatus == TradeStatus.Open,
            "Trade status must be open."
        );

        require(
            msg.sender != trade.lister,
            "lister can't bid on their own NFT."
        );

        uint256 pastBid = bidsByTrade[tradeId][msg.sender];

        bidsByTrade[tradeId][msg.sender] = bid;

        if (pastBid == 0) {
            uint256 startGas = gasleft(); // debug
            auctionsOfUser[msg.sender].push(tradeId);
            emit DebugLog(
                "Gas used by adding to auctionsOfUser",
                startGas - gasleft()
            );
        }

        trades[tradeId].highestBid = bid;
        trades[tradeId].highestBidder = msg.sender;

        IERC20 tkn;
        tkn = IERC20(trade.priceTokenAdr);

        require(
            tkn.transferFrom(msg.sender, address(this), bid - pastBid),
            "Tokens couldn't be transferred. Check your allowance."
        );

        emit BidPlaced(tradeId, msg.sender, bid);
    }

    function endAuction(uint256 tradeId) external {
        Trade memory trade = trades[tradeId];

        require(trade.isAuction == true, "Trade must be an auction.");

        auctionstatus = getAuctionStatus(tradeId);
        require(
            auctionstatus == TradeStatus.Closed,
            "Trade status must be closed."
        );

        require(trade.isAuction == true, "Trade must be an auction.");
        require(
            msg.sender == trade.lister,
            "Only the lister can end their auction."
        );

        require(
            trade.buyer == 0x0000000000000000000000000000000000000000,
            "Already sold"
        );
        IERC721 nftC;
        nftC = IERC721(trade.nftAdr);

        if (trade.highestBidder == trade.lister) {
            trades[tradeId].buyer = trade.lister;
            nftC.safeTransferFrom(
                address(this),
                trade.lister,
                trade.nftTokenId
            );

            emit AuctionCancelled(tradeId, trade.lister);
        } else {
            IERC20 tkn;
            tkn = IERC20(trade.priceTokenAdr);

            uint256 bid = trade.highestBid;

            uint256 feeperc = tokenfee[trade.priceTokenAdr];
            uint256 platoformfee = bid.mul(feeperc).div(100);
            uint256 sellprice = bid.sub(platoformfee);

            _collectedFees[trade.priceTokenAdr] += platoformfee;

            require(
                tkn.transfer(msg.sender, sellprice),
                "Tokens transferred to seller failed"
            );

            nftC.safeTransferFrom(
                address(this),
                trade.highestBidder,
                trade.nftTokenId
            );
            claim[tradeId][trade.highestBidder] = true;
            trades[tradeId].buyer = trade.highestBidder;

            emit ClaimNft(tradeId, trades[tradeId].buyer, trade.nftTokenId);
        }
    }

    function renewAuction(
        uint256 tradeId,
        uint256 startingPrice,
        uint256 startTime,
        uint256 stopTime
    ) external onlyNonContract {
        Trade memory trade = trades[tradeId];

        auctionstatus = getAuctionStatus(tradeId);
        require(
            auctionstatus == TradeStatus.Closed,
            "Trade status must be closed."
        );
        require(trade.isAuction == true, "Trade must be an auction.");

        require(
            msg.sender == trade.lister,
            "Only the lister can renew their auction."
        );
        require(trade.highestBidder == trade.lister, "Already sold");
        require(
            trade.buyer == 0x0000000000000000000000000000000000000000,
            "Already sold"
        );

        trades[tradeId].nftTokenPrice = startingPrice;
        trades[tradeId].openTimestamp = startTime;
        trades[tradeId].endTimestamp = stopTime;
        trades[tradeId].highestBid = startingPrice;
    }

    function withdraw(uint256 tradeId) external {
        require(trades[tradeId].isAuction == true, "Trade must be an auction.");

        Trade memory trade = trades[tradeId];
        uint256 bid = bidsByTrade[tradeId][msg.sender];

        require(claim[tradeId][msg.sender] == false, "Already Claimed");

        require(bid > 0, "There is no bid to withdraw.");

        auctionstatus = getAuctionStatus(tradeId);
        require(
            auctionstatus == TradeStatus.Closed,
            "Trade status must be closed."
        );

        IERC20 tkn;
        tkn = IERC20(trade.priceTokenAdr);

        IERC721 nftC;
        nftC = IERC721(trade.nftAdr);

        if (msg.sender != trade.highestBidder) {
            require(
                tkn.transfer(msg.sender, bid),
                "Token transfer to sender failed."
            );
            claim[tradeId][msg.sender] = true;
            emit BidWithdrawn(tradeId, msg.sender);
        } else if (msg.sender == trade.highestBidder) {
            uint256 feeperc = tokenfee[trade.priceTokenAdr];
            uint256 platoformfee = bid.mul(feeperc).div(100);
            uint256 sellprice = bid.sub(platoformfee);

            _collectedFees[trade.priceTokenAdr] += platoformfee;

            require(
                tkn.transfer(trade.lister, sellprice),
                "Tokens transferred to seller failed"
            );

            nftC.safeTransferFrom(address(this), msg.sender, trade.nftTokenId);
            claim[tradeId][msg.sender] = true;
            trades[tradeId].buyer = msg.sender;
            emit ClaimNft(tradeId, msg.sender, trade.nftTokenId);
        }
    }

    function openInstantSellAuction(
        uint256 nftTokenId,
        uint256 price,
        address tokenaddr,
        string memory _title
    ) external onlyNonContract {
        require(
            nftContract.ownerOf(nftTokenId) == msg.sender,
            "Sender has to be owner of the token."
        );
        require(
            sellToken[tokenaddr] == true,
            "Platform doesnot support this token"
        );

        uint256 id = _tradeCounter.current();
        _tradeCounter.increment();

        trades.push(
            Trade({
                id: id,
                lister: msg.sender,
                nftAdr: address(nftContract),
                nftTokenId: nftTokenId,
                nftTokenPrice: price,
                priceTokenAdr: address(tokenaddr),
                buyer: address(0),
                isAuction: false,
                highestBid: 0,
                highestBidder: address(0),
                openTimestamp: block.timestamp, // useful as metadata
                endTimestamp: 0,
                title: _title
            })
        );

        assert(trades.length == _tradeCounter.current());
        nftContract.safeTransferFrom(msg.sender, address(this), nftTokenId);
        emit AuctionOpened(id, msg.sender);
    }

    function openOtherInstantSellAuction(
        address nftaddress,
        uint256 nftTokenId,
        uint256 price,
        address tokenaddr,
        string memory _title
    ) external onlyNonContract {
        IERC721 nftC;
        nftC = IERC721(nftaddress);

        require(
            nftC.ownerOf(nftTokenId) == msg.sender,
            "Sender has to be owner of the token."
        );
        require(
            sellToken[tokenaddr] == true,
            "Platform doesnot support this token"
        );

        uint256 id = _tradeCounter.current();
        _tradeCounter.increment();

        trades.push(
            Trade({
                id: id,
                lister: msg.sender,
                nftAdr: address(nftaddress),
                nftTokenId: nftTokenId,
                nftTokenPrice: price,
                priceTokenAdr: address(tokenaddr),
                buyer: address(0),
                isAuction: false,
                highestBid: 0,
                highestBidder: address(0),
                openTimestamp: block.timestamp, // useful as metadata
                endTimestamp: 0,
                title: _title
            })
        );

        assert(trades.length == _tradeCounter.current());
        nftC.safeTransferFrom(msg.sender, address(this), nftTokenId);
        emit AuctionOpened(id, msg.sender);
    }

    function buyNft(uint256 tradeId) external onlyNonContract {
        Trade memory trade = trades[tradeId];
        require(
            trade.isAuction == false,
            "A normal trade can't be an auction."
        );
        trades[tradeId].buyer = msg.sender;

        require(trade.lister != trade.buyer, "Trade ends");
        require(
            trade.buyer == 0x0000000000000000000000000000000000000000,
            "Already sold"
        );
        require(
            msg.sender != trade.lister,
            "lister can't bid on their own NFT."
        );

        IERC20 tkn;
        tkn = IERC20(trade.priceTokenAdr);

        IERC721 nftC;
        nftC = IERC721(trade.nftAdr);

        uint256 feeperc = tokenfee[trade.priceTokenAdr];
        uint256 platoformfee = trade.nftTokenPrice.mul(feeperc).div(100);
        uint256 sellprice = trade.nftTokenPrice.sub(platoformfee);

        _collectedFees[trade.priceTokenAdr] += platoformfee;

        require(
            tkn.transferFrom(msg.sender, address(this), platoformfee),
            "Fee transfer failed."
        );
        require(
            tkn.transferFrom(msg.sender, trade.lister, sellprice),
            "Token transfer failed."
        );
        nftC.safeTransferFrom(address(this), msg.sender, trade.nftTokenId);

        emit NFTSold(tradeId, msg.sender, trade.nftTokenId);
    }

    function cancelInstantSellAuction(uint256 tradeId) external {
        Trade memory trade = trades[tradeId];
        require(
            msg.sender == trade.lister,
            "Only the lister of a trade can cancel it."
        );
        require(
            trade.isAuction == false,
            "A normal trade can't be an auction."
        );

        require(
            trade.buyer == 0x0000000000000000000000000000000000000000,
            "Already sold"
        );
        trades[tradeId].buyer = msg.sender;

        IERC721 nftC;
        nftC = IERC721(trade.nftAdr);

        nftC.safeTransferFrom(address(this), trade.lister, trade.nftTokenId);

        emit AuctionCancelled(tradeId, trade.lister);
    }

    function renewInstantSellAuction(uint256 tradeId, uint256 _newprice)
        external
    {
        Trade memory trade = trades[tradeId];
        require(
            msg.sender == trade.lister,
            "Only the lister of a trade can cancel it."
        );
        require(
            trade.isAuction == false,
            "A normal trade can't be an auction."
        );

        require(
            trade.buyer == 0x0000000000000000000000000000000000000000,
            "Already sold"
        );

        trades[tradeId].nftTokenPrice = _newprice;
    }

    function StopAuction(uint256 tradeId) external onlyNonContract {
        require(trades[tradeId].isAuction == true, "Trade must be an auction.");
        require(
            msg.sender == trades[tradeId].lister,
            "Only the lister can stop their auction."
        );

        auctionstatus = getAuctionStatus(tradeId);

        require(
            auctionstatus == TradeStatus.Open,
            "Cannot Stop inactive or completed Auction "
        );

        tradeStatus[tradeId] = TradeStatus.Stopped;
    }

    function resumeAuction(uint256 tradeId) external onlyNonContract {
        require(trades[tradeId].isAuction == true, "Trade must be an auction.");
        require(
            msg.sender == trades[tradeId].lister,
            "Only the lister can resume their auction."
        );

        auctionstatus = getAuctionStatus(tradeId);

        require(auctionstatus == TradeStatus.Stopped, "Auction not stopped");

        tradeStatus[tradeId] = TradeStatus.Open;
    }

    /**
     * Block contracts from calling a function, only allow user wallets
     */
    modifier onlyNonContract() {
        require(
            tx.origin == msg.sender,
            "Sender has to be a regular wallet, not a contract."
        );
        address a = msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(a)
        }
        require(size == 0);
        _;
    }

    /**
     * Set the token contract and fee
     */
    function addSelltoken(address tokenAdrr, uint256 fee) external onlyOwner {
        require(fee <= 20, " Fee too high");
        sellToken[tokenAdrr] = true;
        tokenfee[tokenAdrr] = fee;
        sellTokenArray.push(tokenAdrr);
    }

    /**
     * Set the NFT contract
     */
    function setNftAddress(address nftAdr) external onlyOwner {
        nftAddress = nftAdr;
        nftContract = IERC721(nftAdr);
    }

    function setbidIncreasePercentage(uint256 newPercentage) public onlyOwner {
        require(
            newPercentage <= 20,
            "The bid increase percentage can at most be 20%."
        );
        require(
            newPercentage > 0,
            "The bid increase percentage has to be more than 0."
        );

        bidIncreasePercentage = newPercentage;
    }

    function withdrawCollectedFees(address tokenAdr, uint256 amount)
        external
        onlyOwner
    {
        require(
            sellToken[tokenAdr] == true,
            "Platform does not support this token"
        );
        require(
            amount <= _collectedFees[tokenAdr],
            "Can't withdraw more fees than have been collected"
        );

        IERC20 tkn;
        tkn = IERC20(tokenAdr);

        require(
            amount <= tkn.balanceOf(address(this)),
            "Can't withdraw more fees than are in account balance."
        );

        _collectedFees[tokenAdr] -= amount;
        require(tkn.transfer(msg.sender, amount), "Transfer failed.");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return 0x150b7a02;
    }
}