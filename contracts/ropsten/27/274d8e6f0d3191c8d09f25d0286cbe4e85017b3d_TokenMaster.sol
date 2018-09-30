pragma solidity ^0.4.24;

contract TokenEvents{

    event onNewName
      (
       uint256 indexed playerID,
       bytes32  playerName,
       uint256 amountPaid,
       uint256 timeStamp
       );

    event onBuyWhite
      (
       uint256 indexed playerID,
       uint256 ethCost,
       uint256 timeStamp
       );

    event onReloadWhite
      (
       uint256 indexed playerID,
       uint256 ethCost,
       uint256 timeStamp
       );

    event onBuyStore
      (
       uint256 indexed playerID,
       uint256 ethCost,
       uint256 timeStamp
       );

    event onReloadStore
      (
       uint256 indexed playerID,
       uint256 ethCost,
       uint256 timeStamp
       );

    event onSendStore
      (
       uint256 indexed playerID,
       uint256 indexed reciveID,
       uint256 storeNum,
       uint256 timeStamp
       );

    event onWithdraw
      (
       uint256 indexed playerID,
       uint256 ethNum,
       uint256 timeStamp
       );
}

contract TokenMaster is TokenEvents{
     using SafeMath for *;
     using NameFilter for string;

     address private admin = msg.sender;
     string constant public name = "tokent";
     string constant public symbol = "tokent";

     uint256 public roundTime;
     uint256 public firstEndTime;
     address private aaaa;

     uint256 constant private precision_ = 1 ether;
     uint256 constant private whiteLow_ = 1 finney;
     uint256 constant private ratioMax_ = 500 szabo;
     uint256 constant private affDeepMax = 8;
     uint256 constant private vipMin = 100 finney;

     mapping (address => uint256) public pIDxAddr_;
     mapping (bytes32 => uint256) public pIDxName_;
     mapping (uint256 => TokenDataSets.Player) public plyr_;
     mapping (uint256 => TokenDataSets.PlayerHis) public plyrHis_;
     mapping (uint256 => uint256) public circleNum_;

     uint256 private nextID = 1;

     TokenDataSets.System public systemInfo;

     bool public activated_ = false;

     constructor(address _aaaa, uint256 _roundTime, uint256 _firstEndTime)
       public
     {
       aaaa = _aaaa;
       roundTime = _roundTime;
       firstEndTime = _firstEndTime;

       systemInfo.nextDistributeTime = _firstEndTime;
       systemInfo.lastPercentBase = 1 ether;
     }

//----------------------- modifier
    /**
     * @dev used to make sure no one can interact with contract until it has
     * been activated.
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    modifier updateTimeM() {
      updateTime();
      _;
    }

    /**
     * @dev prevents contracts from interacting with fomo3d
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    modifier determinePID(address _addr)
    {
      if(pIDxAddr_[_addr] == 0){
        pIDxAddr_[_addr] = nextID;
        plyr_[nextID].addr = _addr;
        nextID++;
      }
      
      _;
    }

    modifier isAdmin()
    {
      require(msg.sender == admin, "not admin");
      _;
    }

//------------------------ public

    function startActivated()
      isAdmin()
      public
    {
      require(msg.sender == admin, "can&#39;t activate");

      if(activated_){
        return;
      }
      activated_ = true;
    }

    function()
      isActivated()
      isHuman()
      isWithinLimits(msg.value)
      updateTimeM()
      determinePID(msg.sender)
      public
      payable
    {
      uint256 _pID = pIDxAddr_[msg.sender];

      uint256 _affID = plyr_[_pID].affID;

      require(_affID != 0, "must have affid");

      buyStoreCore(_pID, _affID, msg.value);

      emit onBuyStore(_pID, msg.value, block.timestamp);
    }
      

    function buyStoreByName(bytes32 _affName)
      isActivated()
      isHuman()
      isWithinLimits(msg.value)
      updateTimeM()
      determinePID(msg.sender)
      public
      payable
    {
      uint256 _pID = pIDxAddr_[msg.sender];

      uint256 _affID = addAff(_pID, _affName);

      require(_affID != 0, "must have affid");

      buyStoreCore(_pID, _affID, msg.value);

      emit onBuyStore(_pID, msg.value, block.timestamp);
    }

    function reloadStoreByName(uint256 _eth)
      isActivated()
      isHuman()
      isWithinLimits(_eth)
      updateTimeM()
      public
    {
      uint256 _pID = pIDxAddr_[msg.sender];
      require(_pID != 0, "error, no pid");

      uint256 _affID = plyr_[_pID].affID;
      require(_affID != 0, "error, need affID");
      
      withdrawRed_(_pID, _eth);

      buyStoreCore(_pID, _affID, _eth);

      emit onReloadStore(_pID, _eth, block.timestamp);
    }

    function sendStore(address _reciver, uint256 _store)
      isActivated()
      isHuman()
      determinePID(_reciver)
      updateTimeM()
      public
    {
      uint256 _pID = pIDxAddr_[msg.sender];
      require(_pID != 0, "error, no pid");

      require(plyr_[_pID].store >= _store, "error, not enough store");

      plyr_[_pID].store = plyr_[_pID].store.sub(_store);
      
      uint256 _rID = pIDxAddr_[_reciver];

      require(_rID != _pID, "not send to me");
      
      uint256 whiteBase = calcWhiteBase(_store);

      addWhite(_rID, _store, whiteBase, false);

      refundWhite(_pID, plyr_[_rID].affID, _store.mul(5).div(100), whiteBase.mul(5).div(100));

      emit onSendStore(_pID, _rID, _store, block.timestamp);
    }
    
    function withdraw(uint256 _eth)
      isActivated()
      isHuman()
      isWithinLimits(_eth)
      updateTimeM()
      public
    {
      uint256 _pID = pIDxAddr_[msg.sender];
      require(_pID != 0, "error, no pid");

      require(getARed(_pID, 0) >= 5 ether, "must > 5 red");

      withdrawRed_(_pID, _eth);

      plyrHis_[_pID].ethOut = plyrHis_[_pID].ethOut.add(_eth);
      systemInfo.ethOut = systemInfo.ethOut.add(_eth);
      plyr_[_pID].addr.transfer(_eth);

      emit onWithdraw(_pID, _eth, block.timestamp);
    }

    function buyWhiteByName(bytes32 _affName)
      isActivated()
      isHuman()
      isWithinLimits(msg.value)
      updateTimeM()
      determinePID(msg.sender)
      public
      payable
    {
      uint256 _pID = pIDxAddr_[msg.sender];

      uint256 _affID = addAff(_pID, _affName);

      require(_affID != 0, "must have affid");


      buyWhiteCore(_pID, _affID, msg.value, 0);

      emit onBuyWhite(_pID, msg.value, block.timestamp);
    }

    function reloadWhiteByName(uint256 _eth)
      isActivated()
      isHuman()
      isWithinLimits(_eth)
      updateTimeM()
      public
    {
      uint256 _pID = pIDxAddr_[msg.sender];
      require(_pID != 0, "error, no pid");

      uint256 _affID = plyr_[_pID].affID;

      require(_affID != 0, "error, need affID");
      
      withdrawRed_(_pID, _eth);

      buyWhiteCore(_pID, _affID, _eth, 0);

      emit onReloadWhite(_pID, _eth, block.timestamp);
    }

    function addVip(bytes32 _affInfo, string _affName)
      isActivated()
      isHuman()
      isWithinLimits(msg.value)
      updateTimeM()
      determinePID(msg.sender)
      public
      payable
    {
      require(msg.value >= vipMin, "not enough eth");

      bytes32 _name = _affName.nameFilter();

      require(pIDxName_[_name] == 0, "has name");

      uint256 _pID = pIDxAddr_[msg.sender];
      pIDxName_[_name] = _pID;
      plyr_[_pID].name = _name;

      uint256 _white = 10 ether;
      uint256 whiteBase = calcWhiteBase(_white);
        
      addWhite(_pID, _white, whiteBase, false);

      uint256 _affID = addAff(_pID, _affInfo);

      if(_affID == 0){
        distributeAll(msg.value);
      }  else{
        distributeAll(msg.value.sub(50 finney));
        plyr_[_affID].addr.transfer(50 finney);
        
        plyrHis_[_affID].tRefundEth = plyrHis_[_affID].tRefundEth.add(50 finney);

        refundWhite(_pID, _affID, _white.mul(5).div(100), whiteBase.mul(5).div(100));        
      }
      emit onNewName(_pID, _name, msg.value, block.timestamp);      
    }

    
//------------------------ private

    function addAff(uint256 _pID, bytes32 _affName)
      private
      returns(uint256 affID)
    {
      affID = pIDxName_[_affName];

      if (affID != 0 && affID != _pID && plyr_[_pID].affID == 0){
        plyr_[_pID].affID = affID;
	
	affID = plyr_[affID].affID;

	for(uint256 i = 0; i < affDeepMax - 1; i++){
	  if(affID == 0){
	    break;
	  }
	  
	  if(affID == _pID){
	    for(uint256 j = 0; j < i + 2; j++){
	      circleNum_[affID] = i + 2;
	      affID = plyr_[affID].affID;
	    }
	    break;
	  }

	  affID = plyr_[affID].affID;
	}
      }

      return plyr_[_pID].affID;
    }			   

    function withdrawRed_(uint256 _pID, uint256 _eth)
      private
    {
      require(getAEth(_pID, 0) >= _eth, "error, not enough red");

      plyrHis_[_pID].tWithdrawRed = plyrHis_[_pID].tWithdrawRed.add(_eth.mul(100));
      plyrHis_[_pID].ethOut = plyrHis_[_pID].ethOut.add(_eth);
    }

    function distributeAll(uint256 _eth)
      private
    {
      aaaa.transfer(_eth);
    }
    
    function distribute(uint256 _eth)
      private
      returns(uint256 _remain)
    {
      uint256 fee = _eth.div(10);
      distributeAll(fee);

      return _eth.sub(fee);
    }

    function buyStoreCore(uint256 _pID, uint256 _affID, uint256 _eth)
      private
    {
      uint256 _white = _eth.mul(100);
      uint256 _store = _eth.mul(625);
      
      buyWhiteCore(_pID, _affID, 0, _white);
      addStore(_pID, _store);
      addEth(_pID, _eth);
    }


    function buyWhiteCore(uint256 _pID, uint256 _affID, uint256 _eth, uint256 _white)
        private
    {
      if(_eth > 0){
          _white = _eth.mul(625).add(_white);
          addEth(_pID, _eth);          
      }
      
      uint256 whiteBase = calcWhiteBase(_white);
        
      addWhite(_pID, _white, whiteBase, false);

      refundWhite(_pID, _affID, _white.mul(5).div(100), whiteBase.mul(5).div(100));
    }

    function refundWhite(uint256 _pID, uint256 _affID, uint256 _white, uint256 _whiteBase)
      private
    {
      
      bool circle = false;

      for(uint256 i = affDeepMax; i > 0; i--){
        if(_affID == 0 || _affID == _pID){
          break;
        }

        if(_white < whiteLow_){
          break;
        }

	if(!circle && circleNum_[_affID] > 0){
	  circle = true;
	  i = Math.min(i, circleNum_[_affID]);
	}
	
        addWhite(_affID, _white, _whiteBase, true);

        _white = _white.div(2);
        _whiteBase = _whiteBase.div(2);
        _affID = plyr_[_affID].affID;
      }

    }

    function calcWhiteBase(uint256 _white)
      public
      view
      returns(uint256)
    {
      return _white.mul(precision_).div(systemInfo.lastPercentBase);
    }

    function updatePercentBase(uint256 rnd, uint256 _lastWhite, uint256 _lastWhiteBase)
      private
      view
      returns(uint256 _lastPercentBase)
    {
      require(rnd > 0, "rnd error");
      
      _lastPercentBase = systemInfo.lastPercentBase;
      
      for(uint256 i = 0; i < rnd; i++){
        _lastPercentBase = _lastPercentBase.mul((1 ether).sub(getRatio(_lastWhite, _lastWhiteBase, _lastPercentBase))).div(1 ether);
      }
      
      return;
    }
    
    function updateTime()
      private
    {
      if(block.timestamp < systemInfo.nextDistributeTime){
        return;
      }
      
      uint256 subTime = block.timestamp.sub(systemInfo.nextDistributeTime);
      uint256 rnd = subTime.div(roundTime) + 1;

      systemInfo.lastLastTRed = getTRed(systemInfo.lastWhite, systemInfo.lastWhiteBase, systemInfo.lastPercentBase);
      
      systemInfo.lastWhite = systemInfo.tWhite;
      systemInfo.lastWhiteBase = systemInfo.tWhiteBase;

      systemInfo.lastPercentBase = updatePercentBase(rnd, systemInfo.lastWhite, systemInfo.lastWhiteBase);

      systemInfo.nextDistributeTime = systemInfo.nextDistributeTime.add(rnd.mul(roundTime));
      systemInfo.roundIdx = systemInfo.roundIdx.add(rnd);
    }

    function addEth(uint256 _pID, uint256 _eth)
      private
    {
      plyrHis_[_pID].ethIn  = _eth.add(plyrHis_[_pID].ethIn);
      _eth = distribute(_eth);
      systemInfo.ethIn = systemInfo.ethIn.add(_eth);
    }

    function addStore(uint256 _pID, uint256 _store)
      private
    {
      plyr_[_pID].store = plyr_[_pID].store.add(_store);
      plyrHis_[_pID].tStore = plyrHis_[_pID].tStore.add(_store);

      systemInfo.tStore = systemInfo.tStore.add(_store);
    }

    function addWhite(uint256 _pID, uint256 _white, uint256 _whiteBase, bool _refundF)
        private
    {
      plyrHis_[_pID].tWhite = plyrHis_[_pID].tWhite.add(_white);
      plyrHis_[_pID].tWhiteBase = plyrHis_[_pID].tWhiteBase.add(_whiteBase);
      if(_refundF){
        plyrHis_[_pID].tAffWhite = plyrHis_[_pID].tAffWhite.add(_white);
      }

      systemInfo.tWhiteBase = systemInfo.tWhiteBase.add(_whiteBase);
      systemInfo.tWhite = systemInfo.tWhite.add(_white);
    }

//------------------------ getter

    function getAccountRest(address _account)
      public
      view
      returns(uint256 restWhite, // rest white
              uint256 restRed, // rest red
              uint256 restEth, // rest eth
              uint256 restStore, // rest store
              uint256 pID,
              bytes32 lastName
              )
    {
      uint256 _pID = pIDxAddr_[_account];
      // require(_pID != 0, "error account address");
      uint256 _lastWhite = systemInfo.lastWhite;
      uint256 _lastWhiteBase = systemInfo.lastWhiteBase;
      uint256 _lastPercentBase = systemInfo.lastPercentBase;      

      if(block.timestamp >= systemInfo.nextDistributeTime){
        uint256 rnd = block.timestamp.sub(systemInfo.nextDistributeTime).div(roundTime) + 1;
        _lastWhite = systemInfo.tWhite;
        _lastWhiteBase = systemInfo.tWhiteBase;
        _lastPercentBase = updatePercentBase(rnd, _lastWhite, _lastWhiteBase);
      }

      return (getRestWhite(plyrHis_[_pID].tWhiteBase, _lastPercentBase),
              getARed(_pID, _lastPercentBase),
              getARed(_pID, _lastPercentBase).div(100),
              plyr_[_pID].store,
              _pID,
              plyr_[_pID].name
              );
    }

    function getAccountTotal(address _account)
      public
      view
      returns(uint256 totalWhite,
              uint256 totalRefundEth,
              uint256 totalAffWhite,
              uint256 totalStore,
              uint256 totalWithdrawRed,
              uint256 totalRed,
              uint256 totalEthIn,
              uint256 totalEthOut
              )
    {
      uint256 _pID = pIDxAddr_[_account];
      // require(_pID != 0, "error account address");
      uint256 _lastWhite = systemInfo.lastWhite;
      uint256 _lastWhiteBase = systemInfo.lastWhiteBase;
      uint256 _lastPercentBase = systemInfo.lastPercentBase;      

      if(block.timestamp >= systemInfo.nextDistributeTime){
        uint256 rnd = block.timestamp.sub(systemInfo.nextDistributeTime).div(roundTime) + 1;
        _lastWhite = systemInfo.tWhite;
        _lastWhiteBase = systemInfo.tWhiteBase;
        _lastPercentBase = updatePercentBase(rnd, _lastWhite, _lastWhiteBase);
      }

      return(plyrHis_[_pID].tWhite,
              plyrHis_[_pID].tRefundEth,
              plyrHis_[_pID].tAffWhite,
              plyrHis_[_pID].tStore,
              plyrHis_[_pID].tWithdrawRed,
              getTRed(plyrHis_[_pID].tWhite, plyrHis_[_pID].tWhiteBase, _lastPercentBase),
              plyrHis_[_pID].ethIn,
              plyrHis_[_pID].ethOut
             );
    }

    function getSystemInfo()
      public
      view
      returns(uint256 nextDistributeTime,
              uint256 noMasterEth,
              uint256 availableWhite,
              uint256 totalRed,
              uint256 lastRed, 
              uint256 nowRatio)
    {
      uint256 _lastWhite = systemInfo.lastWhite;
      uint256 _lastWhiteBase = systemInfo.lastWhiteBase;
      uint256 _lastPercentBase = systemInfo.lastPercentBase;
      uint256 _nextTime = systemInfo.nextDistributeTime;

      if(block.timestamp >= systemInfo.nextDistributeTime){
        uint256 rnd = block.timestamp.sub(systemInfo.nextDistributeTime).div(roundTime) + 1;
        _lastWhite = systemInfo.tWhite;
        _lastWhiteBase = systemInfo.tWhiteBase;
        _lastPercentBase = updatePercentBase(rnd, _lastWhite, _lastWhiteBase);
        _nextTime = _nextTime.add(rnd.mul(roundTime));
      }

      return (_nextTime,
              getSysRestEth(_lastWhite, _lastWhiteBase, _lastPercentBase),
              getRestWhite(systemInfo.tWhite, _lastPercentBase),
              getTRed(_lastWhite, _lastWhiteBase, _lastPercentBase),
              getTRed(_lastWhite, _lastWhiteBase, _lastPercentBase).sub(systemInfo.lastLastTRed),
              getRatio(_lastWhite, _lastWhiteBase, _lastPercentBase)
              );
    }
    
    function getRatio(uint256 _lastWhite, uint256 _lastWhiteBase, uint256 _lastPercent)
      public
      view
      returns(uint256 ratio)
    {
      if(_lastWhite > 0 && _lastWhiteBase > 0 && _lastPercent > 0){
        ratio = getSysRestEth(_lastWhite, _lastWhiteBase, _lastPercent);
      } else {
        ratio = getSysRestEth(0, 0, 0);
      }

      if(systemInfo.tWhite == 0){
        return 0;
      }
      
      ratio = ratio.mul(1 ether).mul(100).div(180).div(systemInfo.tWhite);
      if(ratio > ratioMax_){
        return ratioMax_;
      }

      return ratio;
    }

    function getSysRestEth(uint256 _lastWhite, uint256 _lastWhiteBase, uint256 _lastPercent)
      public
      view
      returns(uint256)
    {
      if(_lastWhite > 0 && _lastWhiteBase > 0 && _lastPercent > 0){
        return systemInfo.ethIn.sub(getTEth(_lastWhite, _lastWhiteBase, _lastPercent));
      }
      
      return systemInfo.ethIn.sub(getTEth(systemInfo.lastWhite, systemInfo.lastWhiteBase, 0));
    }

    function getAEth(uint256 _pID, uint256 _lastPercent)
      public
      view
      returns(uint256)
    {
      return getARed(_pID, _lastPercent).div(100);
    }

    function getTEth(uint256 _white, uint256 _whiteBase, uint256 _lastPercent)
      public
      view
      returns(uint256)
    {
      return getTRed(_white, _whiteBase, _lastPercent).div(100);
    }

    function getARed(uint256 _pID, uint256 _lastPercent)
      public
      view
      returns(uint256)
    {
      return getTRed(plyrHis_[_pID].tWhite, plyrHis_[_pID].tWhiteBase, _lastPercent).sub(plyrHis_[_pID].tWithdrawRed);
    }

    function getTRed(uint256 _white, uint256 _whiteBase, uint256 _lastPercent)
      public
      view
      returns(uint256)
    {
      return _white.sub(getRestWhite(_whiteBase, _lastPercent));
    }

    function getRestWhite(uint256 _whiteBase, uint256 _lastPercent)
      public
      view
      returns(uint256)
    {
      if(_lastPercent > 0){
        return _whiteBase.mul(_lastPercent).div(1 ether);
      }
      return _whiteBase.mul(systemInfo.lastPercentBase).div(1 ether);
    }

    function stringToBytes32(string memory source)
      public
      pure
      returns (bytes32 result)
    {
      assembly {
      result := mload(add(source, 32))
          }
    }

    function bytes32ToString(bytes32 x)
      public
      pure
      returns (string)
    {
      bytes memory bytesString = new bytes(32);
      uint charCount = 0;
      for (uint j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
          bytesString[charCount] = char;
          charCount++;
        }
      }
      bytes memory bytesStringTrimmed = new bytes(charCount);
      for (j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
      }
      return string(bytesStringTrimmed);
    }
}

library TokenDataSets {
    struct Player{
      address addr;
      bytes32 name;
      uint256 affID;
      uint256 store;
    }

    struct PlayerHis{
      uint256 tWhite;
      uint256 tWhiteBase;
      
      uint256 tRefundEth;
      uint256 tAffWhite;
      uint256 tStore;
      uint256 tWithdrawRed;
      uint256 ethIn;
      uint256 ethOut;
    }      

    struct System{
      uint256 nextDistributeTime;
      uint256 roundIdx;
        
      uint256 ethIn;
      uint256 ethOut;
      uint256 tWhite;
      uint256 tStore;

      uint256 tWhiteBase;
      
      uint256 lastPercentBase;
      uint256 lastWhite;
      uint256 lastWhiteBase;
      uint256 lastLastTRed;
    }
}
        
        
library NameFilter {
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
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
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
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }

  function average(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // (_a + _b) / 2 can overflow, so we distribute
    return (_a / 2) + (_b / 2) + ((_a % 2 + _b % 2) / 2);
  }
}