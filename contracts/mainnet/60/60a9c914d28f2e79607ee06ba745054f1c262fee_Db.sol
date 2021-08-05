pragma solidity >=0.6.0 <0.7.0;
import "./safeMath.sol";
contract Db {
    using SafeMath for uint256;
    address own = msg.sender;
    address coreAddress;
    address toolAddress;
    address tokenAddress;
    Tool tool;
    uint day = 86400;
    modifier isCore(){
        require(msg.sender == coreAddress);
        _;
    }
    modifier isOwn(){
        require(msg.sender == own);
        _;
    }
    modifier isToken(){
        require(msg.sender == tokenAddress);
        _;
    }
    function init(address _coreAddress,address _toolAddress) isOwn public{
        coreAddress = _coreAddress;
        toolAddress = _toolAddress;
        tool = Tool(_toolAddress);
    }
    function getNow() public view returns(uint){
        return now;
    }
    function setLuckPool(uint _luckNum,uint _luckType,uint _luckArea,uint _balance) isCore public{
        luckPool[_luckNum][_luckType][_luckArea] = _balance;
    }
    function setLuckPool(uint _luckNum) isCore public{
        luckNum = _luckNum;
    }
    function setLastTime(uint _time) isCore public{
        lastTime = _time;
    }
    function setSystemPlayerNum(uint _num) public isCore {
        systemPlayerNum = _num;
    }
    function setPlayerLev(address _own,uint _lev) public isCore{
        if(_lev > 0 && true == playerList[_own].isExist){
            playerList[_own].lev = _lev;
        }
    }
    function getPlayerInfo(address _own) public view returns(address _parent,bool _isExist,bool _isParent){
        return (playerList[_own].parentAddress,playerList[_own].isExist,playerList[_own].isParent);
    }
    function _getProgenitorAddress(address _own) internal view returns (address[30] memory){
        address[30] memory _progenitor;
        Player memory _tempPlayer = playerList[_own];
        for (uint i = 0; i < 30; i++) {
            if (playerList[_tempPlayer.parentAddress].isExist == true) {
                _progenitor[i] = _tempPlayer.parentAddress;
                _tempPlayer = playerList[_tempPlayer.parentAddress];
            }
        }
        return _progenitor;
    }
    function setMyTeam(address _own) internal{
        address[30] memory _progenitor = _getProgenitorAddress(_own);
        for(uint i = 0;i<30;i++){
            if(false == playerList[_progenitor[i]].isExist){
                break;
            }
            if(i == 0){
                playerList[_progenitor[i]].sonAddress.push(_own);
            }
            playerList[_progenitor[i]].teamAddress.push(_own);
        }
    }
    function setPlayerParentAddress(address _own,address _parent) public isCore{
        if(playerList[_own].isParent == false){
            playerList[_own].isParent = true;
            playerList[_own].isExist = true;
            playerList[_own].parentAddress = _parent;
            systemPlayerNum = systemPlayerNum.add(1);
            setMyTeam(_own);
        }
    }
    function getFreeWithdrawBalance(address _own) public view returns (uint){
        require(playerList[_own].isExist == true);
        uint _balance = playerList[_own].allIncome.sub(playerList[_own].withdrawAmount); 
        return _balance;
    }
    function setPlayerWithdraw(address _own) public isCore{
        require(playerList[_own].isExist == true);
        uint _balance = getFreeWithdrawBalance(_own);
        if(_balance <= 0){
            return;
        }
        playerList[_own].withdrawAmount = playerList[_own].withdrawAmount.add(_balance);
        playerList[_own].lastWithdrawTime = getNow();
    }
    function _setMyTeamIncome(address _own,uint _balance) internal{
        address[30] memory _progenitor = _getProgenitorAddress(_own);
        for(uint i = 0;i<30;i++){
            if(false == playerList[_progenitor[i]].isExist){
                break;
            }
            playerList[_progenitor[i]].teamRechargeAmount = playerList[_progenitor[i]].teamRechargeAmount.add(_balance);
        }
    }
    function _setPlayerInvest(address _own,uint _balance) internal isCore{
        require(playerList[_own].isExist == true);
        playerList[_own].rechargeAmount = playerList[_own].rechargeAmount.add(_balance);
        playerList[_own].teamRechargeAmount = playerList[_own].teamRechargeAmount.add(_balance);
        _setMyTeamIncome(_own,_balance);
        if(lastPool >= 9990000e6){
            _setLastPoolOverflowReward(_balance);
        }else{
            lastPool = lastPool.add(_balance.mul(8).div(100));
        }
    }
    function addInvestBurnNum(uint _num) public isCore{
        investTokenUsdtNum[luckCodeNum] = investTokenUsdtNum[luckCodeNum].add(_num);
    }
    function getAreaPerformance(address _own) public view returns (uint _maxPerformance, uint _minPerformance){
        uint _ownBalance = playerList[_own].rechargeAmount;
        address[] memory _sonList = playerList[_own].sonAddress;
        _maxPerformance = 0;
        for (uint i = 0; i < _sonList.length; i++) {
            if (playerList[_sonList[i]].teamRechargeAmount > _maxPerformance) {
                _maxPerformance = playerList[_sonList[i]].teamRechargeAmount;
            }
        }
        _minPerformance = playerList[_own].teamRechargeAmount.sub(_maxPerformance.add(_ownBalance));
        return (_maxPerformance, _minPerformance);
    }
    function getAddressSomeInfo(address _own) public view returns(uint _teamCount,uint _sonCount,uint _investBalance,uint _lev,uint _incomeBalance,uint _withdrawBalance){
        return (
            playerList[_own].teamAddress.length,
            playerList[_own].sonAddress.length,
            playerList[_own].rechargeAmount,
            playerList[_own].lev,
            playerList[_own].allIncome,
            playerList[_own].withdrawAmount
            );
    }
    function addIncome(address _own,uint _type, uint _time ,uint _balance,address _fromAddress) public isCore{
        if(_balance == 0){
            return;
        }
        playerList[_own].allIncome = playerList[_own].allIncome.add(_balance);
        incomeList[_own].push(Income({
            incomeType : _type,
            createTime : _time,
            balance : _balance,
            fromAddress : _fromAddress
        }));
    }
    function addInvest(address _own,uint _balance) public isCore{
        _setPlayerInvest(_own,_balance);
        uint _ratio = tool._getRatio(_balance);
        Invest memory _invest = Invest({
            own : _own,
            createTime : getNow(),
            withdrawTime : getNow(),
            balance : _balance,
            ratio : _ratio,
            profit : 0,
            isFull : false
        });
        investList[_own].push(_invest);
        systemInvest.push(_invest);
    }
    function addCodeToPlayer(address _own,uint _count) public isCore{
        luckCodeBurnTokenNum[luckCodeNum] = luckCodeBurnTokenNum[luckCodeNum].add(_count);//增加消耗门票记录
        for(uint i = 0; i < _count;i++){
            luckCodeList[luckCodeNum].push(_own);
        }
    }
    function _checkOpenLuckCodeLev() internal view returns (bool , bool){
        uint _investBurnToken = investTokenUsdtNum[luckCodeNum];
        uint _nowCodeNum = (luckCodeList[luckCodeNum].length).mul(1e6);
        if(_investBurnToken >= _nowCodeNum.mul(2)){
            return (true,true);
        }else if(_investBurnToken >= _nowCodeNum){
            return (false,true);
        }else{
            return (false,false);
        }
    }
    function _giveUserLuckCodeReward(uint[25] memory _code,uint _length) internal{
        for(uint i = 0;i < _length;i++){
            address _tempAddress = luckCodeList[luckCodeNum][_code[i]];
            luckCodeResList[luckCodeNum].push(_code[i]);
            uint _tempBalance;
            if(i >= 24){
                _tempBalance = luckPool[luckCodeNum][1][1];
                
            }else if(i >= 18){
                _tempBalance = luckPool[luckCodeNum][1][2].div(6);
            }else{
                _tempBalance = luckPool[luckCodeNum][1][3].div(18);
            }
            addIncome(_tempAddress,8,getNow(),_tempBalance,address(0x01));
        }
    }
    function openLuckCodeReward() internal{
        address[] memory _address = luckCodeList[luckCodeNum];
        uint[25] memory _codeList = tool._crateLuckCodeList(_address.length);
        uint[4] memory _poolBalance = luckPool[luckCodeNum][1];
        uint _length;
        (bool isLev1,bool isLev2) = _checkOpenLuckCodeLev();
        if(true == isLev1){
            _length = 25;
        }else if(true == isLev2){
            _length = 24;
        }else{
            _length = 18;
        }
        _giveUserLuckCodeReward(_codeList,_length);
        luckCodeNum = luckCodeNum.add(1);
        luckCodeList[luckCodeNum].push(address(0x00));
        uint _frozenTempBalance;
        if(true == isLev1){
            return;
        }else if(true == isLev2){
            _frozenTempBalance = _poolBalance[1];
        }else{
            _frozenTempBalance = _poolBalance[1].add(_poolBalance[2]);
        }
        luckPool[luckCodeNum][1][0] = luckPool[luckCodeNum][1][1].add(_frozenTempBalance);
        luckPool[luckCodeNum][1][1] = luckPool[luckCodeNum][1][1].add(_frozenTempBalance);
    }
    function openLuckInvestReward() internal{
        Invest[21] memory _invest = _getLuckInvestList(true);
        if(_invest[0].own == address(0x00) || _invest[0].balance == 0){
            return;
        }
        uint _balance1 = luckPool[luckInvestNum][0][1];
        uint _balance2 = luckPool[luckInvestNum][0][2].div(5);
        uint _balance3 =luckPool[luckInvestNum][0][3].div(15);
        for(uint i = 0; i < 21;i++){
            if(_invest[i].balance == 0){
                continue;
            }
            if(i == 0){
                addIncome(_invest[i].own,8,getNow(),_balance1,address(0x00));
            }else if(i <= 5){
                addIncome(_invest[i].own,8,getNow(),_balance2,address(0x00));
            }else{
                addIncome(_invest[i].own,8,getNow(),_balance3,address(0x00));
            }
        }
        lastLuckOpenTime = getNow();
        luckInvestNum = luckInvestNum.add(1);
    }
    function setAssignment(uint _balance) public isCore{
        uint _tempBalance = _balance.mul(5).div(100);
        luckPool[luckCodeNum][0][0] = luckPool[luckCodeNum][0][0].add(_tempBalance); 
        luckPool[luckCodeNum][0][1] = luckPool[luckCodeNum][0][1].add(_tempBalance.mul(20).div(100)); 
        luckPool[luckCodeNum][0][2] = luckPool[luckCodeNum][0][2].add(_tempBalance.mul(30).div(100)); 
        luckPool[luckCodeNum][0][3] = luckPool[luckCodeNum][0][3].add(_tempBalance.mul(50).div(100)); 
        luckPool[luckCodeNum][1][0] = luckPool[luckCodeNum][1][0].add(_tempBalance); 
        luckPool[luckCodeNum][1][1] = luckPool[luckCodeNum][1][1].add(_tempBalance.mul(30).div(100)); 
        luckPool[luckCodeNum][1][2] = luckPool[luckCodeNum][1][2].add(_tempBalance.mul(30).div(100)); 
        luckPool[luckCodeNum][1][3] = luckPool[luckCodeNum][1][3].add(_tempBalance.mul(40).div(100)); 
    }
    function getSurplusBalance(address _own) public view returns (uint, uint){
        Invest[] memory _orderList = investList[_own];
        uint _investCount = _orderList.length;
        uint _surplusBanalce = 0;
        uint _index = 0;
        for (uint i = 0; i < _investCount; i++) {
            if (_orderList[i].isFull == false) {
                _surplusBanalce = ((_orderList[i].balance).mul(_orderList[i].ratio)).sub(_orderList[i].profit);
                _index = i;
                break;
            }
        }
        return (_index, _surplusBanalce);
    }
    function setIncomeBurn(address _own,uint _balance) internal returns (uint) {
        uint _tempBalance = _balance;
        (uint _index, uint _surplusAmount) = getSurplusBalance(_own);
        if (_surplusAmount <= 0) {
            return 0;
        }
        if (_surplusAmount < _tempBalance) {
            _tempBalance = _surplusAmount;
            investList[_own][_index].isFull = true;
            investList[_own][_index].profit = (investList[_own][_index].balance).mul(investList[_own][_index].ratio);
        } else {
            investList[_own][_index].profit = (investList[_own][_index].profit).add(_tempBalance);
        }
        return _tempBalance;
    }
    function _setParentReward(address _own,uint _balance) internal{
        if(false == playerList[_own].isExist || false == playerList[_own].isParent || false == playerList[playerList[_own].parentAddress].isExist){
            return;
        }
        uint _tempBalance = _balance.mul(10).div(100);
        address _parent = playerList[_own].parentAddress;
        _tempBalance = setIncomeBurn(_parent,_tempBalance);
        addIncome(_parent,6,getNow(),_tempBalance,_own);
    }
    function _setSonsReward(address _own,uint _balance) internal{
        if(false == playerList[_own].isExist){
            return;
        }
        address[] memory _mySons = playerList[_own].sonAddress;
        uint _sonNum = _mySons.length;
        if(_sonNum <= 0){
            return;
        }
        uint _giveBalance = _balance.mul(10).div(100).div(_sonNum);
        for(uint i = 0;i < _mySons.length;i++){
            uint _tempBalance = _giveBalance;
            address _son = _mySons[i];
            _tempBalance = setIncomeBurn(_son,_tempBalance);
            addIncome(_son,7,getNow(),_tempBalance,_own);
        }
    }
    function _setParentAndSonReward(address _own,uint _balance) internal{
        _setParentReward(_own,_balance);
        _setSonsReward(_own,_balance);
    }
    function giveShare(address _own, uint _balance) public isCore{
        address[30] memory _progenitor = _getProgenitorAddress(_own);
        address[3] memory _parents;
        _parents[0] = _progenitor[0];
        _parents[1] = _progenitor[1];
        _parents[2] = _progenitor[2];
        uint[3] memory _ratio = [uint(9), 6, 3];
        for (uint i = 0; i < 3; i++) {
            if (playerList[_parents[i]].isExist) {
                uint _tempBalance = _balance.mul(_ratio[i]).div(100);
                _tempBalance = setIncomeBurn(_parents[i],_tempBalance);
                addIncome(_parents[i],1,getNow(),_tempBalance,_own);
                _setParentAndSonReward(_parents[i],_tempBalance);
            }
        }
    }
    function _getSon(address _own) internal view returns (address[] memory){
        address[] memory _sonList = playerList[_own].sonAddress;
        return _sonList;
    }
    function _getTeam(address _own) internal view returns (address[] memory){
        address[] memory _teamList = playerList[_own].teamAddress;
        return _teamList;
    }
    function _getTeamLevNum(address _own, uint _lev) internal view returns (uint, uint) {
        address[] memory _teamAddress = _getTeam(_own);
        uint _count = 0;
        uint _nowLevCount = 0;
        for (uint i = 0; i < _teamAddress.length; i++) {
            if (playerList[_teamAddress[i]].lev >= _lev) {
                _count = _count.add(1);
                if (playerList[_teamAddress[i]].lev == _lev) {
                    _nowLevCount = _nowLevCount.add(1);
                }
            }
        }
        if (playerList[_own].lev >= _lev) {
            _count = _count.add(1);
            if (playerList[_own].lev == _lev) {
                _nowLevCount = _nowLevCount.add(1);
            }
        }
        return (_count, _nowLevCount);
    }
    function getSystemTopLevUser() public view isCore returns (address[] memory) {
        address[] memory _addressList = topLevUser;
        return _addressList;
    }
    function _addAddressToSystem(address _own) internal {
        address[] memory _addressList = getSystemTopLevUser();
        bool _isExist = false;
        for (uint i = 0; i < _addressList.length; i++) {
            if (_addressList[i] == _own) {
                _isExist = true;
            }
        }
        if (false == _isExist) {
            topLevUser.push(_own);
        }
    }
    function _setLev1(address _own) internal {
        uint _ownBalance = playerList[_own].rechargeAmount;
        (uint _maxPerformance,uint _minPerformance) = getAreaPerformance(_own);
        uint _nowLev = playerList[_own].lev;
        if (_ownBalance >= 0 && _maxPerformance >= 30000e6 && _minPerformance >= 30000e6 && _nowLev < 1) {
            playerList[_own].lev = 1;
        }
    }
    function _setLev2(address _own, uint _setLevNum) internal {
        require(_setLevNum >= 2, "_setLevNum < 2");
        require(_setLevNum <= 4, "_setLevNum > 4");
        uint _ownBalance = playerList[_own].rechargeAmount;
        address[] memory _son = _getSon(_own);
        uint _teamCount = 0;
        for (uint i = 0; i < _son.length; i++) {
            (uint _tempCountGtLev,uint _tempCountNowLev) = _getTeamLevNum(_son[i], _setLevNum.sub(1));
            delete _tempCountNowLev;
            if (_tempCountGtLev > 0) {
                _teamCount = _teamCount.add(1);
            }
        }
        uint _minBalance = 0;
        if (_ownBalance >= _minBalance && _teamCount >= 2 && playerList[_own].lev < _setLevNum) {
            playerList[_own].lev = _setLevNum;
            if (_setLevNum == 4) {
                _addAddressToSystem(_own);
            }
        }
    }
    function _addLevNumToSystem(uint _lev) internal {
        require(_lev < 5);
        systemLevNum[_lev] = systemLevNum[_lev].add(1);
        if(_lev == 1){
            return;
        }
        if(systemLevNum[_lev.sub(1)] == 0){
            return;
        }
        systemLevNum[_lev.sub(1)] = systemLevNum[_lev.sub(1)].sub(1);
    }
    function _setLev(address _own) internal {
        _setLev1(_own);
        _setLev2(_own, 2);
        _setLev2(_own, 3);
        _setLev2(_own, 4);
    }
    function setParentLev(address _own) public isCore {
        address[30] memory _progenitor = _getProgenitorAddress(_own);
        _setLev(_own);
        for (uint i = 0; i < 30; i++) {
            if (true == playerList[_progenitor[i]].isExist) {
                _setLev(_progenitor[i]);
            }
        }
    }
    function setTeamLevReward(address _own, uint _balance) public isCore{
        uint[5] memory _teamLevRewardRatio = [0, uint(3), 6, 9, 12];
        address[30] memory _progenitor = _getProgenitorAddress(_own);
        uint _nowLev = playerList[_own].lev;
        teamLevReward[4] memory _teamLevRewardList;
        uint _index = 0;
        for (uint i = 0; i < 30; i++) {
            if (true == playerList[_progenitor[i]].isExist) {
                uint _tempPlayerLev = playerList[_progenitor[i]].lev;
                if (_tempPlayerLev > _nowLev) {
                    uint _ratio = _teamLevRewardRatio[_tempPlayerLev].sub(_teamLevRewardRatio[_nowLev]);
                    _teamLevRewardList[_index].playerAddress = _progenitor[i];
                    _teamLevRewardList[_index].ratio = _ratio;
                    _teamLevRewardList[_index].balance = _balance;
                    _teamLevRewardList[_index].fromAddress = _own;
                    _teamLevRewardList[_index].isExist = true;
                    _nowLev = _tempPlayerLev;
                    _index = _index.add(1);
                }
            }
        }
        for (uint j = 0; j < 4; j++) {
            if (true == _teamLevRewardList[j].isExist) {
                _setTeamLevRewardAct(_teamLevRewardList[j].playerAddress, _teamLevRewardList[j].balance, _teamLevRewardList[j].ratio, _teamLevRewardList[j].fromAddress);
            }
        }
    }
    function _setTeamLevRewardAct(address _own, uint _balance, uint _ratio, address _formAddress) internal {
        uint _tempBalance = (_balance.mul(_ratio)).div(100);
        (,uint _surplusAmount) = getSurplusBalance(_own);
        if (_surplusAmount <= 0) {
            return;
        }
        _tempBalance = setIncomeBurn(_own,_tempBalance);
        addIncome(_own,2,getNow(),_tempBalance,_formAddress);
        _setParentAndSonReward(_own,_tempBalance);
    }
    function _setLastPoolOverflowReward(uint _balance) internal {
        uint _giveBalance = _balance.mul(20).div(100);
        _setTopLevReward(_giveBalance);
    }
    function setTopLevReward(uint _balance) public isCore{
        _setTopLevReward(_balance);
    }
    function _setTopLevReward(uint _balance) internal {
        address[] memory topLevList = topLevUser;
        uint _topLevNum = topLevList.length;
        if (_topLevNum <= 0) {
            return;
        }
        uint _tempBalance = _balance.div(_topLevNum);
        for (uint i = 0; i < _topLevNum; i++) {
            addIncome(topLevList[i],4,getNow(),_tempBalance,tx.origin);
        }
    }
    function getEstimateReward(address _own) public isCore view returns(uint,uint){
        Invest[] memory _invest = investList[_own];
        uint _min;
        uint _max;
        for(uint i = 0;i < _invest.length;i++){
            if(true == _invest[i].isFull){
                continue;
            }
            Invest memory _tempInvest = _invest[i]; 
            (uint _num,uint _endTime,uint _beginTime) = _getCompInvestNum(_tempInvest.withdrawTime);
            _endTime.add(_beginTime);
            _min = _min.add((_invest[i].balance).mul(_num).mul(30).div(10000));
            _max = _max.add((_invest[i].balance).mul(_num).mul(180).div(10000));
        }
        return (_min,_max);
    }
    function _setStaticRewardToInvest(address _own, uint _index,uint _random,uint _actionTime) internal {
        Invest memory _invest = investList[_own][_index];
        if (_invest.isFull == true) {
            return;
        }
        uint _ratio = tool._createRandomNum(30, 150, _index.add(_random));
        uint _tempBalance = _invest.balance.mul(_ratio).div(10000);
        _tempBalance = setIncomeBurn(_own,_tempBalance);
        addIncome(_own,5,_actionTime,_tempBalance,address(0x00));
    }
    function _getCompInvestNum(uint _lastTime) public view returns(uint _num,uint _withdrawTime,uint _beginTime){
        uint _day = day;
        uint _nowTime = getNow();
        _nowTime = _nowTime.sub(_nowTime.mod(day));
        uint _extTime = _lastTime.mod(_day);
        if(_extTime != 0){
            _lastTime.sub(_extTime);
        }
        uint _dayNum;
        if(_nowTime < _lastTime){
            _dayNum = 0;
        }else{
            _dayNum = _nowTime.sub(_lastTime).div(_day);
        }
        return (_dayNum,_nowTime,_lastTime);
    }
    function _setInvestAllDayReward(address _own,uint _index) internal {
        uint _day = day;
        Invest memory _invest = investList[_own][_index];
        (uint _num,uint _endTime,uint _beginTime) = _getCompInvestNum(_invest.withdrawTime);
        for(uint i=0;i<_num;i++){
            _beginTime = _beginTime.add(_day);
            _setStaticRewardToInvest(_own,_index,i,_beginTime);
        }
        investList[_own][_index].withdrawTime = _endTime;
    }
    function setAllStaticReward(address _own) public isCore {
        Invest[] memory _ownInvest = investList[_own];
        for (uint i = 0; i < _ownInvest.length; i++) {
            _setInvestAllDayReward(_own, i);
        }
    }
    function getLastOpenLuckCodeList() public view returns(uint[] memory){
        require(luckCodeNum >= 0);
        uint[] memory _code;
        _code = luckCodeResList[luckCodeNum.sub(1)];
        return  _code;
    }
    function _getRewardList(address _own) internal view  returns (uint[9] memory){
        uint[9] memory _reward;
        Income[] memory _incomeList = incomeList[_own];
        for(uint i=0;i < _incomeList.length;i++){
            if(_incomeList[i].balance > 0){
                _reward[_incomeList[i].incomeType] = _reward[_incomeList[i].incomeType].add(_incomeList[i].balance);
            }
        }
        return _reward;
    }
    function getIncomeList(address _own) public view returns (uint[50] memory , uint[50] memory , uint[50] memory, address[50] memory ) {
        Income[] memory _incomeList = incomeList[_own];
        uint j = 0;
        uint[50] memory _type;
        uint[50] memory _createTime;
        uint[50] memory _balance;
        address[50] memory _address;
        for(uint i = _incomeList.length;i > 0;i--){
            if(j >= 50){
                break;
            }
            _type[j] = _incomeList[i.sub(1)].incomeType;
            _createTime[j] = _incomeList[i.sub(1)].createTime;
            _balance[j] = _incomeList[i.sub(1)].balance;
            _address[j] = _incomeList[i.sub(1)].fromAddress;
            j++;
        }
        return (_type,_createTime,_balance,_address);
    }
    function getMyReward(address _own) public view  returns (uint[9] memory){
        return _getRewardList(_own);
    }
    function _getDayMinInvest(Invest[21] memory _invest) internal pure returns (uint _value,uint _keyIndex){
        uint _minValue = 0;
        uint _index = 0;
        for(uint i = 0; i < 21;i++){
            if(_invest[i].balance  == 0){
                return (0,i);
            }
            if(_minValue == 0){
                _minValue = _invest[i].balance;
                _index = i;
            }
            if(_minValue > _invest[i].balance){
                _minValue = _invest[i].balance;
                _index = i;
            }
        }
        return (_minValue,_index);
    }
    function _setSortInvest(Invest[21] memory _invest) internal pure returns (Invest[21] memory){
        for(uint i = 0;i < 21;i++){
            for(uint j = i+1;j < 21;j++){
                if(_invest[i].balance < _invest[j].balance){
                    (_invest[i], _invest[j]) = (_invest[j], _invest[i]);
                }
            }
        }
        return _invest;
    }
    function _getLuckInvestList(bool _flag) internal view  returns (Invest[21] memory){
        uint _lastTime;
        uint _endTime;
        if(true == _flag){
            _lastTime = lastLuckOpenTime;
            _endTime = getNow();
        }else{
            _lastTime = 0;
            _endTime = getNow();
        }
        Invest[] memory _allInvest = systemInvest;
        uint _allInvestNum = _allInvest.length;
        require (_allInvestNum > 0);
        _allInvestNum = _allInvestNum;
        uint _endIndex;
        bool _endFlag = false;
        uint _startIndex;

        for(;_allInvestNum > 0;_allInvestNum--){
            if(_allInvest[_allInvestNum.sub(1)].createTime < _lastTime){
                break;
            }
            if(_allInvest[_allInvestNum.sub(1)].createTime <= _endTime){
                if(false == _endFlag){
                    _endIndex = _allInvestNum.sub(1);
                    _endFlag = true;
                }
                _startIndex = _allInvestNum.sub(1);
            }
        }
        Invest[21] memory _dayMaxInvest;
        for(uint i = _startIndex;i <= _endIndex;i++){
            (uint _minValue,uint _minIndex) = _getDayMinInvest(_dayMaxInvest);
            if(_minValue < _allInvest[i].balance){
                _dayMaxInvest[_minIndex] = _allInvest[i];
            }
        }
        _dayMaxInvest = _setSortInvest(_dayMaxInvest);
        return _dayMaxInvest;
    }
    function getInvestList(bool _flag) public view isCore returns (address[21] memory) {
        Invest[21] memory investList = _getLuckInvestList(_flag);
        address[21] memory _address;
        for(uint i = 0; i < 21;i++){
            _address[i] = investList[i].own;
        }
        return _address;
    }
    function getSystemInvestLength() public view isCore returns (uint){
        return systemInvest.length;
    }
    function getSystemInvestInfo(uint _index) public view isCore returns (address,uint){
        return (systemInvest[_index].own,systemInvest[_index].createTime);
    }
    function getLuckCode(address _own) public view returns(uint[100] memory){
        address[] memory _luckCodeList = luckCodeList[luckCodeNum];
        uint[100] memory _code;
        uint j = 0;
        for(uint i = 0; i< _luckCodeList.length;i++){
            if(j >= 100){
                continue;
            }
            if(_luckCodeList[i] == _own){
                _code[j] = i;
                j++;
            }
        }
        return _code;
    }
    function openReward() public isCore{
        uint _nowTime = getNow();
        uint _day = day;
        if(_nowTime.sub(luckCodeLastTime) <= _day){
            return;
        }
        openLuckInvestReward();
        openLuckCodeReward();
        luckCodeLastTime = getNow();
    }
    function openLastPoolReward() public isCore{
        Invest[] memory _investList = systemInvest;
        uint _length = systemInvest.length;
        uint _index = _length.sub(1);
        address[568] memory _player;
        for(uint i=0;i<568;i++){
            _player[i] = _investList[_index].own;
            if(_index == 0){
                break;
            }
            _index = _index.sub(1);
        }
        uint _num1 = lastPool.mul(10).div(100).div(8);
        uint _num2 = lastPool.mul(20).div(100).div(60);
        uint _num3 = lastPool.mul(70).div(100).div(500);
        lastPool = 0;
        for(uint j = 0;j<568;j++){
            if(_player[j] == address(0x00)){
                break;
            }
            if(j < 8){
                addIncome(_player[j],3,getNow(),_num1,address(0x00));
            }else if(j < 68){
                addIncome(_player[j],3,getNow(),_num2,address(0x00));
            }else{
                addIncome(_player[j],3,getNow(),_num3,address(0x00));
            }
        }
    }
    mapping(uint=>uint[4][2]) public luckPool;
    uint luckNum = 1;
    uint luckInvestNum = 1;
    uint public systemPlayerNum;
    mapping(address => Player) public playerList;
    address[] public topLevUser;
    Invest[] public systemInvest;
    mapping(address => Income[]) public incomeList;
    mapping(address => Invest[]) public investList;
    mapping(uint =>address[]) public luckCodeList;
    mapping(uint =>uint[]) public luckCodeResList;
    mapping(uint =>uint) public luckCodeBurnTokenNum;
    mapping(uint =>uint) public investTokenUsdtNum;
    uint public luckCodeNum = 1;
    uint public luckCodeLastTime = now;
    uint public lastLuckOpenTime = now;
    uint luckInvestCycle = day;
    uint public lastPool;
    uint public lastTime;
    uint[5] public systemLevNum; 
    struct Player {
        uint lev;
        uint withdrawAmount;
        uint allIncome;
        uint rechargeAmount;
        uint teamRechargeAmount;
        uint lastWithdrawTime;
        bool isExist;
        bool isParent;
        address parentAddress;
        address[] sonAddress;
        address [] teamAddress;
    }
    struct Income {
        uint incomeType;
        uint createTime;
        uint balance;
        address fromAddress;
    }
    struct Invest{
        address own;
        uint createTime;
        uint withdrawTime;
        uint balance;
        uint ratio;
        uint profit;
        bool isFull;
    }
    struct luckIncome{
        uint balance;
        address own;
    }
    struct luckIncomeHistory{
        uint num;
        luckIncome[] list;
        bool isExist;
    }
    struct teamLevReward{
        address playerAddress;
        address fromAddress;
        uint ratio;
        uint balance;
        bool isExist;
    }
}
abstract contract Tool {
    function _getNeedTicketNum(uint _balance) view public virtual returns (uint);
    function _getRatio(uint _balance) pure public virtual returns (uint);
    function _createRandomNum(uint _min, uint _max, uint _randNonce) public virtual view returns (uint);
    function _crateLuckCodeList(uint _max) public view virtual returns (uint[25] memory);
}