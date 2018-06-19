pragma solidity 0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Bet {
    address public ceoAddress;
    address public cooAddress;

    enum RoundStatus { UNKNOWN, RUNNING, FINISHED, CANCELLED }

    event RoundCreated(uint16 roundId);
    event BetPlaced(uint betId, uint16 roundId, uint amount);
    event RoundStatusUpdated(uint16 roundId, RoundStatus oldStatus, RoundStatus newStatus);
    event FinalScoreUpdated(uint16 roundId, bytes32 winner);
    event Debug(uint16 roundId, uint expire, uint time, bool condition);

    struct Round {
        string name;
        bytes32[] statusPossibility;
        uint16 nbBets;
        uint prizePool;
        RoundStatus status;
        bytes32 resultStatus;
        uint runningAt;
        uint finishedAt;
        uint expireAt;
    }

    struct Bet {
        uint16 roundId;
        address owner;
        uint amount;
        bytes32 status;
        bool claimed;
    }

    //mapping(uint => address) public betToOwner;
    mapping(uint16 => uint[]) public roundBets; // roundId => betId[]
    //mapping(address => uint) public ownerBetCount;
    Bet[] public bets;
    Round[] public rounds;
    uint16 public roundsCount;
    uint public fees;
    uint public MINIMUM_BET_VALUE = 0.01 ether;

    constructor() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function setMinimumBetValue(uint _minimumBetValue) onlyCLevel {
        MINIMUM_BET_VALUE = _minimumBetValue;
    }

    function setCEOAddress(address _address) public onlyOwner {
        ceoAddress = _address;
    }

    function setCOOAddress(address _address) public onlyOwner {
        cooAddress = _address;
    }

    function createRound(string _name, bytes32[] _statusPossibility, uint _expireAt) public onlyCLevel {
        uint16 id = uint16(rounds.push(Round(_name, _statusPossibility, 0, 0, RoundStatus.RUNNING, 0, now, 0, _expireAt)) - 1);
        roundsCount = uint16(SafeMath.add(roundsCount, 1));

        emit RoundCreated(id);
    }

    function getRoundStatuses(uint16 _roundId) public view returns(bytes32[] statuses) {
        return rounds[_roundId].statusPossibility;
    }

    function extendRound(uint16 _roundId, uint _time) public onlyCLevel {
        rounds[_roundId].expireAt = _time;
    }

    function getRoundBets(uint16 _roundId) public view returns(uint[] values) {
        return roundBets[_roundId];
    }

    function updateRoundStatus(uint16 _id, RoundStatus _status) public onlyCLevel {
        require(rounds[_id].status != RoundStatus.FINISHED);
        emit RoundStatusUpdated(_id, rounds[_id].status, _status);
        rounds[_id].status = _status;

        if (_status == RoundStatus.CANCELLED) {
            rounds[_id].finishedAt = now;
        }
    }

    function setRoundFinalScore(uint16 _roundId, bytes32 _resultStatus) public
    roundIsRunning(_roundId)
    onlyCLevel
    payable {
        rounds[_roundId].status = RoundStatus.FINISHED;
        rounds[_roundId].finishedAt = now;
        rounds[_roundId].resultStatus = _resultStatus;

        emit FinalScoreUpdated(_roundId, _resultStatus);
    }

    function bet(uint16 _roundId, bytes32 _status) public
    roundIsRunning(_roundId)
    greaterThan(msg.value, MINIMUM_BET_VALUE)
    isNotExpired(_roundId)
    payable {
        Debug(_roundId, rounds[_roundId].expireAt, now, now >= rounds[_roundId].expireAt);
        uint id = bets.push(Bet(_roundId, msg.sender, msg.value, _status, false)) - 1;
        roundBets[_roundId].push(id);
        rounds[_roundId].nbBets++;
        rounds[_roundId].prizePool += msg.value;

        emit BetPlaced(id, _roundId, msg.value);
    }

    function claimRoundReward(uint16 _roundId, address _owner) public roundIsFinish(_roundId) returns (uint rewardAfterFees, uint rewardFees) {
        Round memory myRound = rounds[_roundId];
        uint[] memory betIds = getRoundBets(_roundId);

        uint totalRewardsOnBet = 0;
        uint totalBetOnWinResult = 0;
        uint amountBetOnResultForOwner = 0;
        for (uint i = 0; i < betIds.length; i++) {
            Bet storage bet = bets[betIds[i]];

            if (bet.status == myRound.resultStatus) {
                totalBetOnWinResult = SafeMath.add(totalBetOnWinResult, bet.amount);
                if (bet.claimed == false && bet.owner == _owner) {
                    amountBetOnResultForOwner = SafeMath.add(amountBetOnResultForOwner, bet.amount);
                    bet.claimed = true;
                }
            } else {
                totalRewardsOnBet = SafeMath.add(totalRewardsOnBet, bet.amount);
            }
        }

        uint coef = 10000000; // Handle 4 numbers precision
        uint percentOwnerReward = SafeMath.div(SafeMath.mul(amountBetOnResultForOwner, coef), totalBetOnWinResult);

        uint rewardToOwner = SafeMath.div(SafeMath.mul(percentOwnerReward, totalRewardsOnBet), coef);
        rewardAfterFees = SafeMath.div(SafeMath.mul(rewardToOwner, 90), 100);
        rewardFees = SafeMath.sub(rewardToOwner, rewardAfterFees);
        rewardAfterFees = SafeMath.add(rewardAfterFees, amountBetOnResultForOwner);

        fees = SafeMath.add(fees, rewardFees);

        _owner.transfer(rewardAfterFees);
    }

    function claimCancelled(uint16 _roundId, address _owner) public roundIsCancelled(_roundId) returns(uint amountToClaimBack) {
        uint[] memory betIds = getRoundBets(_roundId);

        amountToClaimBack = 0;
        for (uint i = 0; i < betIds.length; i++) {
            Bet storage bet = bets[betIds[i]];

            if (bet.owner == _owner && bet.claimed != true) {
                amountToClaimBack = SafeMath.add(amountToClaimBack, bet.amount);
                bet.claimed = true;
            }
        }

        _owner.transfer(amountToClaimBack);
    }

    function claimRewards(uint16[] _roundsToClaim, address _owner) public {
        for (uint i = 0; i < _roundsToClaim.length; i++) {
            claimRoundReward(_roundsToClaim[i], _owner);
        }
    }

    function payout(address _to, uint _amount) public onlyOwner {
        require(fees >= _amount);
        fees = SafeMath.sub(fees, _amount);
        _to.transfer(_amount);
    }

    modifier onlyOwner() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    modifier greaterThan(uint _value, uint _expect) {
        require(_value >= _expect);
        _;
    }

    modifier isNotExpired(uint16 _roundId) {
        require(rounds[_roundId].expireAt == 0 || now < rounds[_roundId].expireAt);
        _;
    }

    modifier betStatusPossible(uint16 _roundId, bytes32 _status) {
        //require(_status < rounds[_roundId].statusPossibility);
        _;
    }

    modifier roundIsCancelled(uint16 _roundId) {
        require(rounds[_roundId].status == RoundStatus.CANCELLED);
        _;
    }

    modifier roundIsRunning(uint16 _roundId) {
        require(rounds[_roundId].status == RoundStatus.RUNNING);
        _;
    }

    modifier roundIsFinish(uint16 _roundId) {
        require(rounds[_roundId].status == RoundStatus.FINISHED);
        _;
    }
}