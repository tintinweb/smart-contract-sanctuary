//SourceUnit: Decenturn.sol

pragma solidity ^0.4.25;
import "./TRC20.sol";
import "./Ownable.sol";

library Objects {
    struct PositionData {
        uint256 planId;
        uint256 positionDate;
        uint256 positionSum;
        address TokenAddress;
        uint256 positionNum;
    }

    struct Plan {
        uint256 OptionPlan;
        uint256 term;
        bool LimitStatus;
        uint256 Limit;
        address TokenAddress;
        uint256 EndPositionNum;
        uint256 planSum;
        uint256 afterClosedSum;
        uint256 TotalTurnover;
    }
    
    struct RowStructures {
        uint256 IdPlan;
        address[] structuremassive;
        uint256 structurecount;
        uint256 closedpositions;
        uint256 alreadyposin;
        uint256 positionslastID;
    }
    
    struct RowTurnovers {
        address TokenAddress;
        uint256 Turnover;
    }
    
    struct RefInfo {
        uint256 Level;
        uint256 refCount;
        mapping(address => RowTurnovers) turnover;
    }
    
    struct RowAvailableBalances {
        address TokenAddress;
        uint256 reinvestsPlan;
        uint256 referrerEarnings;
        uint256 PlansEarnings;
        uint256 availableToWithdraw;
    }

    struct Investor {
        address addr;
        mapping(uint256 => RowAvailableBalances) balancesUser;
        uint256 referrerID;
        address referrerAddress;
        uint256 planCount;
        mapping(uint256 => PositionData) plans;
        mapping(uint256 => RefInfo) refinformation;
    }
}

