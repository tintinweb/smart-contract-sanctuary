// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IMarket.sol';
// import './SafeMath.sol';
// import './IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract Market is IMarket {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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

    // bidderAddress => its Total Bid amount
    mapping(address => uint256) private userTotalBids;

    // Mapping from token to the current ask for the token
    mapping(uint256 => Iutils.Ask) public _tokenAsks;

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

    modifier onlyMediaCaller() {
        require(msg.sender == _mediaContract, 'Market: Unauthorized Access!');
        _;
    }

    // New Code -----------

    struct NewBid {
        uint256 _amount;
        uint256 _bidAmount;
    }

    // tokenID => owner => bidder => Bid Struct
    mapping(uint256 => mapping(address => mapping(address => NewBid))) private _newTokenBids;

    // tokenID => owner => all bidders
    mapping(uint256 => mapping(address => address[])) private newTokenBidders;

    // -------------------

    fallback() external {}

    receive() external payable {}

    /**
     * @notice This method is used to Set Media Contract's Address
     *
     * @param _mediaContractAddress Address of the Media Contract to set
     */
    function configureMedia(address _mediaContractAddress) external {
        // TODO: Only Owner Modifier
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
        address _owner
    ) external override onlyMediaCaller returns (bool) {
        require(_bid._amount != 0, "Market: You Can't Bid With 0 Amount!");
        require(_bid._bidAmount != 0, "Market: You Can't Bid For 0 Tokens");
        require(!(_bid._bidAmount < 0), "Market: You Can't Bid For Negative Tokens");
        require(_bid._currency != address(0), 'Market: bid currency cannot be 0 address');
        require(_bid._recipient != address(0), 'Market: bid recipient cannot be 0 address');
        require(_tokenAsks[_tokenID]._currency != address(0), 'Token is not open for Sale');
        require(_bid._amount > _tokenAsks[_tokenID]._reserveAmount, 'Bid Cannot be placed below the reserve Amount');
        require(_bid._currency == _tokenAsks[_tokenID]._currency, 'Incorrect payment Method');

        // fetch existing bid, if there is any
        Iutils.Bid storage existingBid = _tokenBidders[_tokenID][_bidder];

        // Minus the Previous bid, if any, else 0
        userTotalBids[_bidder] = userTotalBids[_bidder].sub(_tokenBidders[_tokenID][_bid._bidder]._bidAmount);

        // If there is an existing bid, refund it before continuing
        if (existingBid._amount > 0) {
            removeBid(_tokenID, _bid._bidder);
        }

        IERC20 token = IERC20(_bid._currency);
        // We must check the balance that was actually transferred to the market,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in locked funds for refunds & bid acceptance
        uint256 beforeBalance = token.balanceOf(address(this));
        // TODO
        token.safeTransferFrom(_bidder, address(this), _bid._amount);
        uint256 afterBalance = token.balanceOf(address(this));

        // Set New Bid for the Token
        _tokenBidders[_tokenID][_bid._bidder] = Iutils.Bid(
            _bid._bidAmount,
            afterBalance.sub(beforeBalance),
            _bid._currency,
            _bid._bidder,
            _bid._recipient
        );

        // Add New bid
        userTotalBids[_bidder] = userTotalBids[_bidder].add(_bid._bidAmount);

        // Add Redeem points for the user
        userRedeemPoints[_bidder] = userRedeemPoints[_bidder].add(_bid._bidAmount);

        emit BidCreated(_tokenID, _bid);
        // Needs to be taken care of
        // // If a bid meets the criteria for an ask, automatically accept the bid.
        // // If no ask is set or the bid does not meet the requirements, ignore.
        if (
            _tokenAsks[_tokenID]._currency != address(0) &&
            _bid._currency == _tokenAsks[_tokenID]._currency &&
            _bid._amount >= _tokenAsks[_tokenID]._amount
        ) {
            // Finalize exchange
            divideMoney(_tokenID, _owner, _bid._amount);
        }
        return true;
    }

    // /**
    //  * @notice Sets the ask on a particular media. If the ask cannot be evenly split into the media's
    //  * bid shares, this reverts.
    //  */
    function setAsk(uint256 _tokenID, Iutils.Ask memory ask) public override onlyMediaCaller {
        _tokenAsks[_tokenID] = ask;
        emit AskCreated(_tokenID, ask);
    }

    /**
     * @dev See {IMarket}
     */
    function acceptBid(
        uint256 _tokenID,
        address _owner,
        address _bidder,
        uint256 _amount
    ) external override returns (bool) {
        require(
            _newTokenBids[_tokenID][_owner][_bidder]._bidAmount != 0,
            'Market: The Specified Bidder Has No bids For The Token!'
        );
        require(
            _newTokenBids[_tokenID][_owner][_bidder]._amount == _amount,
            'Market: The Bidder Has Not Bid For The Specified Amount Of Tokens!'
        );

        // Divide the points
        divideMoney(_tokenID, _owner, _newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        // Minus Bidder's Redeemable Points
        userRedeemPoints[_bidder] = userRedeemPoints[_bidder].sub(_newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        // Remove All The bids for the Token
        for (uint256 index; index < newTokenBidders[_tokenID][_owner].length; index++) {
            userTotalBids[newTokenBidders[_tokenID][_owner][index]] = userTotalBids[
                newTokenBidders[_tokenID][_owner][index]
            ].sub(_newTokenBids[_tokenID][_owner][newTokenBidders[_tokenID][_owner][index]]._bidAmount);
            delete _newTokenBids[_tokenID][_owner][newTokenBidders[_tokenID][_owner][index]];
        }

        // Remove All Bidders from the list
        // delete newTokenBidders[_tokenID][_owner];
        delete _tokenAsks[_tokenID];
        delete _tokenBidders[_tokenID][_bidder];

        emit AcceptBid(_tokenID, _owner, _amount, _bidder, _newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        return true;
    }

    function removeBid(uint256 _tokenID, address _bidder) public override onlyMediaCaller {
        Iutils.Bid storage bid = _tokenBidders[_tokenID][_bidder];
        uint256 bidAmount = bid._amount;
        address bidCurrency = bid._currency;

        require(bid._bidder == _bidder, 'Market: Only bidder can remove the bid');
        require(bid._amount > 0, 'Market: cannot remove bid amount of 0');

        IERC20 token = IERC20(bidCurrency);
        userTotalBids[_bidder] = userTotalBids[_bidder].sub(_tokenBidders[_tokenID][bid._bidder]._bidAmount);
        emit BidRemoved(_tokenID, bid);
        delete _tokenBidders[_tokenID][_bidder];
        token.safeTransfer(bid._bidder, bidAmount);
    }

    /**
     * @dev See {IMarket}
     */
    function cancelBid(
        uint256 _tokenID,
        address _bidder,
        address _owner
    ) external override onlyMediaCaller returns (bool) {
        // require(
        //     userTotalBids[_bidder] != 0,
        //     "Market: You Have Not Set Any Bid Yet!"
        // );
        // require(
        //     tokenBids[_tokenID][_bidder] != 0,
        //     "Market: You Have Not Bid For This Token."
        // );

        // // Minus from User's Total Bids
        // userTotalBids[_bidder] = userTotalBids[_bidder].sub(
        //     tokenBids[_tokenID][_bidder]
        // );

        // // Delete the User's Bid
        // delete tokenBids[_tokenID][_bidder];

        // // Remove Bidder from Token's Bidders' list
        // removeBidder(_tokenID, _bidder);

        // emit CancelBid(_tokenID, _bidder);

        // return true;

        // New Code -------------------
        require(userTotalBids[_bidder] != 0, 'Market: You Have Not Set Any Bid Yet!');
        require(_newTokenBids[_tokenID][_owner][_bidder]._bidAmount != 0, 'Market: You Have Not Bid For This Token.');

        // Minus from Bidder's Total Bids
        userTotalBids[_bidder] = userTotalBids[_bidder].sub(_newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        // Delete the User's Bid
        delete _newTokenBids[_tokenID][_owner][_bidder];

        // Remove Bidder from Token's Bidders' list
        removeBidder(_tokenID, _bidder, _owner);

        emit CancelBid(_tokenID, _bidder);

        return true;
    }

    /**
     * @dev This internal method is used to remove the Bidder's address who has canceled bid from Bidders' list, for the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to remove bidder of
     * @param _bidder Address of the Bidder to remove
     */
    function removeBidder(
        uint256 _tokenID,
        address _bidder,
        address _owner
    ) internal {
        for (uint256 index = 0; index < newTokenBidders[_tokenID][_owner].length; index++) {
            if (newTokenBidders[_tokenID][_owner][index] == _bidder) {
                newTokenBidders[_tokenID][_owner][index] = newTokenBidders[_tokenID][_owner][
                    newTokenBidders[_tokenID][_owner].length - 1
                ];
                newTokenBidders[_tokenID][_owner].pop();
                break;
            }
        }
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

    // TODO: To be removed
    function getMarketBalance() external view returns (uint256) {
        return payable(this).balance;
    }

    /**
     * @dev See {IMarket}
     */
    function divideMoney(
        uint256 _tokenID,
        address _owner,
        uint256 _amountToDivide
    ) public override returns (bool) {
        require(_amountToDivide > 0, "Market: Amount To Divide Can't Be 0!");

        // If no royalty points have been set, transfer the amount to the owner
        if (tokenRoyaltyPercentage[_tokenID] == 0) {
            userRedeemPoints[_owner] = userRedeemPoints[_owner].add(_amountToDivide);
            return true;
        }

        // Amount to divide among Collaborators
        uint256 royaltyPoints = _amountToDivide.mul(tokenRoyaltyPercentage[_tokenID]).div(100);

        Collaborators memory tokenColab = tokenCollaborators[_tokenID];

        uint256 amountToTransfer;
        uint256 totalAmountTransferred;

        for (uint256 index = 0; index < tokenColab._collaborators.length; index++) {
            // Individual Collaborator's share Amount
            amountToTransfer = royaltyPoints.mul(tokenColab._percentages[index]).div(100);

            // Total Amount Transferred
            totalAmountTransferred = totalAmountTransferred.add(amountToTransfer);

            // Add Collaborator's Redeem points
            userRedeemPoints[tokenColab._collaborators[index]] = userRedeemPoints[tokenColab._collaborators[index]].add(
                amountToTransfer
            );
        }

        // Add Remaining amount to Owner's redeem points
        userRedeemPoints[_owner] = userRedeemPoints[_owner].add(_amountToDivide.sub(royaltyPoints));

        totalAmountTransferred = totalAmountTransferred.add(_amountToDivide.sub(royaltyPoints));

        // Check for Transfer amount error
        require(totalAmountTransferred == _amountToDivide, 'Market: Amount Transfer Value Error!');

        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function addAdminCommission(uint256 _amount) external override onlyMediaCaller returns (bool) {
        _adminPoints = _adminPoints.add(_amount);
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function redeemPoints(address _userAddress, uint256 _amount) external override onlyMediaCaller returns (bool) {
        // Admin's points
        if (_userAddress == _adminAddress) {
            require(_adminPoints >= _amount, "Market: You Don't have that much points to redeem!");

            _adminPoints = _adminPoints.sub(_amount);
            payable(_adminAddress).transfer(_amount);
        } else {
            require(userRedeemPoints[_userAddress] >= _amount, "Market: You Don't Have That Much Points To Redeem!");
            require(
                (userRedeemPoints[_userAddress] - userTotalBids[_userAddress]) >= _amount,
                "Market: You Have Bids, You Can't Redeem That Much Points!"
            );

            payable(address(_userAddress)).transfer(_amount);
            userRedeemPoints[_userAddress] = userRedeemPoints[_userAddress].sub(_amount);
        }

        emit Redeem(_userAddress, _amount);
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function getUsersRedeemablePoints(address _userAddress) external view override onlyMediaCaller returns (uint256) {
        if (_userAddress == _adminAddress) {
            return _adminPoints;
        }
        return (userRedeemPoints[_userAddress] - userTotalBids[_userAddress]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './Iutils.sol';

interface IMarket {
    struct Collaborators {
        address[] _collaborators;
        uint8[] _percentages;
    }

    event BidCreated(uint256 indexed tokenID, Iutils.Bid bid);
    event BidRemoved(uint256 indexed tokenID, Iutils.Bid bid);
    event AskCreated(uint256 indexed tokenID, Iutils.Ask ask);
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
        address _owner
    ) external returns (bool);

    function removeBid(uint256 tokenId, address bidder) external;

    function setAsk(uint256 tokenId, Iutils.Ask calldata ask) external;

    /**
     * @notice this function is used to Accept Bid
     *
     * @param _tokenID TokenID of the Token
     * @param _owner Address of the Owner of the Token
     * @param _bidder Address of the Bidder
     * @param _amount Bid Amount
     *
     * @return bool Transaction status
     */
    function acceptBid(
        uint256 _tokenID,
        address _owner,
        address _bidder,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice This function is used to Cancel Bid
     * @dev This methos is also used to Reject Bid
     *
     * @param _tokenID Token ID of the Token to cancel bid for
     * @param _bidder Address of the Bidder to cancel bid of
     *
     * @return bool Transaction status
     */
    function cancelBid(
        uint256 _tokenID,
        address _bidder,
        address _owner
    ) external returns (bool);

    /**
     * @notice This method is used to Divide the selling amount among Owner, Creator and Collaborators
     *
     * @param _tokenID Token ID of the Token sold
     * @param _owner Address of the Owner of the Token
     * @param _amountToDivide Amount to divide -  Selling amount of the Token
     *
     * @return bool Transaction status
     */
    function divideMoney(
        uint256 _tokenID,
        address _owner,
        uint256 _amountToDivide
    ) external returns (bool);

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

    /**
     * @notice This method is used to Redeem Points
     *
     * @param _userAddress Address of the User to Redeem Points of
     * @param _amount Amount of points to redeem
     *
     * @return bool Transaction status
     */
    function redeemPoints(address _userAddress, uint256 _amount) external returns (bool);

    /**
     * @notice This method is used to get User's Redeemable Points
     *
     * @param _userAddress Address of the User to get Points of
     *
     * @return uint Redeemable Points
     */
    function getUsersRedeemablePoints(address _userAddress) external view returns (uint256);
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
    }
    struct Ask {
        uint256 _reserveAmount;
        // Amount of the currency being asked
        uint256 _askAmount;
        // Amount of the tokens being asked
        uint256 _amount;
        // Address to the ERC20 token being asked
        address _currency;
        // Type of ask
        AskTypes askType;
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