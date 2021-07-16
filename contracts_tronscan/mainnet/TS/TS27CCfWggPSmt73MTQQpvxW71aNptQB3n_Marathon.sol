//SourceUnit: Marathon v4.sol

/*
 $$$$$$\            $$\      $$\                               $$\     $$\                           
$$  __$$\           $$$\    $$$ |                              $$ |    $$ |                          
$$ /  \__| $$$$$$\  $$$$\  $$$$ | $$$$$$\   $$$$$$\  $$$$$$\ $$$$$$\   $$$$$$$\   $$$$$$\  $$$$$$$\  
$$ |$$$$\ $$  __$$\ $$\$$\$$ $$ | \____$$\ $$  __$$\ \____$$\\_$$  _|  $$  __$$\ $$  __$$\ $$  __$$\ 
$$ |\_$$ |$$ /  $$ |$$ \$$$  $$ | $$$$$$$ |$$ |  \__|$$$$$$$ | $$ |    $$ |  $$ |$$ /  $$ |$$ |  $$ |
$$ |  $$ |$$ |  $$ |$$ |\$  /$$ |$$  __$$ |$$ |     $$  __$$ | $$ |$$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |
\$$$$$$  |\$$$$$$  |$$ | \_/ $$ |\$$$$$$$ |$$ |     \$$$$$$$ | \$$$$  |$$ |  $$ |\$$$$$$  |$$ |  $$ |
 \______/  \______/ \__|     \__| \_______|\__|      \_______|  \____/ \__|  \__| \______/ \__|  \__|


Telegram Channel: @gomarathon
Website: https://gomarathon.io

Telegram Chat EN: @gomarathonchat
Telegram Chat CN: @gomarathonchatcn
Telegram Chat RU: @gomarathonchatru
Telegram Chat ES: @gomarathonchates
*/

pragma solidity ^0.5.9;

contract MarathonLottery  {
    event payPrizeEvent(address indexed user, uint value, uint time, bool result, uint round); 
    event payDirectReferrersPrizeEvent(address indexed user, address indexed directReferrer, uint value, uint time, bool result, uint round); 
    
    Marathon marathon;
    address public owner;
    address public marathonId1Wallet = 0x0825b54ba88B2659959429bc6942be616D1ED802;
    uint public currentRound = 1;
    uint public betInRound = 0;
    uint public PRIZE_VALUE = 10000 trx;
    bytes32 lastHash;
    uint lastBlock;
    uint public LOTTERY_TICKET_PRICE = 25 trx;
    uint public LOTTERY_TICKET_COMMISSION = 5 trx;
    
    mapping (uint => address) public roundBetsUsers; 
    mapping (address => address) public directReferrers; 
    
    constructor() public {
        owner = 0x0316B9Af8a90A919C6F09d0048D755d85b20F6D8;
        marathon = Marathon(owner);
    }

    function () external payable{

    }

    function buyTicket(uint _referrerId) external payable{
        require(msg.sender == tx.origin, 'Lottery. Operation prohibited. No Contract');
        require(msg.value == (LOTTERY_TICKET_PRICE+LOTTERY_TICKET_COMMISSION), 'Lottery. Operation prohibited. Incorrect Value send');
        
        address directReferrer; 
        
        if(directReferrers[tx.origin]==address(0)){
           directReferrer = marathon.viewUserAddressById(_referrerId);
           
            if(directReferrer==address(0)){
                directReferrer = marathonId1Wallet;
            }
        } else {
            directReferrer = directReferrers[tx.origin];
        }
        
        
        address(uint160(marathonId1Wallet)).send(LOTTERY_TICKET_COMMISSION);
    

        
        if(address(this).balance > PRIZE_VALUE){
            payThePrize();
        }
        
        betInRound += 1;

        directReferrers[tx.origin] = directReferrer;
        roundBetsUsers[betInRound] = tx.origin;
        
        lastHash = blockhash(block.number - 1);
        lastBlock = block.number;
        
    }
    
    function createBet() external payable{
        require(msg.sender == owner, 'Lottery. Operation prohibited Sender != Owner');
        

        
        if(address(this).balance > PRIZE_VALUE){
            payThePrize();
        }
        
        betInRound += 1;
        
        directReferrers[tx.origin] = marathon.viewDirectReferrer(tx.origin);
        roundBetsUsers[betInRound] = tx.origin;
        lastHash = blockhash(block.number - 1);
        lastBlock = block.number; 
        
    }    

    function payThePrize() private  { 
        uint winTicket = 0;
        
        if(uint(blockhash(lastBlock))>0){
            winTicket = uint(blockhash(lastBlock)) % betInRound +1;
        }else{
            winTicket = uint(lastHash) % betInRound +1;
        }
        
        bool result = address(uint160(roundBetsUsers[winTicket])).send(PRIZE_VALUE/2);
        emit payPrizeEvent(roundBetsUsers[winTicket], PRIZE_VALUE/2, now, result, currentRound); 
        
        if(marathonId1Wallet != directReferrers[roundBetsUsers[winTicket]]){
            result = address(uint160(directReferrers[roundBetsUsers[winTicket]])).send(PRIZE_VALUE/2);
            emit payDirectReferrersPrizeEvent(roundBetsUsers[winTicket], directReferrers[roundBetsUsers[winTicket]], PRIZE_VALUE/2, now, result, currentRound); 
        }
        
        betInRound = 0;
        currentRound += 1;
    }
    
    function getBlockhash(uint _blockNumber) public view returns(uint) {
        return uint(blockhash(_blockNumber));
    }
    
    function getWinNum(uint _blockNumber) public view returns(uint) {
        uint winTicket = 0;
        
        if(uint(blockhash(lastBlock))>0){
            winTicket = uint(blockhash(lastBlock)) % betInRound +1;
        }else{
            winTicket = uint(lastHash) % betInRound +1;
        }
        return winTicket;
    }    
}

