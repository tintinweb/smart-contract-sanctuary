// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(uint256 _pid, address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(uint256 _pid, address account);

    mapping(uint256 => bool) private _paused;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(uint256 _pid) public view virtual returns (bool) {
        return _paused[_pid];
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused(uint256 _pid) {
        require(!paused(_pid), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused(uint256 _pid) {
        require(paused(_pid), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause(uint256 _pid) internal virtual whenNotPaused(_pid) {
        _paused[_pid] = true;
        emit Paused(_pid, _msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause(uint256 _pid) internal virtual whenPaused(_pid) {
        _paused[_pid] = false;
        emit Unpaused(_pid, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './libraries/SafeBEP20.sol';
import "./Pausable.sol";
import './interfaces/IPrice.sol';
import './interfaces/IRandom.sol';
import "./interfaces/IAchievement.sol";
import "./interfaces/IPrediction.sol";

contract Prediction is IPrediction, Ownable, Pausable {
    using SafeBEP20 for IBEP20;
    
    /**
     * @dev 100%
     */
    uint256 public oneRatio = 1e6;

    /**
     * @dev 1% total pot paid to the system as revenue
     */
    uint256 public feeRatio = 1e4;

    /**
     * @dev Allowed delay time when getting price in seconds after round expiration.
     */
    uint256 public bufferTimestampPrice=600;

    /**
     * @dev Allowed delay time when getting randomness in seconds after round expiration.
     */
    uint256 public bufferTimestampRandomness=900;
    
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(uint256 => Round)) public override rounds;
    mapping(uint256 => mapping(uint256 => Specification)) public specifications;
    mapping(uint256 => uint256) public currentEpoch;
    mapping(uint256 => bool) public genesisStartOnce;
    uint256 public poolLength;
    
    mapping(address => mapping(uint256 => mapping(uint256 => Bought[]))) public boughts;
    mapping(uint256 => mapping(uint256 => uint256)) private lotteryNumbers;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => address))) public lotteryNumberOwner;
    mapping(uint256 => bool) public isEndRound;
    IBEP20 public override tokenReward;
    IBEP20 public perry;
    IPrice public priceService;
    IRandom public randomService;
    IAchievement public achievementService;
    uint256 public lotteryRatio;
    uint256 public improvementDelta; 
    
    mapping(address => address) public referral;
    mapping(address => uint256) public slippagePrice;
    
    uint256 public treasuryAmount;
    
    /**
     * @dev wallet address of operator, who was allowed create and close pool
     */
    address public operatorAddress;
    
    /**
     * @dev Only called when this pool is existed
     * @param _pid id of pool
     */
    modifier poolExisted(uint256 _pid) {
        require(_pid < poolLength, "PREDICTION: Pool not existed");
        _;
    }
    
    /**
     * @dev Only called by owner or operator
     */
    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operatorAddress, "PREDICTION: Only call by Owner or Operator");
        _;
    }
    
    /**
     * @dev Only called by operator
     */
    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "PREDICTION: Only call by Operator");
        _;
    }
    
    /**
     * @dev Only called by Randomize contract
     */
    modifier onlyRandomService() {
        require(
            msg.sender == address(randomService)
        );
        _;
    }
    
    /**
     * @param _tokenReward Reward token address
     * @param _perry PERRY token address
     * @param _operator Wallet address is allowed to create and close pool
     * @param _lotteryRatio Lottery ratio (real value * 1e6)
     * @param _improvementDelta Improvement delta for ticket price
     */
    constructor(
        address _tokenReward,
        address _perry,
        address _operator, 
        uint256 _lotteryRatio, 
        uint256 _improvementDelta
    ) {
        require(_lotteryRatio < oneRatio, "PREDICTION: lotteryRatio need to be less than 100%");
        tokenReward = IBEP20(_tokenReward);
        perry = IBEP20(_perry);
        operatorAddress = _operator; 
        lotteryRatio = _lotteryRatio;
        improvementDelta = _improvementDelta;
        poolLength = 0;
    }
    
    /**
     * @dev Update wallet address of Randomize contract, only by Owner
     * @param _random New randomize contract address
     */
    function setRandomService(address _random) public onlyOwner {
        emit UpdatedRandomService(address(randomService), _random);
        randomService = IRandom(_random);
    }
    
    /**
     * @dev Update wallet address of Price contract, only by Owner
     * @param _price New price contract address
     */
    function setPriceService(address _price) public onlyOwner {
        emit UpdatedPriceService(address(priceService), _price);
        priceService = IPrice(_price);
    }

    function setAchievementService(address _achievement) public onlyOwner {
        emit UpdatedAchievementService(address(achievementService), _achievement);
        achievementService = IAchievement(_achievement);
    }

    function setBufferTimestamp(uint256 _bufferPrice, uint256 _bufferRandom) public onlyOwner {
        require(_bufferPrice < _bufferRandom);
        bufferTimestampPrice = _bufferPrice;
        bufferTimestampRandomness = _bufferRandom;
        emit UpdateBufferTime(_bufferPrice, _bufferRandom);
    }
    
    /**
     * @dev Update lottery ratio, only by Owner
     * @param _lotteryRatio New lottery ratio token address
     */
    function setLotteryRatio(uint256 _lotteryRatio) public onlyOwner {
        require(_lotteryRatio <= 3e5, "PREDICTION: lotteryRatio  need to be less than 30%");
        emit UpdatedLotteryRatio(lotteryRatio, _lotteryRatio);
        lotteryRatio = _lotteryRatio;
    }
    
    /**
     * @dev Update operator address, only by Owner
     * @param _operator Wallet address of new operator
     */
    function setOperator(address _operator) public onlyOwner {
        emit UpdatedOperator(operatorAddress, _operator);
        operatorAddress = _operator; 
    }
    
    /**
     * @dev called by the admin to pause, triggers stopped state
     */
    function pause(uint256 _pid) public onlyOwner whenNotPaused(_pid) {
        _pause(_pid);
    }
    
    /**
     * @dev called by the Owner to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause(uint256 _pid) public onlyOwner whenPaused(_pid) {
        genesisStartOnce[_pid] = false;
        _unpause(_pid);
    }

    function setEndRound(uint256 _pid, bool _isEnd) public onlyOwner {
        isEndRound[_pid] = _isEnd;
    }
    
    /**
     * @dev Create new pool
     * @param _path Contract address of price feeds (https://docs.chain.link/docs/reference-contracts) or exchange path
     * @param _betTime Bet time of this pool in seconds
     * @param _ticketPrice Price of a ticket starts
     * @param _strikePrice Stricke Price of pool, enter 0 if you want to fetch from oracle
     * @param _initTicketNumber Number of tickets of each type to be initialized
     */
    function genesisPool(
        address[] memory _path,
        uint256 _betTime,
        uint256 _ticketPrice,
        uint256 _ticketFee,
        uint256 _strikePrice,
        uint8 _initTicketNumber
    ) public onlyOwner {
        require(_initTicketNumber > 0);
        
        (, uint8 decimals, string memory description) = priceService.getLastPrice(_path);
        Pool storage pool = pools[poolLength];
        pool.path = _path;
        pool.description = description;
        pool.priceDecimals = decimals;
        pool.betTime = _betTime;
        pool.ticketPriceStart = _ticketPrice;
        pool.ticketFeeStart = _ticketFee;
        pool.strikePrice = _strikePrice;
        pool.ticketNumberInit = _initTicketNumber;
        emit NewPool(poolLength, msg.sender);
        poolLength++;
    }
    
    /**
     * @dev Start genesis round
     */
    function genesisStartRound(uint256 _pid) external poolExisted(_pid) onlyOwner whenNotPaused(_pid) {
        require(!genesisStartOnce[_pid]);
        
        uint256 price;
        if (pools[_pid].strikePrice != 0) {
            price = pools[_pid].strikePrice;
        } else {
            (int256 _price, , ) = priceService.getLastPrice(pools[_pid].path);
            price = uint256(_price);
        }
        
        currentEpoch[_pid] = currentEpoch[_pid] + 1;
        _startRound(_pid, currentEpoch[_pid], price);
        
        genesisStartOnce[_pid] = true;
    }
    
    /**
     * @dev Lock genesis round
     * @param _pid id of pool
     */
    function genesisLockRound(uint256 _pid) external poolExisted(_pid) onlyOwnerOrOperator whenNotPaused(_pid) {
        (int256 _price, , ) = priceService.getLastPrice(pools[_pid].path);
        _safeLockRound(_pid, currentEpoch[_pid], uint256(_price));
        _pause(_pid);
    }
    
    /**
     * @dev Allow admin can deposit additional reward
     * @param _pid id of pool
     * @param _amount Amount of token reward
     */
    function depositReward(uint256 _pid, uint256 _amount) external poolExisted(_pid) onlyOwner whenNotPaused(_pid) {
        uint256 _epoch = currentEpoch[_pid];
        require(bettable(_pid, _epoch));
        Specification storage specification = specifications[_pid][_epoch];
        specification.additionalReward += _amount;
        tokenReward.safeTransferFrom(msg.sender, address(this), _amount);
    }
    
    /**
     * @dev Start the next round n, lock round n-1 for request oracle
     * @param _pid id of pool
     */
    function executeRound(uint256 _pid) external poolExisted(_pid) onlyOwnerOrOperator whenNotPaused(_pid) {
        require(
            genesisStartOnce[_pid]
        );
        
        uint256 price;
        Pool memory pool = pools[_pid];
        (int256 _price, , ) = priceService.getLastPrice(pool.path);
        price = uint256(_price);
        _safeLockRound(_pid, currentEpoch[_pid], price);
        
        if (!isEndRound[_pid]) {
            // Increment currentEpoch to current round (n)
            if (pools[_pid].strikePrice !=0 ) {
                price = pools[_pid].strikePrice;
            }
            currentEpoch[_pid] = currentEpoch[_pid] + 1;
            _safeStartRound(_pid, currentEpoch[_pid], uint256(price));
        } else {
            _pause(_pid);
        }
    }
    
    /**
     * @dev Callback function used by Randomize contract to return a randomness number
     * @param _pid id of pool
     * @param _requestId id was returned by chainlink when request a randomness number (https://docs.chain.link/docs/get-a-random-number)
     * @param _randomNumber a randomness number was returned by oracle
     */
    function numbersDrawn(uint256 _pid, uint256 _epoch, bytes32 _requestId, uint256 _randomNumber) external override {
        require(msg.sender == specifications[_pid][_epoch].oracle);
        if (block.timestamp > rounds[_pid][_epoch].endTime + bufferTimestampRandomness) {
            return;
        }
        require(
            rounds[_pid][_epoch].status == Status.Lock
        );
        
        if (specifications[_pid][_epoch].lotteryWinningRequestId == _requestId) {
            specifications[_pid][_epoch].oracleCalled = true;
            specifications[_pid][_epoch].lotteryWinningNumber = _split(_randomNumber, _pid, _epoch);
            emit OracleResponse(_pid, _epoch, _requestId);
            _calculateRewards(_pid, _epoch);
            _safeEndRound(_pid, _epoch);
        }
    }
    
    /** 
     * @dev Buy a ticket for prediction
     * @param _pid id of pool
     * @param _label true for blue ticket, false for red ticket
     * @param _referral wallet address of referral
     * @param _quantity Quantity of tickets want to buy
     * @param _maxprice Maximum price allow in thí transaction
     * @param _slippagePrice Slippage of price
     */
    function buyTicket(
        uint256 _pid, 
        bool _label, 
        address _referral, 
        uint256 _quantity, 
        uint256 _maxprice,
        uint256 _slippagePrice
    ) public poolExisted(_pid) whenNotPaused(_pid) returns(uint256 _price, uint256 _fee) {
        _updateReferral(msg.sender, _referral);
        (uint256 price, uint256 fee) = _buyTicket(_pid, _label, msg.sender, _quantity);
        require(price <= _maxprice, "PREDICTION: Price is over");
        slippagePrice[msg.sender] = _slippagePrice;
        return (price, fee);
    }
    
    /**
     * @dev Get the claimable stats of specific epoch and user account
     * @param _pid id of pool
     * @param _epoch ordinal number of round
     * @param _user wallet address of user
     */
    function claimable(uint256 _pid, uint256 _epoch, uint256 _tid, address _user) public view returns (bool) {
        Bought memory bought = boughts[_user][_pid][_epoch][_tid];
        Round memory round = rounds[_pid][_epoch];
        Specification memory specification = specifications[_pid][_epoch];
        if (!specification.oracleCalled) {
            return false;
        }
        if (
            (round.closePrice > round.startPrice && bought.label == true) ||
            (round.closePrice < round.startPrice && bought.label == false)
        ) {
            return true;
        }
        return _checkLotteryWinning(_pid, _epoch, _user, _tid);
    }
    
    /**
     * @dev Get the refundable stats of specific epoch and user account
     * @param _pid id of pool
     * @param _tid id of ticket
     * @param _epoch ordinal number of round
     * @param _user wallet address of user
     */
    function refundable(uint256 _pid, uint256 _epoch, uint256 _tid, address _user) public view returns (bool) {
        Bought memory bought = boughts[_user][_pid][_epoch][_tid];
        Round memory round = rounds[_pid][_epoch];
        Specification memory specification = specifications[_pid][_epoch];
        return 
            !specification.oracleCalled && 
            block.timestamp > round.endTime + bufferTimestampRandomness && 
            bought.price != 0;
    }
    
    /**
     * @dev Claim reward
     * @param _pid id of pool
     * @param _epoch ordinal number of round
     * @param _to wallet address of receiver
     * @param _tids List ticket id bought
     */
    function claim(uint256 _pid, uint256 _epoch, address _to, uint256[] memory _tids) external poolExisted(_pid) {
        require(rounds[_pid][_epoch].startTime != 0, "PREDICTION: Round has not started");
        require(block.timestamp > rounds[_pid][_epoch].endTime, "PREDICTION: Round has not ended");

        Round memory round = rounds[_pid][_epoch];
        
        uint256 reward = 0;
        uint256 fee = 0;
        uint256 lotteryReward = 0;
        for (uint256 i = 0; i < _tids.length; i++) {
            uint256 _tid = _tids[i];
            Bought storage bought = boughts[msg.sender][_pid][_epoch][_tid];
            require(!bought.claimed, "PREDICTION: Rewards claimed");
            require(!_checkInitialTicket(_pid, _epoch, msg.sender, _tid), "PREDICTION: Cannot claim initialized ticket");
            
            // Round valid, claim rewards
            if (specifications[_pid][_epoch].oracleCalled == true) {
                require(claimable(_pid, _epoch, _tid, msg.sender), "PREDICTION: Not eligible for claim");
                if (
                    (round.closePrice > round.startPrice && bought.label == true) || 
                    (round.closePrice < round.startPrice && bought.label == false)
                ) {
                    reward += round.rewardAmount * bought.quantity;
                }
                if (_checkLotteryWinning(_pid, _epoch, msg.sender, _tid)) {
                    lotteryReward += round.lotteryRewardAmount;
                }
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(_pid, _epoch, _tid, msg.sender), "PREDICTION: Not eligible for refund");
                reward += bought.price;
                fee += bought.fee;
            }
            bought.claimed = true;
        }
        emit Claim(_pid, _epoch, msg.sender, _to, reward + lotteryReward, _tids);
        if (lotteryReward > 0) {
            achievementService.increaseWinningLotteryCount(msg.sender);
        }
        if (reward + lotteryReward > 0 ) {
            IBEP20(tokenReward).safeTransfer(_to, reward + lotteryReward);
        }
        if (fee > 0) {
            IBEP20(perry).safeTransfer(_to, fee);
        }
        achievementService.increaceTotalWin(msg.sender, _pid, _epoch, reward + lotteryReward);
    }
    
    /**
     * @dev Claim all reward of initialized ticket by owner
     */
    function claimTreasury() external onlyOwner {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        IBEP20(tokenReward).safeTransfer(owner(), currentTreasuryAmount);

        emit ClaimTreasury(currentTreasuryAmount);
    }

    /**
     * @dev Claim all treasury from refund round
     */
    function claimTreasuryOfRefundRound(uint256 _pid, uint256 _epoch) external poolExisted(_pid) onlyOwner {
        require(refundable(_pid, _epoch, 0, owner()), "PREDICTION: Only refund round");
        Specification memory specification = specifications[_pid][_epoch];
        require(boughts[owner()][_pid][_epoch][0].claimed == false, "PREDICTION: Claimed for this round");
        // claim for 2 bought blue and red of owner() when start round
        boughts[owner()][_pid][_epoch][0].claimed = true;
        boughts[owner()][_pid][_epoch][1].claimed = true;
        uint256 amount = boughts[owner()][_pid][_epoch][0].price + boughts[owner()][_pid][_epoch][1].price; 
        uint256 fee = boughts[owner()][_pid][_epoch][0].fee + boughts[owner()][_pid][_epoch][1].fee;

        // claim additional reward
        amount += specification.additionalReward; 
        IBEP20(tokenReward).safeTransfer(owner(), amount);
        IBEP20(perry).safeTransfer(owner(), fee);
    }
    
    /**
     * @dev Get next ticket price for current round
     * @param _buyer wallet address of buye
     * @param _pid id of pool
     * @param _label true for blue ticket, false for red ticket
     * @param _quantity quantity want to buy
     * @return price Next price of ticket
     * @return fee Next fee of ticket
     */
    function getNextTicketPrice(address _buyer, uint256 _pid, bool _label, uint256 _quantity) public view poolExisted(_pid) returns(uint256 price, uint256 fee, uint256 reduceRate) {
        (price, fee, ,reduceRate) = _nextTicket(_buyer, _pid, _label, _quantity);
    }
    
    /**
     * @dev Check if this round can be bet
     */
    function bettable(uint256 _pid, uint256 _epoch) public view returns (bool) {
        return
            rounds[_pid][_epoch].status == Status.Open &&
            block.timestamp <= rounds[_pid][_epoch].endTime;
    }
    
    /**
     * @dev Start round
     * Previous round n-2 must end
     */
    function _safeStartRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        require(genesisStartOnce[_pid]);
        require(rounds[_pid][_epoch - 1].status == Status.Lock || rounds[_pid][_epoch - 1].status == Status.End);
        _startRound(_pid, _epoch, _price);
    }
    
    function _startRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        Round storage round = rounds[_pid][_epoch];
        Pool memory pool = pools[_pid];
        
        round.startTime = block.timestamp;
        round.endTime = block.timestamp + pool.betTime;
        round.startPrice = _price;
        round.status = Status.Open;
        
        emit StartRound(_pid, _epoch, round.startTime, round.endTime, round.startPrice);
        _initTicket(_pid);
    }
    
    /**
     * @dev Lock round
     * 
     */
    function _safeLockRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        require(rounds[_pid][_epoch].startTime != 0);
        require(block.timestamp >= rounds[_pid][_epoch].endTime);
        require(block.timestamp <= rounds[_pid][_epoch].endTime + bufferTimestampPrice);
        _lockRound(_pid, _epoch, _price);
    }
    
    function _lockRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        Pool memory pool = pools[_pid];
        Round storage round = rounds[_pid][_epoch];
        Specification storage specification = specifications[_pid][_epoch];
        require(round.status == Status.Open);
        round.closePrice = uint256(_price);
        round.status = Status.Lock;
        emit LockRound(
            _pid, 
            _epoch, 
            round.closePrice, 
            specification.bluePool, 
            specification.redPool, 
            specification.blueTicketNumber, 
            specification.redTicketNumber
        );
        
        // no need to call oracle to get randomness number when nobody join round
        if (
            specification.blueTicketNumber == pool.ticketNumberInit && 
            specification.redTicketNumber == pool.ticketNumberInit
        ) {
            specifications[_pid][_epoch].oracleCalled = true;
            _calculateRewards(_pid, _epoch);
            _safeEndRound(_pid, _epoch);
        } else {
            specifications[_pid][_epoch].oracle = address(randomService);
            specifications[_pid][_epoch].lotteryWinningRequestId = randomService.getRandomNumber(_pid, _epoch);
        }
    }
    
    /**
     * @dev End round
     * This round must lock
     */
    function _safeEndRound(uint256 _pid, uint256 _epoch) internal {
        require(block.timestamp <= rounds[_pid][_epoch].endTime + bufferTimestampRandomness);
        require(rounds[_pid][_epoch].status == Status.Lock);
        require(specifications[_pid][_epoch].oracleCalled == true);
        _endRound(_pid, _epoch);
    }
    
    function _endRound(uint256 _pid, uint256 _epoch) internal {
        Round storage round = rounds[_pid][_epoch];
        if (specifications[_pid][_epoch].oracleCalled == true) {
            _burnFee(_pid, _epoch);   
        }
        round.status = Status.End;
        emit EndRound(_pid, _epoch, round.closePrice);
    }
    
    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(uint256 _pid, uint256 _epoch) internal {
        Round storage round = rounds[_pid][_epoch];
        Specification storage specification = specifications[_pid][_epoch];
        uint256 rewardAmount;
        uint256 lotteryReward;
        uint8 result;

        uint256 total = specification.bluePool + specification.redPool + specification.additionalReward;
        uint256 totalReward = total * (oneRatio - feeRatio) / oneRatio;
        uint256 totalFee = total - totalReward;

        lotteryReward = totalReward * lotteryRatio / oneRatio;
        // Blue wins
        if (round.closePrice > round.startPrice) {
            result = 1;
            rewardAmount = (totalReward - lotteryReward) / specification.blueTicketNumber;
        }
        // Red wins
        else if (round.closePrice < round.startPrice) {
            result = 0;
            rewardAmount = (totalReward - lotteryReward) / specification.redTicketNumber;
        }
        // House wins
        else {
            result = 2;
            rewardAmount = 0;
        }

        round.rewardAmount = rewardAmount;
        if (specification.lotteryWinningNumber > 0) {
            round.lotteryRewardAmount = lotteryReward;
        } else {
            treasuryAmount += lotteryReward;
        }
        
        if (rewardAmount == 0) {
            treasuryAmount += totalReward - lotteryReward + totalFee; 
        } else {
            Pool memory pool = pools[_pid];
            treasuryAmount += rewardAmount * pool.ticketNumberInit + totalFee; 
        }
        
        emit RewardsCalculated(_pid, _epoch, rewardAmount, lotteryReward, specification.lotteryWinningNumber, result, block.timestamp);
    }
    
    function _buyTicket(uint256 _pid, bool _label, address _buyer, uint256 _quantity) internal returns(uint256 price, uint256 fee) {
        uint256 _currentEpoch = currentEpoch[_pid];
        require(bettable(_pid, _currentEpoch), "PREDICTION: Round not bettable");
        require(_quantity > 0, "PREDICTION: Required quantity > 0");
        Specification storage specification = specifications[_pid][_currentEpoch];

        uint256 newPool; uint256 reduceRate;
        (price, fee, newPool, reduceRate) = _nextTicket(_buyer, _pid, _label, _quantity);
        
        newPool = newPool - price * reduceRate / oneRatio;
        price = price * (oneRatio - reduceRate) / oneRatio;
        fee = fee * (oneRatio - reduceRate) / oneRatio;
        
        if (_label) {
            specification.blueTicketNumber += _quantity;
            specification.bluePool = newPool;
        } else {
            specification.redTicketNumber += _quantity;
            specification.redPool = newPool;
        }
        specification.feePool += fee;
        
        tokenReward.safeTransferFrom(_buyer, address(this), price);
        perry.safeTransferFrom(_buyer, address(this), fee);
        
        _storgeTicket(_buyer, _pid, _currentEpoch, _label, _quantity, price, fee);
        achievementService.updateHistory(_buyer, _pid, _currentEpoch, _quantity);
    }

    function _nextTicket(address _buyer, uint256 _pid, bool _label, uint256 _quantity) internal view returns(uint256 price, uint256 fee, uint256 newPool, uint256 reduceRate) {
        uint256 _currentEpoch = currentEpoch[_pid];
        Pool memory pool = pools[_pid];
        Specification memory specification = specifications[_pid][_currentEpoch];
        
        uint256 improvementDeltaValue = pool.ticketPriceStart * improvementDelta / oneRatio;
        if (_label) {
            newPool = 
                (specification.bluePool / specification.blueTicketNumber + improvementDeltaValue * _quantity) * specification.blueTicketNumber + 
                pool.ticketPriceStart * _quantity +
                improvementDeltaValue * (_quantity - 1) * _quantity / 2;
            price = newPool - specification.bluePool;
        } else {
            newPool = 
                (specification.redPool / specification.redTicketNumber + improvementDeltaValue * _quantity) * specification.redTicketNumber + 
                pool.ticketPriceStart * _quantity +
                improvementDeltaValue * (_quantity - 1) * _quantity / 2;
            price = newPool - specification.redPool;
        }
        fee = pool.ticketFeeStart * price / pool.ticketPriceStart;
        reduceRate = achievementService.totalReduction(_buyer);
    }

    function _initTicket(uint256 _pid) internal {
        uint256 _currentEpoch = currentEpoch[_pid];
        Pool memory pool = pools[_pid];
        Specification storage specification = specifications[_pid][_currentEpoch];
        address _buyer = owner();
        uint256 price = pool.ticketPriceStart * pool.ticketNumberInit;
        uint256 fee = pool.ticketFeeStart * pool.ticketNumberInit;
        specification.bluePool = price;
        specification.redPool = price;
        specification.blueTicketNumber = pool.ticketNumberInit;
        specification.redTicketNumber = pool.ticketNumberInit;
        specification.feePool = 2 * fee;
        
        tokenReward.safeTransferFrom(_buyer, address(this), 2 * price);
        perry.safeTransferFrom(_buyer, address(this), 2 * fee);
        
        _storgeTicket(_buyer, _pid, _currentEpoch, true, pool.ticketNumberInit, price, fee);
        _storgeTicket(_buyer, _pid, _currentEpoch, false, pool.ticketNumberInit, price, fee);
    }
    
    function _storgeTicket(address _buyer, uint256 _pid, uint256 _epoch, bool _label, uint256 _quantity, uint256 _price, uint256 _fee) internal {
        lotteryNumbers[_pid][_epoch] += _quantity;
        Bought memory bought = Bought({
            label: _label,
            quantity: _quantity,
            price: _price,
            fee: _fee,
            lotteryNumber: lotteryNumbers[_pid][_epoch],
            claimed: false
        });
        
        uint256 tid = boughts[_buyer][_pid][_epoch].length;
        boughts[_buyer][_pid][_epoch].push(bought);
        lotteryNumberOwner[_pid][_epoch][bought.lotteryNumber] = _buyer;
        emit BoughtTicket(_buyer, _label, _pid, _epoch, tid, _quantity, bought.lotteryNumber, _price, _fee, block.timestamp);
    }

    function _updateReferral(address _buyer, address _referral) internal {
        if (referral[_buyer] != address(0x0)) {
            return;
        }
        require(_buyer != _referral, "PREDICTION: Yourself not allowed for referral");
        referral[_buyer] = _referral;
        achievementService.increaseReferralCount(_referral);
    }

    function _split(uint256 _randomNumber, uint256 _pid, uint256 _epoch) internal view returns(uint256) {
        Pool memory pool = pools[_pid];
        // Encodes the random number with its position in loop
        bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber, _pid));
        // Casts random number hash into uint256
        uint256 numberRepresentation = uint256(hashOfRandom);
        // Calculation range
        uint256 range = lotteryNumbers[_pid][_epoch] - (2 * pool.ticketNumberInit);
        uint256 position = numberRepresentation % range;
        return position + (2 * pool.ticketNumberInit);
    }

    function _checkLotteryWinning(uint256 _pid, uint256 _epoch, address user, uint256 _tid) internal view returns(bool) {
        Specification memory specification = specifications[_pid][_epoch];
        Bought memory bought = boughts[user][_pid][_epoch][_tid];
        uint256 from = bought.lotteryNumber - bought.quantity;
        uint256 to = bought.lotteryNumber;
        if (from <= specification.lotteryWinningNumber && specification.lotteryWinningNumber < to) {
            return true;
        } else {
            return false;
        }
    }

    function _checkInitialTicket(uint256 _pid, uint256 _epoch, address user, uint256 _tid) internal view returns(bool) {
        Bought memory bought = boughts[user][_pid][_epoch][_tid];
        Pool memory pool = pools[_pid];
        return bought.lotteryNumber <= 2 * pool.ticketNumberInit;
    }
    
    function _burnFee(uint256 _pid, uint256 _epoch) internal {
        Specification memory specification = specifications[_pid][_epoch];
        uint256 fee = specification.feePool;
        perry.safeTransfer(0x000000000000000000000000000000000000dEaD, fee);
        emit BurnFee(_pid, _epoch, fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IAchievement {
    enum AchievementType {
        PlayedGames,
        InvitedFriend,
        WonLottery,
        WonOverall,
        BoughtTicketInOneGame,
        BoughtTicketConsecutive,
        WonInOneGame
    }
    
    struct AchievementDetail {
        uint16 id;
        AchievementType achievementType;
        uint256 powerLevel;
        uint256 earnable;
        uint256 needReached;
    }
    
    struct Round {
        uint256 pid;
        uint256 epoch;
    }
    
    struct BoughtInRound {
        uint256 totalTicket;
        uint256 claimed;
    }

    event MintedAchievement(uint16 indexed achievementId, uint256 indexed tokenId, address indexed to);
    event Harvested(address indexed user, uint256 pid, uint256 epoch);
    event AddNewAchievement(
        AchievementType indexed achievementType, 
        uint16 indexed achievementId,
        uint256 powerLevel,
        uint256 earnable,
        uint256 needReached
    );

    function totalReduction(address user) external view returns(uint256);
    function increaseReferralCount(address referral) external returns(uint256);
    function increaseWinningLotteryCount(address user) external returns(uint256);
    function increaceTotalWin(address user, uint256 pid, uint256 epoch, uint256 amount) external returns(uint256);
    function updateHistory(address user, uint256 pid, uint256 epoch, uint256 quantity) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Interface of the BEP20 standard.
 */
interface IBEP20 {
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
    
    function burn(uint256 amount) external returns(bool success);

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
pragma solidity 0.8.0;

import "./IBEP20.sol";

interface IPrediction {
    /**
     * @dev Status of pool
     */
    enum Status {
        Open,
        Lock,
        End
    }
    
     /**
     * @dev Pool infomation that has not changed or changed very little
     */
    struct Pool {
        address[] path;
        string description;
        uint256 priceDecimals;
        uint256 strikePrice ;
        uint256 betTime;
        uint256 ticketPriceStart;
        uint256 ticketFeeStart;
        uint8 ticketNumberInit;
    }
    
    /**
     * @dev Pool infomation that has not changed or changed very little
     */
    struct Round {
        uint256 startTime;
        uint256 endTime;
        
        uint256 startPrice;
        uint256 closePrice;
        
        Status status;
        
        uint256 rewardAmount;
        uint256 lotteryRewardAmount;
    }
    
    /**
     * @dev Pool specification that change frequently during operation
     */
    struct Specification {
        uint256 redTicketNumber;
        uint256 blueTicketNumber;
        
        uint256 redPool;
        uint256 bluePool;
        uint256 feePool;

        uint256 additionalReward;

        bytes32 lotteryWinningRequestId;
        address oracle;
        bool oracleCalled;
        uint256 lotteryWinningNumber;
    }
    
    /**
     * @dev Ticket infomation
     * label=true if blue ticket, label=false if red ticket
     */
    struct Bought {
        bool label;
        uint256 quantity;
        uint256 price;
        uint256 fee;
        uint256 lotteryNumber;
        bool claimed;
    }
    
    event NewPool(uint256 indexed pid, address indexed creator);
    event StartRound(uint256 indexed pid, uint256 indexed epoch, uint256 startTime, uint256 endTime, uint256 startPrice);
    event LockRound(
        uint256 indexed pid, 
        uint256 indexed epoch, 
        uint256 closePrice, 
        uint256 bluePool,
        uint256 redPool,
        uint256 blueTicket,
        uint256 redTicket
    );
    event EndRound(uint256 indexed pid, uint256 indexed epoch, uint256 price);
    event OracleResponse(uint256 indexed pid, uint256 indexed epoch, bytes32 requestId);
    event BurnFee(uint256 indexed pid, uint256 indexed epoch, uint256 fee);
    event BoughtTicket(
        address indexed buyer, 
        bool label, 
        uint256 indexed pid, 
        uint256 indexed epoch, 
        uint256 tid, 
        uint256 quantity, 
        uint256 lotteryNumber, 
        uint256 price, 
        uint256 fee,
        uint256 timestamp
    );
    event Claim(uint256 indexed pid, uint256 indexed epoch, address indexed owner, address to, uint256 amount, uint256[] tids);
    event ClaimTreasury(uint256 amount);
    event ClaimReferralReward(address caller, address receiver, uint256 amount);
    event RewardsCalculated(
        uint256 indexed pid,
        uint256 indexed epoch,
        uint256 rewardAmount,
        uint256 lotteryAmount,
        uint256 lotteryWinningNumber,
        uint8 result,
        uint256 timestamp
    );
    event UpdatedRandomService(address indexed _old, address indexed _new);
    event UpdatedPriceService(address indexed _old, address indexed _new);
    event UpdatedAchievementService(address indexed _old, address indexed _new);
    event UpdatedLotteryRatio(uint256 indexed _old, uint256 indexed _new);
    event UpdatedOperator(address indexed _old, address indexed _new);
    event UpdateBufferTime(uint256 bufferTimePrice, uint256 bufferTimeRandom);
    /**
     * @dev Callback function used by Randomize contract
     * @param _pid id of pool
     * @param _requestId id was returned by chainlink when request a randomness number (https://docs.chain.link/docs/get-a-random-number)
     * @param _randomNumber a randomness number was returned by chainlink
     */
    function numbersDrawn(uint256 _pid, uint256 _epoch, bytes32 _requestId, uint256 _randomNumber) external;
    function tokenReward() view external returns(IBEP20);
    function rounds(uint256 _pid, uint256 _epoch) view external returns(
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 closePrice,
        Status status,
        uint256 rewardAmount,
        uint256 lotteryRewardAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IPrice {
     /**
     * @dev get last price provided by chainlink (https://docs.chain.link/docs/get-the-latest-price)
     */
     function getLastPrice(address[] memory _path) external view returns (int _price, uint8 _decimals, string memory _description);
 }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IRandom {
    function getRandomNumber(uint256 pid, uint256 epoch) external returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IBEP20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
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

