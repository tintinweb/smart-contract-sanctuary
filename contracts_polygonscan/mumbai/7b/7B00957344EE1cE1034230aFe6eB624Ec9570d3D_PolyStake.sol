/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

pragma solidity =0.7.0;

contract PolyStake {
	
    using SafeMath for uint256;

    uint256 public LAUNCH_TIME;
    uint256[] public REFERRAL_PERCENTS = [50, 30, 10, 5, 5];
    uint256 public constant INVEST_MIN_AMOUNT = 5e18; //5e18
    uint256 public constant PERCENT_STEP = 5; // 0.5 Increase
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days; //1 days
    uint256 public MINIMUM_TIME = 5;
    uint256 public constant DECREASE_DAY_STEP = 0.5 days;//0.5 days decrease
    uint256 public constant PENALTY_STEP = 300;
    uint256 public constant MARKETING_FEE = 50;
    uint256 public constant PROJECT_FEE = 50;

    uint256 public totalStaked;
    uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 pre_percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
        bool force;
    }

    struct User {
        Deposit[] deposits;
        bool preregister;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 totalBonus;
    }

    mapping(address => User) internal users;
    mapping(address => Deposit[]) internal penaltyDeposits;

    address payable public marketingAddress;
    address payable public projectAddress;

    event Newbie(address user, address referrer);
    event NewDeposit(
        address indexed user,
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    );
    event Withdrawn(address indexed user, uint256 amount);
    event ForceWithdrawn(
        address indexed user,
        uint256 amount,
        uint256 penaltyAmount,
        uint256 penaltyID
    );
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event LostRefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
	 event test(
        uint256 amount1,
        uint256 amount2
    );
    
    modifier beforeStarted() {
        require(block.timestamp >= LAUNCH_TIME, "Not Started");
        _;
    }
    
    modifier preRegister() {
        require(block.timestamp < LAUNCH_TIME, "Launched");
        _;
    }

    constructor(address payable marketingAddr, address payable projectAddr)
        public
    {
        require(!isContract(marketingAddr), "Mkr Contract");
        require(!isContract(projectAddr), "Pjr Contract");

        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        
		LAUNCH_TIME = 1626209100;
        
        plans.push(Plan(14, 80, 90));
        plans.push(Plan(21, 65, 75));
        plans.push(Plan(28, 55, 65));
        plans.push(Plan(14, 110, 120));
        plans.push(Plan(21, 95, 105));
        plans.push(Plan(28, 80, 90));
    }
	
    function earlyBirdDeposit(address referrer, uint8 plan)
        public
        payable
        preRegister()
    {
		
        uint256 _amount		=	msg.value;
        
		require(plan < 6, "Invalid plan");
        User storage user = users[msg.sender];
        
        require(user.deposits.length <= 100, "Max Invest");
        
        if (user.referrer == address(0)) {
            if (referrer != msg.sender) {
                user.referrer = referrer;
            }
        }
		
        if (user.checkpoint < 1) {
            user.checkpoint = block.timestamp;
			user.preregister = true;
            emit Newbie(msg.sender, user.referrer);
        }
         emit test(_amount, INVEST_MIN_AMOUNT);
		if(_amount >= INVEST_MIN_AMOUNT){
		  
			marketingAddress.transfer(
				_amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER)
			);
			projectAddress.transfer(
				_amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER)
			);
			if (user.referrer != address(0)) {
				address upline = user.referrer;
				for (uint256 i = 0; i < 5; i++) {
					if (upline != address(0)) {
						 uint256 amount =
								_amount.mul(REFERRAL_PERCENTS[i]).div(
									PERCENTS_DIVIDER
								);
						if(users[upline].deposits.length > 0){
						   
							users[upline].bonus = users[upline].bonus.add(amount);
							users[upline].totalBonus = users[upline].totalBonus.add(
								amount
							);
							emit RefBonus(upline, msg.sender, i, amount);
						}else{
							emit LostRefBonus(upline, msg.sender, i, amount);
						}
						upline = users[upline].referrer;
					} else break;
				}
			}

			(uint256 percent, uint256 profit, , uint256 finish) =
				getResult(plan, msg.value);
			user.deposits.push(
				Deposit(
					plan,
					percent,
					_amount,
					profit,
					LAUNCH_TIME,
					finish,
					true
				)
			);

			totalStaked = totalStaked.add(_amount);
			emit NewDeposit(
				msg.sender,
				plan,
				percent,
				_amount,
				profit,
				LAUNCH_TIME,
				finish
			);
		}
    }
	
	
    function invest(address referrer, uint8 plan)
        public
        payable
        beforeStarted()
    {
	    uint256 _amount		=	msg.value;
        require(plan < 6, "Invalid plan");
		
		require(_amount >= INVEST_MIN_AMOUNT, "Min Value");
       

        marketingAddress.transfer(
            _amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER)
        );
        projectAddress.transfer(
            _amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER)
        );
		
        User storage user = users[msg.sender];
        
        require(user.deposits.length <= 100, "Max Invest");
        
        if (user.referrer == address(0)) {
            if (referrer != msg.sender) {
                user.referrer = referrer;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                     uint256 amount =
                            _amount.mul(REFERRAL_PERCENTS[i]).div(
                                PERCENTS_DIVIDER
                            );
                    if(users[upline].deposits.length > 0){
                       
                        users[upline].bonus = users[upline].bonus.add(amount);
                        users[upline].totalBonus = users[upline].totalBonus.add(
                            amount
                        );
                        emit RefBonus(upline, msg.sender, i, amount);
                    }else{
                        emit LostRefBonus(upline, msg.sender, i, amount);
                    }
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
			if(user.preregister != true){
				user.preregister = false;
			}
            emit Newbie(msg.sender, user.referrer);
        }

        (uint256 percent, uint256 profit, , uint256 finish) =
            getResult(plan, msg.value);
        user.deposits.push(
            Deposit(
                plan,
                percent,
                _amount,
                profit,
                block.timestamp,
                finish,
                true
            )
        );

        totalStaked = totalStaked.add(_amount);
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            _amount,
            profit,
            block.timestamp,
            finish
        );
    }

    function withdraw() public beforeStarted() {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        for (uint256 i = 0; i < user.deposits.length; i++) {            
			if (user.deposits[i].plan < 3) {
				user.deposits[i].force = false;
			} else if (block.timestamp > user.deposits[i].finish) {
				user.deposits[i].force = false;
			}
        }		
		msg.sender.transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
    }

    function forceWithdraw(uint256 index) public beforeStarted() {
        User storage user = users[msg.sender];

        require(index < user.deposits.length, "Invalid index");
        require(user.deposits[index].force == true, "Force is false");

        uint256 depositAmount = user.deposits[index].amount;
        uint256 penaltyAmount =
            depositAmount.mul(PENALTY_STEP).div(PERCENTS_DIVIDER);
        
        uint256 totalAmount = depositAmount.sub(penaltyAmount);
        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
            penaltyAmount = 0;
        }
        msg.sender.transfer(totalAmount);

        penaltyDeposits[msg.sender].push(user.deposits[index]);

        user.deposits[index] = user.deposits[user.deposits.length - 1];
        user.deposits.pop();

        emit ForceWithdrawn(
            msg.sender,
            depositAmount,
            penaltyAmount,
            penaltyDeposits[msg.sender].length
        );
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPercent(uint8 plan) public view returns (uint256) {
		
		User storage user = users[msg.sender];
		uint256	planpercent 	=	0;	
		if(user.preregister==true){
			planpercent	=	plans[plan].pre_percent;
		}else{
			planpercent	=	plans[plan].percent;
		}
		
        if (block.timestamp > LAUNCH_TIME) {
            return
                planpercent.add(
                    PERCENT_STEP.mul(block.timestamp.sub(LAUNCH_TIME)).div(
                        TIME_STEP
                    )
                ); 
        } else {
            return planpercent;
        }
    }

    function getResult(uint8 plan, uint256 deposit)
        public
        view
        returns (
            uint256 percent,
            uint256 profit,
            uint256 current,
            uint256 finish
        )
    {
        percent = getPercent(plan);
        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(
                plans[plan].time
            );
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add(
                    (deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER)
                );
            }
        }

        current = block.timestamp;
        finish = current.add(getDecreaseDays(plans[plan].time));
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User memory user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share =
                        user.deposits[i]
                            .amount
                            .mul(user.deposits[i].percent)
                            .div(PERCENTS_DIVIDER);
                    uint256 from =
                        user.deposits[i].start > user.checkpoint
                            ? user.deposits[i].start
                            : user.checkpoint;
                    uint256 to =
                        user.deposits[i].finish < block.timestamp
                            ? user.deposits[i].finish
                            : block.timestamp;
                    if (from < to) {
                        uint256 planTime =
                            plans[user.deposits[i].plan].time.mul(TIME_STEP);
                        uint256 redress =
                            planTime.div(
                                getDecreaseDays(
                                    plans[user.deposits[i].plan].time
                                )
                            );

                        totalAmount = totalAmount.add(
                            share.mul(to.sub(from)).mul(redress).div(TIME_STEP)
                        );
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }

        return totalAmount;
    }

    function getDecreaseDays(uint256 planTime) public view returns (uint256) {
        
		if(LAUNCH_TIME > block.timestamp){
			return 	planTime.mul(TIME_STEP);
		}else{
			uint256 limitDays = uint256(MINIMUM_TIME).mul(TIME_STEP);
			uint256 pastDays = block.timestamp.sub(LAUNCH_TIME).div(TIME_STEP); 
			uint256 decreaseDays = pastDays.mul(DECREASE_DAY_STEP); 
			uint256 minimumDays = 0;
			if(planTime.mul(TIME_STEP) > decreaseDays){
				minimumDays = planTime.mul(TIME_STEP).sub(decreaseDays);
			}else{
				return limitDays;
			}
			if (minimumDays < limitDays) {
				return limitDays;
			}
			return minimumDays;
		}
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress)
        public
        view
         returns (
            bool preregister,
            uint256 checkpoint,
            address referrer,
            uint256 bonus,
            uint256 totalBonus
        )
    {
        User memory user = users[userAddress];
        preregister = user.preregister;
        checkpoint = user.checkpoint;
        referrer = user.referrer;
        bonus = user.bonus;
        totalBonus = user.totalBonus;
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserAmountOfPenaltyDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return penaltyDeposits[userAddress].length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 profit,
            uint256 start,
            uint256 finish,
            bool force
        )
    {
        User memory user = users[userAddress];

        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
        force = user.deposits[index].force;
    }
	
	function getAllDepositsInfo(address userAddress) view external returns(
		uint8[] memory plan,
		uint256[] memory percent,
		uint256[] memory amount,
		uint256[] memory profit,
		uint256[] memory start,
		uint256[] memory finish,
		bool[] memory force
	) 
	{
		User memory user 			= 	users[userAddress];
		
		uint8[] memory _plan 		= 	new uint8[](user.deposits.length);
		uint256[] memory _percent 	= 	new uint256[](user.deposits.length);
		uint256[] memory _amount 	= 	new uint256[](user.deposits.length);
		uint256[] memory _profit 	= 	new uint256[](user.deposits.length);
		uint256[] memory _start 	= 	new uint256[](user.deposits.length);
		uint256[] memory _finish 	= 	new uint256[](user.deposits.length);
		bool[] memory _force 		= 	new bool[](user.deposits.length);
		
		for(uint256 i = 0; i < user.deposits.length; i++) {
			_plan[i] 		= user.deposits[i].plan;
			_percent[i] 	= user.deposits[i].percent;
			_amount[i] 		= user.deposits[i].amount;
			_profit[i] 		= user.deposits[i].profit;
			_start[i] 		= user.deposits[i].start;
			_finish[i] 		= user.deposits[i].finish;
			_force[i] 		= user.deposits[i].force;
		}
		
		return (
				_plan,
				_percent,
				_amount,
				_profit,
				_start,
				_finish,
				_force
			);
	}
	
	function getAllInfo(address userAddress) view external returns(
		address referrer,
		bool preregister,
		uint256[30] memory bonuses
	) 
	{
		User memory user 	= 	users[userAddress];
		
		bonuses[0]			=	user.bonus;
		bonuses[1]			=	user.totalBonus;
		bonuses[2]			=	user.checkpoint;
		bonuses[3]			=	getUserReferralBonus(userAddress);
		bonuses[4]			=	getUserReferralTotalBonus(userAddress);
		bonuses[5]			=	getUserAmountOfDeposits(userAddress);
		bonuses[6]			=	getUserAmountOfPenaltyDeposits(userAddress);
		bonuses[7]			=	getUserTotalDeposits(userAddress);
		bonuses[8]			=	getContractBalance();
		bonuses[9]			=	address(userAddress).balance;
		bonuses[10]			=	totalStaked;
		bonuses[11]			=	totalRefBonus;
		bonuses[12]			=	getDecreaseDays(plans[0].time);
		bonuses[13]			=	getDecreaseDays(plans[1].time);
		bonuses[14]			=	getDecreaseDays(plans[2].time);
		bonuses[15]			=	getDecreaseDays(plans[3].time);
		bonuses[16]			=	getDecreaseDays(plans[4].time);
		bonuses[17]			=	getDecreaseDays(plans[5].time);
		bonuses[19]			=	getPercent(0);
		bonuses[20]			=	getPercent(1);
		bonuses[21]			=	getPercent(2);
		bonuses[22]			=	getPercent(3);
		bonuses[23]			=	getPercent(4);
		bonuses[24]			=	getPercent(5);
		bonuses[26]			=	getUserReferralWithdrawn(userAddress);
		bonuses[27]			=	getUserDividends(userAddress);
		bonuses[28]			=	block.timestamp;
		bonuses[29]			=	LAUNCH_TIME;
		
		return (
				user.referrer,
				user.preregister,
				bonuses
			);	
	}


    function getUserPenaltyDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 profit,
            uint256 start,
            uint256 finish
        )
    {
        require(index < penaltyDeposits[userAddress].length, "Invalid index");

        plan 	= penaltyDeposits[userAddress][index].plan;
        percent = penaltyDeposits[userAddress][index].percent;
        amount 	= penaltyDeposits[userAddress][index].amount;
        profit 	= penaltyDeposits[userAddress][index].profit;
        start 	= penaltyDeposits[userAddress][index].start;
        finish 	= penaltyDeposits[userAddress][index].finish;
    }
	
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
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
}