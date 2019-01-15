pragma solidity ^0.4.24;

/*
*   gibmireinbier
*   0xA4a799086aE18D7db6C4b57f496B081b44888888
*   <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="701719121d190215191e1219150230171d11191c5e131f1d">[email&#160;protected]</a>
*/

interface F2mInterface {
    function joinNetwork(address[6] _contract) public;
    // one time called
    function disableRound0() public;
    function activeBuy() public;
    // Dividends from all sources (DApps, Donate ...)
    function pushDividends() public payable;
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    //function reinvest() public;
    //function buy() public payable;
    function buyFor(address _buyer) public payable;
    function sell(uint256 _tokenAmount) public;
    function exit() public;
    function devTeamWithdraw() public returns(uint256);
    function withdrawFor(address sender) public returns(uint256);
    function transfer(address _to, uint256 _tokenAmount) public returns(bool);
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function setAutoBuy() public;
    /*==========================================
    =            public FUNCTIONS            =
    ==========================================*/
    // function totalEthBalance() public view returns(uint256);
    function ethBalance(address _address) public view returns(uint256);
    function myBalance() public view returns(uint256);
    function myEthBalance() public view returns(uint256);

    function swapToken() public;
    function setNewToken(address _newTokenAddress) public;
}

interface CitizenInterface {
 
    function joinNetwork(address[6] _contract) public;
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function devTeamWithdraw() public;

    /*----------  WRITE FUNCTIONS  ----------*/
    function updateUsername(string _sNewUsername) public;
    //Sources: Token contract, DApps
    function pushRefIncome(address _sender) public payable;
    function withdrawFor(address _sender) public payable returns(uint256);
    function devTeamReinvest() public returns(uint256);

    /*----------  READ FUNCTIONS  ----------*/
    function getRefWallet(address _address) public view returns(uint256);
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

interface BankInterface {
    function joinNetwork(address[6] _contract) public;
    // Core functions
    function pushToBank(address _player) public payable;
}

interface RewardInterface {

    function mintReward(
        address _lucker,
        uint256 curRoundId,
        uint256 _tNumberFrom,
        uint256 _tNumberTo,
        uint256 _value,
        uint256 _rewardType)
        public;
        
