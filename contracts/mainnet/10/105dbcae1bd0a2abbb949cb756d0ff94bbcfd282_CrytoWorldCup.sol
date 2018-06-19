pragma solidity ^0.4.4;

//////////////////////////////////////////////////////////
//
// Developer: ABCoin
// Date: 2018-06-01
// author: EricShu; Panyox
//
/////////////////////////////////////////////////////////

contract MainBet{

    bytes30 constant public name = &#39;CrytoWorldCup&#39;;
    uint constant public vision = 1.0;

    uint constant internal NOWINNER = 0;
    uint constant internal WIN = 1;
    uint constant internal LOSE = 2;
    uint constant internal TIE = 3;

    uint private CLAIM_TAX = 20;

    address public creatorAddress;

    //player
    struct Player {
        address addr;
        uint balance;
        uint invested;
        uint num;
        uint prize;
        uint claimed;
    }

    mapping(address => Player) public players;
    address[] public ch_players;
    address[][10] public st_players;
    address[][100] public nm_players;

    function getBalance() public constant returns(uint[]){
        Player storage player = players[msg.sender];

        uint[] memory data = new uint[](6);
        data[0] = player.balance;
        data[1] = player.invested;
        data[2] = player.num;
        data[3] = player.prize;
        data[4] = player.claimed;

        return data;
    }

    function claim() public returns(bool){

        Player storage player = players[msg.sender];
        require(player.balance>0);

        uint fee = SafeMath.div(player.balance, CLAIM_TAX);
        uint finalValue = SafeMath.sub(player.balance, fee);

        msg.sender.transfer(finalValue);
        creatorAddress.transfer(fee);

        player.claimed = SafeMath.add(player.claimed, player.balance);
        player.balance = 0;

        return true;
    }

    function setClamTax(uint _tax) public onlyOwner returns(bool){
        require(_tax>0);

        CLAIM_TAX = _tax;
        return true;
    }

    modifier onlyOwner(){
        assert(msg.sender == creatorAddress);
        _;
    }
    modifier beforeTime(uint time){
        assert(now < time);
        _;
    }
    modifier afterTime(uint time){
        assert(now > time);
        _;
    }
}