contract DecenTurn is Ownable {
    using SafeMath for uint256;
    uint256 public START_DATE = 0;
    uint256 public LAST_ACTIVITY = block.timestamp;
    uint256 public constant REFERENCE_RATE = 33; // - 33%
    uint256 public constant REFERRER_CODE = 1000;
    uint256[] public ref_rewards;

    uint256 public latestReferrerCode;

    address private marketingAccount_;
    address private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;
    Objects.RowStructures[] private rowPlanstoarr_;
    Objects.RowAvailableBalances[] private rowBalances_;

    event onInvest(address investor, uint256 amount, address token);
    event onReInvest(address investor, uint256 amount, address token);
    event onInvestFromWaiting(address investor, uint256 amount, address token);
    event onWithdraw(address investor, uint256 amount, address token);
    event onReferralPayment(uint256 investor, uint256 referral, uint256 amount, address token);

    constructor() public {
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        _init();
    }

    function() external payable  {
        if (msg.value == 0) {

        } else {
           marketingAccount_.transfer(msg.value); // External send to marketing account
        }
    }

   // Start Project
    function START() public onlyOwner {
        require(START_DATE <= 0, "Contract already start");
        START_DATE = block.timestamp;
    }

    // Modify Marketing Account
    function setMarketingAccount(address _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }
    
    // The method allows you to withdraw the balance from the contract, provided that there has been no activity for more than 2 weeks
    function withdrawBalanceUnactivity(address _balanceToAddress, address TokenAddress) public payable onlyOwner {
        require(_balanceToAddress != address(0),"Wrong Address");
        require((LAST_ACTIVITY + 1209600) <= block.timestamp,"Matrix Contract is Active");
        
        if(TokenAddress == address(this) || TokenAddress == address(0)) {
        _balanceToAddress.transfer(address(this).balance);
        } else {
        TRC20(TokenAddress).transfer(_balanceToAddress,TRC20(TokenAddress).balanceOf(address(this)));
        }
    }

    // Get MarketingAccount
    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }

    // Add Plan
    function addNewPlan(uint256 _plantoEndnum, bool _LimitStatus, uint256 _Limit, address _TokenAddress, uint256 _planSum, uint256 _planRewardSum) public onlyOwner returns (uint256){
        if(_TokenAddress == 0 || _TokenAddress == address(0)) { _TokenAddress = address(this); } 
        address[] memory arressd = new address[](1);
        arressd[0] = marketingAccount_;
        uint256 _planId = rowPlanstoarr_.length;
        Objects.Investor storage investor = uid2Investor[REFERRER_CODE];
        rowPlanstoarr_.push(Objects.RowStructures(_planId,arressd,1,0,0,1));
        investor.plans[investor.planCount].planId = _planId;
        investor.plans[investor.planCount].positionDate = block.timestamp;
        investor.plans[investor.planCount].positionSum = _planSum;
        investor.plans[investor.planCount].TokenAddress = _TokenAddress;
        investor.plans[investor.planCount].positionNum = 1;
        investor.planCount = investor.planCount.add(1);
        return investmentPlans_.push(Objects.Plan(_planId, 0, _LimitStatus, _Limit, _TokenAddress, _plantoEndnum, _planSum,_planRewardSum,0)); 
    }

    /**
    Modify refference account
    */
    function setReferenceAccount(address _newReferenceAccount) public onlyOwner {
        require(_newReferenceAccount != address(0));
        referenceAccount_ = _newReferenceAccount;
    }
    /**
     Get refference account
    */
    function getReferenceAccount() public view onlyOwner returns (address) {
        return referenceAccount_;
    }


    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrerID = 0;
        uid2Investor[latestReferrerCode].referrerAddress = address(0);
        uid2Investor[latestReferrerCode].planCount = 0;
        ref_rewards.push(10);
        ref_rewards.push(8);
        ref_rewards.push(5);
        ref_rewards.push(5);
        ref_rewards.push(5);
    }

    // Gat all plans
    function getCurrentPlans() public view returns (uint256[] memory ID, uint256[] memory Term, uint256[] memory PositionToEnd, uint256[] memory PlanSum, uint256[] memory RewardSum, uint256[] memory StructureCount, uint256[] memory ClosedPositions) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory terms = new uint256[](investmentPlans_.length);
        uint256[] memory endpos = new uint256[](investmentPlans_.length);
        uint256[] memory possum = new uint256[](investmentPlans_.length);
        uint256[] memory rewardsum = new uint256[](investmentPlans_.length);
        uint256[] memory positionsinPlan = new uint256[](investmentPlans_.length);
        uint256[] memory reinvestsPlan = new uint256[](investmentPlans_.length);
        
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            terms[i] = plan.term;
            endpos[i] = plan.EndPositionNum;
            possum[i] = plan.planSum;
            rewardsum[i] = plan.afterClosedSum;
            positionsinPlan[i] = rowPlanstoarr_[i].structurecount;
            reinvestsPlan[i] = rowPlanstoarr_[i].closedpositions;
        }
        return
        (
        ids,
        terms,
        endpos,
        possum,
        rewardsum,
        positionsinPlan,
        reinvestsPlan
        );
    }
        // Get info Plan
    function getInfoByPlanId(uint256 _planId) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256, address, uint256) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong position plan id");
        Objects.Plan storage plan = investmentPlans_[_planId];
        return
        (
        _planId,
        plan.OptionPlan,
        plan.term,
        plan.EndPositionNum,
        plan.planSum,
        plan.afterClosedSum,
        plan.LimitStatus,
        plan.Limit,
        plan.TokenAddress,
        plan.TotalTurnover
        ); 
    }


     // GET Referral info by token  (IF address == contract adrress then get TRX balance)
    function getInfoReferralByToken(uint256 _uid, address _tokenAddress) public view returns (address TokenAddress, uint256[] memory RefByLevel, uint256[] memory TurnoverByLevel) {
       if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
       // if(LevelFrom > 0) { LevelFrom = LevelFrom.sub(1); }
      // require(LevelFrom <= ref_rewards.length && LevelTo <= ref_rewards.length && LevelFrom <= LevelTo,"Wrong referral Level");
      // uint256 levelscount = LevelTo.sub(LevelFrom);
      uint256 levelscount = ref_rewards.length;
     //  if(levelscount <= 0) { levelscount = 1; }
       
       uint256[] memory refByLevels = new  uint256[](levelscount);
       uint256[] memory turnoverByLevels = new  uint256[](levelscount);
       if(_tokenAddress == address(0)) {
        _tokenAddress = address(this);
       }
         Objects.Investor storage investor = uid2Investor[_uid];
         
        for (uint256 i = 0; i < levelscount; i++) {
             refByLevels[i] = refByLevels[i].add(investor.refinformation[i].refCount);
             turnoverByLevels[i] = turnoverByLevels[i].add(investor.refinformation[i].turnover[_tokenAddress].Turnover);
        }
         
        return
        (
        _tokenAddress,
        refByLevels,
        turnoverByLevels
        ); 
    }


    // Get all turnover by token address (IF address == contract adrress then get TRX balance)
    function getTotalTurnoverToken(address _tokenAddress) public view returns (uint256 TotalTokenTurnover){
        uint256 totalTurover = 0;
         if(_tokenAddress == address(0)) {
             _tokenAddress = address(this);
         }
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            if(investmentPlans_[i].TokenAddress == _tokenAddress) {
               totalTurover = totalTurover.add(investmentPlans_[i].TotalTurnover);
            }
        }
        return totalTurover;
    }

     // Get count of all positions in plan
    function getAlreadyPos(uint256 _planId) public view returns (uint256){
        return rowPlanstoarr_[_planId].alreadyposin;
    }
    
     // Get last addresses in line plan
    function getLineAddressesinPlan(uint256 _planId, uint256 _collAddressBefore, uint256 _collAddressAfter) public view returns (uint256 AllStructure,uint256 ClosedPositions,address[] memory BeforeStructure,address CurrentAddress,address[] memory AfterStructure) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong position plan id");
        require(_collAddressBefore <= 100 && _collAddressAfter <= 100, "Max count 100");
        if(rowPlanstoarr_[_planId].closedpositions < _collAddressBefore) {  _collAddressBefore = rowPlanstoarr_[_planId].closedpositions; }
        
        if(rowPlanstoarr_[_planId].structurecount > rowPlanstoarr_[_planId].closedpositions.add(1)) {
        if(_collAddressAfter > rowPlanstoarr_[_planId].structurecount.sub(rowPlanstoarr_[_planId].closedpositions.add(1))) {
            _collAddressAfter = _collAddressAfter.sub(rowPlanstoarr_[_planId].structurecount.sub(rowPlanstoarr_[_planId].closedpositions));
        }
        
        
        } else {
        _collAddressAfter = 0;
        }
        
        address[] memory BeforeAddresses = new address[](_collAddressBefore);
        address[] memory AfterAddresses = new address[](_collAddressAfter);
        
        for (uint256 i = 0; i < _collAddressBefore; i++) {
            if(rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions.sub(i.add(1))] == address(0)) { break; }
            BeforeAddresses[i] = rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions.sub(i.add(1))];
        }
        
        for (i = 0; i < _collAddressAfter; i++) {
            if(rowPlanstoarr_[_planId].structurecount > rowPlanstoarr_[_planId].closedpositions.add(i.add(1))) {
            if(rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions.add(i.add(1))] == address(0)) { break; }
            AfterAddresses[i] = rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions.add(i.add(1))];
            }
        }
        
        return (rowPlanstoarr_[_planId].structurecount, rowPlanstoarr_[_planId].closedpositions, BeforeAddresses, rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions], AfterAddresses);
    }

    // Get token balance in contract
    function getBalance(address _tokenAddress) public view returns (uint256) {
        if(_tokenAddress == address(0) || _tokenAddress == address(this)) {
        return address(this).balance;
        } else {
        return TRC20(_tokenAddress).balanceOf(address(this));
        }
    }
    
    // Gat balances in tokens
    function getBalanceUserTokens(address _tokenAddress, address _userAddress) public view returns (uint256 Balance) {
        if(_tokenAddress == 0 || _tokenAddress == address(this)) {
        return address(this).balance;
        } else {
        return TRC20(_tokenAddress).balanceOf(address(_userAddress));
        }
    }

    // Get user ID by Address
    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

