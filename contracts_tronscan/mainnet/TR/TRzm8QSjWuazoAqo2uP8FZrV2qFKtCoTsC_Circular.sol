//SourceUnit: circular.sol

pragma solidity ^0.5.4;

interface Supplementary{
    function buyTokenWithEconomicValue(address addr, string calldata trxID) external payable returns(uint256, uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
    }
}



contract Circular is Ownable {
    using SafeMath for uint256;
    
    uint256[] CircleEntrancePrice = [200000000, 900000000, 3000000000];
    uint256[] moneyBoxLimit = [400000000, 1400000000, 3000000000];
    uint256[] PoolEntrance = [400000000, 600000000, 950000000, 1500000000, 1400000000, 2000000000, 3000000000, 4400000000, 6400000000, 3000000000, 4500000000, 6500000000, 10000000000, 15000000000, 0];
    uint256[3] public TotalTRXInCircle;
    uint256 wheelEntrance = 5000000;
    uint256 usageTime = 30 days;
    address payable public DWallet;
    address payable public MainWallet;
    address public SupplementaryContract;
    uint256 public startTime;
    uint256 public idCounter = 1;
    uint256 public totalPaidMoney;
    uint256 private poolStartTime;
    bool public TTSORMoney;
    uint256 nonce;
    uint256 randomG = 1;
    AFKUser[] public AFKUsers; 
    struct AFKUser{
        uint256 id;
        uint256 circle;
    }
    uint256 private counter;
    uint256[] private idCircle2;
    uint256[] private idCircle3;
    mapping(uint256 => address payable) private idToAddress;
    mapping(address => uint256) private addressToId;
    mapping(address => UserCircleData[3]) private userCircleData;
    mapping(address => UserPoolData[3]) private userPoolData;
    mapping(address => UserData) private userData;
    PoolData private poolData;

    struct UserCircleData{
        address payable leftSide;
        address payable rightSide;
        uint256 moneyBox;
        bool isClosedBox;
        address referrer;
        uint256[] referrals;
        bool initiated;
        uint256 enteranceTime;
        uint256 lastIntractTime;
        bool isInFortuneWheel;
        uint256 totalEarnFromCircle;
    }
    

    struct UserData{
        uint256 totalEarn;
        uint256 startTime;
        uint256 FortuneWheelWins;
        uint256 totalTTSCashedOut;
    }

    uint256 public totalFortuneWheelWinMoney;
    uint256 public totalFortuneWheelBoxes;
    uint256 public totalFortuneWheelCalls;

    struct UserPoolData{
        uint256 currentPool;
        address payable behind;
        bool initiated;
        uint256 indexFromStart;
    }
    
    struct PoolData{
        address payable[14] first;
        address payable[14] last;
        bool[14] counter;
        uint256[14] length;
        uint256[14] totalEntrance;
    }
    uint256[3] public lastIntractTimeWithPool;
    ReservedUsers[2] public reserve;

    struct ReservedUsers{
        uint256 id;
        uint256 amount;
        bool isInReserve;
    }

    event SendProfitOfPool(address addr, uint256 amount);

    constructor(address payable dwallet, address payable mainWallet, address supplementaryAddress, uint256 startC, uint256 startP) public{
        DWallet = dwallet;
        MainWallet = mainWallet;
        SupplementaryContract = supplementaryAddress;
        assignId(mainWallet);
        uint256 i=0;
        while(i < 3) {
            userCircleData[mainWallet][i].initiated = true;
            userCircleData[mainWallet][i].leftSide = mainWallet;
            userCircleData[mainWallet][i].rightSide = mainWallet;
            userCircleData[mainWallet][i].referrer = mainWallet;
            userCircleData[mainWallet][i].isClosedBox = true;
            userPoolData[mainWallet][i].initiated = true;
            i++;
        }
        idCircle2.push(1);
        idCircle3.push(1);
        addToPool(0, 0, mainWallet);
        addToPool(4, 1, mainWallet);
        addToPool(9, 2, mainWallet);
        startTime = startC;
        poolStartTime = startP;
    }
    
    function enterCircle(uint256 referrer, uint256 circleNum) public payable{
        require(block.timestamp > startTime, "circles are not open!");
        require(circleNum < 3, "wrong circle number!");
        require(!userCircleData[msg.sender][circleNum].initiated, "You have already registered in this Circle");
        require(msg.value == CircleEntrancePrice[circleNum], "You paid wrong amount");
        if(circleNum == 1){
            require(userCircleData[msg.sender][0].initiated, "You have to be in Circle 1 to Enter Circle 2");
        }else if(circleNum == 2){
            require(userCircleData[msg.sender][1].initiated, "You have to be in Circle 2 to Enter Circle 3");
        }
        totalPaidMoney += msg.value;
        addUserToCircle(msg.sender, referrer, circleNum, msg.value);
    }

    function addUserToCircle(address payable user, uint256 referrer, uint256 circleNum, uint256 value) private {
        if(circleNum > 0){
            address ref = userCircleData[user][circleNum - 1].referrer;
            if(userCircleData[ref][circleNum].initiated)
                referrer = addressToId[ref];
            else if(!userCircleData[idToAddress[referrer]][circleNum].initiated){
                nonce ++;
                if(circleNum == 1)
                    referrer = idCircle2[random(idCircle2.length)];
                else
                    referrer = idCircle3[random(idCircle3.length)];
            }
        }else{
            if(!userCircleData[idToAddress[referrer]][circleNum].initiated){
                nonce ++;
                referrer = random(idCounter - 1) + 1;
            }
        }

        TotalTRXInCircle[circleNum] += value;
        
        userCircleData[user][circleNum].enteranceTime = block.timestamp;
        uint256 id = assignId(user);
        userCircleData[user][circleNum].initiated = true;
        if(circleNum == 1)
            idCircle2.push(id);
        else if(circleNum == 2)
            idCircle3.push(id);
        addToCircle(user, idToAddress[referrer], circleNum, value);
    }

    function enterPool(uint256 stageNumber) public payable{
        require(block.timestamp > poolStartTime, "pools are not open");
        require(stageNumber < 3, "wrong pool number!");
        require(userCircleData[msg.sender][stageNumber].initiated , "You have to be in Circle to get in pool");
        require(!userPoolData[msg.sender][stageNumber].initiated , "You have already registered in this pool");
        require(stageNumber == 0 || userPoolData[msg.sender][stageNumber - 1].initiated, "You have to be in prev pool to get into later ones");
        
        
        uint256 realNum = stageNumber >= 1 ? stageNumber * 5 - 1 : 0;//0 4 9
        require(msg.value <= PoolEntrance[realNum], "you paid wrong amount");
        uint256 amount = msg.value.add(userCircleData[msg.sender][stageNumber].moneyBox);
        require(PoolEntrance[realNum] <= amount, "you paid wrong amount");

        totalPaidMoney += msg.value;
        userCircleData[msg.sender][stageNumber].moneyBox = amount - PoolEntrance[realNum];
        userCircleData[msg.sender][stageNumber].lastIntractTime = block.timestamp;
        userCircleData[msg.sender][stageNumber].isClosedBox = true;

        if(stageNumber != 2 && reserve[stageNumber].isInReserve) {
            reserve[stageNumber].isInReserve = false;
            addToNextCircle(idToAddress[reserve[stageNumber].id], stageNumber + 1, reserve[stageNumber].amount);
        }

        UserPoolData storage data = userPoolData[msg.sender][stageNumber];
        data.initiated = true;

        bool finished = false;

        uint256 poolNumber = realNum;
        address payable addr = msg.sender;
        lastIntractTimeWithPool[stageNumber] = block.timestamp;

        while (!finished){
            finished = true;
            poolData.counter[poolNumber] = !poolData.counter[poolNumber];
            addToPool(poolNumber, stageNumber, addr);
            if (!poolData.counter[poolNumber]){
                finished = false;
                addr = poolData.first[poolNumber];
                poolData.first[poolNumber] = userPoolData[addr][stageNumber].behind;
                poolData.length[poolNumber]--;
                uint256 profit = 2 * PoolEntrance[poolNumber];
                poolNumber++;     

                if(poolNumber == 14) {
                    finished = true;
                } else if (poolNumber == stageNumber * 5 + 4) {
                    finished = true;
                    if (!userCircleData[addr][stageNumber + 1].initiated) {
                        reserve[stageNumber].isInReserve = true;
                        profit = profit.sub(CircleEntrancePrice[stageNumber + 1]);
                        if(!userCircleData[addr][stageNumber + 1].isClosedBox){
                            reserve[stageNumber].id = addressToId[addr];
                            if (stageNumber == 0){
                                reserve[stageNumber].amount = 700000000;
                                profit = profit - 700000000;
                            } else {
                                reserve[stageNumber].amount = 1500000000;
                                profit = profit - 1500000000;
                            }
                        }
                    }
                } else {
                    profit = profit - PoolEntrance[poolNumber];
                }

                if(profit > 0) {
                    addr.transfer(profit);
                    userData[addr].totalEarn += profit;
                    emit SendProfitOfPool(addr, profit);
                }
            }   
        }
        // give back money if fee is too high
    }

    function addToNextCircle(address payable addr, uint256 stageNumber, uint256 profit) private {
        if (!userCircleData[addr][stageNumber].initiated) {
            uint256 ref = addressToId[userCircleData[addr][stageNumber].referrer];
            addUserToCircle(addr, ref, stageNumber, CircleEntrancePrice[stageNumber]);
            if(!userCircleData[addr][stageNumber].isClosedBox){
                userCircleData[addr][stageNumber].moneyBox = userCircleData[addr][stageNumber].moneyBox.add(profit);
                userCircleData[msg.sender][stageNumber].lastIntractTime = block.timestamp;
            }else{
                addr.transfer(profit);
                emit SendProfitOfPool(addr, profit);
            }
        }
    }

    function cashOut(uint256 box) public returns (uint256 amount, string memory h, uint256 returnedMoney) {
        require(box < 3);
        uint256 value = userCircleData[msg.sender][box].moneyBox;
        userCircleData[msg.sender][box].lastIntractTime = block.timestamp;
        userCircleData[msg.sender][box].moneyBox = 0;
        require(value > 0, "money box is empty");
        if (TTSORMoney) {
            msg.sender.transfer(value);
            return (0 , "", value);
        }
        Supplementary s = Supplementary(SupplementaryContract);
        counter++;
        h = uintToString(block.timestamp + counter);
        (amount, returnedMoney) = s.buyTokenWithEconomicValue.value(value)(msg.sender, h);
        userData[msg.sender].totalTTSCashedOut = amount;
        return (amount, h, returnedMoney);
    }

    function sendToNextMoneyBox(uint256 box) public {
        require(box < 2);
        uint256 value = userCircleData[msg.sender][box].moneyBox;
        userCircleData[msg.sender][box].moneyBox = 0;
        userCircleData[msg.sender][box].lastIntractTime = block.timestamp;
        userCircleData[msg.sender][box + 1].lastIntractTime = block.timestamp;
        DWallet.transfer(value.mul(6).div(100));
        userCircleData[msg.sender][box + 1].moneyBox = userCircleData[msg.sender][box + 1].moneyBox.add(value.mul(94).div(100));
    }
    
    function spinWheelOfTheFortune(uint256 id0, uint256 id1, uint256 id2) public payable returns(uint256){
        addToFortuneQueue(id0);
        addToFortuneQueue(id1);
        addToFortuneQueue(id2);

        require(AFKUsers.length > 0, "there is no reward!");
        totalPaidMoney += msg.value;
        if (msg.value < wheelEntrance) {
            msg.sender.transfer(msg.value);
            return 0;
        }
        DWallet.transfer(msg.value);
        if (!userCircleData[msg.sender][0].initiated)
            return 0;
        totalFortuneWheelCalls++;
        uint256 chance = 100;
        nonce++;
        randomG++;
        randomG = randomG.mod(chance);
        if (randomG == random(chance)) {
            AFKUser memory prize = AFKUsers[AFKUsers.length-1];
            delete AFKUsers[AFKUsers.length - 1];
            AFKUsers.length--;
            UserCircleData storage data = userCircleData[idToAddress[prize.id]][prize.circle];
            if(block.timestamp.sub(data.lastIntractTime) > usageTime){
                totalFortuneWheelBoxes++;
                uint256 amount = data.moneyBox;
                totalFortuneWheelWinMoney += amount;
                msg.sender.transfer(amount);
                userData[msg.sender].FortuneWheelWins += amount;
                data.lastIntractTime = block.timestamp;
                data.isInFortuneWheel = false;
                data.moneyBox = 0;
                return amount;
            }
        }
    }

    function sendPoolMoneyToFirst(uint256 poolNumber) public onlyOwner{
        require(poolNumber < 14);
        require(poolIsDisable((poolNumber + 1) / 5), "this function is available 3 months after lastIntractionIime");
        if(poolData.counter[poolNumber]){
            poolData.counter[poolNumber] = false;
            address payable addr = poolData.first[poolNumber];
            addr.transfer(PoolEntrance[poolNumber]);
            poolData.first[poolNumber] = userPoolData[addr][(poolNumber + 1) / 5].behind;
            poolData.length[poolNumber]--;
            if (poolData.length[poolNumber] == 0)
                poolData.first[poolNumber] = address(0);
        }
    }

    //internal functions
    function poolIsDisable(uint256 poolNum) public view returns (bool) {
        return block.timestamp.sub(lastIntractTimeWithPool[poolNum]) > 30 days;
    }

    function assignId(address payable addr) private returns (uint256 id){
        if(addressToId[addr] > 0)
            return addressToId[addr];
        userData[addr].startTime = block.timestamp;
        addressToId[addr] = idCounter;
        idToAddress[idCounter] = addr;
        idCounter++;
        return idCounter - 1;
    }

    function addToFortuneQueue(uint256 id) private{
        UserCircleData[3] storage data = userCircleData[idToAddress[id]];
        
        if(data[0].initiated  && !data[0].isInFortuneWheel && data[0].moneyBox > 0 && block.timestamp.sub(data[0].lastIntractTime) > usageTime){
            data[0].isInFortuneWheel = true;
            AFKUsers.push(AFKUser(id, 0));
        }

        if(data[1].initiated && !data[1].isInFortuneWheel && data[1].moneyBox > 0 && block.timestamp.sub(data[1].lastIntractTime) > usageTime){
            data[1].isInFortuneWheel = true;
            AFKUsers.push(AFKUser(id, 1));
        }
        
        if(data[2].initiated && !data[2].isInFortuneWheel && data[2].moneyBox > 0 && block.timestamp.sub(data[2].lastIntractTime) > usageTime){
            data[2].isInFortuneWheel = true;
            AFKUsers.push(AFKUser(id, 2));
        }
    }

    function uintToString(uint256 v) private pure returns (string memory str) {
        bytes memory s = new bytes(10);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            s[9 - i] = byte(uint8(48 + remainder));
            i++;
        }
        str = string(s);
    }

    function addToPool(uint256 realNum, uint256 stageNumber, address payable addr) private {
        if(poolData.length[realNum] == 0)
            poolData.first[realNum] = addr;
        
        poolData.totalEntrance[realNum]++;
        userPoolData[poolData.last[realNum]][stageNumber].behind = addr;
        userPoolData[addr][stageNumber].behind = addr;
        poolData.last[realNum] = addr;
        poolData.length[realNum]++;   
        userPoolData[addr][stageNumber].currentPool = realNum;
        userPoolData[addr][stageNumber].indexFromStart = poolData.totalEntrance[realNum];
    }

    function addToCircle(address payable addr, address payable referrer, uint256 circleNumber, uint256 value) private {
        address payable one;
        address payable two;
        UserCircleData storage referrerData = userCircleData[referrer][circleNumber];
        UserCircleData storage userCData = userCircleData[addr][circleNumber];
        
        referrerData.referrals.push(addressToId[addr]);
        userCData.referrer = referrer;
        if(referrerData.referrals.length % 2 == 0){
            userCData.rightSide = referrerData.rightSide;
            referrerData.rightSide = addr;
            userCData.leftSide = referrer;
            userCircleData[userCData.rightSide][circleNumber].leftSide = addr;
            one = userCData.rightSide;
            two = referrerData.leftSide;
            
        }else{
            userCData.leftSide = referrerData.leftSide;
            referrerData.leftSide = addr;
            userCData.rightSide = referrer;      
            userCircleData[userCData.leftSide][circleNumber].rightSide = addr;
            two = userCData.leftSide;
            one = referrerData.rightSide;
        }
        addReferralBalance(referrer, value.div(2) , false,circleNumber);

        one = addReferralBalance(one, value.mul(3).div(20) , true,circleNumber);
        two = addReferralBalance(two, value.mul(3).div(20) , false,circleNumber);

        one = addReferralBalance(one, value.div(20) , true,circleNumber);
        two = addReferralBalance(two, value.div(20) , false,circleNumber);

        one = addReferralBalance(one, value.div(50) , true,circleNumber);
        two = addReferralBalance(two, value.div(50) , false,circleNumber);

        DWallet.transfer(value.mul(3).div(50));
        
    }

    function addReferralBalance(address payable addr, uint256 value, bool right, uint256 circleNum) private returns (address payable) {
        UserCircleData storage data = userCircleData[addr][circleNum];
        userData[addr].totalEarn += value;
        data.totalEarnFromCircle += value;
        if(!data.isClosedBox){
            uint256 addedValue = value.div(5);
            if (data.moneyBox.add(addedValue) > moneyBoxLimit[circleNum]){
                addedValue = moneyBoxLimit[circleNum].sub(data.moneyBox);
            }
            data.moneyBox = data.moneyBox.add(addedValue);
            data.lastIntractTime = block.timestamp;
            value = value.sub(addedValue);
        }
        addr.transfer(value);

        return right ? data.rightSide : data.leftSide;
    }

    function setTTSORMoney(uint256 b) public onlyOwner {
        TTSORMoney = (b == 1) ? true : false;
    }

    // view functions
    function loginChecker(address addr) public view returns(uint256){
        return addressToId[addr];
    }

    function getCircleData(uint256 id, uint256 circleNum) public view returns(
        uint256 left1,
        uint256 left2,
        uint256 left3,
        uint256 left4,
        uint256 right1,
        uint256 right2,
        uint256 right3,
        uint256 right4){
        address addr = idToAddress[id];
        require(userCircleData[addr][circleNum].initiated,"Not in this circle");

        address aleft1 = userCircleData[addr][circleNum].leftSide;
        address aleft2 = userCircleData[aleft1][circleNum].leftSide;
        address aleft3 = userCircleData[aleft2][circleNum].leftSide;
        address aleft4 = userCircleData[aleft3][circleNum].leftSide;

        left1=addressToId[aleft1];
        left2=addressToId[aleft2];
        left3=addressToId[aleft3];
        left4=addressToId[aleft4];

        aleft1 = userCircleData[addr][circleNum].rightSide;
        aleft2 = userCircleData[aleft1][circleNum].rightSide;
        aleft3 = userCircleData[aleft2][circleNum].rightSide;
        aleft4 = userCircleData[aleft3][circleNum].rightSide;

        return (left1,left2, left3, left4, addressToId[aleft1], addressToId[aleft2], addressToId[aleft3], addressToId[aleft4]);
    }
        
    function getCircleData2(uint256 id, uint256 circleNum) public view returns (uint256 moneyBox, uint256 referrer, bool isClosed, uint256 referralsCount, uint256 lastIntractTime, bool isInFortuneWheel){
        UserCircleData memory data = userCircleData[idToAddress[id]][circleNum];
        return (data.moneyBox, addressToId[data.referrer], data.isClosedBox, data.referrals.length, data.lastIntractTime, data.isInFortuneWheel); 
    }

    function getReferrals(uint256 id, uint256 circleNum) public view returns (uint256[] memory referrals){
        return userCircleData[idToAddress[id]][circleNum].referrals; 
    }    

    function getCircleLength(uint256 n) public view returns (uint256 length){
        if(n == 0)
            return idCounter - 1;
        if(n == 1)
            return idCircle2.length;
        if(n == 2)
            return idCircle3.length;
    }

    function random(uint256 baseMod) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce))).mod(baseMod);
   }

    function getPoolData() public view returns (uint256[14] memory firsts, uint256[14] memory lasts, bool[14] memory full, uint256[14] memory len, uint256[14] memory totalEntrance){
        for (uint256 i = 0; i < 14; i++){
            firsts[i] = addressToId[poolData.first[i]];
            lasts[i] = addressToId[poolData.last[i]];
        }
        return (firsts, lasts, poolData.counter, poolData.length, poolData.totalEntrance);
    }

    function getUserPoolData(uint256 id, uint256 stageNum) public view returns (uint256 currentPool, address payable behind, bool initiated, uint256 position){
        UserPoolData memory data = userPoolData[idToAddress[id]][stageNum];
        uint256 pos = data.indexFromStart - userPoolData[poolData.first[data.currentPool]][stageNum].indexFromStart + 1;
        if (pos > data.indexFromStart + 1)
            pos = 0;
        return (data.currentPool, data.behind, data.initiated, pos);
    }

    function getIdleUsers(uint256 from, uint256 to) public view returns(bool[20] memory){
        bool[20] memory ids;
        if (to > from + 20)
            to = from + 20;
        if (to > idCounter)
            to = idCounter;
        for (uint256 i = from; i < to; i++) {
            UserCircleData[3] memory data = userCircleData[idToAddress[i]];
            if (data[0].initiated  && !data[0].isInFortuneWheel && data[0].moneyBox > 0 && block.timestamp.sub(data[0].lastIntractTime) > usageTime)
                ids[i - from] = true;
            else if(i < idCircle2.length && data[1].initiated && !data[1].isInFortuneWheel && data[0].moneyBox > 0 && block.timestamp.sub(data[1].lastIntractTime) > usageTime)
                ids[i - from] = true;
            else if (i < idCircle3.length && data[2].initiated && !data[2].isInFortuneWheel && data[0].moneyBox > 0 && block.timestamp.sub(data[2].lastIntractTime) > usageTime)
                ids[i - from] = true;
        }
        return ids;
    }

    function getUserData(uint256 id) public view returns (uint256 totalEarn, uint256[3] memory totalEarnFromCircle, uint256 FortuneWheelWins, uint256 userStartTime) {
        totalEarn = userData[idToAddress[id]].totalEarn;
        userStartTime = userData[idToAddress[id]].startTime;
        FortuneWheelWins = userData[idToAddress[id]].FortuneWheelWins;
        totalEarnFromCircle[0] = userCircleData[idToAddress[id]][0].totalEarnFromCircle;
        totalEarnFromCircle[1] = userCircleData[idToAddress[id]][1].totalEarnFromCircle;
        totalEarnFromCircle[2] = userCircleData[idToAddress[id]][2].totalEarnFromCircle;
        return (totalEarn, totalEarnFromCircle, FortuneWheelWins, userStartTime);
    }

    function getAFKLength() public view returns(uint256){
        return AFKUsers.length;
    }
}


/*
delete behind return of getUserPoolData

*/