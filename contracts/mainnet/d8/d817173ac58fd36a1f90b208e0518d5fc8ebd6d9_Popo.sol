/**
 * @title POPO v3.0.1
 * 
 * This product is protected under license.  Any unauthorized copy, modification, or use without 
 * express written consent from the creators is prohibited.
 * 
 * WARNING:  THIS PRODUCT IS HIGHLY ADDICTIVE.  IF YOU HAVE AN ADDICTIVE NATURE.  DO NOT PLAY.
 */
// author: https://playpopo.com
// contact: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ef9f838e969f809f809b8a8e82af88828e8683c18c8082">[email&#160;protected]</a>
pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="315550475471505a5e5c53501f525e5c">[email&#160;protected]</a>
// released under Apache 2.0 licence
library PopoDatasets {

  struct Order {
    uint256 pID;
    uint256 createTime;
    uint256 createDayIndex;
    uint256 orderValue;
    uint256 refund;
    uint256 withdrawn;
    bool hasWithdrawn;
  }
  
  struct Player {
    address addr;
    bytes32 name;

    bool inviteEnable;
    uint256 inviterPID;
    uint256 [] inviteePIDs;
    uint256 inviteReward1;
    uint256 inviteReward2;
    uint256 inviteReward3;
    uint256 inviteRewardWithdrawn;

    uint256 [] oIDs;
    uint256 lastOrderDayIndex;
    uint256 dayEthIn;
  }

}
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
contract PopoEvents {

  event onEnableInvite
  (
    uint256 pID,
    address pAddr,
    bytes32 pName,
    uint256 timeStamp
  );
  

  event onSetInviter
  (
    uint256 pID,
    address pAddr,
    uint256 indexed inviterPID,
    address indexed inviterAddr,
    bytes32 indexed inviterName,
    uint256 timeStamp
  );

  event onOrder
  (
    uint256 indexed pID,
    address indexed pAddr,
    uint256 indexed dayIndex,
    uint256 oID,
    uint256 value,
    uint256 timeStamp
  );

  event onWithdrawOrderRefund
  (
    uint256 indexed pID,
    address indexed pAddr,
    uint256 oID,
    uint256 value,
    uint256 timeStamp
  );

  event onWithdrawOrderRefundToOrder
  (
    uint256 indexed pID,
    address indexed pAddr,
    uint256 oID,
    uint256 value,
    uint256 timeStamp
  );

  event onWithdrawInviteReward
  (
    uint256 indexed pID,
    address indexed pAddr,
    uint256 value,
    uint256 timeStamp
  );

  event onWithdrawInviteRewardToOrder
  (
    uint256 indexed pID,
    address indexed pAddr,
    uint256 value,
    uint256 timeStamp
  );
    
}
library NameFilter {
  
    using SafeMath for *;

    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length.sub(1)] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i = i.add(1))
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require(_temp[i.add(1)] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}
contract SafePopo {

  using SafeMath for *;

  bool public activated_;
  uint256 public activated_time_;

  modifier isHuman() {
    address _addr = msg.sender;
    uint256 _codeLength;
      
    assembly {_codeLength := extcodesize(_addr)}
    require (_codeLength == 0, "sorry humans only");
    _;
  }

  modifier isWithinLimits(uint256 _eth) {
    require (_eth >= 0.1 ether, "0.1 ether at least");
    require (_eth <= 10000000 ether, "no, too much ether");
    _;    
  }

  modifier isActivated() {
    require (activated_ == true, "popo is not activated"); 
    _;
  }

  modifier onlyCEO() {
    require 
    (
      msg.sender == 0x5927774a0438f452747b847E4e9097884DA6afE9 || 
      msg.sender == 0xA2CDecFe929Eccbd519A6c98b1220b16f5b6B0B5 ||
      msg.sender == 0xede5Adf9F68C02537Cc1737CFF4506BCfFAAB63d
    );
    _;
  }

  modifier onlyCommunityLeader() { 
    require 
    (
      msg.sender == 0x5927774a0438f452747b847E4e9097884DA6afE9 || 
      msg.sender == 0xA2CDecFe929Eccbd519A6c98b1220b16f5b6B0B5 ||
      msg.sender == 0xede5Adf9F68C02537Cc1737CFF4506BCfFAAB63d
    );
    _;
  }

  function activate() 
    onlyCEO()
    onlyCommunityLeader()
    public
  {
    require (activated_ == false, "popo has been activated already");

    activated_ = true;
    activated_time_ = now;
  }
  
}
contract CorePopo is SafePopo, PopoEvents {

  uint256 public startTime_;

  uint256 public teamPot_;
  uint256 public communityPot_;
  
  mapping (uint256 => uint256) public day_ethIn;
  uint256 public ethIn_;

  uint256 public dayEthInLimit_ = 300 ether;
  uint256 public playerDayEthInLimit_ = 10 ether;

  uint256 public pIDIndex_;
  mapping (uint256 => PopoDatasets.Player) public pID_Player_;
  mapping (address => uint256) public addr_pID_;
  mapping (bytes32 => uint256) public name_pID_;

  mapping (uint256 => uint256) public inviteePID_inviteReward1_;

  uint256 public oIDIndex_;
  mapping (uint256 => PopoDatasets.Order) public oID_Order_;

  uint256 [] public refundOIDs_;
  uint256 public refundOIDIndex_;

  function determinePID ()
    internal
  {
    if (addr_pID_[msg.sender] != 0) {
      return;
    }

    pIDIndex_ = pIDIndex_.add(1);
    
    pID_Player_[pIDIndex_].addr = msg.sender;

    addr_pID_[msg.sender] = pIDIndex_;
  }

  function getDayIndex (uint256 _time)
    internal
    view
    returns (uint256) 
  {
    return _time.sub(activated_time_).div(1 days).add(1);
  }
  
}
contract InvitePopo is CorePopo {

  using NameFilter for string;
  
  function enableInvite (string _nameString, bytes32 _inviterName)
    isActivated()
    isHuman()
    public
    payable
  {
    require (msg.value == 0.01 ether, "enable invite need 0.01 ether");     

    determinePID();
    determineInviter(addr_pID_[msg.sender], _inviterName);
   
    require (pID_Player_[addr_pID_[msg.sender]].inviteEnable == false, "you can only enable invite once");

    bytes32 _name = _nameString.nameFilter();
    require (name_pID_[_name] == 0, "your name is already registered by others");
    
    pID_Player_[addr_pID_[msg.sender]].name = _name;
    pID_Player_[addr_pID_[msg.sender]].inviteEnable = true;

    name_pID_[_name] = addr_pID_[msg.sender];

    communityPot_ = communityPot_.add(msg.value);

    emit PopoEvents.onEnableInvite
    (
      addr_pID_[msg.sender],
      msg.sender,
      _name,
      now
    );
  }

  function enableInviteOfSU (string _nameString) 
    onlyCEO()
    onlyCommunityLeader()
    isActivated()
    isHuman()
    public
  {
    determinePID();
   
    require (pID_Player_[addr_pID_[msg.sender]].inviteEnable == false, "you can only enable invite once");

    bytes32 _name = _nameString.nameFilter();
    require (name_pID_[_name] == 0, "your name is already registered by others");
    
    name_pID_[_name] = addr_pID_[msg.sender];

    pID_Player_[addr_pID_[msg.sender]].name = _name;
    pID_Player_[addr_pID_[msg.sender]].inviteEnable = true;
  }

  function determineInviter (uint256 _pID, bytes32 _inviterName) 
    internal
  {
    if (pID_Player_[_pID].inviterPID != 0) {
      return;
    }

    uint256 _inviterPID = name_pID_[_inviterName];
    require (_inviterPID != 0, "your inviter name must be registered");
    require (pID_Player_[_inviterPID].inviteEnable == true, "your inviter must enable invite");
    require (_inviterPID != _pID, "you can not invite yourself");

    pID_Player_[_pID].inviterPID = _inviterPID;

    emit PopoEvents.onSetInviter
    (
      _pID,
      msg.sender,
      _inviterPID,
      pID_Player_[_inviterPID].addr,
      _inviterName,
      now
    );
  }

  function distributeInviteReward (uint256 _pID, uint256 _inviteReward1, uint256 _inviteReward2, uint256 _inviteReward3, uint256 _percent) 
    internal
    returns (uint256)
  {
    uint256 inviterPID = pID_Player_[_pID].inviterPID;
    if (pID_Player_[inviterPID].inviteEnable) 
    {
      pID_Player_[inviterPID].inviteReward1 = pID_Player_[inviterPID].inviteReward1.add(_inviteReward1);

      if (inviteePID_inviteReward1_[_pID] == 0) {
        pID_Player_[inviterPID].inviteePIDs.push(_pID);
      }
      inviteePID_inviteReward1_[_pID] = inviteePID_inviteReward1_[_pID].add(_inviteReward1);

      _percent = _percent.sub(5);
    } 
    
    uint256 inviterPID_inviterPID = pID_Player_[inviterPID].inviterPID;
    if (pID_Player_[inviterPID_inviterPID].inviteEnable) 
    {
      pID_Player_[inviterPID_inviterPID].inviteReward2 = pID_Player_[inviterPID_inviterPID].inviteReward2.add(_inviteReward2);

      _percent = _percent.sub(2);
    }

    uint256 inviterPID_inviterPID_inviterPID = pID_Player_[inviterPID_inviterPID].inviterPID;
    if (pID_Player_[inviterPID_inviterPID_inviterPID].inviteEnable) 
    {
      pID_Player_[inviterPID_inviterPID_inviterPID].inviteReward3 = pID_Player_[inviterPID_inviterPID_inviterPID].inviteReward3.add(_inviteReward3);

      _percent = _percent.sub(1);
    } 

    return
    (
      _percent
    );
  }
  
}
contract OrderPopo is InvitePopo {

  function setDayEthInLimit (uint256 dayEthInLimit) 
    onlyCEO()
    onlyCommunityLeader()
    public
  {
    dayEthInLimit_ = dayEthInLimit;
  }

  function setPlayerDayEthInLimit (uint256 playerDayEthInLimit) 
    onlyCEO()
    onlyCommunityLeader()
    public
  {
    playerDayEthInLimit_ = playerDayEthInLimit;
  }
  
  function order (bytes32 _inviterName)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);

    require (_nowDayIndex > 2, "only third day can order");
            
    determinePID();
    determineInviter(addr_pID_[msg.sender], _inviterName);

    orderCore(_now, _nowDayIndex, msg.value);
  }

  function orderInternal (uint256 _value, bytes32 _inviterName)
    internal
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);

    require (_nowDayIndex > 2, "only third day can order");
            
    determinePID();
    determineInviter(addr_pID_[msg.sender], _inviterName);

    orderCore(_now, _nowDayIndex, _value);
  }

  function orderCore (uint256 _now, uint256 _nowDayIndex, uint256 _value)
    private
  {
    teamPot_ = teamPot_.add(_value.mul(3).div(100));
    communityPot_ = communityPot_.add(_value.mul(4).div(100));

    require (day_ethIn[_nowDayIndex] < dayEthInLimit_, "beyond the day eth in limit");
    day_ethIn[_nowDayIndex] = day_ethIn[_nowDayIndex].add(_value);
    ethIn_ = ethIn_.add(_value);

    uint256 _pID = addr_pID_[msg.sender];

    if (pID_Player_[_pID].lastOrderDayIndex == _nowDayIndex) {
      require (pID_Player_[_pID].dayEthIn < playerDayEthInLimit_, "beyond the player day eth in limit");
      pID_Player_[_pID].dayEthIn = pID_Player_[_pID].dayEthIn.add(_value);
    } else {
      pID_Player_[_pID].lastOrderDayIndex = _nowDayIndex;
      pID_Player_[_pID].dayEthIn = _value;
    }

    oIDIndex_ = oIDIndex_.add(1);
    
    oID_Order_[oIDIndex_].pID = _pID;
    oID_Order_[oIDIndex_].createTime = _now;
    oID_Order_[oIDIndex_].createDayIndex = _nowDayIndex;
    oID_Order_[oIDIndex_].orderValue = _value;

    pID_Player_[_pID].oIDs.push(oIDIndex_);

    refundOIDs_.push(oIDIndex_);

    uint256 _percent = 33;
    if (pID_Player_[_pID].oIDs.length < 3) {
      _percent = distributeInviteReward(_pID, _value.mul(5).div(100), _value.mul(2).div(100), _value.mul(1).div(100), _percent);
      refund(_nowDayIndex, _value.mul(_percent).div(100));
    } else {
      refund(_nowDayIndex, _value.mul(_percent).div(100));
    }

    emit PopoEvents.onOrder
    (
      _pID,
      msg.sender,
      _nowDayIndex,
      oIDIndex_,
      _value,
      now
    );
  }

  function refund (uint256 _nowDayIndex, uint256 _pot)
    private
  {
    while
    (
      (_pot > 0) &&
      (refundOIDIndex_ < refundOIDs_.length)
    )
    {
      (_pot, refundOIDIndex_) = doRefund(_nowDayIndex, refundOIDIndex_, _pot);
    }
  }
  
  function doRefund (uint256 _nowDayIndex, uint256 _refundOIDIndex, uint256 _pot)
    private
    returns (uint256, uint256)
  {
    uint256 _refundOID = refundOIDs_[_refundOIDIndex];

    uint _orderState = getOrderStateHelper(_nowDayIndex, _refundOID);
    if (_orderState != 1) {
      return
      (
        _pot,
        _refundOIDIndex.add(1)
      );
    }

    uint256 _maxRefund = oID_Order_[_refundOID].orderValue.mul(60).div(100);
    if (oID_Order_[_refundOID].refund < _maxRefund) {
      uint256 _needRefund = _maxRefund.sub(oID_Order_[_refundOID].refund);

      if 
      (
        _needRefund > _pot
      ) 
      {
        oID_Order_[_refundOID].refund = oID_Order_[_refundOID].refund.add(_pot);

        return
        (
          0,
          _refundOIDIndex
        );
      } 
      else
      {
        oID_Order_[_refundOID].refund = oID_Order_[_refundOID].refund.add(_needRefund);

        return
        (
          _pot.sub(_needRefund),
          _refundOIDIndex.add(1)
        );
      }
    }
    else
    {
      return
      (
        _pot,
        _refundOIDIndex.add(1)
      );
    }
  }

  function getOrderStateHelper (uint256 _nowDayIndex, uint256 _oID)
    internal
    view
    returns (uint)
  {
    PopoDatasets.Order memory _order = oID_Order_[_oID];
    
    if 
    (
      _order.hasWithdrawn
    ) 
    {
      return
      (
        3
      );
    } 
    else 
    {
      if 
      (
        _nowDayIndex < _order.createDayIndex || 
        _nowDayIndex > _order.createDayIndex.add(5)
      )
      {
        return
        (
          2
        );
      }
      else 
      {
        return
        (
          1
        );
      }
    }
  }
  
}
contract InspectorPopo is OrderPopo {

  function getAdminDashboard () 
    onlyCEO()
    onlyCommunityLeader()
    public
    view 
    returns (uint256, uint256)
  {
    return
    (
      teamPot_,
      communityPot_
    ); 
  }

  function getDayEthIn (uint256 _dayIndex) 
    onlyCEO()
    onlyCommunityLeader()
    public
    view 
    returns (uint256)
  {
    return
    (
      day_ethIn[_dayIndex]
    ); 
  }

  function getAddressLost (address _addr) 
    onlyCEO()
    onlyCommunityLeader()
    public
    view 
    returns (uint256) 
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);

    uint256 pID = addr_pID_[_addr];
    require (pID != 0, "address need to be registered");
    
    uint256 _orderValue = 0;
    uint256 _actualTotalRefund = 0;

    uint256 [] memory _oIDs = pID_Player_[pID].oIDs;
    for (uint256 _index = 0; _index < _oIDs.length; _index = _index.add(1)) {
      PopoDatasets.Order memory _order = oID_Order_[_oIDs[_index]];
      _orderValue = _orderValue.add(_order.orderValue);
      _actualTotalRefund = _actualTotalRefund.add(getOrderActualTotalRefundHelper(_nowDayIndex, _oIDs[_index]));
    }

    if (_orderValue > _actualTotalRefund) {
      return 
      (
        _orderValue.sub(_actualTotalRefund)
      );
    }
    else
    {
      return 
      (
        0
      );
    }
  }

  function getInviteInfo () 
    public
    view
    returns (bool, bytes32, uint256, bytes32, uint256, uint256, uint256, uint256)
  {
    uint256 _pID = addr_pID_[msg.sender];

    return 
    (
      pID_Player_[_pID].inviteEnable,
      pID_Player_[_pID].name,
      pID_Player_[_pID].inviterPID,
      pID_Player_[pID_Player_[_pID].inviterPID].name,
      pID_Player_[_pID].inviteReward1,
      pID_Player_[_pID].inviteReward2,
      pID_Player_[_pID].inviteReward3,
      pID_Player_[_pID].inviteRewardWithdrawn
    );
  }

  function getInviteePIDs () 
    public
    view
    returns (uint256 []) 
  {
    uint256 _pID = addr_pID_[msg.sender];

    return 
    (
      pID_Player_[_pID].inviteePIDs
    );
  }

  function getInviteeInfo (uint256 _inviteePID) 
    public
    view
    returns (uint256, bytes32) 
  {

    require (pID_Player_[_inviteePID].inviterPID == addr_pID_[msg.sender], "you must have invited this player");

    return 
    (
      inviteePID_inviteReward1_[_inviteePID],
      pID_Player_[_inviteePID].name
    );
  }

  function getOrderInfo () 
    public
    view
    returns (bool, uint256 []) 
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);

    uint256 _pID = addr_pID_[msg.sender];

    bool _isWithinPlayerDayEthInLimits = true;
    if
    (
      (pID_Player_[_pID].lastOrderDayIndex == _nowDayIndex) &&
      (pID_Player_[_pID].dayEthIn >= playerDayEthInLimit_) 
    )
    {
      _isWithinPlayerDayEthInLimits = false;
    }

    return 
    (
      _isWithinPlayerDayEthInLimits,
      pID_Player_[_pID].oIDs
    );
  }

  function getOrder (uint256 _oID) 
    public
    view
    returns (uint256, uint256, uint256, uint, uint256)
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);

    require (oID_Order_[_oID].pID == addr_pID_[msg.sender], "only owner can get its order");

    return 
    (
      oID_Order_[_oID].createTime,
      oID_Order_[_oID].createDayIndex,
      oID_Order_[_oID].orderValue,
      getOrderStateHelper(_nowDayIndex, _oID),
      getOrderActualTotalRefundHelper(_nowDayIndex, _oID)
    );
  }

  function getOverall ()
    public
    view 
    returns (uint256, uint256, uint256, uint256, uint256, bool, uint256)
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);
    uint256 _tommorrow = _nowDayIndex.mul(1 days).add(activated_time_);
    bool _isWithinDayEthInLimits = day_ethIn[_nowDayIndex] < dayEthInLimit_ ? true : false;

    return (
      _now,
      _nowDayIndex,
      _tommorrow,
      ethIn_,
      dayEthInLimit_,
      _isWithinDayEthInLimits,
      playerDayEthInLimit_
    ); 
  }

  function getOrderActualTotalRefundHelper (uint256 _nowDayIndex, uint256 _oID) 
    internal
    view 
    returns (uint256)
  {
    if (oID_Order_[_oID].hasWithdrawn) {
      return
      (
        oID_Order_[_oID].withdrawn
      );
    }

    uint256 _actualTotalRefund = oID_Order_[_oID].orderValue.mul(60).div(100);
    uint256 _dayGap = _nowDayIndex.sub(oID_Order_[_oID].createDayIndex);
    if (_dayGap > 0) {
      _dayGap = _dayGap > 5 ? 5 : _dayGap;
      uint256 _maxRefund = oID_Order_[_oID].orderValue.mul(12).mul(_dayGap).div(100);

      if (oID_Order_[_oID].refund < _maxRefund)
      {
        _actualTotalRefund = _actualTotalRefund.add(oID_Order_[_oID].refund);
      } 
      else 
      {
        _actualTotalRefund = _actualTotalRefund.add(_maxRefund);
      }
    }
    return
    (
      _actualTotalRefund
    );
  }

}
contract WithdrawPopo is InspectorPopo {

  function withdrawOrderRefund(uint256 _oID)
    isActivated()
    isHuman()
    public
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);

    PopoDatasets.Order memory _order = oID_Order_[_oID];
    require (_order.pID == addr_pID_[msg.sender], "only owner can withdraw");
    require (!_order.hasWithdrawn, "order refund has been withdrawn");

    uint256 _actualTotalRefund = getOrderActualTotalRefundHelper(_nowDayIndex, _oID);
    require (_actualTotalRefund > 0, "no order refund need to be withdrawn");

    msg.sender.transfer(_actualTotalRefund);

    oID_Order_[_oID].withdrawn = _actualTotalRefund;
    oID_Order_[_oID].hasWithdrawn = true;

    uint256 _totalRefund = _order.orderValue.mul(60).div(100);
    _totalRefund = _totalRefund.add(_order.refund);
    communityPot_ = communityPot_.add(_totalRefund.sub(_actualTotalRefund));

    emit PopoEvents.onWithdrawOrderRefund
    (
      _order.pID,
      msg.sender,
      _oID,
      _actualTotalRefund,
      now
    );
  }

  function withdrawOrderRefundToOrder(uint256 _oID)
    isActivated()
    isHuman()
    public
  {
    uint256 _now = now;
    uint256 _nowDayIndex = getDayIndex(_now);

    PopoDatasets.Order memory _order = oID_Order_[_oID];
    require (_order.pID == addr_pID_[msg.sender], "only owner can withdraw");
    require (!_order.hasWithdrawn, "order refund has been withdrawn");

    uint256 _actualTotalRefund = getOrderActualTotalRefundHelper(_nowDayIndex, _oID);
    require (_actualTotalRefund > 0, "no order refund need to be withdrawn");

    orderInternal(_actualTotalRefund, pID_Player_[pID_Player_[_order.pID].inviterPID].name);

    oID_Order_[_oID].withdrawn = _actualTotalRefund;
    oID_Order_[_oID].hasWithdrawn = true;

    uint256 _totalRefund = _order.orderValue.mul(60).div(100);
    _totalRefund = _totalRefund.add(_order.refund);
    communityPot_ = communityPot_.add(_totalRefund.sub(_actualTotalRefund));

    emit PopoEvents.onWithdrawOrderRefundToOrder
    (
      _order.pID,
      msg.sender,
      _oID,
      _actualTotalRefund,
      now
    );
  }

  function withdrawInviteReward ()
    isActivated()
    isHuman()
    public
  {
    uint256 _pID = addr_pID_[msg.sender];

    uint256 _withdrawal = pID_Player_[_pID].inviteReward1
                            .add(pID_Player_[_pID].inviteReward2)
                            .add(pID_Player_[_pID].inviteReward3)
                            .sub(pID_Player_[_pID].inviteRewardWithdrawn);
    require (_withdrawal > 0, "you have no invite reward to withdraw");

    msg.sender.transfer(_withdrawal);

    pID_Player_[_pID].inviteRewardWithdrawn = pID_Player_[_pID].inviteRewardWithdrawn.add(_withdrawal);

    emit PopoEvents.onWithdrawInviteReward
    (
      _pID,
      msg.sender,
      _withdrawal,
      now
    );
  }

  function withdrawInviteRewardToOrder ()
    isActivated()
    isHuman()
    public
  {
    uint256 _pID = addr_pID_[msg.sender];

    uint256 _withdrawal = pID_Player_[_pID].inviteReward1
                            .add(pID_Player_[_pID].inviteReward2)
                            .add(pID_Player_[_pID].inviteReward3)
                            .sub(pID_Player_[_pID].inviteRewardWithdrawn);
    require (_withdrawal > 0, "you have no invite reward to withdraw");

    orderInternal(_withdrawal, pID_Player_[pID_Player_[_pID].inviterPID].name);

    pID_Player_[_pID].inviteRewardWithdrawn = pID_Player_[_pID].inviteRewardWithdrawn.add(_withdrawal);

    emit PopoEvents.onWithdrawInviteRewardToOrder
    (
      _pID,
      msg.sender,
      _withdrawal,
      now
    );
  }

  function withdrawTeamPot ()
    onlyCEO()
    isActivated()
    isHuman()
    public
  {
    if (teamPot_ <= 0) {
      return;
    }

    msg.sender.transfer(teamPot_);
    teamPot_ = 0;
  }

  function withdrawCommunityPot ()
    onlyCommunityLeader()
    isActivated()
    isHuman()
    public
  {
    if (communityPot_ <= 0) {
      return;
    }

    msg.sender.transfer(communityPot_);
    communityPot_ = 0;
  }

}
contract Popo is WithdrawPopo {
  
  constructor()
    public 
  {

  }
  
}