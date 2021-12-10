// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import {AuctionBase} from './AuctionBase.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract AuctionERC721 is AuctionBase, IERC721Receiver {

  constructor(
    address _feeHolder,
    address _feeCalculator,
    uint64 _baseFeePercent,
    address[] memory _acceptedTokens,
    uint128[] memory _minPriorityFeeSell,
    uint128[] memory _minPriorityFeeBuy
  )
    AuctionBase(
      _feeHolder,
      _feeCalculator,
      _baseFeePercent,
      _acceptedTokens,
      _minPriorityFeeSell,
      _minPriorityFeeBuy
    ) {}

  function makeTransfer(
    address _from,
    address _to,
    address _token,
    uint256 _tokenId,
    uint256 _value
  )
    internal override
  {
    require(_value == 1, 'invalid value for ERC721 token');
    IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
  }

  function hasValidOwnership(
    address _user,
    address _token,
    uint256 _tokenId,
    uint64 _quantities
  ) internal view override returns (bool)
  {
    if (_quantities > 1) return false;
    // Note: it could revert here if _tokenId does not exist
    if (IERC721(_token).ownerOf(_tokenId) == _user) return true;
    return false;
  }

  function onERC721Received(address _user, address from, uint256 tokenId, bytes memory _data) 
  public 
  override
  returns (bytes4) {
    return this.onERC721Received.selector;
  }

}

pragma solidity 0.8.4;

import {IAuctionBase} from "../interfaces/IAuctionBase.sol";
import {IFeeCalculator} from "../interfaces/IFeeCalculator.sol";

import {EnumerableSet, Operators} from '../utils/Operators.sol';
import {AcceptedTokenList} from "../utils/AcceptedTokenList.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


