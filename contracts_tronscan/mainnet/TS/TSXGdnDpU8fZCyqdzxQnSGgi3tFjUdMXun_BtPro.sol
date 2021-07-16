//SourceUnit: bt.sol

pragma solidity ^0.5.0;

/**
 * @title BT
**/
interface tokenTransfer {
    function totalSupply() external view returns (uint256);
    function balanceOf(address receiver) external returns(uint256);
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Util {
    uint usdtWei = 1e6;
    
    //��̬����
    function getRecommendScaleByAmountAndTim(uint performance,uint times) internal view returns(uint){
        if (times == 1) {
            return 18;
        }
        if(performance >= 2000*usdtWei && performance < 6000*usdtWei){
            if (times == 2){
                return 10;
            }
            if(times == 3){
                return 8;
            }
        }
        if(performance >= 6000*usdtWei && performance < 10000*usdtWei){
            if (times == 2){
                return 10;
            }
            if(times == 3){
                return 8;
            }
            if(times == 4){
                return 5;
            }
            if(times >= 5 && times <= 10){
                return 4;
            }
        }
        if(performance >= 10000*usdtWei && performance < 20000*usdtWei){
            if (times == 2){
                return 10;
            }
            if(times == 3){
                return 8;
            }
            if(times == 4){
                return 5;
            }
            if(times >= 5 && times <= 15){
                return 4;
            }
        }
        if(performance >= 20000*usdtWei){
            if (times == 2){
                return 10;
            }
            if(times == 3){
                return 8;
            }
            if(times == 4){
                return 5;
            }
            if(times >= 5 && times <= 15){
                return 4;
            }
            if(times >= 16 && times <= 20){
                return 3;
            }
        }
        
        return 0;
    }
    
    //PK����
    function getAward(uint times) internal pure returns(uint){
        if (times == 1) {
            return 35;
        }
        if(times == 2){
            return 25;
        }
        if(times == 3){
            return 20;
        }
        if(times == 4){
            return 12;
        }
        if(times == 5){
            return 8;
        }
        return 0;
    }
    
    //�û��ȼ�
    function getDynLevel(uint myPerformance,uint hashratePerformance) internal view returns(uint) {
        if (myPerformance < 2000 * usdtWei || hashratePerformance < 2000 * usdtWei) {
            return 0;
        }
        if (hashratePerformance >= 2000 * usdtWei && hashratePerformance < 30000 * usdtWei) {
            return 1;
        }
        if (hashratePerformance >= 30000 * usdtWei && hashratePerformance < 200000 * usdtWei) {
            return 2;
        }
        if (hashratePerformance >= 200000 * usdtWei && hashratePerformance < 500000 * usdtWei) {
            return 3;
        }
        if (hashratePerformance >= 500000 * usdtWei) {
            return 4;
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
        this; 
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

contract CoinTokenWrapper {
    
    using SafeMath for *;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }
}

contract BtPro is Util, WhitelistAdminRole,CoinTokenWrapper {

    string constant private name = "Bt Pro";

    struct User{
        uint id;
        string referrer;
        uint dynamicLevel;
        uint allInvest;
        uint freezeAmount;
        uint allDynamicAmount;
        uint hisDynamicAmount;
	    //Game
        uint hisGameAmount; 
	    //�ҵ�ֱ��ҵ��
        uint performance;   
	    //������ҵ��
        uint nodePerformance;   
        Invest[] invests;
    	uint staticFlag;
	    //������ҵ��
    	uint hashratePerformance;
	    //BT�ڿ��ܽ���
        uint hisBtAward;   
	    //vipδ�ֺ콱��
        uint256 vipBonus;   
	    //vip�ۼƷֺ�
        uint256 vipTotalBonus;
	    //����
        uint checkpoint;    
    }
    
    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }
    
    struct Invest{
        uint investAmount;
        uint limitAmount;
        uint earnAmount;
    }
    
    struct BigRound {
        uint gameAmount;
    }
    
    //24h ȫ��ھ�
    struct GlobalChampion {
        address userAddress;
        uint performance;
    }
    
    uint startTime;
    uint endTime;
    uint investMoney;
    uint residueMoney;
    uint uid = 0;
    uint rid = 1;
    uint period = 12 hours;
    uint statisticsDay;
    uint statisticsTwoCount = 0;
    uint statisticsTwoDay;
    uint gameRate = 20000;
    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) indexMapping;
    
    //==============================================================================
    address payable destructionAddr = address(0xaC772670397Ab85D0d7A8C0E60acc4150a05088E);
    address payable coinPriceAddr = address(0x009e7a1a26A6DCcDC347F00B5Fac14241C66a783);
    address payable marketAddr = address(0x63b79A83ECafAE19D19517A8F88263f7511137d3);
    
    address uToken = address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);
    tokenTransfer u = tokenTransfer(uToken);
    
