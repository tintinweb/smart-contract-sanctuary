// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Context.sol";

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
abstract contract Owned is Context {
    address  private _owner;

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

pragma solidity ^0.8.0;
import "./utils/Context.sol";

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

pragma solidity ^0.8.0;

import './Owned.sol';
import "./Pausable.sol";
import './interfaces/IPrice.sol';
import './interfaces/IRandom.sol';

import './libraries/SafeMath.sol';
import './libraries/SafeBEP20.sol';

contract Prediction is Owned, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    /**
     * @dev Status of pool
     */
    enum Status {
        Open,
        Lock,
        End
    }
    
    /**
     * @dev 100%
     */
    uint256 private oneRatio = 1e6;

    /**
     * @dev Allowed delay time when getting price in seconds
     */
    uint256 private bufferTimestamp=300;
    
    /**
     * @dev Pool infomation that has not changed or changed very little
     */
    struct Pool {
        address oraclePriceCaller;
        string description;
        uint256 priceDecimals;
        uint256 betTime;
        uint256 ticketPriceStart;
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
        
        bytes32 lotteryWinningRequestId;
        bool oracleCalled;
        uint256 lotteryWinningNumber;
    }
    
    /**
     * @dev Ticket infomation
     * label=true if blue ticket, label=false if red ticket
     */
    struct Ticket {
        bool label;
        uint256 index_by_label;
        uint256 price;
        bool claimed;
    }
    
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(uint256 => Round)) public rounds;
    mapping(uint256 => mapping(uint256 => Specification)) public specifications;
    mapping(uint256 => uint256) public currentEpoch;
    mapping(uint256 => bool) public genesisStartOnce;
    uint256 public poolLength;
    
    mapping(address => mapping(uint256 => mapping(uint256 => Ticket[]))) public tickets;
    IBEP20 public tokenReward;
    IPrice public priceService;
    IRandom public randomService;
    uint256 public lotteryRatio;
    uint256 public feeRatio;
    uint256 public improvementDelta; 
    
    mapping(address => address) public referral;
    mapping(address => uint256) public referralReward;
    uint256 public referralRewardPerTicket;
    
    uint256 public treasuryAmount;
    
    /**
     * @dev wallet address of operator, who was allowed create and close pool
     */
    address public operatorAddress;
    
    event NewPool(uint256 indexed pid, address indexed creator);
    event StartRound(uint256 indexed pid, uint256 indexed epoch);
    event LockRound(uint256 indexed pid, uint256 indexed epoch, uint256 price);
    event EndRound(uint256 indexed pid, uint256 indexed epoch, uint256 price);
    event OracleResponse(uint256 indexed pid, uint256 indexed epoch, bytes32 requestId);
    event BurnFee(uint256 indexed pid, uint256 indexed epoch, uint256 fee);
    event NewTicket(uint256 indexed pid, uint256 indexed epoch, address indexed buyer, uint8 tid);
    event Claim(uint256 indexed pid, uint256 indexed epoch, address indexed owner, address to, uint256 amount);
    event ClaimLottery(uint256 indexed pid, uint256 indexed epoch, address indexed owner, address to, uint256 amount);
    event ClaimTreasury(uint256 amount);
    event ClaimReferralReward(address caller, address receiver, uint256 amount);
    event RewardsCalculated(
        uint256 indexed pid,
        uint256 indexed epoch,
        uint256 rewardAmount,
        uint256 lotteryAmount
    );
    
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
            msg.sender == address(randomService),
            "PREDICTION: Only called by Random Service"
        );
        _;
    }
    
    /**
     * @dev Prevent contract call a function
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "PREDICTION: Contract not allowed");
        require(msg.sender == tx.origin, "PREDICTION: Proxy contract not allowed");
        _;
    }
    
    /**
     * @param _tokenReward Reward token address
     * @param _operator Wallet address is allowed to create and close pool
     * @param _lotteryRatio Lottery ratio (real value * 1e6)
     * @param _feeRatio Fee ratio (real value * 1e6)
     * @param _improvementDelta Wallet address is allowed to create and close pool
     * @param _referralRewardPerTicket Referral reward amount per ticket
     */
    constructor(
        address _tokenReward, 
        address _operator, 
        uint256 _lotteryRatio, 
        uint256 _feeRatio, 
        uint256 _improvementDelta, 
        uint256 _referralRewardPerTicket
    ) {
        require(_lotteryRatio < 1e6, "PREDICTION: lotteryRatio need to be less than 100%");
        require(_feeRatio < 1e6, "PREDICTION: feeRatio need to be less than 100%");
        require(_lotteryRatio + _feeRatio < 1e6, "PREDICTION: lotteryRatio + feeRatio need to be less than 100%");
        tokenReward = IBEP20(_tokenReward);
        operatorAddress = _operator; 
        lotteryRatio = _lotteryRatio;
        feeRatio = _feeRatio;
        improvementDelta = _improvementDelta;
        poolLength = 0;
        referralRewardPerTicket = _referralRewardPerTicket;
    }
    
    /**
     * @dev Update wallet address of Randomize contract, only by Owner
     * @param _random New randomize contract address
     */
    function setRandomService(address _random) public onlyOwner {
        randomService = IRandom(_random);
    }
    
    /**
     * @dev Update wallet address of Price contract, only by Owner
     * @param _price New price contract address
     */
    function setPriceService(address _price) public onlyOwner {
        priceService = IPrice(_price);
    }
    
    /**
     * @dev Update token for reward, only by Owner
     * @param _token New reward token address
     */
    function setTokenReward(address _token) public onlyOwner {
        tokenReward = IBEP20(_token); 
    }
    
     /**
     * @dev Update fee ratio, only by Owner
     * @param _feeRatio New fee ratio token address
     */
    function setFeeRatio(uint256 _feeRatio) public onlyOwner {
        require(_feeRatio < 1e6, "PREDICTION: feeRatio need to be less than 100%");
        require(lotteryRatio + _feeRatio < 1e6, "PREDICTION: lotteryRatio + feeRatio need to be less than 100%");
        feeRatio = _feeRatio; 
    }
    
    /**
     * @dev Update lottery ratio, only by Owner
     * @param _lotteryRatio New lottery ratio token address
     */
    function setLotteryRatio(uint256 _lotteryRatio) public onlyOwner {
        require(_lotteryRatio < 1e6, "PREDICTION: lotteryRatio need to be less than 100%");
        require(_lotteryRatio + feeRatio < 1e6, "PREDICTION: lotteryRatio + feeRatio need to be less than 100%");
        lotteryRatio = _lotteryRatio; 
    }
    
    /**
     * @dev Update improvement delta, only by Owner
     * @param _improvementDelta New improvement delta
     */
    function setImprovementDelta(uint256 _improvementDelta) public onlyOwner {
        improvementDelta = _improvementDelta; 
    }
    
    /**
     * @dev Update buffer timestamp, only by Owner
     * @param _bufferTimestamp New buffer timestamp
     */
    function setBufferTimestamp(uint256 _bufferTimestamp) public onlyOwner {
        bufferTimestamp = _bufferTimestamp;
    }
    
    /**
     * @dev Update operator address, only by Owner
     * @param _operator Wallet address of new operator
     */
    function setOperator(address _operator) public onlyOwner {
        operatorAddress = _operator; 
    }
    
     /**
     * @dev Update referral reward per ticket, only by Owner
     * @param _referralRewardPerTicket Reward amount
     */
    function setReferralRewardPerTicket(uint256 _referralRewardPerTicket) public onlyOwner {
        referralRewardPerTicket = _referralRewardPerTicket; 
    }
    
    /**
     * @dev called by the admin to pause, triggers stopped state
     */
    function pause(uint256 _pid) public onlyOwnerOrOperator whenNotPaused(_pid) {
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
    
    /**
     * @dev Create new pool
     * @param _oraclePriceCaller Contract address of price feeds (https://docs.chain.link/docs/reference-contracts)
     * @param _betTime Bet time of this pool in seconds
     * @param _ticketPrice Price of a ticket starts
     * @param _initTicketNumber Number of tickets of each type to be initialized
     */
    function genesisPool(
        address _oraclePriceCaller,
        uint256 _betTime,
        uint256 _ticketPrice,
        uint8 _initTicketNumber
    ) public onlyOperator {
        require(_initTicketNumber > 0, "PREDICTION: Requires initialization of at least 1 pair of tickets");
        require(_initTicketNumber <= 30, "PREDICTION: Requires initialization of at most 30 pair of tickets");
        
        (, uint8 decimals , , , string memory description) = priceService.getLastPrice(_oraclePriceCaller);
        Pool storage pool = pools[poolLength];
        pool.oraclePriceCaller = _oraclePriceCaller;
        pool.description = description;
        pool.priceDecimals = decimals;
        pool.betTime = _betTime;
        pool.ticketPriceStart = _ticketPrice;
        pool.ticketNumberInit = _initTicketNumber;
        emit NewPool(poolLength, msg.sender);
        poolLength++;
    }
    
    /**
     * @dev Start genesis round
     */
    function genesisStartRound(uint256 _pid) external onlyOperator whenNotPaused(_pid) {
        require(!genesisStartOnce[_pid], "PREDICTION: Can only run genesisStartRound once");
        
        (int price, , , , ) = priceService.getLastPrice(pools[_pid].oraclePriceCaller);
        currentEpoch[_pid] = currentEpoch[_pid] + 1;
        _startRound(_pid, currentEpoch[_pid], uint256(price));
        
        genesisStartOnce[_pid] = true;
    }
    
     /**
     * @dev Lock genesis round
     * @param _pid id of pool
     */
    function genesisEndRound(uint256 _pid, uint256 _epoch) external onlyOperator whenNotPaused(_pid) {
        _safeEndRound(_pid, _epoch);
        _calculateRewards(_pid, _epoch);
    }
    
    /**
     * @dev Start the next round n, lock round n-1 for request oracle
     * @param _pid id of pool
     */
    function executeRound(uint256 _pid) external onlyOperator whenNotPaused(_pid) {
        require(
            genesisStartOnce[_pid],
            "PREDICTION: Can only run after genesisStartRound and genesisLockRound is triggered"
        );
        
        Pool memory pool = pools[_pid];
        (int price, , , ,) = priceService.getLastPrice(pool.oraclePriceCaller);
        _safeLockRound(_pid, currentEpoch[_pid], uint256(price));
        
        // Increment currentEpoch to current round (n)
        currentEpoch[_pid] = currentEpoch[_pid] + 1;
        _safeStartRound(_pid, currentEpoch[_pid], uint256(price));
    }
    
    /**
     * @dev Callback function used by Randomize contract to return a randomness number
     * @param _pid id of pool
     * @param _requestId id was returned by chainlink when request a randomness number (https://docs.chain.link/docs/get-a-random-number)
     * @param _randomNumber a randomness number was returned by oracle
     */
    function numbersDrawn(uint256 _pid, bytes32 _requestId, uint256 _randomNumber) external onlyRandomService() {
        uint256 _epoch = currentEpoch[_pid] - 1;
        require(
            rounds[_pid][_epoch].status == Status.Lock,
            "PREDICTION: Required close pool first"
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
     */
    function buyTicket(uint256 _pid, bool _label, address _referral) public poolExisted(_pid) whenNotPaused(_pid) returns(uint256 _price) {
        require(_referral == address(0x0) || !_isContract(_referral), "PREDICTION: Contract not allowed for referral");
        require(_bettable(_pid, currentEpoch[_pid]), "PREDICTION: Round not bettable");
        return _buyTicket(_pid, _label, msg.sender, false, _referral);
    }
    
    /**
     * @dev Get the claimable stats of specific epoch and user account
     * @param _pid id of pool
     * @param _epoch ordinal number of round
     * @param _user wallet address of user
     */
    function claimable(uint256 _pid, uint256 _epoch, uint8 _tid, address _user) public view returns (bool) {
        Ticket memory ticket = tickets[_user][_pid][_epoch][_tid];
        Round memory round = rounds[_pid][_epoch];
        Specification memory specification = specifications[_pid][_epoch];
        if (round.startPrice == round.closePrice) {
            return false;
        }
        return specification.oracleCalled &&
                ((round.closePrice > round.startPrice && ticket.label == true) ||
                (round.closePrice < round.startPrice && ticket.label == false) );
    }
    
     /**
     * @dev Get the refundable stats of specific epoch and user account
     * @param _pid id of pool
     * @param _epoch ordinal number of round
     * @param _user wallet address of user
     */
    function refundable(uint256 _pid, uint256 _epoch, uint8 _tid,address _user) public view returns (bool) {
        Ticket memory ticket = tickets[_user][_pid][_epoch][_tid];
        Round memory round = rounds[_pid][_epoch];
        Specification memory specification = specifications[_pid][_epoch];
        return !specification.oracleCalled && block.timestamp > round.endTime.add(bufferTimestamp) && ticket.price != 0;
    }
    
     /**
     * @dev Claim reward
     * @param _pid id of pool
     * @param _epoch ordinal number of round
     * @param _to wallet address of receiver
     */
    function claim(uint256 _pid, uint256 _epoch, address _to, uint8[] memory _tids) external notContract {
        require(rounds[_pid][_epoch].startTime != 0, "PREDICTION: Round has not started");
        require(block.timestamp > rounds[_pid][_epoch].endTime, "PREDICTION: Round has not ended");

        Round memory round = rounds[_pid][_epoch];
        Specification memory specification = specifications[_pid][_epoch];
        
        for (uint8 i = 0; i < _tids.length; i++) {
            uint8 _tid = _tids[i];
            Ticket storage ticket = tickets[msg.sender][_pid][_epoch][_tid];
            require(!tickets[msg.sender][_pid][_epoch][_tid].claimed, "PREDICTION: Rewards claimed");
            require(ticket.index_by_label >= pools[_pid].ticketNumberInit, "PREDICTION: Cannot claim initialized ticket");
            
            uint256 reward;
            uint256 lotteryReward;
            // Round valid, claim rewards
            if (specifications[_pid][_epoch].oracleCalled == true) {
                require(claimable(_pid, _epoch, _tid, msg.sender), "PREDICTION: Not eligible for claim");
                reward = round.rewardAmount;
                if (ticket.index_by_label == specification.lotteryWinningNumber) {
                    lotteryReward = round.lotteryRewardAmount;
                }
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(_pid, _epoch, _tid, msg.sender), "PREDICTION: Not eligible for refund");
                reward = tickets[msg.sender][_pid][_epoch][_tid].price;
            }
    
            ticket.claimed = true;
            IBEP20(tokenReward).safeTransfer(_to, reward);
            if (lotteryReward > 0) {
                IBEP20(tokenReward).safeTransfer(_to, lotteryReward);
                emit ClaimLottery(_pid, _epoch, msg.sender, _to, reward);
            }
    
            emit Claim(_pid, _epoch, msg.sender, _to, reward);
        }
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
     * @dev Claim all referral reward
     * @param _to wallet address of receiver
     */
    function claimReferralReward(address _to) external notContract {
        require(referralReward[msg.sender] > 0, "PREDICTION: No reward yet");
        uint256 currentRewardAmount = referralReward[msg.sender];
        referralReward[msg.sender] = 0;
        IBEP20(tokenReward).safeTransferFrom(owner(), _to, currentRewardAmount);

        emit ClaimReferralReward(msg.sender, _to, currentRewardAmount);
    }
    
    /**
     * @dev Get next ticket price for current round
     * @param _pid id of pool
     * @param _label true for blue ticket, false for red ticket
     * @return Returns next price of ticket
     */
    function getNextTicketPrice(uint256 _pid, bool _label) public view poolExisted(_pid) returns(uint256) {
        uint256 _currentEpoch = currentEpoch[_pid];
        Pool memory pool = pools[_pid];
        Specification memory specification = specifications[_pid][_currentEpoch];
        uint256 price = 0;
        
        uint256 newBluePool = 0;
        uint256 newRedPool = 0;
        if (_label) {
            newBluePool = (specification.bluePool.div(specification.blueTicketNumber).add(improvementDelta)).mul(specification.blueTicketNumber).add(pool.ticketPriceStart);
            price = newBluePool - specification.bluePool;
        } else {
            newRedPool = (specification.redPool.div(specification.redTicketNumber).add(improvementDelta)).mul(specification.redTicketNumber).add(pool.ticketPriceStart);
            price = newRedPool - specification.redPool;
        }
        return price;
    }
    
    /**
     * @dev Check if this round can be bet
     */
    function _bettable(uint256 _pid, uint256 _epoch) internal view returns (bool) {
        return
            rounds[_pid][_epoch].status == Status.Open;
    }
    
    /**
     * @dev Start round
     * Previous round n-2 must end
     */
    function _safeStartRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        require(genesisStartOnce[_pid], "PREDICTION: Can only run after genesisStartRound is triggered");
        require(rounds[_pid][_epoch - 1].status == Status.Lock || rounds[_pid][_epoch - 1].status == Status.End, "PREDICTION: Can only start round after round n-1 has lock");
        _startRound(_pid, _epoch, _price);
    }
    
    function _startRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        Round storage round = rounds[_pid][_epoch];
        Pool memory pool = pools[_pid];
        
        round.startTime = block.timestamp;
        round.endTime = block.timestamp.add(pool.betTime);
        round.startPrice = _price;
        round.status = Status.Open;
        
        emit StartRound(_pid, _epoch);
        for (uint256 i = 0; i < pool.ticketNumberInit; i++) {
            _buyTicket(_pid, true, owner(), true, address(0x0));
            _buyTicket(_pid, false, owner(), true, address(0x0));
        }
    }
    
     /**
     * @dev Lock round
     * 
     */
    function _safeLockRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        require(rounds[_pid][_epoch].startTime != 0, "PREDICTION: Can only lock round after round has started");
        require(block.timestamp >= rounds[_pid][_epoch].endTime, "PREDICTION: Can only lock round after end time");
        require(block.timestamp <= rounds[_pid][_epoch].endTime.add(bufferTimestamp), "PREDICTION: Can only lock round within bufferTimes");
        _lockRound(_pid, _epoch, _price);
    }
    
    function _lockRound(uint256 _pid, uint256 _epoch, uint256 _price) internal {
        Pool memory pool = pools[_pid];
        Round storage round = rounds[_pid][_epoch];
        Specification storage specification = specifications[_pid][_epoch];
        require(round.status == Status.Open, "PREDICTION: Round status incorrect");
        round.closePrice = uint256(_price);
        round.status = Status.Lock;
        emit LockRound(_pid, _epoch, round.closePrice);
        
        // no need to call oracle to get randomness number
        if (
            round.startPrice == round.closePrice ||  // House win
            (round.startPrice > round.closePrice && specification.blueTicketNumber == pool.ticketNumberInit) || // Bule win but haven't blue ticket
            (round.startPrice < round.closePrice && specification.redTicketNumber == pool.ticketNumberInit)  // Red win but haven't red ticket
        ) {
            specifications[_pid][_epoch].oracleCalled = true;
            _calculateRewards(_pid, _epoch);
            _safeEndRound(_pid, _epoch);
        } else {
            specifications[_pid][_epoch].lotteryWinningRequestId = randomService.getRandomNumber(_pid);
        }
    }
    
    /**
     * @dev End round
     * This round must lock
     */
    function _safeEndRound(uint256 _pid, uint256 _epoch) internal {
        require(block.timestamp <= rounds[_pid][_epoch].endTime.add(bufferTimestamp), "PREDICTION: Can only end round within bufferTimes");
        require(rounds[_pid][_epoch].status == Status.Lock, "PREDICTION: Can only end round after round has locked");
        require(specifications[_pid][_epoch].oracleCalled == true, "PREDICTION: Can only end round after receive response from oracle");
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
        // Blue wins
        if (round.closePrice > round.startPrice) {
            rewardAmount = 
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(lotteryRatio).sub(feeRatio)).div(oneRatio)
                .div(specification.blueTicketNumber);
            lotteryReward = (specification.bluePool.add(specification.redPool)).mul(lotteryRatio).div(oneRatio);
        }
        // Red wins
        else if (round.closePrice < round.startPrice) {
            rewardAmount = 
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(lotteryRatio).sub(feeRatio)).div(oneRatio)
                .div(specification.redTicketNumber);
            lotteryReward = (specification.bluePool.add(specification.redPool)).mul(lotteryRatio).div(oneRatio);
        }
        // House wins
        else {
            rewardAmount = 0;
            lotteryReward = 0;
        }
        round.rewardAmount = rewardAmount;
        round.lotteryRewardAmount =  lotteryReward;
        if (rewardAmount == 0) {
            treasuryAmount = treasuryAmount.add(
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(lotteryRatio).sub(feeRatio)).div(oneRatio)
            ); 
        } else {
            Pool memory pool = pools[_pid];
            treasuryAmount = treasuryAmount.add(
                (specification.bluePool.add(specification.redPool))
                .mul(oneRatio.sub(lotteryRatio).sub(feeRatio)).div(oneRatio)
                .div(specification.redTicketNumber)
                .mul(pool.ticketNumberInit)
            ); 
        }

        emit RewardsCalculated(_pid, _epoch, rewardAmount, lotteryReward);
    }
    
    /**
     * @dev Buy a ticket, only internal call
     * @param _pid id of pool
     * @param _label true for blue ticket, false for red ticket
     * @param _buyer ticket buyer
     * @param _initial only true when start round
     * @param _referral wallet address of referral
     */
    function _buyTicket(uint256 _pid, bool _label, address _buyer, bool _initial, address _referral) internal returns(uint256 _price) {
        uint256 _currentEpoch = currentEpoch[_pid];
        Pool memory pool = pools[_pid];
        Specification storage specification = specifications[_pid][_currentEpoch];
        uint256 price = 0;
        
        if (_initial == true && _label == true) {
            price = pool.ticketPriceStart;
            specification.bluePool = specification.bluePool.add(price);
            specification.blueTicketNumber++;
        } else if (_initial == true && _label == false) {
            price = pool.ticketPriceStart;
            specification.redPool = specification.redPool.add(price);
            specification.redTicketNumber++;
        } else {
            uint256 newBluePool = 0;
            uint256 newRedPool = 0;
             if (_label) {
                newBluePool = (specification.bluePool.div(specification.blueTicketNumber).add(improvementDelta)).mul(specification.blueTicketNumber).add(pool.ticketPriceStart);
                newRedPool = specification.redPool;
                specification.blueTicketNumber++;
                price = newBluePool - specification.bluePool;
            } else {
                newBluePool = specification.bluePool;
                newRedPool = (specification.redPool.div(specification.redTicketNumber).add(improvementDelta)).mul(specification.redTicketNumber).add(pool.ticketPriceStart);
                specification.redTicketNumber++;
                price = newRedPool - specification.redPool;
            }
            specification.bluePool = newBluePool;
            specification.redPool = newRedPool;
            
            if (_referral != address(0x0) && referral[_buyer] == address(0x0)) {
                referral[_buyer] = _referral;
            }
            if (referral[_buyer] != address(0x0)) {
                referralReward[referral[_buyer]] = referralReward[referral[_buyer]].add(referralRewardPerTicket);
            }
        }
        
        tokenReward.safeTransferFrom(_buyer, address(this), price);
        
        uint256 index = (_label ? specification.blueTicketNumber : specification.redTicketNumber) - 1;
        
        Ticket memory ticket = Ticket({
            label: _label,
            price: price,
            index_by_label: index,
            claimed: false
        });
        
        tickets[msg.sender][_pid][_currentEpoch].push(ticket);
        uint8 tid = uint8(tickets[msg.sender][_pid][_currentEpoch].length);
        emit NewTicket(_pid, _currentEpoch, _buyer, tid);
        return (price);
    }
    
    function _split(uint256 _randomNumber, uint256 _pid, uint256 _epoch) internal view returns(uint16) {
        Pool memory pool = pools[_pid];
        Round memory round = rounds[_pid][_epoch];
        Specification memory specification = specifications[_pid][_epoch];
        // Encodes the random number with its position in loop
        bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber, _pid));
        // Casts random number hash into uint256
        uint256 numberRepresentation = uint256(hashOfRandom);
        
        bool result = round.startPrice > round.closePrice;
        // Calculation range
        uint256 range = result ? specification.blueTicketNumber.sub(pool.ticketNumberInit) : specification.redTicketNumber.sub(pool.ticketNumberInit);
        uint256 position = numberRepresentation % range;
        return uint16(position.add(pool.ticketNumberInit));
    }
    
    function _burnFee(uint256 _pid, uint256 _epoch) internal {
        Specification memory specification = specifications[_pid][_epoch];
        uint256 fee = (specification.bluePool.add(specification.redPool)).mul(feeRatio).div(oneRatio);
        IBEP20(tokenReward).burn(fee);
        emit BurnFee(_pid, _epoch, fee);
    }
    
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IPrice {
     /**
     * @dev get last price provided by chainlink (https://docs.chain.link/docs/get-the-latest-price)
     * @param _address Chainlink Price Feed contracts address (https://docs.chain.link/docs/reference-contracts)
     */
     function getLastPrice(address _address) external view returns (int _price, uint8 _decimals, uint _startedAt, uint _timeStamp, string memory _description);

     /**
     * @dev get historical price provided by chainlink (https://docs.chain.link/docs/historical-price-data)
     * @param _address Chainlink Price Feed contracts address (https://docs.chain.link/docs/reference-contracts)
     * @param roundId id of round
     */
     function getHistoricalPrice(address _address, uint80 roundId) external view returns (int _price, uint8 _decimals, uint _startedAt, uint _timeStamp, string memory _description);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandom {

    /** 
     * @dev Requests randomness from lottery for a pool, only by lottery contract
     * @param lotteryId pool id in lotery contract
     * @return requestId request id of this request
     */
    function getRandomNumber(
        uint256 lotteryId
    ) 
        external 
        returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IBEP20.sol";
import "../utils/Address.sol";

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

pragma solidity ^0.8.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
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