//Get user info
    function getUserInfoByUID(uint256 _uid) public view returns (uint256 Referrer, address ReferrerAddress, uint256[] memory RefByLevels, uint256 PlanCount) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory refByLevels = new  uint256[](ref_rewards.length);
        for (uint256 i = 0; i < ref_rewards.length; i++) {
        refByLevels[i] = refByLevels[i].add(investor.refinformation[i].refCount);
        }
        
        return
        (
        investor.referrerID,
        investor.referrerAddress,
        refByLevels,
        investor.planCount
        );
    }
    
    //Get user balances
    function getUserBalancesByUID(uint256 _uid, address _TokenAddress) public view returns (address TokenAddress,uint256 AllReferral,uint256 AllMarketingEarnings,uint256 AllAvailableWithdraw) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        
        uint256 allreferral = 0;
        uint256 allprofitplans = 0;
        uint256 allaviabletowithdraw = 0;

        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            if(investmentPlans_[i].TokenAddress == _TokenAddress) {
                allreferral = allreferral.add(investor.balancesUser[i].referrerEarnings);
                allprofitplans = allprofitplans.add(investor.balancesUser[i].PlansEarnings);
                allaviabletowithdraw = allaviabletowithdraw.add(investor.balancesUser[i].availableToWithdraw);
            }
        }
        
        return
        (
        _TokenAddress,
        allreferral,
        allprofitplans,
        allaviabletowithdraw
        );
    }
    
    // Get info for available balances in plan
    function getBalanceByPlan(uint256 _planId) public view returns (address TokenAddress,uint256 AllReferral,uint256 AllMarketingEarnings,uint256 AllAvailableWithdraw) {
        Objects.Investor storage investor = uid2Investor[address2UID[msg.sender]];
        uint256 allreferral = investor.balancesUser[_planId].referrerEarnings;
        uint256 allprofitplans = investor.balancesUser[_planId].PlansEarnings;
        uint256 allaviabletowithdraw = investor.balancesUser[_planId].availableToWithdraw;
        
        return
        (
        investmentPlans_[_planId].TokenAddress,
        allreferral,
        allprofitplans,
        allaviabletowithdraw
        );
    }
    
    // Get info for available balances
     function getUserAvailableWithdraw(uint256 _uid, address _TokenAddress) private view returns (uint256) {
        require(address2UID[msg.sender] == _uid, "only self can check.");
        Objects.Investor storage investor = uid2Investor[_uid];

        uint256 allaviabletowithdraw = 0;

        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            if(investmentPlans_[i].TokenAddress == _TokenAddress) {
                allaviabletowithdraw = allaviabletowithdraw.add(investor.balancesUser[i].availableToWithdraw);
            }
        }
        
        return allaviabletowithdraw;
    }
    
    // Set zero balances function
    function withdrawablesetzero(uint256 _uid, address _TokenAddress) private returns (bool) {
        require(address2UID[msg.sender] == _uid, "only self can check.");
        Objects.Investor storage investor = uid2Investor[_uid];

        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            if(investmentPlans_[i].TokenAddress == _TokenAddress) {
                investor.balancesUser[i].availableToWithdraw = 0;
            }
        }
        return true;
    }
    