//冠军赛
//32	沙特阿拉伯
//31	俄罗斯
//30	韩国
//29	日本
//28	巴拿马
//27	尼日利亚
//26	埃及
//25	摩洛哥
//24	澳大利亚
//23	塞尔维亚
//22	伊朗
//21	塞内加尔
//20	哥斯达黎加
//19	突尼斯
//18	瑞典
//17	冰岛
//16	墨西哥
//15	克罗地亚
//14	哥伦比亚
//13	丹麦
//12	秘鲁
//11	瑞士
//10	波兰
//9	比利时
//8	葡萄牙
//7	英格兰
//6	法国
//5	西班牙
//4	乌拉圭
//3	阿根廷
//2	德国
//1	巴西
contract Champion is MainBet{
    uint public startTime = 0;
    uint public endTime = 0;

    uint private totalPrize;
    uint private numberBets;
    uint private winner;

    bool private isInit = false;

    struct Country{
        uint totalNum;
        uint totalInvest;
    }

    mapping (address => mapping (uint => uint)) private bets;
    mapping (uint => Country) countrys;

    uint private lucky = 0;

    modifier beforeWinner {
        assert(winner == NOWINNER);
        _;
    }
    modifier beforeInit{
        assert(isInit);
        _;
    }
    function InitCountry(uint _startTime, uint _endTime) internal returns(bool res) {

        startTime = _startTime;
        endTime = _endTime;

        winner = 0;

        totalPrize = 0;
        numberBets = 0;
        isInit = true;
        return true;
    }

    function setChampion(uint _winner) public onlyOwner beforeWinner returns (bool){
        require(_winner>0);

        winner = _winner;

        Country storage country = countrys[_winner];

        for(uint i=0; i<ch_players.length; i++){
            uint myInvest = bets[ch_players[i]][winner];
            if(myInvest>0){
                Player storage player = players[ch_players[i]];
                uint winInest = SafeMath.mul(totalPrize, myInvest);
                uint prize = SafeMath.div(winInest, country.totalInvest);
                player.balance = SafeMath.add(player.balance, prize);
                player.prize = SafeMath.add(player.prize, prize);
            }
        }

        return true;
    }

    function getChampion() public constant returns (uint winnerTeam){
        return winner;
    }

    function BetChampion(uint countryId) public beforeWinner afterTime(startTime) beforeTime(endTime) payable returns (bool)  {
        require(msg.value>0);
        require(countryId>0);

        countrys[countryId].totalInvest = SafeMath.add(countrys[countryId].totalInvest, msg.value);
        countrys[countryId].totalNum = SafeMath.add(countrys[countryId].totalNum, 1);

        bets[msg.sender][countryId] = SafeMath.add(bets[msg.sender][countryId], msg.value);

        totalPrize = SafeMath.add(totalPrize, msg.value);

        numberBets++;

        Player storage player = players[msg.sender];
        if(player.invested>0){
            player.invested = SafeMath.add(player.invested, msg.value);
            player.num = SafeMath.add(player.num, 1);
        }else{
            players[msg.sender] = Player({
                addr: msg.sender,
                balance: 0,
                invested: msg.value,
                num: 1,
                prize: 0,
                claimed: 0
            });
        }

        bool ext = false;
        for(uint i=0; i<ch_players.length; i++){
            if(ch_players[i] == msg.sender) {
                ext = true;
                break;
            }
        }
        if(ext == false){
            ch_players.push(msg.sender);
        }
        return true;
    }

    function getCountryBet(uint countryId) public constant returns(uint[]){
        require(countryId>0);

        Country storage country = countrys[countryId];
        uint[] memory data = new uint[](4);
        data[0] = country.totalNum;
        data[1] = country.totalInvest;
        data[2] = winner;
        if(isInit){
            data[3] = 1;
        }
        return data;
    }

    function getDeepInfo(uint countryId) public constant returns(uint[]){
        require(countryId>0);

        Country storage country = countrys[countryId];
        uint[] memory data = new uint[](10);
        data[0] = country.totalNum;
        data[1] = country.totalInvest;
        data[2] = lucky;
        data[3] = 0;
        data[4] = 0;

        if(winner>0){
            data[4] = 1;
        }
        if(winner == countryId){

            uint myInvest = bets[msg.sender][winner];
            if(myInvest>0){
                uint winInest = SafeMath.mul(totalPrize, myInvest);
                uint prize = SafeMath.div(winInest, country.totalInvest);
                data[2] = 1;
                data[3] = prize;
            }
        }

        return data;
    }

    function getMyBet(uint countryId) public constant returns (uint teamBet) {
       return (bets[msg.sender][countryId]);
    }

    function getChStatus() public constant returns (uint []){
        uint[] memory data = new uint[](3);
        data[0] = totalPrize;
        data[1] = numberBets;
        data[2] = 0;
        if(isInit){
            data[2] = 1;
            if(now > endTime){
                data[2] = 2;
            }
            if(winner > 0){
                data[2] = 3;
            }
        }

        return data;
    }

    function getNumberOfBets() public constant returns (uint num){
        return numberBets;
    }

    function () public payable {
        throw;
    }

}

