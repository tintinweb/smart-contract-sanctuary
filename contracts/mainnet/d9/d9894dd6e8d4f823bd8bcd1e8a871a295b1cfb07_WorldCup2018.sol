pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
    }

    function getOwner() public view returns(address retOwnerAddress) {
        return owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
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

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}


contract AccessControl is Ownable {
    address private ceoAddress;
    address private cfoAddress;
    address private cooAddress;

    bool private paused = false;

    constructor() public {
        paused = true;

        ceoAddress = getOwner();
        cooAddress = getOwner();
        cfoAddress = getOwner();
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress);
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    function getCFO() public view returns(address retCFOAddress) {
        return cfoAddress;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}


contract Base {
    uint8 constant internal INIT = 0;
    uint8 constant internal WIN = 1;
    uint8 constant internal LOSE = 2;
    uint8 constant internal TIE = 3;
    uint8 constant internal MATCH_CNT = 64;

    struct AccountInfo {
        uint invested;
        uint prize;
        uint claimed;
    }

    struct Match {
        uint8 matchId;
        uint8 hostTeamId;
        uint8 guestTeamId;
        uint startTime;
        uint8 outcome;

        uint totalInvest;

        mapping(address => Better) betters;
        mapping(uint8 => uint) mPredictionInvest;
    }

    struct Better {
        uint invested;
        uint prize;

        mapping(uint8 => uint) bPredictionInvest;
    }

    // 0.001 ETH =< msg.value =< 100 ETH
    modifier validValue() {
        require(msg.value >= 1000000000000000 && msg.value <= 100000000000000000000);
        _;
    }

    // 1-32 teams
    modifier validTeam(uint8 _teamId) {
        require(_teamId > 0 && _teamId < 33);
        _;
    }

    // 1-64 matches
    modifier validMatch(uint8 _matchId) {
        require(_matchId > 0 && _matchId < 65);
        _;
    }

    modifier validPredictionOrOutcome(uint8 _predictionOrOutcome) {
        require(_predictionOrOutcome == WIN || _predictionOrOutcome == LOSE || _predictionOrOutcome == TIE);
        _;
    }
}


contract WorldCup2018 is Base, AccessControl {
    using SafeMath for uint256;

    //<------------------------------------------------------------------------------------->
    // /**
    //  * @title PullPayment
    //  * @dev Base contract supporting async send for pull payments. Inherit from this
    //  * contract and use asyncSend instead of send or transfer.
    //  */

    // / @dev WithdrawPayments event is emitted whenever a player withdraws the payments.
    event WithdrawPayments(address indexed _player, uint256 _value);

    mapping(address => uint256) private payments;
    uint256 private totalPayments;

    /**
     * @dev To make sure the totalPayments by calling this method.
     */
    function getTotalPayments() public view returns(uint retTotalPayments) {
        return totalPayments;
    }

    /**
     * @dev Withdraw accumulated balance, called by payee.
     */
    function withdrawPayments() public whenNotPaused {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(address(this).balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;
        payee.transfer(payment);

        emit WithdrawPayments(payee, payment);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function asyncSend(address dest, uint256 amount) internal onlyCLevel whenNotPaused {
        require(address(this).balance >= amount);

        uint tempTotalPayments = totalPayments.add(amount);
        require(address(this).balance >= tempTotalPayments);

        payments[dest] = payments[dest].add(amount);
        // totalPayments = totalPayments.add(amount);
        totalPayments = tempTotalPayments;
    }
    //<------------------------------------------------------------------------------------->

    event ContractUpgrade(address newContract);
    event BetMatch(address indexed _betterAddress, uint _invested, uint8 _matchId, uint8 _prediction);
    event SetOutcome(address indexed _setterAddress, uint8 _matchId, uint8 _outcome);
    event UpdateMatch(address indexed _setterAddress, uint8 _matchId, uint8 _hostTeamId, uint8 _guestTeamId);
    event UpdateMatchStartTime(address indexed _setterAddress, uint8 _matchId, uint _startTime);

    //<------------------------------------------------------------------------------------->
    mapping(address => AccountInfo) private accountInfos;
    uint8[MATCH_CNT] private match_pools;
    mapping(uint8 => Match) private matchs;
    address[][MATCH_CNT] private nm_players;
    //<------------------------------------------------------------------------------------->
    uint private totalInvest;
    uint8 private CLAIM_TAX = 10;
    //<------------------------------------------------------------------------------------->

    constructor() public {
        init();
        unpause();
    }

    function init() 
        private onlyCLevel {

        // 1	1 vs 2	    1528988400
        initRegistMatch(1, 1, 2, 1528988400);
        // 2	3 vs 4	    1529064000
        initRegistMatch(2, 3, 4, 1529064000);
        // 3	5 vs 6	    1529085600
        initRegistMatch(3, 5, 6, 1529085600);
        // 4	7 vs 8	    1529074800
        initRegistMatch(4, 7, 8, 1529074800);
        // 5	9 vs 10	    1529143200
        initRegistMatch(5, 9, 10, 1529143200);
        // 6	11 vs 12	1529164800
        initRegistMatch(6, 11, 12, 1529164800);
        // 7	13 vs 14	1529154000
        initRegistMatch(7, 13, 14, 1529154000);
        // 8	15 vs 16	1529175600
        initRegistMatch(8, 15, 16, 1529175600);
        // 9	17 vs 18	1529258400
        initRegistMatch(9, 17, 18, 1529258400);
        // 10	19 vs 20	1529236800
        initRegistMatch(10, 19, 20, 1529236800);
        // 11	21 vs 22	1529247600
        initRegistMatch(11, 21, 22, 1529247600);
        // 12	23 vs 24	1529323200
        initRegistMatch(12, 23, 24, 1529323200);
        // 13	25 vs 26	1529334000
        initRegistMatch(13, 25, 26, 1529334000);
        // 14	27 vs 28	1529344800
        initRegistMatch(14, 27, 28, 1529344800);
        // 15	29 vs 30	1529420400
        initRegistMatch(15, 29, 30, 1529420400);
        // 16	31 vs 32	1529409600
        initRegistMatch(16, 31, 32, 1529409600);
        // 17	1 vs 3	    1529431200
        initRegistMatch(17, 1, 3, 1529431200);
        // 18	4 vs 2	    1529506800
        initRegistMatch(18, 4, 2, 1529506800);
        // 19	5 vs 7	    1529496000
        initRegistMatch(19, 5, 7, 1529496000);
        // 20	8 vs 6	    1529517600
        initRegistMatch(20, 8, 6, 1529517600);
        // 21	9 vs 11	    1529593200
        initRegistMatch(21, 9, 11, 1529593200);
        // 22	12 vs 10	1529582400
        initRegistMatch(22, 12, 10, 1529582400);
        // 23	13 vs 15	1529604000
        initRegistMatch(23, 13, 15, 1529604000);
        // 24	16 vs 14	1529679600
        initRegistMatch(24, 16, 14, 1529679600);
        // 25	17 vs 19	1529668800
        initRegistMatch(25, 17, 19, 1529668800);
        // 26	20 vs 18	1529690400
        initRegistMatch(26, 20, 18, 1529690400);
        // 27	21 vs 23	1529776800
        initRegistMatch(27, 21, 23, 1529776800);
        // 28	24 vs 22	1529766000
        initRegistMatch(28, 24, 22, 1529766000);
        // 29	25 vs 27	1529755200
        initRegistMatch(29, 25, 27, 1529755200);
        // 30	28 vs 26	1529841600
        initRegistMatch(30, 28, 26, 1529841600);
        // 31	29 vs 31	1529863200
        initRegistMatch(31, 29, 31, 1529863200);
        // 32	32 vs 30	1529852400
        initRegistMatch(32, 32, 30, 1529852400);
        // 33	4 vs 1	    1529935200
        initRegistMatch(33, 4, 1, 1529935200);
        // 34	2 vs 3	    1529935200
        initRegistMatch(34, 2, 3, 1529935200);
        // 35	8 vs 5	    1529949600
        initRegistMatch(35, 8, 5, 1529949600);
        // 36	6 vs 7	    1529949600
        initRegistMatch(36, 6, 7, 1529949600);
        // 37	12 vs 9	    1530021600
        initRegistMatch(37, 12, 9, 1530021600);
        // 38	10 vs 11	1530021600
        initRegistMatch(38, 10, 11, 1530021600);
        // 39	16 vs 13	1530036000
        initRegistMatch(39, 16, 13, 1530036000);
        // 40	14 vs 15	1530036000
        initRegistMatch(40, 14, 15, 1530036000);
        // 41	20 vs 17	1530122400
        initRegistMatch(41, 20, 17, 1530122400);
        // 42	18 vs 19	1530122400
        initRegistMatch(42, 18, 19, 1530122400);
        // 43	24 vs 21	1530108000
        initRegistMatch(43, 24, 21, 1530108000);
        // 44	22 vs 23	1530108000
        initRegistMatch(44, 22, 23, 1530108000);
        // 45	28 vs 25	1530208800
        initRegistMatch(45, 28, 25, 1530208800);
        // 46	26 vs 27	1530208800
        initRegistMatch(46, 26, 27, 1530208800);
        // 47	32 vs 29	1530194400
        initRegistMatch(47, 32, 29, 1530194400);
        // 48	30 vs 31	1530194400
        initRegistMatch(48, 30, 31, 1530194400);
        // 49				1530367200
        initRegistMatch(49, 0, 0, 1530367200);
        // 50				1530381600
        initRegistMatch(50, 0, 0, 1530381600);
        // 51				1530453600
        initRegistMatch(51, 0, 0, 1530453600);
        // 52				1530468000
        initRegistMatch(52, 0, 0, 1530468000);
        // 53				1530540000
        initRegistMatch(53, 0, 0, 1530540000);
        // 54				1530554400
        initRegistMatch(54, 0, 0, 1530554400);
        // 55				1530626400
        initRegistMatch(55, 0, 0, 1530626400);
        // 56				1530640800
        initRegistMatch(56, 0, 0, 1530640800);
        // 57				1530885600
        initRegistMatch(57, 0, 0, 1530885600);
        // 58				1530900000
        initRegistMatch(58, 0, 0, 1530900000);
        // 59				1530972000
        initRegistMatch(59, 0, 0, 1530972000);
        // 60				1530986400
        initRegistMatch(60, 0, 0, 1530986400);
        // 61				1531245600
        initRegistMatch(61, 0, 0, 1531245600);
        // 62				1531332000
        initRegistMatch(62, 0, 0, 1531332000);
        // 63				1531576800
        initRegistMatch(63, 0, 0, 1531576800);
        // 64				1531666800
        initRegistMatch(64, 0, 0, 1531666800);

        totalInvest = 0;
    }

    function initRegistMatch(uint8 _matchId, uint8 _hostTeamId, uint8 _guestTeamId, uint _startTime) 
        private onlyCLevel {

        Match memory _match = Match(_matchId, _hostTeamId, _guestTeamId, _startTime, 0, 0);
        matchs[_matchId] = _match;
        match_pools[_matchId - 1] = _matchId;
    }

    function setClamTax(uint8 _tax) external onlyCLevel {
        require(_tax > 0);
        CLAIM_TAX = _tax;
    }

    function getClamTax() public view returns(uint8 claimTax) {
        return CLAIM_TAX;
    }

    function getTotalInvest() 
        public view returns(uint) {
        return totalInvest;
    }

    function updateMatch(uint8 _matchId, uint8 _hostTeamId, uint8 _guestTeamId) 
        external onlyCLevel validMatch(_matchId) validTeam(_hostTeamId) validTeam(_guestTeamId) whenNotPaused {

        Match storage _match = matchs[_matchId];
        require(_match.outcome == INIT);
        require(now < _match.startTime);

        _match.hostTeamId = _hostTeamId;
        _match.guestTeamId = _guestTeamId;

        emit UpdateMatch(msg.sender, _matchId, _hostTeamId, _guestTeamId);
    }

    function updateMatchStartTime(uint8 _matchId, uint _startTime) 
        external onlyCLevel validMatch(_matchId) whenNotPaused {

        Match storage _match = matchs[_matchId];
        require(_match.outcome == INIT);
        require(now < _startTime);

        _match.startTime = _startTime;

        emit UpdateMatchStartTime(msg.sender, _matchId, _startTime);
    }

    function getMatchIndex(uint8 _matchId) 
        private pure validMatch(_matchId) returns(uint8) {
        return _matchId - 1;
    }

    function betMatch(uint8 _matchId, uint8 _prediction) 
        external payable validValue validMatch(_matchId) validPredictionOrOutcome(_prediction) whenNotPaused {

        Match storage _match = matchs[_matchId];
        require(_match.outcome == INIT);
        require(now < _match.startTime);

        {
            Better storage better = _match.betters[msg.sender];
            if (better.invested > 0) {
                better.invested = better.invested.add(msg.value);
            } else {
                _match.betters[msg.sender] = Better(msg.value, 0);
            }
            _match.betters[msg.sender].bPredictionInvest[_prediction] = _match.betters[msg.sender].bPredictionInvest[_prediction].add(msg.value);
        }

        {
            _match.mPredictionInvest[_prediction] = _match.mPredictionInvest[_prediction].add(msg.value);
            _match.totalInvest = _match.totalInvest.add(msg.value);
        }

        {
            totalInvest = totalInvest.add(msg.value);
        }

        {
            AccountInfo storage accountInfo = accountInfos[msg.sender];
            if (accountInfo.invested > 0) {
                accountInfo.invested = accountInfo.invested.add(msg.value);
            } else {
                accountInfos[msg.sender] = AccountInfo({
                    invested: msg.value, prize: 0, claimed: 0
                });
            }
        }

        {
            uint8 index = getMatchIndex(_matchId);
            address[] memory match_betters = nm_players[index];

            bool ext = false;
            for (uint i = 0; i < match_betters.length; i++) {
                if (match_betters[i] == msg.sender) {
                    ext = true;
                    break;
                }
            }
            if (ext == false) {
                nm_players[index].push(msg.sender);
            }
        }

        emit BetMatch(msg.sender, msg.value, _matchId, _prediction);
    }

    function setOutcome(uint8 _matchId, uint8 _outcome) 
        external onlyCLevel validMatch(_matchId) validPredictionOrOutcome(_outcome) whenNotPaused {

        Match storage _match = matchs[_matchId];
        require(_match.outcome == INIT);
        _match.outcome = _outcome;

        noticeWinner(_matchId);

        emit SetOutcome(msg.sender, _matchId, _outcome);
    }

    function noticeWinner(uint8 _matchId) 
        private onlyCLevel {

        Match storage _match = matchs[_matchId];
        uint totalInvestForWinners = _match.mPredictionInvest[_match.outcome];

        uint fee = 0;
        uint prizeDistributionTotal = 0;

        if (_match.totalInvest > totalInvestForWinners) {
            (prizeDistributionTotal, fee) = feesTakenFromPrize(_match.totalInvest, totalInvestForWinners);
        }

        if (fee > 0) {
            asyncSend(getCFO(), fee);
        }

        if (prizeDistributionTotal > 0 || _match.totalInvest == totalInvestForWinners) {
            uint8 index = getMatchIndex(_matchId);
            address[] memory match_betters = nm_players[index];

            for(uint i = 0; i < match_betters.length; i++) {
                Better storage better = _match.betters[match_betters[i]];

                uint totalInvestForBetter = better.bPredictionInvest[_match.outcome];
                if (totalInvestForBetter > 0) {
                    uint prize = calculatePrize(prizeDistributionTotal, totalInvestForBetter, totalInvestForWinners);

                    better.prize = prize;

                    uint refundVal = totalInvestForBetter.add(prize);
                    asyncSend(match_betters[i], refundVal);

                    {
                        AccountInfo storage accountInfo = accountInfos[match_betters[i]];
                        accountInfo.prize = accountInfo.prize.add(prize);
                        accountInfo.claimed = accountInfo.claimed.add(refundVal);
                    }
                }
            }
        }
    }

    function feesTakenFromPrize(uint _totalInvestForMatch, uint _totalInvestForWinners) 
        private view returns(uint prizeDistributionTotal, uint fee) {

        require(_totalInvestForMatch >= _totalInvestForWinners);

        if (_totalInvestForWinners > 0) {
            if (_totalInvestForMatch > _totalInvestForWinners) {
                uint prizeTotal = _totalInvestForMatch.sub(_totalInvestForWinners);
                fee = prizeTotal.div(getClamTax());
                prizeDistributionTotal = prizeTotal.sub(fee);
            }
        } else {
            fee = _totalInvestForMatch;
        }

        return (prizeDistributionTotal, fee);
    }

    function calculatePrize(uint _prizeDistributionTotal, uint _totalInvestForBetter, uint _totalInvestForWinners) 
        private pure returns(uint) {
        return (_prizeDistributionTotal.mul(_totalInvestForBetter)).div(_totalInvestForWinners);
    }

    function getUserAccountInfo() public view returns(
        uint invested, 
        uint prize, 
        uint balance
    ) {
        AccountInfo storage accountInfo = accountInfos[msg.sender];

        invested = accountInfo.invested;
        prize = accountInfo.prize;
        balance = payments[msg.sender];

        return (invested, prize, balance);
    }

    function getMatchInfoList01() public view returns(
        uint8[MATCH_CNT] matchIdArray, 
        uint8[MATCH_CNT] hostTeamIdArray, 
        uint8[MATCH_CNT] guestTeamIdArray, 
        uint[MATCH_CNT] startTimeArray, 
        uint8[MATCH_CNT] outcomeArray 
    ) {
        for (uint8 intI = 0; intI < MATCH_CNT; intI++) {
            Match storage _match = matchs[match_pools[intI]];

            matchIdArray[intI] = _match.matchId;

            hostTeamIdArray[intI] = _match.hostTeamId;
            guestTeamIdArray[intI] = _match.guestTeamId;
            startTimeArray[intI] = _match.startTime;
            outcomeArray[intI] = _match.outcome;
        }

        return (
            matchIdArray,

            hostTeamIdArray,
            guestTeamIdArray,
            startTimeArray,

            outcomeArray
        );
    }

    function getMatchInfoList02() public view returns(
        uint[MATCH_CNT] winPredictionArray, 
        uint[MATCH_CNT] losePredictionArray, 
        uint[MATCH_CNT] tiePredictionArray
    ) {
        for (uint8 intI = 0; intI < MATCH_CNT; intI++) {
            Match storage _match = matchs[match_pools[intI]];

            winPredictionArray[intI] = _match.mPredictionInvest[WIN];
            losePredictionArray[intI] = _match.mPredictionInvest[LOSE];
            tiePredictionArray[intI] = _match.mPredictionInvest[TIE];
        }

        return (
            winPredictionArray,
            losePredictionArray,
            tiePredictionArray
        );
    }

    function getMatchInfoList03() public view returns(
        uint[MATCH_CNT] winPredictionArrayForLoginUser, 
        uint[MATCH_CNT] losePredictionArrayForLoginUser, 
        uint[MATCH_CNT] tiePredictionArrayForLoginUser
    ) {
        for (uint8 intI = 0; intI < MATCH_CNT; intI++) {
            Match storage _match = matchs[match_pools[intI]];

            Better storage better = _match.betters[msg.sender];

            winPredictionArrayForLoginUser[intI] = better.bPredictionInvest[WIN];
            losePredictionArrayForLoginUser[intI] = better.bPredictionInvest[LOSE];
            tiePredictionArrayForLoginUser[intI] = better.bPredictionInvest[TIE];
        }

        return (
            winPredictionArrayForLoginUser,
            losePredictionArrayForLoginUser,
            tiePredictionArrayForLoginUser
        );
    }

    function () public payable {
        revert();
    }

    function kill() 
        public onlyOwner whenNotPaused {

        require(getTotalPayments() == 0);

        for (uint8 intI = 0; intI < MATCH_CNT; intI++) {
            Match storage _match = matchs[match_pools[intI]];
            require(_match.outcome > INIT);
        }

        selfdestruct(getOwner());
    }
}