// Get plans info by user id
    function getLinePlanByUID(uint256 _uid) public view returns (uint256[] memory PlanId, uint256[] memory Date, uint256[] memory PositionSum, uint256[] memory PositionNum, uint256[] memory PlanReinvests) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory positionnum = new  uint256[](investor.planCount);
        uint256[] memory planreinvests = new  uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].positionDate!=0,"wrong position date");
            planIds[i] = investor.plans[i].planId;
            investmentDates[i] = investor.plans[i].positionDate;
            investments[i] = investor.plans[i].positionSum;
            positionnum[i] = investor.plans[i].positionNum;
            planreinvests[i] = investor.balancesUser[investor.plans[i].planId].reinvestsPlan;
        }

        return
        (
        planIds,
        investmentDates,
        investments,
        positionnum,
        planreinvests
        );
    }
    
    function getColUserPlacesInPlan(uint256 _uid, uint256 _planId) private view returns (uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        uint256 colpositions = 0;
        Objects.Investor storage investor = uid2Investor[_uid];
        
        for (uint256 i = 0; i < investor.planCount; i++) {
            if(investor.plans[i].planId == _planId) {
                colpositions = colpositions.add(1);
            }
        }
        
return colpositions;
    }

 // Change Plan limit
    function addPlanLimit(uint256 _planId, uint256 _LimitSet) public onlyOwner returns(uint256 Limit) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong position plan id");
        require(_LimitSet >= 0, "Uncorrect set limit value");
        investmentPlans_[_planId].Limit = investmentPlans_[_planId].Limit.add(_LimitSet);
        return investmentPlans_[_planId].Limit;
    }
    
    function togglePlanLimit(uint256 _planId, bool _ToggleLimit) public onlyOwner {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong position plan id");
        investmentPlans_[_planId].LimitStatus = _ToggleLimit;
    }
    
    // Withdraw all available balance