//普通赛 胜-平-负
contract Normal is MainBet{

    struct Better {
        address addr;
        uint invested;
        uint teamBet; //bet win: 1,player1; 2,player2; 3,tie
        uint claimPrize; // 0:false; 1:true
    }

    struct Match{
        uint matchId;
        uint startTime;
        uint winner;
        uint totalInvest;
        uint totalNum;
        mapping(address => mapping(uint => Better)) betters;
    }

    mapping(uint => Match) public matchs;
    uint[] public match_pools;
    uint public totalNum;
    uint public totalInvest;

    function initNormal() public returns(bool){
        for(uint i=0;i<match_pools.length;i++){
            match_pools[i] = 0;
        }
        totalNum = 0;
        totalInvest = 0;
        return true;
    }

    function addMatch(uint matchId, uint startTime) public onlyOwner returns(bool res){
        require(matchId > 0);
        require(now<startTime);

        for(uint i=0;i<match_pools.length;i++){
            require(matchId!=match_pools[i]);
        }

        Match memory _match = Match(matchId, startTime, 0, 0, 0);
        matchs[matchId] = _match;
        match_pools.push(matchId);

        return true;
    }

    function getMatchIndex(uint matchId) public constant returns(uint){
        require(matchId>0);

        uint index = 100;
        for(uint i=0;i<match_pools.length;i++){
            if(match_pools[i] == matchId){
                index = i;
                break;
            }
        }
        // require(index < 100);
        return index;
    }

    function betMatch(uint matchId, uint team) public payable returns(bool res){
        require(matchId>0 && team>0);
        require(team == WIN || team == LOSE || team == TIE);
        require(msg.value>0);

        Match storage _match = matchs[matchId];
        require(_match.winner == NOWINNER);
        require(now < _match.startTime);

        Better storage better = _match.betters[msg.sender][team];
        if(better.invested>0){
            better.invested = SafeMath.add(better.invested, msg.value);
        }else{
            _match.betters[msg.sender][team] = Better(msg.sender, msg.value, team,0);
        }

        _match.totalNum = SafeMath.add(_match.totalNum, 1);
        _match.totalInvest = SafeMath.add(_match.totalInvest, msg.value);
        totalNum = SafeMath.add(totalNum, 1);
        totalInvest = SafeMath.add(totalInvest, msg.value);

        Player storage player = players[msg.sender];
        if(player.invested>0){
            player.invested = SafeMath.add(player.invested, msg.value);
            player.num = SafeMath.add(player.num, 1);
        }else{
            players[msg.sender] = Player({
                addr: msg.sender,
                balance: 0,
                invested: msg.value,
                num: 1,
                prize: 0,
                claimed: 0
            });
        }
        uint index = getMatchIndex(matchId);
        address[] memory match_betters = nm_players[index];
        bool ext = false;
        for(uint i=0;i<match_betters.length;i++){
            if(match_betters[i]==msg.sender){
                ext = true;
                break;
            }
        }
        if(ext == false){
            nm_players[index].push(msg.sender);
        }
        return true;
    }
    function getMatch(uint matchId) public constant returns(uint[]){
        require(matchId>0);
        Match storage _match = matchs[matchId];
        uint[] memory data = new uint[](2);
        data[0] = _match.totalNum;
        data[1] = _match.totalInvest;
        return data;
    }
    function getPool() public constant returns(uint[]){
        uint[] memory data = new uint[](2);
        data[0] = totalNum;
        data[1] = totalInvest;
    }
    function setWinner(uint _matchId, uint team) public onlyOwner returns(bool){
        require(_matchId>0);
        require(team == WIN || team == LOSE || team == TIE);
        Match storage _match = matchs[_matchId];
        require(_match.winner == NOWINNER);

        _match.winner = team;

        uint index = getMatchIndex(_matchId);
        address[] memory match_betters = nm_players[index];
        uint teamInvest = getTeamInvest(_matchId, team);
        for(uint i=0;i<match_betters.length;i++){
            Better storage better = _match.betters[match_betters[i]][team];
            if(better.invested>0){
                uint winVal = SafeMath.mul(_match.totalInvest, better.invested);
                uint prize = SafeMath.div(winVal, teamInvest);
                Player storage player = players[match_betters[i]];
                player.balance = SafeMath.add(player.balance, prize);
                player.prize = SafeMath.add(player.prize, prize);
            }
        }
        return true;
    }

    function getTeamInvest(uint matchId, uint team) public constant returns(uint){
        require(matchId>0);
        require(team == WIN || team == LOSE || team == TIE);

        Match storage _match = matchs[matchId];
        uint index = getMatchIndex(matchId);
        address[] storage match_betters = nm_players[index];
        uint invest = 0;
        for(uint i=0;i<match_betters.length;i++){
            Better storage better = _match.betters[match_betters[i]][team];
            invest = SafeMath.add(invest, better.invested);
        }

        return invest;
    }

    function getMyNmBet(uint matchId, uint team) public constant returns(uint[]){
        require(matchId>0);
        require(team>0);
        Match storage _match = matchs[matchId];

        uint[] memory data = new uint[](6);

        data[0] = _match.totalInvest;
        data[1] = _match.totalNum;
        data[2] = 0;
        data[3] = 0;
        data[4] = 0;
        if(_match.winner>0){
            data[2] = 1;
            if(_match.winner == team){
                Better storage better = _match.betters[msg.sender][team];
                uint teamInvest = getTeamInvest(matchId, team);
                uint winVal = SafeMath.mul(_match.totalInvest, better.invested);
                uint prize = SafeMath.div(winVal, teamInvest);
                data[3] = 1;
                data[4] = prize;
            }
        }

        return data;
    }

    function () public payable {
        throw;
    }
}

