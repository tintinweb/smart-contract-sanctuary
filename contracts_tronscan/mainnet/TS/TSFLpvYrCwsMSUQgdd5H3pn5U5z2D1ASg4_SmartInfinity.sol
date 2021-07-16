//SourceUnit: SmartInfinity.sol

pragma solidity 0.5.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract SmartInfinity{

    using SafeMath for uint256;

    struct user{
        uint256 id;
        address inviter;
        uint256 partnersCount;
        uint256 plan;
        uint256 treeId;
        uint256 regTime;
        mapping(uint256 => bool) PlanStatus;
        mapping(uint256 => uint256) TreeNo;
        mapping(uint256 => mapping(uint256 => userTree)) treeDetails;
    }

    struct userTree{
        address inviterAddr;
        address upline;
        address thirdUpline;
        uint256 coreCount;
        address[] firstDownlines;
        address[] ThirdDownlines;
        uint256 treeRegTime;
        uint256 earningsLimit;
        uint256 receivedAmount;
        uint256 earns;
        uint256 give;
        uint256 reinvestCount;
        uint256 reinvestTime;
        uint256 reinvestEligible;
        bool cycleStatus;
        bool coreStatus;
        mapping (uint256 => bool) PositionStatus;
    }
    struct planData {
        uint256 PlanUSDPrice;
        uint256 Limit;
        uint256 TreeCount;
        uint256[] tree_ids;
    }
    mapping(uint256 => mapping(uint256 => uint256)) internal totalTreeUser;
    mapping(address => user) public users;

    mapping(uint256 => planData) internal PlanDetails;
    mapping(uint256 => address) public users_ids;

    uint256 public totalPlan;
    uint256 public lastId;
    uint256 private trxUSDPrice;
    uint256 public  totalTree = 1;
    uint256 public total_deposited;
    bool public contractLockStatus = false;

    address payable public owner;
    address payable public commissionAddress1;
    address payable public commissionAddress2;
    address payable public commissionAddress3;
    address payable public charityAddress;
    address payable public stakeAddress;

    event _Register(address indexed _user,address indexed inviter,address indexed _upline,uint256 _plan,uint256 _tree,uint256 _amount, uint256 Time);
    event _UplineCheck(address indexed _user,address indexed _Upline,address indexed _receiver,uint256 plan,uint256 tree,uint256 Amount, uint256 Time);
    event _Sendtrx(address indexed Receiver,uint256 ReceiverId,uint256 Amount,uint256 Plan,uint256 tree, uint256 Time);
    event _FailSafe(address indexed _receiver,uint256 _amount, uint256 Time);
    event _commissionTrx(address indexed _commissionAddr,uint256 _amount);
    event _reinvest(address indexed _user,uint256 reinvestTime);
    event _injectedUser(address indexed _user,address indexed _inviter,uint256 _plan,uint256 _tree);

    constructor(
        address payable _owner,
        address payable _stakeAddr,
        address payable _charityAddr,
        address payable _commission1,
        address payable _commission2,
        address payable _commission3,
        uint256 _trxPrice
    ) public {

        owner = _owner;
        stakeAddress = _stakeAddr;
        commissionAddress1 = _commission1;
        commissionAddress2 = _commission2;
        commissionAddress3 = _commission3;
        charityAddress = _charityAddr;

        trxUSDPrice = _trxPrice;

        user memory userData = user({
            id: ++lastId,
            inviter: address(0),
            partnersCount:0,
            plan:3,
            treeId:1,
            regTime: block.timestamp
        });

        users[owner] = userData;
        users_ids[lastId] = owner;

        PlanInject(30, 31150500000);
        PlanInject(60, 62301000000);
        PlanInject(120, 124602000000); 
    }
    modifier OwnerOnly(){
        require(msg.sender == owner, "owner only accessible");
        _;
    }
    modifier contractLockCheck(){
        require(contractLockStatus != true, "inject is locked");
        _;
    }
    function currentTrxPriceForOneDoller() public view returns(uint256){
        return trxUSDPrice;
    }
    function userTreeStatus(address _user,uint256 plan) public view returns(uint256 treeNum){
        return users[_user].TreeNo[plan];
    }
    function treeUserCount(uint256 plan,uint256 tree) public view returns(uint256 totolUser){
        return totalTreeUser[plan][tree];
    }
    function trxPriceUpdate(uint256 amount) public OwnerOnly {
       require(amount != 0, "invalid amount");
       trxUSDPrice = amount;
    }
    function PlanInject(uint256 _planPrice,uint256 _limitedAmount) internal { 
        totalPlan++;
        PlanDetails[totalPlan].PlanUSDPrice = _planPrice;
        PlanDetails[totalPlan].Limit = _limitedAmount; 
        PlanDetails[totalPlan].TreeCount = totalTree;
        PlanDetails[totalPlan].tree_ids.push(totalTree);

        users[owner].PlanStatus[totalPlan] = true;
        users[owner].treeDetails[totalPlan][totalTree].treeRegTime = block.timestamp;
        totalTreeUser[totalPlan][totalTree] = totalTreeUser[totalPlan][totalTree].add(1);

        users[owner].treeDetails[totalPlan][totalTree].coreStatus = true;
        users[owner].treeDetails[totalPlan][totalTree].earningsLimit = (PlanDetails[totalPlan].Limit * trxUSDPrice)/ 1e6 ;
    }
    function TreeInject() public OwnerOnly{
        totalTree++;
        for(uint256 _Plan = 1; _Plan <= 3 ; _Plan++){
           PlanDetails[_Plan].TreeCount = totalTree ;
           PlanDetails[_Plan].tree_ids.push(totalTree);

           users[owner].treeDetails[_Plan][totalTree].treeRegTime = block.timestamp;
           totalTreeUser[_Plan][totalTree] = totalTreeUser[_Plan][totalTree].add(1);
        }
    }
    function injectUser(address _userAddr,address _inviter,uint256 _plan,uint256 _tree) public OwnerOnly{
        require(lastId < 22, "Unable to access this function");
        uint256 RegPrice = (PlanDetails[_plan].PlanUSDPrice * trxUSDPrice);
        
        regUser(_userAddr,_inviter,_plan,_tree, RegPrice,3);
        emit _injectedUser(_userAddr,_inviter,_plan,_tree);
    }
    function Register(uint256 id,uint256 plan,uint256 tree) external contractLockCheck payable  {
        
        uint256 RegPrice = (PlanDetails[plan].PlanUSDPrice * trxUSDPrice);
        
        require(users[msg.sender].treeDetails[plan][tree].treeRegTime == 0,"user already exists in this tree");
        
        if(users[msg.sender].id != 0) {
            require(users[msg.sender].partnersCount >=2, "Partners Count Invalid");
            require(users[msg.sender].treeId == tree, "Invalid tree id");
            regUser(msg.sender,users_ids[id],plan,tree, RegPrice,1);
           
        }else {
            require(users[msg.sender].id == 0,"userAddr already exists");
            require(plan == 1, "plan is Invalid");
            regUser(msg.sender,users_ids[id],plan,tree, RegPrice,1);
        }
    }
    function regUser(address userAddr,address inviter,uint256 _plan,uint256 _tree, uint256 checkPlanPrice,uint8 flag) internal{
        
        require((users[inviter].id != 0) && (users[inviter].treeDetails[_plan][_tree].treeRegTime != 0), "Referrals address is invalid");
        
        if(flag == 1){
            require(msg.value == checkPlanPrice, "Amount is invalid " );
        } 
        require((_plan <= totalPlan) && (_plan != 0), "Plan is invalid");
        require(_tree <= PlanDetails[_plan].TreeCount && _tree != 0, "Tree is invalid");        
        require(users[userAddr].TreeNo[_plan] == 0, "Already Exist in this Plan");
        require(users[userAddr].plan.add(1) == _plan, "Buy previous plan");

        if(users[userAddr].id == 0){
          user memory userData = user({
            id: ++lastId,
            inviter: inviter,
            partnersCount:0,
            plan: 0,
            treeId:_tree,
            regTime: block.timestamp
          });

          users[userAddr] = userData;
          users_ids[lastId] = userAddr;
        }
        users[userAddr].treeDetails[_plan][_tree].inviterAddr = inviter;
        users[userAddr].treeDetails[_plan][_tree].treeRegTime = block.timestamp;
        users[userAddr].treeDetails[_plan][_tree].earningsLimit = (PlanDetails[_plan].Limit * trxUSDPrice)/ 1e6 ;

        users[userAddr].PlanStatus[_plan] = true;
        users[userAddr].plan = users[userAddr].plan.add(1);
        users[userAddr].TreeNo[_plan] = _tree;

        users[inviter].partnersCount = users[inviter].partnersCount.add(1);  
        totalTreeUser[_plan][_tree] = totalTreeUser[_plan][_tree].add(1);

        updateUserPlace(userAddr,inviter,_plan,_tree,flag);

    }
    function updateUserPlace(address userAddr,address inviter,uint256 _plan,uint256 _tree,uint8 flag) internal{
        address coreAddr = coreSearch(inviter,_plan,_tree);
        
        address inviter_ = findFreeReferrer(coreAddr,_plan,_tree);
        users[userAddr].treeDetails[_plan][_tree].upline = inviter_;
        users[inviter_].treeDetails[_plan][_tree].firstDownlines.push(userAddr);
        if(users[inviter_].treeDetails[_plan][_tree].upline != address(0)){
            users[users[inviter_].treeDetails[_plan][_tree].upline].treeDetails[_plan][_tree].coreCount += 1;
        }
        
        address _ThirdRef = users[users[inviter_].treeDetails[_plan][_tree].upline].treeDetails[_plan][_tree].upline;
        
        if(_ThirdRef != address(0)){    
            UpdatePlan(userAddr,users[userAddr].id,inviter_,_ThirdRef,_plan,_tree,msg.value,flag);
        }else{
            if(flag == 2) return;
            
            Sendtrx(charityAddress,_plan,_tree,msg.value,flag);
        }
        emit _Register(userAddr,inviter,inviter_,_plan,_tree,msg.value, block.timestamp);
    }
    function coreSearch(address addr,uint256 plan,uint256 tree) internal view returns(address coreAdr){
        if(addr == owner){
            return addr;
        }
        if(users[addr].treeDetails[plan][tree].coreStatus == true){
            if(users[addr].treeDetails[plan][tree].coreCount == 4){
                return addr;
            }
            else{
               return coreSearch(users[addr].treeDetails[plan][tree].upline,plan,tree); 
            } 
        }else{
            return coreSearch(users[addr].treeDetails[plan][tree].upline,plan,tree);
        }
    }
    function findFreeReferrer(address _user,uint256 _plan,uint256 tree) internal view returns(address) {
        
        if(users[_user].treeDetails[_plan][tree].firstDownlines.length < 2) return _user;
        
        address[] memory refs = new address[](1024);
        
        refs[0] = users[_user].treeDetails[_plan][tree].firstDownlines[0];
        refs[1] = users[_user].treeDetails[_plan][tree].firstDownlines[1];

        for(uint16 i = 0; i < 1024; i++) {    
            if(users[refs[i]].treeDetails[_plan][tree].firstDownlines.length < 2) {
                return refs[i];
            }
            if(i < 511) {
                uint16 n = (i + 1) * 2;

                refs[n] = users[refs[i]].treeDetails[_plan][tree].firstDownlines[0];
                refs[n + 1] = users[refs[i]].treeDetails[_plan][tree].firstDownlines[1];
            }
        }
        revert("No free referrer");
    }
    function adminFee(uint256 amount) internal{
        uint256 first = amount.mul(2).div(100);
        uint256 second = amount.mul(2).div(100);
        uint256 third = amount.mul(1).div(100);
        
        require(address(uint160(commissionAddress1)).send(first), "Transaction Failed");
        require(address(uint160(commissionAddress2)).send(second), "Transaction Failed");
        require(address(uint160(commissionAddress3)).send(third), "Transaction Failed");
        emit _commissionTrx(commissionAddress1,first);
        emit _commissionTrx(commissionAddress2,second);
        emit _commissionTrx(commissionAddress3,third);
    }
    function Sendtrx(address _receiver,uint256 _plan,uint256 _tree,uint256 _amount,uint8 flag) private{

        total_deposited = total_deposited.add(_amount);

        uint256 withFee = _amount.mul(95).div(100); // 95%
        if(flag == 1) adminFee(_amount);

        if(_receiver != charityAddress){

            userTree storage userData =  users[_receiver].treeDetails[_plan][_tree];

            userData.earns = userData.earns.add(withFee);
            userData.receivedAmount = userData.receivedAmount.add(_amount);
            userData.reinvestEligible = userData.reinvestEligible.add(1);

            if(_receiver != owner){
               if(flag == 1) require(address(uint160(_receiver)).send(withFee), "Transaction Failed");
               
               emit _Sendtrx(_receiver,users[_receiver].id,withFee,_plan,_tree, block.timestamp);
            }else{
               if(flag == 1) require(address(uint160(stakeAddress)).send(withFee), "Transaction Failed");

               emit _Sendtrx(stakeAddress,1,withFee,_plan,_tree, block.timestamp);
            }
            if(userData.earns >= userData.earningsLimit && userData.reinvestEligible >= 1093){
                Reinvest(_receiver,_plan,_tree);
            }
        }else{
            require(address(uint160(charityAddress)).send(withFee), "Transaction Failed");
            emit _Sendtrx(charityAddress,0,withFee,_plan,_tree, block.timestamp);
        }
    }
    function Reinvest(address _userAdd,uint256 _plan,uint256 _tree) private{
        userTree storage userData =  users[_userAdd].treeDetails[_plan][_tree];

        userData.firstDownlines = new address[](0);
        userData.ThirdDownlines = new address[](0);
        userData.reinvestCount = userData.reinvestCount.add(1);
        userData.receivedAmount = 0;
        userData.earns = 0;
        userData.give = 0;
        userData.coreCount = 0;
        userData.reinvestTime = block.timestamp;
        userData.reinvestEligible = 0;

        if(users[owner].treeDetails[_plan][_tree].reinvestCount == 0){
            users[owner].treeDetails[_plan][_tree].reinvestCount += 1;
        }
        if(_userAdd != owner) {
            userData.cycleStatus = false;
            userData.coreStatus = false;
            address reinvestAddr = reinvestSearch(userData.inviterAddr,_tree,_plan);

            emit _reinvest(_userAdd,block.timestamp);
            return updateUserPlace(_userAdd ,reinvestAddr,_plan,_tree,2);
        }
    }
    function reinvestSearch(address _inviter,uint256 _tree,uint256 _plan) internal view returns(address reinvestAddr){
        if(_inviter == address(0)){
            return owner;
        }
        if(users[_inviter].treeDetails[_plan][_tree].reinvestCount != 0){
            return _inviter;
        }else{
            return reinvestSearch( users[_inviter].treeDetails[_plan][_tree].upline, _tree, _plan);
        }
    }
    function updatePlanDetails(uint256 _planId, uint256 _planPrice, uint256 _planLimit) public OwnerOnly returns(bool){
        require(_planId > 0 && _planId <= totalPlan,"Invalid Plan");
        PlanDetails[_planId].PlanUSDPrice = _planPrice;
        PlanDetails[_planId].Limit = _planLimit;
        return true;
    }
    function changeContractLockStatus(bool _status) public OwnerOnly returns(bool){
        contractLockStatus = _status;
        return true;
    }
    function failSafe(address payable _toUser, uint256 _amount) public OwnerOnly returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        emit _FailSafe(_toUser,_amount, block.timestamp);
        return true;
    }
    function viewDetails(address userAdd,uint256 _plantype,uint256 tree) public view returns(address inviterAddr,uint256 regtime,address upline,address thirdUplineAddress,address[] memory firstDownlines,address[] memory ThirdDownlines){
        address customerAddr = userAdd;
        return (users[userAdd].treeDetails[_plantype][tree].inviterAddr,users[userAdd].treeDetails[_plantype][tree].treeRegTime,users[customerAddr].treeDetails[_plantype][tree].upline,users[customerAddr].treeDetails[_plantype][tree].thirdUpline,users[userAdd].treeDetails[_plantype][tree].firstDownlines,users[customerAddr].treeDetails[_plantype][tree].ThirdDownlines);
    }
    function profitDetails(address userAdd,uint256 _plan,uint256 _tree) public view returns(uint256 ReceivedAmount,uint256 _Earns,uint256 _give,uint256 EarningLimit,uint256 _Reinvest,uint256 reinvestTime,uint256 reinvestEligible){
        userTree storage userData = users[userAdd].treeDetails[_plan][_tree];
        return (userData.receivedAmount,userData.earns,userData.give,userData.earningsLimit,userData.reinvestCount,userData.reinvestTime,userData.reinvestEligible);
    }
    function PlanAndTreeDetails(address _addr,uint256 plan,uint256 tree) public view returns(bool PlanStatus,bool treeStatus){
         PlanStatus = users[_addr].PlanStatus[plan];
         treeStatus = (users[_addr].treeDetails[plan][tree].treeRegTime != 0) ? true : false;
    }
    function PlanDetail(uint256 PlanId) public view returns(uint256 _PlanPrice,uint256 PlanLimit,uint256 treeCount,uint256[] memory _treeDetails){
        return (PlanDetails[PlanId].PlanUSDPrice,PlanDetails[PlanId].Limit,PlanDetails[PlanId].TreeCount,PlanDetails[PlanId].tree_ids);
    }
    function cycleView(address _userAdd,uint256 userId,uint256 _plantype,uint256 tree) public view returns(bool _cycle){
        return (users[_userAdd].treeDetails[_plantype][tree].PositionStatus[userId]);
    }    
    function UpdatePlan(address addr,uint256 userId,address Upline,address ThirdRef,uint256 plan,uint256 tree,uint256 amount,uint8 flag) internal {

        users[addr].treeDetails[plan][tree].thirdUpline = ThirdRef;
        users[ThirdRef].treeDetails[plan][tree].ThirdDownlines.push(addr); 
        
        if(users[ThirdRef].treeDetails[plan][tree].coreStatus == true){
            users[addr].treeDetails[plan][tree].coreStatus = true;
        }
        if(users[ThirdRef].treeDetails[plan][tree].ThirdDownlines.length <= 3){
            if(flag == 1 || flag == 3){
               Sendtrx(ThirdRef,plan,tree,amount,flag);   
            }
            emit _UplineCheck(addr,Upline,ThirdRef,plan,tree,amount, block.timestamp);
        }
        else if(users[ThirdRef].treeDetails[plan][tree].ThirdDownlines.length > 3){
            //
            users[addr].treeDetails[plan][tree].cycleStatus = true;
            
            (address _users,address RefAddress) = uplineStatusCheck(ThirdRef,users[ThirdRef].id,plan,tree);
            
            if(_users != owner){
               users[_users].treeDetails[plan][tree].give = users[_users].treeDetails[plan][tree].give.add(amount);   
            }
            users[_users].treeDetails[plan][tree].receivedAmount = users[_users].treeDetails[plan][tree].receivedAmount.add(amount);
            
            address SecondThirdRef = RefAddress != address(0) ? RefAddress : charityAddress;
            if(flag == 1 || flag == 3){
               Sendtrx(SecondThirdRef,plan,tree,amount,flag);   
            }
            emit _UplineCheck(addr,Upline,SecondThirdRef,plan,tree,amount, block.timestamp);
        }
        
        address PositionStatusAdd = users[ThirdRef].treeDetails[plan][tree].thirdUpline == address(0) ? address(0) : users[ThirdRef].treeDetails[plan][tree].thirdUpline ;
        
        if(PositionStatusAdd != address(0) &&  users[PositionStatusAdd].treeDetails[plan][tree].thirdUpline != address(0)){
            users[PositionStatusAdd].treeDetails[plan][tree].PositionStatus[userId] = true;
        }
    }
    function uplineStatusCheck(address userAddress,uint256 id,uint256 plan,uint256 tree) internal view returns(address _user,address Ref){
         if(userAddress == address(0)){
             return (userAddress,address(0));
         } 
         if (users[userAddress].treeDetails[plan][tree].cycleStatus != true || users[userAddress].treeDetails[plan][tree].PositionStatus[id] == true) {
             return (userAddress,users[userAddress].treeDetails[plan][tree].thirdUpline);
         }
         return uplineStatusCheck(users[userAddress].treeDetails[plan][tree].thirdUpline,id,plan,tree);   
    }
}