abstract contract AuctionBase is IAuctionBase, AcceptedTokenList, Operators, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint64 constant private ONE_HUNDRED_PERCENT = 10000;
    uint64 constant private MIN_ORDER_DURATION = 5 minutes;

    uint256 public numberAuctions;

    mapping(uint256 => Auction) internal auctions;

    mapping(uint256 => mapping(address => uint256)) fundsByBidder;

    FeeConfig internal feeConfig;

    constructor(
        address _feeHolder,
        address _feeCalculator,
        uint64 _baseFeePercent,
        address[] memory _acceptedTokens,
        uint128[] memory _minPriorityFeeSell,
        uint128[] memory _minPriorityFeeBuy
    ) {
        setFeeConfig(_feeHolder, _feeCalculator, _baseFeePercent);
        addAcceptedTokens(_acceptedTokens, _minPriorityFeeSell, _minPriorityFeeBuy);
    }

    function createAuction(
        address _acceptedToken,
        address _nftToken,
        uint256 _tokenId,
        uint32 _quantity,
        uint128 _startingPrice,
        uint128 _directSellingPrice,
        uint128 _bidIncrement,
        uint64 _startTime,
        uint64 _endTime,
        uint128 _priorityFee
    ) 
    external 
    override 
    returns (uint256 auctionId) {
        {
            require(_endTime > _startTime + (5 minutes), "Invalid endtime");
            uint64 duration = _endTime - _startTime;

            require(_quantity > 0, "quantities 0");
            require(isTokenAccepted(_acceptedToken), "acceptedToken is not whitelisted");
            require(_startingPrice > 0, "invalid start price");
            require(
                hasValidOwnership(msg.sender, _nftToken, _tokenId, _quantity),
                "insufficient balance"
            );
            require(
                _priorityFee / duration >= getMinPriorityFeeData(_acceptedToken).sellOrderMinFee,
                "priority is low"
            );
        }

        auctionId = ++numberAuctions;
        uint64 baseFeePercent = uint64(getBaseFeePercent(msg.sender, _acceptedToken, _nftToken, _tokenId, _startingPrice, true));

        auctions[auctionId] = Auction({
            creator: msg.sender,
            acceptedToken: _acceptedToken,
            nftToken: _nftToken,
            highestBidder: address(0),
            tokenId: _tokenId,
            quantity: _quantity,
            startingPrice: _startingPrice,
            directSellingPrice: _directSellingPrice,
            bidIncrement: _bidIncrement,
            createdTime: _getBlockTimestamp(),
            startTime: _startTime,
            endTime: _endTime,
            canceled: false,
            priorityFee: _priorityFee,
            baseFeePercent: baseFeePercent,
            finished: false,
            ownerHasWithdrawn: false
        });

        // collect priority fees
        IERC20(_acceptedToken).safeTransferFrom(msg.sender, address(this), _priorityFee);
        makeTransfer(msg.sender, address(this), _nftToken, _tokenId, _quantity);
    }

    function getAuction(uint256 auctionId)
    external
    view
    override
    returns (Auction memory) {
        return auctions[auctionId];
    }

    function getAuctionInRange(uint256 startIndex, uint256 endIndex)
    external
    view
    override
    returns (Auction[] memory _autions) {
        _autions = new Auction[](endIndex - startIndex + 1);
        for (uint256 i = startIndex; i <= endIndex; i++) {
            _autions[i - startIndex] = auctions[i];
        }
    }

    function getHighestBid(uint256 auctionId)
    view
    public
    override
    returns (uint256) {
        Auction memory auction = auctions[auctionId];
        return fundsByBidder[auctionId][auction.highestBidder];
    }

    function cancelAuction(uint256 auctionId) 
    external
    override
    nonReentrant {
        Auction memory auction = auctions[auctionId];
        address creator = auction.creator;
        require(creator == msg.sender, "unauthorized");
        require(auction.finished, "already sold");
        require(auction.endTime > _getBlockTimestamp(), "finished already");

        uint128 totalFee = auction.priorityFee;
        uint128 refundFee = _getRefundFees(
            auction.createdTime,
            auction.endTime,
            totalFee
        );

        address acceptedToken = auction.acceptedToken;
        // transfer refund fee to sender
        _transferToken(acceptedToken, creator, refundFee);
        // transfer remaining fee to the fee holder
        _transferToken(acceptedToken, feeConfig.feeHolder, totalFee - refundFee);
        makeTransfer(address(this), creator, auction.nftToken, auction.tokenId, auction.quantity);
    }

    function directBuy(uint256 auctionId)
    external
    override
    nonReentrant {
        Auction memory auction = auctions[auctionId];
        require(auction.creator != address(0), "auction not found");
        require(!auction.finished, "already sold");
        require(!auction.canceled, "canceled");
        require(auction.creator != msg.sender, "can not buy your auction");
        require(auction.endTime >= _getBlockTimestamp(), "auction expired");
        
        uint256 totalPrice = auction.directSellingPrice;

        IERC20(auction.acceptedToken).safeTransferFrom(msg.sender, address(this), totalPrice);

        uint256 totalFees = totalPrice * auction.baseFeePercent / ONE_HUNDRED_PERCENT;
        totalPrice -= totalFees;

        // sold all quantities, check if should refund
        uint128 refundFee = _getRefundFees(auction.createdTime, auction.endTime, auction.priorityFee);
        totalFees += auction.priorityFee - refundFee;
        totalPrice += refundFee;

        // transfer fees to the feeHolder
        _transferToken(auction.acceptedToken, feeConfig.feeHolder, totalFees);

        _transferToken(auction.acceptedToken, auction.creator, totalPrice);
        makeTransfer(address(this), msg.sender, auction.nftToken, auction.tokenId, auction.quantity);
    }

    function placeBid(
        uint256 auctionId,
        uint256 raisePrice
    )
    external
    override
    nonReentrant {
        require(raisePrice > 0, "Raise zero");

        Auction memory auction = auctions[auctionId];

        require(auction.creator != msg.sender, "can not bid your auction");
        if (getHighestBid(auctionId) == 0) {
            require(raisePrice >= auction.startingPrice, "Lower than starting price");
        }

        uint newBid = fundsByBidder[auctionId][msg.sender] + raisePrice;

        require(newBid >= fundsByBidder[auctionId][auction.highestBidder] + auction.bidIncrement, "Invalid bid");

        IERC20(auction.acceptedToken).safeTransferFrom(msg.sender, address(this), raisePrice);

        auctions[auctionId].highestBidder = msg.sender;
        fundsByBidder[auctionId][msg.sender] = newBid;
    }

    function withdraw(uint256 auctionId)
    external
    override
    nonReentrant {
        uint withdrawalAmount;

        Auction memory auction = auctions[auctionId];
        require(
            auction.finished || auction.canceled || _getBlockTimestamp() > auction.endTime,
            "Not finish yet"
        );
        require(msg.sender != auction.highestBidder, "Highest bidder cannot withdraw");
        if (auction.canceled || auction.finished) {
            withdrawalAmount = fundsByBidder[auctionId][msg.sender];
            fundsByBidder[auctionId][msg.sender] = 0;
            IERC20(auction.acceptedToken).safeTransfer(msg.sender, withdrawalAmount);
        } else if (getHighestBid(auctionId) == 0) {
            require(msg.sender == auction.creator, "Only auction creator");
            require(!auction.ownerHasWithdrawn, "withdraw already");
            auction.ownerHasWithdrawn = true;
            makeTransfer(address(this), msg.sender, auction.nftToken, auction.tokenId, auction.quantity);
        } else {
            if (msg.sender == auction.creator) {
                require(!auction.ownerHasWithdrawn, "withdraw already");
                withdrawalAmount = getHighestBid(auctionId);
                auction.ownerHasWithdrawn = true;
                fundsByBidder[auctionId][auction.highestBidder] = 0;

                uint256 totalPrice = withdrawalAmount;
                uint256 totalFees = totalPrice * auction.baseFeePercent / ONE_HUNDRED_PERCENT;
                totalPrice -= totalFees;

                uint128 refundFee = _getRefundFees(auction.createdTime, auction.endTime, auction.priorityFee);
                totalFees += auction.priorityFee - refundFee;
                totalPrice += refundFee;

                // transfer fees to the feeHolder
                _transferToken(auction.acceptedToken, feeConfig.feeHolder, totalFees);
                _transferToken(auction.acceptedToken, auction.creator, totalPrice);

            } else if (msg.sender == auction.highestBidder){
                makeTransfer(address(this), msg.sender, auction.nftToken, auction.tokenId, auction.quantity);
            } else {
                withdrawalAmount = fundsByBidder[auctionId][msg.sender];
                fundsByBidder[auctionId][msg.sender] = 0;
                IERC20(auction.acceptedToken).safeTransfer(msg.sender, withdrawalAmount);
            }
        }
    }

     /**
    * @dev Set fee configuration, only called by the owner
    */
    function setFeeConfig(address _feeHolder, address _feeCalculator, uint64 _baseFeePercent)
        public onlyOwner
    {
        require(_feeHolder != address(0), 'invalid fee holder');
        feeConfig.feeHolder = _feeHolder;
        feeConfig.feeCalculator = _feeCalculator;
        feeConfig.baseFeePercent = _baseFeePercent;
        emit SetFeeConfig(_feeCalculator, _baseFeePercent);
    }

    function getBaseFeePercent(
        address user,
        address acceptedToken,
        address nftToken,
        uint256 tokenId,
        uint128 targetPrice,
        bool isSelling
    ) public view returns (uint64 baseFeePercent) {
        FeeConfig memory config = feeConfig;
        baseFeePercent = (config.feeCalculator == address(0))
            ? config.baseFeePercent
            : IFeeCalculator(config.feeCalculator).calculateBaseFeePercent(
                user, acceptedToken, nftToken, tokenId, targetPrice, isSelling
                );
    }

    function _transferToken(address token, address recipient, uint256 amount) internal {
        if (token == address(0)) {
            (bool success, ) = payable(recipient).call{ value: amount }('');
            require(success, "transfer native token failed");
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    function _getRefundFees(
        uint64 _createdTime,
        uint64 _expiredTime,
        uint128 _priorityFee
    ) internal view returns (uint128 refundFee) {
        uint64 currentTime = _getBlockTimestamp();
        if (currentTime < _expiredTime) {
            refundFee = _priorityFee * (_expiredTime - currentTime) / (_expiredTime - _createdTime);
        }
    }

    /**
    * @dev Function to transfer NFT
    */

    function makeTransfer(
        address _from,
        address _to,
        address _token,
        uint256 _tokenId,
        uint256 _value
    ) internal virtual;

    function hasValidOwnership(
        address _user,
        address _token,
        uint256 _tokenId,
        uint64 _quantities
    ) internal view virtual returns (bool);

    function _getBlockTimestamp() internal virtual view returns (uint64) {
        return uint64(block.timestamp);
    }
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

pragma solidity 0.8.4;


interface IAuctionBase {
    struct Auction {
        address creator;
        address acceptedToken;
        address nftToken;
        address highestBidder;
        uint256 tokenId;
        uint32 quantity;
        uint128 startingPrice;
        uint128 directSellingPrice;
        uint128 bidIncrement;
        uint64 createdTime;
        uint64 startTime;
        uint64 endTime;
        bool canceled;
        uint128 priorityFee;
        uint64 baseFeePercent;
        bool finished;
        bool ownerHasWithdrawn;
    }

    struct FeeConfig {
        address feeCalculator;
        address feeHolder;
        uint64 baseFeePercent;
    }

    event SetFeeConfig(address indexed feeCalculator, uint64 baseFeePercent);

    event AuctionCreated(
        address indexed creator,
        address indexed acceptedToken,
        address indexed nftToken,
        uint256 tokenId,
        uint64 quantities,
        uint128 targetPrice,
        uint128 baseFeePercent,
        uint128 priorityFee,
        uint64 createdTime,
        uint64 expiredTime,
        bool isSelling,
        uint256 auctionId
    );

    event AuctionCancelled(uint256 auctionId, address caller);

    function createAuction(
        address _acceptedToken,
        address _nftToken,
        uint256 _tokenId,
        uint32 _quantity,
        uint128 _startingPrice,
        uint128 _directSellingPrice,
        uint128 _bidIncrement,
        uint64 _startTime,
        uint64 _endTime,
        uint128 _priorityFee
    ) 
    external
    returns (uint256 auctionId);

    function getAuction(uint256 auctionId)
    external
    view
    returns (Auction memory);

    function getAuctionInRange(uint256 startIndex, uint256 endIndex)
    external
    view
    returns (Auction[] memory _autions);

    function getHighestBid(uint256 auctionId)
    external
    view
    returns (uint256);

    function cancelAuction(uint256 auctionId) external;

    function directBuy(uint256 auctionId) external;

    function placeBid(
        uint256 auctionId,
        uint256 raisePrice
    )
    external;

    function withdraw(uint256 auctionId) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;


interface IFeeCalculator {
  /**
   * @dev Calculate the base fee percent for user when creating an order/offer
   * @param user address of the user who is making the order/offer
   * @param acceptedToken the token that user wants to use to buy or sell to, only ERC20
   * @param nftToken nft token that user is interacting with
   * @param tokenId id of the token
   * @param price price that user wants to buy/sell
   * @param isSelling whether it is buy or sell
   */
  function calculateBaseFeePercent(
    address user,
    address acceptedToken,
    address nftToken,
    uint256 tokenId,
    uint256 price,
    bool isSelling
  ) external view returns (uint64 baseFeePercent);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';


contract Operators is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet internal operators;

  event OperatorsAdded(address[] _operators);
  event OperatorsRemoved(address[] _operators);

  constructor() {}

  function addOperators(address[] calldata _operators) public onlyOwner {
    for (uint256 i = 0; i < _operators.length; i++) {
      operators.add(_operators[i]);
    }
    emit OperatorsAdded(_operators);
  }

  function removeOperators(address[] calldata _operators) public onlyOwner {
    for (uint256 i = 0; i < _operators.length; i++) {
      operators.remove(_operators[i]);
    }
    emit OperatorsRemoved(_operators);
  }

  function isOperator(address _operator) public view returns (bool) {
    return operators.contains(_operator);
  }

  function numberOperators() public view returns (uint256) {
    return operators.length();
  }

  function operatorAt(uint256 i) public view returns (address) {
    return operators.at(i);
  }

  function getAllOperators() public view returns (address[] memory _operators) {
    _operators = new address[](operators.length());
    for (uint256 i = 0; i < _operators.length; i++) {
      _operators[i] = operators.at(i);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';


contract AcceptedTokenList is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct MinPriorityFee {
    uint128 sellOrderMinFee;
    uint128 buyOrderMinFee;
  }
  EnumerableSet.AddressSet internal acceptedTokens;
  // min priority fee per second for each token, to prevent spamming
  mapping (address => MinPriorityFee) internal minPriorityFeeData;

  event TokensAdded(address[] _tokens);
  event TokensRemoved(address[] _tokens);

  constructor() {}

  function addAcceptedTokens(
    address[] memory _tokens,
    uint128[] memory _minPriorityFeeSell,
    uint128[] memory _minPriorityFeeBuy
  )
    public onlyOwner
  {
    require(
      _tokens.length == _minPriorityFeeSell.length && _tokens.length == _minPriorityFeeBuy.length,
      'invalid lengths'
    );
    for (uint256 i = 0; i < _tokens.length; i++) {
      acceptedTokens.add(_tokens[i]);
      minPriorityFeeData[_tokens[i]] = MinPriorityFee({
        sellOrderMinFee: _minPriorityFeeSell[i],
        buyOrderMinFee: _minPriorityFeeBuy[i]
      });
    }
    emit TokensAdded(_tokens);
  }

  function removeAcceptedTokens(address[] calldata _tokens) public onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      acceptedTokens.remove(_tokens[i]);
      delete minPriorityFeeData[_tokens[i]];
    }
    emit TokensRemoved(_tokens);
  }

  function isTokenAccepted(address _token) public view returns (bool) {
    return acceptedTokens.contains(_token);
  }

  function numberAcceptedTokens() public view returns (uint256) {
    return acceptedTokens.length();
  }

  function acceptedTokenAt(uint256 i) public view returns (address) {
    return acceptedTokens.at(i);
  }

  function getAllAcceptedTokens() public view returns (address[] memory _tokens) {
    _tokens = new address[](acceptedTokens.length());
    for (uint256 i = 0; i < _tokens.length; i++) {
      _tokens[i] = acceptedTokens.at(i);
    }
  }

  function getMinPriorityFeeData(address _token) public view returns (MinPriorityFee memory) {
    return minPriorityFeeData[_token];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}