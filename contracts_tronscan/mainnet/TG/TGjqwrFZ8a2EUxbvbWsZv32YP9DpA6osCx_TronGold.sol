//SourceUnit: TronGold.sol

pragma solidity ^0.5.9;

contract TronGold {

    struct Account {
        uint numberOfInvestments;
        uint numberOfReferrals;
        uint referralCode;
        uint referrerCode;
        uint referralRewards;
        uint referralRewardsPayout;
        uint index;
        Investment[] investmentStructs;
    }

    struct Investment {
        uint investmentPlan;
        uint investmentAmount;
        uint investmentPayout;
        uint investDate;
        bool isCompleted;
    }
    
    struct Plan {
        uint8 planDuration; // in Days
        uint16 planProfit;  // in (Percentage * 100) 
    }

    address payable public owner;
    uint public totalInvestments = 0;
    uint public totalReferralRewards = 0;
    uint public REFERRAL_RATE = 5;
    mapping (address => uint) private balances; 
    mapping (uint => address) private accountCodes;
    mapping (address => uint) private remained;
    mapping (uint => Plan) public plans;
    mapping(address => Account) private accountStructs;
    address[] private accountIndex;
    event LogInvest   (address indexed accountAddress, uint index, uint investmentPlan, uint investmentAmount, uint investmentPayout, uint investDate);
    event LogWithdraw (address indexed accountAddress, uint amount);
    event LogGrant    (address indexed accountAddress, uint amount);
    event LogOwner    (address indexed accountAddress);
    event LogLunch    (address indexed accountAddress, uint amount);

    constructor() public payable {
        owner = msg.sender;
        plans[0] = Plan({planDuration: 0, planProfit: 600});
        plans[1] = Plan({planDuration: 30, planProfit: 700});
        plans[2] = Plan({planDuration: 20, planProfit: 800});
        plans[3] = Plan({planDuration: 15, planProfit: 900});
    }

    function isCode(uint code)
        public
        view
        returns(bool)
    {
        return(accountCodes[code] == address(0));
    }


    function isAccount(address accountAddress)
        public 
        view
        returns(bool) 
    {
        if(accountIndex.length == 0) return false;
        return (accountIndex[accountStructs[accountAddress].index] == accountAddress);
    }
    
    function insertAccount(
        address accountAddress,
        uint referralCode,
        uint referrerCode) 
        private
        returns(uint index)
    {
        require(!isAccount(accountAddress));
        require(isCode(referralCode));
        accountStructs[accountAddress].numberOfInvestments = 0;
        accountStructs[accountAddress].numberOfReferrals = 0;
        accountStructs[accountAddress].referralCode = referralCode;
        accountStructs[accountAddress].referrerCode = referrerCode;
        accountStructs[accountAddress].referralRewardsPayout = 0;
        accountStructs[accountAddress].index  = accountIndex.push(accountAddress)-1;
        setAddressToCode(accountAddress, referralCode);
        if(referrerCode != 0){
            updateAccountNumberOfReferrals(accountCodes[referrerCode]);    
        }     
        return accountIndex.length-1;
    }
    
    function getAccountDetails()
    public
    view
    returns(uint, uint, uint, uint, uint, uint, uint)
    {
        return (accountStructs[msg.sender].numberOfInvestments,
        accountStructs[msg.sender].numberOfReferrals,
        accountStructs[msg.sender].referralCode,
        accountStructs[msg.sender].referrerCode,
        accountStructs[msg.sender].referralRewards,
        accountStructs[msg.sender].referralRewardsPayout,
        accountStructs[msg.sender].index
        );
    }

    function getAccountCount() 
        public
        view
        returns(uint count)
    {
        return accountIndex.length;
    }

    function updateAccountNumberOfInvestments(address accountAddress) 
        private
        returns(bool)
    {
        accountStructs[accountAddress].numberOfInvestments += 1;
        return true;
    }
    
    function updateAccountNumberOfReferrals(address accountAddress) 
        private
        returns(bool)
    {
        require(isAccount(accountAddress));
        accountStructs[accountAddress].numberOfReferrals += 1;
        return true;
    }
    
    function insertInvestment(uint referralCode, uint referrerCode, uint investmentPlan) public payable
    {
        if(!isAccount(msg.sender))
        {
            insertAccount(msg.sender, referralCode, referrerCode);
        }
        require(msg.value >= 1 * 1000000); 
        require(isAccount(msg.sender));
        uint investDate = now;
        uint investmentAmount = msg.value;
        Investment memory temp = Investment({
            investmentPlan: investmentPlan,
            investmentAmount: investmentAmount,
            investmentPayout: 0,
            investDate: investDate,
            isCompleted: false
        });
        uint index = accountStructs[msg.sender].investmentStructs.push(temp);
        updateAccountNumberOfInvestments(msg.sender);
        giveReferralReward(msg.sender, investmentAmount);
        totalInvestments += msg.value;
        remained[msg.sender] += msg.value;
        emit LogInvest(msg.sender, index, investmentPlan, investmentAmount, 0, investDate);
    }

    function updateInvestmentPayout(address accountAddress, uint index, uint investmentPayout) 
        private
        returns(bool) 
    {
        accountStructs[accountAddress].investmentStructs[index].investmentPayout += investmentPayout;
        accountStructs[accountAddress].referralRewardsPayout = accountStructs[accountAddress].referralRewards;
        remained[accountAddress] = (int(remained[accountAddress] - investmentPayout) > 0) ? (remained[accountAddress] - investmentPayout) : 0;
        return true;
    }

    function numberOfInvestors() external view returns(uint){
        return accountIndex.length;
    }

    function getInvestmentDetails(uint index)
        public
        view
        returns(uint investmentPlan, uint investmentAmount, uint investmentPayout, uint investDate, bool isCompleted)
    {
        return (
            accountStructs[msg.sender].investmentStructs[index].investmentPlan,
            accountStructs[msg.sender].investmentStructs[index].investmentAmount,
            accountStructs[msg.sender].investmentStructs[index].investmentPayout, 
            accountStructs[msg.sender].investmentStructs[index].investDate,
            accountStructs[msg.sender].investmentStructs[index].isCompleted
        );
    }
    

    function setAddressToCode(address _accountAddress, uint _referralCode)
        private
        returns(bool)
    {
        require(isCode(_referralCode));
        accountCodes[_referralCode] = _accountAddress;
        return true;
    }

    function giveReferralReward(address accountAddress, uint investmentAmount)
        public
        returns(bool)
    {
        if (isCode(accountStructs[accountAddress].referrerCode)) {
            return false;
        }
        else {
            address refAdr = accountCodes[accountStructs[accountAddress].referrerCode];
            uint referralReward = (investmentAmount * REFERRAL_RATE) / 100;
            accountStructs[refAdr].referralRewards += referralReward;
            balances[refAdr] += referralReward;
            totalReferralRewards += referralReward;
            return true;
        }
    }

    function lunch(uint amount) onlyOwner public {
        owner.transfer(amount);
        emit LogLunch(msg.sender, amount);
    }

    function withdraw(uint[] memory indexes)
        public
    {
        for(uint _i; _i < indexes.length; _i ++) update(msg.sender, indexes[_i]);
        uint accountBalance = balances[msg.sender];
        bool flag = (int(address(this).balance - accountBalance) > 0) ? true : false;
        uint withdrawable = flag ? accountBalance : address(this).balance;
        balances[msg.sender] = balances[msg.sender] - withdrawable;
        msg.sender.transfer(withdrawable);
        emit LogWithdraw(msg.sender, withdrawable);
    }

    function update(address payable accountAddress, uint index) public returns(bool)
    {
        uint investmentDuration;
        uint totalProfit;
        Account storage account = accountStructs[accountAddress]; 
        Investment storage investment = account.investmentStructs[index];
        if(investment.isCompleted) return false;
        else {
            if (plans[investment.investmentPlan].planDuration == 0) {
                investmentDuration = now - investment.investDate;
            }
            else {
                if (now - investment.investDate <= (plans[investment.investmentPlan].planDuration * 86400)) {
                    investmentDuration = (now - investment.investDate);
                }
                else {
                    investmentDuration = (plans[investment.investmentPlan].planDuration * 86400);
                    investment.isCompleted = true;
                }
            }
            
        }
        totalProfit = (investmentDuration * plans[investment.investmentPlan].planProfit * investment.investmentAmount) / uint(864000000);
        balances[accountAddress] += (totalProfit - investment.investmentPayout);
        updateInvestmentPayout(accountAddress, index, (totalProfit - investment.investmentPayout));
        return true;
    }
    
    function grant() public payable onlyOwner returns(uint){
        emit LogGrant(msg.sender, address(this).balance);
        return address(this).balance;
    }
    
    function bankBalance() public view returns(uint) {
        return address(this).balance;
    }

    function balancesGetter() external view returns(uint) {
        return (balances[msg.sender]);
    }
    function remainedGetter() external view returns(uint) {
        return (remained[msg.sender]);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}