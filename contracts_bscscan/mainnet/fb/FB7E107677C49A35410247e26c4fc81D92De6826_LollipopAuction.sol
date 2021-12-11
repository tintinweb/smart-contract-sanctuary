/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract ERC20 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}

contract LollipopAuction
{
    //Constants
    uint256 ONE_HUNDRED = 100000000000000000000;
    //uint256 UINT256_NULL = type(uint256).max;
    uint public UINT_NULL = 999999999999;

    struct Auction 
    {
        address asset;
        uint256 amount;
        uint time_start;
        uint time_end;
        uint256 auction_starting_value;
        uint256 bid_next_increase_value;
        uint256 bid_current_price;
        uint bid_paid; //(0|1)
        uint bid_finished;
    }

    struct BID
    {
        address bidder;
        uint256 value;
    }

    //Auction owner address / Auction record
    mapping(address => Auction[]) auction_item;

    //Bidders list: auction owner address / bid index / BID
    mapping(address => mapping(uint => BID[])) bidders;

    //Auction owners
    address[] auction_owners_in_action;
    mapping(address => uint) auction_owners_in_action_index;
    mapping(address => uint) auction_owners_in_action_active;

    //Administrative parameters
    address public owner;
    address public feeTo;
    uint256 public newAuctionFeePercent;
    uint256 public postponeAuctionFeePercent;
    uint256 public winnerClaimFeePercent;
    address public bidToken;
    uint256 public bidPrice;
    uint public bid_default_time;
    uint256 public bid_default_increase_percent;
    uint public bidder_winer_time_to_pay_and_claim;

    //Events
    event OnAuctionRegister(address auction_owner, address asset, uint time_start, uint time_end, uint256 auction_starting_value, uint256 fee);
    event OnAuctionFinish(address auction_owner, address asset, uint time_start, uint time_end, uint256 auction_starting_value);
    event OnAuctionPostpone(address auction_owner, address asset, uint time_start, uint time_end, uint256 auction_starting_value, uint256 postponeFee);
    event OnWinnerBidClaim(address auction_owner, uint auctionIx, address winner, uint256 sellprice, uint256 fee);

    constructor() 
    {
        owner = msg.sender;
        feeTo = owner;
        bid_default_time = 259200;
        bid_default_increase_percent = 2000000000000000000; //2%
        newAuctionFeePercent = 2000000000000000000; //2%
        postponeAuctionFeePercent = 2000000000000000000; //2%
        winnerClaimFeePercent = 2000000000000000000; //2%
        bidToken = address(0xEA96DAA186C1fa0A709929822867Ec176Af8bafF); //LOLLIPOP
        bidPrice = 100000000000000000000; //100 units
        bidder_winer_time_to_pay_and_claim = 18000; //5 hours
    }

    function AuctionRegister(address _asset, uint256 _amount, uint256 _auction_starting_value) external payable
    {
        require(_auction_starting_value > 0, "ZRO");

        uint256 newBidFee = safeDiv(safeMul(_auction_starting_value, newAuctionFeePercent), ONE_HUNDRED);
        require(msg.value >= newBidFee, "LOW");

        //Send fee to fee to address
        payable(feeTo).transfer(msg.value);

        //Deposit Amount o Asset to this contract
        ERC20 assetTokenERC = ERC20(_asset);
        uint256 allowance = assetTokenERC.allowance(msg.sender, address(this));
        require(allowance >= _amount, "AL"); //Check the token allowance. Use approve function.
        assetTokenERC.transferFrom(msg.sender, address(this), _amount);

        uint time_start = block.timestamp;
        uint time_end = safeAdd(time_start, bid_default_time);


        //If is not a current auction owner, register it
        if(auction_owners_in_action_active[msg.sender] == 0)
        {
            auction_owners_in_action.push(msg.sender);
            auction_owners_in_action_index[msg.sender] = auction_owners_in_action.length -1;
            auction_owners_in_action_active[msg.sender] = 1;
        }

        auction_item[msg.sender].push(Auction({
            asset: _asset,
            amount: _amount,
            time_start: time_start,
            time_end: time_end,
            auction_starting_value: _auction_starting_value,
            bid_next_increase_value: safeAdd(_auction_starting_value, safeDiv(safeMul(_auction_starting_value, bid_default_increase_percent), ONE_HUNDRED)),
            bid_current_price: _auction_starting_value,
            bid_paid: 0,
            bid_finished: 0
        }));

        emit OnAuctionRegister(msg.sender, _asset, time_start, time_end, _auction_starting_value, msg.value);
    }

    function AuctionFinish(address _auction_owner, uint _bidIX) internal
    {
        auction_item[_auction_owner][_bidIX].bid_finished = 1;
        emit OnAuctionFinish(msg.sender, auction_item[_auction_owner][_bidIX].asset, auction_item[_auction_owner][_bidIX].time_start, auction_item[_auction_owner][_bidIX].time_end, auction_item[_auction_owner][_bidIX].auction_starting_value);
    }

    function getAuctionCount(address _auction_owner) external view returns (uint result) 
    {
        return auction_item[_auction_owner].length;
    }

    function getAuctionByIndex(address _auction_owner, uint _auction_ix) external view returns (Auction memory result) 
    {
        return auction_item[_auction_owner][_auction_ix];
    }

    function getAuctionOwnerIndex(address _auction_owner) external view returns (uint result)
    {
        if(auction_owners_in_action_active[_auction_owner] == 0)
        {
            return UINT_NULL;
        }

        return auction_owners_in_action_index[msg.sender];
    }

    function getAuctionOwnerCount() external view returns (uint result)
    {
        return auction_owners_in_action.length;
    }

    function getAuctionOwnerAddressByIndex(uint _index) external view returns (address result)
    {
        return auction_owners_in_action[_index];
    }

    function doBid(address _auction_owner, uint _bidIX) external returns (bool success)
    {
        require(auction_item[_auction_owner].length > _bidIX, "IX");
        require(auction_item[_auction_owner][_bidIX].time_end > block.timestamp, "ED");
        require(auction_item[_auction_owner][_bidIX].bid_finished == 0, "FN");
        require(bidders[_auction_owner][_bidIX].length < UINT_NULL, "MAX");

        //Pay BID Price        
        ERC20 bidTokenERC = ERC20(bidToken);
        uint256 allowance = bidTokenERC.allowance(msg.sender, address(this));
        require(allowance >= bidPrice, "AL"); //Check the token allowance. Use approve function.
        bidTokenERC.transferFrom(msg.sender, feeTo, bidPrice);

        //Set new BID
        auction_item[_auction_owner][_bidIX].bid_current_price = auction_item[_auction_owner][_bidIX].bid_next_increase_value;
        auction_item[_auction_owner][_bidIX].bid_next_increase_value = safeAdd(auction_item[_auction_owner][_bidIX].bid_current_price, safeDiv(safeMul(auction_item[_auction_owner][_bidIX].bid_current_price, bid_default_increase_percent), ONE_HUNDRED));
        bidders[_auction_owner][_bidIX].push(BID({
            bidder: msg.sender, 
            value: auction_item[_auction_owner][_bidIX].bid_current_price
        }));

        return true;
    }

    function getBidders(address _auction_owner, uint _bidIX) external view returns (BID[] memory result)
    {
        return bidders[_auction_owner][_bidIX];
    }

    function getTopBidder(address _auction_owner, uint _bidIX) public view returns (BID memory result)
    {
        if(bidders[_auction_owner][_bidIX].length > 0)
        {
            uint topIx = getTopBidderIx(_auction_owner, _bidIX);

            if(topIx != UINT_NULL)
            {
                return bidders[_auction_owner][_bidIX][topIx];
            }
        }

        BID memory emptyBID;
        return emptyBID;
    }

    function getTopBidderIx(address _auction_owner, uint _bidIX) public view returns(uint result)
    {
        if(bidders[_auction_owner][_bidIX].length > 0)
        {

            //If auction is not finished, it does not check pay/claim timeout
            if(auction_item[_auction_owner][_bidIX].time_end > block.timestamp)
            {
                return bidders[_auction_owner][_bidIX].length - 1;
            }

            uint topIx = UINT_NULL;
            uint ix = bidders[_auction_owner][_bidIX].length - 1;

            //uint256 topValue = 0;

            do
            {
                //Auction is finished, check pay/claim timeout
                uint isTimedOutForBidder = getBidderPayClaimIsTimedOut(_auction_owner, _bidIX, ix);

                //Set as Top Bidder if is not timed-out
                if(isTimedOutForBidder == 0)
                {
                    //topValue = bidders[_auction_owner][_bidIX][ix].value;
                    topIx = ix;
                    break;
                }

                if(ix == 0)
                {
                    break; //uint cannot be negative
                }

                ix--;
            }
            while(ix >= 0);

            return topIx;

        }

        return UINT_NULL;
    }

    function getBidderPayClaimIsTimedOut(address _auction_owner, uint _bidIX, uint _bidderIX) public view returns (uint result)
    {
        //Auction initialized check
        if(auction_item[_auction_owner].length <= _bidIX)
        {
            return 0;
        }

        //Auction is finished check
        if(auction_item[_auction_owner][_bidIX].bid_finished == 1)
        {
            return 1;
        }

        //Auction time finished check
        if(block.timestamp < auction_item[_auction_owner][_bidIX].time_end)
        {
            return 0;
        }

        //Bidders list is not empty
        if(bidders[_auction_owner][_bidIX].length == 0)
        {
            return 0;
        }

        //Index exists into bidders list
        if(bidders[_auction_owner][_bidIX].length <= _bidderIX)
        {
            return 0;
        }

        //Allowed time based on bid registration position (value = time_to_claim X top_position)
        uint valueToMultiplyForPosition = safeSub(bidders[_auction_owner][_bidIX].length, _bidderIX);
        uint allowedTimeAfterFinish = safeMul(bidder_winer_time_to_pay_and_claim, valueToMultiplyForPosition);
        uint maxTime = safeAdd(auction_item[_auction_owner][_bidIX].time_end, allowedTimeAfterFinish);

        //Check current time is greather than allowed time after finish to set as timed-out
        if(block.timestamp <= maxTime)
        {
            //Still has time
            return 0;
        }

        //Timed-out
        return 1;
    }

    function getWinnerBIDMaxTime(address _auction_owner, uint _bidIX, uint _bidderIX) public view returns (uint result)
    {
        //Auction is finished check
        if(block.timestamp > auction_item[_auction_owner][_bidIX].time_end)
        {
            //Bidders list is not empty
            if(bidders[_auction_owner][_bidIX].length > 0)
            {
                //Index exists into bidders list
                if(bidders[_auction_owner][_bidIX].length > _bidderIX)
                {
                    //Allowed time based on bid registration position (value = time_to_claim X top_position)
                    uint valueToMultiplyForPosition = safeSub(bidders[_auction_owner][_bidIX].length, _bidderIX);
                    uint allowedTimeAfterFinish = safeMul(bidder_winer_time_to_pay_and_claim, valueToMultiplyForPosition);
                    uint maxTime = safeAdd(auction_item[_auction_owner][_bidIX].time_end, allowedTimeAfterFinish);

                    return maxTime;
                }
            }
        }

        return 0;
    }

    function doWinnerBidderClaim(address _auction_owner, uint _bidIX, uint _bidderIX) external payable
    {
        BID memory topBidder = getTopBidder(_auction_owner, _bidIX); //Timeout will be also checked into getTopBidder

        require(topBidder.bidder == msg.sender, '500');  //Unauthorized
        require(auction_item[_auction_owner].length > _bidIX, "IX");
        require(bidders[_auction_owner][_bidIX][_bidderIX].bidder == topBidder.bidder && bidders[_auction_owner][_bidIX][_bidderIX].value == topBidder.value, '501');  //Unauthorized match with top bidder
        require(auction_item[_auction_owner][_bidIX].time_end > 0 && auction_item[_auction_owner][_bidIX].time_end <= block.timestamp, '423');  //Unfinished: Locked for claim
        require(auction_item[_auction_owner][_bidIX].bid_paid == 0, '410');  //Already paid
        require(auction_item[_auction_owner][_bidIX].bid_finished == 0, "FN");

        uint256 winnerClaimFee = safeDiv(safeMul(topBidder.value, winnerClaimFeePercent), ONE_HUNDRED);
        require(msg.value >= safeAdd(topBidder.value, winnerClaimFee), '402');  //Invalid payment value
        
        //Send fee to fee to address
        payable(feeTo).transfer(winnerClaimFee);

        //Send BID value to Auction owner
        payable(_auction_owner).transfer(topBidder.value);

        //Send BID amount to winner
        ERC20 assetTokenERC = ERC20(auction_item[_auction_owner][_bidIX].asset);
        assetTokenERC.transfer(msg.sender, auction_item[_auction_owner][_bidIX].amount);

        auction_item[_auction_owner][_bidIX].bid_paid = 1;

        emit OnWinnerBidClaim(_auction_owner, _bidIX, msg.sender, topBidder.value, winnerClaimFee);

        AuctionFinish(_auction_owner, _bidIX);
    }

    function doWithdrawalFromTimedoutUnclaimedAuction(ERC20 token, address _auction_owner, uint _bidIX) external
    {
        require(_auction_owner == msg.sender, '500');  //Unauthorized
        require(auction_item[_auction_owner].length > _bidIX, "IX");
        require(getTopBidderIx(_auction_owner, _bidIX) == UINT_NULL, 'HASBIDDER');
        require(auction_item[_auction_owner][_bidIX].time_end > 0 && auction_item[_auction_owner][_bidIX].time_end <= block.timestamp, '423');  //Unfinished: Locked for claim
        require(auction_item[_auction_owner][_bidIX].bid_paid == 0, '410');  //Already paid
        require(auction_item[_auction_owner][_bidIX].bid_finished == 0, "FN");
        require(auction_item[_auction_owner][_bidIX].asset == address(token), "AS");
        require(auction_item[_auction_owner][_bidIX].amount > 0, "AM");

        //Send BID amount back to owner
        token.transfer(msg.sender, auction_item[_auction_owner][_bidIX].amount);

        AuctionFinish(_auction_owner, _bidIX);
    }

    function doPostponeFromTimedoutUnclaimedAuction(address _auction_owner, uint _bidIX) external payable
    {
        require(_auction_owner == msg.sender, '500');  //Unauthorized
        require(auction_item[_auction_owner].length > _bidIX, "IX");
        require(getTopBidderIx(_auction_owner, _bidIX) == UINT_NULL, 'HASBIDDER');
        require(auction_item[_auction_owner][_bidIX].time_end > 0 && auction_item[_auction_owner][_bidIX].time_end <= block.timestamp, '423');  //Unfinished: Locked for postpone
        require(auction_item[_auction_owner][_bidIX].bid_paid == 0, '410');  //Already paid
        require(auction_item[_auction_owner][_bidIX].bid_finished == 0, "FN");

        uint256 postponeFee = safeDiv(safeMul(auction_item[_auction_owner][_bidIX].auction_starting_value, postponeAuctionFeePercent), ONE_HUNDRED);
        require(msg.value >= postponeFee, "LOW");

        //Send fee to fee to address
        payable(feeTo).transfer(msg.value);

        //Set new end date
        uint time_end = safeAdd(block.timestamp, bid_default_time);
        auction_item[_auction_owner][_bidIX].time_end = time_end;

        emit OnAuctionPostpone(_auction_owner, auction_item[_auction_owner][_bidIX].asset, auction_item[_auction_owner][_bidIX].time_start, time_end, auction_item[_auction_owner][_bidIX].auction_starting_value, postponeFee);
    }

    function transferFund(ERC20 token, address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        token.transfer(to, amountInWei);
    }

    function setOwner(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        owner = newValue;
        return true;
    }

    function setFeeTo(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        feeTo = newValue;
        return true;
    }    

    function setNewAuctionFeePercent(uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        newAuctionFeePercent = newValue;
        return true;
    }

    function setPostponeAuctionFeePercent(uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        postponeAuctionFeePercent = newValue;
        return true;
    }

    function setWinnerClaimFeePercent(uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        winnerClaimFeePercent = newValue;
        return true;
    }

    function setBidToken(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        bidToken = newValue;
        return true;
    }

    function setBidPrice(uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        bidPrice = newValue;
        return true;
    }

    function setBidDefaultTime(uint newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        bid_default_time = newValue;
        return true;
    }

    function setBidDefaultIncreasePercent(uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        bid_default_increase_percent = newValue;
        return true;
    }

    function setBidWinnerTimeToPayAndClaim(uint newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        bidder_winer_time_to_pay_and_claim = newValue;
        return true;
    }

    //Safe Math Functions
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "OADD"); //STAKE: SafeMath: addition overflow

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeSub(a, b, "OSUB"); //STAKE: subtraction overflow
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "OMUL"); //STAKE: multiplication overflow

        return c;
    }

    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = safeDiv(safeMul(a, b), safePow(10, uint256(decimals)));

        return result;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {

        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  safeDiv(e, 2));
            p = safeMul(p, p);

            if (safeMod(e, 2) == 1) 
            {
                p = safeMul(p, n);
            }

            return p;
        }
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeDiv(a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeDiv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeMod(a, b, "ZMOD"); //STAKE: modulo by zero
    }

    function safeMod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}