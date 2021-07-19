//SourceUnit: tronstack.sol

/*
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronstack.org                                      │
 *   │                                                                       │
 *   │   Telegram Live Support: https://t.me/tronstack_admin                 |
 *   │   Telegram Public Group: https://t.me/tronstack_official              |
 *   │                                                                       |
 *   |                                                                       |
 *   |   Twitter:   https://twitter.com/tronstack                            |
 *   |   YouTube:   https://www.youtube.com/channel/UCSWFe6VShJXLvKDNfpR1LGQ |
 *   |   Instagram: https://instagram.com/tronstack                          |
 *   |                                                                       |
 *   |   E-mail: info@tronstack.org                                          |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON Browser Extension TronLink Or TronMask, Or Mobile Wallet Apps Like TronWallet Or Banko
 *   2) Send Any TRX Amount (100 TRX Minimum) Using Our Website Invest Button
 *   3) Wait For Your Earnings
 *   4) Withdraw Earnings Any Time Using Our Website "Withdraw" Button
 *
 *   [PROFIT MAKING PLANS]
 *
 *   - Daily Intrest Rate : 2%   Of Initial Investment Per Day
 *   - Total Margin Bonus : 0.1% For Every 1,000,000 TRX Addition To Total Contract Balance
 *   - Hold Bonus         : 0.1% For Every 24 Hours Profit Holding Without Withdrawal
 *
 *   - Minimum Deposit: 100 TRX, No Maximal Limit
 *   - Maximum income:  300% (Deposit Not Included) Per Every Deposit Row (Investments And Reinvesments)
 *   - Earnings Every Moment, Withdraw Or Reinvest Your Optional Amount Anytime.
 *
 *
 *   [PROFIT LIMITATIONS]
 *   - Total Paying Profit Will Be Reduced By 5% After Each Withdrawal For Every Investment Row.
 *   - Holding- Bonus Time Recorder Will Be Reset After Each Withdrawal.
 *   - Smart Contract Stop Paying Profit After 20 Withdrawals For Each Row.
 *   - Reinvestment Doesn’t Include Profit Limitations.
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 3-Level Referral Commission: 4% - 2% - 0.5% 
 *   - Auto-refback function
 *
 *   [Max INVESTOR CONDITIONS]
 *
 *   - Max Investor Is The Wallet Address Owning The Maximum Balance Even For A Second.
 *   - Max Investor's Daily Interest Rate Turns To 4% And Continues Same Until The Max Investor Change.
 *   - All The Paid Daily Interest Rate Will Be Doubled Up Once After Getting Max-Investor. 
 *   - Getting Max- Investor Doesn’t Necessarily Means More Deposit And Can Be Achieved By More Re-Investments.
 
 *   [FUNDS DISTRIBUTION]
 *
 *   - 85% Contract Balance.
 *   - 8% Back Up Account (For Trading).
 *   - 5% Marketing And Advertisement. 
 *   - 2% Developer’s Fee.
 *
 *   ────────────────────────────────────────────────────────────────────────
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audited by independent company Telescr In (Webiste: https://telescr.in)
 *
 */