    GlobalChampion[] globalChampionArr;
    
    //��0 ��1 
    uint gameSwitch = 0;
    uint bigRid = 1;
    mapping (uint256 => BigRound) bigRound;
    
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
    event LogGameWinner(address indexed who, uint amount, uint time,string gameType);
    event UserLevel(address indexed user,uint256 p, uint256 level);
    event LogPullUpPrices(address user,uint256 amt);

    //==============================================================================
    // Constructor
    //==============================================================================
    constructor () public {
        startTime = now;
        endTime = startTime.add(period);
    }

    function () external payable {
    }
    
    //Ͷ��
    function investIn(string memory inviteCode,string memory referrer,uint256 value)
        public
        updateReward(msg.sender)
        checkStart 
        checkhalve 
        isHuman()
    {
        require(value >= 21*usdtWei, "The minimum bet is 21 USDT");
        require(value <= 210000*usdtWei, "The biggest bet is 210000 USDT");
        require(value == value.div(usdtWei).mul(usdtWei), "invalid msg value");
        
        u.transferFrom(msg.sender,address(this),value);
        
        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");

            registerUser(msg.sender, inviteCode, referrer);
        }
        
        //�Ƿ������û�
        User storage user = userRoundMapping[rid][msg.sender];
        if (user.id != 0) {
            user.allInvest = user.allInvest.add(value);
            user.freezeAmount = user.freezeAmount.add(value);
        } else {
            user.id = userGlobal.id;
            user.freezeAmount = value;
            user.allInvest = value;
            user.referrer = userGlobal.referrer;
        }
        
        //Ǯ���Ŵ�����
        Invest memory invest = Invest(value, value.mul(3), 0);
        user.invests.push(invest);
        
        investMoney = investMoney.add(value);
        statisticsDay = statisticsDay.add(value);
        
        //�û���̬�����Զ��ֺ�
        tjUserDynamicTree(userGlobal.referrer,value);
        
        //ͳ��ÿ������
        statisticOfDay();
        
        //ͳ��ֱ�ƹھ�ҵ��
        statisticOfChampion(getUserAddressByCode(referrer),value);
        
        //40%�ڿ�
        fixedDepositMining(value);
        
