pragma solidity ^0.4.24;

/*
*   gibmireinbier
*   0xA4a799086aE18D7db6C4b57f496B081b44888888
*   <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9cfbf5fef1f5eef9f5f2fef5f9eedcfbf1fdf5f0b2fff3f1">[email&#160;protected]</a>
*/

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Helper {
    using SafeMath for uint256;

    uint256 constant public ZOOM = 1000;
    uint256 constant public SDIVIDER = 3450000;
    uint256 constant public PDIVIDER = 3450000;
    uint256 constant public RDIVIDER = 1580000;
    // Starting LS price (SLP)
    uint256 constant public SLP = 0.002 ether;
    // Starting Added Time (SAT)
    uint256 constant public SAT = 30; // seconds
    // Price normalization (PN)
    uint256 constant public PN = 777;
    // EarlyIncome base
    uint256 constant public PBASE = 13;
    uint256 constant public PMULTI = 26;
    uint256 constant public LBase = 15;

    uint256 constant public ONE_HOUR = 3600;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR;
    //uint256 constant public TIMEOUT0 = 3 * ONE_HOUR;
    uint256 constant public TIMEOUT1 = 12 * ONE_HOUR;
    
    function bytes32ToString (bytes32 data)
        public
        pure
        returns (string) 
    {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
    
    function uintToBytes32(uint256 n)
        public
        pure
        returns (bytes32) 
    {
        return bytes32(n);
    }
    
    function bytes32ToUint(bytes32 n) 
        public
        pure
        returns (uint256) 
    {
        return uint256(n);
    }
    
    function stringToBytes32(string memory source) 
        public
        pure
        returns (bytes32 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function stringToUint(string memory source) 
        public
        pure
        returns (uint256)
    {
        return bytes32ToUint(stringToBytes32(source));
    }
    
    function uintToString(uint256 _uint) 
        public
        pure
        returns (string)
    {
        return bytes32ToString(uintToBytes32(_uint));
    }

/*     
    function getSlice(uint256 begin, uint256 end, string text) public pure returns (string) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i = 0; i <= end - begin; i++){
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);    
    }
 */
    function validUsername(string _username)
        public
        pure
        returns(bool)
    {
        uint256 len = bytes(_username).length;
        // Im Raum [4, 18]
        if ((len < 4) || (len > 18)) return false;
        // Letzte Char != &#39; &#39;
        if (bytes(_username)[len-1] == 32) return false;
        // Erste Char != &#39;0&#39;
        return uint256(bytes(_username)[0]) != 48;
    }

    // Lottery Helper

    // Seconds added per LT = SAT - ((Current no. of LT + 1) / SDIVIDER)^6
    function getAddedTime(uint256 _rTicketSum, uint256 _tAmount)
        public
        pure
        returns (uint256)
    {
        //Luppe = 10000 = 10^4
        uint256 base = (_rTicketSum + 1).mul(10000) / SDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo); // ^3
        expo = expo.mul(expo); // ^6
        // div 10000^6
        expo = expo / (10**24);

        if (expo > SAT) return 0;
        return (SAT - expo).mul(_tAmount);
    }

    function getNewEndTime(uint256 toAddTime, uint256 slideEndTime, uint256 fixedEndTime)
        public
        view
        returns(uint256)
    {
        uint256 _slideEndTime = (slideEndTime).add(toAddTime);
        uint256 timeout = _slideEndTime.sub(block.timestamp);
        // timeout capped at TIMEOUT1
        if (timeout > TIMEOUT1) timeout = TIMEOUT1;
        _slideEndTime = (block.timestamp).add(timeout);
        // Capped at fixedEndTime
        if (_slideEndTime > fixedEndTime)  return fixedEndTime;
        return _slideEndTime;
    }

    // get random in range [1, _range] with _seed
    function getRandom(uint256 _seed, uint256 _range)
        public
        pure
        returns(uint256)
    {
        if (_range == 0) return _seed;
        return (_seed % _range) + 1;
    }


    function getEarlyIncomeMul(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        // Early-Multiplier = 1 + PBASE / (1 + PMULTI * ((Current No. of LT)/RDIVIDER)^6)
        uint256 base = _ticketSum * ZOOM / RDIVIDER;
        uint256 expo = base.mul(base).mul(base); //^3
        expo = expo.mul(expo) / (ZOOM**6); //^6
        return (1 + PBASE / (1 + expo.mul(PMULTI)));
    }

    // get reveiced Tickets, based on current round ticketSum
    function getTAmount(uint256 _ethAmount, uint256 _ticketSum) 
        public
        pure
        returns(uint256)
    {
        uint256 _tPrice = getTPrice(_ticketSum);
        return _ethAmount.div(_tPrice);
    }

    // Lotto-Multiplier = 1 + LBase * (Current No. of Tickets / PDivider)^6
    function getTMul(uint256 _ticketSum) // Unit Wei
        public
        pure
        returns(uint256)
    {
        uint256 base = _ticketSum * ZOOM / PDIVIDER;
        uint256 expo = base.mul(base).mul(base);
        expo = expo.mul(expo); // ^6
        return 1 + expo.mul(LBase) / (10**18);
    }

    // get ticket price, based on current round ticketSum
    //unit in ETH, no need / zoom^6
    function getTPrice(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        uint256 base = (_ticketSum + 1).mul(ZOOM) / PDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo); // ^3
        expo = expo.mul(expo); // ^6
        uint256 tPrice = SLP + expo / PN;
        return tPrice;
    }

    // get weight of slot, chance to win grandPot
    function getSlotWeight(uint256 _ethAmount, uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        uint256 _tAmount = getTAmount(_ethAmount, _ticketSum);
        uint256 _tMul = getTMul(_ticketSum);
        return (_tAmount).mul(_tMul);
    }

    // used to draw grandpot results
    // weightRange = roundWeight * grandpot / (grandpot - initGrandPot)
    // grandPot = initGrandPot + round investedSum(for grandPot)
    function getWeightRange(uint256 grandPot, uint256 initGrandPot, uint256 curRWeight)
        public
        pure
        returns(uint256)
    {
        //calculate round grandPot-investedSum
        uint256 grandPotInvest = grandPot - initGrandPot;
        if (grandPotInvest == 0) return 8;
        uint256 zoomMul = grandPot * ZOOM / grandPotInvest;
        uint256 weightRange = zoomMul * curRWeight / ZOOM;
        if (weightRange < curRWeight) weightRange = curRWeight;
        return weightRange;
    }
}