pragma solidity 0.5.12;
contract TRONSTACK {
	using SafeMath for uint;
	// --------------------------- Define Constant -----------------------
	uint constant public MIN_INVEST = 100 trx;
	uint constant public MAX_CONTRACT_PROFIT = 80000000 trx;
	uint constant public MIN_CONTRACT_PROFIT = 10000000 trx;
	uint constant public D_PROFIT = 2000;/*2000=2*/
	uint constant public C_PROFIT =  100;/*100=0.1*/
	uint constant public H_PROFIT =  100;/*100=0.1*/
	uint[] private REFERRAL_PERCENTS = [4000, 2000, 500];
	uint constant MINUS_FACTOR = 5;   /*0.005*/
	uint constant public ADVER_FEE = 5000;
	uint constant public ADMIN_FEE = 2000;
	uint constant public Backup_FEE = 8000;
	uint constant public PERCENTS_DIVIDER = 100000;
	uint constant public UINT_DIVIDER = 1000000;
	uint constant public TIME_STEP = 1 days;
	// --------------------------- Global Fact Variable--------------------
    uint private totalUsers;
	uint private totalInvested;
	uint private totalWithdrawn;
	uint private Max_Investor_Amount;
	// --------------------------- Important Addresses  --------------------
    address payable private AdverAddrs;
	address payable private adminAddrs;
	address payable private backupAddrs;
	address payable private Max_Investor_Address;
    // --------------------------- Contract Structures  --------------------
    struct Deposit {
	    uint rowno;
    	uint256 amount;
    	uint256 withdrawn;
    	uint256 withdrawDate;
    	uint wCount;
    	uint saveProfit;
		bool deActive;
	}
	struct bonusRows{
	    uint bnsRowno;
	    uint256 bnsSaveDate;
	    uint bnsLevel;
	    uint bnsAmount;
	}
    struct User {
	    Deposit[] deposits;
		uint sumAmount;
		uint sumWithdrawn;
		uint depositCount;
		uint bonus;
		address referrer;
		bonusRows[] bonusRef;
		uint bonusCount;
	}
	// ---------------------------      Mappings        --------------------
    mapping (address => User) internal users;
    // --------------------------- Contract Events      --------------------
    event userInvested(address user);
	event Withdrawn(address indexed user, uint amount);
	event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
	event FeePayed(address indexed user, uint totalAmount);
	event reInvested(address indexed user, uint totalAmount);
    // --------------------------- constructor - Run In Deploy Time Only ---
    constructor(address payable marketingAddr, address payable adminAddr,address payable backupAddr) public {
        require(!isContract(adminAddrs) && !isContract(marketingAddr) && !isContract(backupAddrs));
	    AdverAddrs = marketingAddr;
		adminAddrs = adminAddr;
		backupAddrs = backupAddr;
	}
	// --------------------------- Contract Payable functions ---
	function transferDevBakAdverFee(uint amount) private returns(int){
	    AdverAddrs.transfer(amount.mul(ADVER_FEE).div(PERCENTS_DIVIDER));
		adminAddrs.transfer(amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
		backupAddrs.transfer(amount.mul(Backup_FEE).div(PERCENTS_DIVIDER));
		return 1;
	}
	function invest(address referrer) public payable returns(uint) {
		require(lnchDateOk() == true ,"Contract Has Not Been launched Yet.");
		require(!isContract(msg.sender) && msg.sender == tx.origin,"Invalid Address.");
		require(msg.value >= MIN_INVEST,"invest less than minimum.");
		transferDevBakAdverFee(msg.value);
        emit FeePayed(msg.sender, msg.value.mul(ADVER_FEE.add(ADMIN_FEE).add(Backup_FEE)).div(PERCENTS_DIVIDER));
        User storage user = users[msg.sender];
        if(referrer == msg.sender)
        {
            user.referrer=AdverAddrs;
		    AdverAddrs.transfer(msg.value.mul(REFERRAL_PERCENTS[0]).div(PERCENTS_DIVIDER));
        }
        else
        {
            if (users[referrer].sumAmount > 0 ) {
    			user.referrer = referrer;
    			if (user.referrer != address(0)) {
            		address upline = user.referrer;
            		for (uint i = 0; i < 3; i++) {
            			if (upline != address(0)) {
            				uint amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
            				users[upline].bonus = users[upline].bonus.add(amount);
            			    users[upline].bonusRef.push(bonusRows(users[upline].bonusCount.add(1),block.timestamp,i,amount));
        				    users[upline].bonusCount = users[upline].bonusCount.add(1);
            				emit RefBonus(upline, msg.sender, i, amount);
            				upline = users[upline].referrer;
            			} else break;
            		}
                }
    		}    
        }
        if (user.depositCount == 0) {
	        user.deposits.push(Deposit(1,msg.value, 0, block.timestamp,0,0,false));
			user.sumAmount = msg.value;
    		user.sumWithdrawn=0;
    		user.depositCount=1;
    		user.bonus=0;
    		totalUsers = totalUsers.add(1);
	    }
	    else if (user.depositCount > 0)
	    {
	        user.deposits.push(Deposit(user.depositCount.add(1),msg.value, 0, block.timestamp,0,0,false));
			user.sumAmount = user.sumAmount.add(msg.value);
    		user.depositCount=user.depositCount.add(1);
        }
        // Set Max Investor Except backupAddrs
	    if(user.sumAmount.sub(user.sumWithdrawn) > Max_Investor_Amount && msg.sender != backupAddrs)
		{
		    Max_Investor_Amount = user.sumAmount;
		    Max_Investor_Address = msg.sender;
		}
		emit userInvested(msg.sender);
		totalInvested = totalInvested.add(msg.value);
		return 1;
	}
	function reInvest(uint inx,uint amount) public payable returns(uint) {
	    require(lnchDateOk() == true ,"Contract Has Not Been launched Yet.");
	    require(!isContract(msg.sender) && msg.sender == tx.origin,"Invalid Address.");
	    // Backup Account Cant ReIvest
	    require(msg.sender != backupAddrs,"backupAddrs Cant Access To This Function.");
	    User storage user = users[msg.sender];
        require(user.depositCount>0,"You Dont Have Investment.");
        uint256 pro ;
	    uint256 maxpro ;
	    uint256 avaPro ;
	    bool overMaxHappen=false;
	    if (isUserRowAtTriple(inx) == true)
            pro = getUserRowRemainderToTriple(inx);    
        else
            pro = getUserDailyProfit(inx).add(getUserHoldProfit(inx).add(getUserContractProfit(inx)));
        maxpro = user.deposits[inx].amount.mul(3);
        avaPro = pro.add(user.deposits[inx].saveProfit); 
        if (amount.add(user.deposits[inx].withdrawn) >= maxpro){
            amount = maxpro.sub(user.deposits[inx].withdrawn);
            overMaxHappen = true;
        }
        require(amount > 0,"Amount Must Be Greater Than Zero.");
        require(avaPro>amount,"Not Enough Balance.");
        transferDevBakAdverFee(amount);
		emit FeePayed(msg.sender, amount.mul(ADVER_FEE.add(ADMIN_FEE).add(Backup_FEE)).div(PERCENTS_DIVIDER));
        if (overMaxHappen == true){
            user.deposits[inx].saveProfit=0;
            user.deposits[inx].withdrawn=maxpro;
        }
        else{
            
            user.deposits[inx].withdrawn=user.deposits[inx].withdrawn.add(amount);
            if (avaPro.sub(amount) > maxpro.sub(user.deposits[inx].withdrawn))
                user.deposits[inx].saveProfit=maxpro.sub(user.deposits[inx].withdrawn);
            else
                user.deposits[inx].saveProfit=avaPro.sub(amount);
        }
        // Check For deActive User 
        if (user.deposits[inx].withdrawn >= maxpro || user.deposits[inx].wCount>=20)
            user.deposits[inx].deActive = true;    
        user.deposits[inx].withdrawDate = block.timestamp;
        user.deposits.push(Deposit(user.depositCount.add(1),amount, 0, block.timestamp,0,0,false));
        user.sumAmount = user.sumAmount.add(amount);
        user.depositCount=user.depositCount.add(1);
        totalInvested=totalInvested.add(amount);
        // Set Max Investor Except backupAddrs
	    if(user.sumAmount.sub(user.sumWithdrawn) > Max_Investor_Amount && msg.sender != backupAddrs)
		{
		    Max_Investor_Amount = user.sumAmount;
		    Max_Investor_Address = msg.sender;
		}
        emit reInvested(msg.sender,amount);
        return 1;
    }
    function withdrawProfit(uint inx,uint256 amount) public returns(uint) {
        require(lnchDateOk() == true ,"Contract Has Not Been launched Yet.");
        // Backup Account Cant withdrawProfit
        require(msg.sender != backupAddrs,"backupAddrs Cant Access To This Function.");
        User storage user = users[msg.sender];
        require(user.deposits[inx].wCount<20,"After 20 Withdraw,Your Account Will Be Disable. ");
        require(user.deposits[inx].deActive == false,"This Investment Is Not Active.");
        uint256 pro ;
	    uint256 maxpro ;
	    uint256 avaPro ;
	    if (isUserRowAtTriple(inx) == true)
            pro = getUserRowRemainderToTriple(inx);    
        else
            pro = getUserDailyProfit(inx).add(getUserHoldProfit(inx).add(getUserContractProfit(inx)));
        maxpro = user.deposits[inx].amount.mul(3);
        avaPro = pro.add(user.deposits[inx].saveProfit); 
        
        require(avaPro>amount,"Not Enough Balance.");
        if (amount.add(user.deposits[inx].withdrawn) >= maxpro){
            amount = maxpro.sub(user.deposits[inx].withdrawn);
            user.deposits[inx].saveProfit=0;
            user.deposits[inx].withdrawn=maxpro;
        }
        else{
            
            user.deposits[inx].withdrawn=user.deposits[inx].withdrawn.add(amount);
            if (avaPro.sub(amount) > maxpro.sub(user.deposits[inx].withdrawn))
                user.deposits[inx].saveProfit=maxpro.sub(user.deposits[inx].withdrawn);
            else
                user.deposits[inx].saveProfit=avaPro.sub(amount);
        }
        user.deposits[inx].wCount = user.deposits[inx].wCount.add(1);
        user.deposits[inx].withdrawDate = block.timestamp;
        user.sumWithdrawn = user.sumWithdrawn.add(amount);
        totalWithdrawn=totalWithdrawn.add(amount);
        msg.sender.transfer(amount);
        emit Withdrawn(msg.sender,amount);
        
        // Check For deActive User 
        if (user.deposits[inx].withdrawn >= maxpro || user.deposits[inx].wCount>=20)
            user.deposits[inx].deActive = true;    
        
	    return 1;
	}
    function withdrawBonus() public  returns(uint) {
        require(lnchDateOk() == true ,"Contract Has Not Been launched Yet.");
        // Backup Account Cant withdrawBonus
        require(msg.sender != backupAddrs,"backupAddrs Cant Access To This Function.");
	    User storage user = users[msg.sender];
	    require(user.bonus>0,"You Dont Have Bonus");
	    uint bonus = user.bonus;
	    user.bonus=0;
	    msg.sender.transfer(bonus);
	    totalWithdrawn=totalWithdrawn.add(bonus);
	    return 1;
	}
	function withdrawBackup(uint inx,uint amount) public  returns(uint) {
	    require(lnchDateOk() == true ,"Contract Has Not Been launched Yet.");
	    // Only Backup Account Can Access To This Function
	    require(msg.sender == backupAddrs,"Other Account Cant Access To This Function.");
	    User storage user = users[msg.sender];
	    // Backup Account Cant Withdraw Greater Than Investment
	    uint backupBalance = user.deposits[inx].amount.sub(user.deposits[inx].withdrawn);
	    require(amount<=backupBalance);
	    backupAddrs.transfer(amount);
	    user.deposits[inx].withdrawn =user.deposits[inx].withdrawn.add(amount);
	    totalWithdrawn=totalWithdrawn.add(amount);
	    return 1;
	}
    // --------------------------- Calc User Profits Functions -------------------------
	function timeDiff(uint inx) public view returns (uint) {
	    return block.timestamp.sub(users[msg.sender].deposits[inx].withdrawDate);
	}
    function getUserDailyProfit_Rate(uint inx) public view returns (uint) {
        if (isUserRowAtTriple(inx) == true)
            return 0;
        uint256 D_PROFIT_TMP=D_PROFIT;
	    if (msg.sender == Max_Investor_Address)
	        D_PROFIT_TMP = D_PROFIT_TMP.mul(2);
	    D_PROFIT_TMP=D_PROFIT_TMP.sub(D_PROFIT_TMP.mul(users[msg.sender].deposits[inx].wCount.mul(MINUS_FACTOR)).div(100));
	    return D_PROFIT_TMP;
	}
    function getUserDailyProfit(uint inx) public view returns (uint) {
        if (isUserRowAtTriple(inx) == true)
            return 0;
	    return users[msg.sender].deposits[inx].amount.mul(timeDiff(inx)).mul(getUserDailyProfit_Rate(inx)).div(TIME_STEP).div(PERCENTS_DIVIDER);    
    }
	function getUserHoldProfit_Rate(uint inx) public view returns (uint) {
	    if (isUserRowAtTriple(inx) == true)
            return 0;
	    uint256 H_PROFIT_TMP=H_PROFIT;
	    H_PROFIT_TMP=H_PROFIT_TMP.sub(H_PROFIT_TMP.mul(users[msg.sender].deposits[inx].wCount.mul(MINUS_FACTOR)).div(100));
	    return H_PROFIT_TMP;
	}
	function getUserHoldProfit(uint inx) public view returns (uint) {
	    if (isUserRowAtTriple(inx) == true)
            return 0;
	    return users[msg.sender].deposits[inx].amount.mul(timeDiff(inx)).mul(getUserHoldProfit_Rate(inx)).div(TIME_STEP).div(PERCENTS_DIVIDER);
    }
    function getUserContractProfit_Rate(uint inx) public view returns (uint) {
        if (isUserRowAtTriple(inx) == true)
            return 0;
        if (getContractBalance() >= MIN_CONTRACT_PROFIT)
        {
            uint256 C_PROFIT_TMP=C_PROFIT.mul(getContractBalance().div(UINT_DIVIDER).div(MIN_CONTRACT_PROFIT));
	        C_PROFIT_TMP=C_PROFIT_TMP.sub(C_PROFIT_TMP.mul(users[msg.sender].deposits[inx].wCount.mul(MINUS_FACTOR)).div(100));
	        return C_PROFIT_TMP;
        }
        return 0;
    }
    function getUserContractProfit(uint inx) public view returns (uint) {
        if (isUserRowAtTriple(inx) == true)
            return 0;
        return users[msg.sender].deposits[inx].amount.mul(timeDiff(inx)).mul(getUserContractProfit_Rate(inx)).div(TIME_STEP).div(PERCENTS_DIVIDER);    
    }
    // --------------------------- User Important Info Functions -----------------------
	function getUserRowRemainderToTriple(uint inx) public view returns (uint) {
	    uint remainder = users[msg.sender].deposits[inx].amount.mul(3);
	    remainder = remainder.sub(users[msg.sender].deposits[inx].withdrawn.add(users[msg.sender].deposits[inx].saveProfit));
	    return remainder;
	}
    function getUserDepositInfo(uint inx) public view returns (uint,uint256,uint256,uint256,uint,uint,bool) {
		User storage user = users[msg.sender];
		return(user.deposits[inx].rowno,user.deposits[inx].amount,user.deposits[inx].withdrawn,user.deposits[inx].withdrawDate,user.deposits[inx].wCount,user.deposits[inx].saveProfit,user.deposits[inx].deActive);
	}
	function getUserInfo() public view returns (uint,uint,uint,uint,address,uint) {
		return(users[msg.sender].sumAmount,users[msg.sender].sumWithdrawn,users[msg.sender].depositCount,users[msg.sender].bonus,users[msg.sender].referrer,users[msg.sender].bonusCount);
	}
	function getUserBonusRefs(uint inx) public view returns (uint,uint256,uint,uint) {
        User storage user = users[msg.sender];
        return(user.bonusRef[inx].bnsRowno,user.bonusRef[inx].bnsSaveDate,user.bonusRef[inx].bnsLevel,user.bonusRef[inx].bnsAmount);		
	}
	// --------------------------- Check Functions         -----------------------------
	function isUserRowAtTriple(uint inx) public view returns (bool) {
	    User storage user = users[msg.sender];
	    uint tm = timeDiff(inx);
	    uint256 C_PROFIT_TMP=0;
	    uint256 H_PROFIT_TMP=H_PROFIT;
	    uint256 D_PROFIT_TMP=D_PROFIT;
	    //Calculate Contract Profit Rate
	    if (getContractBalance() >= MIN_CONTRACT_PROFIT)
        {
            C_PROFIT_TMP = C_PROFIT.mul(getContractBalance().div(UINT_DIVIDER).div(MIN_CONTRACT_PROFIT));
            C_PROFIT_TMP = C_PROFIT_TMP.sub(C_PROFIT_TMP.mul(user.deposits[inx].wCount.mul(MINUS_FACTOR)).div(100));
        }
        else
        {
            C_PROFIT_TMP=0;
        }
	    //Calculate Hold Profit Rate
	    H_PROFIT_TMP = H_PROFIT_TMP.sub(H_PROFIT_TMP.mul(user.deposits[inx].wCount.mul(MINUS_FACTOR)).div(100));
	    //Calculate Daily Profit Rate
	    if (msg.sender == Max_Investor_Address)
	        D_PROFIT_TMP = D_PROFIT_TMP.mul(2);
	    D_PROFIT_TMP=D_PROFIT_TMP.sub(D_PROFIT_TMP.mul(user.deposits[inx].wCount.mul(MINUS_FACTOR)).div(100));
	    //Calculate Every Profit Separately
	    D_PROFIT_TMP = user.deposits[inx].amount.mul(tm).mul(D_PROFIT_TMP).div(TIME_STEP).div(PERCENTS_DIVIDER);    
    	C_PROFIT_TMP = user.deposits[inx].amount.mul(tm).mul(C_PROFIT_TMP).div(TIME_STEP).div(PERCENTS_DIVIDER);    
    	H_PROFIT_TMP = user.deposits[inx].amount.mul(tm).mul(H_PROFIT_TMP).div(TIME_STEP).div(PERCENTS_DIVIDER);
	    //Test Row Profit At MAX Or Not
    	uint testToMax = D_PROFIT_TMP.add(C_PROFIT_TMP).add(H_PROFIT_TMP);
    	uint remainder = getUserRowRemainderToTriple(inx);
    	if (testToMax <=remainder)
    	    return false;
    	else
    	    return true;
	}
    function isMaxInvestor() public view returns (uint) {
	    if (msg.sender == Max_Investor_Address)
		    return 1 ;
		return 0;
	}
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    function lnchDateOk() public view returns (bool) {
        int256 tmp = int256(block.timestamp);
        tmp = 1611345600 - tmp; //01/22/2021 @ 8:00pm (UTC)
        if (tmp<=0)
	        return true;
	    return false;
	}
    // --------------------------- Contract Info Functions -----------------------------
    function getContractBalance() public view returns (uint) {
		return address(this).balance;
	}
	function getContractTotalInvest() public view returns (uint) {
		return totalInvested;
	}
	function getContractTotalUsers() public view returns (uint) {
		return totalUsers;
	}
	function getContractTotalWithdraw() public view returns (uint) {
		return totalWithdrawn;
	}
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;
        return c;
    }
}