contract Marathon  {

    event tApproveEvent(address indexed _user, uint _tCode, uint globalEventId);
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time, uint _endTime, uint globalEventId);
    event buyLevelEvent(address indexed _user, uint _level, uint _time, uint _endTime, uint globalEventId);
    event buyAutoLevelEvent(address indexed _user, uint _level, uint _time, uint _endTime, uint globalEventId);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time, uint _endTime, uint globalEventId);
    event getMoneyFromLevelEvent(address indexed _user, address indexed _referral, uint _level, uint value, uint _time, uint globalEventId);
    event getMoneyForNextLevelEvent(address indexed _user, address indexed _referral, uint _level, uint value, uint _time, uint globalEventId);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint value, uint _time, uint globalEventId);
    event chUplineLogEvent(address indexed _chUpline, uint _idCh, uint _idDw, uint globalEventId);
    
    uint globalEventId = 0;
    
    address ownerWallet = 0x0825b54ba88B2659959429bc6942be616D1ED802;
    address managerWallet;

    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) public PERIOD_LENGTH;
    
    uint REFERRER_1_LEVEL_LIMIT = 2;
    uint public RENEWAL_NOT_EARLIER = 42 days;
    uint public LOTTERY_TICKET_PRICE = 25 trx;
    uint public START_TIME = 1616414400;
    bool public START_PERIOD = false;
    mapping (address => bool) whiteList;
    
    MarathonLottery public marathonLottery;


    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint directReferrerID;
        address[] referral;
        address[] directReferrals;
        mapping (uint => uint) levelExpired;
        mapping (uint => uint) incomeForLevel;
        mapping (uint => uint) incomeFromLevel;
        mapping (uint => uint) lostFromLevel;
    }
    
    
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;


    modifier _beforeStart  {
        if(START_PERIOD && now < START_TIME){
            require(
                whiteList[msg.sender],
                "Registration will start later"
            );
        }
        _;
    }


    constructor() public {
    
        LEVEL_PRICE[1] = 100 trx;
        LEVEL_PRICE[2] = 200 trx;
        LEVEL_PRICE[3] = 400 trx;
        LEVEL_PRICE[4] = 800 trx;
        LEVEL_PRICE[5] = 1600 trx;
        LEVEL_PRICE[6] = 1000 trx;
        LEVEL_PRICE[7] = 2000 trx;
        LEVEL_PRICE[8] = 4000 trx;
        LEVEL_PRICE[9] = 8000 trx;
        LEVEL_PRICE[10] = 16000 trx;
        LEVEL_PRICE[11] = 10000 trx;
        LEVEL_PRICE[12] = 20000 trx;
        LEVEL_PRICE[13] = 40000 trx;
        LEVEL_PRICE[14] = 80000 trx;
        LEVEL_PRICE[15] = 160000 trx;
        LEVEL_PRICE[16] = 100000 trx;
        LEVEL_PRICE[17] = 200000 trx;
        LEVEL_PRICE[18] = 400000 trx;
        LEVEL_PRICE[19] = 800000 trx;
        LEVEL_PRICE[20] = 1600000 trx;
        
        whiteList[0x00BebA6438B61469937F7963e4C01CD0a3eCA9a9] = true;
        whiteList[0xd6A2548Ce9F6908006d7258dfbaa5B555E50dacA] = true;
        whiteList[0xA26f7a9143091Edae4291f3C6ac24408Ab6A4E49] = true;
        whiteList[0xfC0f8A87Bd28F5836a6024db2beBB2bd9587246c] = true;
        whiteList[0x0A59DaFFb21f306B17E217A6FfFD265c335E0450] = true;
        whiteList[0xe02daeEed98082c55d6C3936C8850143608F6520] = true;
        whiteList[0xfd060DF9184c1529f52a2128c4f38df1C0a1be84] = true;
        whiteList[0xDc242fe7d2d451d32A5Bf27300fdF317e3dA0C8A] = true;      
        whiteList[0xd5758fCE3070451A8B99D272E1C82E62Eebe04cB] = true;
        whiteList[0x19faD1529cee9b00563D95dE2E4067c3b36F9DFd] = true;
        whiteList[0xc8CD12Fec4a0ebC89071a8424E8d4093dB1bD951] = true;
        whiteList[0x9a88658b3f16B5dB36abf94eE08837390203ff65] = true;
        whiteList[0xb881A51953632ce89a985FE40d941de6369B1Cd3] = true;
        whiteList[0xfb2F4014712Bc61eAfa3Ba419fB50D6e7DCD8a2a] = true;
        whiteList[0x6533908fc6CD806f70141380CF5B562BDd2CA5B4] = true;
        whiteList[0x74C10c857eAc8A16F25b848Eba9F42a6c4FcD12b] = true;          
        whiteList[0x2b959537490Bf49Cd9874fB2797D276138999FC6] = true;
        whiteList[0x455E18a0dC91286d1B816BaDab58c96A35af7906] = true;
        whiteList[0xe9bB8D8Fb84dD8703E95c86C29f3bB660eeb8f4b] = true;
        whiteList[0x2dd042c7Bf13e6aC8E4d7D7e38EdE347F5cA3cc9] = true;
        whiteList[0xcE6Ec4C768f133E7142434c71f779d54f0A36631] = true;
        whiteList[0xbD412f50b269d7E4A987F96041107ec74C312F61] = true;
        whiteList[0x554fDd12E2513BdB2512013B64dD861f91c60641] = true;
        whiteList[0x52ee7126DD891c447403b426C14a74F5b7C66e02] = true;    
        whiteList[0xaDf022e4493315f261eEBE1235D1c8D9B418a831] = true;         
    

        PERIOD_LENGTH[1] = 42 days;
        PERIOD_LENGTH[2] = 42 days;
        PERIOD_LENGTH[3] = 42 days;
        PERIOD_LENGTH[4] = 42 days;
        PERIOD_LENGTH[5] = 42 days;
        PERIOD_LENGTH[6] = 84 days;
        PERIOD_LENGTH[7] = 84 days;
        PERIOD_LENGTH[8] = 84 days;
        PERIOD_LENGTH[9] = 84 days;
        PERIOD_LENGTH[10] = 84 days;
        PERIOD_LENGTH[11] = 168 days;
        PERIOD_LENGTH[12] = 168 days;
        PERIOD_LENGTH[13] = 168 days;
        PERIOD_LENGTH[14] = 168 days;
        PERIOD_LENGTH[15] = 168 days;
        PERIOD_LENGTH[16] = 336 days;
        PERIOD_LENGTH[17] = 336 days;
        PERIOD_LENGTH[18] = 336 days;
        PERIOD_LENGTH[19] = 336 days;
        PERIOD_LENGTH[20] = 336 days;        
       

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 0,
            directReferrerID : 0,
            referral : new address[](0),
            directReferrals : new address[](0)
            
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        users[ownerWallet].levelExpired[1] = 77777777777;
        users[ownerWallet].levelExpired[2] = 77777777777;
        users[ownerWallet].levelExpired[3] = 77777777777;
        users[ownerWallet].levelExpired[4] = 77777777777;
        users[ownerWallet].levelExpired[5] = 77777777777;
        users[ownerWallet].levelExpired[6] = 77777777777;
        users[ownerWallet].levelExpired[7] = 77777777777;
        users[ownerWallet].levelExpired[8] = 77777777777;
        users[ownerWallet].levelExpired[9] = 77777777777;
        users[ownerWallet].levelExpired[10] = 77777777777;
        users[ownerWallet].levelExpired[11] = 77777777777;
        users[ownerWallet].levelExpired[12] = 77777777777;
        users[ownerWallet].levelExpired[13] = 77777777777;
        users[ownerWallet].levelExpired[14] = 77777777777;
        users[ownerWallet].levelExpired[15] = 77777777777;
        users[ownerWallet].levelExpired[16] = 77777777777;
        users[ownerWallet].levelExpired[17] = 77777777777;
        users[ownerWallet].levelExpired[18] = 77777777777;
        users[ownerWallet].levelExpired[19] = 77777777777;
        users[ownerWallet].levelExpired[20] = 77777777777;        
 
        marathonLottery = new MarathonLottery();
        managerWallet = msg.sender;
    }

    function tApprove(uint _tCode) external payable {
        globalEventId++;
        emit tApproveEvent(msg.sender, _tCode, globalEventId);
    }


    function regByAddress(address _user, uint _tCode) external _beforeStart payable {
        globalEventId++;
        emit tApproveEvent(msg.sender, _tCode, globalEventId);        

        uint level;

        if(msg.value == LEVEL_PRICE[1] + LOTTERY_TICKET_PRICE){
            level = 1;
        }else {
            revert('Incorrect Value send');
        }

        if(users[msg.sender].isExist){
            revert('You are already registered');
        } else {
            uint refId = 0;

            if (users[_user].isExist){
                refId = users[_user].id;
            } else {
                revert('Incorrect referrer');
            }

            regUser(refId);
        }
    }  
    
    function regById(uint _referrerID, uint _tCode) external _beforeStart payable {
        globalEventId++;
        emit tApproveEvent(msg.sender, _tCode, globalEventId);        

        uint level;

        if(msg.value == LEVEL_PRICE[1]+LOTTERY_TICKET_PRICE){
            level = 1;
        }else {
            revert('Incorrect Value send');
        }

        if(users[msg.sender].isExist){
            revert('You are already registered');
        } else {
            uint refId = 0;

            if (users[userList[_referrerID]].isExist){
                refId = _referrerID;
            } else {
                revert('Incorrect referrer');
            }

            regUser(refId);
        }
    }     
    
    function buy() external payable {

        uint level;
        uint valueForLevel = msg.value -LOTTERY_TICKET_PRICE;

        if(valueForLevel == LEVEL_PRICE[1]){
            level = 1;
        }else if(valueForLevel == LEVEL_PRICE[2]){
            level = 2;
        }else if(valueForLevel == LEVEL_PRICE[3]){
            level = 3;
        }else if(valueForLevel == LEVEL_PRICE[4]){
            level = 4;
        }else if(valueForLevel == LEVEL_PRICE[5]){
            level = 5;
        }else if(valueForLevel == LEVEL_PRICE[6]){
            level = 6;
        }else if(valueForLevel == LEVEL_PRICE[7]){
            level = 7;
        }else if(valueForLevel == LEVEL_PRICE[8]){
            level = 8;
        }else if(valueForLevel == LEVEL_PRICE[9]){
            level = 9;
        }else if(valueForLevel == LEVEL_PRICE[10]){
            level = 10;
        }else if(valueForLevel == LEVEL_PRICE[11]){
            level = 11;
        }else if(valueForLevel == LEVEL_PRICE[12]){
            level = 12;
        }else if(valueForLevel == LEVEL_PRICE[13]){
            level = 13;
        }else if(valueForLevel == LEVEL_PRICE[14]){
            level = 14;
        }else if(valueForLevel == LEVEL_PRICE[15]){
            level = 15;
        }else if(valueForLevel == LEVEL_PRICE[16]){
            level = 16;
        }else if(valueForLevel == LEVEL_PRICE[17]){
            level = 17;
        }else if(valueForLevel == LEVEL_PRICE[18]){
            level = 18;
        }else if(valueForLevel == LEVEL_PRICE[19]){
            level = 19;
        }else if(valueForLevel == LEVEL_PRICE[20]){
            level = 20;
        }else {
            revert('Incorrect Value send');
        }
        
        marathonLottery.createBet.value(LOTTERY_TICKET_PRICE)();

        if(users[msg.sender].isExist){

            if(users[msg.sender].incomeForLevel[level]>0 && users[msg.sender].incomeForLevel[level]<=address(this).balance && users[msg.sender].levelExpired[level] == 0){
                address(uint160(msg.sender)).send(address(this).balance - users[msg.sender].incomeForLevel[level]);
            }
            
            buyLevel(level);
        } else {
            revert("Please register");
        }
    }       


    function buySpecificLevel(uint _level) external payable {
        if(users[msg.sender].isExist){
            
            if(users[msg.sender].levelExpired[_level] == 0){
                require( (LOTTERY_TICKET_PRICE + users[msg.sender].incomeForLevel[_level] + address(this).balance) >= LEVEL_PRICE[_level], 'Insufficient funds');
            } else {
                require( (LOTTERY_TICKET_PRICE + address(this).balance) >= LEVEL_PRICE[_level], 'Insufficient funds');
            }
            
            marathonLottery.createBet.value(LOTTERY_TICKET_PRICE)();


            if(users[msg.sender].incomeForLevel[_level]>0 && users[msg.sender].incomeForLevel[_level]<=address(this).balance && users[msg.sender].levelExpired[_level] == 0){
                address(uint160(msg.sender)).send(address(this).balance - users[msg.sender].incomeForLevel[_level]);
            }
            
            buyLevel(_level);
        } else {
            revert("Please register");
        }
    }  

    function setStartPeriod() external {
        require(msg.sender == managerWallet, 'Operation prohibited');
        START_PERIOD = true;
    }


    function regUser(uint _referrerID) internal {
        
        uint directReferrerID = _referrerID;
        users[userList[directReferrerID]].directReferrals.push(msg.sender);

        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT)
        {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }


        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            directReferrerID: directReferrerID,
            referrerID : _referrerID,
            referral : new address[](0),
            directReferrals : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH[1];

        users[userList[_referrerID]].referral.push(msg.sender);

        marathonLottery.createBet.value(LOTTERY_TICKET_PRICE)(); 
        
        payForLevel(1, msg.sender);
        
        globalEventId++;
        emit regLevelEvent(msg.sender, userList[_referrerID], now, users[msg.sender].levelExpired[1], globalEventId);
        
    }

    function buyLevel(uint _level) internal {
        
        require(users[msg.sender].levelExpired[_level] < now + RENEWAL_NOT_EARLIER, 'The level has already been extended for a long time. Try later');

        if(_level == 1){
            if(users[msg.sender].levelExpired[_level] < now){
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH[_level];
            } else {
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH[_level];
            }
        } else {
            for(uint l =_level-1; l>0; l-- ){
                require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
            }

            if(users[msg.sender].levelExpired[_level] < now){
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH[_level];
            } else {
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH[_level];
            }
        }

        payForLevel(_level, msg.sender);
        globalEventId++;
        emit buyLevelEvent(msg.sender, _level, now, users[msg.sender].levelExpired[_level], globalEventId);
    }

    function payForLevel(uint _level, address _user) internal {
        
        address referrer;
        if(_level>15)
            referrer = getUserReferrer(_user, _level-15);
        else if(_level>10)
            referrer = getUserReferrer(_user, _level-10);
        else if(_level>5) {
            referrer = getUserReferrer(_user, _level-5);
        } else{
            referrer = getUserReferrer(_user, _level);
        }

        if(!users[referrer].isExist){
            referrer = userList[1];
        }

        if(users[referrer].levelExpired[_level] >= now ){
            if(users[referrer].levelExpired[_level+1] > 0 || _level== 5 || _level== 10 || _level== 15 || _level== 20){
                bool result;
                users[referrer].incomeFromLevel[_level] += address(this).balance;
                result = address(uint160(referrer)).send(address(this).balance);
                globalEventId++;
                emit getMoneyFromLevelEvent(referrer, msg.sender, _level, address(this).balance, now, globalEventId);
            } else{
                users[referrer].incomeForLevel[_level+1] += address(this).balance;
                globalEventId++;
                emit getMoneyForNextLevelEvent(referrer, msg.sender, _level+1, address(this).balance, now, globalEventId);
                if(users[referrer].incomeForLevel[_level+1] >= LEVEL_PRICE[_level+1]){
                    users[referrer].levelExpired[_level+1] = now + PERIOD_LENGTH[_level+1];
                    globalEventId++;
                    emit buyAutoLevelEvent(referrer, _level, now, users[msg.sender].levelExpired[_level], globalEventId);
                }
                payForLevel(_level+1,referrer);
            }
        } else {

                users[referrer].lostFromLevel[_level] += address(this).balance;
                globalEventId++;
                emit lostMoneyForLevelEvent(referrer, msg.sender, _level, address(this).balance, now, globalEventId);
                payForLevel(_level,referrer);  
            
        }
    }


    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT){
            return _user;
        }

        address[] memory referrals = new address[](2046);
        referrals[0] = users[_user].referral[0]; 
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i =0; i<2046;i++){
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT){
                if(i<1022){
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            }else{
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'No Free Referrer');
        return freeReferrer;

    }
    
    function getUserReferrer(address _user, uint _level) public view returns (address) {
      if (_level == 0 || _user == address(0)) {
        return _user;
      }

      return this.getUserReferrer(userList[users[_user].referrerID], _level - 1);
    }    

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    
    function viewUserDirectReferrals(address _user) public view returns(address[] memory) {
        return users[_user].directReferrals;
    }    
    
    function viewDirectReferrer(address _user) public view returns(address) {
        return userList[users[_user].directReferrerID];
    }
    
    function viewUserAddressById(uint _userId) public view returns(address) {
        return userList[_userId];
    }    
    

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return users[_user].levelExpired[_level];
    }
    
    function viewUserIncomeForLevel(address _user, uint _level) public view returns(uint) {
        return users[_user].incomeForLevel[_level];
    }    
    
    function viewUserIncomeFromLevel(address _user, uint _level) public view returns(uint) {
        return users[_user].incomeFromLevel[_level];
    }       
    
    function viewUserLostFromLevel(address _user, uint _level) public view returns(uint) {
        return users[_user].lostFromLevel[_level];
    }       
        
    function bytesToAddress(bytes memory bys) private pure returns (address  addr ) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function newMarathonLottery(address payable _marathonLottery) external {
        require(msg.sender == managerWallet, 'Operation prohibited');
        marathonLottery = MarathonLottery(_marathonLottery);
    }    
    
    function addToWhiteList(address _address) external {
        require(msg.sender == managerWallet, 'Operation prohibited');
        whiteList[_address] = true;
    }     
  
}