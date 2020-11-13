// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./NuCypherToken.sol";
import "./StakingEscrow.sol";
import "./AdditionalMath.sol";


/**
* @notice The WorkLock distribution contract
*/
contract WorkLock is Ownable {
    using SafeERC20 for NuCypherToken;
    using SafeMath for uint256;
    using AdditionalMath for uint256;
    using Address for address payable;
    using Address for address;

    event Deposited(address indexed sender, uint256 value);
    event Bid(address indexed sender, uint256 depositedETH);
    event Claimed(address indexed sender, uint256 claimedTokens);
    event Refund(address indexed sender, uint256 refundETH, uint256 completedWork);
    event Canceled(address indexed sender, uint256 value);
    event BiddersChecked(address indexed sender, uint256 startIndex, uint256 endIndex);
    event ForceRefund(address indexed sender, address indexed bidder, uint256 refundETH);
    event CompensationWithdrawn(address indexed sender, uint256 value);
    event Shutdown(address indexed sender);

    struct WorkInfo {
        uint256 depositedETH;
        uint256 completedWork;
        bool claimed;
        uint128 index;
    }

    uint16 public constant SLOWING_REFUND = 100;
    uint256 private constant MAX_ETH_SUPPLY = 2e10 ether;

    NuCypherToken public immutable token;
    StakingEscrow public immutable escrow;

    /*
    * @dev WorkLock calculations:
    * bid = minBid + bonusETHPart
    * bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens
    * bonusDepositRate = bonusTokenSupply / bonusETHSupply
    * claimedTokens = minAllowableLockedTokens + bonusETHPart * bonusDepositRate
    * bonusRefundRate = bonusDepositRate * SLOWING_REFUND / boostingRefund
    * refundETH = completedWork / refundRate
    */
    uint256 public immutable boostingRefund;
    uint256 public immutable minAllowedBid;
    uint16 public immutable stakingPeriods;
    // copy from the escrow contract
    uint256 public immutable maxAllowableLockedTokens;
    uint256 public immutable minAllowableLockedTokens;

    uint256 public tokenSupply;
    uint256 public startBidDate;
    uint256 public endBidDate;
    uint256 public endCancellationDate;

    uint256 public bonusETHSupply;
    mapping(address => WorkInfo) public workInfo;
    mapping(address => uint256) public compensation;

    address[] public bidders;
    // if value == bidders.length then WorkLock is fully checked
    uint256 public nextBidderToCheck;

    /**
    * @dev Checks timestamp regarding cancellation window
    */
    modifier afterCancellationWindow()
    {
        require(block.timestamp >= endCancellationDate,
            "Operation is allowed when cancellation phase is over");
        _;
    }

    /**
    * @param _token Token contract
    * @param _escrow Escrow contract
    * @param _startBidDate Timestamp when bidding starts
    * @param _endBidDate Timestamp when bidding will end
    * @param _endCancellationDate Timestamp when cancellation will ends
    * @param _boostingRefund Coefficient to boost refund ETH
    * @param _stakingPeriods Amount of periods during which tokens will be locked after claiming
    * @param _minAllowedBid Minimum allowed ETH amount for bidding
    */
    constructor(
        NuCypherToken _token,
        StakingEscrow _escrow,
        uint256 _startBidDate,
        uint256 _endBidDate,
        uint256 _endCancellationDate,
        uint256 _boostingRefund,
        uint16 _stakingPeriods,
        uint256 _minAllowedBid
    ) {
        uint256 totalSupply = _token.totalSupply();
        require(totalSupply > 0 &&                              // token contract is deployed and accessible
            _escrow.secondsPerPeriod() > 0 &&                   // escrow contract is deployed and accessible
            _escrow.token() == _token &&                        // same token address for worklock and escrow
            _endBidDate > _startBidDate &&                      // bidding period lasts some time
            _endBidDate > block.timestamp &&                    // there is time to make a bid
            _endCancellationDate >= _endBidDate &&              // cancellation window includes bidding
            _minAllowedBid > 0 &&                               // min allowed bid was set
            _boostingRefund > 0 &&                              // boosting coefficient was set
            _stakingPeriods >= _escrow.minLockedPeriods());     // staking duration is consistent with escrow contract
        // worst case for `ethToWork()` and `workToETH()`,
        // when ethSupply == MAX_ETH_SUPPLY and tokenSupply == totalSupply
        require(MAX_ETH_SUPPLY * totalSupply * SLOWING_REFUND / MAX_ETH_SUPPLY / totalSupply == SLOWING_REFUND &&
            MAX_ETH_SUPPLY * totalSupply * _boostingRefund / MAX_ETH_SUPPLY / totalSupply == _boostingRefund);

        token = _token;
        escrow = _escrow;
        startBidDate = _startBidDate;
        endBidDate = _endBidDate;
        endCancellationDate = _endCancellationDate;
        boostingRefund = _boostingRefund;
        stakingPeriods = _stakingPeriods;
        minAllowedBid = _minAllowedBid;
        maxAllowableLockedTokens = _escrow.maxAllowableLockedTokens();
        minAllowableLockedTokens = _escrow.minAllowableLockedTokens();
    }

    /**
    * @notice Deposit tokens to contract
    * @param _value Amount of tokens to transfer
    */
    function tokenDeposit(uint256 _value) external {
        require(block.timestamp < endBidDate, "Can't deposit more tokens after end of bidding");
        token.safeTransferFrom(msg.sender, address(this), _value);
        tokenSupply += _value;
        emit Deposited(msg.sender, _value);
    }

    /**
    * @notice Calculate amount of tokens that will be get for specified amount of ETH
    * @dev This value will be fixed only after end of bidding
    */
    function ethToTokens(uint256 _ethAmount) public view returns (uint256) {
        if (_ethAmount < minAllowedBid) {
            return 0;
        }

        // when all participants bid with the same minimum amount of eth
        if (bonusETHSupply == 0) {
            return tokenSupply / bidders.length;
        }

        uint256 bonusETH = _ethAmount - minAllowedBid;
        uint256 bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens;
        return minAllowableLockedTokens + bonusETH.mul(bonusTokenSupply).div(bonusETHSupply);
    }

    /**
    * @notice Calculate amount of work that need to be done to refund specified amount of ETH
    */
    function ethToWork(uint256 _ethAmount, uint256 _tokenSupply, uint256 _ethSupply)
        internal view returns (uint256)
    {
        return _ethAmount.mul(_tokenSupply).mul(SLOWING_REFUND).divCeil(_ethSupply.mul(boostingRefund));
    }

    /**
    * @notice Calculate amount of work that need to be done to refund specified amount of ETH
    * @dev This value will be fixed only after end of bidding
    * @param _ethToReclaim Specified sum of ETH staker wishes to reclaim following completion of work
    * @param _restOfDepositedETH Remaining ETH in staker's deposit once ethToReclaim sum has been subtracted
    * @dev _ethToReclaim + _restOfDepositedETH = depositedETH
    */
    function ethToWork(uint256 _ethToReclaim, uint256 _restOfDepositedETH) internal view returns (uint256) {

        uint256 baseETHSupply = bidders.length * minAllowedBid;
        // when all participants bid with the same minimum amount of eth
        if (bonusETHSupply == 0) {
            return ethToWork(_ethToReclaim, tokenSupply, baseETHSupply);
        }

        uint256 baseETH = 0;
        uint256 bonusETH = 0;

        // If the staker's total remaining deposit (including the specified sum of ETH to reclaim)
        // is lower than the minimum bid size,
        // then only the base part is used to calculate the work required to reclaim ETH
        if (_ethToReclaim + _restOfDepositedETH <= minAllowedBid) {
            baseETH = _ethToReclaim;

        // If the staker's remaining deposit (not including the specified sum of ETH to reclaim)
        // is still greater than the minimum bid size,
        // then only the bonus part is used to calculate the work required to reclaim ETH
        } else if (_restOfDepositedETH >= minAllowedBid) {
            bonusETH = _ethToReclaim;

        // If the staker's remaining deposit (not including the specified sum of ETH to reclaim)
        // is lower than the minimum bid size,
        // then both the base and bonus parts must be used to calculate the work required to reclaim ETH
        } else {
            bonusETH = _ethToReclaim + _restOfDepositedETH - minAllowedBid;
            baseETH = _ethToReclaim - bonusETH;
        }

        uint256 baseTokenSupply = bidders.length * minAllowableLockedTokens;
        uint256 work = 0;
        if (baseETH > 0) {
            work = ethToWork(baseETH, baseTokenSupply, baseETHSupply);
        }

        if (bonusETH > 0) {
            uint256 bonusTokenSupply = tokenSupply - baseTokenSupply;
            work += ethToWork(bonusETH, bonusTokenSupply, bonusETHSupply);
        }

        return work;
    }

    /**
    * @notice Calculate amount of work that need to be done to refund specified amount of ETH
    * @dev This value will be fixed only after end of bidding
    */
    function ethToWork(uint256 _ethAmount) public view returns (uint256) {
        return ethToWork(_ethAmount, 0);
    }

    /**
    * @notice Calculate amount of ETH that will be refund for completing specified amount of work
    */
    function workToETH(uint256 _completedWork, uint256 _ethSupply, uint256 _tokenSupply)
        internal view returns (uint256)
    {
        return _completedWork.mul(_ethSupply).mul(boostingRefund).div(_tokenSupply.mul(SLOWING_REFUND));
    }

    /**
    * @notice Calculate amount of ETH that will be refund for completing specified amount of work
    * @dev This value will be fixed only after end of bidding
    */
    function workToETH(uint256 _completedWork, uint256 _depositedETH) public view returns (uint256) {
        uint256 baseETHSupply = bidders.length * minAllowedBid;
        // when all participants bid with the same minimum amount of eth
        if (bonusETHSupply == 0) {
            return workToETH(_completedWork, baseETHSupply, tokenSupply);
        }

        uint256 bonusWork = 0;
        uint256 bonusETH = 0;
        uint256 baseTokenSupply = bidders.length * minAllowableLockedTokens;

        if (_depositedETH > minAllowedBid) {
            bonusETH = _depositedETH - minAllowedBid;
            uint256 bonusTokenSupply = tokenSupply - baseTokenSupply;
            bonusWork = ethToWork(bonusETH, bonusTokenSupply, bonusETHSupply);

            if (_completedWork <= bonusWork) {
                return workToETH(_completedWork, bonusETHSupply, bonusTokenSupply);
            }
        }

        _completedWork -= bonusWork;
        return bonusETH + workToETH(_completedWork, baseETHSupply, baseTokenSupply);
    }

    /**
    * @notice Get remaining work to full refund
    */
    function getRemainingWork(address _bidder) external view returns (uint256) {
        WorkInfo storage info = workInfo[_bidder];
        uint256 completedWork = escrow.getCompletedWork(_bidder).sub(info.completedWork);
        uint256 remainingWork = ethToWork(info.depositedETH);
        if (remainingWork <= completedWork) {
            return 0;
        }
        return remainingWork - completedWork;
    }

    /**
    * @notice Get length of bidders array
    */
    function getBiddersLength() external view returns (uint256) {
        return bidders.length;
    }

    /**
    * @notice Bid for tokens by transferring ETH
    */
    function bid() external payable {
        require(block.timestamp >= startBidDate, "Bidding is not open yet");
        require(block.timestamp < endBidDate, "Bidding is already finished");
        WorkInfo storage info = workInfo[msg.sender];

        // first bid
        if (info.depositedETH == 0) {
            require(msg.value >= minAllowedBid, "Bid must be at least minimum");
            require(bidders.length < tokenSupply / minAllowableLockedTokens, "Not enough tokens for more bidders");
            info.index = uint128(bidders.length);
            bidders.push(msg.sender);
            bonusETHSupply = bonusETHSupply.add(msg.value - minAllowedBid);
        } else {
            bonusETHSupply = bonusETHSupply.add(msg.value);
        }

        info.depositedETH = info.depositedETH.add(msg.value);
        emit Bid(msg.sender, msg.value);
    }

    /**
    * @notice Cancel bid and refund deposited ETH
    */
    function cancelBid() external {
        require(block.timestamp < endCancellationDate,
            "Cancellation allowed only during cancellation window");
        WorkInfo storage info = workInfo[msg.sender];
        require(info.depositedETH > 0, "No bid to cancel");
        require(!info.claimed, "Tokens are already claimed");
        uint256 refundETH = info.depositedETH;
        info.depositedETH = 0;

        // remove from bidders array, move last bidder to the empty place
        uint256 lastIndex = bidders.length - 1;
        if (info.index != lastIndex) {
            address lastBidder = bidders[lastIndex];
            bidders[info.index] = lastBidder;
            workInfo[lastBidder].index = info.index;
        }
        bidders.pop();

        if (refundETH > minAllowedBid) {
            bonusETHSupply = bonusETHSupply.sub(refundETH - minAllowedBid);
        }
        msg.sender.sendValue(refundETH);
        emit Canceled(msg.sender, refundETH);
    }

    /**
    * @notice Cancels distribution, makes possible to retrieve all bids and owner gets all tokens
    */
    function shutdown() external onlyOwner {
        require(!isClaimingAvailable(), "Claiming has already been enabled");
        internalShutdown();
    }

    /**
    * @notice Cancels distribution, makes possible to retrieve all bids and owner gets all tokens
    */
    function internalShutdown() internal {
        startBidDate = 0;
        endBidDate = 0;
        endCancellationDate = uint256(0) - 1; // "infinite" cancellation window
        token.safeTransfer(owner(), tokenSupply);
        emit Shutdown(msg.sender);
    }

    /**
    * @notice Make force refund to bidders who can get tokens more than maximum allowed
    * @param _biddersForRefund Sorted list of unique bidders. Only bidders who must receive a refund
    */
    function forceRefund(address payable[] calldata _biddersForRefund) external afterCancellationWindow {
        require(nextBidderToCheck != bidders.length, "Bidders have already been checked");

        uint256 length = _biddersForRefund.length;
        require(length > 0, "Must be at least one bidder for a refund");

        uint256 minNumberOfBidders = tokenSupply.divCeil(maxAllowableLockedTokens);
        if (bidders.length < minNumberOfBidders) {
            internalShutdown();
            return;
        }

        address previousBidder = _biddersForRefund[0];
        uint256 minBid = workInfo[previousBidder].depositedETH;
        uint256 maxBid = minBid;

        // get minimum and maximum bids
        for (uint256 i = 1; i < length; i++) {
            address bidder = _biddersForRefund[i];
            uint256 depositedETH = workInfo[bidder].depositedETH;
            require(bidder > previousBidder && depositedETH > 0, "Addresses must be an array of unique bidders");
            if (minBid > depositedETH) {
                minBid = depositedETH;
            } else if (maxBid < depositedETH) {
                maxBid = depositedETH;
            }
            previousBidder = bidder;
        }

        uint256[] memory refunds = new uint256[](length);
        // first step - align at a minimum bid
        if (minBid != maxBid) {
            for (uint256 i = 0; i < length; i++) {
                address bidder = _biddersForRefund[i];
                WorkInfo storage info = workInfo[bidder];
                if (info.depositedETH > minBid) {
                    refunds[i] = info.depositedETH - minBid;
                    info.depositedETH = minBid;
                    bonusETHSupply -= refunds[i];
                }
            }
        }

        require(ethToTokens(minBid) > maxAllowableLockedTokens,
            "At least one of bidders has allowable bid");

        // final bids adjustment (only for bonus part)
        // (min_whale_bid * token_supply - max_stake * eth_supply) / (token_supply - max_stake * n_whales)
        uint256 maxBonusTokens = maxAllowableLockedTokens - minAllowableLockedTokens;
        uint256 minBonusETH = minBid - minAllowedBid;
        uint256 bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens;
        uint256 refundETH = minBonusETH.mul(bonusTokenSupply)
                                .sub(maxBonusTokens.mul(bonusETHSupply))
                                .divCeil(bonusTokenSupply - maxBonusTokens.mul(length));
        uint256 resultBid = minBid.sub(refundETH);
        bonusETHSupply -= length * refundETH;
        for (uint256 i = 0; i < length; i++) {
            address bidder = _biddersForRefund[i];
            WorkInfo storage info = workInfo[bidder];
            refunds[i] += refundETH;
            info.depositedETH = resultBid;
        }

        // reset verification
        nextBidderToCheck = 0;

        // save a refund
        for (uint256 i = 0; i < length; i++) {
            address bidder = _biddersForRefund[i];
            compensation[bidder] += refunds[i];
            emit ForceRefund(msg.sender, bidder, refunds[i]);
        }

    }

    /**
    * @notice Withdraw compensation after force refund
    */
    function withdrawCompensation() external {
        uint256 refund = compensation[msg.sender];
        require(refund > 0, "There is no compensation");
        compensation[msg.sender] = 0;
        msg.sender.sendValue(refund);
        emit CompensationWithdrawn(msg.sender, refund);
    }

    /**
    * @notice Check that the claimed tokens are within `maxAllowableLockedTokens` for all participants,
    * starting from the last point `nextBidderToCheck`
    * @dev Method stops working when the remaining gas is less than `_gasToSaveState`
    * and saves the state in `nextBidderToCheck`.
    * If all bidders have been checked then `nextBidderToCheck` will be equal to the length of the bidders array
    */
    function verifyBiddingCorrectness(uint256 _gasToSaveState) external afterCancellationWindow returns (uint256) {
        require(nextBidderToCheck != bidders.length, "Bidders have already been checked");

        // all participants bid with the same minimum amount of eth
        uint256 index = nextBidderToCheck;
        if (bonusETHSupply == 0) {
            require(tokenSupply / bidders.length <= maxAllowableLockedTokens, "Not enough bidders");
            index = bidders.length;
        }

        uint256 maxBonusTokens = maxAllowableLockedTokens - minAllowableLockedTokens;
        uint256 bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens;
        uint256 maxBidFromMaxStake = minAllowedBid + maxBonusTokens.mul(bonusETHSupply).div(bonusTokenSupply);


        while (index < bidders.length && gasleft() > _gasToSaveState) {
            address bidder = bidders[index];
            require(workInfo[bidder].depositedETH <= maxBidFromMaxStake, "Bid is greater than max allowable bid");
            index++;
        }

        if (index != nextBidderToCheck) {
            emit BiddersChecked(msg.sender, nextBidderToCheck, index);
            nextBidderToCheck = index;
        }
        return nextBidderToCheck;
    }

    /**
    * @notice Checks if claiming available
    */
    function isClaimingAvailable() public view returns (bool) {
        return block.timestamp >= endCancellationDate &&
            nextBidderToCheck == bidders.length;
    }

    /**
    * @notice Claimed tokens will be deposited and locked as stake in the StakingEscrow contract.
    */
    function claim() external returns (uint256 claimedTokens) {
        require(isClaimingAvailable(), "Claiming has not been enabled yet");
        WorkInfo storage info = workInfo[msg.sender];
        require(!info.claimed, "Tokens are already claimed");
        claimedTokens = ethToTokens(info.depositedETH);
        require(claimedTokens > 0, "Nothing to claim");

        info.claimed = true;
        token.approve(address(escrow), claimedTokens);
        escrow.depositFromWorkLock(msg.sender, claimedTokens, stakingPeriods);
        info.completedWork = escrow.setWorkMeasurement(msg.sender, true);
        emit Claimed(msg.sender, claimedTokens);
    }

    /**
    * @notice Get available refund for bidder
    */
    function getAvailableRefund(address _bidder) public view returns (uint256) {
        WorkInfo storage info = workInfo[_bidder];
        // nothing to refund
        if (info.depositedETH == 0) {
            return 0;
        }

        uint256 currentWork = escrow.getCompletedWork(_bidder);
        uint256 completedWork = currentWork.sub(info.completedWork);
        // no work that has been completed since last refund
        if (completedWork == 0) {
            return 0;
        }

        uint256 refundETH = workToETH(completedWork, info.depositedETH);
        if (refundETH > info.depositedETH) {
            refundETH = info.depositedETH;
        }
        return refundETH;
    }

    /**
    * @notice Refund ETH for the completed work
    */
    function refund() external returns (uint256 refundETH) {
        WorkInfo storage info = workInfo[msg.sender];
        require(info.claimed, "Tokens must be claimed before refund");
        refundETH = getAvailableRefund(msg.sender);
        require(refundETH > 0, "Nothing to refund: there is no ETH to refund or no completed work");

        if (refundETH == info.depositedETH) {
            escrow.setWorkMeasurement(msg.sender, false);
        }
        info.depositedETH = info.depositedETH.sub(refundETH);
        // convert refund back to work to eliminate potential rounding errors
        uint256 completedWork = ethToWork(refundETH, info.depositedETH);

        info.completedWork = info.completedWork.add(completedWork);
        emit Refund(msg.sender, refundETH, completedWork);
        msg.sender.sendValue(refundETH);
    }
}
