pragma solidity ^0.4.24;

contract F3Devents {
    
  // winner has win round of value
  event Winner(address winner, uint256 round, uint256 value);
  
  event Buy(address buyer, uint256 keys, uint256 cost, uint256 round);

  event Lucky(address buyer, uint256 round, uint256 lucky, uint256 amount);
  
  event Register(address user, uint256 id, uint256 value, uint256 ref);
  
  event Referer(address referral, uint256 pUser);          //referral has been recommended by pUser
  
  event NewRound(uint256 round, uint256 pool);
  
  event FinalizeRound(uint256 round);
  
  event Withdrawal(address player, uint256 amount, uint256 fee);
}

contract F3d is F3Devents {
  using SafeMath for *;


  // uint256 public maxProfit;                          // user win maximum                         5
  uint256 public luckyNumber;                           //every luckyNumber user get extra win      888
  
  uint256 public toSpread;                              //percentage goes to holder                 580
  uint256 public toOwner;                               //percentage goes to owner                  20
  uint256 public toNext;                                //percentage goes to next round             50
  uint256 public toRefer;                               //goes to refer                             100
  uint256 public toPool;                                //goes to pool                              250
  
  uint256 public toLucky;                               //goes to lucky guy, which                  294
  
  // uint256 public roundTime;                          //time length of each round                 24 * 60 * 60
  uint256 public timeIncrease;                          //time increase when user buy keys          60
  uint256 public maxRound;                              //the maximum round number                  12
  uint256 public registerFee;                           //fee for register                          0.01ether
  uint256 public withdrawFee;
  uint256 public minimumWithdraw;
  
  uint256 public playersCount;                          //number of registerted players
  
  uint256 public decimals = 10 ** 18;

  
  bool public pause;
  uint256 public ownerPool;
  address public admin;

  mapping(address => PlayerStatus) public players;
  mapping(address => uint256) public playerIds;
  mapping(uint256 => address) public id2Players;
  mapping(uint256 => Round) public rounds;
  mapping(address => mapping (uint256 => PlayerRound)) public playerRoundData;
  // uint256 public currentRound;                       seems we don&#39;t need this
  uint256 public nextRound;
  
    
  address public owner1=0x6779043e0f2A0bE96D1532fD07EAa1072E018F22;
  address public owner2=0xa8c5Bcb8547b434Dfd55bbAAf0b15d07BCdCa04f;
  bool public owner1OK;
  bool public owner2OK;
  uint256 public ownerWithdraw;
  address public ownerWithdrawTo;
  
  function kill() public{// only allow this action if the account sending the signal is the creator
      if (msg.sender == admin){
          selfdestruct(admin);       // kills this contract and sends remaining funds back to creator
      }  
  }
  function ownerTake(uint256 amount, address to) public onlyOwner {
      require(!owner1OK && !owner2OK);
      ownerWithdrawTo = to;
      ownerWithdraw = amount;
      if (msg.sender == owner1) {
          owner1OK = true;
      }
      if (msg.sender == owner2) {
          owner2OK = true;
      }
  }
  
  function agree(uint256 amount, address to) public onlyOwner {
      require(amount == ownerWithdraw && to == ownerWithdrawTo);
      if(msg.sender == owner1) {
          require(owner2OK);
      }
      if(msg.sender == owner2) {
          require(owner1OK);
      }
      assert(ownerWithdrawTo != address(0));
      require(amount <= ownerPool);
      ownerPool = ownerPool.sub(amount);
      ownerWithdrawTo.transfer(amount);
      owner1OK = false;
      owner2OK = false;
      ownerWithdraw = 0;
      ownerWithdrawTo = address(0);
  }
  
  function cancel() onlyOwner public {
      owner1OK = false;
      owner2OK = false;
      ownerWithdraw = 0;
      ownerWithdrawTo = address(0);
  }
  
  struct PlayerStatus {
    address addr;          //player addr
    uint256 wallet;        //get from spread
    uint256 affiliate;     //get from reference
    uint256 win;           //get from winning
    uint256 lucky;          //eth get from lucky
    uint256 referer;       //who introduced this player
  }
  
  struct PlayerRound {
      uint256 eth;         //eth player added to this round
      uint256 keys;        //keys player bought in this round
      uint256 mask;        //player mask in this round
      uint256 lucky;       //player lucky profit in this round
      uint256 affiliate;   //player affiliate in this round
      uint256 win;        //player pool in this round
  }
  
  struct Round {
      uint256 eth;                //eth to this round
      uint256 keys;               //keys sold in this round
      uint256 mask;               //mask of this round, up by 10**18
      address winner;             //winner of this round
      uint256 pool;               //the amount of pool when ends
      uint256 minimumPool;        //the minimum requirement to open a pool
      uint256 nextLucky;          //the next lucky number
      uint256 luckyCounter;       //count of luckyBuys (buy that is more than 10 keys)
      uint256 luckyPool;          //amount of eth in luckyPool
      uint256 endTime;            //the end time
      uint256 roundTime;          //different round has different round time
      bool    finalized;          //whether this round has been finalized
      bool    activated;          //whether this round has been activated
      // uint256 players;            //count of players in this round
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner1 || msg.sender == owner2);
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

  constructor(uint256 _lucky, uint256 _maxRound,
  uint256 _toSpread, uint256 _toOwner, uint256 _toNext, uint256 _toRefer, uint256 _toPool, uint256 _toLucky,
  uint256 _increase,
  uint256 _registerFee, uint256 _withdrawFee) public {
      
    luckyNumber = _lucky;
    maxRound = _maxRound;

    toSpread = _toSpread;
    toOwner = _toOwner;
    toNext = _toNext;
    toRefer = _toRefer;
    toPool = _toPool;
    toLucky = _toLucky;
    
    timeIncrease = _increase;

    registerFee = _registerFee;
    withdrawFee = _withdrawFee;
    
    assert(maxRound <= 12); //can&#39;t be more than 12, otherwise the game time will be zero
    
    // split less than 100%
    assert(toSpread.add(toOwner).add(toNext).add(toRefer).add(toPool) == 1000);

    // owner1 = _owner1;
    // owner2 = _owner2;

    // start from first round
    // currentRound = 1;
    nextRound = 1;
    playersCount = 1;  //by default there is one player
    
    uint256 _miniMumPool = 0;
    for(uint256 i = 0; i < maxRound; i ++) {
        //TESTING uint256 roundTime = 12 * 60 * 60 - 60 * 60 * (i);   //roundTime
        uint256 roundTime = 12 * 60 - 60 * (i);   //roundTime

        rounds[i] = Round(
          0,                                  //eth
          0,                                  //keys
          0,                                  //mask
          address(0),                         //winner
          0,                                  //pool
          _miniMumPool,                       //minimumPool
          luckyNumber,                        //luckyNumber
          0,                                  //luckyCounter
          0,                                  //luckyPool
          0,                                  //endTime it&#39;s not accurate
          roundTime,                          //roundTime
          false,                              //finalized
          false                               //activated
          // 0                                   //players
        );
        if(i == 0) {
          //TESTING _miniMumPool = 100 * (10 ** 18);
          _miniMumPool = 1 * (10 ** 18);
        } else {
          _miniMumPool = _miniMumPool.mul(2);
        }
    }
    admin = msg.sender;
  }

  function start1stRound() public {
      require(!rounds[0].activated);
      rounds[0].activated = true;
      rounds[0].endTime = block.timestamp.add(rounds[0].roundTime);
  }

  /*
  function roundProfitByAddr(address _pAddr, uint256 _round) public view returns (uint256) {
      return roundProfit(_pAddr, _round);
  }*/
  
  function roundProfit(address _pAddr, uint256 _round) public view returns (uint256) {
      return calculateMasked(_pAddr, _round);
  }
  
  function totalProfit(address _pAddr) public view returns (uint256) {
      uint256 masked = profit(_pAddr);
      PlayerStatus memory player = players[_pAddr];
      /*
        uint256 wallet;        //get from spread
        uint256 affiliate;     //get from reference
        uint256 win;           //get from winning
        uint256 referer;       //who introduced this player
        uint256 lucky;   
        */
      return masked.add(player.wallet).add(player.affiliate).add(player.win).add(player.lucky);
  }

  function profit(address _pAddr) public view returns (uint256) {
      uint256 userProfit = 0;
      for(uint256 i = 0; i < nextRound; i ++) {
          userProfit = userProfit.add(roundProfit(_pAddr, i));
      }
      return userProfit;
  }
  
  function calculateMasked(address _pAddr, uint256 _round) private view returns (uint256) {
      PlayerRound memory roundData = playerRoundData[_pAddr][_round];
      return (rounds[_round].mask.mul(roundData.keys) / (10**18)).sub(roundData.mask);
  }
  
  /**
   * user register a link
   */
  function register(uint256 ref) public payable {
      require(playerIds[msg.sender] == 0 && msg.value >= registerFee);
      ownerPool = msg.value.add(ownerPool);
      playerIds[msg.sender] = playersCount;
      id2Players[playersCount] = msg.sender;
      playersCount = playersCount.add(1);
      
      //maybe this player already has some profit
      players[msg.sender].referer = ref;
      
      emit Register(msg.sender, playersCount.sub(1), msg.value, ref);
  }
  
  function logRef(address addr, uint256 ref) public {
      if(players[addr].referer == 0 && ref != 0) {
          players[addr].referer = ref;
    
          emit Referer(addr, ref);
      }
  }
  
  // anyone can finalize a round
  function finalize(uint256 _round) public {
      Round storage round = rounds[_round];
      // round must be finished
      require(block.timestamp > round.endTime && round.activated && !round.finalized);
      
      // register the user if necessary
      // no automated registration now?
      // registerUserIfNeeded(ref);
    
      //finalize this round
      round.finalized = true;
      uint256 pool2Next = 0;
      if(round.winner != address(0)) {
        players[round.winner].win = round.pool.add(players[round.winner].win);
        playerRoundData[round.winner][_round].win = round.pool.add(playerRoundData[round.winner][_round].win);

        emit Winner(round.winner, _round, round.pool);
      } else {
        // ownerPool = ownerPool.add(round.pool);
        // to next pool
        // if no one wins this round, the money goes to next pool
        pool2Next = round.pool;
      }
      
      emit FinalizeRound(_round);
      
      if (_round == (maxRound.sub(1))) {
          // if we&#39;re finalizing the last round
          // things will be a little different
          // first there&#39;ll be no more next round
          ownerPool = ownerPool.add(pool2Next);
          return;
      }

      Round storage next = rounds[nextRound];
      
      if (nextRound == maxRound) {
          next = rounds[maxRound - 1];
      }
      
      next.pool = pool2Next.add(next.pool);
      
      if(!next.activated && nextRound == (_round.add(1))) {
          // if this is the last unactivated round, and there&#39;s still next Round
          // activate it
          next.activated = true;
          next.endTime = block.timestamp.add(next.roundTime);
          // next.pool = pool2Next.add(next.pool);

          emit NewRound(nextRound, next.pool);

          if(nextRound < maxRound) {
            nextRound = nextRound.add(1);
          }
      }
  }
  
  // _pID spent _eth to buy keys in _round
  function core(uint256 _round, address _pAddr, uint256 _eth) internal {
      require(_round < maxRound);
      Round storage current = rounds[_round];
      require(current.activated && !current.finalized);

      // new to this round
      // we can&#39;t update user profit into one wallet
      // since user may attend mulitple rounds in this mode
      // the client should check each rounds&#39; profit and do withdrawal
      /*
      if (playerRoundData[_pID][_round].keys == 0) {
          updatePlayer(_pID);
      }*/
      
      if (block.timestamp > current.endTime) {
          //we need to do finalzing
          finalize(_round);
          players[_pAddr].wallet = _eth.add(players[_pAddr].wallet);
          return;
          // new round generated, we need to update the user status to the new round 
          // no need to update
          /*
          updatePlayer(_pID);
          */
      }
      
      if (_eth < 1000000000) {
          players[_pAddr].wallet = _eth.add(players[_pAddr].wallet);
          return;
      }
      
      // calculate the keys that he could buy
      uint256 _keys = keys(current.eth, _eth);
      
      if (_keys <= 0) {
          // put the eth to the sender
          // sorry, you&#39;re bumped
          players[_pAddr].wallet = _eth.add(players[_pAddr].wallet);
          return;
      }

      if (_keys >= decimals) {
          // buy at least one key to be the winner 
          current.winner = _pAddr;
          current.endTime = timeIncrease.add(current.endTime.mul(_keys / decimals));
          if (current.endTime.sub(block.timestamp) > current.roundTime) {
              current.endTime = block.timestamp.add(current.roundTime);
          }
          
          if (_keys >= decimals.mul(10)) {
              // if one has bought more than 10 keys
              current.luckyCounter = current.luckyCounter.add(1);
              if(current.luckyCounter >= current.nextLucky) {
                  players[_pAddr].lucky = current.luckyPool.add(players[_pAddr].lucky);
                  playerRoundData[_pAddr][_round].lucky = current.luckyPool.add(playerRoundData[_pAddr][_round].lucky);
                  
                  emit Lucky(_pAddr, _round, current.nextLucky, current.luckyPool);
                  
                  current.pool = current.pool.sub(current.luckyPool);
                  current.luckyPool = 0;
                  current.nextLucky = luckyNumber.add(current.nextLucky);
                  
              }
          }
      }
      
      //now we do the money distribute
      uint256 toOwnerAmount = _eth.sub(_eth.mul(toSpread) / 1000);
      toOwnerAmount = toOwnerAmount.sub(_eth.mul(toNext) / 1000);
      toOwnerAmount = toOwnerAmount.sub(_eth.mul(toRefer) / 1000);
      toOwnerAmount = toOwnerAmount.sub(_eth.mul(toPool) / 1000);
      current.pool = (_eth.mul(toPool) / 1000).add(current.pool);
      current.luckyPool = ((_eth.mul(toPool) / 1000).mul(toLucky) / 1000).add(current.luckyPool);
      
      if (current.keys == 0) {
          // current no keys to split, send to owner
          toOwnerAmount = toOwnerAmount.add((_eth.mul(toSpread) / 1000));
      } else {
          // the mask is up by 10^18
          current.mask = current.mask.add((_eth.mul(toSpread).mul(10 ** 15)) / current.keys);
          // dust to owner;
          // need to check about the dust
          /*
          uint256 dust = (_eth.mul(toSpread) / 1000)
            .sub( 
                (_eth.mul(toSpread).mul(10**15) / current.keys * current.keys) / (10 ** 18) 
            );*/
          // forget about the dust
          // ownerPool = toOwnerAmount.add(dust).add(ownerPool);
      }
      ownerPool = toOwnerAmount.add(ownerPool);

      // the split doesnt include keys that the user just bought
      playerRoundData[_pAddr][_round].keys = _keys.add(playerRoundData[_pAddr][_round].keys);
      current.keys = _keys.add(current.keys);
      current.eth = _eth.add(current.eth);

      // for the new keys, remove the user&#39;s free earnings
      // this may cause some loose
      playerRoundData[_pAddr][_round].mask = (current.mask.mul(_keys) / (10**18)).add(playerRoundData[_pAddr][_round].mask);
      
      // to referer, or to ownerPool
      if (players[_pAddr].referer == 0) {
          ownerPool = ownerPool.add(_eth.mul(toRefer) / 1000);
      } else {
          address _referer = id2Players[players[_pAddr].referer];
          assert(_referer != address(0));
          players[_referer].affiliate = (_eth.mul(toRefer) / 1000).add(players[_referer].affiliate);
          playerRoundData[_referer][_round].affiliate = (_eth.mul(toRefer) / 1000).add(playerRoundData[_referer][_round].affiliate);
      }

      // to unopened round
      // round 12 will always be the nextRound even after it&#39;s been activated
      Round storage next = rounds[nextRound];
      
      if (nextRound >= maxRound) {	 
          next = rounds[maxRound - 1];	 
      }
      
      next.pool = (_eth.mul(toNext) / 1000).add(next.pool);
      // current.luckyPool = _eth.mul(toLucky).add(current.luckyPool);
        
      // open next round if necessary
      if(next.pool >= next.minimumPool && !next.activated) {
        next.activated = true;
        next.endTime = block.timestamp.add(next.roundTime);
        // ??? winner鏄皝
        next.winner = address(0);

        if(nextRound != maxRound) {
          nextRound = nextRound.add(1);
        }
      }
      
      emit Buy(_pAddr, _keys, _eth, _round);

  }
  
  // calculate the keys that the user can buy with specified amount of eth
  // return the eth left
  function BuyKeys(uint256 ref, uint256 _round) payable whenNotPaused public {
      logRef(msg.sender, ref);
      core(_round, msg.sender, msg.value);
  }

  function ReloadKeys(uint256 ref, uint256 _round, uint256 value) whenNotPaused public {
      logRef(msg.sender, ref);
      players[msg.sender].wallet = retrieveEarnings(msg.sender).sub(value);
      core(_round, msg.sender, value);
  }
  
  function reloadRound(address _pAddr, uint256 _round) internal returns (uint256) {
      uint256 _earn = calculateMasked(_pAddr, _round);
      if (_earn > 0) {
          playerRoundData[_pAddr][_round].mask = _earn.add(playerRoundData[_pAddr][_round].mask);
      }
      return _earn;
  }
  
  function retrieveEarnings(address _pAddr) internal returns (uint256) {
      PlayerStatus storage player = players[_pAddr];
      
      uint256 earnings = player.wallet
        .add(player.affiliate)
        .add(player.win)
        .add(player.lucky);
       /*
          address addr;          //player addr

          uint256 wallet;        //get from spread
          uint256 affiliate;     //get from reference
          uint256 win;           //get from winning
          uint256 lucky;          //eth get from lucky

          uint256 referer;       //who introduced this player

        */
      player.wallet = 0;
      player.affiliate = 0;
      player.win = 0;
      player.lucky = 0;
      for(uint256 i = 0; i <= nextRound; i ++) {
          uint256 roundEarnings = reloadRound(_pAddr, i);
          earnings = earnings.add(roundEarnings);
      }

      return earnings;
  }
  
  /*
  function withdrawalRound(address _pAddr, uint256 _round) public {
      uint256 userProfit = roundProfit(_pAddr, _round);
      if (userProfit == 0) return;
      playerRoundData[_pAddr][_round].mask = userProfit.add(playerRoundData[_pAddr][_round].mask);
      players[_pAddr].wallet = userProfit.add(players[_pAddr].wallet);
      return;
  }*/
  
  // withdrawal all the earning of the game
  function withdrawal() whenNotPaused public {
      uint256 ret = retrieveEarnings(msg.sender);
      require(ret >= minimumWithdraw);
      uint256 fee = ret.mul(withdrawFee) / 1000;
      ownerPool = ownerPool.add(fee);
      ret = ret.sub(fee);
      msg.sender.transfer(ret);
      
      emit Withdrawal(msg.sender, ret, fee);
  }

  function priceForKeys(uint256 keys, uint256 round) public view returns(uint256) {
      require(round < maxRound);
      return eth(rounds[round].keys, keys);
  }
  
  function remainTime(uint256 _round) public view returns (int256) {
      if (!rounds[_round].activated) {
          return -2;
      }
      
      if (rounds[_round].finalized) {
          return -1;
      }
      
      if (rounds[_round].endTime <= block.timestamp) {
          return 0;
      } else {
          return int256(rounds[_round].endTime - block.timestamp);
      }
  }

    function keys(uint256 _curEth, uint256 _newEth) internal pure returns(uint256) {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    function eth(uint256 _curKeys, uint256 _newKeys) internal pure returns(uint256) {
        return eth((_curKeys).add(_newKeys)).sub(eth(_curKeys));
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
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
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