//SourceUnit: FmGame.sol

pragma solidity 0.4.25;

    library DappDatasets {

        struct Player {

            uint withdrawalAmount;

            uint wallet;

            uint fomoTotalRevenue;

            uint lotteryTotalRevenue;

            uint dynamicIncome;

            uint rechargeAmount;
            
            uint lastRechargeAmount;

            uint staticIncome;

            uint shareholderLevel;

            uint underUmbrellaLevel;

            uint subbordinateTotalPerformance;

            bool isExist;

            bool superior;

            address superiorAddr;

            address[] subordinates;
        }


        struct Fomo {

            bool whetherToEnd;

            uint endTime;

            uint fomoPrizePool;

            address[] participant;
            
            uint lastPrizePool;
        }

        struct Lottery {

            bool whetherToEnd;

            uint lotteryPool;

            uint unopenedBonus;

            uint number;

            uint todayAmountTotal;

            uint totayLotteryAmountTotal;

            uint[] firstPrizeNum;

            uint[] secondPrizeNum;

            uint[] thirdPrizeNum;

            mapping(address => uint[]) lotteryMap;

            mapping(uint => address) numToAddr;

            mapping(address => uint) personalAmount;

            mapping(uint => uint) awardAmount;
        }

        function getNowTime() internal view returns(uint) {
            return now;
        }

        function rand(uint256 _length, uint num) internal view returns(uint256) {
            uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now - num)));
            return random%_length;
        }

        function returnArray(uint len, uint range, uint number) internal view returns(uint[]) {
            uint[] memory numberArray = new uint[](len);
            uint i = 0;
            uint num = number;
            while(true) {
                num = num + 9;
                uint temp = rand(range, num);
                if(temp == 0) {
                    continue;
                }
                numberArray[i] = temp;
                i++;
                if(i == len) {
                    break;
                }
            }
            return numberArray;
        }
    }


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

    contract FMGame {

        address owner;

        address mainAddr;

        address[] temp = new address[](0);

        uint[] numArr = new uint[](0);

        uint depositBalance;

        uint fomoSession;

        uint lotterySession = 1;

        FMToken fmToken;

        FMMain main;

        mapping(uint => DappDatasets.Fomo) fomoGame;

        mapping(uint => DappDatasets.Lottery) lotteryGame;

        address amountMaxAddr;

        uint fomoEndNumOne;
        uint fomoEndNumTwo;

        constructor(
            address _owner,
            address _fmAddr
        )  public {
            owner = _owner;
            fmToken = FMToken(_fmAddr);
            lotteryGame[lotterySession] = DappDatasets.Lottery(
                {
                    whetherToEnd : false,
                    lotteryPool : 0,
                    unopenedBonus : 0,
                    number : 1,
                    todayAmountTotal : 0,
                    totayLotteryAmountTotal : 0,
                    firstPrizeNum : numArr,
                    secondPrizeNum : numArr,
                    thirdPrizeNum : numArr
                }
            );
        }

        function init(address addr) external {
            require(owner == msg.sender, "Insufficient permissions");
            main = FMMain(addr);
            mainAddr = addr;
        }
        
        function redeemFM(uint usdtVal, uint usdtPrice, address addr) external {
            require(mainAddr == msg.sender, "Insufficient permissions");

            uint fmCount = SafeMath.div(usdtVal * 10 ** 8, usdtPrice);

            fmToken.gainFMToken(fmCount, true);
            fmToken.transfer(addr, fmCount);
        }

        function buyLotto(uint usdtVal, address addr) external {
            require(mainAddr == msg.sender, "Insufficient permissions");
            require(lotteryGame[lotterySession].whetherToEnd == false,"Game over");
            uint count = SafeMath.div(usdtVal, 2 * 10 ** 6);
            getLottoCode(addr, count);
        }

        function getLottoCode(address addr, uint count) internal {
            if(count == 0) {
                return;
            }
            
            DappDatasets.Lottery storage lottery = lotteryGame[lotterySession];
            lottery.lotteryMap[addr].push(lottery.number);
            if(count > 1) {
                lottery.lotteryMap[addr].push(SafeMath.add(lottery.number, count - 1));
            }
            lottery.lotteryMap[addr].push(0);
            for(uint i = 0; i < count; i++) {
                lottery.numToAddr[lottery.number] = addr;
                lottery.number++;
            }
            lottery.totayLotteryAmountTotal = SafeMath.add(lottery.totayLotteryAmountTotal, count * 2 * 10 ** 6);
           
        }

        function atomicOperationLottery() external {
            require(owner == msg.sender, "Insufficient permissions");
            DappDatasets.Lottery storage lottery = lotteryGame[lotterySession];
            lottery.whetherToEnd = true;
            uint lotteryNumber = lottery.number;
            if(lottery.lotteryPool > 0 && lotteryNumber > 1) {
                uint[] memory firstPrizeNum;
                uint[] memory secondPrizeNum;
                uint[] memory thirdPrizeNum;

                bool flag = lottery.totayLotteryAmountTotal >= SafeMath.mul(lottery.todayAmountTotal, 3);
                if(flag) {
                    firstPrizeNum = DappDatasets.returnArray(1, lotteryNumber, 7);
                    lottery.firstPrizeNum = firstPrizeNum;
                }
                prizeDistribution(firstPrizeNum, 3, 0, flag);

                uint number = 3;
                if(lotteryNumber < 4) {
                    number = lotteryNumber - 1;
                }
                secondPrizeNum = DappDatasets.returnArray(number, lotteryNumber, 17);
                lottery.secondPrizeNum = secondPrizeNum;
                prizeDistribution(secondPrizeNum, 3, 1, true);

                number = 30;
                if(lotteryNumber < 31) {
                    number = lotteryNumber - 1;
                }
                thirdPrizeNum = DappDatasets.returnArray(number, lotteryNumber, 37);
                lottery.thirdPrizeNum = thirdPrizeNum;
                prizeDistribution(thirdPrizeNum, 3, 2, true);
            }else {
                lottery.unopenedBonus = SafeMath.add(lottery.unopenedBonus, lottery.lotteryPool);
            }
            
            uint lastAmount = SafeMath.div(lottery.lotteryPool, 10);
            lottery.unopenedBonus = SafeMath.add(lottery.unopenedBonus, lastAmount);

            lotterySession++;
            lotteryGame[lotterySession] = DappDatasets.Lottery(
                {
                    whetherToEnd : false,
                    lotteryPool : lotteryGame[lotterySession - 1].unopenedBonus,
                    unopenedBonus : 0,
                    number : 1,
                    todayAmountTotal : 0,
                    totayLotteryAmountTotal : 0,
                    firstPrizeNum : numArr,
                    secondPrizeNum : numArr,
                    thirdPrizeNum : numArr
                }
            );
        }

        function prizeDistribution(uint[] winningNumber, uint divide, uint num, bool flag) internal {
            DappDatasets.Lottery storage lottery = lotteryGame[lotterySession];
            uint prize = SafeMath.div(SafeMath.mul(lottery.lotteryPool, divide), 10);
            if(flag) {
                uint personal = SafeMath.div(prize, winningNumber.length);
                for(uint i = 0; i < winningNumber.length; i++) {
                    main.updateRevenue(lottery.numToAddr[winningNumber[i]], personal, false);
                    
                    lottery.personalAmount[lottery.numToAddr[winningNumber[i]]] = SafeMath.add(
                        lottery.personalAmount[lottery.numToAddr[winningNumber[i]]],
                        personal
                    );
                }
                lottery.awardAmount[num] = personal;
            }else {
                lottery.unopenedBonus = SafeMath.add(lottery.unopenedBonus, prize);
            }
        }

        function getLotteryInfo() external view returns(uint session, uint pool, uint unopenedBonus, bool isEnd, uint[]) {
            DappDatasets.Lottery storage lottery = lotteryGame[lotterySession];
            return (
                lotterySession,
                lottery.lotteryPool,
                lottery.unopenedBonus,
                lottery.whetherToEnd,
                lottery.lotteryMap[msg.sender]
                );
        }

        function getHistoryLottery(uint num) external view returns(uint, uint[], uint[], uint[], uint[], uint[]) {
            DappDatasets.Lottery storage lottery = lotteryGame[num];
            uint[] memory awardArray = new uint[](3);
            for(uint i = 0; i < 3; i++) {
                awardArray[i] = lottery.awardAmount[i];
            }
            return (
                lottery.personalAmount[msg.sender],
                lottery.firstPrizeNum,
                lottery.secondPrizeNum,
                lottery.thirdPrizeNum,
                lottery.lotteryMap[msg.sender],
                awardArray
            );
        }


        function getFOMOInfo() external view returns(uint Session, uint nowTime, uint endTime, uint prizePool, bool isEnd) {
            DappDatasets.Fomo memory fomo = fomoGame[fomoSession];
            return (fomoSession, DappDatasets.getNowTime(), fomo.endTime, fomo.fomoPrizePool, fomo.whetherToEnd);
        }

        function startFomoGame() external {
            require(owner == msg.sender, "Insufficient permissions");
            fomoSession++;
            uint lastPrizePool = 0;
            if(fomoSession > 1) {
                require(fomoGame[fomoSession - 1].whetherToEnd == true, "The game is not over yet");
                lastPrizePool = fomoGame[fomoSession - 1].lastPrizePool;
            }
            fomoGame[fomoSession] = DappDatasets.Fomo(
                {
                    whetherToEnd : false,
                    endTime : now + 48 * 60 * 60,
                    fomoPrizePool : lastPrizePool,
                    participant : temp,
                    lastPrizePool : 0
                }
            );
            fomoEndNumOne = 0;
            fomoEndNumTwo = 0;
            amountMaxAddr = address(0x0);
        }

        function deposit(uint usdtVal, address addr) external returns(uint) {
            require(mainAddr == msg.sender, "Insufficient permissions");
            require(fomoSession > 0, "fomo game has not started yet");
            DappDatasets.Fomo storage fomo = fomoGame[fomoSession];
            require(fomo.whetherToEnd == false,"fomo game has not started yet");

            DappDatasets.Lottery storage lottery = lotteryGame[lotterySession];
            depositBalance = SafeMath.div(SafeMath.mul(usdtVal, 72), 100);
            uint needFm = fmToken.calculationNeedFM(usdtVal);
            fmToken.burn(addr, needFm);
            fomo.participant.push(addr);

            uint lotteryPool = SafeMath.div(usdtVal, 10);
            lottery.lotteryPool = SafeMath.add(lottery.lotteryPool, lotteryPool);
            lottery.todayAmountTotal = SafeMath.add(lottery.todayAmountTotal, lotteryPool);
            shareHolderDistribution(addr, usdtVal);
            levelDifference(addr, usdtVal);

            uint fomoPool = SafeMath.div(SafeMath.mul(usdtVal, 8), 100);

            if(SafeMath.add(fomo.fomoPrizePool, fomoPool) > 1000 * 10 ** 4 * 10 ** 6 ) {
                if(fomo.fomoPrizePool < 1000 * 10 ** 4 * 10 ** 6) {
                    uint n = SafeMath.sub(1000 * 10 ** 4 * 10 ** 6, fomo.fomoPrizePool);
                    fomo.fomoPrizePool = SafeMath.add(fomo.fomoPrizePool, n);
                    uint issue = SafeMath.sub(fomoPool, n);
                    main.releaseStaticPool(issue);
                }else {
                    main.releaseStaticPool(fomoPool);
                }
            }else {
                fomo.fomoPrizePool = SafeMath.add(fomo.fomoPrizePool, fomoPool);
            }

            timeExtended(usdtVal);
            return depositBalance;
        }

        function timeExtended(uint usdtVal) internal {
            DappDatasets.Fomo storage fomo = fomoGame[fomoSession];

            uint count = SafeMath.div(usdtVal, SafeMath.mul(100, 10 ** 6));
            uint nowTime = DappDatasets.getNowTime();
            uint laveTime = SafeMath.sub(fomo.endTime, nowTime);
            uint Twoday = 48 * 60 * 60;
            uint hour = 3 * 60 * 60;

            if(count > 0) {
                laveTime = SafeMath.add(laveTime, SafeMath.mul(hour, count));
                if(laveTime <= Twoday) {
                   fomo.endTime = SafeMath.add(nowTime, laveTime);
               }else {
                   fomo.endTime = SafeMath.add(nowTime, Twoday);
               }
            }
        }

        function levelDifference(address addr, uint usdtVal) internal {
            address playerAddr = addr;
            address superiorAddr;
            uint shareLevel;

            uint shareholderAmount = SafeMath.div(SafeMath.mul(usdtVal, 3), 100);
            uint level = 1;
            for(uint k = 0; k < 50; k++) {
                if(level >= 1 && level <= 4) {
                    (shareLevel, superiorAddr, ) = main.getPlayer(playerAddr);
                    if(shareLevel > 4){
                        shareLevel = 4;
                    }
                    if(superiorAddr != address(0x0)) {
                        if(shareLevel >= level) {
                            uint servings = SafeMath.sub(shareLevel + 1, level);
                            if(servings > 4){
                                servings = 4;
                            }
                            depositBalance = SafeMath.sub(depositBalance, main.rewardDistribution(superiorAddr, shareholderAmount * servings));
                            level = level + servings;
                        }
                        playerAddr = superiorAddr;
                    }else {
                        break;
                    }
                }else {
                    break;
                }
            }

        }

        function shareHolderDistribution(address addr, uint usdtVal) internal {
            address playerAddr = addr;
            address superiorAddr;
            address[] memory subordinates;
            for(uint i = 0; i < 3; i++) {
                (, superiorAddr, subordinates) = main.getPlayer(playerAddr);
                if(superiorAddr != address(0x0)) {
                    if(i == 0 && subordinates.length > 0){
                        uint usdt = SafeMath.div(SafeMath.mul(usdtVal, 9), 100);
                        depositBalance = SafeMath.sub(depositBalance, main.rewardDistribution(superiorAddr, usdt));
                    }else if(i == 1 && subordinates.length > 1){
                        usdt = SafeMath.div(SafeMath.mul(usdtVal, 6), 100);
                        depositBalance = SafeMath.sub(depositBalance, main.rewardDistribution(superiorAddr, usdt));
                    }else if(i == 2 && subordinates.length > 2){
                        usdt = SafeMath.div(SafeMath.mul(usdtVal, 5), 100);
                        depositBalance = SafeMath.sub(depositBalance, main.rewardDistribution(superiorAddr, usdt));
                    }
                    playerAddr = superiorAddr;
                }else {
                    break;
                }
            }
        }

        function getFomoParticpantLength() external view returns(uint) {
            DappDatasets.Fomo storage fomo = fomoGame[fomoSession];
            return fomo.participant.length;
        }

        function endGame() external {
            require(owner == msg.sender, "Insufficient permissions");
            require(fomoSession > 0, "fomo game has not started");
            DappDatasets.Fomo storage fomo = fomoGame[fomoSession];
            require(DappDatasets.getNowTime() >= fomo.endTime, "The game is not over");

            fomo.whetherToEnd = true;
            if(fomo.fomoPrizePool == 0) {
                return;
            }

            uint fomoPool = SafeMath.div(SafeMath.mul(fomo.fomoPrizePool, 30), 100);

            uint length = fomo.participant.length;

            uint personalAmount = SafeMath.div(fomoPool, 3);
            uint num = 0;
            for(uint i = fomo.participant.length; i > 0; i--) {
                main.updateRevenue(fomo.participant[i - 1], personalAmount, true);
                num++;
                if(num == 3 || num == length) {
                    break;
                }
            }

            fomo.lastPrizePool = SafeMath.div(fomo.fomoPrizePool, 10);
            
        }

        function endGameStepOne() external {
            require(owner == msg.sender, "Insufficient permissions");
            require(fomoSession > 0, "fomo game has not started");
            DappDatasets.Fomo storage fomo = fomoGame[fomoSession];
            require(DappDatasets.getNowTime() >= fomo.endTime, "The game is not over");

            if(fomo.fomoPrizePool == 0) {
                return;
            }

            if(fomoEndNumOne >= 330){
               return;
            }

            uint fomoPool = SafeMath.div(SafeMath.mul(fomo.fomoPrizePool, 30), 100);

            uint length = fomo.participant.length;
            
            if(length > 332){
                uint personalAmount = SafeMath.div(fomoPool, 330);
                uint num = 0;
                for(uint j = length - fomoEndNumOne - 3; j > 0; j--) {
                    main.updateRevenue(fomo.participant[j - 1], personalAmount, true);
                    num++;
                    fomoEndNumOne++;
                    if(num == 110  || fomoEndNumOne == 330) {
                        break;
                    }
                }
            }

        }

        function endGameStepTwo() external {
            require(owner == msg.sender, "Insufficient permissions");
            require(fomoSession > 0, "fomo game has not started");
            DappDatasets.Fomo storage fomo = fomoGame[fomoSession];
            require(DappDatasets.getNowTime() >= fomo.endTime, "The game is not over");

            if(fomo.fomoPrizePool == 0) {
                return;
            }
            if(fomoEndNumTwo >= 333) {
                return;
            }

            uint length = fomo.participant.length;

            if(length > 332){
                uint personalAmount = SafeMath.div(SafeMath.mul(fomo.fomoPrizePool, 30), 100);
                uint num = 0;
                uint amountMax = 0;
                if(amountMaxAddr != address(0x0)){
                   amountMax = main.getPlayerRechargeAmount(amountMaxAddr);
                }
                for(uint k = length - fomoEndNumTwo; k > 0; k--) {

                    if(main.getPlayerRechargeAmount(fomo.participant[k - 1]) > amountMax){
                       amountMax = main.getPlayerRechargeAmount(fomo.participant[k - 1]);
                       amountMaxAddr = fomo.participant[k - 1];
                    }
                    num++;
                    fomoEndNumTwo++;
                    if(num == 111 || fomoEndNumTwo == 333) {
                        break;
                    }
                }

                if(amountMax > 0 && fomoEndNumTwo == 333){
                    main.updateRevenue(amountMaxAddr, personalAmount, true);
                }
            }
        }

    }

    contract FMToken {
       function burn(address addr, uint value) public;
       function balanceOf(address who) external view returns (uint);
       function calculationNeedFM(uint usdtVal) external view returns(uint);
       function gainFMToken(uint value, bool isCovert) external;
       function transfer(address to, uint value) public;
    }

    contract FMMain {
        function rewardDistribution(address addr, uint amount) external returns(uint);
        function getPlayer(address addr) external view returns(uint, address, address[]);
        function getPlayerRechargeAmount(address addr) external view returns(uint);
        function releaseStaticPool(uint usdtVal) external;
        function updateRevenue(address addr, uint amount, bool flag) external;
    }