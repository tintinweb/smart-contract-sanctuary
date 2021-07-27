//SourceUnit: DEOPP.sol

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

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

contract DEOPP{
    using SafeMath for uint;
    uint constant public MIN_INVESTMENT = 100 trx;
    uint constant public MAX_INVESTMENT = 3500000 trx;
    uint constant public ROI_PERCENT = 300;
	uint constant public TOTAL_GROWTH_REWARD = 800;
	uint constant public AUTOMATED_POWER_CONTRIBUTION = 200;
    uint[] public GROWTH_REWARDS = [300, 200, 100, 50, 50, 40, 30, 10, 10, 10];
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public TIME_STEP = 1 days;
    uint public totalInvested;
    uint public totalDeposits;
    uint public totalWithdrawn;
    uint public contractCreationTime;
    uint public totalRefBonus;
	uint public withdraw5050Total;
	uint public withdrawAndRedepositTotal;
	uint public withdrawAllAfter60DaysTotal;
	uint public withdrawEarlyTotal;
	
    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }
	
    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint64 bonus;
		uint nextwithdrawall;
        uint[10] refs;
		uint[10] refsdeposit;
		uint[10] refsbonus;
    }
	
    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;
    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
	
    constructor() {
	
    }
	
	function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(msg.value >= MIN_INVESTMENT && msg.value <= MAX_INVESTMENT, "Incorrect Deposit");
		User storage user = users[msg.sender];
        uint msgValue = msg.value;
		if(totalDeposits > 0)
		{
		    require(users[referrer].deposits.length > 0 && referrer != msg.sender, "Incorrect Referrer");
			user.referrer = referrer;
		}
		else
		{
		    user.referrer = address(0);
		}
		
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(GROWTH_REWARDS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, msg.sender, i, amount);
                    }
                    users[upline].refs[i]++;
					users[upline].refsdeposit[i]=uint(users[upline].refsdeposit[i]).add(msgValue);
					users[upline].refsbonus[i]=uint(users[upline].refsbonus[i]).add(amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }
		
        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
			user.nextwithdrawall = block.timestamp + 60 days;
            emit Newbie(msg.sender);
        }
		
		uint growthReward = msgValue.mul(TOTAL_GROWTH_REWARD).div(PERCENTS_DIVIDER);
		uint powerContribution = msgValue.mul(AUTOMATED_POWER_CONTRIBUTION).div(PERCENTS_DIVIDER);
		
        user.deposits.push(Deposit(uint64(msgValue.sub(growthReward).sub(powerContribution)), 0, uint32(block.timestamp)));
        totalInvested = totalInvested.add(msgValue.sub(growthReward).sub(powerContribution));
        totalDeposits++;
        emit NewDeposit(msg.sender, msgValue.sub(growthReward).sub(powerContribution));
    }
	
	function reinvest(address investor, uint msgValue) private{
        require(msg.value >= MIN_INVESTMENT && msg.value <= MAX_INVESTMENT, "Incorrect Deposit");
		User storage user = users[investor];
		
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(GROWTH_REWARDS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, investor, i, amount);
                    }
                    users[upline].refs[i]++;
					users[upline].refsdeposit[i]=uint(users[upline].refsdeposit[i]).add(msgValue);
					users[upline].refsbonus[i]=uint(users[upline].refsbonus[i]).add(amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }
		
		uint growthReward = msgValue.mul(TOTAL_GROWTH_REWARD).div(PERCENTS_DIVIDER);
		uint powerContribution = msgValue.mul(AUTOMATED_POWER_CONTRIBUTION).div(PERCENTS_DIVIDER);
		
		user.deposits.push(Deposit(uint64(msgValue.sub(growthReward).sub(powerContribution)), 0, uint32(block.timestamp)));
        totalInvested = totalInvested.add(msgValue.sub(growthReward).sub(powerContribution));
        totalDeposits++;
        emit NewDeposit(msg.sender, msgValue.sub(growthReward).sub(powerContribution));
		
    }
	
    function withdrawEarly() public {
        User storage user = users[msg.sender];
        uint totalAmount;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {
		
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {
				
                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.deposits[i].start))).div(TIME_STEP);
                
				} else {

                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
					
                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) 
				{
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }
				
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
                totalAmount = totalAmount.add(dividends);
            }
        }
		
        require(totalAmount > 0, "User has no dividends");
		
        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
		uint powerContribution = totalAmount.mul(2200).div(PERCENTS_DIVIDER);
        user.checkpoint = uint32(block.timestamp);
        msg.sender.transfer(totalAmount.sub(powerContribution));
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        withdrawEarlyTotal++;
        emit Withdrawn(msg.sender, totalAmount);
    }
	
	function withdraw5050() public {
	    uint useravailable = getUserAvailable(msg.sender); 
		uint contribution = useravailable.mul(AUTOMATED_POWER_CONTRIBUTION).div(PERCENTS_DIVIDER);
		uint remaining = useravailable.sub(contribution);
		require(remaining.div(2) >= MIN_INVESTMENT && remaining.div(2) <= MAX_INVESTMENT, "Incorrect Withdraw");
		
        User storage user = users[msg.sender];
        uint totalAmount;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {
				
                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.deposits[i].start))).div(TIME_STEP);
                
				} else {

                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
					
                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) 
				{
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }
				
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
                totalAmount = totalAmount.add(dividends);

            }
        }
		
        require(totalAmount > 0, "User has no dividends");
        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
		uint powerContribution = totalAmount.mul(AUTOMATED_POWER_CONTRIBUTION).div(PERCENTS_DIVIDER);
        user.checkpoint = uint32(block.timestamp);
		
		uint finalAmount = totalAmount.sub(powerContribution);
		msg.sender.transfer(finalAmount.div(2));
		reinvest(msg.sender, finalAmount.div(2));
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		withdraw5050Total++;
        emit Withdrawn(msg.sender, totalAmount);
    }
	
	function withdrawAndRedeposit() public {
	    uint useravailable = getUserAvailable(msg.sender); 
		uint contribution = useravailable.mul(AUTOMATED_POWER_CONTRIBUTION).div(PERCENTS_DIVIDER);
		require(useravailable.sub(contribution) >= MIN_INVESTMENT && useravailable.sub(contribution) <= MAX_INVESTMENT, "Incorrect Withdraw");
		
        User storage user = users[msg.sender];
        uint totalAmount;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {
				
                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.deposits[i].start))).div(TIME_STEP);
                
				} else {

                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
					
                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) 
				{
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }
				
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
                totalAmount = totalAmount.add(dividends);
            }
        }
		
        require(totalAmount > 0, "User has no dividends");
		
        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
		uint powerContribution = totalAmount.mul(AUTOMATED_POWER_CONTRIBUTION).div(PERCENTS_DIVIDER);
        user.checkpoint = uint32(block.timestamp);
		reinvest(msg.sender, totalAmount.sub(powerContribution));
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		withdrawAndRedepositTotal++;
        emit Withdrawn(msg.sender, totalAmount);
    }
	
	function withdrawAll() public {
	    User storage user = users[msg.sender];
		require(user.nextwithdrawall <= block.timestamp, "No Eligible For Withdrawal All");
		
        uint totalAmount;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {
				
                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.deposits[i].start))).div(TIME_STEP);
                
				} else {

                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
					
                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) 
				{
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }
				
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
                totalAmount = totalAmount.add(dividends);

            }
        }
		user.nextwithdrawall = block.timestamp + 60 days;
		
        require(totalAmount > 0, "User has no dividends");
		
        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
		uint powerContribution = totalAmount.mul(AUTOMATED_POWER_CONTRIBUTION).div(PERCENTS_DIVIDER);
        user.checkpoint = uint32(block.timestamp);
		msg.sender.transfer(totalAmount.sub(powerContribution));
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		withdrawAllAfter60DaysTotal++;
        emit Withdrawn(msg.sender, totalAmount);
    }
	
    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint totalDividends;
        uint dividends;
		
        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.deposits[i].start))).div(TIME_STEP);
                
				} else {

                    dividends = (uint(user.deposits[i].amount).mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
					
                }
				
                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) 
				{
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }
                totalDividends = totalDividends.add(dividends);
            }
        }
        return totalDividends;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];
        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }
    
    function getUserLastDeposit(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpoint;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }
        return amount;
    }
	
    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount = user.bonus;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }
        return amount;
    }

    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];
		
        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }
		
        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory refback = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }
        return (amount, withdrawn, refback, start);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance, ROI_PERCENT);
    }
	
    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint) {
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);
        return (userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }
    
     function getUserRefStats(address userAddress) public view returns (uint[10] memory, uint[10] memory, uint[10] memory) {
        return (users[userAddress].refs, users[userAddress].refsdeposit, users[userAddress].refsbonus);
    }


	function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}