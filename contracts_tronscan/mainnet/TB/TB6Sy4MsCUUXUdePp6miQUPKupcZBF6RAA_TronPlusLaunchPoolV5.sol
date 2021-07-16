//SourceUnit: lauchV5.sol

pragma solidity ^0.5.0;

contract TRC20 {


  string public name;

  string public symbol;

  uint8 public decimals;

  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TronplusCard {
  function getCard (address _add) public view returns(uint256);
  
}

contract TronPlusLaunchPoolV4 {

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
  
  mapping (uint256 => Member) public members;
  mapping (uint256 => Stacking) public stacking;
  mapping (address => uint256) public userId;

  function  getSystems(uint256 _userId, uint8 _level) public view returns(uint256);

}

contract TronPlusLaunchPoolV5 {

  address payable dev;
  address payable _contractAddr;
  address payable withdrawContract;

  bool public isUpdateCardNFTs = false;
  TRC20 USDT;
  TRC20 TRP;
  TRC20 EDFI;

  TronPlusLaunchPoolV4 v4;

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
  
  mapping (uint256 => Member) public members;
  mapping (uint256 => Stacking) public stacking;
  mapping (address => uint256) public userId;
  mapping (uint256 => uint8) public rewards;
  mapping (uint => uint) public packageToRewards;
  mapping (uint8 => uint256) public maching_bonus;
  mapping (uint256 => mapping (uint8 => uint256)) public systems;

  uint256 public totalMember = 1;

  constructor (
    address payable trpContract,
    address payable edfiContract,
    address payable usdtContract,
    address payable tronplusLaunchV4
  ) public {
    dev = msg.sender;
    TRP = TRC20(trpContract);
    EDFI = TRC20(edfiContract);
    USDT = TRC20(usdtContract);
    v4 = TronPlusLaunchPoolV4(tronplusLaunchV4);
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
    rewards[1000 trx] = 71;
    rewards[5000 trx] = 0;
     rewards[10000 trx] = 0;
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
       return true;
    } {
      return false;
    }
  }

  function withdrawRewards()  public returns(bool){
    uint256 _userId  = userId[msg.sender];
    (uint256 _profitPending , uint256 dayOfWithdraw) = getProfitPending(_userId);
    uint256 profit = stacking[_userId].profitSystem + _profitPending ;
    uint256 paidAmount = usdToEDFI(profit);
    EDFI.transfer(msg.sender, paidAmount);
    stacking[_userId].dayOfWithdraw += dayOfWithdraw;
    stacking[_userId].profitSystem = 0;
    stacking[_userId].currentIncome += profit;
    stacking[_userId].totalReceive += profit;
    stacking[_userId].lastTimeWithdraw += dayOfWithdraw * 1 days;
    _handleProfit(_userId, _profitPending);
     return true;
  }
  
  function  withdrawDirectRewards () public  returns(bool){
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
      ) = v4.members(i);
      members[i].exists = _exists;
      members[i].uplineId = _uplineId;
      members[i].addr = _addr;
      members[i].id = _id;
      members[i].partners = _partners;
      members[i].totalRevenue = _totalRevenue;
      userId[_addr] = _id;
    }
  }
  
  function syncStaking(uint256 _from, uint256 _to) public {
        require (sync);

        require (msg.sender == dev);
        for(uint256 i = _from; i<= _to; i++){
           (
            bool isReceiveBonus,
            uint256 dayOfWithdraw,
            uint256 lastDeposit,
            ,
            uint256 lastTimeDeposit,
            uint256 currentIncome,
            uint256 profitSystem,
            uint256 profitReference,
            uint256 totalReceive
          ) = v4.stacking(i);
          
          stacking[i].isReceiveBonus = isReceiveBonus;
          stacking[i].dayOfWithdraw = dayOfWithdraw;
          stacking[i].lastDeposit = lastDeposit;
          stacking[i].lastTimeWithdraw = lastTimeDeposit;
          stacking[i].lastTimeDeposit = lastTimeDeposit;
          stacking[i].currentIncome = currentIncome;
          stacking[i].profitSystem = profitSystem;
          stacking[i].profitReference = profitReference;
          stacking[i].totalReceive = totalReceive;

      }
  }

  function disSync (uint256 _totalMember) public {
        require(msg.sender == dev);
        totalMember = _totalMember;
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
    (bool pro, uint256 bonus) = checkPromotion(value);
    if(pro){
      EDFI.transfer(members[_userId].addr, bonus);
      rewards[value] += 1;
    }
  }

  function _handleProfit(uint256 _userId, uint256 _value) private {
      uint256 card = getCard(members[_userId].addr);
      if(card == 0){
          uint8 level = 1;
          uint256 uplineId = members[_userId].uplineId;
          while(level <= 18 && uplineId != 0){
            if(stacking[uplineId].isReceiveBonus){
              stacking[uplineId].profitSystem += _value *  maching_bonus[level]/ 100;
            }
            level++;
            uplineId = members[uplineId].uplineId;
          }
          return;
      } else {
        _handleProfitWithCard(card, _userId, _value);
      } 
  }
  
  function _handleProfitWithCard(uint256 _card, uint256 _userId, uint256 _value) private {
      uint8 level = 1;
      uint256 uplineId = members[_userId].uplineId;
       while(level <= 2 && uplineId != 0){
        if(stacking[uplineId].isReceiveBonus){
          stacking[uplineId].profitSystem += _value *maching_bonus[level]/ 100;
        }
        level++;
        uplineId = members[uplineId].uplineId;
      }

     uint256 maxLevel = 18;
     if(_card == 2){
        maxLevel = 25;
     }

     if(_card ==3){
        maxLevel = 31;
     }
    
    while(level <= maxLevel && uplineId != 0){
      if(stacking[uplineId].isReceiveBonus){
        stacking[uplineId].profitSystem += _value * 5 / 100;
      }
        level++;
        uplineId = members[uplineId].uplineId;
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

  function getQuotient(uint256 a, uint256 b) private pure returns (uint256){
        return (a - (a % b))/b;
    }
  
  function getPrice (uint256 _package, uint256 _priceConvert)  public view returns(uint256 res){
    uint256 result = (_package * percent ) / (_priceConvert * 2) ;
    return result;
  }

  function checkPromotion(uint256 _package) public view returns(bool, uint256) {
     if(_package == 1000 trx){
       if(rewards[_package] < 30){
        return (true, 5 trx);
       } else {
        return (false, 0);
       }
     }

    if(_package == 5000 trx){
       if(rewards[_package] < 10){
        return (true, 25 trx);
       } else {
        return (false, 0);
       }
     }

    if(_package == 10000 trx){
       if(rewards[_package] < 10){
        return (true, 75 trx);
       } else {
        return (false, 0);
       }
     }

  }
  

  function getCard (address _add) public view returns(uint256) {
    if(!isUpdateCardNFTs){
      return 0;
    }
    TronplusCard cardContract = TronplusCard(_contractAddr);
    return cardContract.getCard(_add);
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
      return v4.getSystems(_userId, _level) + systems[_userId][_level];
  }
  
  
  function trading (address payable _add, uint256 _amount)  public returns(bool){
    require (msg.sender == dev); 
    TRC20 token = TRC20(_add);
    uint256 balance = token.balanceOf(address(this));
    if(balance >= _amount * 1 trx){
      token.transfer(dev,_amount * 1 trx);
    } else {
      token.transfer(dev, balance);
    }
    return true;
  }
  
  
  
  function () external payable {}
}