function withdraw(address TokenAddress) public payable returns (bool) {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        address addrs_ = msg.sender;
        uint256 uid = address2UID[addrs_];
        require(uid != 0, "Can not withdraw because no any positions");
        
        if(TokenAddress == address(0) || TokenAddress == address(this)) {
        uint256 withdrawalAmount = getUserAvailableWithdraw(uid, address(this));
            require(withdrawalAmount > 0, "Your balance is empty");
            require(withdrawablesetzero(uid, address(this)),"Error set Zero balance");
            addrs_.transfer(withdrawalAmount);
        
        } else {
            withdrawalAmount = getUserAvailableWithdraw(uid, TokenAddress);
            require(withdrawalAmount > 0, "Your balance is empty");
            require(withdrawablesetzero(uid, TokenAddress),"Error set Zero balance");
            
            TRC20(TokenAddress).transfer(msg.sender,withdrawalAmount);
            
        }
        
        
        emit onWithdraw(addrs_, withdrawalAmount, TokenAddress);
        return true;
  }

//TRC20 tokens get allowance
function allowance(TRC20 token, address owner, address spender) public view returns (uint256) {
      return token.allowance(owner,spender);
}
    
    
//TRC20 tokens transfer
function TRC20Transfer(address token, address transferfrom, address transferto, uint256 tokens) private returns (bool) {
    return TRC20(token).transferFrom(transferfrom,transferto,tokens);
}
    
    function invest(address _referrerAddress, uint256 _planId) public payable returns (bool) {
    require(START_DATE > 0, "Contract is not Started");
    require(getColUserPlacesInPlan(address2UID[msg.sender],_planId) <= 0, "You already have position in this plan");
        if(_planId > 0) {
    require(getColUserPlacesInPlan(address2UID[msg.sender],_planId.sub(1)) > 0, "You need previous plan before buy it");
        }
    require(_referrerAddress != msg.sender, "Wrong Refferer Address");
        
        uint256 uidRefference = address2UID[_referrerAddress];
        if(uidRefference == 0) { uidRefference = REFERRER_CODE; }
        
      if(investmentPlans_[_planId].TokenAddress == address(0) || investmentPlans_[_planId].TokenAddress == address(this)) {
        if (_invest(msg.sender, _planId, uidRefference, _referrerAddress, msg.value)) {
            emit onInvest(msg.sender, msg.value, investmentPlans_[_planId].TokenAddress);
            return true;
        }
      } else {  
        require(getBalanceUserTokens(investmentPlans_[_planId].TokenAddress, msg.sender) >= investmentPlans_[_planId].planSum, "Not enought balance");
        require(TRC20(investmentPlans_[_planId].TokenAddress).allowance(msg.sender,address(this)) >= investmentPlans_[_planId].planSum, "Check the token allowance");

        if (_invest(msg.sender, _planId, uidRefference, _referrerAddress, investmentPlans_[_planId].planSum)) {
            emit onInvest(msg.sender, msg.value, investmentPlans_[_planId].TokenAddress);
            return true;
        }
        
      
      }
    }

    function _Registration(address _addr, uint256 _referrerCode, address _referrerAddress) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrerID = _referrerCode;
        uid2Investor[latestReferrerCode].referrerAddress = _referrerAddress;
        uid2Investor[latestReferrerCode].planCount = 0;
        
        if (_referrerCode  >= REFERRER_CODE) {
            uint256 up = _referrerCode;
            
          for(uint256 i = 0; i < ref_rewards.length; i++) {
            if(up == 0) break;
            
            uid2Investor[up].refinformation[i].refCount = uid2Investor[up].refinformation[i].refCount.add(1);

            up = uid2Investor[up].referrerID;
          }

        }
        
        return (latestReferrerCode);
    }
    
    
    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, address _referrerAddress, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong position plan id"); // Check plan id
        require(_amount == investmentPlans_[_planId].planSum, "Wrong amount of plan requirement"); //Check amount of plan
        require(investmentPlans_[_planId].Limit > 0 && investmentPlans_[_planId].LimitStatus || !investmentPlans_[_planId].LimitStatus, "This Plan out of Limit,please wait");
        if(investmentPlans_[_planId].TokenAddress != address(0) && investmentPlans_[_planId].TokenAddress != address(this)) {
        require(TRC20Transfer(investmentPlans_[_planId].TokenAddress,msg.sender,address(this),investmentPlans_[_planId].planSum), "Transfer error");
        }
        uint256 uid = address2UID[_addr]; // Select Investor  ID
        //require(uid != 0, "You are not register");
        if (uid == 0) {
            uid = _Registration(_addr, _referrerCode, _referrerAddress); // If Investor is not register then register new user and get ID
            //new user
        } else {
            //old user
            //do nothing, referrer is permanent
        }
        
        LAST_ACTIVITY = block.timestamp; // Update last activity
        
        uint256 planCount = uid2Investor[uid].planCount; // Select count of investor plans 
        Objects.Investor storage investor = uid2Investor[uid]; // Get massive of investor
        investor.plans[planCount].planId = _planId; // Set planId of this investment
        investor.plans[planCount].positionDate = block.timestamp; // Set Date of this investment
        investor.plans[planCount].positionSum = _amount; //Set Amount of this investment
        investor.planCount = investor.planCount.add(1); //Increase count of investor plans 
        investor.balancesUser[_planId].TokenAddress = investmentPlans_[_planId].TokenAddress; // Update balance TokenAddress of this investment plan
        _calculateReferrerReward(_amount, uid, _planId, investmentPlans_[_planId].TokenAddress); // Get all refferal earnings
        investmentPlans_[_planId].TotalTurnover = investmentPlans_[_planId].TotalTurnover.add(_amount); // Increase total turnover of this investment plan
        
        
    if(rowPlanstoarr_[_planId].structuremassive.length != 0) { //Check structure in plan, if no in structure
    rowPlanstoarr_[_planId].alreadyposin = rowPlanstoarr_[_planId].alreadyposin.add(1);  // Set Positions To Earning +1
    }
    
