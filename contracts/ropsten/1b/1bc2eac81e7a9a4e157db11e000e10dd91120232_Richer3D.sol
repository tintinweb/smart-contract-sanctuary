pragma solidity ^0.4.25;

contract Richer3D {
    using SafeMath for *;
    
    //************
    //Game Setting
    //************
    string constant public name = "Richer3D";
    string constant public symbol = "R3D";
    address constant private sysAdminAddress = 0x4A3913ce9e8882b418a0Be5A43d2C319c3F0a7Bd;
    address constant private sysInviterAddress = 0xC5E41EC7fa56C0656Bc6d7371a8706Eb9dfcBF61;
    address constant private sysDevelopAddress = 0xCf3A25b73A493F96C15c8198319F0218aE8cAA4A;
    address constant private p3dInviterAddress = 0x82Fc4514968b0c5FdDfA97ed005A01843d0E117d;
    uint256 constant cycleTime = 5 minutes;
    //************
    //Game Data
    //************
    uint256 private roundNumber;
    uint256 private dayNumber;
    uint256 private totalPlayerNumber;
    uint256 private platformBalance;
    //*************
    //Game DataBase
    //*************
    mapping(uint256=>DataModal.RoundInfo) private rInfoXrID;
    mapping(address=>DataModal.PlayerInfo) private pInfoXpAdd;
    mapping(address=>uint256) private pIDXpAdd;
    mapping(uint256=>address) private pAddXpID;
    
    //*************
    // P3D Data
    //*************
    //Ropsten
    HourglassInterface constant p3dContract = HourglassInterface(0xEE8A59A44b61976413EFf4AB544F664d3D0Ca74A);
    //Rinkeby
    // HourglassInterface constant p3dContract = HourglassInterface(0xD42E58289fc3D595a83996753a5a0cDCCdE4ecDb);
    uint256 private p3dDivides;
    uint256 private p3dTokens;
    mapping(uint256=>uint256) private p3dDividesXroundID;
    mapping(uint256=>uint256) private p3dAmountXroundID;
    
    //*************
    //Game Events
    //*************
    event newPlayerJoinGameEvent(address indexed _address,uint256 indexed _amount,bool indexed _JoinWithEth,uint256 _timestamp);
    event calculateTargetEvent(uint256 indexed _roundID);
    
    constructor() public {
        dayNumber = 1;
    }
    
    function() external payable {}
    
    //************
    //Game payable
    //************
    function joinGameWithInviterID(uint256 _inviterID) public payable {
        // require(msg.value >= 0.01 ether,"You need to pay 0.01 eth at least");
        // require(now.sub(rInfoXrID[roundNumber].lastCalculateTime) < cycleTime,"Waiting for settlement");
        if(pIDXpAdd[msg.sender] < 1) {
            registerWithInviterID(_inviterID);
        }
        buyCore(pInfoXpAdd[msg.sender].inviterAddress,msg.value);
        emit newPlayerJoinGameEvent(msg.sender,msg.value,true,now);
    }
    
    //********************
    // Method need Gas
    //********************
    function joinGameWithBalance(uint256 _amount) public payable {
        require(msg.value >= 0.01 ether,"You need to pay 0.01 eth at least");
        require(now.sub(rInfoXrID[roundNumber].lastCalculateTime) < cycleTime,"Waiting for settlement");
        uint256 balance = getUserBalance(msg.sender);
        require(balance >= _amount.mul(11).div(10),"balance is not enough");
        platformBalance = platformBalance.add(_amount.div(10));
        buyCore(pInfoXpAdd[msg.sender].inviterAddress,_amount);
        pInfoXpAdd[msg.sender].withDrawNumber = pInfoXpAdd[msg.sender].withDrawNumber.sub(_amount.div(10).mul(11));
        emit newPlayerJoinGameEvent(msg.sender,_amount,false,now);
    }
    
    function calculateTarget() public {
        require(now.sub(rInfoXrID[roundNumber].lastCalculateTime) >= cycleTime,"Less than cycle Time from last operation");
        //查询每日p3d分成，并提现到合约
        uint256 dividends = p3dContract.myDividends(true);
        if(dividends > 0) {
            p3dDividesXroundID[roundNumber] = p3dDividesXroundID[roundNumber].add(dividends);
            p3dAmountXroundID[roundNumber] = p3dAmountXroundID[roundNumber].add(p3dContract.balanceOf(address(this))).sub(p3dTokens);
            p3dContract.withdraw();
            p3dDivides = p3dDivides.add(dividends);
        }
        uint256 increaseBalance = getIncreaseBalance(dayNumber,roundNumber);
        uint256 targetBalance = getDailyTarget(roundNumber,dayNumber);
        if(increaseBalance >= targetBalance) {
            //购买P3D，购买金额为每日新增投资额的1%
            if(getIncreaseBalance(dayNumber,roundNumber) > 0) {
                p3dContract.buy.value(getIncreaseBalance(dayNumber,roundNumber).div(100))(p3dInviterAddress);
            }
            //continue
            dayNumber = dayNumber.add(1);
            rInfoXrID[roundNumber].totalDay = dayNumber;
            if(rInfoXrID[roundNumber].startTime == 0) {
                rInfoXrID[roundNumber].startTime = now;
                rInfoXrID[roundNumber].lastCalculateTime = now;
            } else {
                rInfoXrID[roundNumber].lastCalculateTime = rInfoXrID[roundNumber].startTime.add((cycleTime).mul(dayNumber.sub(1)));   
            }
            emit calculateTargetEvent(0);
        } else {
            //Game over, start new round
            // p3dTokens = p3dContract.balanceOf(address(this));
            bool haveWinner = false;
            if(dayNumber > 1) {
                sendBalanceForDevelop(roundNumber);
                haveWinner = true;
            }
            rInfoXrID[roundNumber].winnerDay = dayNumber.sub(1);
            roundNumber = roundNumber.add(1);
            dayNumber = 1;
            if(haveWinner) {
                rInfoXrID[roundNumber].bounsInitNumber = getBounsWithRoundID(roundNumber.sub(1)).div(10);
            } else {
                rInfoXrID[roundNumber].bounsInitNumber = getBounsWithRoundID(roundNumber.sub(1));
            }
            rInfoXrID[roundNumber].totalDay = 1;
            rInfoXrID[roundNumber].startTime = now;
            rInfoXrID[roundNumber].lastCalculateTime = now;
            emit calculateTargetEvent(roundNumber);
        }
    }

    function registerWithInviterID(uint256 _inviterID) private {
        totalPlayerNumber = totalPlayerNumber.add(1);
        pIDXpAdd[msg.sender] = totalPlayerNumber;
        pAddXpID[totalPlayerNumber] = msg.sender;
        pInfoXpAdd[msg.sender].inviterAddress = pAddXpID[_inviterID];
    }
    
    function buyCore(address _inviterAddress,uint256 _amount) private {
        //for inviter
        if(_inviterAddress == 0x0 || _inviterAddress == msg.sender) {
            platformBalance = platformBalance.add(_amount/10);
        } else {
            pInfoXpAdd[_inviterAddress].inviteEarnings = pInfoXpAdd[_inviterAddress].inviteEarnings.add(_amount/10);
        }
        uint256 playerIndex = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber.add(1);
        if(rInfoXrID[roundNumber].numberXaddress[msg.sender] == 0) {
            rInfoXrID[roundNumber].number = rInfoXrID[roundNumber].number.add(1);
            rInfoXrID[roundNumber].numberXaddress[msg.sender] = rInfoXrID[roundNumber].number;
            rInfoXrID[roundNumber].addressXnumber[rInfoXrID[roundNumber].number] = msg.sender;
        }
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber = playerIndex;
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].addXIndex[playerIndex] = msg.sender;
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].indexXAddress[msg.sender] = playerIndex;
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].amountXIndex[playerIndex] = _amount;
    }
    
    function playerWithdraw(uint256 _amount) public {
        uint256 balance = getUserBalance(msg.sender);
        require(balance>=_amount,"amount out of limit");
        msg.sender.transfer(_amount);
        pInfoXpAdd[msg.sender].withDrawNumber = pInfoXpAdd[msg.sender].withDrawNumber.add(_amount);
    }
    
    function sendBalanceForDevelop(uint256 _roundID) private {
        uint256 bouns = getBounsWithRoundID(_roundID).div(5);
        sysDevelopAddress.transfer(bouns.div(2));
        sysInviterAddress.transfer(bouns.div(2));
    }
    
    //********************
    // Calculate Data
    //********************
    function getBounsWithRoundID(uint256 _roundID) private view returns(uint256 _bouns) {
        _bouns = _bouns.add(rInfoXrID[_roundID].bounsInitNumber);
        for(uint256 d=1;d<=rInfoXrID[_roundID].totalDay;d++){
            for(uint256 i=1;i<=rInfoXrID[_roundID].dayInfoXDay[d].playerNumber;i++) {
                uint256 amount = rInfoXrID[_roundID].dayInfoXDay[d].amountXIndex[i];
                _bouns = _bouns.add(amount.mul(891).div(1000));  
            }
            for(uint256 j=1;j<=rInfoXrID[_roundID].number;j++) {
                address address2 = rInfoXrID[_roundID].addressXnumber[j];
                if(d>=2) {
                    _bouns = _bouns.sub(getTransformMineInDay(address2,_roundID,d.sub(1)));
                } else {
                    _bouns = _bouns.sub(getTransformMineInDay(address2,_roundID,d));
                }
            }
        }
        return(_bouns);
    }
    
    function getIncreaseBalance(uint256 _dayID,uint256 _roundID) private view returns(uint256 _balance) {
        for(uint256 i=1;i<=rInfoXrID[_roundID].dayInfoXDay[_dayID].playerNumber;i++) {
            uint256 amount = rInfoXrID[_roundID].dayInfoXDay[_dayID].amountXIndex[i];
            _balance = _balance.add(amount);   
        }
        _balance = _balance.mul(9).div(10);
        return(_balance);
    }
    
    function getMineInfoInDay(address _userAddress,uint256 _roundID, uint256 _dayID) private view returns(uint256 _totalMine,uint256 _myMine,uint256 _additional) {
        for(uint256 i=1;i<=_dayID;i++) {
            for(uint256 j=1;j<=rInfoXrID[_roundID].dayInfoXDay[i].playerNumber;j++) {
                address userAddress = rInfoXrID[_roundID].dayInfoXDay[i].addXIndex[j];
                uint256 amount = rInfoXrID[_roundID].dayInfoXDay[i].amountXIndex[j];
                if(_totalMine == 0) {
                    _totalMine = _totalMine.add(amount.mul(5));
                    if(userAddress == _userAddress){
                        _myMine = _myMine.add(amount.mul(5));
                    }
                } else {
                    uint256 addPart = (amount.mul(5)/2).mul(_myMine)/_totalMine;
                    _totalMine = _totalMine.add(amount.mul(15).div(2));
                    if(userAddress == _userAddress){
                        _myMine = _myMine.add(amount.mul(5)).add(addPart);    
                    }else {
                        _myMine = _myMine.add(addPart);
                    }
                    _additional = _additional.add(addPart);
                }
            }
        }
        return(_totalMine,_myMine,_additional);
    }
    
    function getTransformRate(address _userAddress,uint256 _roundID,uint256 _dayID) private view returns(uint256 _rate) {
        (,uint256 userMine,) = getMineInfoInDay(_userAddress,_roundID,_dayID);
        if(userMine > 0) {
            uint256 rate = userMine.mul(4).div(1000000000000000000).add(40);
            if(rate >80)                              
                return(80);
            else
                return(rate);        
        } else {
            return(40);
        }
    }
    
    function getTransformMineInDay(address _userAddress,uint256 _roundID,uint256 _dayID) private view returns(uint256 _transformedMine) {
        (,uint256 userMine,) = getMineInfoInDay(_userAddress,_roundID,_dayID.sub(1));
        uint256 rate = getTransformRate(_userAddress,_roundID,_dayID.sub(1));
        _transformedMine = userMine.mul(rate).div(10000);
        return(_transformedMine);
    }
    
    function calculateTotalMinePay(uint256 _roundID,uint256 _dayID) public view returns(uint256 _needToPay) {
        (uint256 mine,,) = getMineInfoInDay(msg.sender,_roundID,_dayID.sub(1));
        _needToPay = mine.mul(8).div(1000);
        return(_needToPay);
    }
    
    function getDailyTarget(uint256 _roundID,uint256 _dayID) private view returns(uint256) {
        uint256 needToPay = calculateTotalMinePay(_roundID,_dayID);
        uint256 target = 0;
        if (_dayID > 20) {
            target = (SafeMath.pwr(((5).mul(_dayID).sub(100)),3).add(1000000)).mul(needToPay).div(1000000);
            return(target);
        } else {
            target = ((1000000).sub(SafeMath.pwr((100).sub((5).mul(_dayID)),3))).mul(needToPay).div(1000000);
            if(target == 0) target = 0.0063 ether;
            return(target);            
        }
    }
    
    function getUserBalance(address _userAddress) private view returns(uint256 _balance) {
        if(pIDXpAdd[_userAddress] == 0) {
            return(0);
        }
        uint256 withDrawNumber = pInfoXpAdd[_userAddress].withDrawNumber;
        uint256 totalTransformed = 0;
        for(uint256 i=1;i<=roundNumber;i++) {
            for(uint256 j=1;j<rInfoXrID[i].totalDay;j++) {
                totalTransformed = totalTransformed.add(getTransformMineInDay(_userAddress,i,j));
            }
        }
        uint256 inviteEarnings = pInfoXpAdd[_userAddress].inviteEarnings;
        _balance = totalTransformed.add(inviteEarnings).add(getBounsEarnings(_userAddress)).add(getHoldEarnings(_userAddress)).add(pInfoXpAdd[_userAddress].p3dDividesEarnings).sub(withDrawNumber);
        return(_balance);
    }
    
    function getBounsEarnings(address _userAddress) private view returns(uint256 _bounsEarnings) {
        for(uint256 i=1;i<roundNumber;i++) {
            uint256 winnerDay = rInfoXrID[i].winnerDay;
            uint256 myAmountInWinnerDay=0;
            uint256 totalAmountInWinnerDay=0;
            if(winnerDay == 0) {
                _bounsEarnings = _bounsEarnings;
            } else {
                for(uint256 player=1;player<=rInfoXrID[i].dayInfoXDay[winnerDay].playerNumber;player++) {
                    address useraddress = rInfoXrID[i].dayInfoXDay[winnerDay].addXIndex[player];
                    uint256 amount = rInfoXrID[i].dayInfoXDay[winnerDay].amountXIndex[player];
                    if(useraddress == _userAddress) {
                        myAmountInWinnerDay = myAmountInWinnerDay.add(amount);
                    }
                    totalAmountInWinnerDay = totalAmountInWinnerDay.add(amount);
                }
                uint256 bouns = getBounsWithRoundID(i).mul(18).div(25);
                _bounsEarnings = _bounsEarnings.add(bouns.mul(myAmountInWinnerDay).div(totalAmountInWinnerDay));
            }
        }
        return(_bounsEarnings);
    }

    function getHoldEarnings(address _userAddress) private view returns(uint256 _holdEarnings) {
        for(uint256 i=1;i<roundNumber;i++) {
            uint256 winnerDay = rInfoXrID[i].winnerDay;
            if(winnerDay == 0) {
                _holdEarnings = _holdEarnings;
            } else {  
                (uint256 totalMine,uint256 myMine,) = getMineInfoInDay(_userAddress,i,rInfoXrID[i].totalDay);
                uint256 bouns = getBounsWithRoundID(i).mul(7).div(50);
                _holdEarnings = _holdEarnings.add(bouns.mul(myMine).div(totalMine));    
            }
        }
        return(_holdEarnings);
    }
    
    //*******************
    // UI 
    //*******************
    //查询防守方地址列表
    function getDefendPlayerList() public view returns(address[]) {
        if (rInfoXrID[roundNumber].dayInfoXDay[dayNumber-1].playerNumber == 0) {
            address[] memory playerListEmpty = new address[](0);
            return(playerListEmpty);
        }        
        address[] memory playerList = new address[](rInfoXrID[roundNumber].dayInfoXDay[dayNumber-1].playerNumber);
        for(uint256 i=0;i<rInfoXrID[roundNumber].dayInfoXDay[dayNumber-1].playerNumber;i++) {
            playerList[i] = rInfoXrID[roundNumber].dayInfoXDay[dayNumber-1].addXIndex[i+1];
        }
        return(playerList);
    }
    
    //查询攻占方地址列表
    function getAttackPlayerList() public view returns(address[]) {
        address[] memory playerList = new address[](rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber);
        for(uint256 i=0;i<rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber;i++) {
            playerList[i] = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].addXIndex[i+1];
        }
        return(playerList);
    }
    
    //查询当前矿场收益及每日目标，返回结果依次为轮次、矿场收益，今天新增的投资额，今天的目标值
    function getCurrentFieldBalanceAndTarget() public view returns(uint256 day,uint256 bouns,uint256 todayBouns,uint256 dailyTarget) {
        uint256 fieldBalance = getBounsWithRoundID(roundNumber).mul(7).div(10);
        uint256 todayBalance = getIncreaseBalance(dayNumber,roundNumber) ;
        dailyTarget = getDailyTarget(roundNumber,dayNumber);
        return(dayNumber,fieldBalance,todayBalance,dailyTarget);
    }
    
    //查询用户ID及邀请奖励
    function getUserIDAndInviterEarnings() public view returns(uint256 userID,uint256 inviteEarning) {
        return(pIDXpAdd[msg.sender],pInfoXpAdd[msg.sender].inviteEarnings);
    }
    
    //查询当前局的信息 依次返回第几局、第几轮、当前的矿石总量、本局游戏的开始时间、最近一次结算的结算时
    function getCurrentRoundInfo() public view returns(uint256 _roundID,uint256 _dayNumber,uint256 _ethMineNumber,uint256 _startTime,uint256 _lastCalculateTime) {
        DataModal.RoundInfo memory roundInfo = rInfoXrID[roundNumber];
        (uint256 totalMine,,) = getMineInfoInDay(msg.sender,roundNumber,dayNumber);
        return(roundNumber,dayNumber,totalMine,roundInfo.startTime,roundInfo.lastCalculateTime);
    }
    
    //查询用户资产，依次返回用户持有矿石数量，额外收到的矿石，当前的转化率，eth余额，本轮已经转化的eth，今天可以转化的矿石，今天可以领取的eth，是否以及领取过转化矿石
    function getUserProperty() public view returns(uint256 ethMineNumber,uint256 holdEarning,uint256 transformRate,uint256 ethBalance,uint256 ethTranslated,uint256 ethMineCouldTranslateToday,uint256 ethCouldGetToday) {
        if(pIDXpAdd[msg.sender] <1) {
            return(0,0,0,0,0,0,0);        
        }
        (,uint256 myMine,uint256 additional) = getMineInfoInDay(msg.sender,roundNumber,dayNumber);
        ethMineNumber = myMine;
        holdEarning = additional;
        transformRate = getTransformRate(msg.sender,roundNumber,dayNumber);      
        ethBalance = getUserBalance(msg.sender);
        uint256 totalTransformed = 0;
        for(uint256 i=1;i<rInfoXrID[roundNumber].totalDay;i++) {
            totalTransformed = totalTransformed.add(getTransformMineInDay(msg.sender,roundNumber,i));
        }
        ethTranslated = totalTransformed;
        ethCouldGetToday = getTransformMineInDay(msg.sender,roundNumber,dayNumber);
        ethMineCouldTranslateToday = myMine.mul(transformRate).div(10000);
        return(
            ethMineNumber,
            holdEarning,
            transformRate,
            ethBalance,
            ethTranslated,
            ethMineCouldTranslateToday,
            ethCouldGetToday
            );
    }
    
    //查询创始团队收益
    function getPlatformBalance() public view returns(uint256 _platformBalance) {
        require(msg.sender == sysAdminAddress,"Ummmmm......Only admin could do this");
        return(platformBalance);
    }
    
    //创始团队提现
    function withdrawForAdmin(address _toAddress,uint256 _amount) public {
        require(msg.sender==sysAdminAddress,"You are not the admin");
        require(platformBalance>=_amount,"Lack of balance");
        _toAddress.transfer(_amount);
        platformBalance = platformBalance.sub(_amount);
    }
    
    //************
    //统计后台
    //************
    function getDataOfGame() public view returns(uint256 _playerNumber,uint256 _dailyIncreased,uint256 _dailyTransform,uint256 _contractBalance,uint256 _userBalanceLeft,uint256 _platformBalance,uint256 _mineBalance,uint256 _balanceOfMine) {
        for(uint256 i=1;i<=totalPlayerNumber;i++) {
            address userAddress = pAddXpID[i];
            _userBalanceLeft = _userBalanceLeft.add(getUserBalance(userAddress));
        }
        return(
            totalPlayerNumber,
            getIncreaseBalance(dayNumber,roundNumber),
            calculateTotalMinePay(roundNumber,dayNumber),
            address(this).balance,
            _userBalanceLeft,
            platformBalance,
            getBounsWithRoundID(roundNumber),
            getBounsWithRoundID(roundNumber).mul(7).div(10)
            );
    }
    
    //查询参与用户地址列表，根据ID升序
    function getUserAddressList() public view returns(address[]) {
        address[] memory addressList = new address[](totalPlayerNumber);
        for(uint256 i=0;i<totalPlayerNumber;i++) {
            addressList[i] = pAddXpID[i+1];
        }
        return(addressList);
    }
    
    //查询用户信息列表， 依次为持有矿石数量、转化率、额外矿石收益、eth收益余额、历史eth总收益、邀请奖励、累计转化的eth
    function getUsersInfo() public view returns(uint256[7][]){
        uint256[7][] memory infoList = new uint256[7][](totalPlayerNumber);
        for(uint256 i=0;i<totalPlayerNumber;i++) {
            address userAddress = pAddXpID[i+1];
            (,uint256 myMine,uint256 additional) = getMineInfoInDay(userAddress,roundNumber,dayNumber);
            uint256 totalTransformed = 0;
            for(uint256 j=1;j<=roundNumber;j++) {
                for(uint256 k=1;k<=rInfoXrID[j].totalDay;k++) {
                    totalTransformed = totalTransformed.add(getTransformMineInDay(userAddress,j,k));
                }
            }
            infoList[i][0] = myMine ;
            infoList[i][1] = getTransformRate(userAddress,roundNumber,dayNumber);
            infoList[i][2] = additional;
            infoList[i][3] = getUserBalance(userAddress);
            infoList[i][4] = getUserBalance(userAddress).add(pInfoXpAdd[userAddress].withDrawNumber);
            infoList[i][5] = pInfoXpAdd[userAddress].inviteEarnings;
            infoList[i][6] = totalTransformed;
        }        
        return(infoList);
    }
    
    //查询用户P3D信息 依次返回本P3D token的数量、分成金额、我的token数量、我的分成金额
    function getUserP3DInfo() public view returns(uint256 _p3dTokenInRound,uint256 _p3dDivideInRound,uint256 _myP3D,uint256 _myP3DDivide) {
        if(rInfoXrID[roundNumber].winnerDay == 0) {
            return(0,0,0,0);
        }
        uint256 lastDay = rInfoXrID[roundNumber].totalDay;
        (uint256 _totalBefore,uint256 _myBefore,) = getMineInfoInDay(msg.sender,roundNumber,lastDay.sub(1));
        (uint256 _total,uint256 _my,) = getMineInfoInDay(msg.sender,roundNumber,lastDay);
        _p3dDivideInRound =p3dDividesXroundID[roundNumber];
        _p3dTokenInRound = p3dAmountXroundID[roundNumber];
        if(pInfoXpAdd[msg.sender].P3DrecieveXRoundID[roundNumber] == true) {
           _myP3D = 0;
           _myP3DDivide = 0;
        } else {
            _myP3D = _p3dTokenInRound.mul((_my.sub(_myBefore))).div(_total.sub(_totalBefore));
            _myP3DDivide = _p3dDivideInRound.mul((_my.sub(_myBefore))).div(_total.sub(_totalBefore));    
        }
        return(_p3dDivideInRound,_p3dDivideInRound,_myP3D,_myP3DDivide);
    }
    
    //用户领取P3D收益
    function P3DReceive() public {
        (,,uint256 _myP3D,uint256 _myP3DDivide) = getUserP3DInfo();
        if(_myP3D > 0) {
            p3dContract.transfer(msg.sender,_myP3D);
            p3dTokens = p3dTokens.sub(_myP3D);
            p3dDivides = p3dDivides.sub(_myP3DDivide);
            pInfoXpAdd[msg.sender].p3dDividesEarnings = pInfoXpAdd[msg.sender].p3dDividesEarnings.add(_myP3DDivide);
            pInfoXpAdd[msg.sender].P3DrecieveXRoundID[roundNumber] = true;
        }
    }
}

//P3D合约接口
interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
    function balanceOf(address _customerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
}

library DataModal {
    struct PlayerInfo {
        uint256 inviteEarnings;
        address inviterAddress;
        uint256 withDrawNumber;
        uint256 p3dDividesEarnings;
        mapping(uint256=>bool)P3DrecieveXRoundID;
    }
    
    struct DayInfo {
        uint256 playerNumber;
        mapping(uint256=>address) addXIndex;
        mapping(uint256=>uint256) amountXIndex;
        mapping(address=>uint256) indexXAddress;
    }
    
    struct RoundInfo {
        uint256 startTime;
        uint256 lastCalculateTime;
        uint256 bounsInitNumber;
        uint256 totalDay;
        uint256 winnerDay;
        mapping(uint256=>DayInfo) dayInfoXDay;
        mapping(uint256=>address) addressXnumber;
        mapping(address=>uint256) numberXaddress;
        uint256 number;
    }
}

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath div failed");
        uint256 c = a / b;
        return c;
    } 

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}