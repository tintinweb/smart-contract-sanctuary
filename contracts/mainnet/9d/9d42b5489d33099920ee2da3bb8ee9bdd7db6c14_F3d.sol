pragma solidity ^0.4.24;

contract F3Devents {
  event Winner(address winner, uint256 pool, address revealer);
  event Buy(address buyer, uint256 keys, uint256 cost);
  event Sell(address from, uint256 price, uint256 count);
  event Bought(address buyer, address from, uint256 amount, uint256 price);
}

contract F3d is F3Devents {
  using SafeMath for *;

  
  uint256 public a;    // key price parameter                    15825000
  uint256 public b;    // key price parameter                    749999139625000

  uint256 public ta;   // percentage goes to pool                37.5
  uint256 public tb;   // percentage goes to split               38.5
  uint256 public tc;   // percentage goes to ref1                15
  uint256 public td;   // percentage goes to ref2                5
  uint256 public te;   // percentage goes to owner               4

  uint256 public wa;   // percentage of pool goes to winner      50
  uint256 public wb;   // percentage of pool goes to next pool   16.6
  uint256 public wc;   // percentage of pool goes to finalizer   0.5
  uint256 public wd;   // percentage of pool goes to owner       2.6
  uint256 public we;   // percentage of pool goes to split       30.3

  uint256 public maxTimeRemain;                     //           4 * 60 * 60
  uint256 public timeGap;                           //           5 * 60
  
  uint256 public soldKeys;                          //           0

  uint256 public decimals = 1000000;
  
  bool public pause;
  address public owner;
  address public admin;

  PlayerStatus[] public players;
  mapping(address => uint256) public playerIds;
  mapping(uint256 => Round) public rounds;
  mapping(uint256 => mapping (uint256 => PlayerRound)) public playerRoundData;
  uint256 public currentRound;
  
  struct PlayerStatus {
    address addr;          //player addr
    uint256 wallet;        //get from spread
    uint256 affiliate;     //get from reference
    uint256 win;           //get from winning
    uint256 lrnd;          //last round played
    uint256 referer;       //who introduced this player
  }
  
  struct PlayerRound {
      uint256 eth;         //eth player added to this round
      uint256 keys;        //keys player bought in this round
      uint256 mask;        //player mask in this round
  }
  
  struct Round {
      uint256 eth;         //eth to this round
      uint256 keys;        //keys sold in this round
      uint256 mask;        //mask of this round
      address winner;      //winner of this round
      uint256 pool;        //the amount of pool when ends
      uint256 endTime;     //the end time
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier whenNotPaused() {
    require(!pause);
    _;
  }

  modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
  }
  
  function setPause(bool _pause) onlyAdmin public {
    pause = _pause;
  }

  constructor(uint256 _a, uint256 _b, 
  uint256 _ta, uint256 _tb, uint256 _tc, uint256 _td, uint256 _te,
  uint256 _wa, uint256 _wb, uint256 _wc, uint256 _wd, uint256 _we,
  uint256 _maxTimeRemain, uint256 _gap, address _owner) public {
    a = _a;
    b = _b;

    ta = _ta;
    tb = _tb;
    tc = _tc;
    td = _td;
    te = _te;
    
    wa = _wa;
    wb = _wb;
    wc = _wc;
    wd = _wd;
    we = _we;
    
    // split less than 100%
    require(ta.add(tb).add(tc).add(td).add(te) == 1000);
    require(wa.add(wb).add(wc).add(wd).add(we) == 1000);

    owner = _owner;

    // start from first round
    currentRound = 1;
    rounds[currentRound] = Round(0, 0, 0, owner, 0, block.timestamp.add(_maxTimeRemain));
    maxTimeRemain = _maxTimeRemain;
    timeGap = _gap;
    
    admin = msg.sender;
    // the first player is the owner
    players.push(PlayerStatus(
        owner,
        0,
        0,
        0,
        0,
        0));
  }

  // return the price for nth key  n = keys / decimals
  function Price(uint256 n) public view returns (uint256) {
    return n.mul(a).add(b);
  }

  function updatePlayer(uint256 _pID) private {
      if(players[_pID].lrnd != 0) {
          updateWallet(_pID, players[_pID].lrnd);
      }
      players[_pID].lrnd = currentRound;
  }
  
  function updateWallet(uint256 _pID, uint256 _round) private {
      uint256 earnings = calculateMasked(_pID, _round);
      if (earnings > 0) {
          players[_pID].wallet = earnings.add(players[_pID].wallet);
          playerRoundData[_pID][_round].mask = earnings.add(playerRoundData[_pID][_round].mask);
      }
  }
  
  function profit() public view returns (uint256) {
      uint256 id = playerIds[msg.sender];
      if (id == 0 && msg.sender != owner) {
          return 0;
      }
      PlayerStatus memory player = players[id];
      
      return player.wallet.add(player.affiliate).add(player.win).add(calculateMasked(id, player.lrnd));
  }
  
  function calculateMasked(uint256 _pID, uint256 _round) private view returns (uint256) {
      PlayerRound memory roundData = playerRoundData[_pID][_round];
      return rounds[_round].mask.mul(roundData.keys).sub(roundData.mask);
  }
  
  function registerUserIfNeeded(uint256 ref) public {
      if (msg.sender != owner) {
          if (playerIds[msg.sender] == 0) {
              playerIds[msg.sender] = players.length;
              if (ref >= players.length) {
                  ref = 0;
              }
              
              players.push(PlayerStatus(
                  msg.sender,
                  0,
                  0,
                  0,
                  0,
                  ref));
          }
      }
  }
  
  // anyone can finalize a round
  function finalize(uint256 ref) public {
      Round storage lastOne = rounds[currentRound];
      // round must be finished
      require(block.timestamp > lastOne.endTime);
      
      // register the user if necessary
      registerUserIfNeeded(ref);

      // new round has started
      currentRound = currentRound.add(1);
      Round storage _round = rounds[currentRound];
      _round.endTime = block.timestamp.add(maxTimeRemain);
      _round.winner = owner;            
      // save the round data
      uint256 money = lastOne.pool;
      
      if (money == 0) {
          // nothing happend in last round
          return;
      }
      // to pool
      _round.pool = money.mul(wb) / 1000;

      // to winner
      uint256 toWinner = money.mul(wa) / 1000;
      players[playerIds[lastOne.winner]].win = toWinner.add(players[playerIds[lastOne.winner]].win);
      
      // to revealer
      uint256 toRevealer = money.mul(wc) / 1000;
      uint256 revealId = playerIds[msg.sender];
      
      // self reveal, no awards
      if (msg.sender == lastOne.winner) {
          revealId = 0;
      }
      
      players[revealId].win = players[revealId].win.add(toRevealer);
      
      uint256 toOwner = money.mul(wd) / 1000;
      players[0].win = players[0].win.add(toOwner);
      
      uint256 split = money.sub(_round.pool).sub(toWinner).sub(toRevealer).sub(toOwner);
      
      if (lastOne.keys != 0) {
          lastOne.mask = lastOne.mask.add(split / lastOne.keys);
          // gather the dust
          players[0].wallet = players[0].wallet.add(split.sub((split/lastOne.keys) * lastOne.keys));
      } else {
          // last round no one bought any keys, sad
          // put the split into next round
          _round.pool = split.add(_round.pool);
      }
  }
  
  function price(uint256 key) public view returns (uint256) {
      return a.mul(key).add(b);
  }
  
  function ethForKey(uint256 _keys) public view returns (uint256) {
      Round memory current = rounds[currentRound];
      uint256 c_key = (current.keys / decimals);
      
      // in (a, a + 1], we use price(a + 1)
      if (c_key.mul(decimals) != current.keys) {
          c_key = c_key.add(1);
      }
      
      uint256 _price = price(c_key);
      uint256 remainKeys = c_key.mul(decimals).sub(current.keys);

      if (remainKeys >= _keys) {
          return _price.mul(_keys) / decimals;
      } 
      
      uint256 costEth = _price.mul(_keys) / decimals;
      _keys = _keys.sub(remainKeys);
      
      while(_keys >= decimals) {
          c_key = c_key.add(1);
          _price = price(c_key);
          costEth = costEth.add(_price);
          _keys = _keys.sub(decimals);
      }
    
      c_key = c_key.add(1);
      _price = price(c_key);

      costEth = costEth.add(_price.mul(_keys) / decimals);
      return costEth;
  }

  // the keys that one could buy at a stage using _eth
  function keys(uint256 _eth) public view returns (uint256) {
      Round memory current = rounds[currentRound];
      
      uint256 c_key = (current.keys / decimals).add(1);
      uint256 _price = price(c_key);
      uint256 remainKeys = c_key.mul(decimals).sub(current.keys);
      uint256 remain =remainKeys.mul(_price) / decimals;
      
      if (remain >= _eth) {
          return _eth.mul(decimals) / _price;
      }
      uint256 boughtKeys = remainKeys;
      _eth = _eth.sub(remain);
      while(true) {
          c_key = c_key.add(1);
          _price = price(c_key);
          if (_price <= _eth) {
              // buy a whole unit
              boughtKeys = boughtKeys.add(decimals);
              _eth = _eth.sub(_price);
          } else {
              boughtKeys = boughtKeys.add(_eth.mul(decimals) / _price);
              break;
          }
      }
      return boughtKeys;
  }
  
  // _pID spent _eth to buy keys in _round
  function core(uint256 _round, uint256 _pID, uint256 _eth) internal {
      Round memory current = rounds[currentRound];

      // new to this round
      if (playerRoundData[_pID][_round].keys == 0) {
          updatePlayer(_pID);
      }
      
      if (block.timestamp > current.endTime) {
          //we need to do finalzing
          finalize(players[_pID].referer);
          
          //new round generated, we need to update the user status to the new round 
          updatePlayer(_pID);
      }
      
      // retrive the current round obj again, in case it changed
      Round storage current_now = rounds[currentRound];
      
      // calculate the keys that he could buy
      uint256 _keys = keys(_eth);
      
      if (_keys <= 0) {
          // put the eth to the sender
          // sorry, you&#39;re bumped
          players[_pID].wallet = _eth.add(players[_pID].wallet);
          return;
      }

      if (_keys >= decimals) {
          // buy at least one key to be the winner 
          current_now.winner = players[_pID].addr;
          current_now.endTime = current_now.endTime.add(timeGap);
          if (current_now.endTime.sub(block.timestamp) > maxTimeRemain) {
              current_now.endTime = block.timestamp.add(maxTimeRemain);
          }
      }
      
      //now we do the money distribute
      uint256 toOwner = _eth.sub(_eth.mul(ta) / 1000);
      toOwner = toOwner.sub(_eth.mul(tb) / 1000);
      toOwner = toOwner.sub(_eth.mul(tc) / 1000);
      toOwner = toOwner.sub(_eth.mul(td) / 1000);
      
      // to pool
      current_now.pool = (_eth.mul(ta) / 1000).add(current_now.pool);
      
      if (current_now.keys == 0) {
          // current no keys to split, send to owner
          toOwner = toOwner.add((_eth.mul(tb) / 1000));
          players[0].wallet = toOwner.add(players[0].wallet);
      } else {
          current_now.mask = current_now.mask.add((_eth.mul(tb) / 1000) / current_now.keys);
          // dust to owner;
          // since the _eth will > 0, so the division is ok
          uint256 dust = (_eth.mul(tb) / 1000).sub( _eth.mul(tb) / 1000 / current_now.keys * current_now.keys );
          players[0].wallet = toOwner.add(dust).add(players[0].wallet);
      }
      // the split doesnt include keys that the user just bought
      playerRoundData[_pID][currentRound].keys = _keys.add(playerRoundData[_pID][currentRound].keys);
      current_now.keys = _keys.add(current_now.keys);
      current_now.eth = _eth.add(current_now.eth);

      // for the new keys, remove the user&#39;s free earnings
      playerRoundData[_pID][currentRound].mask = current_now.mask.mul(_keys).add(playerRoundData[_pID][currentRound].mask);
      
      // to ref 1, 2
      uint256 referer1 = players[_pID].referer;
      uint256 referer2 = players[referer1].referer;
      players[referer1].affiliate = (_eth.mul(tc) / 1000).add(players[referer1].affiliate);
      players[referer2].affiliate = (_eth.mul(td) / 1000).add(players[referer2].affiliate);
  }
  
  // calculate the keys that the user can buy with specified amount of eth
  // return the eth left
  function BuyKeys(uint256 ref) payable whenNotPaused public {
      registerUserIfNeeded(ref);
      core(currentRound, playerIds[msg.sender], msg.value);
  }

  function ReloadKeys(uint256 value, uint256 ref) whenNotPaused public {
      registerUserIfNeeded(ref);
      players[playerIds[msg.sender]].wallet = retrieveEarnings().sub(value);
      core(currentRound, playerIds[msg.sender], value);
  }
  
  function retrieveEarnings() internal returns (uint256) {
      uint256 id = playerIds[msg.sender];
      updatePlayer(id);
      PlayerStatus storage player = players[id];
      
      uint256 earnings = player.wallet.add(player.affiliate).add(player.win);
      
      if (earnings == 0) {
          return;
      }
      
      player.wallet = 0;
      player.affiliate = 0;
      player.win = 0;
      return earnings;
  }
  
  // withdrawal all the earning of the game
  function withdrawal(uint256 ref) whenNotPaused public {
      registerUserIfNeeded(ref);
      
      uint256 earnings = retrieveEarnings();
      if (earnings == 0) {
          return;
      }
      msg.sender.transfer(earnings);
  }

  function playerCount() public view returns (uint256) {
      return players.length;
  }
  
  function register(uint256 ref) public whenNotPaused {
    registerUserIfNeeded(ref);
  }
  
  function remainTime() public view returns (uint256) {
      if (rounds[currentRound].endTime <= block.timestamp) {
          return 0;
      } else {
          return rounds[currentRound].endTime - block.timestamp;
      }
  }
}


/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
}