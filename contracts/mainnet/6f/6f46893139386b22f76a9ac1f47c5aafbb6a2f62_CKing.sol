pragma solidity ^0.4.24;

// File: contracts\utils\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  /**
  * @dev gives square root of given x.
  */
  function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y)
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y)
    {
        y = z;
        z = ((add((x / z),z)) / 2);
    }
  }

  /**
  * @dev gives square. multiplies x by x
  */
  function sq(uint256 x)
    internal
    pure
    returns (uint256)
  {
    return (mul(x,x));
  }

  /**
  * @dev x to the power of y
  */
  function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else
    {
        uint256 z = x;
        for (uint256 i=1; i < y; i++)
            z = mul(z,x);
        return (z);
    }
  }
}

// File: contracts\CKingCal.sol

library CKingCal {

  using SafeMath for *;
  /**
  * @dev calculates number of keys received given X eth
  * @param _curEth current amount of eth in contract
  * @param _newEth eth being spent
  * @return amount of ticket purchased
  */
  function keysRec(uint256 _curEth, uint256 _newEth)
    internal
    pure
    returns (uint256)
  {
    return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
  }

  /**
  * @dev calculates amount of eth received if you sold X keys
  * @param _curKeys current amount of keys that exist
  * @param _sellKeys amount of keys you wish to sell
  * @return amount of eth received
  */
  function ethRec(uint256 _curKeys, uint256 _sellKeys)
    internal
    pure
    returns (uint256)
  {
    return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
  }

  /**
  * @dev calculates how many keys would exist with given an amount of eth
  * @param _eth total ether received.
  * @return number of keys that would exist
  */
  function keys(uint256 _eth)
    internal
    pure
    returns(uint256)
  {
      // sqrt((eth*1 eth* 312500000000000000000000000)+5624988281256103515625000000000000000000000000000000000000000000) - 74999921875000000000000000000000) / 15625000
      return ((((((_eth).mul(1000000000000000000)).mul(31250000000000000000000000)).add(56249882812561035156250000000000000000000000000000000000000000)).sqrt()).sub(7499992187500000000000000000000)) / (15625000);
  }  

  /**
  * @dev calculates how much eth would be in contract given a number of keys
  * @param _keys number of keys "in contract"
  * @return eth that would exists
  */
  function eth(uint256 _keys)
    internal
    pure
    returns(uint256)
  {
    // (149999843750000*keys*1 eth) + 78125000 * keys * keys) /2 /(sq(1 ether))
    return ((7812500).mul(_keys.sq()).add(((14999984375000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
  }
}

// File: contracts\utils\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts\TowerCKing.sol

contract CKing is Ownable {
  using SafeMath for *;
  using CKingCal for uint256;


  string constant public name = "Cryptower";
  string constant public symbol = "CT";

  // time constants;
  uint256 constant private timeInit = 1 weeks; // 600; //1 week 
  uint256 constant private timeInc = 30 seconds; //60 ///////
  uint256 constant private timeMax = 30 minutes; // 300

  // profit distribution parameters
  uint256 constant private fixRet = 46;
  uint256 constant private extraRet = 10;
  uint256 constant private affRet = 10;
  uint256 constant private gamePrize = 12;
  uint256 constant private groupPrize = 12;
  uint256 constant private devTeam = 10;

  // player data
  struct Player {
    address addr; // player address
    string name; // playerName
    uint256 aff;  // affliliate vault
    uint256 affId; // affiliate id, who referered u
    uint256 hretKeys; // number of high return keys
    uint256 mretKeys; // number of medium return keys
    uint256 lretKeys; // number of low return keys
    uint256 eth;      // total eth spend for the keys
    uint256 ethWithdraw; // earning withdrawed by user
  }

  mapping(uint256 => Player) public players; // player data
  mapping(address => uint) public addrXpId; // player address => pId
  uint public playerNum = 0;

  // game info
  uint256 public totalEther;     // total key sale revenue
  uint256 public totalKeys;      // total number of keys.
  uint256 private constant minPay = 1000000000; // minimum pay to buy keys or deposit in game;
  uint256 public totalCommPot;   // total ether going to be distributed
  uint256 private keysForGame;    // keys belongs to the game for profit distribution
  uint256 private gamePot;        // ether need to be distributed based on the side chain game
  uint256 public teamWithdrawed; // eth withdrawed by dev team. 
  uint256 public gameWithdrawed; // ether already been withdrawn from game pot 
  uint256 public endTime;        // main game end time
  address public CFO;
  address public COO; 
  address public fundCenter; 
  address public playerBook; 



  uint private stageId = 1;   // stageId start 1
  uint private constant groupPrizeStartAt = 2000000000000000000000000; // 1000000000000000000000;
  uint private constant groupPrizeStageGap = 100000000000000000000000; // 100000000000000000000
  mapping(uint => mapping(uint => uint)) public stageInfo; // stageId => pID => keys purchased in this stage

  // admin params
  uint256 public startTime;  // admin set start
  uint256 constant private coolDownTime = 2 days; // team is able to withdraw fund 2 days after game end.

  modifier isGameActive() {
    uint _now = now;
    require(_now > startTime && _now < endTime);
    _;
  }
  
  modifier onlyCOO() {
    require(COO == msg.sender, "Only COO can operate.");
    _; 
  }

  // events
  event BuyKey(uint indexed _pID, uint _affId, uint _keyType, uint _keyAmount);
  event EarningWithdraw(uint indexed _pID, address _addr, uint _amount);


  constructor(address _CFO, address _COO, address _fundCenter, address _playerBook) public {
    CFO = _CFO;
    COO = _COO; 
    fundCenter = _fundCenter; 
    playerBook = _playerBook; 
  }
    
  function setCFO(address _CFO) onlyOwner public {
    CFO = _CFO; 
  }  
  
  function setCOO(address _COO) onlyOwner public {
    COO = _COO; 
  }  
  
  function setContractAddress(address _fundCenter, address _playerBook) onlyCOO public {
    fundCenter = _fundCenter; 
    playerBook = _playerBook; 
  }

  function startGame(uint _startTime) onlyCOO public {
    require(_startTime > now);
    startTime = _startTime;
    endTime = startTime.add(timeInit);
  }
  
  function gameWithdraw(uint _amount) onlyCOO public {
    // users may choose to withdraw eth from cryptower game, allow dev team to withdraw eth from this contract to fund center. 
    uint _total = getTotalGamePot(); 
    uint _remainingBalance = _total.sub(gameWithdrawed); 
    
    if(_amount > 0) {
      require(_amount <= _remainingBalance);
    } else{
      _amount = _remainingBalance;
    }
    
    fundCenter.transfer(_amount); 
    gameWithdrawed = gameWithdrawed.add(_amount); 
  }


  function teamWithdraw(uint _amount) onlyCOO public {
    uint256 _now = now;
    if(_now > endTime.add(coolDownTime)) {
      // dev team have rights to withdraw all remaining balance 2 days after game end. 
      // if users does not claim their ETH within coolDown period, the team may withdraw their remaining balance. Users can go to crytower game to get their ETH back.
      CFO.transfer(_amount);
      teamWithdrawed = teamWithdrawed.add(_amount); 
    } else {
        uint _total = totalEther.mul(devTeam).div(100); 
        uint _remainingBalance = _total.sub(teamWithdrawed); 
        
        if(_amount > 0) {
            require(_amount <= _remainingBalance);
        } else{
            _amount = _remainingBalance;
        }
        CFO.transfer(_amount);
        teamWithdrawed = teamWithdrawed.add(_amount); 
    }
  }
  

  function updateTimer(uint256 _keys) private {
    uint256 _now = now;
    uint256 _newTime;

    if(endTime.sub(_now) < timeMax) {
        _newTime = ((_keys) / (1000000000000000000)).mul(timeInc).add(endTime);
        if(_newTime.sub(_now) > timeMax) {
            _newTime = _now.add(timeMax);
        }
        endTime = _newTime;
    }
  }
  
  function receivePlayerInfo(address _addr, string _name) external {
    require(msg.sender == playerBook, "must be from playerbook address"); 
    uint _pID = addrXpId[_addr];
    if(_pID == 0) { // player not exist yet. create one 
        playerNum = playerNum + 1;
        Player memory p; 
        p.addr = _addr;
        p.name = _name; 
        players[playerNum] = p; 
        _pID = playerNum; 
        addrXpId[_addr] = _pID;
    } else {
        players[_pID].name = _name; 
    }
  }

  function buyByAddress(uint256 _affId, uint _keyType) payable isGameActive public {
    uint _pID = addrXpId[msg.sender];
    if(_pID == 0) { // player not exist yet. create one
      playerNum = playerNum + 1;
      Player memory p;
      p.addr = msg.sender;
      p.affId = _affId;
      players[playerNum] = p;
      _pID = playerNum;
      addrXpId[msg.sender] = _pID;
    }
    buy(_pID, msg.value, _affId, _keyType);
  }

  function buyFromVault(uint _amount, uint256 _affId, uint _keyType) public isGameActive  {
    uint _pID = addrXpId[msg.sender];
    uint _earning = getPlayerEarning(_pID);
    uint _newEthWithdraw = _amount.add(players[_pID].ethWithdraw);
    require(_newEthWithdraw < _earning); // withdraw amount cannot bigger than earning
    players[_pID].ethWithdraw = _newEthWithdraw; // update player withdraw
    buy(_pID, _amount, _affId, _keyType);
  }

  function getKeyPrice(uint _keyAmount) public view returns(uint256) {
    if(now > startTime) {
      return totalKeys.add(_keyAmount).ethRec(_keyAmount);
    } else { // copy fomo init price
      return (7500000000000);
    }
  }

  function buy(uint256 _pID, uint256 _eth, uint256 _affId, uint _keyType) private {

    if (_eth > minPay) { // bigger than minimum pay
      players[_pID].eth = _eth.add(players[_pID].eth);
      uint _keys = totalEther.keysRec(_eth);
      //bought at least 1 whole key
      if(_keys >= 1000000000000000000) {
        updateTimer(_keys);
      }

      //update total ether and total keys
      totalEther = totalEther.add(_eth);
      totalKeys = totalKeys.add(_keys);
      // update game portion
      uint256 _game = _eth.mul(gamePrize).div(100);
      gamePot = _game.add(gamePot);


      // update player keys and keysForGame
      if(_keyType == 1) { // high return key
        players[_pID].hretKeys  = _keys.add(players[_pID].hretKeys);
      } else if (_keyType == 2) {
        players[_pID].mretKeys = _keys.add(players[_pID].mretKeys);
        keysForGame = keysForGame.add(_keys.mul(extraRet).div(fixRet+extraRet));
      } else if (_keyType == 3) {
        players[_pID].lretKeys = _keys.add(players[_pID].lretKeys);
        keysForGame = keysForGame.add(_keys);
      } else { // keytype unknown.
        revert();
      }
      //update affliliate gain
      if(_affId != 0 && _affId != _pID && _affId <= playerNum) { // udate players
          uint256 _aff = _eth.mul(affRet).div(100);
          players[_affId].aff = _aff.add(players[_affId].aff);
          totalCommPot = (_eth.mul(fixRet+extraRet).div(100)).add(totalCommPot);
      } else { // addId == 0 or _affId is self, put the fund into earnings per key
          totalCommPot = (_eth.mul(fixRet+extraRet+affRet).div(100)).add(totalCommPot);
      }
      // update stage info
      if(totalKeys > groupPrizeStartAt) {
        updateStageInfo(_pID, _keys);
      }
      emit BuyKey(_pID, _affId, _keyType, _keys);
    } else { // if contribute less than the minimum conntribution return to player aff vault
      players[_pID].aff = _eth.add(players[_pID].aff);
    }
  }

  function updateStageInfo(uint _pID, uint _keyAmount) private {
    uint _stageL = groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1));
    uint _stageH = groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId));
    if(totalKeys > _stageH) { // game has been pushed to next stage
      stageId = (totalKeys.sub(groupPrizeStartAt)).div(groupPrizeStageGap) + 1;
      _keyAmount = (totalKeys.sub(groupPrizeStartAt)) % groupPrizeStageGap;
      stageInfo[stageId][_pID] = stageInfo[stageId][_pID].add(_keyAmount);
    } else {
      if(_keyAmount < totalKeys.sub(_stageL)) {
        stageInfo[stageId][_pID] = stageInfo[stageId][_pID].add(_keyAmount);
      } else {
        _keyAmount = totalKeys.sub(_stageL);
        stageInfo[stageId][_pID] = stageInfo[stageId][_pID].add(_keyAmount);
      }
    }
  }

  function withdrawEarning(uint256 _amount) public {
    address _addr = msg.sender;
    uint256 _pID = addrXpId[_addr];
    require(_pID != 0);  // player must exist

    uint _earning = getPlayerEarning(_pID);
    uint _remainingBalance = _earning.sub(players[_pID].ethWithdraw);
    if(_amount > 0) {
      require(_amount <= _remainingBalance);
    }else{
      _amount = _remainingBalance;
    }


    _addr.transfer(_amount);  // transfer remaining balance to
    players[_pID].ethWithdraw = players[_pID].ethWithdraw.add(_amount);
  }

  function getPlayerEarning(uint256 _pID) view public returns (uint256) {
    Player memory p = players[_pID];
    uint _gain = totalCommPot.mul(p.hretKeys.add(p.mretKeys.mul(fixRet).div(fixRet+extraRet))).div(totalKeys);
    uint _total = _gain.add(p.aff);
    _total = getWinnerPrize(_pID).add(_total);
    return _total;
  }

  function getPlayerWithdrawEarning(uint _pid) public view returns(uint){
    uint _earning = getPlayerEarning(_pid);
    return _earning.sub(players[_pid].ethWithdraw);
  }

  function getWinnerPrize(uint256 _pID) view public returns (uint256) {
    uint _keys;
    uint _pKeys;
    if(now < endTime) {
      return 0;
    } else if(totalKeys > groupPrizeStartAt) { // keys in the winner stage share the group prize
      _keys = totalKeys.sub(groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1)));
      _pKeys = stageInfo[stageId][_pID];
      return totalEther.mul(groupPrize).div(100).mul(_pKeys).div(_keys);
    } else { // totalkeys does not meet the minimum group prize criteria, all keys share the group prize
      Player memory p = players[_pID];
      _pKeys = p.hretKeys.add(p.mretKeys).add(p.lretKeys);
      return totalEther.mul(groupPrize).div(100).mul(_pKeys).div(totalKeys);
    }
  }

  function getWinningStageInfo() view public returns (uint256 _stageId, uint256 _keys, uint256 _amount) {
    _amount = totalEther.mul(groupPrize).div(100);
    if(totalKeys < groupPrizeStartAt) { // group prize is not activate yet
      return (0, totalKeys, _amount);
    } else {
      _stageId = stageId;
      _keys = totalKeys.sub(groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1)));
      return (_stageId, _keys, _amount);
    }
  }

  function getPlayerStageKeys() view public returns (uint256 _stageId, uint _keys, uint _pKeys) {
    uint _pID = addrXpId[msg.sender];
    if(totalKeys < groupPrizeStartAt) {
      Player memory p = players[_pID];
      _pKeys = p.hretKeys.add(p.mretKeys).add(p.lretKeys);
      return (0, totalKeys, _pKeys);
    } else {
      _stageId = stageId;
      _keys = totalKeys.sub(groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1)));
      _pKeys = stageInfo[_stageId][_pID];
      return (_stageId, _keys, _pKeys);
    }

  }

  function getTotalGamePot() view public returns (uint256) {
    uint _gain = totalCommPot.mul(keysForGame).div(totalKeys);
    uint _total = _gain.add(gamePot);
    return _total;
  }
  
}