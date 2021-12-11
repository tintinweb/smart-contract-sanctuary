// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IMarket.sol';
import './interfaces/Iutils.sol';

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Counters} from '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";


contract Market is IMarket, Ownable, ERC1155Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _auctionIdTracker;

    address private _mediaContract;
    address private _adminAddress;

    // To store commission amount of admin
    uint256 private _adminPoints;
    // To storre commission percentage for each mint
    uint8 private _adminCommissionPercentage;

    // tokenID => (bidderAddress => BidAmount)
    mapping(uint256 => mapping(address => uint256)) private tokenBids;

    // Mapping from token to mapping from bidder to bid
    mapping(uint256 => mapping(address => Iutils.Bid)) private _tokenBidders;

    // Mapping from token to the current ask for the token
    mapping(uint256 => Iutils.Ask) private _tokenAsks;

    // userAddress => its Redeem points
    mapping(address => uint256) private userRedeemPoints;

    // tokenID => List of Transactions
    mapping(uint256 => string[]) private tokenTransactionHistory;

    // tokenID => creator's Royalty Percentage
    mapping(uint256 => uint8) private tokenRoyaltyPercentage;

    // tokenID => { collaboratorsAddresses[] , percentages[] }
    mapping(uint256 => Collaborators) private tokenCollaborators;

    // tokenID => all Bidders
    mapping(uint256 => address[]) private tokenBidders;

    mapping(address => bool) private approvedCurrency;

    // address[] public allApprovedCurrencies;

    // The minimum percentage difference between the last bid amount and the current bid.
    uint8 public minBidIncrementPercentage = 5;

    modifier onlyMediaCaller() {
        require(msg.sender == _mediaContract, 'Market: Unauthorized Access!');
        _;
    }

    uint256 constant EXPO = 1e18;

    uint256 constant BASE = 100 * EXPO;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer = 15 * 60; // extend 15 minutes after every bid made in last 15 minutes

    // New Code -----------

    struct NewBid {
        uint256 _amount;
        uint256 _bidAmount;
    }

    // tokenID => owner => bidder => Bid Struct
    mapping(uint256 => mapping(address => mapping(address => NewBid))) private _newTokenBids;

    // tokenID => owner => all bidders
    mapping(uint256 => mapping(address => address[])) private newTokenBidders;

    /**
     * @notice This method is used to Set Media Contract's Address
     *
     * @param _mediaContractAddress Address of the Media Contract to set
     */
    function configureMedia(address _mediaContractAddress) external onlyOwner {
        require(_mediaContractAddress != address(0), 'Market: Invalid Media Contract Address!');
        require(_mediaContract == address(0), 'Market: Media Contract Alredy Configured!');

        _mediaContract = _mediaContractAddress;
    }

    /**
     * @dev See {IMarket}
     */
    function setCollaborators(uint256 _tokenID, Collaborators calldata _collaborators)
        external
        override
        onlyMediaCaller
    {
        tokenCollaborators[_tokenID] = _collaborators;
    }

    /**
     * @dev See {IMarket}
     */
    function setRoyaltyPoints(uint256 _tokenID, uint8 _royaltyPoints) external override onlyMediaCaller {
        tokenRoyaltyPercentage[_tokenID] = _royaltyPoints;
    }

    /**
     * @dev See {IMarket}
     */
    function setBid(
        uint256 _tokenID,
        address _bidder,
        Iutils.Bid calldata _bid,
        address _owner,
        address _creator
    ) external override onlyMediaCaller returns (bool) {
        require(_bid._amount != 0, "Market: You Can't Bid With 0 Amount!");
        require(_bid._bidAmount != 0, "Market: You Can't Bid For 0 Tokens");
        require(!(_bid._bidAmount < 0), "Market: You Can't Bid For Negative Tokens");
        require(_bid._currency != address(0), 'Market: bid currency cannot be 0 address');
        require(this.isTokenApproved(_bid._currency), 'Market: bid currency not approved by admin');
        require(_bid._recipient != address(0), 'Market: bid recipient cannot be 0 address');
        require(_tokenAsks[_tokenID]._currency != address(0), 'Market: Token is not open for Sale');
        require(
            _bid._amount >= _tokenAsks[_tokenID]._reserveAmount,
            'Market: Bid Cannot be placed below the min Amount'
        );
        require(_bid._currency == _tokenAsks[_tokenID]._currency, 'Market: Incorrect payment Method');

        IERC20 token = IERC20(_tokenAsks[_tokenID]._currency);

        // fetch existing bid, if there is any
        require(
            token.allowance(_bid._bidder, address(this)) >= _bid._amount,
            'Market: Please Approve Tokens Before You Bid'
        );
        Iutils.Bid storage existingBid = _tokenBidders[_tokenID][_bidder];

        if (_tokenAsks[_tokenID].askType == Iutils.AskTypes.FIXED) {
            require(
                _bid._amount <= _tokenAsks[_tokenID]._askAmount,
                'Market: You Cannot Pay more then Max Asked Amount '
            );
            // If there is an existing bid, refund it before continuing
            if (existingBid._amount > 0) {
                removeBid(_tokenID, _bid._bidder);
            }
            _handleIncomingBid(_bid._amount, _tokenAsks[_tokenID]._currency, _bid._bidder);

            // Set New Bid for the Token
            _tokenBidders[_tokenID][_bid._bidder] = Iutils.Bid(
                _bid._bidAmount,
                _bid._amount,
                _bid._currency,
                _bid._bidder,
                _bid._recipient,
                _bid.askType
            );

            emit BidCreated(_tokenID, _bid);
            // Needs to be taken care of
            // // If a bid meets the criteria for an ask, automatically accept the bid.
            // // If no ask is set or the bid does not meet the requirements, ignore.
            if (
                _tokenAsks[_tokenID]._currency != address(0) &&
                _bid._currency == _tokenAsks[_tokenID]._currency &&
                _bid._amount >= _tokenAsks[_tokenID]._askAmount
            ) {
                // Finalize Exchange
                divideMoney(_tokenID, _owner, _bidder, _bid._amount, _creator);
            }
            return true;
        } else {
            _handleAuction(_tokenID, _bid);
            return false;
        }
    }

    function _handleAuction(uint256 _tokenID, Iutils.Bid calldata _bid) internal {
        IERC20 token = IERC20(_tokenAsks[_tokenID]._currency);

        // fetch existing bid, if there is any
        require(
            token.allowance(_bid._bidder, address(this)) >= _bid._amount,
            'Market: Please Approve Tokens Before You Bid'
        );
        // Manage if the Bid is of Auction Type
        address lastBidder = _tokenAsks[_tokenID]._bidder;

        require(
            _tokenAsks[_tokenID]._firstBidTime == 0 ||
                block.timestamp < _tokenAsks[_tokenID]._firstBidTime.add(_tokenAsks[_tokenID]._duration),
            'Market: Auction expired'
        );

        require(
            _bid._amount >=
                _tokenAsks[_tokenID]._highestBid.add(
                    _tokenAsks[_tokenID]._highestBid.mul(minBidIncrementPercentage * EXPO).div(BASE)
                ),
            'Market: Must send more than last bid by minBidIncrementPercentage amount'
        );
        if (_tokenAsks[_tokenID]._firstBidTime == 0) {
            // If this is the first valid bid, we should set the starting time now.
            _tokenAsks[_tokenID]._firstBidTime = block.timestamp;
            // Set New Bid for the Token
        } else if (lastBidder != address(0)) {
            // If it's not, then we should refund the last bidder
            delete _tokenBidders[_tokenID][lastBidder];
            token.safeTransfer(lastBidder, _tokenAsks[_tokenID]._highestBid);
        }
        _tokenAsks[_tokenID]._highestBid = _bid._amount;
        _tokenAsks[_tokenID]._bidder = _bid._bidder;
        _handleIncomingBid(_bid._amount, _tokenAsks[_tokenID]._currency, _bid._bidder);

        // create new Bid
        _tokenBidders[_tokenID][_bid._bidder] = Iutils.Bid(
            _bid._bidAmount,
            _bid._amount,
            _bid._currency,
            _bid._bidder,
            _bid._recipient,
            _bid.askType
        );

        emit BidCreated(_tokenID, _bid);

        bool extended = false;

        // at this point we know that the timestamp is less than start + duration (since the auction would be over, otherwise)
        // we want to know by how much the timestamp is less than start + duration
        // if the difference is less than the timeBuffer, increase the duration by the timeBuffer
        uint256 auctionDuration = _tokenAsks[_tokenID]._firstBidTime.add(_tokenAsks[_tokenID]._duration);
        if (auctionDuration.sub(block.timestamp) < timeBuffer) {
            uint256 oldDuration = _tokenAsks[_tokenID]._duration;
            uint256 _firstBidTime = _tokenAsks[_tokenID]._firstBidTime;
            _tokenAsks[_tokenID]._duration = oldDuration.add(
                timeBuffer.sub(_firstBidTime.add(oldDuration).sub(block.timestamp))
            );
            extended = true;
        }
    }

    function _handleIncomingBid(
        uint256 _amount,
        address _currency,
        address _bidder
    ) internal {
        // We must check the balance that was actually transferred to the auction,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in potentally locked funds
        IERC20 token = IERC20(_currency);
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(_bidder, address(this), _amount);
        uint256 afterBalance = token.balanceOf(address(this));
        require(beforeBalance.add(_amount) == afterBalance, 'Token transfer call did not transfer expected amount');
    }

    // /**
    //  * @notice Sets the ask on a particular media. If the ask cannot be evenly split into the media's
    //  * bid shares, this reverts.
    //  */
    function setAsk(uint256 _tokenID, Iutils.Ask memory ask) public override onlyMediaCaller {
        if (ask.askType == Iutils.AskTypes.FIXED) {
            require(ask._reserveAmount == ask._askAmount, 'Amount observe and Asked Need to be same for Fixed Sale');
        }
        //TODO reserve amount cannot be greater than ask amoutn
        // require(ask._reserveAmount < ask._askAmount, 'Market reserve amount error');
        require(this.isTokenApproved(ask._currency), 'Market: ask currency not approved by admin');
        _tokenAsks[_tokenID] = ask;
        emit AskCreated(_tokenID, ask);
    }

    function removeBid(uint256 _tokenID, address _bidder) public override onlyMediaCaller {
        Iutils.Bid storage bid = _tokenBidders[_tokenID][_bidder];
        uint256 bidAmount = bid._amount;
        address bidCurrency = bid._currency;

        require(bid._bidder == _bidder, 'Market: Only bidder can remove the bid');
        require(bid._amount > 0, 'Market: cannot remove bid amount of 0');

        IERC20 token = IERC20(bidCurrency);
        emit BidRemoved(_tokenID, bid);
        // line safeTransfer should be upper before delete??
        token.safeTransfer(bid._bidder, bidAmount);
        delete _tokenBidders[_tokenID][_bidder];

    }

    /**
     * @dev See {IMarket}
     */
    function setAdminAddress(address _newAdminAddress) external override onlyMediaCaller returns (bool) {
        require(_newAdminAddress != address(0), 'Market: Invalid Admin Address!');
        require(_adminAddress == address(0), 'Market: Admin Already Configured!');

        _adminAddress = _newAdminAddress;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function addCurrency(address _tokenAddress) external override onlyMediaCaller returns (bool) {
        
        require(_tokenAddress != address(0), 'Market: Invalid Token Address!');
        require(!this.isTokenApproved(_tokenAddress), 'Market: Token Already Configured!');

        approvedCurrency[_tokenAddress] = true;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function removeCurrency(address _tokenAddress) external override onlyMediaCaller returns (bool) {
        
        require(_tokenAddress != address(0), 'Market: Invalid Token Address!');
        require(this.isTokenApproved(_tokenAddress), 'Market: Token not found!');

        approvedCurrency[_tokenAddress] = false;
        return true;
    }

     /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
            if (approvedCurrency[_tokenAddress] == true) {
                return true;
                } else {
                return false;
            }
    }

    /**
     * @dev See {IMarket}
     */
    function getAdminAddress() external view override onlyMediaCaller returns (address) {
        return _adminAddress;
    }

    /**
     * @dev See {IMarket}
     */
    function setCommissionPercentage(uint8 _commissionPercentage) external override onlyMediaCaller returns (bool) {
        _adminCommissionPercentage = _commissionPercentage;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function getCommissionPercentage() external view override onlyMediaCaller returns (uint8) {
        return _adminCommissionPercentage;
    }

    function endAuction(
        uint256 _tokenID,
        address _owner,
        address _creator
    ) external override onlyMediaCaller returns (bool) {
        require(uint256(_tokenAsks[_tokenID]._firstBidTime) != 0, "Market.Auction hasn't begun");
        require(
            block.timestamp >= _tokenAsks[_tokenID]._firstBidTime.add(_tokenAsks[_tokenID]._duration),
            "Auction hasn't completed"
        );
        // address(0) for _bidder is only need when sale type is of type Auction
        return divideMoney(_tokenID, _owner, address(0), _tokenAsks[_tokenID]._highestBid, _creator);
    }

    /**
     * @notice Cancel an auction.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCanceled event
     */
    function cancelAuction(uint256 _tokenID) external override onlyMediaCaller {
        require(uint256(_tokenAsks[_tokenID]._firstBidTime) == 0, "Can't cancel an auction once it's begun");
        delete _tokenAsks[_tokenID];
    }

    /**
     * @dev See {IMarket}
     */
    function divideMoney(
        uint256 _tokenID,
        address _owner,
        address _bidder,
        uint256 _amountToDistribute,
        address _creator
    ) internal returns (bool) {
        require(_amountToDistribute > 0, "Market: Amount To Divide Can't Be 0!");

        Iutils.Ask memory _ask = _tokenAsks[_tokenID];
        IERC20 token = IERC20(_ask._currency);

        // first send admin cut
        uint256 adminCommission = _amountToDistribute.mul(_adminCommissionPercentage * EXPO).div(BASE);
        uint256 _amount = _amountToDistribute - adminCommission;

        token.transfer(_adminAddress, adminCommission);

        // fetch owners added royality points
        uint256 collabPercentage = tokenRoyaltyPercentage[_tokenID];
        uint256 royaltyPoints = _amount.mul(collabPercentage * EXPO).div(BASE);

        // royaltyPoints represents amount going to divide among Collaborators
        token.transfer(_owner, _amount.sub(royaltyPoints));

        // Collaboratoes will only receive share when creator have set some royalty and sale is occuring for the first time
        Collaborators storage tokenColab = tokenCollaborators[_tokenID];
        uint256 totalAmountTransferred = 0;

        if (tokenColab._receiveCollabShare == false) {
            for (uint256 index = 0; index < tokenColab._collaborators.length; index++) {
                // Individual Collaborator's share Amount

                uint256 amountToTransfer = royaltyPoints.mul(tokenColab._percentages[index] * EXPO).div(BASE);
                // transfer Individual Collaborator's share Amount
                token.transfer(tokenColab._collaborators[index], amountToTransfer);
                // Total Amount Transferred
                totalAmountTransferred = totalAmountTransferred.add(amountToTransfer);
            }
            // after transfering to collabs, remaining would be sent to creator
            // update collaborators got the shares
            tokenColab._receiveCollabShare = true;
        }

        token.transfer(_creator, royaltyPoints.sub(totalAmountTransferred));
        
        totalAmountTransferred = totalAmountTransferred.add(royaltyPoints.sub(totalAmountTransferred));

        totalAmountTransferred = totalAmountTransferred.add(_amount.sub(royaltyPoints));
        // Check for Transfer amount error
        require(totalAmountTransferred == _amount, 'Market: Amount Transfer Value Error!');
        delete _tokenBidders[_tokenID][_bidder];
        delete _tokenAsks[_tokenID];

        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function addAdminCommission(uint256 _amount) external override onlyMediaCaller returns (bool) {
        _adminPoints = _adminPoints.add(_amount);
        return true;
    }

    function updateAsk(uint256 _tokenID, Iutils.Ask calldata ask) public override onlyMediaCaller {
        
        Iutils.Ask storage _oldAsk = _tokenAsks[_tokenID];

        if(ask.askType == Iutils.AskTypes.AUCTION) {
            require( _oldAsk._highestBid == ask._highestBid, "Market: cannot change highest bid");
        }
        if (ask.askType == Iutils.AskTypes.FIXED) {
            require(ask._reserveAmount == ask._askAmount, 'Amount observe and Asked Need to be same for Fixed Sale');
            } else {
            require(ask._reserveAmount < ask._askAmount, 'Market reserve amount error');
        }

        require(this.isTokenApproved(ask._currency), 'Market: ask currency not approved by admin');
        require(_oldAsk._sender == ask._sender, 'Market: sender should be token owner');
        // TODO what will the duration, will it be previous or updated one
        require(_oldAsk._duration == ask._duration, 'Market: cannot change duration');
        require(_oldAsk._firstBidTime == ask._firstBidTime, 'Market: cannot change first bid time');
        require(_oldAsk._bidder == ask._bidder, "Market: cannot change bidder");
        require( _oldAsk._highestBid == ask._highestBid, "Market: cannot change highest bid");

        // this require should be use if we don't remove the highest bid for the ask Price.
        require(ask._askAmount > _oldAsk._highestBid, "Market: Ask Amount Should be greater than highest bid");
        Iutils.Ask memory _updatedAsk = Iutils.Ask(
            _oldAsk._sender,
            ask._reserveAmount,
            ask._askAmount,
            ask._amount,
            ask._currency,
            ask.askType,
            _oldAsk._duration,
            _oldAsk._firstBidTime,
            _oldAsk._bidder,
            _oldAsk._highestBid
        );
        
        _tokenAsks[_tokenID] = _updatedAsk;
        emit AskUpdated(_tokenID, _updatedAsk);
    }

    function getTokenAsks(uint256 _tokenId) external view override returns( Iutils.Ask memory) {
        return _tokenAsks[_tokenId];
    }

    function getTokenBid(uint256 _tokenId) external view override returns( Iutils.Bid memory) {
        address bidder = _tokenAsks[_tokenId]._bidder;
        return _tokenBidders[_tokenId][bidder];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './Iutils.sol';

interface IMarket {
    struct Collaborators {
        address[] _collaborators;
        uint8[] _percentages;
        bool _receiveCollabShare;
    }

    event BidCreated(uint256 indexed tokenID, Iutils.Bid bid);
    event BidRemoved(uint256 indexed tokenID, Iutils.Bid bid);
    event AskCreated(uint256 indexed tokenID, Iutils.Ask ask);
    event AskUpdated(uint256 indexed _tokenID, Iutils.Ask ask);
    event CancelBid(uint256 tokenID, address bidder);
    event AcceptBid(uint256 tokenID, address owner, uint256 amount, address bidder, uint256 bidAmount);
    event Redeem(address userAddress, uint256 points);

    /**
     * @notice This method is used to set Collaborators to the Token
     * @param _tokenID TokenID of the Token to Set Collaborators
     * @param _collaborators Struct of Collaborators to set
     */
    function setCollaborators(uint256 _tokenID, Collaborators calldata _collaborators) external;

    /**
     * @notice tHis method is used to set Royalty Points for the token
     * @param _tokenID Token ID of the token to set
     * @param _royaltyPoints Points to set
     */
    function setRoyaltyPoints(uint256 _tokenID, uint8 _royaltyPoints) external;

    /**
     * @notice this function is used to place a Bid on token
     *
     * @param _tokenID Token ID of the Token to place Bid on
     * @param _bidder Address of the Bidder
     *
     * @return bool Stransaction Status
     */
    function setBid(
        uint256 _tokenID,
        address _bidder,
        Iutils.Bid calldata bid,
        address _owner,
        address _creator
    ) external returns (bool);

    function removeBid(uint256 tokenId, address bidder) external;

    function setAsk(uint256 tokenId, Iutils.Ask calldata ask) external;
    
    function updateAsk(uint256 tokenId, Iutils.Ask calldata ask ) external;

    function endAuction(
        uint256 _tokenID,
        address _owner,
        address _creator
    ) external returns (bool);

    function cancelAuction(uint256 _tokenID) external;

    /**
     * @notice This method is used to Divide the selling amount among Owner, Creator and Collaborators
     *
     * @param _tokenID Token ID of the Token sold
     * @param _owner Address of the Owner of the Token
     * @param _bidder Address of the _bidder of the Token
     * @param _amount Amount to divide -  Selling amount of the Token
     * @param _creator Original Owner of contract
     * @return bool Transaction status
     */

    /**
     * @notice This Method is used to set Commission percentage of The Admin
     *
     * @param _commissionPercentage New Commission Percentage To set
     *
     * @return bool Transaction status
     */
    function setCommissionPercentage(uint8 _commissionPercentage) external returns (bool);

    /**
     * @notice This Method is used to set Admin's Address
     *
     * @param _newAdminAddress Admin's Address To set
     *
     * @return bool Transaction status
     */
    function setAdminAddress(address _newAdminAddress) external returns (bool);

    /**
     * @notice This method is used to get Admin's Commission Percentage
     *
     * @return uint8 Commission Percentage
     */
    function getCommissionPercentage() external view returns (uint8);

    /**
     * @notice This method is used to get Admin's Address
     *
     * @return address Admin's Address
     */
    function getAdminAddress() external view returns (address);

    /**
     * @notice This method is used to give admin Commission while Minting new token
     *
     * @param _amount Commission Amount
     *
     * @return bool Transaction status
     */
    function addAdminCommission(uint256 _amount) external returns (bool);

    function addCurrency(address _tokenAddress) external returns (bool);

    function removeCurrency(address _tokenAddress) external returns (bool);

    function isTokenApproved(address _tokenAddress) external view returns (bool);

    function getTokenAsks(uint256 _tokenId) external view returns( Iutils.Ask memory);
    
    function getTokenBid(uint256 _tokenId) external view returns( Iutils.Bid memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Iutils {
    enum AskTypes {
        AUCTION,
        FIXED
    }
    struct Bid {
        // quantity of the tokens being bid
        uint256 _bidAmount;
        // amount of ERC20 token being used to bid
        uint256 _amount;
        // Address to the ERC20 token being used to bid
        address _currency;
        // Address of the bidder
        address _bidder;
        // Address of the recipient
        address _recipient;
        // Type of ask
        AskTypes askType;
    }
    struct Ask {
        //this is to check in Ask function if _sender is the token Owner
        address _sender;
        // min amount Asked
        uint256 _reserveAmount;
        // Amount of the currency being asked
        uint256 _askAmount;
        // Amount of the tokens being asked
        uint256 _amount;
        // Address to the ERC20 token being asked
        address _currency;
        // Type of ask
        AskTypes askType;
        // following attribute used for managing auction ask
        // The length of time to run the auction for, after the first bid was made
        uint256 _duration;
        // The time of the first bid
        uint256 _firstBidTime;
        // The address of the current highest bidder
        address _bidder;
        // The current highest bid amount
        uint256 _highestBid;
    }
}

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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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