interface DevTeamInterface {
    function setF2mAddress(address _address) public;
    function setLotteryAddress(address _address) public;
    function setCitizenAddress(address _address) public;
    function setBankAddress(address _address) public;
    function setRewardAddress(address _address) public;
    function setWhitelistAddress(address _address) public;

    function setupNetwork() public;
}

interface LotteryInterface {
    function joinNetwork(address[6] _contract) public;
    // call one time
    function activeFirstRound() public;
    // Core Functions
    function pushToPot() public payable;
    function finalizeable() public view returns(bool);
    // bounty
    function finalize() public;
    function buy(string _sSalt) public payable;
    function buyFor(string _sSalt, address _sender) public payable;
    //function withdraw() public;
    function withdrawFor(address _sender) public returns(uint256);

    function getRewardBalance(address _buyer) public view returns(uint256);
    function getTotalPot() public view returns(uint256);
    // EarlyIncome
    function getEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    // included claimed amount
    // function getEarlyIncomeByAddressRound(address _buyer, uint256 _rId) public view returns(uint256);
    function getCurEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    // function getCurEarlyIncomeByAddressRound(address _buyer, uint256 _rId) public view returns(uint256);
    function getCurRoundId() public view returns(uint256);
    // set endRound, prepare to upgrade new version
    function setLastRound(uint256 _lastRoundId) public;
    function getPInvestedSumByRound(uint256 _rId, address _buyer) public view returns(uint256);
    function cashoutable(address _address) public view returns(bool);
    function isLastRound() public view returns(bool);
}

