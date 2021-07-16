//SourceUnit: lottery.sol

pragma solidity ^0.5.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library TransferHelper {
    function safeTransferTrx(address to, uint256 value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper::safeTransferTRX: TRX transfer failed');
    }
}


contract LotteryConfig {
    uint256 public constant ONE_DAY = 24 * 60 * 60;
    uint256[15] public LOSS_LEADER_BONUS_PERCENTS = [10, 6, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2];
    uint256 public BET_LOSS_PERCENT = 20;
    uint256 public LOSS_SPEEDUP_PERCENT = 10;
}

contract Lottery is LotteryConfig {
    using SafeMath for uint256;

    struct BetInfo {
        uint256 no;
        bool isOpen;
        uint256 startTime;
        uint256 endTime;
        uint betPersonCount;
        uint betIdMin;
        uint betIdMax;
        uint[5] lotteryNumber;
        BetRecord[] betRecords;
    }

    struct BetRecord {
        uint betId;
        bool isWin;
        bool isOpen;
        uint no;
        uint userId;
        uint amount;
        uint[] lotteryNumber;
        uint lotteryDigits;
        uint256 withdrawStartTime;
        uint256 withdrawEndTime;
        uint256 withdrawAmount;
        uint256 withdrawAlreadyAmount;
    }

    struct Player {
        uint id;
        bool isBet;
        uint256 refsCount;
        uint256 teamCount;
        uint256 withdrawWallet;
        uint256 speedUpWallet;
        uint256 teamPerformance;
        address referrer;
        uint256 leaderWallet;
        uint256 WithdrawAmount;
        uint256 teamAmount;
        uint256 costAmount;
        uint256 refsPerformance;
        uint256 backLossAmount;
        mapping(uint256 => BetRecord) betRecords;
    }

    uint public lastBetid = 0;
    uint public lastUserId = 1009;
    RankPool rankPool;
    address private owner;
    address private techAddress;
    address private rankPoolAddress;
    uint public rankNum = 1;
    uint256[5] public rankPercent = [5, 4, 3, 2, 1];

    mapping(address => Player) public players;
    mapping(uint => address) public idToAddress;
    mapping(uint256 => BetInfo) public betInfos;
    mapping(uint256 => BetRecord) public betRecord;
    mapping(uint256 => address[5]) public performanceRank;
    mapping(uint256 => mapping(address => uint256)) public performances;

    event Bet(uint indexed userId, uint one, uint ten, uint hundred, uint thousand, uint tenThousand, uint lotteryDigits, uint no, uint betId);
    event OpenBet(uint no, uint one, uint ten, uint hundred, uint thousand, uint tenThousand);
    event WriteBetInfo(uint no);
    event BetWin(uint no, uint indexed userId, uint unit, uint number, uint betId);
    event BetLoss(uint no, uint indexed userId, uint betId, uint backLossAmount);
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event LossLeaderBonus(uint indexed userId, uint amount, uint betId, uint typeId, uint resTime); 
    event walletDetail(uint indexed userId, uint amount, uint betId, uint typeId, uint resTime); 

    constructor(address _owners, address _techAddress, address _rankPoolAddress) public {
        owner = _owners;
        techAddress = _techAddress;
        rankPool = RankPool(_rankPoolAddress);
        rankPoolAddress = _rankPoolAddress;
        players[owner].id = 1009;
        players[owner].referrer = address(0);
        players[owner].refsCount = 0;
        idToAddress[1009] = owner;
    }

    function writeBetInfo(uint256 no, uint256 startTime, uint256 endTime) public {
        require(owner == msg.sender, "Insufficient permissions");
        require(betInfos[no].no == 0, "bet info exists");
        require(startTime < endTime, "start time must be < end time");

        betInfos[no].no = no;
        betInfos[no].startTime = startTime;
        betInfos[no].endTime = endTime;
        betInfos[no].isOpen = false;
        betInfos[no].betPersonCount = 0;

        emit WriteBetInfo(no);
    }

    function openBet(uint256 no, uint[5] memory lotteryNumber, uint[] memory betIds) public {
        require(owner == msg.sender, "Insufficient permissions");
        require(lotteryNumber.length == 5, "lottery number must be 5");
        require(betInfos[no].no != 0, "bet info not exists");
        //require(!betInfos[no].isOpen, "bet is opened");
        require(betInfos[no].betRecords.length > 0, "not user bet");
        
        if (betInfos[no].isOpen){
            lotteryNumber = betInfos[no].lotteryNumber;
        }else {
            betInfos[no].isOpen = true;
            betInfos[no].lotteryNumber = lotteryNumber;                      
            emit OpenBet(no, lotteryNumber[4], lotteryNumber[3], lotteryNumber[2], lotteryNumber[1], lotteryNumber[0]);
        }

        for (uint i = 0; i < betIds.length; i++) {
            BetRecord memory userBr = betRecord[betIds[i]];
            if(userBr.isOpen){
                continue;
            }

            if(userBr.no != no){
                continue;
            }
            
            bool isWin = false;

            for (uint j = 0; j < userBr.lotteryNumber.length; j++) {
                if (lotteryNumber[0] == userBr.lotteryNumber[j] && userBr.lotteryDigits == 0) {
                    isWin = true;
                    emit BetWin(no, userBr.userId, 0, lotteryNumber[0], userBr.betId);
                }
                if (lotteryNumber[1] == userBr.lotteryNumber[j] && userBr.lotteryDigits == 1) {
                    isWin = true;
                    emit BetWin(no, userBr.userId, 1, lotteryNumber[1], userBr.betId);
                }
                if (lotteryNumber[2] == userBr.lotteryNumber[j] && userBr.lotteryDigits == 2) {
                    isWin = true;
                    emit BetWin(no, userBr.userId, 2, lotteryNumber[2], userBr.betId);
                }
                if (lotteryNumber[3] == userBr.lotteryNumber[j] && userBr.lotteryDigits == 3) {
                    isWin = true;
                    emit BetWin(no, userBr.userId, 3, lotteryNumber[3], userBr.betId);
                }
                if (lotteryNumber[4] == userBr.lotteryNumber[j] && userBr.lotteryDigits == 4) {
                    isWin = true;
                    emit BetWin(no, userBr.userId, 4, lotteryNumber[4], userBr.betId);
                }
            }

            betRecord[userBr.betId].isWin = isWin;
            betRecord[userBr.betId].isOpen = true;

            if (isWin) {
                uint wTimes = userBr.amount.div(userBr.lotteryNumber.length).mul(10);
                uint winAmount = wTimes.sub(userBr.amount);
                winAmount = winAmount.mul(110).div(100);
                betRecord[userBr.betId].withdrawAmount = winAmount;

                address winUserAddress = idToAddress[userBr.userId];
                players[winUserAddress].withdrawWallet = players[winUserAddress].withdrawWallet.add(userBr.amount);
                emit walletDetail(players[winUserAddress].id, userBr.amount, userBr.betId, 0, now);

            } else {
                // loss
                uint backLossAmount = userBr.amount.mul(BET_LOSS_PERCENT).div(100);
                uint backSpeedUpAmount = userBr.amount.mul(LOSS_SPEEDUP_PERCENT).div(100);

                address lossUserAddress = idToAddress[userBr.userId];
                
                players[lossUserAddress].withdrawWallet = players[lossUserAddress].withdrawWallet.add(backLossAmount);
                emit walletDetail(players[lossUserAddress].id, backLossAmount, userBr.betId, 2, now);

                players[lossUserAddress].speedUpWallet = players[lossUserAddress].speedUpWallet.add(backSpeedUpAmount);
                players[lossUserAddress].backLossAmount = players[lossUserAddress].backLossAmount.add(backLossAmount);

                Player memory player = players[lossUserAddress];
                _teamCount(player.referrer, userBr.amount, 1);
                _dynamicLossLeaderBonus(backLossAmount, lossUserAddress, userBr.betId);

                performances[rankNum][player.referrer] = performances[rankNum][player.referrer].add(userBr.amount);
                players[player.referrer].refsPerformance = players[player.referrer].refsPerformance.add(userBr.amount);
                _updateRanking(player.referrer);

                emit BetLoss(no, userBr.userId, userBr.betId, backLossAmount);
            }
        }

    }

    function bet(uint[] memory lotteryNumber, uint lotteryDigits, uint lotteryNo, address referrerAddress) public payable {
        require(betInfos[lotteryNo].no != 0, "bet info not exists");
        require(!betInfos[lotteryNo].isOpen, "bet is opened");
        require(msg.value >= 1000 trx, "bet amount must be 1000");
        require(now >= betInfos[lotteryNo].startTime, "The game didn't start");
        require(now <= betInfos[lotteryNo].endTime, "The game is over");
        require(players[msg.sender].betRecords[lotteryNo].userId == 0, "user is bet");
        require(!isRepeatNumber(lotteryNumber), "bet cannot be repeated");

        if(!isUserExists(msg.sender)){
            _registration(msg.sender, referrerAddress);
        }
        
        uint one = 99;
        uint ten = 99;
        uint hundred = 99;
        uint thousand = 99;
        uint tenThousand = lotteryNumber[0];

        if(lotteryNumber.length > 4){
            one = lotteryNumber[4];
        }

        if(lotteryNumber.length > 3){
            ten = lotteryNumber[3];
        }

        if(lotteryNumber.length > 2){
            hundred = lotteryNumber[2];
        }

        if(lotteryNumber.length > 1){
            thousand = lotteryNumber[1];
        }

        lastBetid++;

        BetRecord memory br = BetRecord({
            betId : lastBetid,
            isWin : false,
            isOpen : false,
            no : lotteryNo,
            userId : players[msg.sender].id,
            amount : msg.value,
            lotteryNumber : lotteryNumber,
            lotteryDigits : lotteryDigits,
            withdrawStartTime : now + ONE_DAY,
            withdrawEndTime : 0,
            withdrawAmount : 0,
            withdrawAlreadyAmount : 0
            });
            
        betRecord[lastBetid] = br;

        players[msg.sender].isBet = true;
        players[msg.sender].costAmount = players[msg.sender].costAmount.add(msg.value);
        betInfos[lotteryNo].betRecords.push(br);
        betInfos[lotteryNo].betPersonCount ++;
        if(betInfos[lotteryNo].betIdMin == 0){
            betInfos[lotteryNo].betIdMin = lastBetid;
        }
        betInfos[lotteryNo].betIdMax = lastBetid;
        players[msg.sender].betRecords[lotteryNo] = br;

        TransferHelper.safeTransferTrx(techAddress, msg.value.mul(10).div(100));
        TransferHelper.safeTransferTrx(rankPoolAddress, msg.value.mul(5).div(100));

        _teamCount(players[msg.sender].referrer, msg.value, 2);
        emit Bet(players[msg.sender].id, one, ten, hundred, thousand, tenThousand, lotteryDigits, lotteryNo, lastBetid);
    }

    function _registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
 
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        lastUserId++;

        Player memory player = Player({
            id : lastUserId,
            isBet : false,
            refsCount : 0,
            teamCount : 0,
            withdrawWallet : 0,
            speedUpWallet : 0,
            teamPerformance : 0,
            referrer : referrerAddress,
            leaderWallet : 0,
            teamAmount : 0,
            WithdrawAmount : 0,
            costAmount : 0,
            refsPerformance : 0,
            backLossAmount : 0
            });

        players[userAddress] = player;
        idToAddress[lastUserId] = userAddress;

        players[userAddress].referrer = referrerAddress;
        players[referrerAddress].refsCount++;

        _teamCount(referrerAddress, 0, 0);

        emit Registration(userAddress, referrerAddress, players[userAddress].id, players[referrerAddress].id);
    }

    function withdrawImpl(address payable addr) internal {
        require(players[addr].withdrawWallet > 0, "Insufficient wallet balance");
        bool isEnough;
        uint sendMoney = players[addr].withdrawWallet;
        if(sendMoney > 0){

            (isEnough, sendMoney) = isEnoughBalance(sendMoney);
            if (isEnough) {
                players[addr].withdrawWallet = 0;
                addr.transfer(sendMoney);
                emit walletDetail(players[addr].id, sendMoney, 0, 1, now);
            }else {
                require(sendMoney == 0,"withdraw fail");
                return;
            }

        }
    }

    function withdrawService() external {
        withdrawImpl(msg.sender);
    }

    function withdrawLeaderImpl(address payable addr) internal {
        require(players[addr].leaderWallet > 0, "Insufficient wallet balance");
        bool isEnough;
        uint sendMoney = players[addr].leaderWallet;
        if(sendMoney > 0){

            (isEnough, sendMoney) = isEnoughBalance(sendMoney);
            if (isEnough) {
                uint costAmount = players[addr].costAmount.mul(36).div(10);
                if(players[addr].WithdrawAmount.add(sendMoney) > costAmount){
                    sendMoney = costAmount.sub(players[addr].WithdrawAmount);
                }
                players[addr].leaderWallet = players[addr].leaderWallet.sub(sendMoney);
                players[addr].WithdrawAmount = players[addr].WithdrawAmount.add(sendMoney);
                addr.transfer(sendMoney);
                emit LossLeaderBonus(players[addr].id, sendMoney, 0, 1, now);
            }else {
                require(sendMoney == 0,"withdraw fail");
                return;
            }

        }
    }

    function withdrawLeaderWalletService() external {
        withdrawLeaderImpl(msg.sender);
    }

    function releaseBetRecord(uint256 betId) external payable returns(bool success){
        require(betRecord[betId].isWin, "not win");
        require(now >= betRecord[betId].withdrawStartTime, "It is not time yet");
        require(betRecord[betId].withdrawAmount > betRecord[betId].withdrawAlreadyAmount, "Insufficient balance");
        uint releaseAmount = betRecord[betId].withdrawAmount.mul(10).div(100);

        if(betRecord[betId].withdrawAmount - betRecord[betId].withdrawAlreadyAmount < releaseAmount){
            releaseAmount = betRecord[betId].withdrawAmount.sub(betRecord[betId].withdrawAlreadyAmount);
        }
        betRecord[betId].withdrawAlreadyAmount = betRecord[betId].withdrawAlreadyAmount.add(releaseAmount);
        betRecord[betId].withdrawStartTime = now + ONE_DAY;
        players[msg.sender].withdrawWallet = players[msg.sender].withdrawWallet.add(releaseAmount);
        emit walletDetail(players[msg.sender].id, releaseAmount, betId, 3, now);

        return true;
    }

    function speedUpBetRecord(uint256 betId) external payable returns(bool success){
        require(players[msg.sender].speedUpWallet > 0, "Insufficient balance");
        require(betRecord[betId].isWin, "not win");
        require(betRecord[betId].withdrawAmount > betRecord[betId].withdrawAlreadyAmount, "Insufficient balance");
        uint speedAmount = players[msg.sender].speedUpWallet;

        if(betRecord[betId].withdrawAmount - betRecord[betId].withdrawAlreadyAmount < speedAmount){
            speedAmount = betRecord[betId].withdrawAmount.sub(betRecord[betId].withdrawAlreadyAmount);
        }
        betRecord[betId].withdrawAlreadyAmount = betRecord[betId].withdrawAlreadyAmount.add(speedAmount);
        players[msg.sender].withdrawWallet = players[msg.sender].withdrawWallet.add(speedAmount);
        emit walletDetail(players[msg.sender].id, speedAmount, betId, 4, now);

        players[msg.sender].speedUpWallet = players[msg.sender].speedUpWallet.sub(speedAmount);
        return true;
    }

    function _updateRanking(address userAddress) private {
        address[5] memory rankingList = performanceRank[rankNum];
        
        (uint256 sn,uint256 minPerformance) = shootOut(rankingList,userAddress);
        if(sn!=5){
            if(minPerformance < performances[rankNum][userAddress]){
                rankingList[sn] = userAddress;
            }
            performanceRank[rankNum] = rankingList;
        }
    }

    function shootOut(address[5] memory rankingList,address userAddress) public view returns (uint256 sn,uint256 minPerformance){
        
        minPerformance = performances[rankNum][rankingList[0]];
        for(uint8 i = 0; i < 5; i++){
            if(rankingList[i] == userAddress){
                return (5,0);
            }
            if(performances[rankNum][rankingList[i]] < minPerformance){
                minPerformance = performances[rankNum][rankingList[i]];
                sn = i;
            }
        }
        
        return (sn,minPerformance);
    }


    function sortRanking(uint256 _rankNum) public view returns (address[5] memory ranking){
        ranking = performanceRank[_rankNum];

        address tmp;
        for (uint8 i = 1; i < 5; i++) {
            for (uint8 j = 0; j < 5 - i; j++) {
                if (performances[_rankNum][ranking[j]] < performances[_rankNum][ranking[j + 1]]) {
                    tmp = ranking[j];
                    ranking[j] = ranking[j + 1];
                    ranking[j + 1] = tmp;
                }
            }
        }
        return ranking;
    }

    function userRanking(uint256 _rankNum) external view returns (address[5] memory addressList, uint256[5] memory performanceList, uint256[5] memory refsCounts, uint256[5] memory preEarn){
        addressList = sortRanking(_rankNum);
        uint lossPool = rankPoolAddress.balance;
        for (uint8 i = 0; i < 5; i++) {
            refsCounts[i] = players[addressList[i]].refsCount;
            preEarn[i] = lossPool.mul(rankPercent[i]).div(100);
            performanceList[i] = performances[_rankNum][addressList[i]];
        }
    }

    function getRankingIncome() external payable returns (address[5] memory addressList, uint256[5] memory performanceList, uint256[5] memory refsCounts, uint256[5] memory preEarn){
        require(owner == msg.sender, "Insufficient permissions");
        addressList = sortRanking(rankNum);
        uint lossPool = rankPoolAddress.balance;
        for (uint8 i = 0; i < 5; i++) {
            refsCounts[i] = players[addressList[i]].refsCount;
            preEarn[i] = lossPool.mul(rankPercent[i]).div(100);
            if(addressList[i] != address(0)){
                rankPool.poolTransfer(addressList[i], preEarn[i]);
            }

            performanceList[i] = performances[rankNum][addressList[i]];
        }

        rankNum++;

    }

    function getIsBet(uint lotteryNo) external view returns (bool) {
        return (players[msg.sender].betRecords[lotteryNo].userId != 0);
    }
    
    function getBetIdMax(uint lotteryNo) external view returns (uint betIdMax) {
        return (betInfos[lotteryNo].betIdMax);
    }
    
    function getBetIdMin(uint lotteryNo) external view returns (uint betIdMin) {
        return (betInfos[lotteryNo].betIdMin);
    }

    function getBetNo(uint betId) external view returns (uint lotteryNo) {
        return (betRecord[betId].no);
    }

    function getOpenBetInfo(uint lotteryNo) external view returns (uint no, uint one, uint ten, uint hundred, uint thousand, uint tenThousand) {
        return (betInfos[lotteryNo].no, betInfos[lotteryNo].lotteryNumber[4], betInfos[lotteryNo].lotteryNumber[3], betInfos[lotteryNo].lotteryNumber[2], betInfos[lotteryNo].lotteryNumber[1], betInfos[lotteryNo].lotteryNumber[0]);
    }

   //Team Performance statistics
    function _teamCount(address _ref, uint256 amount, uint typeId) private {
        address player = _ref;
        for (uint256 i = 0; i < 15; i++) {
            if (player == address(0)) {
                break;
            }
            if (typeId == 1) {
                players[player].teamPerformance = players[player].teamPerformance.add(amount);
            }else if(typeId == 2){
                players[player].teamAmount = players[player].teamAmount.add(amount);
            }else {
                players[player].teamCount++;
            }
            player = players[player].referrer;
        }
    }

    function _dynamicLossLeaderBonus(uint256 _amount, address _player, uint256 _betId) private {
        address player = _player;
        address ref = players[_player].referrer;
        uint256 leaderBonus;
        for (uint256 i = 0; i < LOSS_LEADER_BONUS_PERCENTS.length; i++) {
            // Illegal referrer to skip
            if (ref == address(0x0)) {
                break;
            }

            // Invalid user
            if (!players[ref].isBet) {
                break;
            }

            if (players[ref].refsCount > i) {

                leaderBonus = (_amount.mul(LOSS_LEADER_BONUS_PERCENTS[i]).div(100));
                players[ref].leaderWallet = players[ref].leaderWallet.add(leaderBonus);

                emit LossLeaderBonus(players[ref].id, leaderBonus, _betId, 0, now);
            }

            //User recommendation reward
            player = ref;
            ref = players[ref].referrer;
        }
    }

    function isUserExists(address user) public view returns (bool) {
        return (players[user].id != 0);
    }

    function isRepeatNumber(uint[] memory a) internal pure returns (bool) {
        require(a.length <= 5, "bet number must be <= 5");

        bool duplicates = false;

        for (uint i = 0; i < a.length; i += 1) {
            uint k = 0;

            for (uint j = 0; j < a.length; j += 1) {
                if (a[i] == a[j]) {
                    k += 1;
                }

                if (k > 1) {
                    duplicates = true;
                }
            }
        }

        return duplicates;
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        if (sendMoney >= address(this).balance) {
            return (false, address(this).balance);
        } else {
            return (true, sendMoney);
        }
    }

}

contract RankPool {
    function poolTransfer(address to, uint value) public;
}