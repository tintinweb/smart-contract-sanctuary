/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity ^0.5.8;


interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

 
  function name() external view returns (string memory);


  function getOwner() external view returns (address);

 
  function balanceOf(address account) external view returns (uint256);

  
  function transfer(address recipient, uint256 amount) external returns (bool);

  
  function allowance(address _owner, address spender) external view returns (uint256);


  function approve(address spender, uint256 amount) external returns (bool);


  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  function mint(address _to, uint256 amount) external returns (bool);

 
  event Transfer(address indexed from, address indexed to, uint256 value);


  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { 
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Objects {
    struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Soda_investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }
    struct Plan {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
    }

    struct Investor {
        address payable addr;
        uint256 referrerSodaEarnings;
        uint256 refRewardsToClaim;
        uint256 referrer;
        uint256 planCount;
        uint256 planCountSoda;
        mapping(uint256 => Investment) plans;
        mapping(uint256 => Soda_investment) plans_soda;
        uint256 referrals;
        uint256 lotteryRewards;
        
    }
    

}

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract WINEDEFI is Ownable {
    using SafeMath for uint256;
    
    IBEP20 public WNE;

    uint256 public constant DEVELOPER_RATE = 90; //per thousand
    uint256 public constant MARKETING_RATE = 10;
    uint256 public constant ADMIN_RATE = 10;
    uint256 public constant TEAM_RATE = 10;
    uint256[] public REFERRAL_PERCENTS = [1500, 1500, 800, 800, 600, 500, 500, 500, 400, 400, 400, 300, 300, 300, 200, 200, 200, 100, 100, 100];

    uint256 public constant TIME_STEP = 1 days;
    
    uint256 public START_DATE;
    
    uint256 public BNB_PER_SODA;
    uint256 public SODA_STAKED = 0;
    
    uint256 public constant SODA_PER_TICKET = 1e18; // 1 SODA
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;
    uint256 public LOTTERY_STEP = 12 hours; 
    uint256 public LOTTERY_START_TIME;
    
    uint256 public constant REFERRER_CODE = 7777; //default

    uint256 public constant MIN_INVESTMENT = 1e16; // 0.01 bnb

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private adminAccount_;
    address payable private teamAccount_;

    mapping(address => uint256) public address2UID; // address => user_id
    mapping(uint256 => Objects.Investor) public uid2Investor; // user_id => investor object
    
    mapping(uint256 => mapping(address => uint256)) public ticketOwners; // round => address => amount of owned tickets
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; // round => id => address
    
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);
    event onStake(address investor, uint256 amount);
    event onUnstake(address investor, uint256 amount);
    event onRefClaimed(address investor, uint256 amount);
    event onSwap(address investor, uint256 amount);
    event onLotteryWinner(address investor, uint256 pot);
    event onLotteryRewardsClaimed(address investor, uint256 rewards);

    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor(address payable adminAccount, address payable marketingAccount, address payable teamAccount, uint256 price, IBEP20 SODA_ADDRESS) public {
        developerAccount_ = msg.sender;
        marketingAccount_ = marketingAccount;
        adminAccount_ = adminAccount;
        teamAccount_ = teamAccount;
        
        BNB_PER_SODA = price.mul(1e16); // if price = 1, BNB_PER_SODA = 0.01 and so on 
        WNE = SODA_ADDRESS;
        
        START_DATE = block.timestamp;
        LOTTERY_START_TIME = block.timestamp;
        _init();
    }


    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }

    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
    }


    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = REFERRER_CODE;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].planCountSoda = 0;
        investmentPlans_.push(Objects.Plan(10, 200*60*60*24)); //1% per day for 200 days 
        investmentPlans_.push(Objects.Plan(12, 200*60*60*24)); //1.2% per day for 200 days



    }
    
    function getSodaPrice() public view returns(uint256) { // +0.2% per day (0.02)
        uint256 timeMultiplier = (block.timestamp.sub(START_DATE)).div(TIME_STEP); 
        
        uint256 sodaPrice = BNB_PER_SODA.add(BNB_PER_SODA.mul(timeMultiplier).mul(2).div(1000));
        
        return sodaPrice;
    }


    function getTotalInvestments() public  view returns (uint256){
        return totalInvestments_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }


    function _addInvestor(address payable _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            //require(uid2Investor[_referrerCode].addr != address(0), "Wrong referrer code");
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address payable addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].planCountSoda = 0;
        if (_referrerCode >= REFERRER_CODE) {
            
            uint256 upline = _referrerCode;
            
            for(uint256 i = 0; i < 20; i++){
                if(upline >=REFERRER_CODE){
                    
                    uid2Investor[upline].referrals = uid2Investor[upline].referrals.add(1);
                    upline = uid2Investor[upline].referrer;
                    
                } else break;
            }

        }
        return (latestReferrerCode);
    }

    function _invest(address payable _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        
        require(_amount>=MIN_INVESTMENT, "Wrong min investment");

        uint256 uid = address2UID[_addr];

        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        } else {//old user
            //do nothing, referrer is permenant
        }

        

        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        totalInvestments_ = totalInvestments_.add(_amount);

        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        uint256 adminPercentage = (_amount.mul(ADMIN_RATE)).div(1000);
        adminAccount_.transfer(adminPercentage);
        uint256 teamPercentage = (_amount.mul(TEAM_RATE)).div(1000);
        teamAccount_.transfer(teamPercentage);
        
        return true;
    }

    function _stake(address payable _addr, uint256 _planId, uint256 _amount) private returns(bool){
        require(WNE.balanceOf(_addr)>=_amount, "insufficient amount of soda token");

        uint256 uid = address2UID[_addr];

        if (uid == 0) {
            revert("You do not have active investment in bnb");
        }
        
        WNE.transferFrom(_addr, address(this), _amount);
         
        uint256 planCountSoda = uid2Investor[uid].planCountSoda;
        Objects.Investor storage investor = uid2Investor[uid];

        investor.plans_soda[planCountSoda].planId = _planId;
        investor.plans_soda[planCountSoda].investmentDate = block.timestamp;
        investor.plans_soda[planCountSoda].lastWithdrawalDate = block.timestamp;
        investor.plans_soda[planCountSoda].investment = _amount;
        investor.plans_soda[planCountSoda].currentDividends = 0;
        investor.plans_soda[planCountSoda].isExpired = false;

        investor.planCountSoda = investor.planCountSoda.add(1);

        SODA_STAKED = SODA_STAKED.add(_amount);


        return true;
    }


    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, 0, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function stake(uint256 _value) public {
        if(_stake(msg.sender,1,_value)){
            emit onStake(msg.sender, _value);
        }
    }

    function claimReward() public {
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        require(uid2Investor[uid].planCountSoda != 0, "Can not withdraw because no any investments in soda");
        uint256 withdrawalAmount = 0;

         for (uint256 i = 0; i < uid2Investor[uid].planCountSoda; i++) {
             if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

             Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans_soda[i].planId];

          
            bool isExpired = false;
             uint256 withdrawalDate = block.timestamp;
             if (plan.term > 0) {
                 uint256 endTime = uid2Investor[uid].plans_soda[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                     withdrawalDate = endTime;
                     isExpired = true;
                   
                 }
             }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans_soda[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans_soda[i].lastWithdrawalDate);
            

            withdrawalAmount += amount;
          
            uid2Investor[uid].plans_soda[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans_soda[i].isExpired = isExpired;
            uid2Investor[uid].plans_soda[i].currentDividends += amount;
         }
        
        uint256 payout = withdrawalAmount.mul(9).div(10); // 90%
        
        WNE.mint(msg.sender,payout);
        
        _calculateSodaReferrerReward(payout, uid2Investor[uid].referrer);
        _buyTickets(msg.sender, withdrawalAmount.sub(payout)); // 10% of withdrawal goes on tickets purchase
        
        emit onWithdraw(msg.sender, withdrawalAmount);
    }   


    function withdraw() public {
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because of no investments");
        uint256 withdrawalAmount = 0;

        

        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

          

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                   
                }
            }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate);
            

            withdrawalAmount += amount;
          
            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
        }
        
        uint256 sodaReward = withdrawalAmount.mul(1e18).div(BNB_PER_SODA);
        uint256 payout = sodaReward.mul(9).div(10); // 90% 
        
        WNE.mint(msg.sender,payout);
        
        _calculateSodaReferrerReward(payout, uid2Investor[uid].referrer);
        _buyTickets(msg.sender,sodaReward.sub(payout)); // 10% of withdrawal goes on tickets purchase
        

        emit onWithdraw(msg.sender, sodaReward);
    }

    function unstake() public {
        uint256 uid = address2UID[msg.sender];
        require(uid != 0,"Can not withdraw because of no investments");
        require(uid2Investor[uid].planCountSoda != 0,"nothing to unstake");
        
        uint256 body = 0;
        
        uint256 withdrawalAmount = 0;

         for (uint256 i = 0; i < uid2Investor[uid].planCountSoda; i++) {
             if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

             Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans_soda[i].planId];

          
            
             uint256 withdrawalDate = block.timestamp;
             if (plan.term > 0) {
                 uint256 endTime = uid2Investor[uid].plans_soda[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                     withdrawalDate = endTime;
                   
                 }
             }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans_soda[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans_soda[i].lastWithdrawalDate);
            

            withdrawalAmount += amount;
            body += uid2Investor[uid].plans_soda[i].investment;
          
            uid2Investor[uid].plans_soda[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans_soda[i].isExpired = true;
            uid2Investor[uid].plans_soda[i].currentDividends += amount;
         }
         
         uid2Investor[uid].planCountSoda = 0;
         
         uint256 payout = withdrawalAmount.mul(9).div(10); // 90%
         
         
         _calculateSodaReferrerReward(payout, uid2Investor[uid].referrer);
        
         
         
         WNE.transfer(msg.sender, body);
         WNE.mint(msg.sender, payout);
         
         _buyTickets(msg.sender, withdrawalAmount.sub(payout)); // 10% of withdrawal goes on tickets purchase
          
         SODA_STAKED = SODA_STAKED.sub(body);
         
        
         emit onUnstake(msg.sender, body);
        
        
    }

    function swap(uint256 _sodaAmount) public{
        require(WNE.balanceOf(msg.sender)>=_sodaAmount, "insufficient amount of soda token");

        uint256 price = getSodaPrice();
        uint256 payout = _sodaAmount.mul(price).div(1e18);

        WNE.transferFrom(msg.sender, address(this), _sodaAmount);

        msg.sender.transfer(payout);
        
        emit onSwap(msg.sender, payout);

    }
    
    function claimRef() public {
         uint256 uid = address2UID[msg.sender];
         require(uid != 0,"You are not registered");
         require(uid2Investor[uid].refRewardsToClaim !=0, "Nothing to claim");
         
         uint256 amount = uid2Investor[uid].refRewardsToClaim;
         
         WNE.mint(msg.sender,amount);
         
         uid2Investor[uid].refRewardsToClaim = 0;
         uid2Investor[uid].referrerSodaEarnings = uid2Investor[uid].referrerSodaEarnings.add(amount);
         
         emit onRefClaimed(msg.sender,amount);
    }
    
    function claimLotteryReward() public {
        uint256 uid = address2UID[msg.sender];
        require(uid != 0,"You are not registered");
        require(uid2Investor[uid].lotteryRewards !=0, "Nothing to claim");
        
        uint256 amount = uid2Investor[uid].lotteryRewards;
        
        WNE.mint(msg.sender, amount);
        
        uid2Investor[uid].lotteryRewards = 0;
        
        emit onLotteryRewardsClaimed(msg.sender, amount);
    }
    
    function _buyTickets(address userAddress, uint256 withdrawalAmount) private { // withdrawalAmount = 10% of initial withdrawal amount
    
        require(withdrawalAmount != 0, "zero withdrawal amount");
        
        uint256 tickets = withdrawalAmount.mul(SODA_PER_TICKET).div(1e18);
        
        if(ticketOwners[lotteryRound][userAddress] == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;
            participants = participants.add(1);
        }
        
        ticketOwners[lotteryRound][userAddress] = ticketOwners[lotteryRound][userAddress].add(tickets);
        currentPot = currentPot.add(withdrawalAmount);
        totalTickets = totalTickets.add(tickets);
        
        if(block.timestamp - LOTTERY_START_TIME >= LOTTERY_STEP){
            _chooseWinner(participants);
        }
    }
    
    function _chooseWinner(uint256 pt) private {
        
       uint256[] memory init_range = new uint256[](pt);
       uint256[] memory end_range = new uint256[](pt);
       
       uint256 last_range = 0;
       
       for(uint256 i = 0; i < pt; i++){
           uint256 range0 = last_range.add(1);
           uint256 range1 = range0.add(ticketOwners[lotteryRound][participantAdresses[lotteryRound][i]].div(1e18)); 
           
           init_range[i] = range0;
           end_range[i] = range1;
           
           last_range = range1;
       }
        
       uint256 random = _getRandom().mod(last_range).add(1); 
       
       for(uint256 i = 0; i < pt; i++){
           if((random >= init_range[i]) && (random <= end_range[i])){
               // winner found
               
               address winnerAddress = participantAdresses[lotteryRound][i];
               uint256 uid = address2UID[winnerAddress];
               
               uid2Investor[uid].lotteryRewards = uid2Investor[uid].lotteryRewards.add(currentPot.mul(9).div(10));
              
               // reset lotteryRound
               
               currentPot = 0;
               lotteryRound = lotteryRound.add(1);
               participants = 0;
               totalTickets = 0;
               LOTTERY_START_TIME = block.timestamp;
               
               emit onLotteryWinner(winnerAddress, uid2Investor[uid].lotteryRewards);

               break;
           }
       }
    }
    
    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,block.difficulty,currentPot)));
    }

    function _calculateSodaReferrerReward(uint256 _investment, uint256 _referrerCode) private {

       if (_referrerCode != 0) {
          address payable upline = uid2Investor[_referrerCode].addr; // upline`s address
          
          for(uint256 i = 0; i<20;i++){
              if(upline != address(0)){
                  uint256 amount = _investment.mul(REFERRAL_PERCENTS[i]).div(10000);
                  
                  uint256 uid = address2UID[upline]; // upline id
                  uid2Investor[uid].refRewardsToClaim = uid2Investor[uid].refRewardsToClaim.add(amount);
                  
                  uint256 upline_uid = uid2Investor[uid].referrer; // id upline`s upline
                  upline = uid2Investor[upline_uid].addr;
                  
              } else break;
          }
        }

    }
        
    

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns(uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    
    
    function getUserReferrer(address _userAddress) public view returns(uint256){
        uint256 uid = address2UID[_userAddress];
        
        return uid2Investor[uid].referrer;
    }
    
    function getUserReferralEarnings(address _userAddress) public view returns(uint256) {
        uint256 uid = address2UID[_userAddress];
        
        return uid2Investor[uid].referrerSodaEarnings;
    }
    
    function getUserAmountOfReferrals(address _userAddress) public view returns(uint256){
        uint256 uid = address2UID[_userAddress];
        
        return uid2Investor[uid].referrals;
    }
    
    function getUserSodaPoolReward(address _userAddress) public view returns(uint256){
        uint256 uid = address2UID[_userAddress];
        
        uint256 withdrawalAmount = 0;

         for (uint256 i = 0; i < uid2Investor[uid].planCountSoda; i++) {
             if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

             Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans_soda[i].planId];

          
             uint256 withdrawalDate = block.timestamp;
             if (plan.term > 0) {
                 uint256 endTime = uid2Investor[uid].plans_soda[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                     withdrawalDate = endTime;
                   
                 }
             }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans_soda[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans_soda[i].lastWithdrawalDate);
            

            withdrawalAmount += amount;
          
            
         }
         
         return withdrawalAmount;
        
    }
    
    function getUserBnbPoolReward(address _userAddress) public view returns(uint256){
        uint256 uid = address2UID[_userAddress];
        
       uint256 withdrawalAmount = 0;

        

        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

          

            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                   
                   
                }
            }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate);
            

            withdrawalAmount += amount;
          
     
        }
        
        uint256 sodaReward = withdrawalAmount.mul(1e18).div(BNB_PER_SODA);
        
        return sodaReward;
        
    }
    
    function getUserLotteryRewards(address _userAddress) public view returns(uint256) {
        uint256 uid = address2UID[_userAddress];
        
        return uid2Investor[uid].lotteryRewards;
    }

    function userTotalBnbInvestments(address _userAddress) public view returns(uint256) {
        uint256 uid = address2UID[_userAddress];
        
        uint256 amount = 0;
        
        for(uint256 i = 0; i < uid2Investor[uid].planCount; i++){
            amount = amount.add(uid2Investor[uid].plans[i].investment);
        }
        
        return amount;
    }
    
    function userTotalSodaInvestments(address _userAddress) public view returns(uint256) {
        uint256 uid = address2UID[_userAddress];
        
        uint256 amount = 0;
        
        for(uint256 i = 0; i < uid2Investor[uid].planCountSoda; i++){
            amount = amount.add(uid2Investor[uid].plans_soda[i].investment);
        }
        
        return amount;
    }
    
    function getAvailableRefEarnings(address _userAddress) public view returns(uint256) {
        uint256 uid = address2UID[_userAddress];
        
        return uid2Investor[uid].refRewardsToClaim;
    }
    
    function getUserTickets(address _userAddress) public view returns(uint256) {
         
         return ticketOwners[lotteryRound][_userAddress];
    }
    
    function getLotteryTimer() public view returns(uint256) {
        return LOTTERY_START_TIME.add(12 hours);
    }
    
    
}