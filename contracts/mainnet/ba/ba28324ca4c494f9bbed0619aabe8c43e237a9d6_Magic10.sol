pragma solidity ^0.4.24;

contract Magic10 {
    
    // Timer of percentage increasing 
	uint256 public periodLength = 7 days;
	
	// We need to work with fractional percents like 0.7%, so we need to devide by 1000 before multiply the number
	// Each variable which calculated with this value has a prefix Decimal
	uint256 public percentDecimals = 3;
	
	// Percents calculation using percentDecimals 2% = 20
	uint256 public startDecimalPercent = 20;

    // Additional percent for completed period is 0.3% = 3
	uint256 public bonusDecimalPercentByPeriod = 3; 
	
	// Maximal percent is 5% = 50
	uint256 public maximalDecimalPercent = 50;

    // Structure of deposit
	struct Deposit {
	    address owner;
        uint256 amount;
        uint64 timeFrom;
    }
    
    // Notice, start index for all deposits is 1.
    // List of all deposits
    mapping(uint64 => Deposit) public deposits;
    
    // List of all deposits by each investor
    // Implemented to enable quick access to investor deposits even without server caching
    mapping(address => mapping(uint64 => uint64)) public investorsToDeposit;
    
    // Count of deposits by each investor
    mapping(address => uint16) public depositsByInvestor;
    
    // List of registered referrals
    mapping(address => bool) public referralList;
    
    // Total number of deposits
    uint64 public depositsCount = 0;
    
    
    // Create a new deposit
    function createDeposit(address _referral) external payable {
        
        // Minimal deposit is 1 finney
        require(msg.value >= 1 finney);
        
        // Create a deposit object
        Deposit memory _deposit = Deposit({
            owner: msg.sender,
            amount: msg.value,
            timeFrom: uint64(now)
        });
        
        //
        // Calculating IDS
        //
        
        // New deposit ID equals to current deposits count + 1
        uint64 depositId = depositsCount+1;
        
        // new deposit ID for investor equals current count + 1
        uint64 depositIdByInvestor = depositsByInvestor[msg.sender] + 1;
        
        //
        // Saving data
        //
        
        // Saving deposit into current ID
        deposits[depositId] = _deposit;
        
        // Adding deposit ID into list of deposits for current investor
        investorsToDeposit[msg.sender][depositIdByInvestor] = depositId;
        
        //
        // Counters incrementing    
        //
        
        // Increment count of deposits for current investor
        depositsByInvestor[msg.sender]++;
        
        // Increment global count of deposits
        depositsCount++;
        
        //
        // Additional sendings - 5% to company and 1-5% to referrals
        //
        
        address company = 0xFd40fE6D5d31c6A523F89e3Af05bb3457B5EAD0F;
        
        // 5% goes to the company budget
        company.transfer(msg.value / 20);
        
        // Referral percent
        uint8 refferalPercent = currentReferralPercent();
        
        // Referral receive reward according current reward percent if he is in list.
        if(referralList[_referral] && _referral != msg.sender) {
            _referral.transfer(msg.value * refferalPercent/ 100);
        }
    }
    
    // Function for withdraw
    function withdrawPercents(uint64 _depositId) external {
        
        // Get deposit information
        Deposit memory deposit = deposits[_depositId];
        
        // Available for deposit owner only
        require(deposit.owner == msg.sender);
        
        // Get reward amount by public function currentReward
        uint256 reward = currentReward(_depositId);
        
        // Refresh deposit time and save it
        deposit.timeFrom = uint64(now);
        deposits[_depositId] = deposit;
        
        // Transfer reward to investor
        deposit.owner.transfer(reward);
    }

    // Referal registration
    function registerReferral(address _refferal) external {
        // Available from this address only 
        require(msg.sender == 0x21b4d32e6875a6c2e44032da71a33438bbae8820);
        
        referralList[_refferal] = true;
    }
    
    //
    //
    //
    // Information functions
    //
    //
    //
    
    // Calcaulating current reward by deposit ID
    function currentReward(uint64 _depositId)
        view 
        public 
        returns(uint256 amount) 
    {
        // Get information about deposit
        Deposit memory deposit = deposits[_depositId];
        
        // Bug protection with "now" time
        if(deposit.timeFrom > now)
            return 0;
        
        // Get current deposit percent using public function rewardDecimalPercentByTime
        uint16 dayDecimalPercent = rewardDecimalPercentByTime(deposit.timeFrom);
        
        // Calculating reward for each day
        uint256 amountByDay = ( deposit.amount * dayDecimalPercent / 10**percentDecimals ) ;
        
        // Calculate time from the start of the deposit to current time in minutes
        uint256 minutesPassed = (now - deposit.timeFrom) / 60;
        amount = amountByDay * minutesPassed / 1440;
    }
    
    // Calculate reward percent by timestamp of creation
    function rewardDecimalPercentByTime(uint256 _timeFrom) 
        view 
        public 
        returns(uint16 decimalPercent) 
    {
        // Returning start percent, if sending timestamp from the future
        if(_timeFrom >= now)
            return uint16(startDecimalPercent);
            
        // Main calculating
        decimalPercent = uint16(startDecimalPercent +  (( (now - _timeFrom) / periodLength ) * bonusDecimalPercentByPeriod));
        
        // Returning the maximum percentage if the percentage is higher than the maximum
        if(decimalPercent > maximalDecimalPercent)
            return uint16(maximalDecimalPercent);
    }
    
    // Referral percent calculating by contract balance
    function currentReferralPercent() 
        view 
        public 
        returns(uint8 percent) 
    {
        if(address(this).balance > 10000 ether)
            return 1;
            
        if(address(this).balance > 1000 ether)
            return 2;
            
        if(address(this).balance > 100 ether)
            return 3;
            
        if(address(this).balance > 10 ether)
            return 4;
        
        return 5;
    }
}