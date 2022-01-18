/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

interface IDocuments {
    function _removeDocument(string calldata _name) external;
    function getDocumentCount() external view returns (uint256);
    function getAllDocuments() external view returns (bytes memory);
    function _setDocument(string calldata _name, string calldata _data)
        external;
    function getDocumentName(uint256 _index)
        external
        view
        returns (string memory);
    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256);
}

interface IAnnexStake {
    function depositReward() external payable;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AnnexDutchAuction is ReentrancyGuard, Ownable {

    mapping (bytes32 => uint) internal config;
    IDocuments public documents; // for storing documents
    IERC20 public annexToken;
    address public treasury;
    uint256 public threshold = 100000 ether; // 100000 ANN

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 internal constant TxFeeRatio =              bytes32("TxFeeRatio");
    bytes32 internal constant MinValueOfBotHolder =     bytes32("MinValueOfBotHolder");
    bytes32 internal constant BotToken =                bytes32("BotToken");
    bytes32 internal constant StakeContract =           bytes32("StakeContract");

    struct AuctionReq {
        // address of sell token
        address _auctioningToken;
        // address of buy token
        address _biddingToken;
        // total amount of _auctioningToken
        uint _auctionedSellAmount;
        // maximum amount of ETH that creator want to swap
        uint amountMax1;
        // minimum amount of ETH that creator want to swap
        uint amountMin1;
        // uint amountReserve1;
        // how many times a bid will decrease it's price
        uint times;
        // the timestamp in seconds the auction will open
        uint auctionStartDate;
        // the timestamp in seconds the auction will be closed
        uint auctionEndDate;
        bool onlyBot;
        // whether or not whitelist is enable
        bool enableWhiteList;
        // About Info in request
        AuctionAbout about;
    }

    struct Auction {
        // creator of the auction
        address payable creator;
        // address of sell token
        address _auctioningToken;
        // address of buy token
        address _biddingToken;
        // total amount of sell token
        uint _auctionedSellAmount;
        // maximum amount of ETH that creator want to swap
        uint amountMax1;
        // minimum amount of ETH that creator want to swap
        uint amountMin1;
        // how many times a bid will decrease it's price
        uint times;
        // the duration in seconds the auction will be closed
        uint duration;
        // the timestamp in seconds the auction will open
        uint auctionStartDate;
        // the timestamp in seconds the auction will be closed
        uint auctionEndDate;
        // whether or not whitelist is enable
        bool enableWhiteList;
    }

    struct AuctionAbout {
        string website;
        string description;
        string telegram;
        string discord;
        string medium;
        string twitter;
    }

    Auction[] public auctions;

    // auction auctionId => amount of sell token has been swap
    mapping(uint => uint) public amountSwap0P;
    // auction auctionId => amount of ETH has been swap
    mapping(uint => uint) public amountSwap1P;
    // auction auctionId => a flag that if creator is claimed the auction
    mapping(uint => bool) public creatorClaimedP;
    // auction auctionId => the swap auction only allow BOT holder to take part in
    mapping(uint => bool) public onlyBotHolderP;

    mapping(uint => uint) public lowestBidPrice;
    // bidder address => auction auctionId => whether or not bidder claimed
    mapping(address => mapping(uint => bool)) public bidderClaimedP;
    // bidder address => auction auctionId => swapped amount of _auctioningToken
    mapping(address => mapping(uint => uint)) public myAmountSwap0P;
    // bidder address => auction auctionId => swapped amount of _biddingToken
    mapping(address => mapping(uint => uint)) public myAmountSwap1P;

    // creator address => auction auctionId + 1. if the result is 0, the account don't create any auction.
    mapping(address => uint) public myCreatedP;

    bool public enableWhiteList;
    // auction auctionId => account => whether or not allow swap
    mapping(uint => mapping(address => bool)) public whitelistP;

    event NewAuction(
        uint256 indexed auctionId,
        address _auctioningToken,
        address _biddingToken,
        uint256 auctionStartDate,
        uint256 auctionEndDate,
        address auctioner_address,
        uint256 _auctionedSellAmount,
        uint256 amountMax1,
        uint256 amountMin1
    );

    event NewSellOrder(uint indexed auctionId, address indexed sender, uint _minBuyAmounts, uint _sellAmounts);
    event ClaimedFromOrder(uint indexed auctionId, address indexed sender, uint unFilled_minBuyAmounts);
    event AuctionDetails(
        uint256 indexed auctionId,
        string[6] social
    );

    function initiateAuction(AuctionReq memory auctionReq, address[] memory whitelist_) external nonReentrant {

        // Auctioner can init an auction if he has 100 Ann
        require(
            annexToken.balanceOf(msg.sender) >= threshold,
            "NOT_ENOUGH_ANN"
        );
        if (threshold > 0) {
            annexToken.safeTransferFrom(msg.sender, treasury, threshold);
        }

        require(tx.origin == msg.sender, "disallow contract caller");
        require(auctionReq._auctionedSellAmount != 0, "the value of _auctionedSellAmount is zero");
        require(auctionReq.amountMin1 != 0, "the value of amountMax1 is zero");
        require(auctionReq.amountMax1 != 0, "the value of amountMin1 is zero");
        require(auctionReq.amountMax1 > auctionReq.amountMin1, "amountMax1 should larger than amountMin1");
        // require(auctionReq.auctionStartDate <= auctionReq.auctionEndDate && auctionReq.auctionEndDate.sub(auctionReq.auctionStartDate) < 7 days, "invalid closed");
        require(auctionReq.times != 0, "the value of times is zero");
        // require(bytes(auctionReq.name).length <= 15, "the length of name is too long");

        uint auctionId = auctions.length;

        // transfer amount of _auctioningToken to this contract
        IERC20  __auctioningToken = IERC20(auctionReq._auctioningToken);
        uint _auctioningTokenBalanceBefore = __auctioningToken.balanceOf(address(this));
        __auctioningToken.safeTransferFrom(msg.sender, address(this), auctionReq._auctionedSellAmount);
        require(
            __auctioningToken.balanceOf(address(this)).sub(_auctioningTokenBalanceBefore) == auctionReq._auctionedSellAmount,
            "not support deflationary token"
        );

        if (auctionReq.enableWhiteList) {
            require(whitelist_.length > 0, "no whitelist imported");
            _addWhitelist(auctionId, whitelist_);
        }

        // creator auction
        Auction memory auction;
        auction.creator = msg.sender;
        auction._auctioningToken = auctionReq._auctioningToken;
        auction._biddingToken = auctionReq._biddingToken;
        auction._auctionedSellAmount = auctionReq._auctionedSellAmount;
        auction.amountMax1 = auctionReq.amountMax1;
        auction.amountMin1 = auctionReq.amountMin1;
        auction.times = auctionReq.times;
        auction.duration = auctionReq.auctionEndDate.sub(auctionReq.auctionStartDate);
        auction.auctionStartDate = auctionReq.auctionStartDate;
        auction.auctionEndDate = auctionReq.auctionEndDate;
        auction.enableWhiteList = auctionReq.enableWhiteList;
        auctions.push(auction);

        if (auctionReq.onlyBot) {
            onlyBotHolderP[auctionId] = auctionReq.onlyBot;
        }

        myCreatedP[msg.sender] = auctions.length;

        emit NewAuction(auctionId,auctionReq._auctioningToken,auctionReq._biddingToken,auctionReq.auctionStartDate,auctionReq.auctionEndDate,msg.sender,auctionReq._auctionedSellAmount,auctionReq.amountMax1,auctionReq.amountMin1);

        /**
        * socials[0] = webiste link 
        * socials[1] = description 
        * socials[2] = telegram link 
        * socials[3] = discord link 
        * socials[4] = medium link 
        * socials[5] = twitter link 
        **/
        string[6] memory socials = [auctionReq.about.website,auctionReq.about.description,auctionReq.about.telegram,auctionReq.about.discord,auctionReq.about.medium,auctionReq.about.twitter];
        emit AuctionDetails(
            auctionId,
            socials
        );

    }

    function placeSellOrders(
        // auction auctionId
        uint auctionId,
        // amount of _auctioningToken want to bid
        uint _minBuyAmounts,
        // amount of _biddingToken
        uint _sellAmounts
    ) external payable
        nonReentrant
        isAuctionExist(auctionId)
        checkBotHolder(auctionId)
        isAuctionNotClosed(auctionId)
    {
        address payable sender = msg.sender;
        require(tx.origin == msg.sender, "disallow contract caller");
        if (enableWhiteList) {
            require(whitelistP[auctionId][sender], "sender not in whitelist");
        }
        Auction memory auction = auctions[auctionId];
        require(auction.auctionStartDate <= now, "auction not open");
        require(_minBuyAmounts != 0, "the value of _minBuyAmounts is zero");
        require(_sellAmounts != 0, "the value of _sellAmounts is zero");
        require(auction._auctionedSellAmount > amountSwap0P[auctionId], "swap amount is zero");

        // calculate price
        uint curPrice = currentPrice(auctionId);
        uint bidPrice = _sellAmounts.mul(1 ether).div(_minBuyAmounts);
        require(bidPrice >= curPrice, "the bid price is lower than the current price");

        if (lowestBidPrice[auctionId] == 0 || lowestBidPrice[auctionId] > bidPrice) {
            lowestBidPrice[auctionId] = bidPrice;
        }

        address _biddingToken = auction._biddingToken;
        if (_biddingToken == address(0)) {
            require(_sellAmounts == msg.value, "invalid ETH amount");
        } else {
            IERC20(_biddingToken).safeTransferFrom(sender, address(this), _sellAmounts);
        }

        _swap(sender, auctionId, _minBuyAmounts, _sellAmounts);

        emit NewSellOrder(auctionId, sender, _minBuyAmounts, _sellAmounts);
    }

    function creatorClaim(uint auctionId) external
        nonReentrant
        isAuctionExist(auctionId)
        isAuctionClosed(auctionId)
    {
        address payable creator = msg.sender;
        require(isCreator(creator, auctionId), "sender is not auction creator");
        require(!creatorClaimedP[auctionId], "creator has claimed this auction");
        creatorClaimedP[auctionId] = true;

        // remove ownership of this auction from creator
        delete myCreatedP[creator];

        // calculate un-filled _minBuyAmounts
        Auction memory auction = auctions[auctionId];
        uint unFilled_minBuyAmounts = auction._auctionedSellAmount.sub(amountSwap0P[auctionId]);
        if (unFilled_minBuyAmounts > 0) {
            // transfer un-filled amount of _auctioningToken back to creator
            IERC20(auction._auctioningToken).safeTransfer(creator, unFilled_minBuyAmounts);
        }

        // send _biddingToken to creator
        uint _sellAmounts = lowestBidPrice[auctionId].mul(amountSwap0P[auctionId]).div(1 ether);
        if (_sellAmounts > 0) {
            if (auction._biddingToken == address(0)) {
                uint256 txFee = _sellAmounts.mul(getTxFeeRatio()).div(1 ether);
                uint256 _actual_sellAmounts = _sellAmounts.sub(txFee);
                if (_actual_sellAmounts > 0) {
                    auction.creator.transfer(_actual_sellAmounts);
                }
                if (txFee > 0) {
                    // deposit transaction fee to staking contract
                    IAnnexStake(getStakeContract()).depositReward{value: txFee}();
                }
            } else {
                IERC20(auction._biddingToken).safeTransfer(auction.creator, _sellAmounts);
            }
        }

    
        emit ClaimedFromOrder(auctionId, creator, unFilled_minBuyAmounts);
    }

    function bidderClaim(uint auctionId) external
        nonReentrant
        isAuctionExist(auctionId)
        isAuctionClosed(auctionId)
    {
        address payable bidder = msg.sender;
        require(!bidderClaimedP[bidder][auctionId], "bidder has claimed this auction");
        bidderClaimedP[bidder][auctionId] = true;

        Auction memory auction = auctions[auctionId];
        // send _auctioningToken to bidder
        if (myAmountSwap0P[bidder][auctionId] > 0) {
            IERC20(auction._auctioningToken).safeTransfer(bidder, myAmountSwap0P[bidder][auctionId]);
        }

        // send unfilled _biddingToken to bidder
        uint actual_sellAmounts = lowestBidPrice[auctionId].mul(myAmountSwap0P[bidder][auctionId]).div(1 ether);
        uint unfilled_sellAmounts = myAmountSwap1P[bidder][auctionId].sub(actual_sellAmounts);
        if (unfilled_sellAmounts > 0) {
            if (auction._biddingToken == address(0)) {
                bidder.transfer(unfilled_sellAmounts);
            } else {
                IERC20(auction._biddingToken).safeTransfer(bidder, unfilled_sellAmounts);
            }
        }
    }

    function _swap(address payable sender, uint auctionId, uint _minBuyAmounts, uint _sellAmounts) private {
        Auction memory auction = auctions[auctionId];
        uint __minBuyAmounts = auction._auctionedSellAmount.sub(amountSwap0P[auctionId]);
        uint __sellAmounts = 0;
        uint _excess_sellAmounts = 0;

        // check if _minBuyAmounts is exceeded
        if (__minBuyAmounts < _minBuyAmounts) {
            __sellAmounts = __minBuyAmounts.mul(_sellAmounts).div(_minBuyAmounts);
            _excess_sellAmounts = _sellAmounts.sub(__sellAmounts);
        } else {
            __minBuyAmounts = _minBuyAmounts;
            __sellAmounts = _sellAmounts;
        }
        myAmountSwap0P[sender][auctionId] = myAmountSwap0P[sender][auctionId].add(__minBuyAmounts);
        myAmountSwap1P[sender][auctionId] = myAmountSwap1P[sender][auctionId].add(__sellAmounts);
        amountSwap0P[auctionId] = amountSwap0P[auctionId].add(__minBuyAmounts);
        amountSwap1P[auctionId] = amountSwap1P[auctionId].add(__sellAmounts);

        // send excess amount of _biddingToken back to sender
        if (_excess_sellAmounts > 0) {
            if (auction._biddingToken == address(0)) {
                sender.transfer(_excess_sellAmounts);
            } else {
                IERC20(auction._biddingToken).safeTransfer(sender, _excess_sellAmounts);
            }
        }
    }

    function isCreator(address target, uint auctionId) private view returns (bool) {
        if (auctions[auctionId].creator == target) {
            return true;
        }
        return false;
    }

    function currentPrice(uint auctionId) public view returns (uint) {
        Auction memory auction = auctions[auctionId];
        uint __sellAmounts = auction.amountMin1;
        uint realTimes = auction.times.add(1);

        if (now < auction.auctionEndDate) {
            uint stepInSeconds = auction.duration.div(realTimes);
            if (stepInSeconds != 0) {
                uint remainingTimes = auction.auctionEndDate.sub(now).sub(1).div(stepInSeconds);
                if (remainingTimes != 0) {
                    __sellAmounts = auction.amountMax1.sub(auction.amountMin1)
                        .mul(remainingTimes).div(auction.times)
                        .add(auction.amountMin1);
                }
            }
        }

        return __sellAmounts.mul(1 ether).div(auction._auctionedSellAmount);
    }

    function nextRoundInSeconds(uint auctionId) public view returns (uint) {
        Auction memory auction = auctions[auctionId];
        if (now >= auction.auctionEndDate) return 0;
        uint realTimes = auction.times.add(1);
        uint stepInSeconds = auction.duration.div(realTimes);
        if (stepInSeconds == 0) return 0;
        uint remainingTimes = auction.auctionEndDate.sub(now).sub(1).div(stepInSeconds);

        return auction.auctionEndDate.sub(remainingTimes.mul(stepInSeconds)).sub(now);
    }

    function _addWhitelist(uint auctionId, address[] memory whitelist_) private {
        for (uint i = 0; i < whitelist_.length; i++) {
            whitelistP[auctionId][whitelist_[i]] = true;
        }
    }

    function addWhitelist(uint auctionId, address[] memory whitelist_) external {
        require(owner() == msg.sender || auctions[auctionId].creator == msg.sender, "no permission");
        _addWhitelist(auctionId, whitelist_);
    }

    function removeWhitelist(uint auctionId, address[] memory whitelist_) external {
        require(owner() == msg.sender || auctions[auctionId].creator == msg.sender, "no permission");
        for (uint i = 0; i < whitelist_.length; i++) {
            delete whitelistP[auctionId][whitelist_[i]];
        }
    }

    function getAuctionCount() public view returns (uint) {
        return auctions.length;
    }

    function getTxFeeRatio() public view returns (uint) {
        return config[TxFeeRatio];
    }

    function getMinValueOfBotHolder() public view returns (uint) {
        return config[MinValueOfBotHolder];
    }

    function getBotToken() public view returns (address) {
        return address(config[BotToken]);
    }

    function getStakeContract() public view returns (address) {
        return address(config[StakeContract]);
    }

    modifier checkBotHolder(uint auctionId) {
        if (onlyBotHolderP[auctionId]) {
            require(IERC20(getBotToken()).balanceOf(msg.sender) >= getMinValueOfBotHolder(), "BOT is not enough");
        }
        _;
    }

    modifier isAuctionClosed(uint auctionId) {
        require(auctions[auctionId].auctionEndDate <= now, "this auction is not closed");
        _;
    }

    modifier isAuctionNotClosed(uint auctionId) {
        require(auctions[auctionId].auctionEndDate > now, "this auction is closed");
        _;
    }

    modifier isAuctionNotCreate(address target) {
        if (myCreatedP[target] > 0) {
            revert("a auction has created by this address");
        }
        _;
    }

    modifier isAuctionExist(uint auctionId) {
        require(auctionId < auctions.length, "this auction does not exist");
        _;
    }

    //--------------------------------------------------------
    // Getter & Setters
    //--------------------------------------------------------

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function setAnnexAddress(address _annexToken) external onlyOwner {
        annexToken = IERC20(_annexToken);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setDocumentAddress(address _document) external onlyOwner {
        documents = IDocuments(_document);
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data)
        external
        onlyOwner()
    {
        documents._setDocument(_name, _data);
    }

    function getDocumentCount() external view returns (uint256) {
        return documents.getDocumentCount();
    }

    function getAllDocuments() external view returns (bytes memory) {
        return documents.getAllDocuments();
    }

    function getDocumentName(uint256 _auctionId)
        external
        view
        returns (string memory)
    {
        return documents.getDocumentName(_auctionId);
    }

    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256)
    {
        return documents.getDocument(_name);
    }

    function removeDocument(string calldata _name) external {
        documents._removeDocument(_name);
    }

    //--------------------------------------------------------
    // Configurable
    //--------------------------------------------------------

    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint auctionId) public view returns (uint) {
        return config[bytes32(uint(key) ^ auctionId)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }
    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint auctionId, uint value) internal {
        _setConfig(bytes32(uint(key) ^ auctionId), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    function setConfig(bytes32 key, uint value) external onlyOwner {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint auctionId, uint value) external onlyOwner {
        _setConfig(bytes32(uint(key) ^ auctionId), value);
    }
    function setConfig(bytes32 key, address addr, uint value) public onlyOwner {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}