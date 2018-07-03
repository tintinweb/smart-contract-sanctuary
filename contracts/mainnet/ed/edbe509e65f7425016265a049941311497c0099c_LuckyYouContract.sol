pragma solidity ^0.4.18;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Resume();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to resume, returns to normal state
     */
    function resume() onlyOwner whenPaused public {
        paused = false;
        emit Resume();
    }
}

contract LuckyYouTokenInterface {
    function airDrop(address _to, uint256 _value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);
}

contract LuckyYouContract is Pausable {
    using SafeMath for uint256;
    LuckyYouTokenInterface public luckyYouToken = LuckyYouTokenInterface(0x6D7efEB3DF42e6075fa7Cf04E278d2D69e26a623); //LKY token address
    bool public airDrop = true;// weather airdrop LKY tokens to participants or not,owner can set it to true or false;

    //set airDrop flag
    function setAirDrop(bool _airDrop) public onlyOwner {
        airDrop = _airDrop;
    }

    //if airdrop LKY token to participants , this is airdrop rate per round depends on participated times, owner can set it
    uint public baseTokenGetRate = 100;

    // set token get rate
    function setBaseTokenGetRate(uint _baseTokenGetRate) public onlyOwner {
        baseTokenGetRate = _baseTokenGetRate;
    }

    //if the number of participants less than  minParticipants,game will not be fired.owner can set it
    uint public minParticipants = 50;

    function setMinParticipants(uint _minParticipants) public onlyOwner {
        minParticipants = _minParticipants;
    }

    //base price ,owner can set it
    uint public basePrice = 0.01 ether;

    function setBasePrice(uint _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    uint[5] public times = [1, 5, 5 * 5, 5 * 5 * 5, 5 * 5 * 5 * 5];//1x=0.01 ether;5x=0.05 ether; 5*5x=0.25 ether; 5*5*5x=1.25 ether; 5*5*5*5x=6.25 ether;
    //at first only enable 1x(0.02ether) ,enable others proper time in future
    bool[5] public timesEnabled = [true, false, false, false, false];

    uint[5] public currentCounter = [1, 1, 1, 1, 1];
    mapping(address => uint[5]) public participatedCounter;
    mapping(uint8 => address[]) private participants;
    //todo
    mapping(uint8 => uint256) public participantsCount;
    mapping(uint8 => uint256) public fundShareLastRound;
    mapping(uint8 => uint256) public fundCurrentRound;
    mapping(uint8 => uint256) public fundShareRemainLastRound;
    mapping(uint8 => uint256) public fundShareParticipantsTotalTokensLastRound;
    mapping(uint8 => uint256) public fundShareParticipantsTotalTokensCurrentRound;
    mapping(uint8 => bytes32) private participantsHashes;

    mapping(uint8 => uint8) private lastFiredStep;
    mapping(uint8 => address) public lastWinner;
    mapping(uint8 => address) public lastFiredWinner;
    mapping(uint8 => uint256) public lastWinnerReward;
    mapping(uint8 => uint256) public lastFiredWinnerReward;
    mapping(uint8 => uint256) public lastFiredFund;
    mapping(address => uint256) public whitelist;
    uint256 public notInWhitelistAllow = 1;

    bytes32  private commonHash = 0x1000;

    uint256 public randomNumberIncome = 0;

    event Winner1(address value, uint times, uint counter, uint256 reward);
    event Winner2(address value, uint times, uint counter, uint256 reward);


    function setNotInWhitelistAllow(uint _value) public onlyOwner
    {
        notInWhitelistAllow = _value;
    }

    function setWhitelist(uint _value,address [] _addresses) public onlyOwner
    {
        uint256 count = _addresses.length;
        for (uint256 i = 0; i < count; i++) {
            whitelist[_addresses [i]] = _value;
        }
    }

    function setTimesEnabled(uint8 _timesIndex, bool _enabled) public onlyOwner
    {
        require(_timesIndex < timesEnabled.length);
        timesEnabled[_timesIndex] = _enabled;
    }

    function() public payable whenNotPaused {

        if(whitelist[msg.sender] | notInWhitelistAllow > 0)
        {
            uint8 _times_length = uint8(times.length);
            uint8 _times = _times_length + 1;
            for (uint32 i = 0; i < _times_length; i++)
            {
                if (timesEnabled[i])
                {
                    if (times[i] * basePrice == msg.value) {
                        _times = uint8(i);
                        break;
                    }
                }
            }
            if (_times > _times_length) {
                revert();
            }
            else
            {
                if (participatedCounter[msg.sender][_times] < currentCounter[_times])
                {
                    participatedCounter[msg.sender][_times] = currentCounter[_times];
                    if (airDrop)
                    {
                        uint256 _value = baseTokenGetRate * 10 ** 18 * times[_times];
                        uint256 _plus_value = uint256(keccak256(now, msg.sender)) % _value;
                        luckyYouToken.airDrop(msg.sender, _value + _plus_value);
                    }
                    uint256 senderBalance = luckyYouToken.balanceOf(msg.sender);
                    if (lastFiredStep[_times] > 0)
                    {
                        issueLottery(_times);
                        fundShareParticipantsTotalTokensCurrentRound[_times] += senderBalance;
                        senderBalance = senderBalance.mul(2);
                    } else
                    {
                        fundShareParticipantsTotalTokensCurrentRound[_times] += senderBalance;
                    }
                    if (participantsCount[_times] == participants[_times].length)
                    {
                        participants[_times].length += 1;
                    }
                    participants[_times][participantsCount[_times]++] = msg.sender;
                    participantsHashes[_times] = keccak256(msg.sender, uint256(commonHash));
                    commonHash = keccak256(senderBalance,commonHash);
                    fundCurrentRound[_times] += times[_times] * basePrice;

                    //share last round fund
                    if (fundShareRemainLastRound[_times] > 0)
                    {
                        uint256 _shareFund = fundShareLastRound[_times].mul(senderBalance).div(fundShareParticipantsTotalTokensLastRound[_times]);
                        if(_shareFund  > 0)
                        {
                            if (_shareFund <= fundShareRemainLastRound[_times]) {
                                fundShareRemainLastRound[_times] -= _shareFund;
                                msg.sender.transfer(_shareFund);
                            } else {
                                uint256 _fundShareRemain = fundShareRemainLastRound[_times];
                                fundShareRemainLastRound[_times] = 0;
                                msg.sender.transfer(_fundShareRemain);
                            }
                        }
                    }

                    if (participantsCount[_times] > minParticipants)
                    {
                        if (uint256(keccak256(now, msg.sender, commonHash)) % (minParticipants * minParticipants) < minParticipants)
                        {
                            fireLottery(_times);
                        }

                    }
                } else
                {
                    revert();
                }
            }
        }else{
            revert();
        }
    }

    function issueLottery(uint8 _times) private {
        uint256 _totalFundRate = lastFiredFund[_times].div(100);
        if (lastFiredStep[_times] == 1) {
            fundShareLastRound[_times] = _totalFundRate.mul(30) + fundShareRemainLastRound[_times];
            if (randomNumberIncome > 0)
            {
                if (_times == (times.length - 1) || timesEnabled[_times + 1] == false)
                {
                    fundShareLastRound[_times] += randomNumberIncome;
                    randomNumberIncome = 0;
                }
            }
            fundShareRemainLastRound[_times] = fundShareLastRound[_times];
            fundShareParticipantsTotalTokensLastRound[_times] = fundShareParticipantsTotalTokensCurrentRound[_times];
            fundShareParticipantsTotalTokensCurrentRound[_times] = 0;
            if(fundShareParticipantsTotalTokensLastRound[_times] == 0)
            {
                fundShareParticipantsTotalTokensLastRound[_times] = 10000 * 10 ** 18;
            }
            lastFiredStep[_times]++;
        } else if (lastFiredStep[_times] == 2) {
            lastWinner[_times].transfer(_totalFundRate.mul(65));
            lastFiredStep[_times]++;
            lastWinnerReward[_times] = _totalFundRate.mul(65);
            emit Winner1(lastWinner[_times], _times, currentCounter[_times] - 1, _totalFundRate.mul(65));
        } else if (lastFiredStep[_times] == 3) {
            if (lastFiredFund[_times] > (_totalFundRate.mul(30) + _totalFundRate.mul(4) + _totalFundRate.mul(65)))
            {
                owner.transfer(lastFiredFund[_times] - _totalFundRate.mul(30) - _totalFundRate.mul(4) - _totalFundRate.mul(65));
            }
            lastFiredStep[_times] = 0;
        }
    }

    function fireLottery(uint8 _times) private {
        lastFiredFund[_times] = fundCurrentRound[_times];
        fundCurrentRound[_times] = 0;
        lastWinner[_times] = participants[_times][uint256(participantsHashes[_times]) % participantsCount[_times]];
        participantsCount[_times] = 0;
        uint256 winner2Reward = lastFiredFund[_times].div(100).mul(4);
        msg.sender.transfer(winner2Reward);
        lastFiredWinner[_times] = msg.sender;
        lastFiredWinnerReward[_times] = winner2Reward;
        emit Winner2(msg.sender, _times, currentCounter[_times], winner2Reward);
        lastFiredStep[_times] = 1;
        currentCounter[_times]++;
    }

    function _getRandomNumber(uint _round) view private returns (uint256){
        return uint256(keccak256(
                participantsHashes[0],
                participantsHashes[1],
                participantsHashes[2],
                participantsHashes[3],
                participantsHashes[4],
                msg.sender
            )) % _round;
    }

    function getRandomNumber(uint _round) public payable returns (uint256){
        uint256 tokenBalance = luckyYouToken.balanceOf(msg.sender);
        if (tokenBalance >= 100000 * 10 ** 18)
        {
            return _getRandomNumber(_round);
        } else if (msg.value >= basePrice) {
            randomNumberIncome += msg.value;
            return _getRandomNumber(_round);
        } else {
            revert();
            return 0;
        }
    }
    //in case some bugs
    function kill() public {//for test
        if (msg.sender == owner)
        {
            selfdestruct(owner);
        }
    }
}