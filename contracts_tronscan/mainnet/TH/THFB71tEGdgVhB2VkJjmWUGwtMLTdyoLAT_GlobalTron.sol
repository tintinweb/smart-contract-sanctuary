//SourceUnit: global_tron_sources.sol


pragma solidity ^0.5.4;

/**
 * @title GlobalTron
**/
interface tokenTransfer {
    function deposit() external payable;
}

contract Util {
    uint ethWei = 1 trx;
    
    function getRecommendScaleByAmountAndTim(uint headcount,uint times) internal  pure returns(uint){
        //1
        if (times == 1) {
            return 100;
        }
        //2
        if(times == 2 && headcount >= 2){
            return 30;
        }
        //3-10
        if(times >= 3 && times <= 10){
            if(headcount >= times){
                return 10;
            }
        }
        return 0;
    }
    
    function getDividendRate(uint performance) internal view returns(uint) {
        if (performance < 10000 * ethWei) {
            return 5;
        }
        if (performance >= 10000 * ethWei && performance < 9000000 * ethWei) {
            return 10;
        }
        if (performance >= 9000000 * ethWei ) {
            return 15;
        }
        return 5;
    }
    
    function getDynamicLevel(uint performance) internal view returns(uint){
        if (performance < 1000000 * ethWei) {
            return 0;
        }
        if (performance >= 1000000 * ethWei && performance < 3000000 * ethWei) {
            return 1;
        }
        if (performance >= 3000000 * ethWei && performance < 6000000 * ethWei) {
            return 2;
        }
        if (performance >= 6000000 * ethWei) {
            return 3;
        }
        return 0;
    }
    
    function getAward(uint times) internal pure returns(uint){
        if (times == 1) {
            return 500;
        }
        if(times == 2){
            return 200;
        }
        if(times == 3){
            return 150;
        }
        if(times == 4){
            return 100;
        }
        if(times == 5){
            return 50;
        }
        return 0;
    }
    
    function getLeader(uint level,uint times) internal pure returns(uint){
        if(level == 1){
            if (times == 1) {
                return 15;
            }
        }
        if(level == 2){
            if (times == 1) {
                return 15;
            }
            if(times == 2){
                return 6;
            }
            if(times == 3){
                return 3;
            }
        }
        if(level == 3){
            if (times == 1) {
                return 15;
            }
            if(times == 2){
                return 6;
            }
            if(times == 3){
                return 3;
            }
            if(times == 4){
                return 2;
            }
            if(times == 5){
                return 1;
            }
        }
        return 0;
    }

    function compareStr(string memory _str, string memory str) internal pure returns(bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }
    
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelist(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelist(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function addWhitelist(address account) public onlyWhitelistAdmin {
        _addWhitelist(account);
    }

    function removeWhitelist(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
    }
    
    function isWhitelist(address account) private view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function _addWhitelist(address account) internal {
        _whitelistAdmins.add(account);
    }

}

contract GlobalTron is Util, WhitelistAdminRole {

    using SafeMath for *;

    string constant private name = "Global Tron";
    
    uint ethWei = 1 trx;
    
    struct User{
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
        uint staticLevel;
        uint dynamicLevel;
        uint allInvest;
        uint freezeAmount;
        uint allStaticAmount;
        uint allDynamicAmount;
        uint hisStaticAmount;
        uint hisDynamicAmount;
        uint hisGameAmount; 
        uint inviteAmount;  
        uint performance;   
        uint nodeCount; 
        uint nodePerformance;   
    	Invest[] invests;
    	uint staticFlag;
    	uint hitContributionAmount; 
    	uint maxLinePerformance;    
    }
    
    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }
    
    struct Invest{
        address userAddress;
        uint investAmount;
        uint limitAmount;
        uint earnAmount;
        uint investTime;
        uint times;
    }
    
    struct BigRound {
        uint strt;   // time round started
        uint end;    // time ends/ended
        address lastone;   // lastone
        uint gameAmount;
        bool ended;
    }
    
    struct GlobalChampion {
        address userAddress;
        uint total;
        uint performance;
    }
    
    uint startTime;
    uint endTime;
    uint investCount;
    mapping(uint => uint) rInvestCount;
    uint investMoney;
    mapping(uint => uint) rInvestMoney;
    uint uid = 0;
    uint rid = 1;
    uint period = 1 days;
    uint dividendRate = 10;
    uint statisticsDay;
    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) indexMapping;
    
    //==============================================================================
    tokenTransfer marketingAddress;
    
    GlobalChampion[] globalChampionArr;
    
    uint bigRid = 1;    // round id number / total rounds that have happened
    mapping (uint256 => BigRound) bigRound;   // (rID => data) round data
    
    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    event LogRedeem(address indexed who, uint indexed uid, uint amount, uint time);
    event LogGameWinner(address indexed who, uint amount, uint time,string gameType);

    //==============================================================================
    // Constructor
    //==============================================================================
    constructor (address payable marketingAddr) public {
        startTime = now;
        endTime = startTime.add(period);
        
        marketingAddress = tokenTransfer(marketingAddr);
    }

    function () external payable {
    }
    
    function investIn(string memory inviteCode,string memory referrer)
        public
        isHuman()
        payable
    {
        require(msg.value >= 1000*ethWei && msg.value <= 60000 * ethWei, "between 1000 and 60000");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");
        
        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");

            registerUser(msg.sender, inviteCode, referrer);
        }

        User storage user = userRoundMapping[rid][msg.sender];
	
	    uint value = msg.value;
	    
        uint8 isNewNode = 0;
        if (uint(user.userAddress) != 0) {
            require(user.freezeAmount.add(value) <= 60000 * ethWei, "can not beyond 60000 trx");
            
            user.allInvest = user.allInvest.add(value);
            user.freezeAmount = user.freezeAmount.add(value);
            
            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].performance += value;
            }
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = value;
            user.allInvest = value;
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
            
            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].inviteAmount++;
                userRoundMapping[rid][referrerAddr].performance += value;
                isNewNode++;
            }
        }
        
        uint limitAmount = value.mul(3);
        Invest memory invest = Invest(msg.sender, value, limitAmount, 0, now,0);
        user.invests.push(invest);
        
        investCount = investCount.add(1);
        investMoney = investMoney.add(value);
        statisticsDay = statisticsDay.add(value);
        
        upDynamicLevel();
	
        address okTmpUserAddr = addressMapping[userGlobal.referrer];
        User storage okUser = userRoundMapping[rid][okTmpUserAddr];
        uint pMaxLinePerformance = user.nodePerformance + user.allInvest;
        if (okUser.id != 0 && pMaxLinePerformance > okUser.maxLinePerformance) {
            okUser.maxLinePerformance = pMaxLinePerformance;
        }
        
        tjUserDynamicTree(isNewNode,userGlobal.referrer,value);
        
        statisticOfDay();
        
        statisticOfChampion(getUserAddressByCode(referrer),value);
        
        fixedDepositBank(value);
        
        emit LogInvestIn(msg.sender, userGlobal.id, value, now, userGlobal.inviteCode, userGlobal.referrer);
    }
    
    function statisticOfDay() private {
        bool flag = getTimeLeft() <= 0;
        if(flag){
            //update time
            startTime = endTime;
            endTime = startTime.add(period);
	        
	        //update dividendRate
            updateDividendRate();
            
            uint awardAmount = bigRound[bigRid].gameAmount.mul(10).div(100);
            if(awardAmount > 0){
                (address[5] memory ads,,uint[5] memory awards) = pkRanking();
                uint topLen = ads.length;
                
                for(uint i = 0;i<topLen;i++){
                    uint a = awards[i];
                    if(a > 0){
                       uint topAwar = awardAmount.mul(a).div(1000);
                       winnerAward(ads[i],topAwar,"King");
                    }
                }
                
                bigRound[bigRid].gameAmount = bigRound[bigRid].gameAmount.sub(awardAmount);
            }
            
            globalChampionArr.length = 0;
        }
    }
    
    function statisticOfChampion(address _sender,uint _value) private {
        //pk 5%
        bigRound[bigRid].gameAmount += _value.mul(5).div(100);
        
        if(uint(_sender) == 0){
            return;
        }
        
        uint addrIndex = getChampionIndex(globalChampionArr,_sender);
        if(addrIndex == 1000000){
            GlobalChampion memory cg = GlobalChampion(_sender,1,_value);
            globalChampionArr.push(cg);
        } else {
            GlobalChampion storage cg = globalChampionArr[addrIndex];
            cg.performance += _value;
        }
    }
    
    function getChampionIndex(GlobalChampion[] memory a,address _address) internal pure returns (uint) {
        uint256 length = a.length;
        for(uint i = 0; i < length; i++) {
            if(a[i].userAddress == _address){
                return i;
            }
        }
        return 1000000;
    }
    
    function pkCompare(address[] memory _top) internal view returns (uint,address) {
        uint max;
        address userAddress;
        
    	for(uint i = 0; i < globalChampionArr.length; i++) {
    	    if(globalChampionArr[i].performance > max){
    	        uint flag = 0;
    	        //check
                for(uint j = 0; j < _top.length;j++){
                    if(globalChampionArr[i].userAddress == _top[j]){
                        flag = 1;
                        break;
                    }
                }
                
                if(flag == 0){
                    max = globalChampionArr[i].performance;
                    userAddress = globalChampionArr[i].userAddress;
                }
            }
        }
        return (max,userAddress);
    }
    
    function pkRanking() public view returns (address[5] memory ads,uint[5] memory cts,uint[5] memory awards) {
    	
        address[] memory tops = new address[](5);
        for(uint i = 0; i<5; i++){
            (uint top,address topAddress) = pkCompare(tops);
            if(top == 0){
                break;
            }
            
            tops[i] = topAddress; 
            cts[i] = top;
            ads[i] = topAddress;
            awards[i] = getAward(i+1);
        }
        
        return (ads,cts,awards);
    }
    
    function withdrawProfit() public
    {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        
        statisticOfDay();
        useStaticAutoProfitInner(msg.sender,now,0);
        
        upDynamicLevel();
        
        uint resultMoney = user.allStaticAmount.add(user.allDynamicAmount);
        if (resultMoney > 0) {
            takeInner(msg.sender,resultMoney);
    	    
    	    tjUserFiveLevel(user.referrer,user.allStaticAmount);
            
            user.allStaticAmount = 0;
            user.allDynamicAmount = 0;
            
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }
    }
    
    function upDynamicLevel() private 
    {
        User storage calUser = userRoundMapping[rid][msg.sender];
        uint newDynamicLevel = getDynamicLevel(calUser.nodePerformance.sub(calUser.maxLinePerformance));
        if(newDynamicLevel > 0 && calUser.dynamicLevel != newDynamicLevel){
             calUser.dynamicLevel = newDynamicLevel;
        }
    }
    
    function fixedDepositBank(uint money) private {
        marketingAddress.deposit.value(money.mul(5).div(100))();
    }
    
    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        if (sendMoney >= address(this).balance) {
            return (false, address(this).balance);
        } else {
            return (true, sendMoney);
        }
    }
    
    function takeInner(address payable userAddress, uint money) private {
        uint sendMoney;
        (, sendMoney) = isEnoughBalance(money);
        if (sendMoney > 0) {
            userAddress.transfer(sendMoney);
        }
    }

    function useStaticAutoProfitInner(address userAddr,uint _now,uint _flag) private returns(uint)
    {
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }
        
        uint allStatic = 0;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest storage invest = user.invests[i];
            
            uint startDay = invest.investTime.div(period).mul(period);
            uint staticGaps = _now.sub(startDay).div(period);
            if (staticGaps < invest.times) {
                continue;
            }
            
            uint unclaimedDays =  staticGaps - invest.times;
            if(unclaimedDays > 7 && _flag == 0){
               unclaimedDays = 7; 
            }
            uint incomeByDay = invest.investAmount.mul(dividendRate).div(1000);
            uint incomeTotal = incomeByDay * unclaimedDays;
            
            allStatic = allStatic.add(incomeTotal);
            invest.earnAmount = invest.earnAmount.add(incomeTotal);
            invest.times = staticGaps;
            
            if (invest.earnAmount >= invest.limitAmount) {
                user.staticFlag = user.staticFlag.add(1);
                user.freezeAmount = user.freezeAmount.sub(invest.investAmount);
                
                uint xiuzheng = invest.earnAmount - invest.limitAmount;
                if(xiuzheng > 0){
                    allStatic = allStatic.sub(xiuzheng);
                    invest.earnAmount = invest.limitAmount;
                }
            }
        }
        
        user.allStaticAmount = user.allStaticAmount.add(allStatic);
        user.hisStaticAmount = user.hisStaticAmount.add(allStatic);
        return user.allStaticAmount;
    }
    
    function unbalancedStaticProfit(address userAddr) public view returns(uint)
    {
         User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }
        
        uint allStatic = 0;
        uint _now = now;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest storage invest = user.invests[i];
            
            uint startDay = invest.investTime.div(period).mul(period);
            uint staticGaps = _now.sub(startDay).div(period);
            if (staticGaps < invest.times) {
                continue;
            }
            
            uint unclaimedDays =  staticGaps - invest.times;
            if(unclaimedDays > 7){
               unclaimedDays = 7; 
            }
            uint incomeByDay = invest.investAmount.mul(dividendRate).div(1000);
            uint incomeTotal = incomeByDay * unclaimedDays;
            
            allStatic = allStatic.add(incomeTotal);
            uint earnAmount = invest.earnAmount.add(incomeTotal);
            
            if (earnAmount >= invest.limitAmount) {
                uint xiuzheng = invest.limitAmount - earnAmount;
                if(xiuzheng > 0){
                    allStatic = allStatic.sub(xiuzheng);
                }
            }
        }
        return allStatic;
    }
    
    function tjUserDynamicTree(uint8 isNewNode,string memory referrer, uint investAmount) private {
        string memory tmpReferrer = referrer;
        
        for (uint i = 1; i <= 10; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            if (calUser.id == 0) {
                break;
            }
            
            if(calUser.freezeAmount <= 0){
                tmpReferrer = calUser.referrer;
                continue;
            }
            
            if(isNewNode > 0){
                calUser.nodeCount = calUser.nodeCount.add(1);
            }
            
            calUser.nodePerformance = calUser.nodePerformance.add(investAmount);
            
            address pTmpUserAddr = addressMapping[calUser.referrer];
            User storage pUser = userRoundMapping[rid][pTmpUserAddr];
            uint pMaxLinePerformance = calUser.nodePerformance.add(calUser.allInvest);
            if (pUser.id != 0 && pMaxLinePerformance > pUser.maxLinePerformance) {
                pUser.maxLinePerformance = pMaxLinePerformance;
            }
            
            uint recommendSc = getRecommendScaleByAmountAndTim(calUser.inviteAmount, i);
            if (recommendSc != 0) {
                uint moneyResult = 0;
                if (investAmount <= calUser.freezeAmount) {
                    moneyResult = investAmount;
                } else {
                    moneyResult = calUser.freezeAmount;
                }
                
                uint tmpDynamicAmount = moneyResult.mul(recommendSc).div(1000);
                
                calUser.allDynamicAmount = calUser.allDynamicAmount.add(tmpDynamicAmount);
                calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(tmpDynamicAmount);
                
                Invest storage invest = calUser.invests[calUser.staticFlag];
                invest.earnAmount = invest.earnAmount.add(tmpDynamicAmount);
                if (invest.earnAmount >= invest.limitAmount) {
                    calUser.staticFlag = calUser.staticFlag.add(1);
                    calUser.freezeAmount = calUser.freezeAmount.sub(invest.investAmount);
                }
            }
            
            tmpReferrer = calUser.referrer;
        }
    }
    
    function tjUserFiveLevel(string memory referrer, uint staticAmount) private {
        string memory tmpReferrer = referrer;
        
        for (uint i = 1; i <= 5; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            if (calUser.id == 0) {
                break;
            }
            
            if(calUser.freezeAmount <= 0){
                tmpReferrer = calUser.referrer;
                continue;
            }
            
            
            if(calUser.dynamicLevel >= 1){
               uint levelAward = staticAmount.mul(getLeader(calUser.dynamicLevel,i)).div(100);
               calUser.allDynamicAmount = calUser.allDynamicAmount.add(levelAward);
               calUser.hitContributionAmount = calUser.hitContributionAmount.add(levelAward);
            }
            
            tmpReferrer = calUser.referrer;
        }
    }
    
    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }

    function getGameInfo() public isHuman() view returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return (
            rid,
            uid,
            endTime,
            investCount,
            investMoney,
            getTimeLeft(),
            bigRid,
            dividendRate
        );
    }
    
    function getUserInfo(address user, uint roundId, uint i) public isHuman() view returns(
        uint[28] memory ct, string memory inviteCode, string memory referrer
    ) {
        if(roundId == 0){
            roundId = rid;
        }

        User memory userInfo = userRoundMapping[roundId][user];

        ct[0] = userInfo.id;
        ct[1] = userInfo.staticLevel;
        ct[2] = userInfo.dynamicLevel;
        ct[3] = userInfo.allInvest;
        ct[4] = userInfo.freezeAmount;
        ct[5] = 0;
        ct[6] = userInfo.allStaticAmount;
        ct[7] = userInfo.allDynamicAmount;
        ct[8] = userInfo.hisStaticAmount;
        ct[9] = userInfo.hisDynamicAmount;
        ct[10] = userInfo.inviteAmount;
        ct[11] = userInfo.maxLinePerformance;
        ct[12] = userInfo.staticFlag;
        ct[13] = userInfo.invests.length;
        if (ct[13] != 0) {
            ct[14] = userInfo.invests[i].investAmount;
            ct[15] = userInfo.invests[i].limitAmount;
            ct[16] = userInfo.invests[i].earnAmount;
            ct[17] = userInfo.invests[i].investTime;
        } else {
            ct[14] = 0;
            ct[15] = 0;
            ct[16] = 0;
            ct[17] = 0;
        }
        ct[18] = userInfo.performance;
        ct[19] = userInfo.hisGameAmount;

        ct[20] = 0;
        ct[21] = userInfo.hitContributionAmount;
        ct[22] = 0;
        ct[23] = 0;
        ct[24] = 0;
        
        ct[25] = userInfo.nodeCount;    
        ct[26] = userInfo.nodePerformance;  
        ct[27] = unbalancedStaticProfit(user);   
        
        inviteCode = userMapping[user].inviteCode;
        referrer = userMapping[user].referrer;

        return (
            ct,
            inviteCode,
            referrer
        );
    }
    
    function getAwardInfo()
        public
        isHuman()
        view
        returns(uint256,uint,uint)
    {
        //my
        uint myPerformance;
        uint addrIndex = getChampionIndex(globalChampionArr,msg.sender);
        if(addrIndex != 1000000){
            myPerformance = globalChampionArr[addrIndex].performance;
        }
        
        return (bigRound[bigRid].gameAmount,getTimeLeft(),myPerformance);
    }
    
    function activeGame(uint time) external onlyWhitelistAdmin
    {
        require(time > now, "invalid game start time");
        startTime = time;
        endTime = startTime.add(period);
    }
    
    function correctionStatistics(uint _statisticsDay) external onlyWhitelistAdmin
    {
        statisticOfDay();
        
        //handle rate
        if(_statisticsDay != 0){
            uint betting = _statisticsDay * ethWei;
            dividendRate = getDividendRate(betting);
        }
    }
    
    function getTimeLeft() private view returns(uint256)
    {
        // grab time
        uint256 _now = now;

        if (_now < endTime)
            if (_now > startTime)
                return( endTime.sub(_now));
            else
                return( (startTime).sub(_now));
        else
            return(0);
    }
    
    function updateDividendRate() private {
        //handle rate
        uint newRate = getDividendRate(statisticsDay);
        dividendRate = newRate;
        statisticsDay = 0;
    }

    function winnerAward(address _address,uint sendMoney,string memory gameType) private 
    {
        User storage calUser = userRoundMapping[rid][_address];
        if(calUser.freezeAmount <= 0){
            emit LogGameWinner(_address,sendMoney,now,gameType);
            return;
        }
        
        calUser.hisGameAmount = calUser.hisGameAmount.add(sendMoney);
        
        address payable sendAddr = address(uint160(_address));
        takeInner(sendAddr,sendMoney);
        emit LogGameWinner(sendAddr,sendMoney,now,gameType);
    }
    
    function registerUserInfo(address user, string calldata inviteCode, string calldata referrer) external onlyOwner {
        registerUser(user, inviteCode, referrer);
    }
    
    function registerUser(address user, string memory inviteCode, string memory referrer) private {
        UserGlobal storage userGlobal = userMapping[user];
        uid++;
        userGlobal.id = uid;
        userGlobal.userAddress = user;
        userGlobal.inviteCode = inviteCode;
        userGlobal.referrer = referrer;

        addressMapping[inviteCode] = user;
        indexMapping[uid] = user;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");

        return c;
    }

}