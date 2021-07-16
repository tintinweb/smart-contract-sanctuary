//SourceUnit: FmMain.sol

pragma solidity 0.4.25;


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

    contract FMMain {


        address owner;

        address specifyAddr;

        address technologyAddr;

        address gameAddr;

        address[] temp = new address[](0);

        uint public staticPrizePool;

        uint public staticTotalRecharge;

        address[] allPlayer;

        address[] shareholdersV1;

        address[] shareholdersV2;

        address[] shareholdersV3;

        address[] shareholdersV4;

        address[] shareholdersV5;

        uint public usdtPool;

        mapping(address => uint) lastChangeTime;

        TetherToken tether;
        
        FMToken fmToken;

        FMGame game;

        mapping(address => DappDatasets.Player) public playerMap;

        constructor(
            address _owner,
            address _tetherAddr,
            address _fmAddr,
            address _gameAddr,
            address _technologyAddr,
            address _specifyAddr
        )  public {
            owner = _owner;
            DappDatasets.Player memory player = DappDatasets.Player(
                {
                    withdrawalAmount : 0,
                    wallet : 0,
                    fomoTotalRevenue : 0,
                    lotteryTotalRevenue : 0,
                    dynamicIncome : 0,
                    rechargeAmount : 0,
                    lastRechargeAmount : 0,
                    staticIncome : 0,
                    shareholderLevel : 0, 
                    underUmbrellaLevel : 0,
                    subbordinateTotalPerformance : 0, 
                    isExist : true,
                    superior : false,
                    superiorAddr : address(0x0), 
                    subordinates : temp
                }
            );
            specifyAddr = _specifyAddr;
            playerMap[owner] = player;
            tether = TetherToken(_tetherAddr);
            fmToken = FMToken(_fmAddr);
            game = FMGame(_gameAddr);
            gameAddr = _gameAddr;
            technologyAddr = _technologyAddr;
            allPlayer.push(owner);
        }

        function() public payable {
            withdrawImpl(msg.sender);
        }

        function addWalletAndDynamicIncome(address addr, uint num) internal {
            uint motionAndStaticAmount = SafeMath.add(playerMap[addr].staticIncome, playerMap[addr].dynamicIncome);
            uint withdrawableBalance = SafeMath.div(SafeMath.mul(playerMap[addr].rechargeAmount, 33), 10);
            
            if(motionAndStaticAmount >= withdrawableBalance) {
                return;
            }else {
                uint amount = SafeMath.sub(withdrawableBalance, motionAndStaticAmount);
                if(num > amount){
                    playerMap[addr].wallet = SafeMath.add(playerMap[addr].wallet, amount);
                    playerMap[addr].dynamicIncome = SafeMath.add(playerMap[addr].dynamicIncome, amount);                       
                }else {
                    playerMap[addr].wallet = SafeMath.add(playerMap[addr].wallet, num);
                    playerMap[addr].dynamicIncome = SafeMath.add(playerMap[addr].dynamicIncome, num);
                }
            }

        }

        function getShareholder() external view returns(uint, uint, uint, uint, uint, uint) {
            return (
                shareholdersV1.length - shareholdersV2.length,
                shareholdersV2.length - shareholdersV3.length,
                shareholdersV3.length - shareholdersV4.length,
                shareholdersV4.length - shareholdersV5.length,
                shareholdersV5.length,
                allPlayer.length
            );
        }

        function getStaticStatus() external view returns(uint, uint, uint) {
            uint LeftTime= SafeMath.sub(DappDatasets.getNowTime(), lastChangeTime[msg.sender]);
            uint LeftTimeNum = SafeMath.div(LeftTime, 24 * 60 * 60);
            uint perAmount;
            if(LeftTimeNum > 0){
                perAmount = SafeMath.div(SafeMath.mul(playerMap[msg.sender].lastRechargeAmount, LeftTimeNum), 250);
            }

            return (
                lastChangeTime[msg.sender],
                playerMap[msg.sender].lastRechargeAmount,
                perAmount
            );
        }

        function getStatistics() external view returns(
            uint level,
            uint destroyedQuantity,
            uint fomoTotalRevenue,
            uint lotteryTotalRevenue,
            uint difference
        ) {
            return (
                playerMap[msg.sender].shareholderLevel,
                fmToken.balanceOf(address(0x0)),
                playerMap[msg.sender].fomoTotalRevenue,
                playerMap[msg.sender].lotteryTotalRevenue,
                SafeMath.sub(
                    SafeMath.div(SafeMath.mul(playerMap[msg.sender].rechargeAmount, 33), 10), 
                    playerMap[msg.sender].staticIncome
                )
            );
        }
		
        function getSubordinatesAndPerformanceByAddr(address addr) external view returns(address[], uint[], uint[]) {
            DappDatasets.Player storage player = playerMap[addr];
            uint[] memory performance = new uint[](player.subordinates.length);
            uint[] memory numberArray = new uint[](player.subordinates.length);
            for(uint i = 0; i < player.subordinates.length; i++) {
                performance[i] = SafeMath.add(
                    playerMap[player.subordinates[i]].subbordinateTotalPerformance,
                    playerMap[player.subordinates[i]].rechargeAmount
                );
                numberArray[i] = playerMap[player.subordinates[i]].subordinates.length;
            }
            return (player.subordinates, performance, numberArray);
        }
		
        function getPlayerInfo() external view returns(address superiorAddr, address ownerAddr, uint numberOfInvitations, bool exist) {
            return (playerMap[msg.sender].superiorAddr,  msg.sender, playerMap[msg.sender].subordinates.length, playerMap[msg.sender].isExist);
        }

        function getRevenueAndPerformance() external view returns(
            uint withdrawalAmount,
            uint subbordinateTotalPerformance,
            uint dynamicIncome,
            uint staticIncome,
            uint withdrawn,
            uint outboundDifference
        ) {
            uint number = 0;
            uint motionAndStaticAmount = SafeMath.add(playerMap[msg.sender].staticIncome, playerMap[msg.sender].dynamicIncome);
            uint withdrawableBalance = SafeMath.div(SafeMath.mul(playerMap[msg.sender].rechargeAmount, 33), 10);
            if(motionAndStaticAmount > withdrawableBalance) {
                number = SafeMath.sub(motionAndStaticAmount, withdrawableBalance);
            }
            uint value = SafeMath.add(playerMap[msg.sender].dynamicIncome, playerMap[msg.sender].staticIncome);
            uint difference = 0;
            
            if(value > SafeMath.div(SafeMath.mul(playerMap[msg.sender].rechargeAmount, 33), 10)) {
                difference = 0;
            }else {
                difference = SafeMath.sub(SafeMath.div(SafeMath.mul(playerMap[msg.sender].rechargeAmount, 33), 10), value);
            }
            return (
                SafeMath.sub(playerMap[msg.sender].wallet, number),
                playerMap[msg.sender].subbordinateTotalPerformance,
                playerMap[msg.sender].dynamicIncome,
                playerMap[msg.sender].staticIncome,
                playerMap[msg.sender].withdrawalAmount,
                difference
            );
        }
        
        function withdrawImpl(address addr) internal {
            require(playerMap[addr].wallet > 0, "Insufficient wallet balance");

            uint number = 0;
            uint motionAndStaticAmount = SafeMath.add(playerMap[addr].staticIncome, playerMap[addr].dynamicIncome);
            uint withdrawableBalance = SafeMath.div(SafeMath.mul(playerMap[addr].rechargeAmount, 33), 10);

            if(motionAndStaticAmount > withdrawableBalance) {
                number = SafeMath.sub(motionAndStaticAmount, withdrawableBalance);
            }

            uint amount = SafeMath.sub(playerMap[addr].wallet, number);
            uint value = amount;
            if(amount > 1000 * 10 ** 6) {
                value = 1000 * 10 ** 6;
            }
			
            uint leftPool;
            (, , , leftPool, ) = game.getFOMOInfo();
			
 			if(tether.balanceOf(this) > leftPool) {
			  if(SafeMath.sub(tether.balanceOf(this), leftPool) < value) {
			      return;
			  }
			} else {
			  return;
			}          
            
            playerMap[addr].wallet = SafeMath.sub(playerMap[addr].wallet, value);
            playerMap[addr].withdrawalAmount = SafeMath.add(playerMap[addr].withdrawalAmount, value);

            uint handlingFee = SafeMath.div(value, 10);
            game.buyLotto(handlingFee, addr);
            staticPrizePool = SafeMath.add(staticPrizePool, handlingFee);
            tether.transfer(addr, SafeMath.sub(value, handlingFee));
        }

        function withdrawService() external {
            withdrawImpl(msg.sender);
        }

        function getStaticIncome() external {
            StaticPayment(msg.sender);
        }

        function StaticPayment(address addr) internal {
            uint lastTime = lastChangeTime[msg.sender];
            require(DappDatasets.getNowTime() > lastTime, "It is not time yet");
            
            uint LeftTime= SafeMath.sub(DappDatasets.getNowTime(), lastTime);
            if(LeftTime < 24 * 60 * 60){
                return;
            }
            uint LeftTimeNum = SafeMath.div(LeftTime, 24 * 60 * 60);

            uint totalAmount = SafeMath.add(playerMap[addr].staticIncome, playerMap[addr].dynamicIncome);
            uint totalBalance = SafeMath.div(SafeMath.mul(playerMap[addr].rechargeAmount, 33), 10);

            if(totalAmount >= totalBalance) {
                return;
            }else if(LeftTimeNum > 0){
                
                uint perAmount = SafeMath.div(SafeMath.mul(playerMap[addr].lastRechargeAmount, LeftTimeNum), 250);
                uint amount = SafeMath.add(totalAmount, perAmount);
                uint number = 0;
                if(amount > totalBalance){
                    number = SafeMath.sub(perAmount,SafeMath.sub(amount, totalBalance));
                }else{
                    number = perAmount;
                }

                if(number > 0){
                    playerMap[addr].staticIncome = SafeMath.add(playerMap[addr].staticIncome, number);
                    playerMap[addr].wallet = SafeMath.add(playerMap[addr].wallet, number);
                    lastChangeTime[msg.sender] = now;
                }else {
                    return;
                }

            }

        }

        function participateFomo(uint usdtVal, address superiorAddr) external {
            require(usdtVal >= 300 * 10 ** 6, "Less than the minimum amount");
            register(msg.sender, superiorAddr);
            lastChangeTime[msg.sender] = now;

            DappDatasets.Player storage player = playerMap[msg.sender];
            player.rechargeAmount = SafeMath.add(player.rechargeAmount, usdtVal);
            player.lastRechargeAmount = usdtVal;

            staticTotalRecharge = SafeMath.add(staticTotalRecharge, usdtVal);

            uint amount = SafeMath.div(SafeMath.mul(usdtVal, 3), 100);
            tether.transferFrom(msg.sender, technologyAddr, amount);

            uint uAmount = SafeMath.div(SafeMath.mul(usdtVal, 7), 100);
            usdtPool = SafeMath.add(usdtPool, uAmount);

            increasePerformance(usdtVal);

            uint remaining = game.deposit(usdtVal, msg.sender);
            staticPrizePool = SafeMath.add(staticPrizePool, remaining);
            
            tether.transferFrom(msg.sender, this, SafeMath.sub(usdtVal, amount));
        }

        function increasePerformance(uint usdtVal) internal {
            DappDatasets.Player storage player = playerMap[msg.sender];
            uint length = 0;
            while(player.superior && length < 50) {
                address tempAddr = player.superiorAddr;
                player = playerMap[player.superiorAddr];
                player.subbordinateTotalPerformance = SafeMath.add(player.subbordinateTotalPerformance, usdtVal);
                promotionMechanisms(tempAddr);
                length++;
                if(length == 50) {
                    break;
                }
            }
        }

        function promotionMechanisms(address addr) internal {
            DappDatasets.Player storage player = playerMap[addr];
            if(player.subbordinateTotalPerformance >= 10 * 10 ** 10) {
                uint length = player.subordinates.length;
                if(player.subordinates.length > 30) {
                    length = 30;
                }
                for(uint i = 0; i < 5; i++) {
                    if(player.shareholderLevel == i) {
                        uint levelCount = 0;
                        if(i == 0 && length >= 10){
                            player.shareholderLevel = 1;
                            shareholdersV1.push(addr);
                        }
                        for(uint j = 0; j < length; j++) {
                            if(i == 0) {
                                if(length >= 10) {
                                    levelCount++;
                                }
                            }else if(i == 1) {
                                if(playerMap[player.subordinates[j]].shareholderLevel >= 1 || playerMap[player.subordinates[j]].underUmbrellaLevel >= 1) {
                                    levelCount++;
                                }
                            }else if(i == 2) {
                                if(playerMap[player.subordinates[j]].shareholderLevel >= 2 || playerMap[player.subordinates[j]].underUmbrellaLevel >= 2) {
                                    levelCount++;
                                }
                            }else if(i == 3) {
                                if(playerMap[player.subordinates[j]].shareholderLevel >= 3 || playerMap[player.subordinates[j]].underUmbrellaLevel >= 3) {
                                    levelCount++;
                                }
                            }else if(i == 4) {
                                if(playerMap[player.subordinates[j]].shareholderLevel >= 4 || playerMap[player.subordinates[j]].underUmbrellaLevel >= 4) {
                                    levelCount++;
                                }
                            }

                            if(levelCount >= 2) {
                                if(i == 1 ) {
                                    player.shareholderLevel = 2;
                                    shareholdersV2.push(addr);
                                }else if(i == 2) {
                                    player.shareholderLevel = 3;
                                    shareholdersV3.push(addr);
                                }else if(i == 3) {
                                    player.shareholderLevel = 4;
                                    shareholdersV4.push(addr);
                                }else if(i == 4 && levelCount >= 3){
                                    player.shareholderLevel = 5;
                                    shareholdersV5.push(addr);
                                }
                                
                                DappDatasets.Player storage tempPlayer = player;
                                uint count = 0;
                                while(tempPlayer.superior && count < 50) {
                                    tempPlayer = playerMap[tempPlayer.superiorAddr];
                                    if(tempPlayer.underUmbrellaLevel < i + 1 && i < 4) {
                                        tempPlayer.underUmbrellaLevel = i + 1;
                                    }else if(tempPlayer.underUmbrellaLevel < i + 1 && i == 4 && levelCount >= 3){
                                        tempPlayer.underUmbrellaLevel = i + 1;
                                    }else {
                                        break;
                                    }
                                    count++;
                                    if(count == 50) {
                                        break;
                                    }
                                }

                                if(i < 4){
                                   break;
                                }else if(i == 4 && levelCount >= 3){
                                   break;
                                }

                            }
                        }
                    }
                }

            }
        }

        function rewardDistribution(address addr, uint amount) external returns(uint) {
            require(gameAddr == msg.sender, "Insufficient permissions");
            addWalletAndDynamicIncome(addr, amount);
            return amount;
        }

        function releaseStaticPool(uint usdtVal) external {
            require(gameAddr == msg.sender, "Insufficient permissions");
            staticPrizePool = SafeMath.add(staticPrizePool, usdtVal);
        }

        function updateRevenue(address addr, uint amount, bool flag) external {
            require(gameAddr == msg.sender, "Insufficient permissions");
            DappDatasets.Player storage player = playerMap[addr];
            if(flag) {
                player.wallet = SafeMath.add(player.wallet, amount);
                player.fomoTotalRevenue = SafeMath.add(player.fomoTotalRevenue, amount);
            }else {
                player.wallet = SafeMath.add(player.wallet, amount);
                player.lotteryTotalRevenue = SafeMath.add(player.lotteryTotalRevenue, amount);
            }
        }

        function resetNodePool() external {
            require(owner == msg.sender, "Insufficient permissions");
            usdtPool = 0;
        }

        function usdtNodeV1(uint start, uint count) external {
            require(owner == msg.sender, "Insufficient permissions");
            uint awardV1 = SafeMath.div(SafeMath.mul(usdtPool, 3), 7);
            if(shareholdersV1.length < 1) {
                staticPrizePool = SafeMath.add(staticPrizePool, awardV1);
            }else {
                uint NodeV1Len = shareholdersV1.length - shareholdersV4.length;
                uint award = SafeMath.div(awardV1,NodeV1Len);
                uint index = 0;
                for(uint i = start; i < shareholdersV1.length; i++) {
                    if(playerMap[shareholdersV1[i]].shareholderLevel < 4){
                        addWalletAndDynamicIncome(shareholdersV1[i], award);
                    }
                    index++;
                    if(index == count) {
                        break;
                    }
                }
            }
        }

        function usdtNodeV4(uint start, uint count) external {
            require(owner == msg.sender, "Insufficient permissions");
            uint awardV4 = SafeMath.div(SafeMath.mul(usdtPool, 3), 7);
            if(shareholdersV4.length < 1) {
                staticPrizePool = SafeMath.add(staticPrizePool, awardV4);
            }else {
                uint award = SafeMath.div(awardV4,shareholdersV4.length);
                uint index = 0;
                for(uint i = start; i < shareholdersV4.length; i++) {
                    if(playerMap[shareholdersV4[i]].shareholderLevel > 3){
                        addWalletAndDynamicIncome(shareholdersV4[i], award);
                    }
                    index++;
                    if(index == count) {
                        break;
                    }
                }
            }
        }

        function usdtNodeV5(uint start, uint count) external {
            require(owner == msg.sender, "Insufficient permissions");
            uint awardV5 = SafeMath.div(SafeMath.mul(usdtPool, 1), 7);
            if(shareholdersV5.length < 1) {
                staticPrizePool = SafeMath.add(staticPrizePool, awardV5);
            }else {
                uint award = SafeMath.div(awardV5,shareholdersV5.length);
                uint index = 0;
                for(uint i = start; i < shareholdersV5.length; i++) {
                    if(playerMap[shareholdersV5[i]].shareholderLevel == 5){
                        addWalletAndDynamicIncome(shareholdersV5[i], award);
                    }
                    index++;
                    if(index == count) {
                        break;
                    }
                }
            }
        }

        function getPlayer(address addr) external view returns(uint, address, address[]) {
            DappDatasets.Player memory player = playerMap[addr];
            return (playerMap[player.superiorAddr].shareholderLevel, player.superiorAddr, playerMap[player.superiorAddr].subordinates);
        }

        function getPlayerRechargeAmount(address addr) external view returns(uint) {
            return playerMap[addr].lastRechargeAmount;
        }
        
        function exchange(uint usdtVal) external {
            require(usdtVal >= 10 ** 6, "Redeem at least 1USDT");
            uint usdtPrice = fmToken.usdtPrice();
            game.redeemFM(usdtVal, usdtPrice, msg.sender);
            
            if(usdtPrice < 10 ** 6){
                uint staticAmount = SafeMath.div(SafeMath.mul(usdtVal, 4), 10);
            }else if(usdtPrice < 50 ** 6){
                staticAmount = SafeMath.div(SafeMath.mul(usdtVal, 5), 10);
            }else if(usdtPrice < 100 ** 6){
                staticAmount = SafeMath.div(SafeMath.mul(usdtVal, 7), 10);
            }else{
                staticAmount = SafeMath.div(SafeMath.mul(usdtVal, 95), 100);
            }
            staticPrizePool = SafeMath.add(staticPrizePool, staticAmount);
            tether.transferFrom(msg.sender, this, staticAmount);
            tether.transferFrom(msg.sender, specifyAddr, SafeMath.sub(usdtVal, staticAmount));
        }

        function register(address addr, address superiorAddr) internal{
            if(playerMap[addr].isExist == true) {
                return;
            }
            DappDatasets.Player memory player;
            if(superiorAddr == address(0x0) || playerMap[superiorAddr].isExist == false) {
                player = DappDatasets.Player(
                    {
                        withdrawalAmount             : 0,
                        wallet                       : 0,
                        fomoTotalRevenue             : 0,
                        lotteryTotalRevenue          : 0,
                        dynamicIncome                : 0,
                        rechargeAmount               : 0,
                        lastRechargeAmount           : 0,
                        staticIncome                 : 0,
                        shareholderLevel             : 0,
                        underUmbrellaLevel           : 0,
                        subbordinateTotalPerformance : 0,
                        isExist                      : true,
                        superior                     : false,
                        superiorAddr                 : address(0x0),
                        subordinates                 : temp
                    }
                );
                playerMap[addr] = player;
            }else {
                player = DappDatasets.Player(
                    {
                        withdrawalAmount : 0,
                        wallet : 0,
                        fomoTotalRevenue : 0,
                        lotteryTotalRevenue : 0,
                        dynamicIncome : 0,
                        rechargeAmount : 0,
                        lastRechargeAmount : 0,
                        staticIncome : 0,
                        shareholderLevel : 0,
                        underUmbrellaLevel : 0,
                        subbordinateTotalPerformance : 0,
                        isExist : true,
                        superior : true,
                        superiorAddr : superiorAddr,
                        subordinates : temp
                    }
                );
                DappDatasets.Player storage superiorPlayer = playerMap[superiorAddr];
                superiorPlayer.subordinates.push(addr);
                playerMap[addr] = player;
            }
            allPlayer.push(addr);
        }

    }

    contract TetherToken {
       function transfer(address to, uint value) public;
       function transferFrom(address from, address to, uint value) public;
       function balanceOf(address who) public view returns (uint256);
    }

    contract FMToken {
       function burn(address addr, uint value) public;
       function balanceOf(address who) external view returns (uint);
       function calculationNeedFM(uint usdtVal) external view returns(uint);
       function usdtPrice() external view returns(uint);
    }

    contract FMGame {
        function deposit(uint usdtVal, address addr) external returns(uint);
        function updateLotteryPoolAndTodayAmountTotal(uint usdtVal, uint lotteryPool) external;
        function redeemFM(uint usdtVal, uint usdtPrice, address addr) external;
        function buyLotto(uint usdtVal, address addr) external;
        function getFOMOInfo() external view returns(uint Session, uint nowTime, uint endTime, uint prizePool, bool isEnd);
    }