    function joinNetwork(address[6] _contract) public;
    function pushBounty(uint256 _curRoundId) public payable;
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
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

contract Lottery {
    using SafeMath for uint256;

    modifier withdrawRight(){
        require(msg.sender == address(bankContract), "Bank only");
        _;
    }

    modifier onlyDevTeam() {
        require(msg.sender == devTeam, "only for development team");
        _;
    }

    modifier buyable() {
        require(block.timestamp > round[curRoundId].startTime, "not ready to sell Ticket");
        require(block.timestamp < round[curRoundId].slideEndTime, "round over");
        _;
    }

    enum RewardType {
        Minor,
        Major,
        Grand,
        Bounty
    }

    // 1 buy = 1 slot = _ethAmount => (tAmount, tMul) 
    struct Slot {
        address buyer;
        uint256 rId;
        // ticket numbers in range and unique in all rounds
        uint256 tNumberFrom;
        uint256 tNumberTo;
        // weight to, used for grandPot finalize
        uint256 wTo;
        uint256 ethAmount;
        uint256 salt;
    }

    struct Round {
        // earlyIncome weight sum
        uint256 rEarlyIncomeWeight;
        // blockNumber to get hash as random seed
        uint256 keyBlockNr;
        
        mapping(address => uint256) pTicketSum;
        mapping(address => uint256) pInvestedSum;

        // early income weight by address
        mapping(address => uint256) pEarlyIncomeWeight;
        mapping(address => uint256) pEarlyIncomeCredit;
        mapping(address => uint256) pEarlyIncomeClaimed;
        // early income per weight
        uint256 ppw;
        // endTime increased every slot sold
        // endTime limited by fixedEndTime
        uint256 startTime;
        uint256 slideEndTime;
        uint256 fixedEndTime;

        // ticketSum from round 1 to this round
        uint256 ticketSum;
        // investedSum from round 1 to this round
        uint256 investedSum;
        // number of slots from round 1 to this round
        uint256 slotSum;
    }

    // round started with this grandPot amount,
    // used to calculate the rate for grandPot results
    // init in roundInit function
    uint256 initGrandPot;

    Slot[] slot;
    // slotId logs by address
    mapping( address => uint256[]) pSlot;
    mapping( address => uint256) public pSlotSum;

    // logs by address
    mapping( address => uint256) public pTicketSum;
    mapping( address => uint256) public pInvestedSum;

    CitizenInterface public citizenContract;
    F2mInterface public f2mContract;
    BankInterface public bankContract;
    RewardInterface public rewardContract;

    address public devTeam;

    uint256 constant public ZOOM = 1000;
    uint256 constant public ONE_HOUR = 60 * 60;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR;
    uint256 constant public TIMEOUT0 = 3 * ONE_HOUR;
    uint256 constant public TIMEOUT1 = 12 * ONE_HOUR;
    uint256 constant public TIMEOUT2 = 7 * ONE_DAY;
    uint256 constant public FINALIZE_WAIT_DURATION = 60; // 60 Seconds
    uint256 constant public NEWROUND_WAIT_DURATION = ONE_DAY; // 24 Hours

    // 15 seconds on Ethereum, 12 seconds used instead to make sure blockHash unavaiable
    // when slideEndTime reached
    // keyBlockNumber will be estimated again after every slot buy
    uint256 constant public BLOCK_TIME = 12;
    uint256 constant public MAX_BLOCK_DISTANCE = 254;

    uint256 constant public MAJOR_RATE = 1000;
    uint256 constant public MINOR_RATE = 1000;
    uint256 constant public MAJOR_MIN = 0.1 ether ;
    uint256 constant public MINOR_MIN = 0.1 ether ;

    //uint256 public toNextPotPercent = 27;
    uint256 public grandRewardPercent = 20;
    uint256 public jRewardPercent = 60;

    uint256 public toTokenPercent = 12; // 10% dividends 2% fund
    uint256 public toBuyTokenPercent = 1;
    uint256 public earlyIncomePercent = 22;
    uint256 public toRefPercent = 15;

    // sum == 100% = toPotPercent/100 * investedSum
    // uint256 public grandPercent = 68;
    uint256 public majorPercent = 24;
    uint256 public minorPercent = 8;

    uint256 public grandPot;
    uint256 public majorPot;
    uint256 public minorPot;

    uint256 public curRoundId;
    uint256 public lastRoundId = 88888888;

    uint256 constant public startPrice = 0.002 ether;

    mapping (address => uint256) public rewardBalance;
    // used to save gas on earlyIncome calculating, curRoundId never included
    // only earlyIncome from round 1st to curRoundId-1 are fixed
    mapping (address => uint256) public lastWithdrawnRound;
    mapping (address => uint256) public earlyIncomeScannedSum;

    mapping (uint256 => Round) public round;

    // Current Round

    // first SlotId in last Block to fire jackpot
    uint256 public jSlot;
    // jackpot results of all slots in same block will be drawed at the same time,
    // by player, who buys the first slot in next block
    uint256 public lastBlockNr;
    // used to calculate grandPot results
    uint256 public curRWeight;
    // added by slot salt after every slot buy
    // does not matter with overflow
    uint256 public curRSalt;
    // ticket sum of current round
    uint256 public curRTicketSum;

    constructor (address _devTeam)
        public
    {
        // register address in network
        DevTeamInterface(_devTeam).setLotteryAddress(address(this));
        devTeam = _devTeam;
    }

    // _contract = [f2mAddress, bankAddress, citizenAddress, lotteryAddress, rewardAddress, whitelistAddress];
    function joinNetwork(address[6] _contract)
        public
    {
        require(address(citizenContract) == 0x0,"already setup");
        f2mContract = F2mInterface(_contract[0]);
        bankContract = BankInterface(_contract[1]);
        citizenContract = CitizenInterface(_contract[2]);
        //lotteryContract = LotteryInterface(lotteryAddress);
        rewardContract = RewardInterface(_contract[4]);
    }

    function activeFirstRound()
        public
        onlyDevTeam()
    {
        require(curRoundId == 0, "already activated");
        initRound();
    }

    // Core Functions

    function pushToPot() 
        public 
        payable
    {
        addPot(msg.value);
    }

    function checkpoint() 
        private
    {
        // dummy slot between every 2 rounds
        // dummy slot never win jackpot cause of min 0.1 ETH
        Slot memory _slot;
        _slot.tNumberTo = round[curRoundId].ticketSum;
        slot.push(_slot);

        Round memory _round;
        _round.startTime = NEWROUND_WAIT_DURATION.add(block.timestamp);
        // started with 3 hours timeout
        _round.slideEndTime = TIMEOUT0 + _round.startTime;
        _round.fixedEndTime = TIMEOUT2 + _round.startTime;
        _round.keyBlockNr = genEstKeyBlockNr(_round.slideEndTime);
        _round.ticketSum = round[curRoundId].ticketSum;
        _round.investedSum = round[curRoundId].investedSum;
        _round.slotSum = slot.length;

        curRoundId = curRoundId + 1;
        round[curRoundId] = _round;

        initGrandPot = grandPot;
        curRWeight = 0;
        curRTicketSum = 0;
    }

    // from round 18+ function
    function isLastRound()
        public
        view
        returns(bool)
    {
        return (curRoundId == lastRoundId);
    }

    function goNext()
        private
    {
        uint256 _totalPot = getTotalPot();
        grandPot = 0;
        majorPot = 0;
        minorPot = 0;
        f2mContract.pushDividends.value(_totalPot)();
        // never start
        round[curRoundId].startTime = block.timestamp * 10;
        round[curRoundId].slideEndTime = block.timestamp * 10 + 1;
    }

    function initRound()
        private
    {
        // update all Round Log
        checkpoint();
        if (isLastRound()) goNext();
    }

    function finalizeable() 
        public
        view
        returns(bool)
    {
        uint256 finalizeTime = FINALIZE_WAIT_DURATION.add(round[curRoundId].slideEndTime);
        if (finalizeTime > block.timestamp) return false; // too soon to finalize
        if (getEstKeyBlockNr(curRoundId) >= block.number) return false; //block hash not exist
        return curRoundId > 0;
    }

    // bounty
    function finalize()
        public
    {
        require(finalizeable(), "Not ready to draw results");
        // avoid txs blocked => curRTicket ==0 => die
        require((round[curRoundId].pTicketSum[msg.sender] > 0) || (curRTicketSum == 0), "must buy at least 1 ticket");
        endRound(msg.sender);
        initRound();
    }

    function mintReward(
        address _lucker,
        uint256 _slotId,
        uint256 _value,
        RewardType _rewardType)
        private
    {
        // add reward balance
        rewardBalance[_lucker] = rewardBalance[_lucker].add(_value);
        // reward log
        rewardContract.mintReward(
            _lucker,
            curRoundId,
            slot[_slotId].tNumberFrom,
            slot[_slotId].tNumberTo,
            _value,
            uint256(_rewardType)
        );
    }

    function jackpot()
        private
    {
        // get blocknumber to get blockhash
        uint256 keyBlockNr = getKeyBlockNr(lastBlockNr);//block.number;
        // salt not effected by jackpot, too risk
        uint256 seed = getSeed(keyBlockNr);
        // slot numberic from 1 ... totalSlot(round)
        // jackpot for all slot in last block, jSlot <= i <= lastSlotId (=slotSum - 1)
        // _to = first Slot in new block
        //uint256 _to = round[curRoundId].slotSum;

        uint256 jReward;
        uint256 toF2mAmount;
        address winner;
        // jackpot check for slots in last block
        while (jSlot + 1 < round[curRoundId].slotSum) {
            // majorPot
            if ((seed % MAJOR_RATE == 6) &&
                (slot[jSlot].ethAmount >= MAJOR_MIN)) {

                winner = slot[jSlot].buyer;
                jReward = majorPot / 100 * jRewardPercent;
                mintReward(winner, jSlot, jReward, RewardType.Major);
                toF2mAmount = majorPot / 100 * toTokenPercent;
                f2mContract.pushDividends.value(toF2mAmount)();
                majorPot = majorPot - jReward - toF2mAmount;
            }

            // minorPot
            if (((seed + jSlot) % MINOR_RATE == 8) && 
                (slot[jSlot].ethAmount >= MINOR_MIN)) {

                winner = slot[jSlot].buyer;
                jReward = minorPot / 100 * jRewardPercent;
                mintReward(winner, jSlot, jReward, RewardType.Minor);
                toF2mAmount = minorPot / 100 * toTokenPercent;
                f2mContract.pushDividends.value(toF2mAmount)();
                minorPot = minorPot - jReward - toF2mAmount;
            }
            seed = seed + 1;
            jSlot = jSlot + 1;
        }
    }

    function endRound(address _bountyHunter)
        private
    {
        uint256 _rId = curRoundId;
        uint256 keyBlockNr = getKeyBlockNr(round[_rId].keyBlockNr);
        uint256 _seed = getSeed(keyBlockNr) + curRSalt;
        uint256 onePercent = grandPot / 100;
        uint256 rGrandReward = onePercent * grandRewardPercent;

        //PUSH DIVIDENDS
        uint256 toF2mAmount = onePercent * toTokenPercent;
        //uint256 _bountyAmount = onePercent * bountyPercent;
        
        grandPot = grandPot - toF2mAmount - onePercent;
        f2mContract.pushDividends.value(toF2mAmount)();

        // base on grand-intestedSum current grandPot
        uint256 weightRange = getWeightRange();

        // roll 3 turns
        for (uint256 i = 0; i < 3; i++){
            uint256 winNr = Helper.getRandom(_seed, weightRange);
            // if winNr > curRoundWeight => no winner this turn
            // win Slot : fromWeight <= winNr <= toWeight
            // got winner this rolling turn
            if (winNr <= curRWeight) {
                grandPot -= rGrandReward;
                uint256 _winSlot = getWinSlot(winNr);
                address _winner = slot[_winSlot].buyer;
                mintReward(_winner, _winSlot, rGrandReward, RewardType.Grand);
                _seed = _seed + (_seed / 10);
            }
        }
        mintReward(_bountyHunter, 0, onePercent * 3 / 10, RewardType.Bounty);
        rewardContract.pushBounty.value(onePercent * 7 / 10)(curRoundId);
    }

    function buy(string _sSalt)
        public
        payable
    {
        buyFor(_sSalt, msg.sender);
    }

    function updateInvested(address _buyer, uint256 _ethAmount)
        private
    {
        round[curRoundId].investedSum += _ethAmount;
        round[curRoundId].pInvestedSum[_buyer] += _ethAmount;
        pInvestedSum[_buyer] += _ethAmount;
    }

    function updateTicketSum(address _buyer, uint256 _tAmount)
        private
    {
        round[curRoundId].ticketSum = round[curRoundId].ticketSum + _tAmount;
        round[curRoundId].pTicketSum[_buyer] = round[curRoundId].pTicketSum[_buyer] + _tAmount;
        curRTicketSum = curRTicketSum + _tAmount;
        pTicketSum[_buyer] = pTicketSum[_buyer] + _tAmount;
    }

    function updateEarlyIncome(address _buyer, uint256 _pWeight)
        private
    {
        round[curRoundId].rEarlyIncomeWeight = _pWeight.add(round[curRoundId].rEarlyIncomeWeight);
        round[curRoundId].pEarlyIncomeWeight[_buyer] = _pWeight.add(round[curRoundId].pEarlyIncomeWeight[_buyer]);
        round[curRoundId].pEarlyIncomeCredit[_buyer] = round[curRoundId].pEarlyIncomeCredit[_buyer].add(_pWeight.mul(round[curRoundId].ppw));
    }

    function buyFor(string _sSalt, address _sender) 
        public
        payable
        buyable()
    {
        uint256 _salt = Helper.stringToUint(_sSalt);
        uint256 _ethAmount = msg.value;
        uint256 _ticketSum = curRTicketSum;
        require(_ethAmount >= Helper.getTPrice(_ticketSum), "not enough to buy 1 ticket");

        // investedSum logs
        updateInvested(_sender, _ethAmount);
        // update salt
        curRSalt = curRSalt + _salt;
        // init new Slot, Slot Id = 1..curRSlotSum
        Slot memory _slot;
        _slot.rId = curRoundId;
        _slot.buyer = _sender;
        _slot.ethAmount = _ethAmount;
        _slot.salt = _salt;
        uint256 _tAmount = Helper.getTAmount(_ethAmount, _ticketSum);
        uint256 _tMul = Helper.getTMul(_ticketSum);
        uint256 _pMul = Helper.getEarlyIncomeMul(_ticketSum);
        uint256 _pWeight = _pMul.mul(_tAmount);
        uint256 _toAddTime = Helper.getAddedTime(_ticketSum, _tAmount);
        addTime(curRoundId, _toAddTime);

        // update weight
        uint256 _slotWeight = (_tAmount).mul(_tMul);
        curRWeight = curRWeight.add(_slotWeight);
        _slot.wTo = curRWeight;
        uint256 lastSlot = slot.length - 1;
        // update ticket params
        _slot.tNumberFrom = slot[lastSlot].tNumberTo + 1;
        _slot.tNumberTo = slot[lastSlot].tNumberTo + _tAmount;
        updateTicketSum(_sender, _tAmount);

        // EarlyIncome Weight
        // ppw and credit zoomed x1000
        // earlyIncome mul of each ticket in this slot
        updateEarlyIncome(_sender, _pWeight);
     
        // add Slot and update round data
        slot.push(_slot);
        round[curRoundId].slotSum = slot.length;
        // add slot to player logs
        pSlot[_sender].push(slot.length - 1);

        // first slot in this block draw jacpot results for 
        // all slot in last block
        if (lastBlockNr != block.number) {
            jackpot();
            lastBlockNr = block.number;
        }

        distributeSlotBuy(_sender, curRoundId, _ethAmount);

        round[curRoundId].keyBlockNr = genEstKeyBlockNr(round[curRoundId].slideEndTime);
    }

    function distributeSlotBuy(address _sender, uint256 _rId, uint256 _ethAmount)
        private
    {
        uint256 onePercent = _ethAmount / 100;
        uint256 toF2mAmount = onePercent * toTokenPercent; // 12
        uint256 toRefAmount = onePercent * toRefPercent; // 10
        uint256 toBuyTokenAmount = onePercent * toBuyTokenPercent; //1
        uint256 earlyIncomeAmount = onePercent * earlyIncomePercent; //27
        uint256 taxAmount = toF2mAmount + toRefAmount + toBuyTokenAmount + earlyIncomeAmount; // 50
        uint256 taxedEthAmount = _ethAmount.sub(taxAmount); // 50
        addPot(taxedEthAmount);
        
        // 10% Ref
        citizenContract.pushRefIncome.value(toRefAmount)(_sender);
        // 2% Fund + 10% Dividends 
        f2mContract.pushDividends.value(toF2mAmount)();
        // 1% buy Token
        f2mContract.buyFor.value(toBuyTokenAmount)(_sender);
        // 27% Early
        uint256 deltaPpw = (earlyIncomeAmount * ZOOM).div(round[_rId].rEarlyIncomeWeight);
        round[_rId].ppw = deltaPpw.add(round[_rId].ppw);
    }

    function claimEarlyIncomebyAddress(address _buyer)
        private
    {
        if (curRoundId == 0) return;
        claimEarlyIncomebyAddressRound(_buyer, curRoundId);
        uint256 _rId = curRoundId - 1;
        while ((_rId > lastWithdrawnRound[_buyer]) && (_rId + 20 > curRoundId)) {
            earlyIncomeScannedSum[_buyer] += claimEarlyIncomebyAddressRound(_buyer, _rId);
            _rId = _rId - 1;
        }
    }

    function claimEarlyIncomebyAddressRound(address _buyer, uint256 _rId)
        private
        returns(uint256)
    {
        uint256 _amount = getCurEarlyIncomeByAddressRound(_buyer, _rId);
        if (_amount == 0) return 0;
        round[_rId].pEarlyIncomeClaimed[_buyer] = _amount.add(round[_rId].pEarlyIncomeClaimed[_buyer]);
        rewardBalance[_buyer] = _amount.add(rewardBalance[_buyer]);
        return _amount;
    }

    function withdrawFor(address _sender)
        public
        withdrawRight()
        returns(uint256)
    {
        if (curRoundId == 0) return;
        claimEarlyIncomebyAddress(_sender);
        lastWithdrawnRound[_sender] = curRoundId - 1;
        uint256 _amount = rewardBalance[_sender];
        rewardBalance[_sender] = 0;
        bankContract.pushToBank.value(_amount)(_sender);
        return _amount;
    }
    
    function addTime(uint256 _rId, uint256 _toAddTime)
        private
    {
        round[_rId].slideEndTime = Helper.getNewEndTime(_toAddTime, round[_rId].slideEndTime, round[_rId].fixedEndTime);
    }

    // distribute to 3 pots Grand, Majorm Minor
    function addPot(uint256 _amount)
        private
    {
        uint256 onePercent = _amount / 100;
        uint256 toMinor = onePercent * minorPercent;
        uint256 toMajor = onePercent * majorPercent;
        uint256 toGrand = _amount - toMinor - toMajor;

        minorPot = minorPot + toMinor;
        majorPot = majorPot + toMajor;
        grandPot = grandPot + toGrand;
    }


    //////////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////////////////////////////////////////

    function isWinSlot(uint256 _slotId, uint256 _keyNumber)
        public
        view
        returns(bool)
    {
        return (slot[_slotId - 1].wTo < _keyNumber) && (slot[_slotId].wTo >= _keyNumber);
    }

    function getWeightRange()
        public
        view
        returns(uint256)
    {
        return Helper.getWeightRange(grandPot, initGrandPot, curRWeight);
    }

    function getWinSlot(uint256 _keyNumber)
        public
        view
        returns(uint256)
    {
        // return 0 if not found
        uint256 _to = slot.length - 1;
        uint256 _from = round[curRoundId-1].slotSum + 1; // dummy slot ignore
        uint256 _pivot;
        //Slot memory _slot;
        uint256 _pivotWTo;
        // Binary search
        while (_from <= _to) {
            _pivot = (_from + _to) / 2;
            //_slot = round[_rId].slot[_pivot];
            _pivotWTo = slot[_pivot].wTo;
            if (isWinSlot(_pivot, _keyNumber)) return _pivot;
            if (_pivotWTo < _keyNumber) { // in right side
                _from = _pivot + 1;
            } else { // in left side
                _to = _pivot - 1;
            }
        }
        return _pivot; // never happens or smt gone wrong
    }

    // Key Block in future
    function genEstKeyBlockNr(uint256 _endTime) 
        public
        view
        returns(uint256)
    {
        if (block.timestamp >= _endTime) return block.number + 8; 
        uint256 timeDist = _endTime - block.timestamp;
        uint256 estBlockDist = timeDist / BLOCK_TIME;
        return block.number + estBlockDist + 8;
    }

    // get block hash of first block with blocktime > _endTime
    function getSeed(uint256 _keyBlockNr)
        public
        view
        returns (uint256)
    {
        // Key Block not mined atm
        if (block.number <= _keyBlockNr) return block.number;
        return uint256(blockhash(_keyBlockNr));
    }

    // current reward balance
    function getRewardBalance(address _buyer)
        public
        view
        returns(uint256)
    {
        return rewardBalance[_buyer];
    } 

    // GET endTime
    function getSlideEndTime(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return(round[_rId].slideEndTime);
    }

    function getFixedEndTime(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return(round[_rId].fixedEndTime);
    }

    function getTotalPot()
        public
        view
        returns(uint256)
    {
        return grandPot + majorPot + minorPot;
    }

    // EarlyIncome
    function getEarlyIncomeByAddress(address _buyer)
        public
        view
        returns(uint256)
    {
        uint256 _sum = earlyIncomeScannedSum[_buyer];
        uint256 _fromRound = lastWithdrawnRound[_buyer] + 1; // >=1
        if (_fromRound + 100 < curRoundId) _fromRound = curRoundId - 100;
        uint256 _rId = _fromRound;
        while (_rId <= curRoundId) {
            _sum = _sum + getEarlyIncomeByAddressRound(_buyer, _rId);
            _rId++;
        }
        return _sum;
    }

    // included claimed amount
    function getEarlyIncomeByAddressRound(address _buyer, uint256 _rId)
        public
        view
        returns(uint256)
    {
        uint256 _pWeight = round[_rId].pEarlyIncomeWeight[_buyer];
        uint256 _ppw = round[_rId].ppw;
        uint256 _rCredit = round[_rId].pEarlyIncomeCredit[_buyer];
        uint256 _rEarlyIncome = ((_ppw.mul(_pWeight)).sub(_rCredit)).div(ZOOM);
        return _rEarlyIncome;
    }

    function getCurEarlyIncomeByAddress(address _buyer)
        public
        view
        returns(uint256)
    {
        uint256 _sum = 0;
        uint256 _fromRound = lastWithdrawnRound[_buyer] + 1; // >=1
        if (_fromRound + 100 < curRoundId) _fromRound = curRoundId - 100;
        uint256 _rId = _fromRound;
        while (_rId <= curRoundId) {
            _sum = _sum.add(getCurEarlyIncomeByAddressRound(_buyer, _rId));
            _rId++;
        }
        return _sum;
    }

    function getCurEarlyIncomeByAddressRound(address _buyer, uint256 _rId)
        public
        view
        returns(uint256)
    {
        uint256 _rEarlyIncome = getEarlyIncomeByAddressRound(_buyer, _rId);
        return _rEarlyIncome.sub(round[_rId].pEarlyIncomeClaimed[_buyer]);
    }

    ////////////////////////////////////////////////////////////////////

    function getEstKeyBlockNr(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return round[_rId].keyBlockNr;
    }

    function getKeyBlockNr(uint256 _estKeyBlockNr)
        public
        view
        returns(uint256)
    {
        require(block.number > _estKeyBlockNr, "blockHash not avaiable");
        uint256 jump = (block.number - _estKeyBlockNr) / MAX_BLOCK_DISTANCE * MAX_BLOCK_DISTANCE;
        return _estKeyBlockNr + jump;
    }

    // Logs
    function getCurRoundId()
        public
        view
        returns(uint256)
    {
        return curRoundId;
    }

    function getTPrice()
        public
        view
        returns(uint256)
    {
        return Helper.getTPrice(curRTicketSum);
    }

    function getTMul()
        public
        view
        returns(uint256)
    {
        return Helper.getTMul(curRTicketSum);
    }

    function getPMul()
        public
        view
        returns(uint256)
    {
        return Helper.getEarlyIncomeMul(curRTicketSum);
    }

    function getPTicketSumByRound(uint256 _rId, address _buyer)
        public
        view
        returns(uint256)
    {
        return round[_rId].pTicketSum[_buyer];
    }

    function getTicketSumToRound(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return round[_rId].ticketSum;
    }

    function getPInvestedSumByRound(uint256 _rId, address _buyer)
        public
        view
        returns(uint256)
    {
        return round[_rId].pInvestedSum[_buyer];
    }

    function getInvestedSumToRound(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return round[_rId].investedSum;
    }

    function getPSlotLength(address _sender)
        public
        view
        returns(uint256)
    {
        return pSlot[_sender].length;
    }

    function getSlotLength()
        public
        view
        returns(uint256)
    {
        return slot.length;
    }

    function getSlotId(address _sender, uint256 i)
        public
        view
        returns(uint256)
    {
        return pSlot[_sender][i];
    }

    function getSlotInfo(uint256 _slotId)
        public
        view
        returns(address, uint256[4], string)
    {
        Slot memory _slot = slot[_slotId];
        return (_slot.buyer,[_slot.rId, _slot.tNumberFrom, _slot.tNumberTo, _slot.ethAmount], Helper.uintToString(_slot.salt));
    }

    function cashoutable(address _address) 
        public
        view
        returns(bool)
    {
        // need 1 ticket or in waiting time to start new round
        return (round[curRoundId].pTicketSum[_address] > 0) || (round[curRoundId].startTime > block.timestamp);
    }

    // set endRound, prepare to upgrade new version
    function setLastRound(uint256 _lastRoundId) 
        public
        onlyDevTeam()
    {
        require(_lastRoundId >= 18 && _lastRoundId > curRoundId, "too early to end");
        require(lastRoundId == 88888888, "already set");
        lastRoundId = _lastRoundId;
    }
}