        //�ڿ�
        super.stake(value);
        emit LogInvestIn(msg.sender, userGlobal.id, value, now, userGlobal.inviteCode, userGlobal.referrer);
    }
    
    //ͳ���û��ڵ�
    function tjUserDynamicTree(string memory referrer, uint investAmount) private {
        string memory tmpReferrer = referrer;
        uint dynAmt = investAmount.mul(50).div(100);
        
        uint totalTmpAmount;
        for (uint i = 1; i <= 20; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            if (calUser.id == 0) {
                break;
            }
            
            //����ϼ��ѿյ���������
            if(calUser.freezeAmount <= 0){
                tmpReferrer = calUser.referrer;
                continue;
            }
            
            //ͳ��2���ڵ�������ҵ��
            if(i == 1 || i == 2){
                //ͳ��1��������ڵ�ҵ��
                if(i == 1){
                    calUser.performance = calUser.performance.add(investAmount);
                }
                calUser.nodePerformance = calUser.nodePerformance.add(investAmount);
            }
            
            //�����������
            uint recommendSc = getRecommendScaleByAmountAndTim(calUser.nodePerformance, i);
            if (recommendSc != 0) {
                
                //ͳ������������
                calUser.hashratePerformance = calUser.hashratePerformance.add(investAmount);
                
                //����
                uint tmpDynamicAmount = dynAmt.mul(recommendSc).div(100);
                
                Invest storage invest = calUser.invests[calUser.staticFlag];
                invest.earnAmount = invest.earnAmount.add(tmpDynamicAmount);
                //�����ж�
                if (invest.earnAmount >= invest.limitAmount) {
                    calUser.staticFlag = calUser.staticFlag.add(1);
                    calUser.freezeAmount = calUser.freezeAmount.sub(invest.investAmount);
                    
                    //��������
                    uint correction = invest.earnAmount.sub(invest.limitAmount);
                    if(correction > 0){
                        tmpDynamicAmount = tmpDynamicAmount.sub(correction);
                        invest.earnAmount = invest.limitAmount;
                    }
                }
                
                //�ۼ��û�����
                calUser.allDynamicAmount = calUser.allDynamicAmount.add(tmpDynamicAmount);
                calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(tmpDynamicAmount);
                totalTmpAmount = totalTmpAmount.add(tmpDynamicAmount);
            }
            
            tmpReferrer = calUser.referrer;
        }
        
        //������ʽ���䵽40%��ַ
        residueMoney = residueMoney.add(dynAmt.sub(totalTmpAmount));
    }
    
    //ͳ��ÿ������
    function statisticOfDay() private {
        if(getTimeLeft() != 0){
            return;
        }
        
        //update time
        startTime = endTime;
        endTime = startTime.add(period);
        
        //��Ϸ����
        if(gameSwitch == 1){
            //����10%
            uint awardAmount = bigRound[bigRid].gameAmount.mul(10).div(100);
            if(awardAmount > 1 * usdtWei){
                //Top5����
                (address[5] memory ads,,uint[5] memory awards) = pkRanking();
                uint topLen = ads.length;
                
                for(uint i = 0;i<topLen;i++){
                    uint a = awards[i];
                    if(a > 0){
                       //���а���
                       uint topAwar = awardAmount.mul(a).div(100);
                       winnerAward(ads[i],topAwar,"King");
                    }
                }
                
                //���½�������
                bigRound[bigRid].gameAmount = bigRound[bigRid].gameAmount.sub(awardAmount);
            }
            
            //���ֱ�ƹھ�����
            globalChampionArr.length = 0;
            
            //48Сʱ����
            statisticsTwoDay = statisticsTwoDay.add(statisticsDay);
            statisticsTwoCount = statisticsTwoCount.add(1);
            
            if(statisticsTwoCount >= 2){
                //����½��ʽ��Ƿ����10��U
                if(statisticsTwoDay <= gameRate * usdtWei){
                    pullUpPrices();
                }
                statisticsTwoDay = 0;
                statisticsTwoCount = 0;
            }
            statisticsDay = 0;
        }
        
        //����ֺ�
        settlementBonus();
    }
    
    //ֱ�ƹھ�ͳ��
    function statisticOfChampion(address _sender,uint _value) private {
        //pk 10%
        bigRound[bigRid].gameAmount = bigRound[bigRid].gameAmount.add(_value.mul(10).div(100));
        
        if(uint(_sender) == 0){
            return;
        }
        
        if(gameSwitch == 1){
            uint addrIndex = getChampionIndex(globalChampionArr,_sender);
            if(addrIndex == 1000000){
                GlobalChampion memory cg = GlobalChampion(_sender,_value);
                globalChampionArr.push(cg);
            } else {
                GlobalChampion storage cg = globalChampionArr[addrIndex];
                cg.performance = cg.performance.add(_value);
            }        
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
    
    function pkRanking() public view returns (address[5] memory ads,uint[5] memory cts,uint[5] memory awards) 
    {
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
    
    //����USDT
    function withdrawProfit() updateReward(msg.sender) checkhalve checkIncreaseCoin public
    {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        
        statisticOfDay();
        
        uint resultMoney = user.allDynamicAmount;
        if (resultMoney > 0) {
            //��U
            takeInner(msg.sender,resultMoney);
            user.allDynamicAmount = 0;
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }
        
        //������
        upDynamicLevel();
    }
    
    //�����Ҽ�
    function pullUpPrices() private {
        uint destructionAmountAmount = bigRound[bigRid].gameAmount.mul(10).div(100);
        if(destructionAmountAmount > 1 * usdtWei){
            //תU
            takeInner(coinPriceAddr,destructionAmountAmount);
            //���½�������
            bigRound[bigRid].gameAmount = bigRound[bigRid].gameAmount.sub(destructionAmountAmount);
            emit LogPullUpPrices(coinPriceAddr,destructionAmountAmount);
        }
    }
    
    //�г�����
    function marketIncentives() public {
        uint resultMoney = residueMoney;
        //תU
        takeInner(marketAddr,resultMoney);
        //���ʣ���ʽ�
        residueMoney = 0;
        emit LogPullUpPrices(marketAddr,resultMoney);
    }
    
    //�ڿ�
    function fixedDepositMining(uint256 money) private {
        uint miningAmount = money.mul(40).div(100);
        //תU
        takeInner(destructionAddr,miningAmount);
    }
    
    //�����û��ȼ�
    function upDynamicLevel() private
    {
        User storage calUser = userRoundMapping[rid][msg.sender];
        
        uint dynamicLevel = calUser.dynamicLevel;
        uint newDynLevel = getDynLevel(calUser.performance,calUser.hashratePerformance);
        if(newDynLevel != 0 && dynamicLevel != newDynLevel){
            
            //update checkpoint            
            if(calUser.checkpoint == 0){
               calUser.checkpoint = shareBonusCount; 
            }
            
             //��ȡ�ֺ�
            useStatisticalBonusInner();
            
            //up level
            calUser.dynamicLevel = newDynLevel;
                
            //�Ƴ�ԭ��&�����û�
            doRemoveVip(calUser.id,dynamicLevel);
            doAddVip(calUser.id,newDynLevel);
            emit UserLevel(msg.sender,calUser.hashratePerformance,newDynLevel);
        }
    }
    
    //�����
    function isEnoughBalance(uint sendMoney) private returns (bool, uint){
        uint _balance = u.balanceOf(address(this));
        if (sendMoney >=  _balance) {
            return (false, _balance);
        } else {
            return (true, sendMoney);
        }
    }
    
    //ȡǮ
    function takeInner(address payable userAddress, uint money) private {
        uint sendMoney;
        (, sendMoney) = isEnoughBalance(money);
        if (sendMoney > 0) {
            u.transfer(userAddress,sendMoney);
        }
    }
    
    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }
    
    function getMiningInfo(address _user) public view returns(uint[44] memory ct,string memory inviteCode, string memory referrer) {
        User memory userInfo = userRoundMapping[rid][_user];
        
        uint256 earned = earned(_user);
        
        ct[0] = totalSupply();
        ct[1] = turnover;
        ct[2] = userInfo.hashratePerformance;
        ct[3] = userInfo.hisBtAward;
        ct[4] = userInfo.dynamicLevel;
        ct[5] = earned;
        ct[6] = status;
        ct[7] = bonusPool;
        
        ct[8] = vipTodayBonus[0];
        ct[9] = vipTodayBonus[1];
        ct[10] = vipTodayBonus[2];
        ct[11] = vipTodayBonus[3];
        
        ct[12] = vipHisBonus[0];
        ct[13] = vipHisBonus[1];
        ct[14] = vipHisBonus[2];
        ct[15] = vipHisBonus[3];
        
        ct[16] = vipLength[0];
        ct[17] = vipLength[1];
        ct[18] = vipLength[2];
        ct[19] = vipLength[3];
        
        ct[20] = unWithdrawBonus(_user);
        ct[21] = basicCoin;
        ct[22] = increaseNumber;
        
        ct[23] = userInfo.vipBonus;
        ct[24] = userInfo.vipTotalBonus;
        ct[25] = userInfo.checkpoint;
        
        //Game INFO
        ct[26] = endTime;
        ct[27] = getTimeLeft();
        ct[28] = investMoney;
        ct[29] = residueMoney;
        ct[30] = gameSwitch;
        
        //USER INFO
        ct[31] = userInfo.dynamicLevel;
        ct[32] = userInfo.allInvest;
        ct[33] = userInfo.freezeAmount;
        ct[34] = userInfo.allDynamicAmount;
        ct[35] = userInfo.hisDynamicAmount;
        ct[36] = userInfo.staticFlag;
        ct[37] = userInfo.invests.length;
        ct[38] = userInfo.performance;
        ct[39] = userInfo.hisGameAmount;
        ct[40] = userInfo.nodePerformance;
        
        ct[41] = periodFinish;
    	ct[42] = bigRid;
    	ct[43] = bigRound[bigRid].gameAmount;
        
        inviteCode = userMapping[_user].inviteCode;
        referrer = userMapping[_user].referrer;
        
        return (
            ct,
            inviteCode,
            referrer
        );
    }
    
    function getUserAssetInfo(address user, uint i) public view returns(
        uint[5] memory ct
    ) {
        User memory userInfo = userRoundMapping[rid][user];
        ct[0] = userInfo.invests.length;
        if (ct[0] != 0) {
            ct[1] = userInfo.invests[i].investAmount;
            ct[2] = userInfo.invests[i].limitAmount;
            ct[3] = userInfo.invests[i].earnAmount;
            ct[4] = 0;
        } else {
            ct[1] = 0;
            ct[2] = 0;
            ct[3] = 0;
            ct[4] = 0;
        }
    }
    
    function activeGame(uint time) external onlyWhitelistAdmin
    {
        require(time > now, "invalid game start time");
        startTime = time;
        endTime = startTime.add(period);
    }
    
    function correctionStatistics() external onlyWhitelistAdmin
    {
        statisticOfDay();
    }
    
    function changeGameSwitch(uint _gameSwitch) external onlyWhitelistAdmin
    {
        gameSwitch = _gameSwitch;
    }
    
    function changeGameRate(uint _gameRate) external onlyWhitelistAdmin
    {
        gameRate = _gameRate;
    }
    
    function clearChampion() external onlyWhitelistAdmin
    {
        //���ֱ�ƹھ�����
        globalChampionArr.length = 0;
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

    //��ϷӮ�ҽ���
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
    
    //------------------------------�ڿ��߼�
    uint256 turnover;
    uint256 bonusPool;
    address btTokenAddr = address(0x89803bED482520Df00Eb634c6477dA20E3Bf6E61);
    tokenTransfer btToken = tokenTransfer(btTokenAddr);
    
    //Ϊ0����ͷ��Ϊ1��������
    uint256 status = 0;  
    //utc+8 2021-03-12 19:41:05
    uint256 public starttime = 1615549265; 
    //�ڿ����ʱ��
    uint256 public periodFinish = 0;    
    //��������
    uint256 public rewardRate = 0;  
    //������ʱ��
    uint256 public lastUpdateTime;
    //ÿ���洢�����ƽ���
    uint256 public rewardPerTokenStored;    
    //ÿ֧��һ�����ҵ��û�����
    mapping(address => uint256) public userRewardPerTokenPaid;  
    //�û�����
    mapping(address => uint256) public rewards; 
    
    //---------------------------------global vip
    struct Bonus {
        uint256 vip1AvgBonus;
        uint256 vip2AvgBonus;
        uint256 vip3AvgBonus;
        uint256 vip4AvgBonus;
    }
    
    //�ֺ����
    uint256 public shareBonusCount = 1;
    //�����
    mapping (uint => Bonus) public gifts;
    
    //uid -> 1
    mapping (uint => uint) vip1s;
    mapping (uint => uint) vip2s;
    mapping (uint => uint) vip3s;
    mapping (uint => uint) vip4s;
    
    //��̬�������
    uint256[] bonusRate = [18,10,7,5];
    //vip���ս���
    uint256[] public vipTodayBonus = [0,0,0,0];
    //vip��ʷ����
    uint256[] public vipHisBonus = [0,0,0,0];
    //vip����
    uint256[] public vipLength = [0,0,0,0];
    
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return SafeMath.min(block.timestamp, periodFinish);
    }
    
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }
    
    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }
    
    //��ȡBT
    function getReward() public updateReward(msg.sender) checkhalve checkIncreaseCoin {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        
        statisticOfDay();
        
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            uint staticReward = reward.mul(60).div(100);
            
            //�ۼ��û���̬�ڿ�����
            user.hisBtAward = user.hisBtAward.add(staticReward);
            
            //��ͨ��
            turnover = turnover.add(staticReward);
            
            rewards[msg.sender] = 0;
            btToken.transfer(msg.sender, staticReward);
            emit RewardPaid(msg.sender, staticReward);
            
            //vip�����
            uint dynReward = reward.mul(40).div(100);
            bonusPool = bonusPool.add(dynReward);
            
            //��̬�ֺ��ۼ�
            for(uint i = 0;i<bonusRate.length;i++){
                uint amt = reward.mul(bonusRate[i]).div(100);
                vipTodayBonus[i] = vipTodayBonus[i].add(amt);
                vipHisBonus[i] = vipHisBonus[i].add(amt);
            }
        }
        
        //������
        upDynamicLevel();
    }
    
    //����24Сʱ�ֺ콱��
    function settlementBonus() private {
        //�����ܽ��� / vip���� = ƽ���ֺ콱��
        for(uint i = 0;i<vipTodayBonus.length;i++){
            uint todayBonus = vipTodayBonus[i];
            if(todayBonus == 0){
                break;
            }
            
            uint length = vipLength[i];
            if(length == 0){
                length = 1;
            }
            
            uint256 avgBonus = todayBonus.div(length);
            if(i == 0){
                gifts[shareBonusCount].vip1AvgBonus = avgBonus;
            }else if(i == 1){
                gifts[shareBonusCount].vip2AvgBonus = avgBonus;
            }else if(i == 2){
                gifts[shareBonusCount].vip3AvgBonus = avgBonus;
            }else if(i == 3){
                gifts[shareBonusCount].vip4AvgBonus = avgBonus;
            }
            
            //�������ս���
            vipTodayBonus[i] = 0;
        }
        shareBonusCount++;
    }
    
    //��ȡ�ֺ�
    function useStatisticalBonusInner() private {
        User storage user = userRoundMapping[rid][msg.sender];
        uint totalAmt = unWithdrawBonus(msg.sender);
        if(totalAmt > 0){
            user.vipBonus = user.vipBonus.add(totalAmt);
            user.vipTotalBonus = user.vipTotalBonus.add(totalAmt);
        }
        //must update checkpoint
        user.checkpoint = shareBonusCount;
    }
    
    //δ��ȡ�ֺ�
    function unWithdrawBonus(address _add) public view returns(uint) {
        User storage user = userRoundMapping[rid][_add];
        if(user.id == 0){
            return 0;
        }
        
        uint level = user.dynamicLevel;
        uint checkpoint = user.checkpoint;
        
        uint totalAmt = 0;
        for(uint i = checkpoint;i<shareBonusCount;i++){
            if(level == 1){
                totalAmt = totalAmt.add(gifts[i].vip1AvgBonus);
            }else if(level == 2){
                totalAmt = totalAmt.add(gifts[i].vip2AvgBonus);
            }else if(level == 3){
                totalAmt = totalAmt.add(gifts[i].vip3AvgBonus);
            }else if(level == 4){
                totalAmt = totalAmt.add(gifts[i].vip4AvgBonus);
            }
        }
        return totalAmt;
    }
        
    //��ȡ�ֺ콱��
    function getBonus() public updateReward(msg.sender) checkhalve checkIncreaseCoin {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        
        statisticOfDay();
        useStatisticalBonusInner();
        
        if(user.vipBonus > 0){
            uint dynReward = user.vipBonus;
            
            //�ۼ��û���̬�ڿ�����
            user.hisBtAward = user.hisBtAward.add(dynReward);
            //��ͨ��
            turnover = turnover.add(dynReward);
            
            btToken.transfer(msg.sender, dynReward);
            user.vipBonus = 0;
            emit RewardPaid(msg.sender, dynReward);
        }
        
        //������
        upDynamicLevel();
    }
    
    modifier checkhalve(){
        if(status == 0){
            if (block.timestamp >= periodFinish) {
                changeNotifyRewardAmount();
	        }
        }
        _;
    }
    
    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }
    
    modifier checkIncreaseCoin(){
        increaseCoin(investMoney);
        _;
    }
    
    function notifyRewardAmount()
        external
        onlyWhitelistAdmin
        updateReward(address(0))
    {
        uint256 reward = 10000 * 1e18;
        uint256 INIT_DURATION = 10 days;
        
        rewardRate = reward.div(INIT_DURATION);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(INIT_DURATION);
        emit RewardAdded(reward);
    }
    
    function changeNotifyRewardAmount() private {
        status = 1;
        
        uint256 reward = 200000 * 1e18;
        uint256 DURATION = 400 days;
        
        rewardRate = reward.div(DURATION);
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
    
    //ÿ�ղ�����
    uint public basicCoin = 500 * 1e18;
    //��������
    uint public increaseNumber = 0;  
    //��������
    uint increaseUnits = 50 * 1e18;  
    //��������,usdt
    uint public increaseCondition = 500000 * usdtWei; 
    
    event LogIncreaseCoin(uint256 _newBasicCoin,uint256 _btBalance,uint _rewardRate,uint256 _periodFinish);
    
    //���Ӳ���
    function increaseCoin(uint256 total) public {
        //��ͷ�������������������
        if(status == 0 || total < increaseCondition){
            return;
        }
        
        //������
        uint increaseGaps = total.div(increaseCondition);
         if(increaseGaps > increaseNumber){
            //last balance
            uint balance = btToken.balanceOf(address(this));
            if(balance > basicCoin){
                uint difference = increaseGaps.sub(increaseNumber);
                basicCoin = basicCoin.add(difference.mul(increaseUnits));
                increaseNumber = increaseGaps;
                
                //�������¼�������
                uint newDuration = balance.div(basicCoin).mul(1 days);
        
                rewardRate = balance.div(newDuration);
                periodFinish = block.timestamp.add(newDuration);
                emit LogIncreaseCoin(basicCoin,balance,rewardRate,periodFinish);
            }
        }
    }
    
    //���Ӻϻ���
    function doAddVip(uint _uid,uint _level) private
    {
        uint8 flag = 1;
        if(_level == 1){
            vip1s[_uid] = flag;
        }else if(_level == 2){
            vip2s[_uid] = flag;
        }else if(_level == 3){
            vip3s[_uid] = flag;
        }else if(_level == 4){
            vip4s[_uid] = flag;
        }
        
        uint _index = _level - 1;
        vipLength[_index] = vipLength[_index].add(1);
    }
    
    //�Ƴ��ϻ���
    function doRemoveVip(uint _uid,uint _level) private
    {
        if(doContainsVip(_uid,_level)){
            uint8 flag = 0;
            if(_level == 1){
                vip1s[_uid] = flag;
            }else if(_level == 2){
                vip2s[_uid] = flag;
            }else if(_level == 3){
                vip3s[_uid] = flag;
            }else if(_level == 4){
                vip4s[_uid] = flag;
            }
            
            uint _index = _level - 1;
            vipLength[_index] = vipLength[_index].sub(1);
        }
    }
    
    //�����ϻ���
    function doContainsVip(uint _uid,uint _level) public view returns (bool)
    {
        uint8 flag = 1;
        if(_level == 1){
            return vip1s[_uid] == flag;
        }else if(_level == 2){
            return vip2s[_uid] == flag;
        }else if(_level == 3){
            return vip3s[_uid] == flag;
        }else if(_level == 4){
            return vip4s[_uid] == flag;
        }
        return false;
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

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