//小组出线 4选2
contract Stage is MainBet{
    event InitiateBet(address indexed _from, uint group_num);
    event Bet(address indexed _from, uint[] teams, uint value, uint group_num, uint[] groupData, uint[] totalData);
    event Winner(address indexed _from, uint group_num, uint[] _winner, uint _prize, uint winnerNum);
    event Claim(address indexed _from, uint group_num, uint _value, uint taxValue);

    struct StageBetter {
        address addr;
        uint money_invested;
        uint bet_team1;
        uint bet_team2;
    }

    struct Group {
       uint group_num;
       uint start_time;
       uint end_time;
       uint winner_team1;
       uint winner_team2;
       uint num_betters;
       uint total_prize;
       mapping (address => mapping (uint => StageBetter)) betters;
       mapping (uint => uint) num_team_bets;
    }

    mapping (uint => Group) groups;
    uint[] public group_pools;

    function initStage() public onlyOwner returns(bool){

        for(uint i = 0;i<group_pools.length; i++){
            group_pools[i] = 0;
        }

        return true;
    }

    function addGroup(uint _group_num, uint _start_time, uint _end_time) public returns(bool) {
        require(_group_num > 0);
        require(now <= _start_time);
        require(_start_time <= _end_time);

        for(uint i = 0; i < group_pools.length; i++) {
            require(_group_num != group_pools[i]);
        }

        Group memory group = Group(_group_num, _start_time, _end_time, 0, 0, 0, 0);
        groups[_group_num] = group;
        group_pools.push(_group_num);

        InitiateBet(msg.sender, _group_num);
        return true;
    }

    function betStage(uint _group_num, uint[] _bet_teams) public payable returns (bool) {

        require(_group_num > 0);
        require(msg.value > 0);
        require(_bet_teams.length == 2);

        Group storage group = groups[_group_num];
        require(group.winner_team1 == 0 && group.winner_team2 == 0);

        require(now <= group.start_time);

        uint sumofsquares = SafeMath.sumofsquares(_bet_teams[0], _bet_teams[1]);

        StageBetter storage better = group.betters[msg.sender][sumofsquares];
        if(better.money_invested > 0) {
            better.money_invested = SafeMath.add(better.money_invested, msg.value);
        } else {
            group.betters[msg.sender][_group_num] = StageBetter({
                addr: msg.sender,
                money_invested: msg.value,
                bet_team1: _bet_teams[0],
                bet_team2: _bet_teams[1]
            });
        }

        group.total_prize = SafeMath.add(group.total_prize, msg.value);
        group.num_betters = SafeMath.add(group.num_betters, 1);
        group.num_team_bets[sumofsquares] = SafeMath.add(group.num_team_bets[sumofsquares], 1);

        Player storage player = players[msg.sender];
        if(player.invested>0){
            player.invested = SafeMath.add(player.invested, msg.value);
            player.num = SafeMath.add(player.num, 1);
        }else{
            players[msg.sender] = Player({
                addr: msg.sender,
                balance: 0,
                invested: msg.value,
                num: 1,
                prize: 0,
                claimed: 0
            });
        }
        uint index = getGroupIndex(_group_num);
        address[] memory group_betters = st_players[index];
        bool ext = false;
        for(uint i=0;i<group_betters.length;i++){
            if(group_betters[i]==msg.sender){
                ext = true;
                break;
            }
        }
        if(ext==false){
            st_players[index].push(msg.sender);
        }
        return true;
    }

    function setGroupWinner(uint _group_num, uint[] _winner_teams) public onlyOwner returns(bool) {

        require(_group_num > 0);
        require(_winner_teams.length == 2);

        Group storage group = groups[_group_num];
        require(group.winner_team1 == 0 && group.winner_team2 == 0);

        group.winner_team1 = _winner_teams[0];
        group.winner_team2 = _winner_teams[1];

        uint sumofsquares = SafeMath.sumofsquares(group.winner_team1, group.winner_team2);

        uint index = getGroupIndex(_group_num);
        address[] memory group_betters = st_players[index];
        uint teamInvest = getGroupTeamInvest(_group_num, sumofsquares);
        for(uint i=0;i<group_betters.length;i++){
            StageBetter storage better = group.betters[group_betters[i]][_group_num];
            if(better.money_invested > 0){
                uint aux = SafeMath.mul(group.total_prize, better.money_invested);
                uint prize = SafeMath.div(aux, teamInvest);

                Player storage player = players[group_betters[i]];
                player.balance = SafeMath.add(player.balance, prize);
                player.prize = SafeMath.add(player.prize, prize);
            }
        }

        // Winner(msg.sender, _group_num, _winner_teams, prize, winnerNum);
        return true;
    }

    function updateEndTimeManually(uint _group_num, uint _end_time) public onlyOwner returns (bool){
        Group storage group = groups[_group_num];
        require(group.winner_team1 == 0 && group.winner_team2 == 0);

        group.end_time = _end_time;
        return true;
    }

    function updateStartTimeManually(uint _group_num, uint _start_time) public onlyOwner returns (bool){
        Group storage group = groups[_group_num];
        require(group.winner_team1 == 0 && group.winner_team2 == 0);

        group.start_time = _start_time;
        return true;
    }

    function getWinnerTeam(uint _group_num) public constant returns (uint[]){
        require(_group_num > 0);

        uint[] memory data = new uint[](2);
        Group storage group = groups[_group_num];
        require(group.winner_team1 > 0 && group.winner_team2 > 0);

        data[0] = group.winner_team1;
        data[1] = group.winner_team2;

        return data;
    }

    function getGroupTeamInvest(uint _group_num, uint squares) public constant returns(uint){
        require(_group_num>0);

        uint index = getGroupIndex(_group_num);
        address[] storage group_betters = st_players[index];
        Group storage group = groups[_group_num];
        uint sumofsquares = SafeMath.sumofsquares(group.winner_team1, group.winner_team2);

        uint invest = 0;
        for(uint i=0;i<group_betters.length;i++){
            StageBetter storage better = group.betters[group_betters[i]][_group_num];
            if(sumofsquares == squares){
                invest = SafeMath.add(invest, better.money_invested);
            }

        }
        return invest;
    }

    function getGroupStatistic(uint _group_num) public constant returns (uint[]){
        require(_group_num > 0);

        uint[] memory data = new uint[](5);
        Group storage group = groups[_group_num];

        data[0] = group.total_prize;
        data[1] = group.num_betters;
        return data;
    }

    function getMyStageBet(uint _group_num, uint team1, uint team2) public constant returns(uint[]){
        require(_group_num>0);
        require(team1>0);
        require(team2>0);

        Group storage group = groups[_group_num];
        uint sumofsquares = SafeMath.sumofsquares(team1, team2);
        uint sumofsquares1 = SafeMath.sumofsquares(group.winner_team1, group.winner_team2);

        uint[] memory data = new uint[](6);
        data[0] = group.total_prize;
        data[1] = group.num_betters;
        data[2] = 0;
        data[3] = 0;
        data[4] = 0;
        if(sumofsquares1>0){
            data[2] = 1;
        }
        if(sumofsquares == sumofsquares1){
            data[3] = 1;
            StageBetter storage better = group.betters[msg.sender][_group_num];
            uint teamInvest = getGroupTeamInvest(_group_num, sumofsquares);
            uint aux = SafeMath.mul(group.total_prize, better.money_invested);
            uint prize = SafeMath.div(aux, teamInvest);
            data[4] = prize;
        }

        return data;
    }

    function getGroupIndex(uint group_id) public constant returns(uint){
        require(group_id>0);

        uint index = 10;
        for(uint i=0;i<group_pools.length;i++){
            if(group_pools[i] == group_id){
                index = i;
                break;
            }
        }
        // require(index<10);
        return index;
    }

    function getNumberOfBets(uint _group_num) public constant returns (uint num_betters){
        require(_group_num > 0);

        Group storage group = groups[_group_num];
        return group.num_betters;
    }

    function getAllGameStatistic() public constant returns (uint[]){
        uint[] memory data = new uint[](2);
        uint allTotalPrize = 0;
        uint allNumberOfBets = 0;

        for(uint i = 0; i < group_pools.length; i++) {
            uint group_num = group_pools[i];
            Group storage group = groups[group_num];
            allTotalPrize = SafeMath.add(group.total_prize, allTotalPrize);
            allNumberOfBets = SafeMath.add(group.num_betters, allNumberOfBets);
        }

        data[0] = allTotalPrize;
        data[1] = allNumberOfBets;
        return data;
    }

    function getAllTotalPrize() public constant returns (uint){
        uint allTotalPrize = 0;
        for(uint i = 0; i < group_pools.length; i++) {
            uint group_num = group_pools[i];
            Group storage group = groups[group_num];
            allTotalPrize = SafeMath.add(group.total_prize, allTotalPrize);
        }
        return allTotalPrize;
    }

    function getAllNumberOfBets() public constant returns (uint){
        uint allNumberOfBets = 0;
        for(uint i = 0; i < group_pools.length; i++) {
            uint group_num = group_pools[i];
            Group storage group = groups[group_num];
            allNumberOfBets = SafeMath.add(group.num_betters, allNumberOfBets);
        }

        return allNumberOfBets;
    }


    function () public payable {
        throw;
    }
}

contract CrytoWorldCup is Champion, Normal, Stage{

    function CrytoWorldCup() public {
        creatorAddress = msg.sender;
    }

    //初始化冠军赛
    function initCountry(uint startTime, uint endTime) public onlyOwner returns(bool){
        //
        InitCountry(startTime, endTime);
        return true;
    }

    // gets called when no other function matches
    function() public payable{
        // just being sent some cash?
        throw;
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function sumofsquares(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * a + b * b;
        assert(c >= a);
        return c;
    }
}