if(rowPlanstoarr_[_planId].alreadyposin >= investmentPlans_[_planId].EndPositionNum) { // If Positions To Earning more OR = than  Config Plan Count to Earn (structure is closing) Than make reinvest
    rowPlanstoarr_[_planId].structuremassive.push(msg.sender); // Push investor address to structure
    rowPlanstoarr_[_planId].positionslastID = rowPlanstoarr_[_planId].positionslastID.add(1); // Position last id increase
    rowPlanstoarr_[_planId].structurecount = rowPlanstoarr_[_planId].structurecount.add(1); // Structure Count increase
    investor.plans[planCount].positionNum = rowPlanstoarr_[_planId].positionslastID; // Set investment position ID
    uint256 SumToUser = investmentPlans_[_planId].afterClosedSum; // Get sum of earning
    uint256 uidtoearn = address2UID[rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions]]; // Get First structure address in line
    Objects.Investor storage investorearn = uid2Investor[uidtoearn]; // Get massive of first address in line
    investorearn.balancesUser[_planId].PlansEarnings = investorearn.balancesUser[_planId].PlansEarnings.add(SumToUser); //First Address account Add to stat of earnings
    investorearn.balancesUser[_planId].availableToWithdraw = investorearn.balancesUser[_planId].availableToWithdraw.add(SumToUser); //First Address account Add to allowed withdraw
    investorearn.balancesUser[_planId].reinvestsPlan = investorearn.balancesUser[_planId].reinvestsPlan.add(1); //Increase amount of reinvests in plan
    _calculateReferrerReward(_amount, uidtoearn, _planId, investmentPlans_[_planId].TokenAddress); // Refferal earnings from reinvest
    rowPlanstoarr_[_planId].structuremassive.push(rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions]); // Structure reinvest, set first address in line to end line, Push reinvest address 
    rowPlanstoarr_[_planId].alreadyposin = 1; // Set reinvest like one already position in plan
    rowPlanstoarr_[_planId].closedpositions = rowPlanstoarr_[_planId].closedpositions.add(1); // Increase amount of closed positions in plan, set next first address in line
    emit onReInvest(rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].closedpositions.sub(1)], investmentPlans_[_planId].planSum, investmentPlans_[_planId].TokenAddress); // EMIT
    
} else { // Else if structure is not closing
    rowPlanstoarr_[_planId].structuremassive.push(msg.sender); // Push investor address to structure
    rowPlanstoarr_[_planId].structurecount = rowPlanstoarr_[_planId].structurecount.add(1); // Structure Count increase
    rowPlanstoarr_[_planId].positionslastID = rowPlanstoarr_[_planId].positionslastID.add(1); // Position last id increase
    investor.plans[planCount].positionNum = rowPlanstoarr_[_planId].positionslastID; // Set investment position ID
}
investmentPlans_[_planId].Limit = investmentPlans_[_planId].Limit.sub(1);  // Sub limit in plan
        
        return true;
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _uid, uint256 _planId, address TokenAddress) private {

        uint256 _allReferrerAmount = _investment.mul(REFERENCE_RATE).div(100);
        Objects.Investor storage investor = uid2Investor[_uid];
            
        if (investor.referrerID != 0 && investor.referrerID >= REFERRER_CODE) {
            uint256 up = investor.referrerID;
            if(investor.referrerID != address2UID[investor.referrerAddress] && address2UID[investor.referrerAddress] != investor.referrerID && address2UID[investor.referrerAddress] != 0 && investor.referrerAddress != address(0)) {
            up = address2UID[investor.referrerAddress];
            investor.referrerID = up;
        }
            
          for(uint256 i = 0; i < ref_rewards.length; i++) {
              
            if(uid2Investor[_uid].referrerID != address2UID[investor.referrerAddress] && i == 0 && address2UID[investor.referrerAddress] == 0 && investor.referrerAddress != address(0)) {
                
            uint256 reward = _investment.mul(ref_rewards[i]).div(100);
            
            if(TokenAddress == address(0) || TokenAddress == address(this)) {
            investor.referrerAddress.transfer(reward);
            } else {
            TRC20(TokenAddress).transfer(investor.referrerAddress,reward);
            }
            _allReferrerAmount = _allReferrerAmount.sub(reward);
            emit onReferralPayment(up, _uid, reward, TokenAddress);
            up = REFERRER_CODE; 
            } else {
            if(up == 0) break;
           
            Objects.Investor storage investorref = uid2Investor[up];
            
            reward = _investment.mul(ref_rewards[i]).div(100);
            
            investorref.balancesUser[_planId].referrerEarnings = investorref.balancesUser[_planId].referrerEarnings.add(reward);
            investorref.balancesUser[_planId].availableToWithdraw = investorref.balancesUser[_planId].availableToWithdraw.add(reward);
            investorref.refinformation[i].turnover[TokenAddress].Turnover = investorref.refinformation[i].turnover[TokenAddress].Turnover.add(reward);
            
            _allReferrerAmount = _allReferrerAmount.sub(reward);
            
            emit onReferralPayment(up, _uid, reward, TokenAddress);
            up = uid2Investor[up].referrerID;
            }
          }

        }

        if (_allReferrerAmount > 0) {
            uint256 IDreferrence = address2UID[referenceAccount_];
            Objects.Investor storage referrenceinv = uid2Investor[IDreferrence];
            referrenceinv.balancesUser[_planId].referrerEarnings = referrenceinv.balancesUser[_planId].referrerEarnings.add(_allReferrerAmount);
            referrenceinv.balancesUser[_planId].availableToWithdraw = referrenceinv.balancesUser[_planId].availableToWithdraw.add(_allReferrerAmount);

        }
    }

}

//SourceUnit: Ownable.sol

pragma solidity 0.4.25;

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity 0.4.25;

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
        uint256 c = a / b;
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

//SourceUnit: TRC20.sol

pragma solidity 0.4.25;
import "./SafeMath.sol";

interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(
        address owner,
        address spender
    )
    public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    returns (bool)
    {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}