contract Reward {
    using SafeMath for uint256;

    event NewReward(address indexed _lucker, uint256[5] _info);
    
    modifier onlyOwner() {
        require(msg.sender == address(lotteryContract), "This is just log for lottery contract");
        _;
    }

    modifier claimable() {
        require(
            rest > 1 && 
            block.number > lastBlock &&
            lastRoundClaim[msg.sender] < lastRoundId,
            "out of stock in this round, block or already claimed");
        _;
    }

/*     
    enum RewardType {
        Minor, 0
        Major, 1
        Grand, 2
        Bounty 3
        SBounty 4 // smal bounty
    } 
*/

    struct Rewards {
        address lucker;
        uint256 time;
        uint256 rId;
        uint256 value;
        uint256 winNumber;
        uint256 rewardType;
    }

    Rewards[] public rewardList;
    // reward array by address
    mapping( address => uint256[]) public pReward;
    // reward sum by address
    mapping( address => uint256) public pRewardedSum;
    // reward sum by address, round
    mapping( address => mapping(uint256 => uint256)) public pRewardedSumPerRound;
    // reward sum by round
    mapping( uint256 => uint256) public rRewardedSum;
    // reward sum all round, all addresses
    uint256 public rewardedSum;
    
    // last claimed round by address to check timeout
    // timeout balance will be pushed to dividends
    mapping(address => uint256) lastRoundClaim;

    LotteryInterface lotteryContract;

    //////////////////////////////////////////////////////////
    
    // rest times for sBounty, small bountys free for all (round-players) after each round
    uint256 public rest = 0;
    // last block that sBounty claimed, to prevent 2 time claimed in same block
    uint256 public lastBlock = 0;
    // sBounty will be saved in logs of last round
    // new round will be started after sBountys pushed
    uint256 public lastRoundId;

    constructor (address _devTeam)
        public
    {
        // register address in network
        DevTeamInterface(_devTeam).setRewardAddress(address(this));
    }

    // _contract = [f2mAddress, bankAddress, citizenAddress, lotteryAddress, rewardAddress, whitelistAddress];
    function joinNetwork(address[6] _contract)
        public
    {
        require((address(lotteryContract) == 0x0),"already setup");
        lotteryContract = LotteryInterface(_contract[3]);
    }

    // sBounty program
    // rules :
    // 1. accept only eth from lottery contract
    // 2. one claim per block
    // 3. one claim per address (reset each round)

    function getSBounty()
        public
        view
        returns(uint256, uint256, uint256)
    {
        uint256 sBountyAmount = rest < 2 ? 0 : address(this).balance / (rest-1);
        return (rest, sBountyAmount, lastRoundId);
    }

    // pushed from lottery contract only
    function pushBounty(uint256 _curRoundId) 
        public 
        payable 
        onlyOwner() 
    {
        rest = 8;
        lastBlock = block.number;
        lastRoundId = _curRoundId;
    }

    function claim()
        public
        claimable()
    {
        address _sender = msg.sender;
        uint256 rInvested = lotteryContract.getPInvestedSumByRound(lastRoundId, _sender);
        require(rInvested > 0, "sorry, not invested no bounty");
        lastBlock = block.number;
        lastRoundClaim[_sender] = lastRoundId;
        rest = rest - 1;
        uint256 claimAmount = address(this).balance / rest;
        _sender.transfer(claimAmount);
        mintRewardCore(
            _sender,
            lastRoundId,
            0,
            0,
            claimAmount,
            4
        );
    }

    // rewards sealed by lottery contract
    function mintReward(
        address _lucker,
        uint256 _curRoundId,
        uint256 _tNumberFrom,
        uint256 _tNumberTo,
        uint256 _value,
        uint256 _rewardType)
        public
        onlyOwner()
    {
        mintRewardCore(
            _lucker,
            _curRoundId,
            _tNumberFrom,
            _tNumberTo,
            _value,
            _rewardType);
    }

    // reward logs generator
    function mintRewardCore(
        address _lucker,
        uint256 _curRoundId,
        uint256 _tNumberFrom,
        uint256 _tNumberTo,
        uint256 _value,
        uint256 _rewardType)
        private
    {
        Rewards memory _reward;
        _reward.lucker = _lucker;
        _reward.time = block.timestamp;
        _reward.rId = _curRoundId;
        _reward.value = _value;

        // get winning number if rewardType is not bounty or sBounty
        // seed = rewardList.length to be sure that seed changed after
        // every reward minting
        if (_rewardType < 3)
        _reward.winNumber = getWinNumberBySlot(_tNumberFrom, _tNumberTo);

        _reward.rewardType = _rewardType;
        rewardList.push(_reward);
        pReward[_lucker].push(rewardList.length - 1);
        // reward sum logs
        pRewardedSum[_lucker] += _value;
        rRewardedSum[_curRoundId] += _value;
        rewardedSum += _value;
        pRewardedSumPerRound[_lucker][_curRoundId] += _value;
        emit NewReward(_reward.lucker, [_reward.time, _reward.rId, _reward.value, _reward.winNumber, uint256(_reward.rewardType)]);
    }

    function getWinNumberBySlot(uint256 _tNumberFrom, uint256 _tNumberTo)
        public
        view
        returns(uint256)
    {
        //uint256 _seed = uint256(keccak256(rewardList.length));
        uint256 _seed = rewardList.length * block.number + block.timestamp;
        // get random number in range (1, _to - _from + 1)
        uint256 _winNr = Helper.getRandom(_seed, _tNumberTo + 1 - _tNumberFrom);
        return _tNumberFrom + _winNr - 1;
    }

    function getPRewardLength(address _sender)
        public
        view
        returns(uint256)
    {
        return pReward[_sender].length;
    }

    function getRewardListLength()
        public
        view
        returns(uint256)
    {
        return rewardList.length;
    }

    function getPRewardId(address _sender, uint256 i)
        public
        view
        returns(uint256)
    {
        return pReward[_sender][i];
    }

    function getPRewardedSumByRound(uint256 _rId, address _buyer)
        public
        view
        returns(uint256)
    {
        return pRewardedSumPerRound[_buyer][_rId];
    }

    function getRewardedSumByRound(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return rRewardedSum[_rId];
    }

    function getRewardInfo(uint256 _id)
        public
        view
        returns(
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Rewards memory _reward = rewardList[_id];
        return (
            _reward.lucker,
            _reward.winNumber,
            _reward.time,
            _reward.rId,
            _reward.value,
            _reward.rewardType
        );
    }
}