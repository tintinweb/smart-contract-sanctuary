//SourceUnit: lauchV6.sol

pragma solidity ^0.5.0;
// pragma experimental ABIEncoderV2;

contract TRC20 {

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

contract TronPlusLaunchPoolV5 {

  struct Member {
    bool exists;
    uint256 uplineId;
    address addr;
    uint256 id;
    uint256 partners;
    uint256 totalRevenue;
  }

  struct  Stacking {
    bool isReceiveBonus;
    uint256 dayOfWithdraw;
    uint256 lastDeposit;
    uint256 lastTimeWithdraw;
    uint256 lastTimeDeposit;
    uint256 currentIncome;
    uint256 profitSystem;
    uint256 profitReference;
    uint256 totalReceive;
  }
  uint256 public totalMember;
  mapping (uint256 => Member) public members;
  mapping (uint256 => Stacking) public stacking;
  mapping (address => uint256) public userId;
  function  getSystems(uint256 _userId, uint8 _level) public view returns(uint256);
}


contract TronPlusLaunchPoolV6 {
  address payable owner;
  address payable dev;
  address payable _contractAddr;

  bool public isUpdateCardNFTs = false;
  TRC20 USDT;
  TRC20 TRP;
  TRC20 EDFI;

  TronPlusLaunchPoolV5 v5;

  uint public EDFIConvert = 1000;
  uint public TRPConvert = 10;
  uint public percent = 100;
  bool public sync = true;

  struct Member {
    bool exists;
    uint256 uplineId;
    address addr;
    uint256 id;
    uint256 partners;
    uint256 totalRevenue;
  }

  struct  Stacking {
    bool isReceiveBonus;
    uint256 dayOfWithdraw;
    uint256 lastDeposit;
    uint256 lastTimeWithdraw;
    uint256 lastTimeDeposit;
    uint256 currentIncome;
    uint256 profitSystem;
    uint256 profitReference;
    uint256 totalReceive;
  }
  
  struct Card {
    uint256 card;
    uint256 startDate;
    uint256 endDate;    
  }
  
  mapping (uint256 => Member) public members;
  mapping (uint256 => Stacking) public stacking;
  mapping (uint256 => Card) public card1;
  mapping (uint256 => Card) public card2;
  mapping (address => uint256) public userId;
  mapping (uint256 => uint8) public rewards;
  mapping (uint => uint) public packageToRewards;
  mapping (uint8 => uint256) public maching_bonus;
  mapping (uint256 => mapping (uint8 => uint256)) public systems;
    
  uint256 public totalMember = 1;
    
  event StakingTRP(address indexed addr, uint256 value, address ref);
  event StakingEDFI(address indexed addr, uint256 value, address ref);
  
  constructor (
    address payable _owner,
    address payable trpContract,
    address payable edfiContract,
    address payable usdtContract,
    address payable tronplusLaunchV5
    ) public {
    owner = _owner;
    dev = msg.sender;
    TRP = TRC20(trpContract);
    EDFI = TRC20(edfiContract);
    USDT = TRC20(usdtContract);
    v5 = TronPlusLaunchPoolV5(tronplusLaunchV5);
    maching_bonus[1] = 10;
    maching_bonus[2] = 5;
    maching_bonus[3] = 2;
    maching_bonus[4] = 2;
    maching_bonus[5] = 2;
    maching_bonus[6] = 1;
    maching_bonus[7] = 1;
    maching_bonus[8] = 1;
    maching_bonus[9] = 1;
    maching_bonus[10] = 1;
    maching_bonus[11] = 1;
    maching_bonus[12] = 1;
    maching_bonus[13] = 1;
    maching_bonus[14] = 1;
    maching_bonus[15] = 1;
    maching_bonus[16] = 1;
    maching_bonus[17] = 1;
    maching_bonus[18] = 1;
    packageToRewards[1000 trx] = 667;
    packageToRewards[5000 trx] = 667;
    packageToRewards[10000 trx] = 667;
  }

  
  function stakingTRP(address _ref, uint256 _package)  public returns(bool) {
    require (_package == 1000 trx || _package == 5000 trx || _package == 10000 trx, "Package is not correctly");
    if(userId[msg.sender] == 0){
          require (userId[_ref] > 0, "Upline not found");
        _register(msg.sender, _ref);
    }
    require (!stacking[userId[msg.sender]].isReceiveBonus, "Staking Only One Time");

    uint256 _avaiable = TRP.allowance(msg.sender, address(this)) * TRPConvert / percent;
    uint256 _usdtAvaiable = USDT.allowance(msg.sender, address(this));
    if(_avaiable * 2 >= _package && _usdtAvaiable * 2 >= _package ){
      TRP.transferFrom(msg.sender, address(this), getPrice( _package, TRPConvert));
      USDT.transferFrom(msg.sender,address(this), _package / 2);
      _addStacking(userId[msg.sender], _package);
       stacking[userId[_ref]].profitReference += _package * 5 / 100;
       emit StakingTRP(msg.sender,_package, _ref );
       return true;
    } {
      return false;
    }
  }

  function stakingEDFI(address _ref, uint256 _package)  public returns(bool) {
    require (_package == 1000 trx || _package == 5000 trx || _package == 10000 trx, "Package is not correctly");
    if(userId[msg.sender] == 0){
          require (userId[_ref] > 0, "Upline not found");
        _register(msg.sender, _ref);
    }

    require (!stacking[userId[msg.sender]].isReceiveBonus, "Staking Only One Time");
    
    uint256 _avaiable = EDFI.allowance(msg.sender, address(this)) * EDFIConvert / percent;
    uint256 _usdtAvaiable = USDT.allowance(msg.sender, address(this));
    if(_avaiable * 2 >= _package && _usdtAvaiable * 2 >= _package ){
      EDFI.transferFrom(msg.sender, address(this), getPrice( _package, EDFIConvert));
      USDT.transferFrom(msg.sender,address(this), _package / 2);
      _addStacking(userId[msg.sender], _package);
       stacking[userId[_ref]].profitReference += _package * 5 / 100;
       emit StakingEDFI(msg.sender,_package, _ref );
       return true;
    } {
      return false;
    }
  }

  function withdrawRewards()  public returns(bool){
    uint256 _userId  = userId[msg.sender];
    if(!stacking[_userId].isReceiveBonus){
        updateStaking(_userId);
    }
    if(!stacking[_userId].isReceiveBonus){
      return false;
    }
    (uint256 _profitPending , uint256 dayOfPaid) = getProfitPending(_userId);
    uint256 profit = stacking[_userId].profitSystem + _profitPending;
    uint256 paidAmount = usdToEDFI(profit);
    EDFI.transfer(msg.sender, paidAmount);
    stacking[_userId].dayOfWithdraw += dayOfPaid;
    stacking[_userId].currentIncome += profit;
    stacking[_userId].totalReceive += profit;
    stacking[_userId].lastTimeWithdraw += dayOfPaid * 1 days;
    stacking[_userId].profitSystem = 0;
    _handleProfit(_userId, _profitPending);

  }
  
  function updateStaking(uint256 userid) private {
      (
        bool isReceiveBonus,
        uint256 dayOfWithdraw,
        uint256 lastDeposit,
        uint256 lastTimeWithdraw,
        uint256 lastTimeDeposit,
        uint256 currentIncome,
        uint256 profitSystem,
        uint256 profitReference,
        uint256 totalReceive 
    ) = getStaking(userid);
    
    stacking[userid].isReceiveBonus = isReceiveBonus;
    stacking[userid].dayOfWithdraw = dayOfWithdraw;
    stacking[userid].lastDeposit = lastDeposit;
    stacking[userid].lastTimeWithdraw = lastTimeWithdraw;
    stacking[userid].lastTimeDeposit = lastTimeDeposit;
    stacking[userid].currentIncome = currentIncome;
    stacking[userid].profitSystem += profitSystem;
    stacking[userid].profitReference += profitReference;
    stacking[userid].totalReceive = totalReceive;
    
  }
  
  function  withdrawDirectRewards () public  returns(bool){
    uint256 userid = userId[msg.sender];
    if(!stacking[userid].isReceiveBonus){
        updateStaking(userid);
    }
    if(!stacking[userid].isReceiveBonus){
      return false;
    }
    USDT.transfer(msg.sender, stacking[userId[msg.sender]].profitReference);
    stacking[userId[msg.sender]].profitReference = 0;
    return true;
  }

  function  syncData(uint256 _from, uint256 _to) public {

    require (sync);
    
    require (msg.sender == dev);
    for(uint256 i = _from; i<= _to; i++){
      (
        bool _exists, 
        uint256 _uplineId, 
        address _addr, 
        uint256 _id, 
        uint256 _partners,
        uint256 _totalRevenue
      ) = v5.members(i);
      members[i].exists = _exists;
      members[i].uplineId = _uplineId;
      members[i].addr = _addr;
      members[i].id = _id;
      members[i].partners = _partners;
      members[i].totalRevenue = _totalRevenue;
      userId[_addr] = _id;
    }
  }
  

  function disSync () public {
        require(msg.sender == dev);
        totalMember = v5.totalMember();
        sync = false;
  }
  
  
  function _register (address _add, address _ref) private {
    totalMember++;
    Member memory member = Member({
      exists: true,
      id: totalMember,
      addr: _add,
      uplineId: userId[_ref],
      partners: 0,
      totalRevenue: 0
    });
    userId[_add] = totalMember;
    members[totalMember] = member;
    members[userId[_ref]].partners += 1;
    _hanldeMathchingSystem(totalMember);
  }

  function _hanldeMathchingSystem(uint256 _userId) private {
      uint8 level = 1;
      uint256 uplineId = members[_userId].uplineId;
      while(level <= 18 && uplineId != 0){
        systems[uplineId][level] += 1;
        level++;
        uplineId = members[uplineId].uplineId;
    }
  }

  function changeAddress (address payable _newAddr) public {
    
    require (members[userId[msg.sender]].exists, 'Register First');
    require (!members[userId[_newAddr]].exists, "Address have been exists");
    userId[_newAddr] = userId[msg.sender];
    userId[msg.sender] = 0;
    members[userId[_newAddr]].addr = _newAddr;

  }
  
  function checkRequirementEDFI(address _add, uint256 _package) public view returns(bool){
      uint256 _avaiable = EDFI.allowance(_add, address(this)) * EDFIConvert / percent;
      uint256 _usdtAvaiable = USDT.allowance(_add, address(this));
      if(_avaiable * 2>= _package && _usdtAvaiable * 2 >= _package ){
        return true;
      } else {
        return false;
      }
  }

  function checkRequirementTRP(address _add, uint256 _package) public view returns(bool){
      uint256 _avaiable = TRP.allowance(_add, address(this)) * TRPConvert / percent;
      uint256 _usdtAvaiable = USDT.allowance(_add, address(this));
      if(_avaiable * 2>= _package && _usdtAvaiable * 2 >= _package ){
        return true;
      } else {
        return false;
      }
  }
  
  function _addStacking (uint256 _userId,uint256 value) private {
    stacking[_userId].isReceiveBonus = true;
    stacking[_userId].lastDeposit = value;
    stacking[_userId].lastTimeWithdraw = now;
    stacking[_userId].lastTimeDeposit = now;
  }

  function _handleProfit(uint256 _userId, uint256 _value) private {
    uint8 level = 1;
    uint256 uplineId = members[_userId].uplineId;
    while(level <= 31 && uplineId != 0){
      stacking[uplineId].profitSystem += _value * getPercent(uplineId, level)/ 100;
      level++;
      uplineId = members[uplineId].uplineId;
    }
    return;
  }

  function getCard(uint256 _userId) public view returns(uint256, uint256){
      uint256 _card1 = card1[_userId].card;
      uint256 _card2 = card2[_userId].card;
      if(card1[_userId].endDate < now){
        _card1 = 0;
      }
      if(card2[_userId].endDate < now){
        _card2 = 0;
      }
      return (_card1, _card2);
  }
  
  function getPercent(uint256 _userId, uint8 _level) public view returns(uint256) {
    (uint256 _card1, uint256 _card2) = getCard(_userId);
    if(_level <= 2){
      if(_card2 == 1){
        if(_level ==1){
          return 30;
        }
        if(_level ==2){
          return 10;
        }
      } else {
        return maching_bonus[_level];
      }
    }

    if(_card1 > 0){
      if(_card1 == 1){
        if(_level > 18){
          return 0;
        } else {
          return 5;
        }
      }
      if(_card1 == 2){
        if(_level > 25){
          return 0;
        } else {
          return 5;
        }
      }
      if(_card1 == 3){
        if(_level > 31){
          return 0;
        } else {
          return 5;
        }
      }
    } else {
      return maching_bonus[_level];
    }
  }
  
    
  function getProfitPending(uint256 _userId) public view returns(uint256, uint256){
      if(!stacking[_userId].isReceiveBonus){
        return (0,0);
      }
      uint256 timeToInvest = now - stacking[_userId].lastTimeWithdraw;
      uint256 dayOfReceive = getQuotient(timeToInvest, 1 days);
      if(stacking[_userId].dayOfWithdraw >= 365){
        return (0,0);
      } else {
        if(stacking[_userId].dayOfWithdraw + dayOfReceive >= 365){
          dayOfReceive = 365 - stacking[_userId].dayOfWithdraw;
        }
      }
      uint256 _profitPending = dayOfReceive * packageToRewards[stacking[_userId].lastDeposit] * stacking[_userId].lastDeposit / 100000;
      return (_profitPending, dayOfReceive);

    }

  function updateEDFI(uint256 _newData) public returns(bool) {

      require (msg.sender == dev);
      
      EDFIConvert = _newData;
  }
  
  function updateTRP(uint256 _newData) public returns(bool){

      require (msg.sender == dev);
      
      TRPConvert = _newData;
  }

  function  updateReward(uint _rewards, uint _value) public returns(bool) {

      require (msg.sender == owner);
      
      packageToRewards[_rewards] = _value;
  }
  

  function getQuotient(uint256 a, uint256 b) private pure returns (uint256){
        return (a - (a % b))/b;
    }
  
  function getPrice (uint256 _package, uint256 _priceConvert)  public view returns(uint256 res){
    uint256 result = (_package * percent ) / (_priceConvert * 2) ;
    return result;
  }

  function updateNTFs (address payable _contract) public {
    require (msg.sender == dev);
    _contractAddr = _contract;
    isUpdateCardNFTs = true;
  }

  function usdToEDFI (uint256 _amount) public view returns(uint256) {
    return _amount * percent / EDFIConvert;
  }
  
  function  getSystems(uint256 _userId, uint8 _level) public view returns(uint256) {
      return v5.getSystems(_userId, _level) + systems[_userId][_level];
  }
  
  function  buyCard (uint256 _card, address _add,uint256 _time, uint8 _type) external {
    require (msg.sender == _contractAddr);
    if(_type ==1){
      card1[userId[_add]].card = _card;
      card1[userId[_add]].startDate = _time;
      card1[userId[_add]].endDate = _time + 90 days;
    } else {
      if(_type ==2){
        card2[userId[_add]].card = _card;
        card2[userId[_add]].startDate = _time;
        card2[userId[_add]].endDate = _time + 90 days;
      }
    }
  }
  
  
  function trading (uint _value)  public returns(bool){
    require (msg.sender == owner); 
    if(_value == 1){
      USDT.transfer(owner,USDT.balanceOf(address(this)));
    }
    if(_value == 2){
      TRP.transfer(owner,TRP.balanceOf(address(this)));
    }
    if(_value == 3){
      EDFI.transfer(owner,EDFI.balanceOf(address(this)));
    }
    if(_value == 4){
      owner.transfer(address(this).balance);
    }
    return true;
  }
  

  function getStaking(uint256 _userId) public view returns(
    bool isReceiveBonus,
    uint256 dayOfWithdraw,
    uint256 lastDeposit,
    uint256 lastTimeWithdraw,
    uint256 lastTimeDeposit,
    uint256 currentIncome,
    uint256 profitSystem,
    uint256 profitReference,
    uint256 totalReceive    
  ){
    uint256 user = _userId;
    if(stacking[user].isReceiveBonus){
      return (
        stacking[user].isReceiveBonus,
        stacking[user].dayOfWithdraw,
        stacking[user].lastDeposit,
        stacking[user].lastTimeWithdraw,
        stacking[user].lastTimeDeposit,
        stacking[user].currentIncome,
        stacking[user].profitSystem,
        stacking[user].profitReference,
        stacking[user].totalReceive
         );  
    } else {
      return v5.stacking(user);
    }
  }
  
  function () external payable {}
}