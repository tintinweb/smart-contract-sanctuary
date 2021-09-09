/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;


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


contract BscEcology {

    using SafeMath for uint256;
    using SafeMath for uint8;
    // 最小投资数量
	uint256 constant public INVEST_MIN_AMOUNT = 0.1 ether;
    // 最小提现数量
	uint256 constant public WITHDRAWN_MIN_AMOUNT = 0.001 ether;
	// 项目方收手续费比例 提现的时候扣除掉
    uint256 constant public PROJECT_FEE = 10; // 10%;
	// 百分比底数
    uint256 constant public PERCENTS_DIVIDER = 100;
	// 没有用 
    uint256 constant public TIME_STEP =  1 days; // 1 days
    // 用户总数
    uint256 public totalUsers;
	// 总投资额
    uint256 public totalInvested;
    // 总提现额
    uint256 public totalWithdrawn;
	// 总投资次数
    uint256 public totalDeposits;
	
    uint[10] public ref_bonuses = [20, 10, 2, 2, 6, 2, 2, 2, 2, 2];
    // 套餐选择
    uint256[7] public defaultPackages = [ 0.1 ether, 0.2 ether, 0.4 ether, 0.6 ether, 1 ether, 4 ether, 10 ether];
    
    // 管理员收手续费地址
    address payable public admin;
    // 一条线存储表 按照入单顺序排
    mapping(uint256 => address payable) public singleLeg;
    // 参与总人数 第一次参与时刻累加
    uint256 public singleLegLength;
    // 用户结构
    struct User {
        // 投资总额
        uint256 amount;
        // 注册投资额
        uint256 firstAmount;
        // 复投
        uint256 reinvestAmount;
		// 用户第一次投资时间
        uint256 firstpoint; 
		// 用户最近投资时间
        uint256 checkpoint; 
        // 推荐人
        address referrer;
        // 推荐奖励累加值
        uint256 referrerBonus;
        
		// 
        uint256 totalWithdrawn;
		// 
        // uint256 remainingWithdrawn;
		// 
        uint256 totalReferrer;
        uint256 totalFirstReferrer;
		// 
        // uint256 singleUplineBonusTaken;
		// 
        // uint256 singleDownlineBonusTaken;
		// 用于方便的找到前一个人
        address singleUpline; 
		// 用户方便的找到后一个人
        address singleDownline; 
		// 记录伞下 对应层入金总数量 叫levelTotalInvest 更合适
        uint256[10] refStageIncome;
		// 记录伞下 对应层投资次数 叫leveInvestCount 更合适
        uint[10] refs;
        
        // 上社区提现复投奖励
        uint256 uplineBonus;
        // 下社区提现复投奖励
        uint256 downlineBonus;
	}
	// 所有用户
	mapping(address => User) public users;
	// 下层
    mapping(address => mapping(uint256=>address)) public downline;
    // 充值事件
	event NewDeposit(address indexed user, uint256 amount);
	// 提现事件
    event Withdrawn(address indexed user, uint256 amount);
    // 没有用
    event FeePayed(address indexed user, uint256 totalAmount);
	
    // 构造函数
    constructor(address payable _admin) public {
		require(!isContract(_admin));
		admin = _admin;
		
		singleLeg[0]=admin;
		singleLegLength++;
	}

    // 推荐人逐级别返佣
    function _refPayout(address _addr, uint256 _amount) internal {
		address up = users[_addr].referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            // need to be change here after discussion
            // 
            if(i >= 4){
                if(users[up].totalFirstReferrer>=5 && users[up].amount >= 1 ether){
        		    uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                    users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                }
            } else {
    		    uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                users[up].referrerBonus = users[up].referrerBonus.add(bonus);
            }
            up = users[up].referrer;
        }
    }
    
    // 上社区奖励
    function _uplinePayout(address _addr, uint256 _amount) internal {
        uint256 totalAmount;
		address upline = users[_addr].singleUpline;
		address temp = users[_addr].singleUpline;

        for(uint8 i = 0; i < 30; i++) {
            if(upline == address(0)) break;
            totalAmount = totalAmount.add(users[upline].amount);
            upline = users[upline].singleUpline;
        }
        if (totalAmount == 0) {
            return;
        }
        upline = temp;
        for(uint8 i = 0; i < 30; i++) {
            if(upline == address(0)) break;
            uint256 bonus = _amount.mul(users[upline].amount).div(totalAmount);
            users[upline].downlineBonus = users[upline].downlineBonus.add(bonus);
            upline = users[upline].singleUpline;
        }
    }
    
    // 下社区奖励
    function _downlinePayout(address _addr, uint256 _amount) internal {
        uint256 totalAmount;
		address upline = users[_addr].singleDownline;
		address temp = users[_addr].singleDownline;

        for(uint8 i = 0; i < 20; i++) {
            if(upline == address(0)) break;
            totalAmount = totalAmount.add(users[upline].amount);
            upline = users[upline].singleDownline;
        }
        if (totalAmount == 0) {
            return;
        }
        upline = temp;
        for(uint8 i = 0; i < 20; i++) {
            if(upline == address(0)) break;
            uint256 bonus = _amount.mul(users[upline].amount).div(totalAmount);
            users[upline].uplineBonus = users[upline].uplineBonus.add(bonus);
            upline = users[upline].singleDownline;
        }
    }

    // 投资接口
    function invest(address referrer) public payable {		
		require(msg.value >= INVEST_MIN_AMOUNT, 'Min invesment 0.1 BNB');
	
		User storage user = users[msg.sender];

        // 第一次投资时进行绑定推荐人
		if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }
        // 判断绑定是否绑定成功
		require(user.referrer != address(0) || msg.sender == admin, "No upline");
		
		// setup upline 设置一条线
		if (user.checkpoint == 0) {
		   // single leg setup
		   singleLeg[singleLegLength] = msg.sender;
		   user.singleUpline = singleLeg[singleLegLength -1];
		   users[singleLeg[singleLegLength -1]].singleDownline = msg.sender;
		   singleLegLength++;
		}
		// 当用户不是管理员的时候
		if (user.referrer != address(0)) {   
            // unilevel level count
            address upline = user.referrer;
            //累加推荐人直推人数
            if (user.checkpoint == 0) {
                users[upline].totalFirstReferrer++;
            }
            // 往上再找10层
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    // 累加这个距离层级的入金数量
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(msg.value);
                    if (user.checkpoint == 0) {
                        // 累加这个距离层级的 入金次数
                        users[upline].refs[i] = users[upline].refs[i].add(1);
    					// 累加这个推荐人的 总推荐数量
                        users[upline].totalReferrer++;
                    }

                    upline = users[upline].referrer;
                } else break;
            }
            // 记录用户的直推下级，按照先后顺序来排列
			downline[referrer][users[referrer].refs[0] - 1]= msg.sender;
        }
	
		uint msgValue = msg.value.div(2);

		// 推荐奖金返佣 10层
        _refPayout(msg.sender, msgValue);
        
        // 新用户则记录用户总数+1
        if(user.checkpoint == 0) {
            totalUsers = totalUsers.add(1);
            user.firstAmount = msg.value;
        } else {
            user.reinvestAmount = user.reinvestAmount.add(msg.value);
            DownlineIncomeByUserId(msg.sender, msg.value);
        }
        // 用户投资额累加
        user.amount = user.amount.add(msg.value);
        // 用户第一次投资时间
        if (user.firstpoint == 0) {
            user.firstpoint = block.timestamp;
        }
        // 用户最近投资时间记录
        user.checkpoint = block.timestamp;
        // 总投资额累加
        totalInvested = totalInvested.add(msg.value);
        // 总充值次数+1
        totalDeposits = totalDeposits.add(1);
        
        emit NewDeposit(msg.sender, msg.value);
	}
	
    // 复投
    function reinvest(address _user, uint256 _amount) private{
        
        User storage user = users[_user];
        // 用户投资金额累加
        user.amount = user.amount.add(_amount);
        // 总投资额累加
        totalInvested = totalInvested.add(_amount);
        // 总充值次数+1
        totalDeposits = totalDeposits.add(1);
        // 推荐奖金分配
        _refPayout(msg.sender, _amount.div(2));
        // 上社区奖金分配
        _uplinePayout(msg.sender, _amount.mul(30).div(100));
        // 下社区奖金分配
        _downlinePayout(msg.sender, _amount.mul(20).div(100));
    }

    // 提现
    function withdrawal(uint256 _amount) external{
        User storage _user = users[msg.sender];
        
        // 可提现奖金
        uint256 balance = TotalAvailable();
        
    	require(_amount >= WITHDRAWN_MIN_AMOUNT, 'Min withdrawn 1');
    	require(balance >= _amount, 'TotalAvailable not enough');
    	
    	uint256 _fees = _amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
    	uint256 actualAmountToSend = _amount.sub(_fees);
        
        // 计算总提现
        _user.totalWithdrawn = _user.totalWithdrawn.add(_amount);
        
        totalWithdrawn = totalWithdrawn.add(_amount);
        
        // re-invest
        // 计算复投 提现比例
        (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
        reinvest(msg.sender, actualAmountToSend.mul(reivest).div(100));

        // 发送对应的奖金
        _safeTransfer(msg.sender, actualAmountToSend.mul(withdrwal).div(100));
        
        _safeTransfer(admin, _fees);
        emit Withdrawn(msg.sender, actualAmountToSend.mul(withdrwal).div(100));
    }
    
    // 复投分给下线的收益
    function DownlineIncomeByUserId(address _user, uint256 _amount) internal {
        address upline = users[_user].singleDownline;
        uint256 bonus;
        for (uint i = 0; i < 20; i++) {
            if (upline != address(0)) {
                bonus = _amount.mul(1).div(100);
                users[upline].uplineBonus = users[upline].uplineBonus.add(bonus);
                upline = users[upline].singleDownline;
            }else break;
        }
    }

    // 获取从上线的收益
    function GetUplineIncomeByUserId(address _user) public view returns(uint256){
        // address upline = users[_user].singleUpline;
        // uint256 bonus;
        // for (uint i = 0; i < 20; i++) {
        //     if (upline != address(0)) {
        //         bonus = bonus.add(users[upline].reinvestAmount.mul(1).div(100));
        //         upline = users[upline].singleUpline;
        //     }else break;
        // }
        
        // return users[_user].uplineBonus.add(bonus);
        return users[_user].uplineBonus;
    }
    // 获取从下线的收益
    function GetDownlineIncomeByUserId(address _user) public view returns(uint256){
        address upline = users[_user].singleDownline;
        uint256 bonus;
        for (uint i = 0; i < 30; i++) {
            if (upline != address(0)) {
                bonus = bonus.add(users[upline].firstAmount.mul(1).div(100));
                bonus = bonus.add(users[upline].reinvestAmount.mul(1).div(100));
                upline = users[upline].singleDownline;
            }else break;
        }
        
        return users[_user].downlineBonus.add(bonus);
    }
  
    // 根据伞下投资情况 确定 比例
    function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){ 
        uint256 TotalDeposit = users[_user].amount;
        if(users[_user].totalFirstReferrer >= 10 && TotalDeposit >=10 ether){
            reivest = 30;
            withdrwal = 70;
        }else if(users[_user].totalFirstReferrer >=8 && TotalDeposit >=4 ether){
            reivest = 40;
            withdrwal = 60;
        }else if(users[_user].totalFirstReferrer >=5 && TotalDeposit >=1 ether){
            reivest = 50;
            withdrwal = 50;
        }else{
            reivest = 60;
            withdrwal = 40;
        }
        
        return(reivest,withdrwal);
    }
    
    // 获取总数量
    function TotalBonus(address _user) public view returns(uint256){
        return users[_user].referrerBonus.add(GetUplineIncomeByUserId(_user)).add(GetDownlineIncomeByUserId(_user));
    }
    
    // 获取可用余额
    function TotalAvailable() public view returns(uint256){
        User storage _user = users[msg.sender];
        
         // 计算总奖金
        uint256 bonus = TotalBonus(msg.sender);
        
        uint256 balance = bonus.sub(_user.totalWithdrawn);
        
        return balance;
    }

    function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
        _to.transfer(amount);
    }
   
    function referral_stage(address _user,uint _index) external view returns(uint _noOfUser, uint256 _investment){
        return (users[_user].refs[_index], users[_user].refStageIncome[_index]);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function _onlyemergency(uint256 _amount) external{
        require(admin==msg.sender, 'Admin what?');
        _safeTransfer(admin,_amount);
    }
    
    
    function _changeAdmin(address payable _admin) external{
        require(admin==msg.sender, 'Admin what?');
        admin = _admin;
    }
}